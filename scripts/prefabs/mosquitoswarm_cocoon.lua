local assets =
{
    Asset("ANIM", "anim/lantern_fly.zip"),
}

local prefabs =
{
	"mosquitoswarm",
}

local tree_data =
{
    regrowth_tuning=TUNING.MOSQUITOSWARM_GROWTH,
    grow_times=TUNING.MOSQUITOSWARM_COCOON_GROW_TIME,
}

local function OnDeath(inst)
	inst:DoTaskInTime(0, function()
		inst.AnimState:PlayAnimation("cocoon_death")
		inst:DoTaskInTime(1, function()
			local mosq = SpawnAt("mosquitoswarm", inst)
			mosq:SetData(inst.components.growable.stage)
			mosq.sg:GoToState("spawn")
			inst:PushEvent("onspawned")
			ErodeAway(inst)
		end)
	end)
end

local function OnGrowth(inst)
	inst.AnimState:PlayAnimation("cocoon_idle_pst")
	inst:DoTaskInTime(1, function()
		local mosq = SpawnAt("mosquitoswarm", inst)
		mosq:SetData(inst.components.growable.stage)
		mosq.sg:GoToState("spawn")
		inst:PushEvent("onspawned")
		ErodeAway(inst)
	end)
end

local function OnAttacked(inst)
	inst.AnimState:PlayAnimation("cocoon_hit")
	inst.AnimState:PushAnimation("cocoon_idle_loop", true)
end

local function OnSpawn(inst)
	inst.AnimState:PlayAnimation("cocoon_hit")
	inst.AnimState:PushAnimation("cocoon_idle_loop", true)
end

local function SetSmall(inst)
	inst.Transform:SetScale(0.5, 0.5, 0.5)
	inst:PushEvent("onstage", 0.5)
end

local function GrowSmall(inst)
	inst.AnimState:PlayAnimation("cocoon_hit")
	inst.AnimState:PushAnimation("cocoon_idle_loop", true)
	inst.Transform:SetScale(0.5, 0.5, 0.5)
	inst:PushEvent("onstage", 0.5)
end

local function SetMed(inst)
	inst.Transform:SetScale(0.75, 0.75, 0.75)
	inst:PushEvent("onstage", 0.75)
end

local function GrowMed(inst)
	inst.AnimState:PlayAnimation("cocoon_hit")
	inst.AnimState:PushAnimation("cocoon_idle_loop", true)
	inst.Transform:SetScale(0.75, 0.75, 0.75)
	inst:PushEvent("onstage", 0.75)
end

local function SetNormal(inst)
	inst.Transform:SetScale(1, 1, 1)
	inst:PushEvent("onstage", 1)
end

local function GrowNormal(inst)
	inst.AnimState:PlayAnimation("cocoon_hit")
	inst.AnimState:PushAnimation("cocoon_idle_loop", true)
	inst.Transform:SetScale(1, 1, 1)
	inst:PushEvent("onstage", 1)
end

local function OnGrowthFn(inst)
	--ErodeAway(inst)
end

local growth_stages =
{
    {
        name = "small",
        time = function(inst) return GetRandomWithVariance(tree_data.grow_times[1].base, tree_data.grow_times[1].random) end,
        fn = SetSmall,
        growfn = GrowSmall,
    },
	
    {
        name = "medium",
        time = function(inst) return GetRandomWithVariance(tree_data.grow_times[1].base, tree_data.grow_times[1].random) end,
        fn = SetMed,
        growfn = GrowMed,
    },
	
    {
        name = "normal",
        time = function(inst) return GetRandomWithVariance(tree_data.grow_times[1].base, tree_data.grow_times[1].random) end,
        fn = SetNormal,
        growfn = GrowNormal,
    },
	
    {
        name = "hatch",
        time = function(inst) return GetRandomWithVariance(tree_data.grow_times[1].base, tree_data.grow_times[1].random) end,
        fn = OnGrowthFn,
        growfn = OnGrowth,
    },
}

local function PlayFX(proxy)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.AnimState:SetBank("gnat")
    inst.AnimState:SetBuild("gnat")
    inst.AnimState:PlayAnimation("sleep_loop", true)
	inst.AnimState:SetScale(0.75, 0.75, 0.75)
    inst.AnimState:SetFinalOffset(-1)
	inst.AnimState:HideSymbol("fx_swarm")
	
	proxy:ListenForEvent("onspawned", function() ErodeAway(inst) end)
	proxy:ListenForEvent("onstage", function(_, val) inst.Transform:SetScale(val, val, val) end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lantern_fly")
    inst.AnimState:SetBuild("lantern_fly")
    inst.AnimState:PlayAnimation("cocoon_idle_loop", true)
	inst.AnimState:Hide("eyes")
	inst.AnimState:Hide("upper_body")
	inst.AnimState:HideSymbol("cocoon_break")
	inst.AnimState:HideSymbol("shaded_shape")
	inst.AnimState:HideSymbol("mouthparts")
	inst.AnimState:HideSymbol("fur")
	inst.AnimState:HideSymbol("lower_body")
	inst.AnimState:HideSymbol("wing")
	inst.AnimState:HideSymbol("antenna")
	inst.AnimState:HideSymbol("body_patch")

	inst.Transform:SetFourFaced()
	
	if not TheNet:IsDedicated() then
		inst:DoTaskInTime(0, PlayFX)
	end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("growable")
	inst.components.growable.stages = growth_stages
	inst.components.growable:SetStage(1)
	inst.components.growable.loopstages = false
	inst.components.growable.springgrowth = true
	inst.components.growable:StartGrowing()
	
	inst:AddComponent("combat")
	
	inst:AddComponent("health")
	
	inst:AddComponent("inspectable")

	inst.OnSpawn = OnSpawn
	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("death", OnDeath)
	
    return inst
end

return Prefab("mosquitoswarm_cocoon", fn, assets, prefabs)
