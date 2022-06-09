local assets =
{
    Asset("ANIM", "anim/quagmire_tentacle_root.zip"),
}

local prefabs =
{
	"plantmeat",
	"vine",
	"nectar_pod",
}


SetSharedLootTable( 'mean_flytrap',
{
    {'plantmeat',   1.0}, 
    {'vine',        0.5},
    {'nectar_pod',  0.3},    
})

local WAKE_TO_FOLLOW_DISTANCE = 8
local SHARE_TARGET_DIST = 15

local NO_TAGS = {"FX", "NOCLICK","DECOR","INLIMBO"}

local function OnNewTarget(inst, data)
	inst.keeptargetevenifnofood = nil
	if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function findfood(inst,guy)
	if guy.components.inventory then
		return guy.components.inventory:FindItem(
			function(item) 						
				return inst.components.eater:CanEat(item)
			end)
	end
end

local function retargetfn(inst)
	local dist = 10
	local notags = {"FX", "NOCLICK","INLIMBO", "wall", "flytrap", "structure", "aquatic"}
	return FindEntity(inst, dist, function(guy)

		if (guy:HasTag("plantkin") or guy:HasTag("chess") ) and (guy:GetDistanceSqToInst(inst) > 10*10 or not findfood(inst,guy)) then
			return false
		end

		return  inst.components.combat:CanTarget(guy)
	end, nil, notags)
end

local function KeepTarget(inst, target)
	if not inst.keeptargetevenifnofood and target:HasTag("plantkin") and not findfood(inst,target) then
		return false
	end
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (10*10) and not target:HasTag("aquatic")
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	--inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("flytrap")and not dude.components.health:IsDead() end, 5)	
	inst.keeptargetevenifnofood = true
end

local function OnAttackOther(inst, data)
	--inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("flytrap") and not dude.components.health:IsDead() end, 5)
end

local function DoReturn(inst)
	--print("DoReturn", inst)
	if inst.components.homeseeker then
		inst.components.homeseeker:ForceGoHome()
	end
end

local function OnDay(inst)
	--print("OnNight", inst)
	if inst:IsAsleep() then
		DoReturn(inst)
	end
end

local function OnEntitySleep(inst)
	--print("OnEntitySleep", inst)
	if GetClock():IsDay() then
		DoReturn(inst)
	end
end

local function OnSave(inst, data)
	if inst.currentTransform then
		data.currentTransform = inst.currentTransform 
	end
end

local function OnLoad(inst, data)
	if data and data.currentTransform then
		inst.currentTransform  = data.currentTransform -1
	end
end

local function SanityAura(inst, observer)
    return -TUNING.SANITYAURA_SMALL
end

local function ShouldSleep(inst)
    return GetClock():IsDay()
           and not (inst.components.combat and inst.components.combat.target)
           and not (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           and not (inst.components.burnable and inst.components.burnable:IsBurning() )
           and not (inst.components.follower and inst.components.follower.leader)
           and not (inst.components.freezable and inst.components.freezable:IsFrozen())
end

local function ShouldWake(inst)   
    return GetClock():IsNight()
           or (inst.components.combat and inst.components.combat.target)
           or (inst.components.homeseeker and inst.components.homeseeker:HasHome() )
           or (inst.components.burnable and inst.components.burnable:IsBurning() )
           or (inst.components.follower and inst.components.follower.leader)           
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local physics = inst.entity:AddPhysics()
	local sound = inst.entity:AddSoundEmitter()
	local shadow = inst.entity:AddDynamicShadow()
	shadow:SetSize( 2.5, 1.5 )
	inst.Transform:SetFourFaced()

	inst.AnimState:Hide("dirt")

	inst:AddTag("character")
	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("flytrap")
	inst:AddTag("hostile")
	inst:AddTag("animal")
	inst:AddTag("usefastrun")

	MakeCharacterPhysics(inst, 10, .5)

	anim:SetBank("venus_flytrap")
	anim:SetBuild("venus_flytrap_sm_build")
	anim:PlayAnimation("idle")

	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = 3

	inst:SetStateGraph("SGflytrap")

	local brain = require "brains/swamprootbrain"
	inst:SetBrain(brain)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(10)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(10)
	inst.components.combat:SetAttackPeriod(5) 
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRange(2,3)

	inst:AddComponent("inspectable")

	inst:ListenForEvent("newcombattarget", OnNewTarget)

	inst.OnEntitySleep = OnEntitySleep

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst.currentTransform = 1

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

	MakeMediumFreezableCharacter(inst, "stem")
	MakeMediumBurnableCharacter(inst, "stem")

	return inst
end

return Prefab("swamptree_root", fn, assets)
