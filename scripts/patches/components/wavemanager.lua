local NotCoastal = {
	[GROUND.SWAMP_FLOOD] = true,
}

local function IsNotMarshFloodTile(tile)
	return tile ~= GROUND.SWAMP_FLOOD
end

local function IsSurroundedByMarsh(x, y, radius)
	for i = -radius, radius, 1 do
		if not IsNotMarshFloodTile(TheWorld.Map:GetTile(x - radius, y + i)) or not IsNotMarshFloodTile(TheWorld.Map:GetTile(x + radius, y + i)) then
			return true
		end
	end
	for i = -(radius - 1), radius - 1, 1 do
		if not IsNotMarshFloodTile(TheWorld.Map:GetTile(x + i, y - radius)) or not IsNotMarshFloodTile(TheWorld.Map:GetTile(x + i, y + radius)) then
			return true
		end
	end
	return false
end

local function checkground(inst, map, x, y, z, ground)
	local is_ground = map:GetTileAtPoint( x, y, z ) == ground
	if not is_ground then return false end

    local iswrongtile = false
	for _z = 1, -1, -1 do
	    for _x = -1, 1 do
			local tile = map:GetTileAtPoint(x+_x*TILE_SCALE, 0, z+_z*TILE_SCALE)
			if not NotCoastal[tile] then
				iswrongtile = true
				break
			end
		end
	end
	if iswrongtile then
		return false
	end
	return map:IsValidTileAtPoint( x, y, z )
end

local function IsFlooded(x, y, z)
	local actual_tile = TheWorld.Map:GetTile(x, z)
	if actual_tile == GROUND.SWAMP then
		return true
	end
	return false
end

local function GetWaveBearing(ex, ey, ez, lines)
	local offs =
	{
		{-2,-2}, {-1,-2}, {0,-2}, {1,-2}, {2,-2},
		{-2,-1}, {-1,-1}, {0,-1}, {1,-1}, {2,-1},
		{-2, 0}, {-1, 0},		  {1, 0}, {2, 0},
		{-2, 1}, {-1, 1}, {0, 1}, {1, 1}, {2, 1},
		{-2, 2}, {-1, 2}, {0, 2}, {1, 2}, {2, 2}
	}

	local map = TheWorld.Map
	local width, height = map:GetSize()
	local halfw, halfh = 0.5 * width, 0.5 * height
	local x, y = map:GetTileXYAtPoint(ex, ey, ez)
	local xtotal, ztotal, n = 0, 0, 0
	for i = 1, #offs, 1 do
		local ground = map:GetTile( x + offs[i][1], y + offs[i][2] )
		if IsNotMarshFloodTile(ground) then
			xtotal = xtotal + ((x + offs[i][1] - halfw) * TILE_SCALE)
			ztotal = ztotal + ((y + offs[i][2] - halfh) * TILE_SCALE)
			n = n + 1
		end
	end

	local bearing = nil
	if n > 0 then
		local a = math.atan2(ztotal/n - ez, xtotal/n - ex)
		bearing = -a/DEGREES - 90
	end

	return bearing
end

local function SpawnWaveFlood(inst, x, y, z)
	local is_surrounded_by_marsh = IsSurroundedByMarsh(x, y, z, 4.5)
	local wave = SpawnPrefab( "wave_shimmer_flood" )
	wave.Transform:SetPosition( x, y, z )
	wave.AnimState:SetAddColour(1,1,1,1)

	if is_surrounded_by_marsh then
		local wave = SpawnPrefab( "wave_shimmer" )
		wave.Transform:SetPosition( x, y, z )
	else
		local is_nearby_ground = not IsSurroundedByMarsh(x, y, z, 3.5)
		if is_nearby_ground then
			local bearing = GetWaveBearing(x, y, z)
			if bearing then
				local wave_shore = SpawnPrefab( "wave_shore")
				wave_shore.Transform:SetPosition( x, y, z )
				wave_shore.Transform:SetRotation(bearing)
				wave_shore.AnimState:SetAddColour(1,1,1,1)
				wave_shore:SetAnim()
			end
		end
	end
end

return function(self)
    self.shimmer[GROUND.SWAMP_FLOOD] = {per_sec = 80, spawn_rate = 0, checkfn = checkground, spawnfn = SpawnWaveFlood}
end
