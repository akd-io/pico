--[[
  flip(0x3) - 0b011

  Findings:
  - Window movement framerate: low.
  - Can't resize window.
  - CPU: ~0.006
  - FPS: 60
]]

window(200, 50)

local frame = 0
while (true) do
  frame += 1
  cls()
  print("flip(0x3)")
  print("frame: " .. frame)

  flip(0x3)
end
