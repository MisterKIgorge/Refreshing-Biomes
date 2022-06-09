local CANOPY_SHADOW_DATA = require("prefabs/canopyshadows")
local SHADE_RANGE = TUNING.SHADE_CANOPY_RANGE*2.5
local assets =
{
    Asset("ANIM", "anim/oceantree_pillar_build1.zip"),
    Asset("ANIM", "anim/oceantree_pillar_build2.zip"),
    Asset("ANIM", "anim/oceantree_pillar.zip"),
    Asset("SOUND", "sound/tentacle.fsb"),
    Asset("MINIMAP_IMAGE", "oceantree_pillar"),
    Asset("SCRIPT", "scripts/prefabs/canopyshadows.lua")
}

local prefabs = 
{
    "oceantreenut",
}

local small_ram_products =
{
    "twigs",
    "cutgrass",
    "oceantree_leaf_fx_fall",
    "oceantree_leaf_fx_fall",
}

local ram_products_to_refabs = {}
for _, v in ipairs(small_ram_products) do
    ram_products_to_refabs[v] = true
end
for k, v in pairs(ram_products_to_refabs) do
    table.insert(prefabs, k)
end

local MIN = SHADE_RANGE
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER

local DROP_ITEMS_DIST_MIN = 8
local DROP_ITEMS_DIST_VARIANCE = 12

local NUM_DROP_SMALL_ITEMS_MIN = 10
local NUM_DROP_SMALL_ITEMS_MAX = 14

local DROPPED_ITEMS_SPAWN_HEIGHT = 10

local function removecanopyshadow(inst)
    if inst.canopy_data ~= nil then
        for _, shadetile_key in ipairs(inst.canopy_data.shadetile_keys) do
            if TheWorld.shadetiles[shadetile_key] ~= nil then
                TheWorld.shadetiles[shadetile_key] = TheWorld.shadetiles[shadetile_key] - 1

                if TheWorld.shadetiles[shadetile_key] <= 0 then
                    if TheWorld.shadetile_key_to_leaf_canopy_id[shadetile_key] ~= nil then
                        DespawnLeafCanopy(TheWorld.shadetile_key_to_leaf_canopy_id[shadetile_key])
                        TheWorld.shadetile_key_to_leaf_canopy_id[shadetile_key] = nil
                    end
                end
            end
        end

        for _, ray in ipairs(inst.canopy_data.lightrays) do
            ray:Remove()
        end
    end
end

local function OnFar(inst, player)
    if player.canopytrees then   
        player.canopytrees = player.canopytrees - 1
    end
    inst.players[player] = nil
end

local function OnNear(inst,player)
    inst.players[player] = true

    player.canopytrees = (player.canopytrees or 0) + 1
end

local function OnTimerDone(inst, data)
    if data ~= nil then

    end
end

local function DropLightningItems(inst, items)
    local x, _, z = inst.Transform:GetWorldPosition()
    local num_items = #items

    for i, item_prefab in ipairs(items) do
        local dist = DROP_ITEMS_DIST_MIN + DROP_ITEMS_DIST_VARIANCE * math.random()
        local theta = 2 * PI * math.random()

        inst:DoTaskInTime(i * 5 * FRAMES, function(inst2)
            local item = SpawnPrefab(item_prefab)
            item.Transform:SetPosition(x + dist * math.cos(theta), 20, z + dist * math.sin(theta))

            if i == num_items then
                inst._lightning_drop_task:Cancel()
                inst._lightning_drop_task = nil
            end 
        end)
    end
end

local function OnLightningStrike(inst)
    if inst._lightning_drop_task ~= nil then
        return
    end

    local num_small_items = math.random(NUM_DROP_SMALL_ITEMS_MIN, NUM_DROP_SMALL_ITEMS_MAX)
    local items_to_drop = {}

    for i = 1, num_small_items do
        table.insert(items_to_drop, small_ram_products[math.random(1, #small_ram_products)])
    end

    inst._lightning_drop_task = inst:DoTaskInTime(20*FRAMES, DropLightningItems, items_to_drop)
end

local function OnSave(inst, data)

end

local function OnLoad(inst, data)
    if data then

    end
end

local function removecanopy(inst)
    for player in pairs(inst.players) do
        if player:IsValid() then
            if player.canopytrees then
                player.canopytrees = player.canopytrees - 1
            end
        end
    end

    inst._hascanopy:set(false)
end

local function OnRemove(inst)
    removecanopy(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeWaterObstaclePhysics(inst, 4, 2, 0.75)

    inst:SetDeployExtraSpacing(TUNING.MAX_WALKABLE_PLATFORM_RADIUS + 4)

    -- HACK: this should really be in the c side checking the maximum size of the anim or the _current_ size of the anim instead
    -- of frame 0
    inst.entity:SetAABB(60, 20)

    inst:AddTag("shadecanopy")

    inst.MiniMapEntity:SetIcon("oceantree_pillar.png")

    inst.AnimState:SetBank("oceantree_pillar")
    inst.AnimState:SetBuild("oceantree_pillar_build1")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:AddOverrideBuild("oceantree_pillar_build2")

    if not TheNet:IsDedicated() then
        inst:AddComponent("distancefade")
        inst.components.distancefade:Setup(15,25)
    end

    inst._hascanopy = net_bool(inst.GUID, "oceantree_pillar._hascanopy", "hascanopydirty")
    inst._hascanopy:set(true)  
    inst:ListenForEvent("hascanopydirty", function()
		if not inst._hascanopy:value() then 
			removecanopyshadow(inst) 
		end
	end)

    inst:DoTaskInTime(0,function()
        inst.canopy_data = CANOPY_SHADOW_DATA.spawnshadow(inst, math.floor(SHADE_RANGE/4))
    end)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.players = {}
   
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(MIN, MAX)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:AddComponent("lightningblocker")
    inst.components.lightningblocker:SetBlockRange(SHADE_RANGE)
    inst.components.lightningblocker:SetOnLightningStrike(OnLightningStrike)

    inst:ListenForEvent("timerdone", OnTimerDone)
    inst:ListenForEvent("onremove", OnRemove)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end


return Prefab("greateswamptree", fn, assets, prefabs)