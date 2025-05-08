--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-03-31 19:04:03",revision=35]]

-- This script documents the return value of the env() function.

include("/lib/describe.lua")

local defaultDest = "/projects/env/env.txt"
local dest = env().argv[1]
if (dest == nil) then
  print("No destination specified. Saving to default path: " .. defaultDest)
end

local result = describe(env())
store(dest, result)
print(result)
