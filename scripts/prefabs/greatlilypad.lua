local assets =
{
	Asset("ANIM", "anim/lily_pad.zip"),
}

local prefabs = {}

local function RemoveConstrainedPhysicsObj(physics_obj)
    if physics_obj:IsValid() then
        physics_obj.Physics:ConstrainTo(nil)
        physics_obj:Remove()
    end
end

local function AddConstrainedPhysicsObj(boat, physics_obj)
	physics_obj:ListenForEvent("onremove", function() RemoveConstrainedPhysicsObj(physics_obj) end, boat)

    physics_obj:DoTaskInTime(0, function()
		if boat:IsValid() then
			physics_obj.Transform:SetPosition(boat.Transform:GetWorldPosition())
   			physics_obj.Physics:ConstrainTo(boat.entity)
		end
	end)
end

local function OnDrown(inst, onload)
	local c = .075
	
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z, inst.radius, {"_inventoryitem"})
	
	inst.AnimState:SetMultColour(c,c,c,c)
	inst.AnimState:Hide("ripples")
	
	inst.components.walkableplatform.platform_radius = 0
	inst.components.walkableplatform.radius = 0
	
	if not onload then
		SpawnAttackWaves(inst:GetPosition(), nil, inst.radius - .25, 6, nil, 2.5, nil, 0.15)
		SpawnAttackWaves(inst:GetPosition(), nil, inst.radius - .5, 6, nil, 2.5, nil, 0.15)
	end
	
	for k, v in ipairs(ents) do
		if v and v.components.floater then
			v.components.floater:OnLandedServer()
		end
	end
	
	inst.components.timer:StartTimer("undrown", math.random(120, 300))
	
	inst.drowned = true
end

local function Appear(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z, inst.radius, {"_inventoryitem"})
	
	inst.AnimState:SetMultColour(1,1,1,1)
	inst.AnimState:Show("ripples")
	
	inst.components.walkableplatform.platform_radius = inst.radius
	inst.components.walkableplatform.radius = inst.radius
	
	SpawnAttackWaves(inst:GetPosition(), nil, inst.radius - .25, 6, nil, 2.5, nil, 0.15)
	SpawnAttackWaves(inst:GetPosition(), nil, inst.radius - .5, 6, nil, 2.5, nil, 0.15)
	
	for k, v in ipairs(ents) do
		if v and v.components.floater then
			v.components.floater:OnNoLongerLandedServer()
		end
	end
	
	inst.drowned = false
end

local function build_lilypad_collision_mesh(radius, height)
    local segment_count = 20
    local segment_span = math.pi * 2 / segment_count

    local triangles = {}
    local y0 = 0
    local y1 = height

    for segement_idx = 0, segment_count do

        local angle = segement_idx * segment_span
        local angle0 = angle - segment_span / 2
        local angle1 = angle + segment_span / 2

        local x0 = math.cos(angle0) * radius
        local z0 = math.sin(angle0) * radius

        local x1 = math.cos(angle1) * radius
        local z1 = math.sin(angle1) * radius
        
        table.insert(triangles, x0)
        table.insert(triangles, y0)
        table.insert(triangles, z0)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y1)
        table.insert(triangles, z1)
    end

	return triangles
end

local function lilypad_item_collision_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("CLASSIFIED")

    local phys = inst.entity:AddPhysics()
    phys:SetMass(1000)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.BOAT_LIMITS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.FLYERS)
    phys:CollidesWith(COLLISION.WORLD)
    phys:SetDontRemoveOnSleep(true)
	
	inst.SetTriangleMesh = function(inst, radius)
		phys:SetTriangleMesh(build_lilypad_collision_mesh(1.15 * radius, 3))
	end

    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function OnTimerDone(inst, data)
    if data.name == "undrown" then
		if inst.drowned then
			Appear(inst)
		end
    end
end

local function OnSave(inst, data)
	data.drowned = inst.drowned
end

local function OnLoad(inst, data)
	if data then
		if inst.drowned then
			OnDrown(inst, true)
		end
	end
end

function MakeLilyPad(name, radius, bank, build, anim)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.MiniMapEntity:SetIcon("boat.png")
		inst.entity:AddNetwork()

		inst:AddTag("ignorewalkableplatforms")
		inst:AddTag("antlion_sinkhole_blocker")
		inst:AddTag("boat")
		inst:AddTag("wood")
		inst:AddTag("lilypad")

		local phys = inst.entity:AddPhysics()
		phys:SetMass(TUNING.BOAT.MASS)
		phys:SetFriction(0)
		phys:SetDamping(5)
		phys:SetCollisionGroup(COLLISION.OBSTACLES)
		phys:ClearCollisionMask()
		phys:CollidesWith(COLLISION.WORLD)
		phys:CollidesWith(COLLISION.OBSTACLES)
		phys:SetDontRemoveOnSleep(true)           
		phys:SetCylinder(radius, 3)
	
		inst.AnimState:SetBank(bank)
		inst.AnimState:SetBuild(build)
		inst.AnimState:PlayAnimation(anim, true)
		inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
		inst.AnimState:SetFinalOffset(1)
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
	
		local color = math.min(1, math.random() + 0.5)
		inst.AnimState:SetMultColour(color, color, color, 1)    

		inst.radius = radius

		inst:AddComponent("walkableplatform")
		inst.components.walkableplatform.platform_radius = radius
		inst.components.walkableplatform.radius = radius
	
		inst.itemcollision = SpawnPrefab("lilypad_item_collision")
		inst.itemcollision:SetTriangleMesh(radius)
	
		AddConstrainedPhysicsObj(inst, inst.itemcollision)

		inst:AddComponent("waterphysics")
		inst.components.waterphysics.restitution = 1.75    

		inst.doplatformcamerazoom = net_bool(inst.GUID, "doplatformcamerazoom")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("timer")

		inst:AddComponent("hull")
		inst.components.hull:SetRadius(radius)

		inst:AddComponent("boatphysics")

		inst:DoTaskInTime(0, function()
			inst.components.boatphysics.boat_rotation_offset = math.random(0, 359)
		end)
		
		inst.OnDrown = OnDrown
		inst.OnUnDrown = Appear
		
		inst:ListenForEvent("timerdone", OnTimerDone)
		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
		
		return inst
	end

	return Prefab(name, fn, assets)
end


return MakeLilyPad("lilypad_small", 1.85, "lily_pad", "lily_pad", "small_idle"),
	MakeLilyPad("lilypad_medium", 2.35, "lily_pad", "lily_pad", "med_idle"),
	MakeLilyPad("lilypad_large", 4, "lily_pad", "lily_pad", "big_idle"),
	Prefab("lilypad_item_collision", lilypad_item_collision_fn)