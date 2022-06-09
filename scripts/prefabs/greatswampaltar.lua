local assets =
{
	Asset("ANIM", "anim/hydroponic_slow_farmplot.zip"),
}

local prefabs =
{
}
--[[
Idle
grow 
grow_pst 
Idle2 
rustle 
picked
grow
grow_pst 
rustle 
picked 
]]
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("hydroponic_slow_farmplot")	
	inst.AnimState:SetBuild("hydroponic_slow_farmplot")
    inst.AnimState:PlayAnimation("Idle",true)

	inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("greatswampaltar", fn, assets, prefabs)
