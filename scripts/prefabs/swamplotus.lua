local assets =
{
	Asset("ANIM", "anim/lotus.zip"),
    Asset("MINIMAP_IMAGE", "lotus"),    
}

local function OnPickedLotus(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked")
end

local function OnRegenLotus(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle_plant", true)
end

local function EmptyLotus(inst)
	inst.AnimState:PlayAnimation("picked")
end

local function OnIsDay(inst, isday)
    if isday then
        inst:DoTaskInTime(math.random()*10, function(inst) 
            if inst.components.pickable and inst.components.pickable.canbepicked and inst.closed then
                inst.closed = nil
                inst.AnimState:PlayAnimation("open")
                inst.AnimState:PushAnimation("idle_plant", true)
            end
        end)
    else
        inst:DoTaskInTime(math.random()*10, function(inst) 
            if inst.components.pickable and inst.components.pickable.canbepicked then
                inst.AnimState:PlayAnimation("close")
                inst.AnimState:PushAnimation("idle_plant_close")
                inst.closed = true
            end
        end)
    end
end

local function OnInit(inst)
    inst:WatchWorldState("isday", OnIsDay)
    OnIsDay(inst, TheWorld.state.isday)
end

local function fn(Sim)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

    MakeInventoryPhysics(inst, nil, 0.7)

	inst.AnimState:SetBank("lotus")
	inst.AnimState:SetBuild("lotus")
	inst.AnimState:PlayAnimation("idle_plant", true)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.AnimState:SetTime(math.random() * 2)
	local color = 0.75 + math.random() * 0.25
	inst.AnimState:SetMultColour(color, color, color, 1)

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("lotus_flower", 20)
	inst.components.pickable.onregenfn = OnRegenLotus
	inst.components.pickable.onpickedfn = OnPickedLotus
    inst.components.pickable.makeemptyfn = EmptyLotus
    inst.components.pickable.product = "lotus_flower"
    inst.components.pickable.SetRegenTime = 120
	
    inst:DoTaskInTime(0, OnInit)

	MakeNoGrowInWinter(inst)    
	
	return inst
end

return Prefab("lotus", fn, assets, prefabs)
