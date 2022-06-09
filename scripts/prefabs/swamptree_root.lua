require "brains/swamprootbrain"
require "stategraphs/SGswamproot"

local trace = function() end

local SWAMPROOT_HEALTH = 250
local SWAMPROOT_DAMAGE = 15
local SWAMPROOT_SPEED = 4

local SWAMPROOT_TARGET_DIST = 8
local SWAMPROOT_KEEP_TARGET_DIST= 15
local SWAMPROOT_ATTACK_PERIOD = 3
local SPIDER_WARRIOR_WAKE_RADIUS = 6
local SPRING_COMBAT_MOD = 1.33

local assets=
{
	Asset("ANIM", "anim/quagmire_tentacle_root.zip"),
}

local prefabs =
{
	"plantmeat",
}


SetSharedLootTable( 'swamproot',
{
    {'plantmeat',   1.0}, 
})

local WAKE_TO_FOLLOW_DISTANCE = 8
local SHARE_TARGET_DIST = 30

local NO_TAGS = {"FX", "NOCLICK","DECOR","INLIMBO"}

local function retargetfn(inst)
	local dist = SWAMPROOT_TARGET_DIST
	local notags = {"FX", "NOCLICK","INLIMBO", "wall", "structure", "aquatic", "swamproot"}
	return FindEntity(inst, dist, function(guy)
		return  inst.components.combat:CanTarget(guy)
	end, nil, notags)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (SWAMPROOT_KEEP_TARGET_DIST*SWAMPROOT_KEEP_TARGET_DIST) and not target:HasTag("aquatic")
end

local function OnAttacked(inst, data)
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, function(dude) return dude:HasTag("swamproot") and not dude.components.health:IsDead() end, 5)
end

local function OnAttackOther(inst, data)
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("swamproot") and not dude.components.health:IsDead() end, 5)
end

local function SanityAura(inst, observer)
    return -TUNING.SANITYAURA_SMALL
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst:AddTag("character")
	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("animal")
	inst:AddTag("swamproot")
	
	MakeCharacterPhysics(inst, 1000, .5)
	
	MakeInventoryFloatable(inst, "small", 0.1, {1.1, 0.9, 1.1})
	inst.components.floater.bob_percent = 0

	local land_time = (POPULATING and math.random()*5*FRAMES) or 0
	inst:DoTaskInTime(land_time, function(inst)
		inst.components.floater:OnLandedServer()
	end)

	inst.AnimState:SetBank("tentacle")
	inst.AnimState:SetBuild("quagmire_tentacle_root")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	
	
	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = SWAMPROOT_SPEED

	inst:SetStateGraph("SGswamproot")

	local brain = require "brains/swamprootbrain"
	inst:SetBrain(brain)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(SWAMPROOT_HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(SWAMPROOT_DAMAGE)
	inst.components.combat:SetAttackPeriod(SWAMPROOT_ATTACK_PERIOD) 
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetRange(2,3)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('swamproot')

	inst:AddComponent("inspectable")
  
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = SanityAura

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

	return inst
end

return Prefab("swamproot", fn, assets, prefabs)

