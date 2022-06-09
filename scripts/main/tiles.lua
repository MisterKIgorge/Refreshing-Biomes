modimport("scripts/tools/tile_adder.lua")

local function GetAvailableTileKey(ocean) --What's the next available number we can choose to make our tile ID?
	local GROUND_INVERTED = table.invert(GROUND)
	if ocean then
		for i = 231, 247 do
			if GROUND_INVERTED[i] == nil then
				return i
			end
		end
	else
		for i = 70, 89 do
			if GROUND_INVERTED[i] == nil then
				return i
			end
		end
	end
end

AddTile("SWAMP", GetAvailableTileKey(false), "deciduous",
	{
		noise_texture = "levels/textures/Ground_noise_swamp.tex",
		runsound = "dontstarve/movement/run_marsh",
		walksound = "dontstarve/movement/walk_marsh",
		snowsound = "dontstarve/movement/run_ice",
		mudsound = "dontstarve/movement/run_mud",
	},
	{noise_texture = "levels/textures/Ground_noise_swamp.tex"}
)

AddTile("SWAMP_FLOOD", GetAvailableTileKey(false), "marsh_pond",
	{
		noise_texture = "levels/textures/Ground_noise_swamp_water.tex",
		runsound = "turnoftides/common/together/water/swim/run_water_med",
		walksound = "turnoftides/common/together/water/swim/walk_water_med",
		snowsound = "turnoftides/common/together/water/swim/walk_water_med",
		mudsound = "turnoftides/common/together/water/swim/walk_water_med",
	},
	{noise_texture = "levels/textures/Ground_noise_swamp_water.tex"}
)

ChangeTileTypeRenderOrder(GROUND.SWAMP_FLOOD, GROUND.CARPET, false)
ChangeTileTypeRenderOrder(GROUND.SWAMP, GROUND.ROAD, false)
