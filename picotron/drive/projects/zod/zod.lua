--[[
   A simple Zod-like clone for Pictron's Lua dialect.
   See https://zod.dev/

   Boundaries where zod could be useful:
   - UI forms
   - Third-party process communication
   - File system
     - AppData (could be tampered with)
     - Shared: Third party file communication
   - Configuration files, user input, and could be tampered
   - Command-line arguments, user input, machine input

   TODOs:
   - Find out if the lua type annotations are flexible enough for a task like
     this. Maybe it'll be validate, not parse, after all.
]]

local function addEntries(tbl, entries)
  for k, v in pairs(entries) do
    tbl[k] = v
  end
  return tbl
end

local schemaTypes = {
  string = "string",
  object = "object"
}

local internalParse
local commonReturnValues = {
  parse = function(value) return internalParse(value, false) end,
  safeParse = function(value) return internalParse(value, true) end
}

local function parseString(schema, value, safe)
  if type(value) != "string" then
    local errorMessage = "Expected string, got " .. type(value)
    return safe
        and { success = false, error = errorMessage }
        or error(errorMessage)
  end

  return safe
      and { success = true, data = value }
      or value
end

local function zodString()
  local result = {
    _type = schemaTypes.string,
  }
  return addEntries(result, commonReturnValues)
end

local function parseObject(childSchemas, value, safe)
  if type(value) ~= "table" then
    local errorMessage = "Expected table, got " .. type(value)
    return safe
        and { success = false, error = errorMessage }
        or error(errorMessage)
  end

  for key, fieldValidator in pairs(childSchemas) do
    if safe then
      local result = fieldValidator.safeParse(value[key])
      if not result.success then
        return {
          success = false,
          error = "Error in field '" .. key .. "': " .. result.error
        }
      end
    else
      fieldValidator.parse(value[key])
    end
  end

  return safe
      and { success = true, data = value }
      or value
end

local function zodObject(childSchemas)
  local result = {
    _type = schemaTypes.object,
    childSchemas = childSchemas,
  }
  return addEntries(result, commonReturnValues)
end

internalParse = function(schema, value, safe)
  if (schema._type == "object") then
    return parseObject(schema, value, safe)
  elseif (schema._type == "string") then
    return parseString(schema, value, safe)
  end

  return error("Invalid schema type")
end

local zod = {
  string = zodString,
  object = zodObject
}

return zod
