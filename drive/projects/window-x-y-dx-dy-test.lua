window({
  width = 100,
  height = 100,
  x = 20,
  y = 20,
})

local f = 0
function _draw()
  if (f % 60 == 0) then
    window({ dx = 1 })
  end
  cls(0)
  print("Hello")
  f += 1
end
