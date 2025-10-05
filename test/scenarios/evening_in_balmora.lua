-- test/scenarios/evening_in_balmora.lua
-- Scenario: Agent plans an evening in Balmora (Morrowind)

local Bus = require("core.bus")
local Blackboard = require("core.blackboard")
local RuleEngine = require("core.strategic.rule_engine")
local EpisodicMemory = require("memory.episodic")
local EveningRules = require("test.rules.evening_rules")

local M = {}

function M.run()
    print("=== Evening in Balmora Scenario ===")
    
    -- Setup
    local bus = Bus.new()
    local bb = Blackboard.new("evening_20250405")
    local engine = RuleEngine.new(bus, bb)
    
    local state = {
      -- Постоянное состояние агента (долговременное)
      agent = {
        id = "agent_7",
        role = "adventurer",
        stats = { health = 65, magicka = 40, fatigue = 30 },
        resources = { gold = 72 },
        emotions = { loneliness = 0.4, curiosity = 0.5, fear = 0.1 },
        relationships = {
          ["npc_faruse"] = { trust = 0.6, last_seen = os.time() - 86400 },
          ["npc_dralor"] = { trust = 0.8, guild = "mages_guild" }
        },
        memory = EpisodicMemory  -- ссылка на модуль памяти
      },

      -- Контекст текущей задачи (временный)
      task = {
        id = "evening_20250405",
        goal = { type = "spend_evening", location = "balmora" },
        blackboard = bb,   -- локальный Blackboard
        bus = bus,         -- локальная шина
        start_time = os.time(),
        deadline = os.time() + 300  -- 5 минут игрового времени
      },

      -- Окружающая среда (может обновляться)
      world = {
        location = "balmora",
        time_of_day = "evening",  -- 18:00-23:00
        weather = "clear",
        active_events = { "guild_meeting_tomorrow", "almsei_festival" }
      }
    }
    
    -- Load evening rules
    for _, rule in ipairs(EveningRules.rules) do
        engine:add_rule(rule)
    end
    
    -- Run one step
    engine:step(state)
    
    print("Scenario completed (stub).")
end

return M