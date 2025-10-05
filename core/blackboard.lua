-- core/blackboard.lua
-- Local blackboard for a single cognitive task.
-- Stores goals, plans, hypotheses, events.
-- Destroyed after task completion.

local M = {}

-- Create a new blackboard for a task
function M.new(task_id)
    local bb = {
        task_id = task_id,
        data = {},
        created_at = os.time()
    }
    return setmetatable(bb, { __index = M })
end

-- Write a key-value pair
function M:write(key, value)
    self.data[key] = value
end

-- Read a value
function M:read(key)
    return self.data[key]
end

-- Check if key exists
function M:has(key)
    return self.data[key] ~= nil
end

-- Clear the blackboard (called on task end)
function M:clear()
    self.data = {}
end

-- TODO: Add TTL-based cleanup
-- TODO: Add serialization for debugging

return M