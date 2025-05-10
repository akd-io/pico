--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-03-31 11:24:42",revision=10]]

include("/lib/describe.lua")

window({
  width = 140,
  height = 80,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = tostr(pid())
})

local mathWorker = create_process("math-worker.lua")

local function add(a, b)
  local request = { event = "add", a = a, b = b }
  printh("Sending request:")
  printh("[multi-thread] " .. describe(request))
  send_message(mathWorker, { event = "add", a = a, b = b })
end

on_event("add_result", function(response)
  printh("Received response:")
  printh("[multi-thread] " .. describe(response))
  printh("Killing math worker with ID " .. mathWorker .. "...")
  send_message(2, { event = "kill_process", proc_id = mathWorker })
  printh("Exiting...")
  exit()
end)

function _init()
  add(3, 4)
end

function _draw()
  cls()
  print("processId: " .. pid())
  print("pwd: " .. tostr(pwd()))
  print("pwf: " .. tostr(pwf()))
  print("CPU: " .. stat(1))
  print("FPS: " .. stat(7))
  print("mathWorker: " .. mathWorker)
end
