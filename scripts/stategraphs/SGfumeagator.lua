require("stategraphs/commonstates")

local FUME_MUST_TAGS = { "character" }
local FUME_CANT_TAGS = { "wall", "fumeagator", "bird", "mosquitoswarm", "INLIMBO" }

local events=
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),

    EventHandler("doattack", function(inst)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState((not inst.components.timer:TimerExists("fume_cd")) and "attack_fume" or "attack")
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("attacked", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then inst.sg:GoToState("hit") end end),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst.sg:SetTimeout(2 + 2*math.random())
        end,

        ontimeout = function(inst)

        end,
    },

    State{
        name = "attack",
        tags = {"attack"},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,


        timeline=
        {
            TimeEvent(15*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack_fume",
        tags = {"attack", "fume"},

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("poot")
            SpawnAt("fume_fx", inst)
        end,


        timeline =
		{
		    TimeEvent(0*FRAMES, function(inst) end),
		    TimeEvent(20*FRAMES, function(inst)
                inst.components.timer:StopTimer("fume_cd")
                inst.components.timer:StartTimer("fume_cd", TUNING.FUMEAGATOR_FUMEPERIOD) 
		    	local x, y, z = inst.Transform:GetWorldPosition()
		    	local ents = TheSim:FindEntities(x, y, z, TUNING.FUMEAGATOR_ATTACKRANGE + 6, nil, FUME_CANT_TAGS, FUME_MUST_TAGS)
		    	for _, ent in ipairs(ents) do
		    		if inst:IsNear(ent, ent:GetPhysicsRadius(0) + (TUNING.FUMEAGATOR_ATTACKRANGE + 0.5)) then
		    			if ent.components.health ~= nil and not ent.components.health:IsDead() then
		    				ent.components.health:DoFireDamage(TUNING.FUMEAGATOR_DAMAGE-20, inst, true)
		    			end
		    		end
		    	end
		    end),
		},

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/yell")
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

    },
 }

CommonStates.AddWalkStates(
    states,
    {
        walktimeline =
        {
            TimeEvent(10*FRAMES, PlayFootstep),
            TimeEvent(15*FRAMES, function(inst)
                if math.random(1,3) == 2 then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/walk")
                end
            end ),
            TimeEvent(40*FRAMES, PlayFootstep),
        }
    })

CommonStates.AddRunStates(
    states,
    {
        runtimeline =
        {
            TimeEvent(2*FRAMES, PlayFootstep),
        }
    })

CommonStates.AddSleepStates(states,
{
    starttimeline = {},
    sleeptimeline =
    {
        TimeEvent(0 * FRAMES, function(inst)  end),
    },
    endtimeline = {},
})

CommonStates.AddSimpleState(states,"hit", "hit", {"hit", "busy"})

CommonStates.AddFrozenStates(states)

return StateGraph("fumeagator", states, events, "idle")

