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
	FindClearSpaceForUnit(GameControl.hero, GameControl.midRadianTower:GetAbsOrigin() + Vector(-100,-100,0) , true)
	--RandomVector( RandomFloat( 0, 200 ))
	GameControl.midRadianTower:SetHealth( GameControl.midRadianTower:GetMaxHealth() )
	GameControl.midDireTower:SetHealth( GameControl.midDireTower:GetMaxHealth() )
end

function GameControl:resetAll()
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
	for i = 1, 4 do
		GameControl.creeps_Dire[i] = CreateUnitByName( "npc_dota_creep_goodguys_melee", goodSpawn_Dire:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )

	end
	-- GameControl.creeps_Dire[4] = CreateUnitByName( "npc_dota_creep_goodguys_ranged" , goodSpawn_Dire:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )
	local randomNum = RandomInt(1, 10)
	for i = 1, 4 do
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

function GameControl:getMinHpCreep(creeps)
	
	local minHp = 999;
	local minHp_creep = nil;
	
	for i, creep in pairs(creeps) do
		if(creep:IsNull() == false and creep:IsAlive() )then
			hp = creep:GetHealth();
			if( hp < minHp )then
				minHp = hp;
				minHp_creep = creep;
			end
		end
	end
	
	return minHp_creep, minHp
	
end

function GameControl:getCreepTarget(target, group_creep_attack)
	local result_group = {}
	local count = 1
	if target ~= nil then
		for key, creep in pairs(group_creep_attack) do
			if(creep:IsNull() == false and creep:IsAlive() )then
				if creep:GetAttackTarget() == target then
					result_group[count] = creep
					count = count + 1
				end
			end
		end
	end
	return result_group
end


--[[
        Run Function
--]] 

function GameControl:runAction(action,state)
	if CalcDistanceBetweenEntityOBB( GameControl.hero, GameControl.creeps_Dire[1]) < 500 then
		if action == 0 then
			GameControl.hero:Stop()
			-- print('stop')
			return 0.1
		elseif action == 1 then
			GameControl.hero:Stop()
			if state[2] == 0 then
				local minHp_creep, minHp = GameControl:getMinHpCreep(GameControl.creeps_Dire)
				GameControl.hero:MoveToTargetToAttack(minHp_creep)
				return 0.4
			else
				return 0.1
			end
			-- print('hit')
			
			
		end
	else
		GameControl.hero:MoveToTargetToAttack(GameControl.midDireTower)
		return 0.1
	end
end

--[[
        Agent Function
--]] 
function GameControl:getState()
	local stateArray = {}

	-- stateArray[1] = GameControl.creeps_Dire[1]:GetHealth() /550
	-- stateArray[2] = GameControl.hero:TimeUntilNextAttack() 
	-- stateArray[3] = GameControl.creeps_Radian[1]:TimeUntilNextAttack()
	-- stateArray[4] = GameControl.creeps_Radian[2]:TimeUntilNextAttack()
	-- stateArray[5] = GameControl.creeps_Radian[3]:TimeUntilNextAttack()
	-- stateArray[6] = GameControl.creeps_Radian[4]:TimeUntilNextAttack()
	
	local minHp_creep, minHp = GameControl:getMinHpCreep(GameControl.creeps_Dire)
	local result_group = GameControl:getCreepTarget(minHp_creep, GameControl.creeps_Radian)
	if minHp_creep ~= nil then
		stateArray[1] = minHp_creep:GetHealth() / minHp_creep:GetMaxHealth() 
	else
		stateArray[1] = -2
	end
	stateArray[2] = GameControl.hero:TimeUntilNextAttack()

	for i = 1,4 do
		if result_group[i] == nil then
			stateArray[i+2] = -2
		else
			stateArray[i+2] = result_group[i]:TimeUntilNextAttack()
		end
	end

	for key,value in pairs(stateArray) do
		print(key,value)
	end
	print("------")
	

	return stateArray


end

--[[
        Other Function
--]] 

function GameControl:shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function normalize(value, min, max)
	return (value - min) / (max - min)
end

return GameControl

