--[[pod_format="raw",created="2025-04-01 10:19:31",modified="2025-04-01 10:19:31",revision=0]]
include("/lib/utils.lua")
include("/lib/describe.lua")

local min_width = 200
local min_height = 100

window({
  width = min_width,
  height = min_height,
  min_width = min_width,
  min_height = min_height,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = tostr(pid())
})

local processAttributes = { "id", "name", "cpu", "memory", "pwd", "prog", "priority" }
local formatMap = {
  id = "%2d", -- TODO: Doesn't update to %3d at PID 100. Consider dynamically calculating based on highest PID.
  name = "%s",
  cpu = "%0.3f",
  memory = "%d",
  pwd = "%s",
  prog = "%s",
  priority = "%d",
}

function _init()
  local processes = fetch "/ram/system/processes.pod"
  local firstProcess = processes[1]
  local actualProcessAttributes = objectKeys(firstProcess)
  assert(#processAttributes == #actualProcessAttributes)
  for actualProcessAttribute in all(actualProcessAttributes) do
    assert(arrayIncludes(processAttributes, actualProcessAttribute))
  end
end

local scrollY = 0
local scrollX = 0

function _draw()
  local _, _, _, wheelX, wheelY = mouse()
  scrollX -= 2 * wheelX
  scrollY -= 2 * wheelY

  camera(scrollX, scrollY)

  cls(0)
  local processes = fetch "/ram/system/processes.pod"

  local columnWidth = {}
  foreach(processAttributes, function(key)
    local keyWidth = getTextWidth(key)
    for process in all(processes) do
      local valueString = string.format(formatMap[key], process[key])
      keyWidth = max(keyWidth, getTextWidth(valueString))
    end
    columnWidth[key] = keyWidth
  end)

  local x = 0
  local y = 0
  local xPadding = 8
  foreach(processAttributes, function(key)
    print(key, x, y)
    x += columnWidth[key] + xPadding
  end)

  for process in all(processes) do
    x = 0
    y += 9
    for key in all(processAttributes) do
      local valueString = string.format(formatMap[key], process[key])
      print(valueString, x, y)
      x += columnWidth[key] + xPadding
    end
    -- print(string.format(" %4d %-" .. keyWidth .. "s %0.3f  %0.0fk", process.id, process.name, process.cpu, process.memory / 1024))
  end
end
