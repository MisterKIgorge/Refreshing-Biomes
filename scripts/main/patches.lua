local _G = GLOBAL
local env = env
local AddClassPostConstruct = AddClassPostConstruct
local AddStategraphPostInit = AddStategraphPostInit
local AddPlayerPostInit = AddPlayerPostInit
local AddPrefabPostInit = AddPrefabPostInit
local AddComponentPostInit = AddComponentPostInit
local AddStategraphState = AddStategraphState
local AddGlobalClassPostConstruct = AddGlobalClassPostConstruct
_G.setfenv(1, _G)

local GenericPlayerFn = require("patches/prefabs/player")

local PATCHES = 
{
	COMPONENTS = {
		"amphibiouscreature",
		"wavemanager",
		"colourcube",
	},
	
	PREFABS = {
		world = "world",
	},
	
	SCREENS = {
	},

	WIDGETS = {},
	STATEGRAPHS = {},
}

local function patch(prefab, fn)
	AddPrefabPostInit(prefab, fn)
end
	
for path, data in pairs(PATCHES.PREFABS) do
	local fn = require("patches/prefabs/"..path)
	
	if type(data) == "string" then
		patch(data, function(inst) fn(inst, data) end)
	else
		for _, pref in ipairs(data) do
			patch(pref, function(inst) fn(inst, pref) end)
		end
	end
end

AddPlayerPostInit(GenericPlayerFn)

for _, name in ipairs(PATCHES.STATEGRAPHS) do
	AddStategraphPostInit(name, require("patches/stategraphs/"..name))
end

for _, file in ipairs(PATCHES.COMPONENTS) do
	local fn = require("patches/components/"..file)
	AddComponentPostInit(file, fn)
end

for _, file in ipairs(PATCHES.SCREENS) do
	local fn = require("patches/screens/"..file)
	AddClassPostConstruct("screens/"..file, fn)
end

for _, file in ipairs(PATCHES.WIDGETS) do
	local fn = require("patches/widgets/"..file)
	AddClassPostConstruct("widgets/"..file, fn)
end

local _IsOceanTile = IsOceanTile
function IsOceanTile(tile)
	return FAKEOCEANTILES[tile] or _IsOceanTile
end

local _IsLandTile = IsLandTile
function IsLandTile(tile)
	return not FAKEOCEANTILES[tile] or _IsLandTile
end