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

local zod = {}

function zod.string()
  local getErrorMessage = function(value)
    return "Expected string, got " .. type(value)
  end

  local function condition(value)
    return type(value) == "string"
  end

  local function parse(value, safe)
    if (condition(value)) then
      return safe
          and { success = true, data = value }
          or value
    end
    return safe
        and { success = false, error = getErrorMessage(value) }
        or error(getErrorMessage(value))
  end

  return {
    parse = function(value) return parse(value, false) end,
    safeParse = function(value) return parse(value, true) end
  }
end

function zod.object(schema)
  local function parse(value, safe)
    if type(value) ~= "table" then
      return safe
          and { success = false, error = "Expected table, got " .. type(value) }
          or error("Expected table, got " .. type(value))
    end

    local result = {}
    for key, fieldValidator in pairs(schema) do
      if fieldValidator and fieldValidator.parse then
        local parsedValue = fieldValidator.parse(value[key], safe)
        if safe and not parsedValue.success then
          return parsedValue
        end
        result[key] = safe and parsedValue.data or parsedValue
      else
        result[key] = value[key]
      end
    end

    return safe
        and { success = true, data = result }
        or result
  end

  return {
    parse = function(value) return parse(value, false) end,
    safeParse = function(value) return parse(value, true) end
  }
end

return zod
