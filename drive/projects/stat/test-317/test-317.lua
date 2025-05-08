--[[pod_format="raw",created="2025-05-03 23:31:50",modified="2025-05-03 23:31:50",revision=0]]

window(200, 100)

function _draw()
  cls(0)

  color(7)

  print("stat(317): " .. tostr(stat(317)), 10, 10)
  -- Run as lua: 0.0
  -- Run as p.64: 0.0
  -- Run as p.64.rom: 0.0
  -- Run as p.64.png: 0.0
  -- `run #cartridge`: 0.0 (#kepijibakifgsdfgsdfg)
  -- Run as web/.html export: 3.0
  -- Run as MacOS binary: 3.0
  -- Run as Linux binary: 3.0
  -- Run as Windows binary: 3.0
  -- Run on BBS web player: 1.0 (https://www.lexaloffle.com/bbs/cart_info.php?cid=kepijibakifgsdfgsdfg-0)

  print("stat(318): " .. tostr(stat(318)), 10, 20)
  -- Run as lua: 0.0
  -- Run as p.64: 0.0
  -- Run as p.64.rom: 0.0
  -- Run as p.64.png: 0.0
  -- `run #cartridge`: 0.0 (#kepijibakifgsdfgsdfg)
  -- Run as web/.html export: 1.0
  -- Run as MacOS binary: 0.0
  -- Run as Linux binary: 0.0
  -- Run as Windows binary: 0.0
  -- Run on BBS web player: 1.0 (https://www.lexaloffle.com/bbs/cart_info.php?cid=kepijibakifgsdfgsdfg-0)
end
