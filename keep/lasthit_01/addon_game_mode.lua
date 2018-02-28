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

	----------- Set control creep
	SendToServerConsole( "dota_creeps_no_spawning  1" )
	SendToServerConsole( "dota_all_vision 1" )

	----------- Set Event Listener
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CAddonTemplateGameMode, 'OnEntity_kill' ), self )
	ListenToGameEvent( "player_chat", Dynamic_Wrap( CAddonTemplateGameMode, 'OnInitial' ), self ) ---- when player chat the game will reset


end

function CAddonTemplateGameMode:OnInitial()
	GameControl:InitialValue()
	ai_state = STATE_GETMODEL
	check_done = false
	check_send = false
	all_reward = 0

	GameRules:GetGameModeEntity():SetThink( "state_loop", self, 1)
	
	print("init")	
end

STATE_GETMODEL = 0
STATE_SIMULATING = 1
STATE_UPDATEMODEL = 2

baseURL = "http://localhost:5000"


function CAddonTemplateGameMode:state_loop()
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
								GameRules:GetGameModeEntity():SetThink( "bot_loop", self, 1)	

							end
						end )
	elseif ai_state == STATE_SIMULATING then
		check_send = false
	elseif ai_state == STATE_UPDATEMODEL then
		if check_send == false then
			check_send = true
			data_send = {}
			data_send['mem'] = dqn_agent.memory
			data_send['all_reward'] = all_reward
			print('update')
			request = CreateHTTPRequestScriptVM( "POST", baseURL .. "/update")
			request:SetHTTPRequestHeaderValue("Accept", "application/json")		
			request:SetHTTPRequestRawPostBody('application/json', package.loaded['game/dkjson'].encode(data_send))
			request:Send( 	function( result ) 
								if result["StatusCode"] == 200 and ai_state == STATE_UPDATEMODEL then  
									-- Say(hero, "Model Updated", false)
									local data = package.loaded['game/dkjson'].decode(result['Body'])
									dqn_agent.weight_array = data['weights_all']
									dqn_agent.bias_array = data['bias_all']     
									dqn_agent.memory = {}           
									
									GameControl:CreateCreep()
									check_done = false
									ai_state = STATE_SIMULATING							
									check_send = false
									all_reward = 0
									
									
								end
							end )
		end
		
	else
		Warning("Some shit has gone bad..")
	end
	-- print(ai_state)
	
	return 3
end

function CAddonTemplateGameMode:bot_loop()
	if ai_state ~= STATE_SIMULATING then
		return 0.2
	end

	new_state = GameControl:getState()
	if check_done then
		if reward == 0 then
			reward = -1
		end
		dqn_agent:remember({state,action,reward,new_state,true})
		print("reward: "..reward)
		all_reward = all_reward + reward
		reward = 0		
		GameControl:resetAll()
		ai_state = STATE_UPDATEMODEL				
	else
		dqn_agent:remember({state,action,reward,new_state,false})
	end

	state = new_state
	------------------------
	action = dqn_agent:act(state) - 1
	-- if state[1] < 20 then
	-- 	action = 1
	-- end
	GameControl:runAction(action)	
	-- print(action)

	return 0.3

end


function CAddonTemplateGameMode:OnEntity_kill(event)
	local killed = EntIndexToHScript(event.entindex_killed);
	local attaker = EntIndexToHScript(event.entindex_attacker );
	-- local damage = event.damagebits
	-- print(killed:GetName())
	if(killed:GetName() == "npc_dota_creep_lane" )then
		if killed:GetTeam() == DOTA_TEAM_BADGUYS then
			check_done = true
			if attaker:GetName() == GameControl.nameHero then
				reward = 1
			end
		end		
	end

end