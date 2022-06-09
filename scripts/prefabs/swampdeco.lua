local function MakeDeco(name, bank, build, anim, canfloat, data) 
	local assets =
	{
		Asset("ANIM", "anim/"..build..".zip"),
	}

	local prefabs = {}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(bank)	
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation(anim,true)

		local color = math.min(1, math.random() + 0.5)
        inst.AnimState:SetMultColour(color, color, color, 1)    

		if data and data.faced == "four" then
			inst.Transform:SetFourFaced()
		end
		
		if canfloat then
			MakeInventoryFloatable(inst, "small", 0.1, {1.1, 0.9, 1.1})
			inst.components.floater.bob_percent = 0

			local land_time = (POPULATING and math.random()*5*FRAMES) or 0
			inst:DoTaskInTime(land_time, function(inst)
				inst.components.floater:OnLandedServer()
			end)
		end
		
		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		if data and data.canbepicked then
			inst:AddComponent("pickable")
			inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
			if type(data.loot) == "table" then
				inst.components.pickable:SetUp(data.loot[math.random(1, #data.loot)], 1)
			end
			inst.components.pickable.onpickedfn = function() inst:Remove() end
		end
		
		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return MakeDeco("swamp_root1", "roc_junk", "roc_junk", "tree1", true),
		MakeDeco("swamp_root2", "roc_junk", "roc_junk", "tree2", true),
		MakeDeco("swamp_bush", "roc_junk", "roc_junk", "bush"), --?
		MakeDeco("swamp_bushdebris", "roc_junk", "roc_junk", "bush_debris", nil, {canbepicked = true, loot = {"petals", "cutgrass"}}), --?
		MakeDeco("swamp_branch1", "roc_junk", "roc_junk", "branch1", true),
		MakeDeco("swamp_branch2", "roc_junk", "roc_junk", "branch2", true),
		MakeDeco("swamp_trunk", "roc_junk", "roc_junk", "trunk", true),

		MakeDeco("swamp_debris1", "roc_junk", "roc_junk", "stick01", nil, {canbepicked = true, loot = {"twigs"}, faced = "four"}),
		MakeDeco("swamp_debris2", "roc_junk", "roc_junk", "stick02", nil, {canbepicked = true, loot = {"twigs"}, faced = "four"}),
		MakeDeco("swamp_debris3", "roc_junk", "roc_junk", "stick03", nil, {canbepicked = true, loot = {"twigs"}, faced = "four"}),
		MakeDeco("swamp_debris4", "roc_junk", "roc_junk", "stick04", nil, {canbepicked = true, loot = {"twigs"}, faced = "four"}),
		MakeDeco("swamp_fern", "fern2_plant", "fern2_plant", "idle", true)
