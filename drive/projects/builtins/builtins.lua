--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-03-31 00:58:25",revision=31]]

-- This script documents Picotron's built-in functions and variables.
-- It does so using the _ENV table.

include("/lib/describe.lua")

local defaultDest = "/projects/builtins/builtins.txt"
local dest = env().argv[1]
if (dest == nil) then
  print("No destination specified. Saving to default path: " .. defaultDest)
end
local localDescribe = describe
_ENV.describe = nil
local result = localDescribe(_ENV)
store(dest, result)
print(result)
