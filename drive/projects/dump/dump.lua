--[[pod_format="raw",created="2025-03-31 15:08:47",modified="2025-03-31 15:08:47",revision=0]]

include("/lib/describe.lua")
include("/lib/literal.lua")

--[[
  !IMPORTANT: Zep seems to have forgotten to bump the version number in `0.1.0c`
    - This means `0.1.0c` writes to `0.1.0b`, and you have to manually override the target directory by passing `0.1.0c` as CLI argument.

  TODO:
  - Fix error for versions prior to 0.1.1:
    - `builtins:3: bad argument #2 to 'load' (string expected, got table)`
]]

local destinationArg = env().argv[1]
assert(destinationArg == nil or type(destinationArg) == "string", "Usage: dump [destination]")

local systemMetadata = fetch_metadata("/system")
local systemVersion = systemMetadata.version

local targetDir = "/dumps/" .. (destinationArg or systemVersion)

print("Preparing target directory: " .. targetDir)
rm(targetDir)
mkdir(targetDir)

-- Dump builtins (_ENV)
local builtinsPath = targetDir .. "/builtins.txt"
rm(builtinsPath)
create_process("/projects/builtins/builtins.lua", { argv = { builtinsPath } })

-- Dump env()
local envPath = targetDir .. "/env.txt"
rm(envPath)
create_process("/projects/env/env.lua", { argv = { envPath } })

-- Dump /system
local systemPath = targetDir .. "/system"
rm(systemPath)
cp("/system", systemPath)

-- Dump /ram
local ramPath = targetDir .. "/ram"
rm(ramPath)
cp("/ram", ramPath)

-- Dump system metadata
local systemMetadataPath = targetDir .. "/system-metadata.txt"
rm(systemMetadataPath)
store(systemMetadataPath, describe(systemMetadata))

-- Remove jettison
include("/projects/patcher/head-remove-jettison.lua")

-- Dump jailbroken builtins (_ENV without jettison)
-- !Important: This will only work on second run, as `createProcess()` reuses the `head.lua` of this script's process!
local builtinsJailbrokenPath = targetDir .. "/builtins-jailbroken.txt"
rm(builtinsJailbrokenPath)
create_process("/projects/builtins/builtins.lua", { argv = { builtinsJailbrokenPath } })

print("Done.") -- Note that this doesn't mean async processes are finished.
