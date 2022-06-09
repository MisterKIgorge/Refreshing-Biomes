local lava = resolvefilepath("images/colour_cubes/lavaarena2_cc.tex")
local cave = resolvefilepath("images/colour_cubes/caves_default.tex")

local lavacctable = {day = lava, dusk = lava, night = lava, full_moon = lava,}
local cavecctable = {day = cave, dusk = cave, night = cave, full_moon = cave,}

local SEASON_COLOURCUBES_LAVA = {
	autumn = lavacctable,
	winter = lavacctable,
	spring = lavacctable,
	summer = lavacctable,
}

local SEASON_COLOURCUBES_CAVE = {
	autumn = cavecctable,
	winter = cavecctable,
	spring = cavecctable,
	summer = cavecctable,
}

return function(self)
    local OnOverrideCCPhaseFn
    for i, v in ipairs(self.inst.event_listening["playeractivated"][TheWorld]) do
    	OnOverrideCCPhaseFn = UpvalueHacker.GetUpvalue(v, "OnOverrideCCPhaseFn")
    	if OnOverrideCCPhaseFn then
    		break
    	end
    end
    if not OnOverrideCCPhaseFn then return end

    local _OnPlayerActivated = UpvalueHacker.GetUpvalue(OnOverrideCCPhaseFn, "OnPlayerActivated")
    local _UpdateAmbientCCTable = UpvalueHacker.GetUpvalue(OnOverrideCCPhaseFn, "UpdateAmbientCCTable")
    local _SEASON_COLOURCUBES = UpvalueHacker.GetUpvalue(_UpdateAmbientCCTable, "SEASON_COLOURCUBES")

    local _player
    local _isLavaCC = false
	local _isCaveCC = false
    local function UpdateAmbientCCTable(blendtime, data)
    	if _player then
            if data ~= nil and data.cave then
        		if not _isCaveCC then
        			_isCaveCC = true
					_isLavaCC = false
					UpvalueHacker.SetUpvalue(_UpdateAmbientCCTable, SEASON_COLOURCUBES_CAVE, "SEASON_COLOURCUBES")
				end
			elseif data ~= nil and data.lava then
				if not _isLavaCC then
        			_isLavaCC = true
					_isCaveCC = false
					UpvalueHacker.SetUpvalue(_UpdateAmbientCCTable, SEASON_COLOURCUBES_LAVA, "SEASON_COLOURCUBES")
				end
			elseif _isLavaCC or _isCaveCC then
        		_isLavaCC = false
				_isCaveCC = false
        		UpvalueHacker.SetUpvalue(_UpdateAmbientCCTable, _SEASON_COLOURCUBES, "SEASON_COLOURCUBES")
        	end
        end
    	
    	return _UpdateAmbientCCTable(blendtime)
    end

    UpvalueHacker.SetUpvalue(OnOverrideCCPhaseFn, UpdateAmbientCCTable, "UpdateAmbientCCTable")

    local function CaveChandeDirty(inst, data)
    	UpdateAmbientCCTable(1, data)
    end
    self.inst:ListenForEvent("playeractivated", function(src, player)
    	if player and _player ~= player then
    		player:ListenForEvent("onchangecavezone", CaveChandeDirty)
    		player:DoTaskInTime(0, function()
				local x, y, z = player.Transform:GetWorldPosition()
				local node, node_index = TheWorld.Map:FindVisualNodeAtPoint(x, y, z)
				local data =
				{
					cave = node and node.tags and table.contains(node.tags, "Cave") or false,
					lava = node and node.tags and table.contains(node.tags, "LavaCave") or false,
				}
				player:PushEvent("onchangecavezone", data)
			end)
    	end
    	_player = player
    end)
    self.inst:ListenForEvent("playerdeactivated", function(src, player)
    	if player then
    		player:RemoveEventCallback("onchangecavezone", CaveChandeDirty)
    		if _player == player then
    			_player = nil
    		end
    	end
    end)
end
