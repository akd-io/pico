--[[pod_format="raw",created="2025-03-31 19:08:43",modified="2025-03-31 19:10:22",revision=2]]
local function isArray(table)
  if (type(table) != "table") then return false end
  local i = 1
  for _ in pairs(table) do
    if table[i] == nil then return false end
    i += 1
  end
  return true
end

-- Modified sortedArray by Werxyz from https://discord.com/channels/215267007245975552/1168158710372241498/1168158710372241498
local function sortedArray(array)
  assert(isArray(array))
  local sorted = {}
  for d in all(array) do
    local i = 1
    while (sorted[i] and sorted[i] < d) do
      i += 1
    end
    add(sorted, d, i)
  end
  return sorted
end

local localInnerDescribe

local function describeFunction(func)
  assert(type(func) == "function")
  local addr = tostring(func):match '%X(%x+)%X*$'
  local info, params = debug.getinfo(func, 'u'), {}
  for i = 1, info.nparams do
    params[i] = debug.getlocal(func, i)
  end
  if info.isvararg then
    params[#params + 1] = '...'
  end
  return 'function (' .. table.concat(params, ', ') .. ')'
end

local function describeArray(array)
  assert(isArray(array))
  local result = "["
  for k, v in ipairs(array) do
    if (k > 1) then result = result .. ", " end
    result = result .. localInnerDescribe(v)
  end
  return result .. "]"
end

local indentation = 0
local function describeObject(object)
  assert(type(object) == "table" and not isArray(object))

  local stringKeys = {}
  local numberKeys = {}
  local functionKeys = {}
  local tableKeys = {}
  local otherKeys = {}

  for k, v in pairs(object) do
    if type(v) == "string" then
      add(stringKeys, k)
    elseif type(v) == "number" then
      add(numberKeys, k)
    elseif type(v) == "function" then
      add(functionKeys, k)
    elseif type(v) == "table" then
      add(tableKeys, k)
    else
      add(otherKeys, k)
    end
  end

  local keys = {}
  for k in all(sortedArray(stringKeys)) do add(keys, k) end
  for k in all(sortedArray(numberKeys)) do add(keys, k) end
  for k in all(sortedArray(functionKeys)) do add(keys, k) end
  for k in all(sortedArray(tableKeys)) do add(keys, k) end
  for k in all(sortedArray(otherKeys)) do add(keys, k) end

  if #keys == 0 then
    return "{}"
  end

  local result = "{\n"
  indentation += 2
  for k in all(keys) do
    local v = object[k]
    result = result .. string.rep(" ", indentation) .. localInnerDescribe(k) .. " = " .. localInnerDescribe(v) .. ",\n"
  end
  indentation -= 2
  return result .. string.rep(" ", indentation) .. "}"
end

local seenTables = {}
local function describeTable(table)
  assert(type(table) == "table")

  if seenTables[table] == nil then
    seenTables[table] = 0
  end
  seenTables[table] += 1
  if (seenTables[table] > 1) then
    return "<circular reference>"
  end

  if isArray(table) then
    return describeArray(table)
  else
    return describeObject(table)
  end
end

---@param value any
---@return string
localInnerDescribe = function(value)
  if (type(value) == "function") then
    return describeFunction(value)
  elseif (type(value) == "table") then
    return describeTable(value)
  elseif (type(value) == "string") then
    return '"' .. value:gsub("\n", "\\n") .. '"'
  else
    return tostring(value)
  end
end

function describe(value)
  seenTables = {}
  return localInnerDescribe(value)
end
