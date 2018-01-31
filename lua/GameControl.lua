local GameControl = {}
GameControl.__index = table

GameControl.nameHero = "npc_dota_hero_sniper"

GameControl.number_creep = 1

function GameControl:InitialValue()

	--------- get tower
	GameControl.midRadianTower = Entities:FindByName (nil, "dota_goodguys_tower1_mid")
	GameControl.mid2RadianTower = Entities:FindByName (nil, "dota_goodguys_tower2_mid")
	GameControl.mid3RadianTower = Entities:FindByName (nil, "dota_goodguys_tower3_mid")
	GameControl.midDireTower = Entities:FindByName (nil, "dota_badguys_tower1_mid")

	--------- Hero Find
	GameControl.hero = Entities:FindByName(nil, GameControl.nameHero)	

	--------- Hero Properties	
	GameControl.attackRangeHero = GameControl.hero:GetAttackRange()	

	GameControl.distanceBetweenRadianTower = CalcDistanceBetweenEntityOBB( GameControl.midRadianTower, GameControl.mid3RadianTower)
	GameControl.maxDistance = CalcDistanceBetweenEntityOBB( GameControl.midRadianTower, GameControl.midDireTower)
  
  print("test")

	----------- respawn	
	GameControl:CreateCreep()
	GameControl:resetThing()
end

function GameControl:resetThing()
    FindClearSpaceForUnit(GameControl.hero, GameControl.midRadianTower:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 )) , true)
end

function GameControl:resetAll()
	GameControl:resetThing()
	GameControl:ForceKillCreep()
end

--[[
        Creep Function
--]] 

function GameControl:CreateCreep()
    --------------- Create Radian Creep
	local goodSpawn_Radian = GameControl.midRadianTower
	local goodWP_Radian = Entities:FindByName ( nil, "lane_mid_pathcorner_goodguys_1")
	GameControl.creeps_Radian = {}
	for i = 1, 4 do
		GameControl.creeps_Radian[i] = CreateUnitByName( "npc_dota_creep_goodguys_melee", goodSpawn_Radian:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_GOODGUYS )
	end
	-- GameControl.creeps_Radian[4] = CreateUnitByName( "npc_dota_creep_goodguys_ranged" , goodSpawn_Radian:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_GOODGUYS )
	for i = 1, 4 do
		GameControl.creeps_Radian[i]:SetInitialGoalEntity( goodWP_Radian )
		-- print(creeps_Radian[i]:GetName())
	end


	--------------- Create Dire Creep
	local goodSpawn_Dire = GameControl.midDireTower
	local goodWP_Dire = Entities:FindByName ( nil, "lane_mid_pathcorner_badguys_1")
	GameControl.creeps_Dire = {}
	for i = 1, GameControl.number_creep do
		GameControl.creeps_Dire[i] = CreateUnitByName( "npc_dota_creep_goodguys_melee", goodSpawn_Dire:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )

	end
	-- GameControl.creeps_Dire[4] = CreateUnitByName( "npc_dota_creep_goodguys_ranged" , goodSpawn_Dire:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )
	local randomNum = RandomInt(1, 10)
	for i = 1, GameControl.number_creep do
		GameControl.creeps_Dire[i]:SetInitialGoalEntity( goodWP_Dire )
		-- creeps_Dire[i]:SetForceAttackTarget(hero)
	end
end

function GameControl:ForceKillCreep(creeps)
	local allCreeps =  Entities:FindAllByName("npc_dota_creep_lane")
	for idx,creep in pairs( allCreeps ) do
		-- print(creep:GetName())
		if(creep ~= nil and creep:IsNull() == false and creep:IsAlive() )then
			creep:ForceKill(false)
		end
	end
end


function GameControl:runAction(action)
	if CalcDistanceBetweenEntityOBB( GameControl.hero, GameControl.creeps_Dire[1]) < 500 then
		if action == 0 then
			GameControl.hero:Stop()
			print('stop')
		elseif action == 1 then
			GameControl.hero:MoveToTargetToAttack(GameControl.creeps_Dire[1])
		end
	else
		GameControl.hero:MoveToTargetToAttack(GameControl.midDireTower)
	end
end
--[[
        Server Function
--]] 
-- function GameControl:requestActionFromServer(method, input)
--     input = input or {}
--     local dataSend = {}
--     dataSend['method'] = method

--     if dataSend['method'] == GET_DQN_DETAIL then
-- 		print("GET DQN")

-- 	elseif dataSend['method'] == UPPDATE_MODEL_STATE then
-- 		print("update model")
-- 		dataSend['mem_episode'] = dqn_agent.memory

--     end
    
--     request = CreateHTTPRequestScriptVM("POST", "http://localhost:8080" )
-- 	request:SetHTTPRequestHeaderValue("Accept", "application/json")
--     request:SetHTTPRequestRawPostBody('application/json', dkjson.encode(dataSend))

--     request:Send( function( result )

-- 		if result["StatusCode"] == 200 then
--             dict_value = dkjson.decode(result['Body'])

--             if dataSend['method'] == GET_DQN_DETAIL then
                
--             elseif dataSend['method'] == UPPDATE_MODEL_STATE then
--                 dqn_agent.memory = {}             
--             end

--         end

-- 	end )

-- end


--[[
        Agent Function
--]] 
function GameControl:getState(num_hero)
	local stateArray = {}
	-- stateArray[1] = normalize(GameControl.creeps_Dire[1]:GetHealth(), 0, GameControl.creeps_Dire[1]:GetMaxHealth() )
	-- stateArray[2] = normalize(GameControl.hero:TimeUntilNextAttack(), 0 ,GameControl.hero:GetBaseAttackTime() )
	stateArray[1] = GameControl.creeps_Dire[1]:GetHealth()
	stateArray[2] = GameControl.hero:TimeUntilNextAttack()
	return stateArray
end

--[[
        Other Function
--]] 

function normalize(value, min, max)
	return (value - min) / (max - min)
end

return GameControl