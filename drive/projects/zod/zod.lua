--[[
   A simple Zod-like clone for Pictron's Lua dialect.
   See https://zod.dev/

   While I would love to *parse over validate*, I have not found the Lua type
   annotations powerful enough for that yet.

   Boundaries where zod is be useful:
   - UI forms
   - Third-party process communication
   - File system
     - AppData (could be tampered with)
     - Shared: Third party file communication
   - Configuration files, user input, and could be tampered
   - Command-line arguments, user input, machine input
]]

local schemaTypes = {
  string = "string",
  object = "object",
}

---@param schema table
---@param value any
---@param safe boolean
local function internalParse(schema, value, safe) end

local function zodString()
  local schema = {
    _type = "string",
  }
  schema.parse = function(value) return internalParse(schema, value, false) end
  schema.safeParse = function(value) return internalParse(schema, value, true) end
  return schema
end

---@param schema table
---@param value any
---@param safe boolean
local function parseString(schema, value, safe)
  if type(value) != "string" then
    local errorMessage = "Expected string, got " .. type(value)
    return safe and { success = false, error = errorMessage } or error(errorMessage)
  end

  return safe and { success = true, data = value } or value
end

---@param childSchemas? table
---@return table
local function zodObject(childSchemas)
  local schema = {
    _type = schemaTypes.object,
    childSchemas = childSchemas,
  }
  schema.parse = function(value) return internalParse(schema, value, false) end
  schema.safeParse = function(value) return internalParse(schema, value, true) end
  return schema
end

---@param schema table
---@param value any
---@param safe boolean
---@return table
local function parseObject(schema, value, safe)
  if (not schema or (schema._type != schemaTypes.object)) then
    error("Invalid schema type. Expected object, got " .. schema._type)
  end

  if type(value) != "table" then
    local errorMessage = "Expected table, got " .. type(value)
    return safe
        and { success = false, error = errorMessage }
        or error(errorMessage)
  end

  local childSchemas = schema.childSchemas
  if (type(childSchemas) == "table") then
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
  end

  return safe
      and { success = true, data = value }
      or value
end

internalParse = function(schema, value, safe)
  if (schema._type == schemaTypes.object) then
    return parseObject(schema, value, safe)
  elseif (schema._type == schemaTypes.string) then
    return parseString(schema, value, safe)
  end

  error("Invalid schema type, got " .. tostr(schema._type))
end

local zod = {
  string = zodString,
  object = zodObject
}

return zod
