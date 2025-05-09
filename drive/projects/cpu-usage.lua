--[[pod_format="raw",created="2025-03-30 21:12:50",modified="2025-03-31 11:24:42",revision=10]]

window({
  width = 140,
  height = 100,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = tostr(pid())
})

local minMag, mag, maxMag = 1, 1, 22
local btnUp, btnDown = 2, 3

local update = 0
function _update()
  update += 1

  if btnp(btnUp) then
    print("btnUp pressed")
    mag = mid(minMag, mag + 1, maxMag)
  end
  if btnp(btnDown) then
    mag = mid(minMag, mag - 1, maxMag)
  end
end

local draw = 0
function _draw()
  draw += 1

  cls()

  print("processId: " .. pid())
  print("pwd: " .. tostr(pwd()))
  print("pwf: " .. tostr(pwf()))
  print("draw: " .. draw)
  print("update: " .. update)
  print("CPU (pre): " .. stat(1))

  local n = 2 ^ mag
  for i = 1, n do
    -- Do nothing.
  end

  print("CPU (post): " .. stat(1))
  print("FPS: " .. stat(7))
  print("mag: " .. mag)
  print("n: " .. n)
end
