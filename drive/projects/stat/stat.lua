--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-03-31 00:58:25",revision=31]]

-- This script documents Picotron's built-in functions and variables.
-- It does so using the _ENV table.

include("/lib/describe.lua")

local podPath = "/projects/stat/stat.pod"
local txtPath = "/projects/stat/stat.txt"

local stats = fetch(podPath)
if (stats == nil) then
  stats = {}
  printh("No pod! Initializing new table.")
end

for i = 0, 1000 do
  local val = stat(i)
  stats[i] = val != 0 and val or nil
end

store(podPath, stats)
local str = describe(stats)
store(txtPath, str)
printh(str)
