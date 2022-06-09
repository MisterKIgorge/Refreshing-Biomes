require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/faceentity"
require "behaviours/standstill"

local FlytrapBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function FlytrapBrain:OnStart()
	
	local root = PriorityNode(
	{
		WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst) ),

		ChaseAndAttack(self.inst, 10),
        StandStill(self.inst),
		--Wander(self.inst, function() return self.inst:GetPosition() end, 15),

	}, .25)
	
	self.bt = BT(self.inst, root)
	
end

return FlytrapBrain
