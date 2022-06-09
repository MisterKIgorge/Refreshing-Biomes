local assets =
{
    Asset("ANIM", "anim/lavaarena_heal_flowers_fx.zip"),
}

--------------------------------------------------------------------------

local NUM_BLOOM_VARIATIONS = 6

local function OnEnterDark(inst)
	print("enter dark")
	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("idle_"..inst.variation, true)
	inst.Light:Enable(true)
end

local function OnExitDark(inst)
	print("enter light")
	inst.AnimState:PlayAnimation("out_"..inst.variation)
	inst.Light:Enable(false)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

	inst.Light:SetFalloff(2)
    inst.Light:SetIntensity(0.3)
	inst.Light:SetRadius(0.5)
	inst.Light:SetColour(0/255, 128/255, 255/255,1)
	inst.Light:Enable(true)
	inst.Light:EnableClientModulation(true)
	
    inst.LightWatcher:SetLightThresh(.20)
    inst.LightWatcher:SetDarkThresh(.45)
	
	inst.variation = tostring(math.random(NUM_BLOOM_VARIATIONS)) or 1

	inst.AnimState:SetBank("lavaarena_heal_flowers")
	inst.AnimState:SetBuild("lavaarena_heal_flowers_fx")
	inst.AnimState:Hide("buffed_hide_layer")
	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("idle_"..inst.variation, true)

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:ListenForEvent("enterdark", OnEnterDark)
	inst:ListenForEvent("enterlight", OnExitDark)
	
	return inst
end

return Prefab("moonbloom", fn, assets)
