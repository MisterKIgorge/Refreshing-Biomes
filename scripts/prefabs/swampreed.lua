local assets =
{
	Asset("ANIM", "anim/reeds.zip"),
}

local prefabs =
{
}
local function OnDigFinished(inst, worker)
	--inst.components.lootdropper:SpawnLootPrefab("dug_grass")
	inst:Remove()
end

local function OnChopFinished(inst, worker)
	inst.chopped = true
    inst.AnimState:PlayAnimation("fall", false)
    inst.AnimState:PushAnimation("picked", true)
	inst.components.lootdropper:SpawnLootPrefab("cutreeds")
	inst.components.lootdropper:SpawnLootPrefab("cutreeds")

	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(OnDigFinished)
	inst.components.workable:SetWorkLeft(1)
	
	inst.components.timer:StartTimer("regrow", TUNING.GRASS_REGROW_TIME)
end

local function OnChop(inst, worker, workleft)
    inst.AnimState:PlayAnimation("chop")
    inst.AnimState:PushAnimation("idle", true)
end

local function onregenfn(inst)
	inst.chopped = false

    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
	
	inst.components.workable:SetWorkAction(ACTIONS.CHOP)
	inst.components.workable:SetOnFinishCallback(OnChopFinished)
	inst.components.workable:SetWorkLeft(3)
end

local function OnPlayerNear(inst)
	if inst.chopped then
		return
	end
	inst.AnimState:PlayAnimation("rustle")
	inst.AnimState:PushAnimation("idle", true)
end

local function OnPlayerFar(inst)
	if inst.chopped then
		return
	end
	inst.AnimState:PlayAnimation("rustle")
	inst.AnimState:PushAnimation("idle", true)
end

local function OnTimerDone(inst, data)
    if data.name == "regrow" then
        onregenfn(inst)
    end
end

local function OnSave(inst, data)
    data.chopped = inst.chopped
    data.scale = inst.scale
end

local function OnLoad(inst, data)
    if data then
        inst.chopped = data.chopped
		inst.scale = data.scale
		
		if inst.chopped then
			inst.AnimState:PlayAnimation("picked", true)
			
			--inst.components.lootdropper:SpawnLootPrefab("dug_grass")
	
			inst.components.workable:SetWorkAction(ACTIONS.DIG)
			inst.components.workable:SetOnFinishCallback(OnDigFinished)
			inst.components.workable:SetWorkLeft(1)
		end
		
		if inst.scale then
			inst.Transform:SetScale(inst.scale,inst.scale,inst.scale)
		end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("grass_tall")	
	inst.AnimState:SetBuild("reeds")
    inst.AnimState:PlayAnimation("idle",true)

	local color = math.min(1, math.random() + 0.5)
	inst.AnimState:SetMultColour(color, color, color, 1)    

    MakeInventoryFloatable(inst, "small", 0.1, {1.1, 0.9, 1.1})
    inst.components.floater.bob_percent = 0

    local land_time = (POPULATING and math.random()*5*FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:SetTime(math.random() * 2)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.CHOP)
	inst.components.workable:SetOnFinishCallback(OnChopFinished)
    inst.components.workable:SetOnWorkCallback(OnChop)
	inst.components.workable:SetWorkLeft(3)
    
	inst:AddComponent("playerprox")
    inst.components.playerprox:SetOnPlayerNear(OnPlayerNear)
    inst.components.playerprox:SetOnPlayerFar (OnPlayerFar)
    inst.components.playerprox:SetDist(0.75,1)
    inst.components.playerprox:SetPlayerAliveMode(true)
	
	inst:AddComponent("timer")
	
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)
	
	inst:ListenForEvent("timerdone", OnTimerDone)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
	
    return inst
end

local function spawner()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:DoTaskInTime(0, function()
		for i=1,math.random(8, 15) do
			local reed = SpawnPrefab("swampreed")
			local x,y,z = inst.Transform:GetWorldPosition()
			local theta = math.random()*math.pi*2
			local d = math.random()+math.random()
			if d > 1 then d = 2-d end
			local dist = d * 3
			local scale = Remap(d, 1, 0, .75, 1.5)
			reed.scale = scale
			reed.Transform:SetScale(scale,scale,scale)
			reed.Transform:SetPosition(x + math.cos(theta)*dist, y, z + math.sin(theta)*dist)
			inst:Remove()
		end
	end)

	return inst
end

return Prefab("swampreed", fn, assets, prefabs),
	Prefab("swampreed_spawner", spawner)
