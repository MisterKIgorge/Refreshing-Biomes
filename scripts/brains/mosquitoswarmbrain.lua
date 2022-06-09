require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/findlight"
require "behaviours/follow"
require "behaviours/chaseandattack"

local MAX_WANDER_DIST = 20
local AGRO_DIST = 5
local AGRO_STOP_DIST = 7

local function FindCombineTarget(inst, brain)  
	if inst.components.timer:TimerExists("cantcombine") then
		return
	end
	 
	if inst:HasTag("swarm_lvl1") then
		local target = GetClosestInstWithTag("swarm_lvl1", inst, 5)
		local target2 = GetClosestInstWithTag("swarm_lvl2", inst, 5)
		
		if target then
			return target
		end
		
		if target2 then
			return target2
		end		
	end
	
	if inst:HasTag("swarm_lvl2") then
		local target = GetClosestInstWithTag("swarm_lvl1", inst, 5)
		
		if target then
			return target
		end

		return  
	end
	return
end

local function CombineSwarms(inst,brain)   
	if inst.components.timer:TimerExists("cantcombine") then
		return
	end
	  
	if inst:HasTag("swarm_lvl1") then
		local target = GetClosestInstWithTag("swarm_lvl1", inst, 5)
		local target2 = GetClosestInstWithTag("swarm_lvl2", inst, 5)
		
		if target then
			return BufferedAction(inst, target, ACTIONS.SWARMATTACH)
		end
		
		if target2 then
			return BufferedAction(inst, target2, ACTIONS.SWARMATTACH)
		end		
	end
	
	if inst:HasTag("swarm_lvl2") then
		local target = GetClosestInstWithTag("swarm_lvl1", inst, 5)
		
		if target then
			return BufferedAction(inst, target, ACTIONS.SWARMATTACH)
		end

		return  
	end
	return
end

local function findinfesttarget(inst,brain)    
	local target = GetClosestInstWithTag("player", inst, 5)
	
	if target and not inst.attachedentity and not target:HasTag("infested") then
		return target
	end
	
	return  
end

local function infestplayer(inst,brain)    
	local target = GetClosestInstWithTag("player", inst, 1)
	
	if target and not inst.attachedentity and not target:HasTag("infested") then
		return BufferedAction(inst, target, ACTIONS.SWARMATTACH)
    end
	
    return false
end

local function DoDamage(inst,brain)    
	local target = inst.attachedentity
	
	if target then
		return BufferedAction(inst, target, ACTIONS.ATTACK)
    end
	
    return false
end

local function findlight(inst)
    local targetDist = 15
    local notags = {"FX", "NOCLICK","INLIMBO"}
	local light = FindEntity(inst, targetDist, 
        function(guy) 
            if guy.Light and guy.Light:IsEnabled() and guy:HasTag("lightsource") then
                return true
            end
    end, nil, notags)

    return light
end

local function findlighttarget(inst)
    local light = findlight(inst)
    if light then
        return light
    end
end

local function makenest(inst)
    if not inst.components.homeseeker and not inst.makehome then
	
		if TheWorld.Map:IsPassableAtPoint(inst.Transform:GetWorldPosition()) then
			inst.makehometime = inst:DoTaskInTime(5 * (0.5 + (math.random()*0.5) ), function() --
                inst.makehome = true
            end)
		end
	end
	
    if inst.makehome and not inst.components.homeseeker then       
        --return BufferedAction(inst, nil, ACTIONS.SPECIAL_ACTION)
    end
	return
end

local function FindLily(inst, brain)  
	if inst:HasTag("swarm_lvl3") and inst:HasTag("wanttococoon") then
		local target = GetClosestInstWithTag("lilypad", inst, 5)
		
		if target then
			return target
		end
	end

	return
end

local function SpawnCocoon(inst,brain)    
	local target = GetClosestInstWithTag("lilypad", inst, 5)
	
	if target and inst:HasTag("wanttococoon") then
		return BufferedAction(inst, target, ACTIONS.SWARMATTACH)
    end
	
    return false
end

local GnatBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function GnatBrain:OnStart()
    
    local root =
        PriorityNode(
        {
            WhileNode( function() return not self.inst.attachedentity end, "no entity",
            PriorityNode{            
                WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", 
                    Panic(self.inst) ),
				WhileNode( function() return  TheWorld.state.isdusk or TheWorld.state.isnight end, "chase light",  Follow(self.inst, function() return findlighttarget(self.inst) end, 0, 1, 1) ),
				WhileNode( function() return  findinfesttarget end, "chase player",  Follow(self.inst, function() return findinfesttarget(self.inst) end, 0, 1, 1) ),
				WhileNode( function() return  FindCombineTarget end, "chase swarm",  Follow(self.inst, function() return FindCombineTarget(self.inst) end, 0, 1, 1) ),
				WhileNode( function() return  FindLily end, "chase lily",  Follow(self.inst, function() return FindLily(self.inst) end, 0, 1, 1) ),
        
                DoAction(self.inst, function() return infestplayer(self.inst,self) end, "infest", true),
                DoAction(self.inst, function() return CombineSwarms(self.inst,self) end, "combine", true),
                DoAction(self.inst, function() return SpawnCocoon(self.inst,self) end, "cocoon", true),
                DoAction(self.inst, function() return makenest(self.inst) end, "make nest", true),                          
                Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST)
            },.5),
            WhileNode( function() return self.inst.attachedentity end, "entity exists",
            PriorityNode{            
				ChaseAndAttack(self.inst, 10, 10),
            },.5)
        },1)
    
    
    self.bt = BT(self.inst, root)
    
         
end

return GnatBrain