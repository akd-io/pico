--[[
  flip(0x4) - 0b100

  Findings:
  - Window movement framerate: high.
  - Can resize window.
  - CPU: ~0.008
  - FPS: 60
  - Resizing window seems to clear screen buffer.

  flip(0x4) is equivalent to flip() (no bitfield argument specified)
  See `flags = flags or 0x4` in the `flip` function in `system/lib/events.lua`
]]

window(200, 50)

local frame = 0
while (true) do
  frame += 1
  cls()
  print("flip(0x4)")
  print("frame: " .. frame)

  flip(0x4)
end
