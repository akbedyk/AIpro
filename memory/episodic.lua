-- memory/episodic.lua
-- Episodic memory module.
-- Stores events with emotional weights, context, significance.
-- Supports retrieval by emotion, tags, time, and significance-based forgetting.

local M = {}

-- Initialize memory store (in real impl: disk or DB)
function M.init()
    M.store = {}
    M.next_id = 1
end

-- Store an episode
-- episode: table with fields as described in design
function M.store_episode(episode)
    episode.id = "ep_" .. M.next_id
    M.next_id = M.next_id + 1
    episode.timestamp = os.time()
    table.insert(M.store, episode)
    -- TODO: compute personal_significance
    -- TODO: apply compression flag
end

-- Retrieve episodes by filter (emotion, tags, time range, etc.)
function M.retrieve(filter)
    -- filter: { min_significance = 0.5, tags = {"social"}, ... }
    local results = {}
    for _, ep in ipairs(M.store) do
        if M.matches_filter(ep, filter) then
            table.insert(results, ep)
        end
    end
    return results
end

-- Simple filter match (to be expanded)
function M.matches_filter(episode, filter)
    if filter.min_significance and (episode.personal_significance or 0) < filter.min_significance then
        return false
    end
    -- TODO: add more filters
    return true
end

-- Forget low-significance episodes when memory is full
function M.forget_low_significance(max_count)
    -- TODO: implement significance-based forgetting
end

-- Compute personal significance of an episode
-- formula: alpha * max_emotion + beta * goal_relevance + gamma * novelty
function M.compute_significance(episode)
    -- TODO: implement
    return 0.5
end

M.init()
return M