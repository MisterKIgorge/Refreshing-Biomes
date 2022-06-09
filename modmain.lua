-- General Dependencies.
local env = env
local AddReplicableComponent = AddReplicableComponent
local AddStategraphState = AddStategraphState
local AddPrefabPostInit = AddPrefabPostInit
local AddComponentPostInit = AddComponentPostInit
local modimport = modimport

local AddAction = AddAction
local AddStategraphActionHandler = AddStategraphActionHandler
local AddComponentAction = AddComponentAction

GLOBAL.UpvalueHacker = require("tools/upvaluehacker")
GLOBAL.FAKEOCEANTILES = {
	[GROUND.SWAMP_FLOOD] = true,
}

GLOBAL.FAKEOCEAN_CAN_DEPLOY =
{
	["dug_grass"] = true,
}

GLOBAL.setfenv(1, GLOBAL)

modimport("scripts/main.lua")
modimport("scripts/to_load.lua")

-- Dev Mode.
if not env.MODROOT:find("workshop-") then
	CHEATS_ENABLED = true
	require("debugkeys")
end

require("actions")

local SWARMATTACH = AddAction("SWARMATTACH", "Attach", function(act)
	if not act then
		return false
	end
	local target = act.target 
	if target:HasTag("player") and not target:HasTag("infested") then
		act.doer:AttachToEntity(target)
		return true
	elseif target:HasTag("mosquitoswarm") then
		act.doer:CombineSwarms(target)
		target:Remove()
		return true
	elseif target:HasTag("lilypad") then
		return true
	end
	return false
end)
SWARMATTACH.mindistance = 1

