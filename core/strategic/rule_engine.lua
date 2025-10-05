-- core/strategic/rule_engine.lua
-- Interpreter for strategic production rules.
-- Rules are Lua tables with 'condition' and 'action' functions.
-- Uses a bus to emit signals and a blackboard for state.

--local Dump = require('util.dump')

local M = {}

-- Create a rule engine instance
function M.new(bus, blackboard)
    local engine = {
        bus = bus,
        blackboard = blackboard,
        rules = {}
    }
    return setmetatable(engine, { __index = M })
end

-- Add a rule (rule is a table with id, condition, action, priority)
function M:add_rule(rule)
    table.insert(self.rules, rule)
    -- TODO: sort by priority
end

-- Run all applicable rules once
function M:step(state)
    for _, rule in ipairs(self.rules) do
        if rule.condition(state) then
            -- Create safe context for action
            local ctx = self:create_context()
            rule.action(state, ctx)

            --debug
            print("action", rule.id)

            -- TODO: break or continue? (for now: run all)
        else
            --print("condition return: false, rule:", rule.id)
        end
    end
end

-- Create execution context for actions
function M:create_context()
    local ctx = {}
    
    -- Safe interface to blackboard
    function ctx:write_to_blackboard(key, value)
        --print('ctx:write_to_blackboard self =', Dump.dump(self))
        self.engine.blackboard:write(key, value)
    end
    
    function ctx:read_from_blackboard(key)
        return self.engine.blackboard:read(key)
    end
    
    -- Safe interface to bus
    function ctx:emit_signal(event_type, data)
        self.engine.bus:emit(event_type, data)
    end
    
    -- Logging (ASCII only)
    function ctx:log(message)
        -- TODO: use util/logger.lua
        print("[LOG] " .. message)
    end

    function ctx:blackboard_read_all()
        return self.engine.blackboard
    end

    -- Reference to engine for internal use    -- errors in lua code just on start coding
    ctx.engine = self
    
    return ctx
end

-- TODO: Add rule priority sorting
-- TODO: Add conflict resolution strategy
-- TODO: Add rule deprecation based on meta-feedback

return M