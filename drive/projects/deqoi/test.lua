include("deqoi.lua")

local qoiString = fetch("/desktop/label.qoi")

printh(qoiString:sub(1, 4))

local imageUserdata = qoiDecode(qoiString)

function _draw()
  cls()
  spr(imageUserdata, 0, 0)
end
