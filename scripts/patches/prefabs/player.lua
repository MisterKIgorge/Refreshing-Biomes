local function EnterWaterFn(inst)
	if inst:HasTag("playerghost") then
		inst.AnimState:SetBank("ghost")
		return
	end

	local isriding = inst.components.rider and inst.components.rider:IsRiding()

	local size = "small"
	local scale = 0.7
	local high = 0.6
	if isriding then
		inst.AnimState:SetBank("wilsonbeefalo")
		size = "med"
		scale = 1.75
		high = 0.8
	end

	SpawnAt("splash_green", inst)

	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "waterspeed", 0.5)
	
	inst._waketask = inst:DoPeriodicTask(0.75, function()
		local running
		if inst.sg ~= nil then
			running = inst.sg:HasStateTag("moving") 
		else
			running = inst:HasTag("moving")
		end
		if running then
			local wake = SpawnPrefab("wake_small")
			local theta = inst.Transform:GetRotation() * DEGREES
			local offset = Vector3(math.cos( theta )*0.2, 0, -math.sin( theta )*0.2)
			local pos = Vector3(inst.Transform:GetWorldPosition()) + offset
			wake.Transform:SetPosition(pos.x,pos.y+0.5,pos.z)
			wake.Transform:SetRotation(inst.Transform:GetRotation() - 90)
			
			inst.SoundEmitter:PlaySound("turnoftides/common/together/water/swim/medium")
		end
	end)

	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(false)
	end

	if not isriding then
		if inst.player_classified then
			inst.player_classified.iscarefulwalking:set(true)
		end
	end

	if not inst.front_fx then
		inst.front_fx = SpawnPrefab("float_fx_front")
		inst.front_fx.entity:SetParent(inst.entity)
		inst.front_fx.Transform:SetPosition(0, high, 0)
		inst.front_fx.Transform:SetScale(scale, scale, scale)
		inst.front_fx.AnimState:PlayAnimation("idle_front_"..size, true)
	end

	if not inst.back_fx then
		inst.back_fx = SpawnPrefab("float_fx_back")
		inst.back_fx.entity:SetParent(inst.entity)
		inst.back_fx.Transform:SetPosition(0, high, 0)
		inst.back_fx.Transform:SetScale(scale, scale, scale)
		inst.back_fx.AnimState:PlayAnimation("idle_back_"..size, true)
	end

    inst.AnimState:SetFloatParams(0.3, 1.0, 0)
    inst.AnimState:SetDeltaTimeMultiplier(0.75)

	inst._waterdelta = inst:DoPeriodicTask(1, function()
		inst.components.moisture:DoDelta(1)
	end)
end

local function ExitWaterFn(inst)
	if inst:HasTag("playerghost") then
		inst.AnimState:SetBank("ghost")
		return
	end

	local isriding = inst.components.rider and inst.components.rider:IsRiding()

	if isriding then
		inst.AnimState:SetBank("wilsonbeefalo")
	end

	SpawnAt("splash_green", inst)

	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "waterspeed")

	if inst.DynamicShadow then
		inst.DynamicShadow:Enable(true)
	end

	if not isriding then
		if inst.player_classified then
			inst.player_classified.iscarefulwalking:set(false)
		end
	end

	if inst.front_fx then
		inst.front_fx:Remove()
		inst.front_fx = nil
	end

	if inst.back_fx then
		inst.back_fx:Remove()
		inst.back_fx = nil
	end

    inst.AnimState:SetFloatParams(0, 0, 0)
    inst.AnimState:SetDeltaTimeMultiplier(1)

	if inst._waketask then
		inst._waketask:Cancel()
		inst._waketask = nil
	end

	if inst._waterdelta then
		inst._waterdelta:Cancel()
		inst._waterdelta = nil
	end
end

return function(inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("amphibiouscreature")
	inst.components.amphibiouscreature:SetBanks("wilson", "wilson")
	inst.components.amphibiouscreature:SetEnterWaterFn(EnterWaterFn)         
	inst.components.amphibiouscreature:SetExitWaterFn(ExitWaterFn)

	inst:ListenForEvent("death", ExitWaterFn)
end
