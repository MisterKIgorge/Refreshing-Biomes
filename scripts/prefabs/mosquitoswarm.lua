local brain = require "brains/mosquitoswarmbrain"

local assets =
{
    Asset("ANIM", "anim/gnat.zip"),
}

local prefabs =
{
}
local DATA = {
	SMALL = {
		HEALTH = 50,
		SCALE = 0.5,
		SPEEDDOWN = 0.9,
		
		PERIOD = 15,
		DMG = 1,
	},
	
	MEDIUM = {
		HEALTH = 100,
		SCALE = 0.75,
		SPEEDDOWN = 0.75,
		
		PERIOD = 15,
		DMG = 2,
	},
	
	NORMAL = {
		HEALTH = 200,
		SCALE = 1,
		SPEEDDOWN = 0.5,
		
		PERIOD = 10,
		DMG = 3
	},
}

local function DeattachEntity(inst)
	if not inst.attachedentity then
		return
	end

	inst.attachedentity:RemoveChild(inst)
	local pos = Vector3(inst.attachedentity.Transform:GetWorldPosition())
	inst.Transform:SetPosition(pos.x, pos.y, pos.z) 
		
	if inst.attachedentity:HasTag("player") then
		inst.attachedentity:RemoveTag("infested")
		if inst.attachedentity.player_classified then
			inst.attachedentity.player_classified.stormlevel:set(0)
		end
	end
	
	if inst.attachedentity.components.locomotor then
		inst.attachedentity.components.locomotor:RemoveExternalSpeedMultiplier(inst.attachedentity, "mosquitos")	
	end
	
	inst.attachedentity = nil
end

local function AttachToEntity(inst, entity)
	if not entity then
		return
	end
	
	entity:AddChild(inst)
	
	inst.AnimState:SetFinalOffset(1)
	inst.Transform:SetPosition(0,0,0)	
		
	if entity:HasTag("player") then
		entity:AddTag("infested")
		if entity.player_classified then
			entity.player_classified.stormlevel:set(7)
		end
	end
	
	if entity.components.locomotor then
		entity.components.locomotor:SetExternalSpeedMultiplier(entity, "mosquitos", inst.data and inst.data.SPEEDDOWN or 0.5)	
	end
	
	inst.attachedentity = entity
end

local function SetData(inst, id)
    if not id then
		return
	end
	inst.data = id == 1 and DATA.SMALL or id == 2 and DATA.MEDIUM or DATA.NORMAL
end

local function CombineSwarms(inst, other)
    if not other then
		return
	end

	if inst:HasTag("swarm_lvl1") and other:HasTag("swarm_lvl1") then
		SpawnAt("mosquitoswarm", inst):SetData(2)
	elseif inst:HasTag("swarm_lvl2") and other:HasTag("swarm_lvl1") or inst:HasTag("swarm_lvl1") and other:HasTag("swarm_lvl2") then
		SpawnAt("mosquitoswarm", inst):SetData(3)
	end
	
	other:Remove()
	inst:Remove()
end

local function SplitSwarms(inst)
	if inst.data.SCALE == 1 then
		if math.random() < 0.4 then
			local mosq = SpawnAt("mosquitoswarm", inst)
			mosq.data = DATA.MEDIUM
			mosq.sg:GoToState("hit")
			mosq:UpdateSwarm()
			mosq.components.timer:StartTimer("cantcombine", TUNING.MOSQUITOSWARM_RESTOCK)
			
			local mosq2 = SpawnAt("mosquitoswarm", inst)
			mosq2.data = DATA.SMALL
			mosq2.sg:GoToState("hit")
			mosq2:UpdateSwarm()
			mosq2.components.timer:StartTimer("cantcombine", TUNING.MOSQUITOSWARM_RESTOCK)
		else 
			for i = 1, 3 do
				local mosq = SpawnAt("mosquitoswarm", inst)
				mosq.data = DATA.SMALL
				mosq.sg:GoToState("hit")
				mosq:UpdateSwarm()
				mosq.components.timer:StartTimer("cantcombine", TUNING.MOSQUITOSWARM_RESTOCK)
			end
		end
	elseif inst.data.SCALE == 0.75 then
		for i = 1, 2 do
			local mosq = SpawnAt("mosquitoswarm", inst)
			mosq.data = DATA.SMALL
			mosq.sg:GoToState("hit")
			mosq:UpdateSwarm()
			mosq.components.timer:StartTimer("cantcombine", TUNING.MOSQUITOSWARM_RESTOCK)
		end
	end
	inst:Remove()
end

local function UpdateSwarm(inst)
    if not inst.data then
		return
	end
	
	local lvl = inst.data.SCALE == 0.5 and "1" or inst.data.SCALE == 0.75 and "2" or "3"
	inst:RemoveTag("swarm_lvl1")
	inst:RemoveTag("swarm_lvl2")
	inst:RemoveTag("swarm_lvl3")
	inst:AddTag("swarm_lvl"..lvl)

	inst.AnimState:SetScale(inst.data.SCALE, inst.data.SCALE, inst.data.SCALE)
	inst.components.health:SetMaxHealth(inst.data.HEALTH)
	
	inst.components.combat:SetAttackPeriod(inst.data.PERIOD)
	inst.components.combat:SetDefaultDamage(inst.data.DMG)
	
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY * (2*inst.data.SCALE)
end

local function FindLilyToCocoon(inst, val)
	if val and inst:HasTag("swarm_lvl3") and not inst.plantedcocoon then
		inst:AddTag("wanttococoon")
	else
		inst:RemoveTag("wanttococoon")
	end
end

local function OnSave(inst, data)
    data._data = inst.data
    data.plantedcocoon = inst.plantedcocoon
end

local function OnLoad(inst, data)
    if data then
        inst.data = data._data
        inst.plantedcocoon = data.plantedcocoon
		inst:UpdateSwarm()
    end
end
local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "wall", "mosquitoswarm", "INLIMBO" }
local function RetargetFn(inst)
    return not inst.sg:HasStateTag("hidden")
        and FindEntity(
                inst,
                inst.range or TUNING.DECID_MONSTER_TARGET_DIST * 1.5,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                RETARGET_MUST_TAGS, --See entityreplica.lua (re: "_combat" tag)
                RETARGET_CANT_TAGS
            )
        or nil
end

local function KeepTargetFn(inst, target)
    return inst and not inst.sg:HasStateTag("exit")
        and (inst.sg:HasStateTag("hidden")
            or (target and
                not target.components.health:IsDead() and
                inst.components.combat:CanTarget(target) and
                inst:IsNear(target, 20)
                )
            )
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    inst:AddTag("monster")
    inst:AddTag("ignorewalkableplatformdrowning")
	inst:AddTag("mosquitoswarm")
	inst:AddTag("flying")
	inst:AddTag("insect")
	inst:AddTag("animal")	
	inst:AddTag("smallcreature")
    inst:AddTag("hostile")	

    inst:AddTag("burnable") -- needs this to be frozen by flingomatic

    inst.AnimState:SetBank("gnat")
    inst.AnimState:SetBuild("gnat")
    inst.AnimState:PlayAnimation("idle_loop")
	
	MakeFlyingCharacterPhysics(inst, 1, .25)
	
	inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("locomotor")
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 7

	inst:SetStateGraph("SGmosquitoswarm")
	
	inst:SetBrain(brain)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "fx_puff"
    inst.components.combat:SetDefaultDamage(1)
    inst.components.combat:SetAttackPeriod(10)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.NEVER)

	inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_TINY * 2

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst:AddComponent("timer")

	inst:AddComponent("knownlocations")

	inst.AttachToEntity = AttachToEntity
	inst.DeattachEntity = DeattachEntity
	inst.SetData = SetData
	inst.UpdateSwarm = UpdateSwarm
	inst.SplitSwarms = SplitSwarms
	inst.CombineSwarms = CombineSwarms

	inst.data = DATA.NORMAL
	inst:DoTaskInTime(0, UpdateSwarm)
	
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

	inst:WatchWorldState("isspring", FindLilyToCocoon)
	inst:DoTaskInTime(0, function()
		if TheWorld.state.isspring then
			FindLilyToCocoon(inst)
		end
	end)
	
	inst:ListenForEvent("onremove", inst.DeattachEntity)
	
    return inst
end

return Prefab("mosquitoswarm", fn, assets, prefabs)
