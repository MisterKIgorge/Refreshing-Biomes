local menv = env
local AddPrefabPostInit = AddPrefabPostInit
local AddComponentPostInit = AddComponentPostInit
local AddClassPostInit = AddClassPostInit
local modimport = modimport
modimport("scripts/main/patches.lua")
local _G = GLOBAL
_G.setfenv(1, _G)
modimport("scripts/tunings.lua")


local _PlayFootstep = _G.PlayFootstep
function _G.PlayFootstep(inst, volume, ispredicted, ...)
	local sound = inst.SoundEmitter
	if sound then
        local my_platform = inst:GetCurrentPlatform()
		if not (my_platform and my_platform:HasTag("lilypad")) then
			return _PlayFootstep(inst, volume, ispredicted, ...)
		end
		
        local size_inst = inst
        if inst:HasTag("player") then
            local rider = inst.components.rider or inst.replica.rider
            if rider ~= nil and rider:IsRiding() then
                size_inst = rider:GetMount() or inst
            end
        end

		sound:PlaySound(
			(inst.sg and inst.sg:HasStateTag("running") and "dontstarve/movement/run_marsh" or "dontstarve/movement/walk_marsh"
			)..
			(   (size_inst:HasTag("smallcreature") and "_small") or
				(size_inst:HasTag("largecreature") and "_large" or "")
			),
			nil,
			volume or 1,
			ispredicted)	
	end
end
