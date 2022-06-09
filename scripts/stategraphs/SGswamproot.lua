require("stategraphs/commonstates")

local actionhandlers =
{
}

local events=
{
	EventHandler("attacked", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("busy") then inst.sg:GoToState("hit") end end),
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
	EventHandler("doattack", function(inst, data) if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then inst.sg:GoToState("attack_pre", data.target) end end),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnLocomote(true,false),
	CommonHandlers.OnFreeze(),
}

local function SpawnMoveFx(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local prefab = "mole_move_fx"
    if not TheWorld.Map:IsVisualGroundAtPoint(x,y,z) then
		prefab = "splash"
	end
	SpawnPrefab(prefab).Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.components.floater:OnLandedServer()
end

local states=
{

    State{
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("breach_pre")
            if inst.AnimState:AnimDone() or inst.AnimState:GetCurrentAnimationLength() == 0 then
                inst.sg:GoToState("run")
            else
                inst.components.locomotor:RunForward()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("breach_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline =
        {
            TimeEvent(0*FRAMES,  SpawnMoveFx),
            TimeEvent(5*FRAMES,  SpawnMoveFx),
            TimeEvent(10*FRAMES, SpawnMoveFx),
            TimeEvent(15*FRAMES, SpawnMoveFx),
            TimeEvent(20*FRAMES, SpawnMoveFx),
            TimeEvent(25*FRAMES, SpawnMoveFx),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation("atk_idle", true)
			else
				inst.AnimState:PlayAnimation("atk_idle", true)
			end
		end,

	timeline=
		{
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/breath_out") end),
			TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/venus_flytrap/4/breath_in") end),
		},
	},


    State{
        name ="attack_pre",
        tags = {"attack"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge")
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.keeprumblesound = true
                inst.sg:GoToState("attack")
            end),
        },
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge_VO") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("atk_loop")
            inst.AnimState:PushAnimation("atk_idle", false)
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") end),
			TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") end),
            TimeEvent(17*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(18*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst)
                inst.sg.statemem.keeprumblesound = true
                if inst.components.combat.target then
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("attack_post")
                end
            end),
        },
    },

    State{
        name ="attack_post",
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_disappear")
            inst.AnimState:PlayAnimation("atk_pst")
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.SoundEmitter:KillAllSounds() inst.sg:GoToState("idle") end),
        },
    },


	State{			
		name = "hit",
		tags = {"busy", "hit"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "taunt",
		tags = {"busy"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("atk_idle", true)
		end,

		timeline=
		{
			
		},

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("taunt_pst") end ),
		},
	},

	State{
		name = "taunt_pst",
		tags = {"busy"},

		onenter = function(inst, cb)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("atk_pst", false)
		end,

		timeline=
		{
			
		},

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
		},
	},
	
	State{
		name = "death",
		tags = {"busy"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)            
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
		end,

	timeline=
		{
		},
	},
}

CommonStates.AddFrozenStates(states)


return StateGraph("mean_flytrap", states, events, "taunt", actionhandlers)
