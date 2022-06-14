local assets =
{
    Asset("ANIM", "anim/fume_fx.zip"),
}

--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("fume_fx")
	inst.AnimState:SetBuild("fume_fx")
	inst.AnimState:PlayAnimation("poot")

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:ListenForEvent("animqueueover", inst.Remove)

	return inst
end

return Prefab("fume_fx", fn, assets)
