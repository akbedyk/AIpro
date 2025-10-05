-- test/rules/evening_rules.lua
-- Basic strategic rules for "Evening in Balmora" scenario

local M = {}

local function table_contains(tab, key)
    return tab[key]
end

local function table_to_string(t)
  if type(t) ~= "table" then return tostring(t) end
  local parts = {}
  for k, v in pairs(t) do
    table.insert(parts, tostring(k) .. "=" .. tostring(v))
  end
  return "{" .. table.concat(parts, ", ") .. "}"
end


M.rules = {
    {
      id = "debug_state",
      description = "Print full state for debugging",
      condition = function(state)
        return true  -- always run once
      end,
      action = function(state, ctx)
        ctx:log("DEBUG: agent.role = " .. tostring(state.agent.role))
        ctx:log("DEBUG: world.time_of_day = " .. tostring(state.world.time_of_day))
        ctx:log("DEBUG: blackboard keys = " .. table_to_string(ctx:blackboard_read_all()))
        ctx:write_to_blackboard("debug_done", true)
      end,
      priority = 200
    },
    
    {
        id = "init_evening_planning",
        description = "Start evening planning if goal is spend_evening",
        condition = function(state)
            return state.task.goal and state.task.goal.type == "spend_evening"
        end,
        action = function(state, ctx)
            ctx:log("Starting evening planning in Balmora")
            ctx:write_to_blackboard("planning_started", true)
            ctx:emit_signal("planning_initiated", { location = state.task.goal.location })
        end,
        priority = 100
    },

    {
        id = "choose_companionship_vs_solitude",
        description = "Decide whether to seek company or solitude based on loneliness",
        condition = function(state)
            return state.agent.emotions and state.agent.emotions.self 
                and state.task.blackboard:read("planning_started")
                and not state.task.blackboard:read("companionship_decided")
        end,
        action = function(state, ctx)
            local loneliness = state.agent.emotions.self.loneliness or 0
            if loneliness > 0.5 then
                ctx:write_to_blackboard("seek_companionship", true)
                ctx:log("Loneliness high -> seeking company")
            else
                ctx:write_to_blackboard("prefer_solitude", true)
                ctx:log("Loneliness low -> preferring solitude")
            end
            ctx:write_to_blackboard("companionship_decided", true)
        end,
        priority = 90
    },

    {
        id = "check_budget_for_tavern",
        description = "Check if gold is sufficient for tavern visit",
        condition = function(state)
            return state.agent.resources and state.agent.resources.gold
                and state.task.blackboard:read("seek_companionship")
                and not state.task.blackboard:read("budget_checked")
        end,
        action = function(state, ctx)
            if state.agent.resources.gold >= 30 then
                ctx:write_to_blackboard("can_afford_tavern", true)
                ctx:log("Budget sufficient for tavern")
            else
                ctx:write_to_blackboard("avoid_tavern", true)
                ctx:log("Budget low -> avoiding tavern")
            end
            ctx:write_to_blackboard("budget_checked", true)
        end,
        priority = 80
    },

    {
        id = "select_evening_activity",
        description = "Select final evening activity based on decisions",
        condition = function(state)
            return state.task.blackboard:read("companionship_decided")
                and state.task.blackboard:read("budget_checked")
                and not state.task.blackboard:read("activity_selected")
        end,
        action = function(state, ctx)
            if state.task.blackboard:read("seek_companionship") and state.task.blackboard:read("can_afford_tavern") then
                ctx:write_to_blackboard("selected_activity", "tavern")
                ctx:log("Selected activity: tavern")
            elseif state.task.blackboard:read("prefer_solitude") then
                ctx:write_to_blackboard("selected_activity", "temple")
                ctx:log("Selected activity: temple")
            else
                ctx:write_to_blackboard("selected_activity", "walk")
                ctx:log("Selected activity: walk")
            end
            ctx:write_to_blackboard("activity_selected", true)
            ctx:emit_signal("evening_plan_ready", { activity = ctx:read_from_blackboard("selected_activity") })
        end,
        priority = 70
    },

    {
      id = "avoid_tavern_if_mage",
      description = "Mages Guild members avoid taverns due to cultural norms",
      condition = function(state)
        return state.agent.role == "mages_guild_member"
            and state.task.blackboard:read("can_afford_tavern")
      end,
      action = function(state, ctx)
        ctx:blackboard_write("avoid_tavern", true)
        ctx:log("Cultural norm: mages avoid taverns")
      end,
      priority = 95
    },

    {
      id = "prefer_temple_if_festival",
      description = "Temple festival offers free magicka restoration and socializing",
      condition = function(state)
        return state.world.active_events and
               table_contains(state.world.active_events, "almsei_festival")
      end,
      action = function(state, ctx)
        ctx:blackboard_write("temple_is_better", true)
        ctx:log("Temple festival active -> prefer temple")
      end,
      priority = 85
    },

    {
      id = "check_npc_availability",
      description = "Check if desired NPCs are available tonight",
      condition = function(state)
        return state.task.blackboard:read("seek_companionship")
            and not state.task.blackboard:read("npcs_checked")
      end,
      action = function(state, ctx)
        -- Simulate world knowledge
        local faruse_available = false  -- shop closed
        local dralor_available = true   -- in guild hall
        ctx:blackboard_write("npc_faruse_available", faruse_available)
        ctx:blackboard_write("npc_dralor_available", dralor_available)
        ctx:blackboard_write("npcs_checked", true)
        ctx:log("Checked NPC availability")
      end,
      priority = 75
    },

    {
      id = "select_activity_with_constraints",
      description = "Final activity selection with all constraints",
      condition = function(state)
        return state.task.blackboard:read("npcs_checked")
            and not state.task.blackboard:read("final_activity")
      end,
      action = function(state, ctx)
        local activity = "walk"  -- default

        -- Prefer temple if festival
        if state.task.blackboard:read("temple_is_better") then
          activity = "temple"
        -- If want company and Dralor is available
        elseif state.task.blackboard:read("seek_companionship") and
               state.task.blackboard:read("npc_dralor_available") then
          activity = "guild_hall"
        -- Avoid tavern if mage or budget low
        elseif not state.task.blackboard:read("avoid_tavern") and
               state.task.blackboard:read("can_afford_tavern") then
          activity = "tavern"
        end

        ctx:blackboard_write("final_activity", activity)
        ctx:log("Final activity selected: " .. activity)
        ctx:emit_signal("plan_finalized", { activity = activity })
      end,
      priority = 60
    },
}

return M