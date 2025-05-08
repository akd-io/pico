--[[pod_format="raw",created="2025-04-12 00:50:33",modified="2025-04-12 00:50:41",revision=2]]
local defaultPaletteHex = {
  [0] = "000000", -- 0
  "1d2b53",       -- 1
  "7e2553",       -- 2
  "008751",       -- 3
  "ab5236",       -- 4
  "5f574f",       -- 5
  "c2c3c7",       -- 6
  "fff1e8",       -- 7
  "ff004d",       -- 8
  "ffa300",       -- 9
  "ffec27",       -- 10
  "00e436",       -- 11
  "29adff",       -- 12
  "83769c",       -- 13
  "ff77a8",       -- 14
  "ffccaa",       -- 15
  "2463b0",       -- 16
  "00a5a1",       -- 17
  "654688",       -- 18
  "125359",       -- 19
  "742f29",       -- 20
  "452d32",       -- 21
  "a28879",       -- 22
  "ffacc5",       -- 23
  "b9003e",       -- 24
  "e26b02",       -- 25
  "95f042",       -- 26
  "00b251",       -- 27
  "64dff6",       -- 28
  "bd9adf",       -- 29
  "e40dab",       -- 30
  "ff8557",       -- 31
}
function hexToRGB(hex)
  assert(#hex == 6, "Hex color must be 6 characters long (RRGGBB format). Got: " .. hex)
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local defaultPaletteRGB = {}
for i = 0, 31 do
  assert(defaultPaletteHex[i] ~= nil, "Missing color for index " .. i .. " in defaultPaletteHex.")
  local r, g, b = hexToRGB(defaultPaletteHex[i])
  defaultPaletteRGB[i] = { r, g, b }
end

local picotronColorCache = {}
function getPicotronColor(r, g, b)
  local id = r .. "-" .. g .. "-" .. b
  if picotronColorCache[id] then
    return picotronColorCache[id]
  end
  local color = 0
  local minDist = 1000000
  for i = 0, 31 do
    local pr, pg, pb = unpack(defaultPaletteRGB[i])
    local dist = (r - pr) ^ 2 + (g - pg) ^ 2 + (b - pb) ^ 2
    if dist < minDist then
      minDist = dist
      color = i
    end
  end
  picotronColorCache[id] = color
  return color
end

-- imageData, channels, colorSpace = qoi.decode( dataString )
-- Returns nil and a message on error.
function qoiDecode(s)
  assert(type(s) == "string", "Expected string, got " .. type(s))

  local pos = 1

  --
  -- Header.
  --
  local getByte = string.byte

  if s:sub(pos, pos + 3) ~= "qoif" then
    return nil, "Invalid signature."
  end
  pos = pos + 4

  if #s < 14 then -- Header is 14 bytes.
    return nil, "Missing part of header."
  end

  local w = 256 ^ 3 * getByte(s, pos) + 256 ^ 2 * getByte(s, pos + 1) + 256 * getByte(s, pos + 2) + getByte(s, pos + 3)
  if w == 0 then return nil, "Invalid width (0)." end
  pos = pos + 4

  local h = 256 ^ 3 * getByte(s, pos) + 256 ^ 2 * getByte(s, pos + 1) + 256 * getByte(s, pos + 2) + getByte(s, pos + 3)
  if h == 0 then return nil, "Invalid height (0)." end
  pos = pos + 4

  local channels = getByte(s, pos)
  if not (channels == 3 or channels == 4) then
    return nil, "Invalid channel count."
  end
  pos = pos + 1

  local colorSpace = getByte(s, pos)
  if colorSpace > 1 then
    return nil, "Invalid color space value."
  end
  colorSpace = (colorSpace == 0 and "srgb" or "linear")
  pos        = pos + 1

  --
  -- Data stream.
  --
  --Removed: local imageData        = require "love.image".newImageData(w, h, "rgba8")
  --Removed: local imageDataPointer = require "ffi".cast("uint8_t*", imageData:getFFIPointer())
  print("w: " .. w .. ", h: " .. h)
  local imageUserdata = userdata("u8", w, h)

  local seen          = {
    -- 64 RGBA pixels.
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  }

  local prevR         = 0 -- Note: All these color values are treated as signed bytes.
  local prevG         = 0
  local prevB         = 0
  -- prevA not needed.

  local r             = 0
  local g             = 0
  local b             = 0
  local a             = -1

  local run           = 0

  local band          = function(a, b) return a & b end  --Removed: require "bit".band
  local rshift        = function(a, b) return a >> b end --Removed: require "bit".rshift
  local lshift        = function(a, b) return a << b end --Removed: require "bit".lshift

  for pixelIz = 0, 4 * w * h - 1, 4 do
    if run > 0 then
      run = run - 1
    else
      local byte1 = getByte(s, pos)
      if not byte1 then return nil, "Unexpected end of data stream." end
      pos = pos + 1

      -- QOI_OP_RGB 11111110
      if byte1 == 254 --[[11111110]] then
        r, g, b = getByte(s, pos, pos + 2)
        if not b then return nil, "Unexpected end of data stream." end
        pos = pos + 3

        -- QOI_OP_RGBA 11111111
      elseif byte1 == 255 --[[11111111]] then
        r, g, b, a = getByte(s, pos, pos + 3)
        if not a then return nil, "Unexpected end of data stream." end
        pos = pos + 4

        -- QOI_OP_INDEX 00xxxxxx
      elseif byte1 < 64 --[[01000000]] then
        local hash4 = lshift(byte1, 2)

        r = seen[hash4 + 1]
        g = seen[hash4 + 2]
        b = seen[hash4 + 3]
        a = seen[hash4 + 4]

        -- QOI_OP_DIFF 01xxxxxx
      elseif byte1 < 128 --[[10000000]] then
        byte1 = byte1 - 64 --[[01000000]]

        r = prevR + rshift(band(byte1, 48 --[[00110000]]), 4) - 2
        g = prevG + rshift(band(byte1, 12 --[[00001100]]), 2) - 2
        b = prevB + band(byte1, 3 --[[00000011]]) - 2

        -- QOI_OP_LUMA 10xxxxxx
      elseif byte1 < 192 --[[11000000]] then
        local byte2 = getByte(s, pos)
        if not byte2 then return nil, "Unexpected end of data stream." end
        pos = pos + 1

        local diffG = byte1 + (-(128 --[[10000000]]) - 32)

        g = prevG + diffG
        r = prevR + diffG + rshift(band(byte2, 240 --[[11110000]]), 4) - 8
        b = prevB + diffG + band(byte2, 15 --[[00001111]]) - 8

        -- QOI_OP_RUN 11xxxxxx
      else
        run = byte1 - 192 --[[11000000]]
      end

      prevR = r
      prevG = g
      prevB = b
    end

    -- TODO: Use cached function to map RGBA to 8bit Picotron color index.
    -- TODO: Use a Userdata instead for imageData?
    local x = (pixelIz / 4) % w
    local y = (pixelIz / 4) // w
    imageUserdata:set(x, y, getPicotronColor(r, g, b))

    local hash4     = lshift(band(r * 3 + g * 5 + b * 7 + a * 11, 63 --[[00111111]]), 2)
    seen[hash4 + 1] = r
    seen[hash4 + 2] = g
    seen[hash4 + 3] = b
    seen[hash4 + 4] = a
  end

  if run > 0 then
    return nil, "Corrupt data."
  end

  if s:sub(pos, pos + 7) ~= "\0\0\0\0\0\0\0\1" then
    return nil, "Missing data end marker."
  end
  pos = pos + 8

  if pos <= #s then
    return nil, "Junk after data."
  end

  return imageUserdata, channels, colorSpace
end
