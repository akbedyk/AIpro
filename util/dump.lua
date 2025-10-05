-- utils/dump.lua
-- Красивый вывод Lua-таблиц для отладки

local M = {}

function M.dump(value, indent, seen)
  seen = seen or {}
  indent = indent or ""

  if type(value) == "table" then
    if seen[value] then
      return "<циклическая ссылка>"
    end
    seen[value] = true

    local result = "{\n"
    local sub_indent = indent .. "  "

    for k, v in pairs(value) do
      local key = (type(k) == "number") and "[" .. k .. "]" or k
      result = result .. sub_indent .. key .. " = " .. M.dump(v, sub_indent, seen) .. ",\n"
    end

    result = result .. indent .. "}"
    return result
  elseif type(value) == "string" then
    return '"' .. value .. '"'
  elseif type(value) == "function" then
    return "<функция>"
  elseif type(value) == "nil" then
    return "nil"
  else
    return tostring(value)
  end
end

return M