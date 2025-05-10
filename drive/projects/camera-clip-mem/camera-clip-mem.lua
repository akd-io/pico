function _draw()
  printh("--- Zeros:")

  camera(0, 0)
  clip(0, 0, 0, 0)

  local unrelatedAddresses = {}

  for i = 0x5500, 0x5540 do
    if peek(i) ~= 0 then
      printh("[camera-clip-mem] " .. tostr(i, true) .. " " .. tostr(peek(i), true))
      unrelatedAddresses[i] = true
    end
  end

  printh("--- i64")

  camera(0x1111111111111111, 0x2222222222222222)
  clip(0x3333333333333333, 0x4444444444444444, 0x5555555555555555, 0x6666666666666666)

  for i = 0x5500, 0x5540 do
    if peek(i) ~= 0 then
      if not unrelatedAddresses[i] then
        printh("[camera-clip-mem] " .. tostr(i, true) .. " " .. tostr(peek(i), true))
      end
    end
  end

  printh("--- i32")

  camera(0x11111111, 0x22222222)
  clip(0x33333333, 0x44444444, 0x55555555, 0x66666666)

  for i = 0x5500, 0x5540 do
    if peek(i) ~= 0 then
      if not unrelatedAddresses[i] then
        printh("[camera-clip-mem] " .. tostr(i, true) .. " " .. tostr(peek(i), true))
      end
    end
  end

  printh("--- i16")

  camera(0x1111, 0x2222)
  clip(0x3333, 0x4444, 0x5555, 0x6666)

  for i = 0x5500, 0x5540 do
    if peek(i) ~= 0 then
      if not unrelatedAddresses[i] then
        printh("[camera-clip-mem] " .. tostr(i, true) .. " " .. tostr(peek(i), true))
      end
    end
  end
end
