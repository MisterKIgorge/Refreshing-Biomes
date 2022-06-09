local JUMP_DIST = 6

return function(self)
	local _ShouldTransition = self.ShouldTransition
	function self:ShouldTransition(...)
		if self.inst:HasTag("player") and _ShouldTransition(self, ...) then
			return 
		end
		return _ShouldTransition(self, ...)
	end
end
