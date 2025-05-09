window(200, 50)

local frame = 0
while (true) do
  frame += 1
  cls()
  print("yield")
  print("frame: " .. frame)

  yield()
end
