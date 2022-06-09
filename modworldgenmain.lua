local _G = GLOBAL
_G.UpvalueHacker = require("tools/upvaluehacker")
local rawget = _G.rawget
local rawset = _G.rawset

mods = rawget(_G, "mods")
if not mods then
	mods = {}
	rawset(_G, "mods", mods)
end
env.mods = mods

modimport("scripts/main/tiles.lua")

local menv = env
GLOBAL.setfenv(1, GLOBAL)
