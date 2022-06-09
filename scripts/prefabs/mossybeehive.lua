local assets =
{
	Asset("ANIM", "anim/ant_cave_lantern.zip"),
}

local prefabs =
{
}
--[[
idle 
hit 
break 
]]
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("ant_cave_lantern")	
	inst.AnimState:SetBuild("ant_cave_lantern")
    inst.AnimState:PlayAnimation("idle",true)

	inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("mossybeehive", fn, assets, prefabs)
