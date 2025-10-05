-- core/bus.lua
-- Vertical event bus for communication between cognitive levels.
-- Each task gets its own bus instance.
-- Events are simple tables: { type = "string", data = {...} }
-- Listeners are functions registered by level.

local M = {}

-- Create a new event bus
function M.new()
    local bus = {
        listeners = {}  -- { event_type -> { func1, func2, ... } }
    }
    return setmetatable(bus, { __index = M })
end

-- Subscribe to an event type
function M:on(event_type, callback)
    if not self.listeners[event_type] then
        self.listeners[event_type] = {}
    end
    table.insert(self.listeners[event_type], callback)
end

-- Emit an event
function M:emit(event_type, data)
    local listeners = self.listeners[event_type]
    if not listeners then
        return
    end
    for _, callback in ipairs(listeners) do
        callback(data)
    end
end

return M