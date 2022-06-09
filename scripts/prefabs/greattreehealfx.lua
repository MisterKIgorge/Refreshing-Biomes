local assets =
{
    Asset("ANIM", "anim/lavaarena_heal_salve_fx.zip"),
}

local prefabs =
{
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_heal_salve_fx")
    inst.AnimState:SetBuild("lavaarena_heal_salve_fx")
    inst.AnimState:PlayAnimation("pre")
    inst.AnimState:PushAnimation("loop", true)
    inst.AnimState:SetMultColour(.5, .5, .5, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("greattreehealfx", fn, assets, prefabs)
