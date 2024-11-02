pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- font preview
-- by akd

white = 7

-- all chars are written by pressing 1-9, 0, qwe..iop, asd..jkl, zxc..bnm
-- and then holding shift afterwards.

local regular = "1234567890qwertyuiopasdfghjklzxcvbnm<,.-"
local regular_shift = "!\"#%&/()=…∧░➡️⧗▤⬆️☉🅾️◆█★⬇️✽●♥웃⌂⬅️▥❎🐱ˇ▒♪😐>;:_"
local puny = "1234567890𝘲𝘸𝘦𝘳𝘵𝘺𝘶𝘪𝘰𝘱𝘢𝘴𝘥𝘧𝘨𝘩𝘫𝘬𝘭𝘻𝘹𝘤𝘷𝘣𝘯𝘮<,.-"
local puny_shift = "!\"#%&/()=qwertyuiopasdfghjklzxcvbnm>;:_"
local hiragana = "1234567890qゆいおは゜xv<、。-"
local hiragana_shift = "▮\"□⁘◀•◜◝=…∧░➡️⧗▤⬆️☉🅾️◆█★⬇️✽●♥웃⌂⬅️▥❎🐱ˇ▒♪😐>;:_"
local katakana = "1234567890qユイオハ゜xv<、。-"
local katakana_shift = "▮\"□⁘◀•◜◝=…∧░➡️⧗▤⬆️☉🅾️◆█★⬇️✽●♥웃⌂⬅️▥❎🐱ˇ▒♪😐>;:_"

function _draw()
  cls()
  local fontHeight = 6
  local strings = {
    regular,
    regular_shift,
    puny,
    puny_shift,
    hiragana,
    hiragana_shift,
    katakana,
    katakana_shift
  }
  for i = 1, #strings do
    print(sub(strings[i], 0 * 16 + 1, 1 * 16), 0, (2 * (i - 1) + 0) * fontHeight, white)
    print(sub(strings[i], 1 * 16 + 1, 2 * 16), 0, (2 * (i - 1) + 1) * fontHeight, white)
  end

  -- What is \^=?
  print("\^.hello wo", 0, (2 * (8 - 1) + 1 + 1) * fontHeight, white)
  print("\^.abcdefgh", 0, (2 * (8 - 1) + 1 + 2) * fontHeight, white)
  --print("\^.00000000\^.33333333\^.77777777\^.ffffffff\^3Blink", 0, (2 * (8 - 1) + 1 + 3) * fontHeight, white)
  --print("\^.00000000\^.33333333\^.77777777\^.ffffffff\^82", 0, (2 * (8 - 1) + 1 + 4) * fontHeight, white)
  print("\^t\^wthis is a test", 20, (2 * (8 - 1) + 1 + 2) * fontHeight, white)
  print("\^=\^wthis is a test", 00, (2 * (8 - 1) + 1 + 4) * fontHeight, white)
  print("\^wthis is a test", 00, (2 * (8 - 1) + 1 + 5) * fontHeight, white)
end
