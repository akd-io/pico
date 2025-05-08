include("/lib/printPrint.lua")

local function printPrintUsage()
  printPrint("Usage: touch <path/to/file>")
end

cd(env().path)
local rawInputPath = env().argv[1]
local fullInputPath = fullpath(rawInputPath)

if fullInputPath == nil then
  printPrintUsage()
  exit(1)
end

local fileType = fstat(fullInputPath)
if fileType != nil then
  local prettyFileType = fileType == "folder" and "directory" or fileType
  printPrint(prettyFileType .. " already exists")
  exit(2)
end

local segments = split(fullInputPath, "/")
local fileName = segments[#segments]
local parentDir = fullInputPath:sub(1, #fullInputPath - #fileName)
if (fstat(parentDir) == nil) then
  printPrint("Directory " .. parentDir .. " does not exist")
  exit(3)
end

store(fullInputPath, "")
print("Made file: " .. rawInputPath)
