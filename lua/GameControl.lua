local GameControl = {}
GameControl.__index = table

GameControl.nameHero = "npc_dota_hero_sniper"

GameControl.number_creep = 1

GameControl.TEAM_RADIAN = 0
GameControl.TEAM_DIRE = 1

function GameControl:InitialValue()

	--------- get tower
	GameControl.midRadianTower = Entities:FindByName (nil, "dota_goodguys_tower1_mid")
	GameControl.mid2RadianTower = Entities:FindByName (nil, "dota_goodguys_tower2_mid")
	GameControl.mid3RadianTower = Entities:FindByName (nil, "dota_goodguys_tower3_mid")
	GameControl.midDireTower = Entities:FindByName (nil, "dota_badguys_tower1_mid")

	--------- Hero Find
	allHero =  Entities:FindAllByName(GameControl.nameHero)
	for idx,hero in pairs( allHero ) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			GameControl.hero = hero
		else	
			GameControl.enemyHero = hero
		end
	end

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
	FindClearSpaceForUnit(GameControl.enemyHero, GameControl.midDireTower:GetAbsOrigin() + Vector(-100,-100,0) , true)
	--RandomVector( RandomFloat( 0, 200 ))
	GameControl.hero:SetHealth( GameControl.hero:GetMaxHealth() )
	GameControl.enemyHero:SetHealth( GameControl.enemyHero:GetMaxHealth() )


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
	-- print("create")
    --------------- Create Radian Creep
	local goodSpawn_Radian = GameControl.midRadianTower
	local goodWP_Radian = Entities:FindByName ( nil, "lane_mid_pathcorner_goodguys_1")
	GameControl.creeps_Radian = {}
	for i = 1, 1 do
		GameControl.creeps_Radian[i] = CreateUnitByName( "npc_dota_creep_goodguys_melee", goodSpawn_Radian:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_GOODGUYS )
	end
	-- GameControl.creeps_Radian[4] = CreateUnitByName( "npc_dota_creep_goodguys_ranged" , goodSpawn_Radian:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_GOODGUYS )
	for i = 1, 1 do
		GameControl.creeps_Radian[i]:SetInitialGoalEntity( goodWP_Radian )
		-- print(creeps_Radian[i]:GetName())
	end


	--------------- Create Dire Creep
	local goodSpawn_Dire = GameControl.midDireTower
	local goodWP_Dire = Entities:FindByName ( nil, "lane_mid_pathcorner_badguys_1")
	GameControl.creeps_Dire = {}
	for i = 1, 1 do
		GameControl.creeps_Dire[i] = CreateUnitByName( "npc_dota_creep_goodguys_melee", goodSpawn_Dire:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )

	end
	-- GameControl.creeps_Dire[4] = CreateUnitByName( "npc_dota_creep_goodguys_ranged" , goodSpawn_Dire:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_BADGUYS )
	local randomNum = RandomInt(1, 10)
	for i = 1, 1 do
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
				-- print("change")
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

function GameControl:findAttacked(targetObject)
	local allObj = {}
	if targetObject:GetTeam() == DOTA_TEAM_BADGUYS then -- set target
		allObj = { GameControl.creeps_Radian, {GameControl.hero} , { GameControl.midRadianTower }  }
	else
		allObj = { GameControl.creeps_Radian, {GameControl.enemyhero} , { GameControl.midRadianTower }  }
	end

	local results = {}
	local count = 1
	for i = 1,#allObj do
		for j = 1,#allObj[i] do
			if allObj[i][j]:GetAttackTarget() == targetObject then
				results[count] = allObj[i][j]
				count = count + 1
			end
		end
	end

	return results
end


--[[
        Run Function
--]] 

function GameControl:runAction(action,state)
	
	if action == 0 then
		GameControl.hero:Stop()
		-- print('stop')
		return 0.1
	elseif action == 1 then
		GameControl.hero:Stop()
		if state[28] == 0 then
			local minHp_creep, minHp = GameControl:getMinHpCreep(GameControl.creeps_Dire)
			GameControl.hero:MoveToTargetToAttack(minHp_creep)
			return 0.4
		else
			return 0.1
		end		
	elseif action == 2 then --- hit hero
		if state[28] == 0 then
			GameControl.hero:MoveToTargetToAttack(GameControl.enemyHero)
			return 0.4
		else
			return 0.1
		end		
		
	elseif action == 3 then --- forward
		GameControl.hero:MoveToPosition(GameControl.midDireTower:GetAbsOrigin())
		return 0.3
	elseif action == 4 then --- backward
		GameControl.hero:MoveToPosition(GameControl.midRadianTower:GetAbsOrigin())
		return 0.3
	end

end

--[[
        Agent Function
--]] 
function GameControl:getState(team)
	local stateArray = {}

	-- stateArray[1] = GameControl.creeps_Dire[1]:GetHealth() /550
	-- stateArray[2] = GameControl.hero:TimeUntilNextAttack() 
	-- stateArray[3] = GameControl.creeps_Radian[1]:TimeUntilNextAttack()
	-- stateArray[4] = GameControl.creeps_Radian[2]:TimeUntilNextAttack()
	-- stateArray[5] = GameControl.creeps_Radian[3]:TimeUntilNextAttack()
	-- stateArray[6] = GameControl.creeps_Radian[4]:TimeUntilNextAttack()
	
	local minHp_creep_dire, minHp_dire = GameControl:getMinHpCreep(GameControl.creeps_Dire)
	local minHp_creep_radian, minHp_radian = GameControl:getMinHpCreep(GameControl.creeps_Radian)
	local heroPosition = nil 
	local tableObj = {}
	
	if team == GameControl.TEAM_RADIAN then
		
		heroPosition = GameControl.hero:GetAbsOrigin()
		tableObj = { minHp_creep_radian, minHp_creep_dire ,
							GameControl.midRadianTower , GameControl.midDireTower  ,
							GameControl.enemyHero, GameControl.hero}
	else

		heroPosition = GameControl.enemyHero:GetAbsOrigin()
		tableObj = { minHp_creep_dire, minHp_creep_radian ,
							GameControl.midDireTower , GameControl.midRadianTower  ,
							GameControl.hero, GameControl.enemyHero}
	end

	for i=1,#tableObj do
		local obj = tableObj[i]
		if obj ~= nil then
			local objPosition = obj:GetAbsOrigin()
			stateArray[ (i-1)*5 + 1] = (objPosition.x - heroPosition.x)/3000
			stateArray[ (i-1)*5 + 2] = (objPosition.y - heroPosition.y)/3000
			stateArray[ (i-1)*5 + 3] = obj:TimeUntilNextAttack()
			-- print(creep:GetName())
			local attackedTarget = obj:GetAttackTarget()
			if attackedTarget ~= nil then
				local attackedName = attackedTarget:GetName()
				if attackedName == GameControl.nameHero then
					stateArray[ (i-1)*5 + 4] = 0.25
				elseif attackedName == "npc_dota_creep_lane" then
					stateArray[ (i-1)*5 + 4] = 0.50
				elseif attackedName == GameControl.midRadianTower:GetName() or attackedName == GameControl.midDireTower:GetName() then
					stateArray[ (i-1)*5 + 4] = 0.75
				end
			else -- none target
				stateArray[ (i-1)*5 + 4] = 1
			end

			stateArray[ (i-1)*5 + 5] = obj:GetHealth() / obj:GetMaxHealth() 
		else
			stateArray[ (i-1)*5 + 1] = -1
			stateArray[ (i-1)*5 + 2] = -1
			stateArray[ (i-1)*5 + 3] = -1
			stateArray[ (i-1)*5 + 4] = -1
			stateArray[ (i-1)*5 + 5] = -1
		end

	end

	stateArray[26] = heroPosition.x/3000
	stateArray[27] = heroPosition.y/3000

	stateArray[31] = team
	



	-- for key,value in pairs(stateArray) do
	-- 	print(key,value)
	-- end
	-- print("------")
	

	return stateArray


end

--[[
        run bot  Function
--]] 

function GameControl:hero_force_think()
	local minHp_creep, minHp = GameControl:getMinHpCreep(GameControl.creeps_Radian)
	local minHp_creep_dire, minHp_dire = GameControl:getMinHpCreep(GameControl.creeps_Dire)
	if CalcDistanceBetweenEntityOBB( GameControl.hero, minHp_creep) < 500 then
		if minHp < GameControl.enemyHero:GetAttackDamage() then
			return 1  -- lasthit
		elseif GameControl.enemyHero:GetHealth() < GameControl.hero:GetAttackDamage() then
			return 2 -- hit hero
		elseif GameControl.enemyHero:GetAttackTarget() == GameControl.hero then
			return 2 -- hit hero
		else
			return 0 -- idle
		end
	else
		return 3 -- forward
	end
end

function GameControl:EnemyRun()
	local minHp_creep, minHp = GameControl:getMinHpCreep(GameControl.creeps_Radian)
	local minHp_creep_dire, minHp_dire = GameControl:getMinHpCreep(GameControl.creeps_Dire)
	returntime = 0.1
	prob = math.random()

	local objectAttack = GameControl:findAttacked(GameControl.enemyHero,false)
	if #objectAttack > 0 then
		-- retreat
		print("-- retreat--")
		GameControl.enemyHero:MoveToNPC(GameControl.midDireTower)
		returntime = 0.1

	elseif CalcDistanceBetweenEntityOBB( GameControl.enemyHero, minHp_creep_dire) > 500 then -- go to creep
		GameControl.enemyHero:MoveToPosition(minHp_creep_dire:GetAbsOrigin())

	elseif minHp < GameControl.enemyHero:GetAttackDamage() then  --- lastcreep
		GameControl.enemyHero:MoveToTargetToAttack(minHp_creep)
		
	elseif CalcDistanceBetweenEntityOBB( GameControl.hero, GameControl.enemyHero) < 500 and CalcDistanceBetweenEntityOBB( GameControl.enemyHero, GameControl.midRadianTower) > 500 then -- hit hero
		GameControl.enemyHero:MoveToTargetToAttack(GameControl.hero)

	elseif prob < 0.2 and CalcDistanceBetweenEntityOBB( GameControl.hero, minHp_creep) < 800 then -- move to enemy hero
		GameControl.enemyHero:MoveToPosition(GameControl.hero:GetAbsOrigin())
		returntime = 0.4

	elseif prob >= 0.2 and prob < 0.6 then -- attack min hp creep
		GameControl.enemyHero:MoveToTargetToAttack(minHp_creep)
		returntime = 0.3

	else --- walk random 
		GameControl.enemyHero:MoveToPosition(GameControl.enemyHero:GetAbsOrigin()+RandomVector(1000))
		returntime = 0.3

	end

	return returntime
	-- print("---")

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

