--[[
  flip(0x5) - 0b101

  Findings:
  - Window movement framerate: high.
  - Can resize window.
  - CPU: ~0.008
  - FPS: 60
  - Resizing window seems to clear screen buffer.
]]

window(200, 50)

local frame = 0
while (true) do
  frame += 1
  cls()
  print("flip(0x5)")
  print("frame: " .. frame)

  flip(0x5)
end
