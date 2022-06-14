local seg_time = 30
local total_day_time = seg_time*16

local day_segs = 10
local dusk_segs = 4
local night_segs = 2

--default day composition. changes in winter, etc
local day_time = seg_time * day_segs
local dusk_time = seg_time * dusk_segs
local night_time = seg_time * night_segs

TUNING.MOSQUITOSWARM_GROWTH = {
	OFFSPRING_TIME = total_day_time * 5,
	DESOLATION_RESPAWN_TIME = total_day_time * 50,
	DEAD_DECAY_TIME = total_day_time * 30,
}

TUNING.MOSQUITOSWARM_COCOON_GROW_TIME =
{
	{base=1.5*day_time, random=0.5*day_time},   --short
	{base=5*day_time, random=2*day_time},   --normal
	{base=5*day_time, random=2*day_time},   --tall
	{base=1*day_time, random=0.5*day_time}   --old
}

TUNING.MOSQUITOSWARM_RESTOCK = 15

TUNING.FUMEAGATOR_TARGETRANGE = 12
TUNING.FUMEAGATOR_DAMAGE = 50
TUNING.FUMEAGATOR_HEALTH = 1200
TUNING.FUMEAGATOR_ATTACKRANGE = 3.5
TUNING.FUMEAGATOR_ATTACKPERIOD = 2.5
TUNING.FUMEAGATOR_FUMEPERIOD = 20