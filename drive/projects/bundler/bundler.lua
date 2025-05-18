--[[
  bundler <my-script.lua>

  TODOs:
  - Process:
    - (Done) Takes a Lua file
    - (Done) Creates a .p64 cart
    - recursively finds all includes
    - copies all dependencies to cart
  - I believe include statements just need to have leading `/` removed if files
    are copied into the cart such that the cart becomes the new root for their
    paths.
  - Should the bundler also generate an installer cart?
    - What is the best UX for downloading apps and libs?
    - Apps are probably nicer through the package manager, but I'm guessing
      all apps won't be there.
      - It would also be nice to be able to send an installer to a friend.
    - For libs I'm guessing the best UX is finding a `load #react-installer`
      command on the BBS page for react, and then simply running that in the
      terminal.
      - Find out how this plays into the package manager
        - Should the package manager take essentially a package.json with a
          "post-install" script, or?
        - For some reason I'm guessing stand-alone installer have their uses
          but also that a higher level API through the package manager has its
          merits too?
          - Or maybe it's not weird that the package manager just calls an
            install script? Too unsafe?
]]

include("/lib/printPrint.lua")

-- TODO: Fix black label path. Should be relative, so it works for exported cart too.
local blackLabelPath = "/projects/bundler/black-label.qoi"

local function printPrintUsage()
  printPrint("Usage: bundler.lua <path/to/input.lua> [path/to/output.p64]")
end

local argv = env().argv

if argv[1] == "-h" or argv[1] == "--help" or argv[1] == "-help" then
  printPrintUsage()
  exit(0)
end

cd(env().path)
local rawInputPath = argv[1]
local rawOutputPath = argv[2]
local inputPath = fullpath(rawInputPath)
local outputPath = fullpath(rawOutputPath)

-- Validate input
if inputPath == nil then
  printPrintUsage()
  exit(0)
end
if inputPath:ext() == nil then
  inputPath = inputPath .. ".lua"
end
if inputPath:ext() != "lua" then
  printPrint("Input file must be a .lua file.")
  printPrint("Got: " .. rawInputPath)
  printPrintUsage()
  exit(1)
end

-- Validate output
if outputPath == nil then
  outputPath = inputPath:gsub("%.lua", ".p64")
end
if outputPath:ext() == nil then
  outputPath = outputPath .. ".p64"
end
if outputPath:ext() != "p64" then
  printPrint("Output file must be a .p64 file.")
  printPrint("Got: " .. rawOutputPath)
  printPrintUsage()
  exit(2)
end

-- Ensure input file exists
if fstat(inputPath) != "file" then
  printPrint("Input file does not exist.")
  printPrint("Got: " .. inputPath)
  printPrintUsage()
  exit(3)
end

-- TODO: Check if output path exists
-- TODO: - If it exists:
-- TODO:   - Require user re-runs with `-o`/`--overwrite` flag
-- TODO:     - If `-o`/`--overwrite` flag given,
-- TODO:       - Check if output/label.qoi exists
-- TODO:         - If it exists, copy label.qoi to temp location, overwrite output, then copy back over the label.qoi.
-- TODO:         - If it doesn't, just overwrite output

-- Make cartridge
print("Making .p64 directory...")
mkdir(outputPath)

-- Copy input file to the cartridge as main.lua
print("Adding main.lua...")
cp(inputPath, outputPath .. "/main.lua")

print("Adding label.qoi...")
cp(blackLabelPath, outputPath .. "/label.qoi")

printPrint("Created cartridge: " .. outputPath)
