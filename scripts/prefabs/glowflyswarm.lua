local assets =
{
	Asset("ANIM", "anim/bioluminessence.zip"),
}

local prefabs =
{
}
--[[
idle_pre
idle_loop 
idle_pst 
anim
]]
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetBank("bioluminessence")	
	inst.AnimState:SetBuild("bioluminessence")
    inst.AnimState:PlayAnimation("idle_loop",true)

	inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("glowflyswarm", fn, assets, prefabs)
