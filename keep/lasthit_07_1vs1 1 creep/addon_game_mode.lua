dkjson = package.loaded['game/dkjson']
local GameControl = require("lua/GameControl")
local DQN = require("lua/dqn")

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache( context )
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CAddonTemplateGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CAddonTemplateGameMode:InitGameMode()
	print( "Template addon is loaded." )

	------------ Set the hero can't  level up
	local XP_PER_LEVEL_TABLE = {
		0, -- 1
	}
	GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
	GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
	GameRules:GetGameModeEntity():SetCustomGameForceHero(name_hero)
	GameRules:GetGameModeEntity():SetFixedRespawnTime(1)

	----------- Create Hero
	GameRules:GetGameModeEntity():SetCustomGameForceHero(GameControl.nameHero)
	CreateUnitByName( GameControl.nameHero ,  RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )
	
	
	----------- Set control creep
	SendToServerConsole( "dota_creeps_no_spawning  1" )
	SendToServerConsole( "dota_all_vision 1" )

	----------- Set Event Listener
	ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CAddonTemplateGameMode, 'OnEntity_hurt' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CAddonTemplateGameMode, 'OnEntity_kill' ), self )
	ListenToGameEvent( "player_chat", Dynamic_Wrap( CAddonTemplateGameMode, 'OnInitial' ), self ) ---- when player chat the game will reset


end


function CAddonTemplateGameMode:OnInitial()	
	GameControl:ForceKillCreep()
	GameControl:InitialValue()
	ai_state = STATE_GETMODEL
	check_done = false
	check_send = false
	all_reward = {}
	all_reward['Radian'] = 0
	all_reward['Dire'] = 0
	reward = {}
	reward['Radian'] = 0
	reward['Dire'] = 0

	GameControl.enemyHero:Stop()

	state = {}
	new_state = {}
	action = {}

	episode = 0
	creepRound = 1
	GameRules:GetGameModeEntity():SetThink( "state_loop", self, 1)
	
	print("init")	
end

STATE_GETMODEL = 0
STATE_SIMULATING = 1
STATE_UPDATEMODEL = 2
STATE_UPDATEMODEL2 = 3

baseURL = "http://localhost:5000"


function CAddonTemplateGameMode:state_loop()
	timestate = 3

	if ai_state == STATE_GETMODEL then
		request = CreateHTTPRequestScriptVM( "GET", baseURL .. "/model")
		request:Send( 	function( result ) 
							if result["StatusCode"] == 200 and ai_state == STATE_GETMODEL then
								local data = package.loaded['game/dkjson'].decode(result['Body'])
								-- self:UpdateModel(data)
								dqn_agent = DQN.new(data['num_input'], data['num_output'], data['hidden'])
								print("gettt")
								dqn_agent.weight_array = data['weights_all']
								dqn_agent.bias_array = data['bias_all']
								
								ai_state = STATE_SIMULATING		
								GameRules:GetGameModeEntity():SetThink( "bot_loop", self)	
								GameRules:GetGameModeEntity():SetThink( "botEnemy_loop", self)	
								-- GameRules:GetGameModeEntity():SetThink( "enemy_loop", self)
								state['Radian'] = GameControl:getState(GameControl.TEAM_RADIAN)
								state['Dire'] = GameControl:getState(GameControl.TEAM_DIRE)
								
							end
						end )

	elseif ai_state == STATE_SIMULATING then
		check_send = false
	elseif ai_state == STATE_UPDATEMODEL then
		if check_send == false then
			check_send = true
			data_send = {}
			data_send['mem'] = dqn_agent.memory
			data_send['all_reward'] = all_reward['Radian']
			data_send['team'] = GameControl.TEAM_RADIAN
			print('update')
			request = CreateHTTPRequestScriptVM( "POST", baseURL .. "/update")
			request:SetHTTPRequestHeaderValue("Accept", "application/json")		
			request:SetHTTPRequestRawPostBody('application/json', package.loaded['game/dkjson'].encode(data_send))
			request:Send( 	function( result ) 
								if result["StatusCode"] == 200 and ai_state == STATE_UPDATEMODEL then  
									-- Say(hero, "Model Updated", false)
									print("get update1")
									local data = package.loaded['game/dkjson'].decode(result['Body'])
									dqn_agent.weight_array = data['weights_all']
									dqn_agent.bias_array = data['bias_all']     
									dqn_agent.memory = {}         														
									check_send = false
									all_reward['Radian'] = 0
									reward['Radian'] = 0
									ai_state = STATE_UPDATEMODEL2	

								end
							end )
		end
		-- timestate = 10
	elseif ai_state == STATE_UPDATEMODEL2 then
		if check_send == false then
			check_send = true
			data_send = {}
			data_send['mem'] = dqn_agent.memory2
			data_send['all_reward'] = all_reward['Dire']
			data_send['team'] = GameControl.TEAM_DIRE
			print('update2')
			request = CreateHTTPRequestScriptVM( "POST", baseURL .. "/update")
			request:SetHTTPRequestHeaderValue("Accept", "application/json")		
			request:SetHTTPRequestRawPostBody('application/json', package.loaded['game/dkjson'].encode(data_send))
			request:Send( 	function( result ) 
								print(result["StatusCode"])
								if result["StatusCode"] == 200 and ai_state == STATE_UPDATEMODEL2 then  
									-- Say(hero, "Model Updated", false)
									print("get update2")
									local data = package.loaded['game/dkjson'].decode(result['Body'])
									dqn_agent.weight_array = data['weights_all']
									dqn_agent.bias_array = data['bias_all']     
									dqn_agent.memory2 = {} 
									
									all_reward['Dire'] = 0	
									reward['Dire'] = 0

																									
									
																	
									GameRules:GetGameModeEntity():SetThink( "change_state", self )
									-- GameRules:GetGameModeEntity():SetThink( "enemy_loop", self )									
									-- GameRules:GetGameModeEntity():SetThink( "creep_loop", self, 2)									
																
								end
							end )
		end

	else
		Warning("Some shit has gone bad..")
	end
	-- print(ai_state)
	
	return timestate
end

function CAddonTemplateGameMode:change_state()

	GameControl:ForceKillCreep()
	GameControl:CreateCreep()
	GameControl:resetThing()	

	state['Radian'] = GameControl:getState(GameControl.TEAM_RADIAN)
	state['Dire'] = GameControl:getState(GameControl.TEAM_DIRE)

	ai_state = STATE_SIMULATING	
	check_done = false
	check_send = false
	print("finish update")
	return nil
end

function CAddonTemplateGameMode:bot_loop()
	-- print(ai_state)
	if ai_state ~= STATE_SIMULATING then
		return 0.2
	end

	new_state['Radian'] =  GameControl:getState(GameControl.TEAM_RADIAN)

	if creepRound % 50 == 0 then
		check_done = true
	end

	if check_done then

		-- radian
		dqn_agent:remember({state['Radian'], action['Radian'], reward['Radian'], new_state['Radian'],true})
		print("reward Radian: "..reward['Radian'])
		all_reward['Radian'] = all_reward['Radian'] + reward['Radian']
		reward['Radian'] = 0	
		
		
		-- dire
		dqn_agent:remember2({state['Dire'], action['Dire'], reward['Dire'], new_state['Dire'],true})
		print("reward Dire: "..reward['Dire'])
		all_reward['Dire'] = all_reward['Dire'] + reward['Dire']
		reward['Dire'] = 0	
		print("All reward: "..all_reward['Radian'].." "..all_reward['Dire'])


		episode = episode + 1
		ai_state = STATE_UPDATEMODEL
	
	else
		
		dqn_agent:remember({state['Radian'], action['Radian'], reward['Radian'], new_state['Radian'],false})
		if reward['Radian'] == 1000 or reward['Radian'] == -1000 then
			print("repeat")
		end

		all_reward['Radian'] = all_reward['Radian'] + reward['Radian']
		reward['Radian'] = 0
	end

	state['Radian'] = new_state['Radian']
	------------------------
	if creepRound % 5 == 0 then  --- force learning
		
		action['Radian'] = GameControl:hero_force_think(GameControl.TEAM_RADIAN)
	else
		action['Radian'] = dqn_agent:act(state['Radian']) - 1
	end

	local time_return = GameControl:runAction(action['Radian'], state['Radian'], GameControl.TEAM_RADIAN)
	
	return time_return

end

function CAddonTemplateGameMode:botEnemy_loop()
	-- print(ai_state)
	if ai_state ~= STATE_SIMULATING then
		return 0.2
	end

	new_state['Dire'] =  GameControl:getState(GameControl.TEAM_DIRE)
	
	if check_done == false then
		dqn_agent:remember2({state['Dire'], action['Dire'], reward['Dire'], new_state['Dire'], false})
		all_reward['Dire'] = all_reward['Dire'] + reward['Dire']
		reward['Dire'] = 0
	end

	state['Dire'] = new_state['Dire']
	------------------------
	if creepRound % 5 == 0 then  --- force learning
		
		action['Dire'] = GameControl:hero_force_think(GameControl.TEAM_DIRE)
	else
		action['Dire'] = dqn_agent:act(state['Dire']) - 1
	end

	local time_return = GameControl:runAction(action['Dire'], state['Dire'], GameControl.TEAM_DIRE)
	
	return time_return

end

-- enemy_retreat = false
-- function CAddonTemplateGameMode:enemy_loop()
-- 	-- if enemy_retreat then
-- 	-- 	GameControl.enemyHero:MoveToNPC(GameControl.midDireTower)
-- 	-- 	enemy_retreat = false
-- 	-- 	-- print("retreat")
-- 	-- 	return 1
-- 	-- else
-- 	-- 	-- print("do")
-- 	return GameControl:EnemyRun()
	
-- end


-- function CAddonTemplateGameMode:creep_loop()
-- 	if ai_state == STATE_SIMULATING then
-- 		GameControl:CreateCreep()
-- 		return 30
-- 	end
-- end



function CAddonTemplateGameMode:OnEntity_kill(event)
	local killed = EntIndexToHScript(event.entindex_killed);
	local attaker = EntIndexToHScript(event.entindex_attacker );

	if(killed:GetName() == "npc_dota_creep_lane" )then

		-- lasthit
		if attaker:GetName() == GameControl.nameHero then			
			print("kill creep")				
			if killed:GetTeam() == DOTA_TEAM_BADGUYS then 
				reward['Radian'] = 100
			else
				reward['Dire'] = 100
			end
			
		end

		--- check launch next wave
		local countCreepDieDire = 0
		----------- Count die creep number
		if GameControl.creeps_Dire ~= nil and GameControl.creeps_Radian ~= nil then
			for i = 1, #GameControl.creeps_Dire do
				if(GameControl.creeps_Dire[i]:IsNull() or GameControl.creeps_Dire[i]:IsAlive() == false )then
					countCreepDieDire = countCreepDieDire + 1
				end
			end

			local countCreepDieRadian = 0
			----------- Count die creep number
			for i = 1, #GameControl.creeps_Radian do
				if(GameControl.creeps_Radian[i]:IsNull() or GameControl.creeps_Radian[i]:IsAlive() == false )then
					countCreepDieRadian = countCreepDieRadian + 1
				end
			end

			------------- Reset the episode when all dire creep are die
			if(countCreepDieDire == #GameControl.creeps_Dire and countCreepDieRadian == #GameControl.creeps_Radian )then
				-- check_done = true
				if check_done == false then
					GameControl:CreateCreep()
				end
				print("creepRound :"..creepRound)
				creepRound = creepRound + 1

			end
		end
			
	end

	if(killed:GetName() == GameControl.nameHero )then
		if check_done == false then
			if killed:GetTeam() == DOTA_TEAM_GOODGUYS then
				reward['Radian'] = -1000
				reward['Dire'] = 1000
			else 
				reward['Radian'] = 1000
				reward['Dire'] = -1000
			end
			print("die-------")
			check_done = true
		end
		
	end

end

function CAddonTemplateGameMode:OnEntity_hurt(event)

	local killed = EntIndexToHScript(event.entindex_killed);
	local attaker = EntIndexToHScript(event.entindex_attacker );
	-- local damage = event.damagebits
	-- print(killed:GetName())
	if(killed == GameControl.enemyHero )then
		-- enemy_retreat = true
		-- print("retreat")
	end

end