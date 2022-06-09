local WALKABLE_PLATFORM_TAGS = {"walkableplatform"}

return function(inst)
	local map = getmetatable(inst.Map).__index
	if map then
		local _IsAboveGroundAtPoint =	map.IsAboveGroundAtPoint
		map.IsAboveGroundAtPoint = function(self, x, y, z, allow_water, ...)
			if not allow_water and FAKEOCEANTILES[self:GetTileAtPoint(x, y, z)] then
				return false
			end
			return _IsAboveGroundAtPoint(self, x, y, z, allow_water, ...)
		end

		local _IsVisualGroundAtPoint = map.IsVisualGroundAtPoint
		map.IsVisualGroundAtPoint = function(self, x, y, z, ...)
			if FAKEOCEANTILES[self:GetTileAtPoint(x, y, z)] then
				return false
			end
			return _IsVisualGroundAtPoint(self, x, y, z, ...)
		end
		--local x,y,z = ThePlayer.Transform:GetWorldPosition() print(TheWorld.Map:IsOceanTileAtPoint(x,y,z))
		local _IsOceanTileAtPoint =	map.IsOceanTileAtPoint
		map.IsOceanTileAtPoint = function(self, x, y, z, ...)
			if FAKEOCEANTILES[self:GetTileAtPoint(x, y, z)] then
				return true
			end
			return _IsOceanTileAtPoint(self, x, y, z, ...)
		end

		local _IsOceanAtPoint =	map.IsOceanAtPoint
		map.IsOceanAtPoint = function(self, x, y, z, allow_boats, ...)
			if FAKEOCEANTILES[self:GetTileAtPoint(x, y, z)] then
				return (allow_boats or self:GetPlatformAtPoint(x, z) == nil)
			end
			return _IsOceanAtPoint(self, x, y, z, allow_boats, ...)
		end

		--this is not the best implementation... but oh well *shrug*
		local _CalcPercentOceanTilesAtPoint = map.CalcPercentOceanTilesAtPoint
		map.CalcPercentOceanTilesAtPoint = function(self, x, y, z, r, ...)
			local percent = _CalcPercentOceanTilesAtPoint(self, x, y, z, r, ...)

			local numWaterTiles = 0
			local totalTiles = 0

			--X direction
			for i = -r, r, 4 do
				--z direction
				for j = -r, r, 4 do
					totalTiles = totalTiles + 1
					if TheWorld.Map:GetTileAtPoint(x + i, y, z + j) == GROUND.SWAMP_FLOOD then
						numWaterTiles = numWaterTiles + 1
					end
				end
			end

			return ((numWaterTiles/totalTiles) + percent)
		end

		local _CanDeployPlantAtPoint = map.CanDeployPlantAtPoint
		map.CanDeployPlantAtPoint = function(self, pt, inst)
			if self:GetPlatformAtPoint(pt.x, pt.z) ~= nil then
				return false
			end

			if self:IsOceanTileAtPoint(pt.x, pt.y, pt.z) then
				if FAKEOCEAN_CAN_DEPLOY[inst.prefab] then
					return self:IsDeployPointClear(pt, inst, inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:DeploySpacingRadius() or DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT])
				end
				return false
			end

			return _CanDeployPlantAtPoint(self, pt, inst)
		end

		local IsNearOtherWallOrPlayerFN = UpvalueHacker.GetUpvalue(map.CanDeployWallAtPoint, "IsNearOtherWallOrPlayer")
		local _CanDeployWallAtPoint = map.CanDeployWallAtPoint
		map.CanDeployWallAtPoint = function(self, pt, inst, ...)
			pt = Vector3(math.floor(pt.x) + 0.5, pt.y, math.floor(pt.z) + 0.5)
			local x,y,z = pt:Get()

			if self:IsOceanAtPoint(x, y, z, false) and FAKEOCEAN_CAN_DEPLOY[inst.prefab] then
				return self:IsDeployPointClear(pt, inst, 1, nil, IsNearOtherWallOrPlayerFN, false)
			end

			return _CanDeployWallAtPoint(self, pt, inst, ...)
		end

		local _CanDeployAtPoint = map.CanDeployAtPoint
		map.CanDeployAtPoint = function(self, pt, inst, mouseover, ...)
			if self:IsOceanAtPoint(pt.x, pt.y, pt.z, false) and FAKEOCEAN_CAN_DEPLOY[inst.prefab] then
				return (mouseover == nil or mouseover:HasTag("player") or mouseover:HasTag("walkableplatform"))
        			and self:IsDeployPointClear(pt, inst, inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:DeploySpacingRadius() or DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT])
			end

			return _CanDeployAtPoint(self, pt, inst, mouseover, ...)
		end

		local _CanDeployRecipeAtPoint = map.CanDeployRecipeAtPoint
		map.CanDeployRecipeAtPoint = function(self, pt, recipe, rot, ...)
			if self:IsOceanAtPoint(pt.x, pt.y, pt.z, false) and FAKEOCEAN_CAN_DEPLOY[recipe.name] then
				return (recipe.testfn == nil or recipe.testfn(pt, rot))
        			and self:IsDeployPointClear(pt, nil, recipe.min_spacing or 3.2)
			end

			return _CanDeployRecipeAtPoint(self, pt, recipe, rot, ...)
		end
		local _GetPlatformAtPoint = map.GetPlatformAtPoint
		map.GetPlatformAtPoint = function(self, pos_x, pos_y, pos_z, extra_radius)
			if pos_z == nil then
				pos_z = pos_y
				pos_y = 0
			end
			local entities = TheSim:FindEntities(pos_x, pos_y, pos_z, TUNING.MAX_WALKABLE_PLATFORM_RADIUS + (extra_radius or 0), WALKABLE_PLATFORM_TAGS)
			for i, v in ipairs(entities) do
				if v ~= nil and math.sqrt(v:GetDistanceSqToPoint(pos_x, 0, pos_z)) <= v.components.walkableplatform.platform_radius then
					return v 
				end
			end
			return nil --_GetPlatformAtPoint(Map, pos_x, pos_y, pos_z, extra_radius)
		end


		--local _CanTerraformAtPoint = map.CanTerraformAtPoint
		--map.CanTerraformAtPoint = function(self, x, y, z, ...)
		--	local tile = self:GetTileAtPoint(x, y, z)
		--	if tile == GROUND.DINOICE then
		--		return false
		--	end

		--	return _CanTerraformAtPoint(self, x, y, z, ...)
		--end
	end

    if not inst.ismastersim then
	    return
	end
end
