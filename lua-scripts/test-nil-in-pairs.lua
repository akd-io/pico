-- Based on similar file from pico8 repo
-- picotron -x test-nil-in-pairs.lua

local function pairsOrder(table)
  local result = {}
  for _, v in pairs(table) do
    --print("i: " .. tostr(i) .. " v: " .. tostr(v))
    result[#result + 1] = v
  end
  return result
end

-- TODO: Consider using arrayToString from utils.lua instead.
local function arrayToString(array)
  local result = ""
  for v in all(array) do
    result = result .. tostr(v) .. " "
  end
  return result
end

print("")
print("This script show that statically-created tables preserves their ordering over several calls to pairs().")

print("")
local numArray = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
print("num declaration: { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }")
print("num pairs() 1:   " .. arrayToString(pairsOrder(numArray)))
print("num pairs() 2:   " .. arrayToString(pairsOrder(numArray)))

print("")
local reverseNumArray = { 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
print("reverseNum declaration: { 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }")
print("reverseNum pairs() 1:   " .. arrayToString(pairsOrder(reverseNumArray)))
print("reverseNum pairs() 2:   " .. arrayToString(pairsOrder(reverseNumArray)))

print("")
local lettersArray = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j" }
print("letters declaration: { a, b, c, d, e, f, g, h, i, j }")
print("letters pairs() 1:   " .. arrayToString(pairsOrder(lettersArray)))
print("letters pairs() 2:   " .. arrayToString(pairsOrder(lettersArray)))

print("")
local reverseLettersArray = { "j", "i", "h", "g", "f", "e", "d", "c", "b", "a" }
print("reverseLetters declaration: { j, i, h, g, f, e, d, c, b, a }")
print("reverseLetters pairs() 1:   " .. arrayToString(pairsOrder(reverseLettersArray)))
print("reverseLetters pairs() 2:   " .. arrayToString(pairsOrder(reverseLettersArray)))

print("")
local mixedArray = { 10, "a", 3, nil, nil, 3, "abc", nil, false, true, "34", 32, 1, 2 }
print("mixedArray declaration: { 10, a, 3, nil, nil, 3, abc, nil, false, true, 34, 32, 1, 2 }")
print("mixedArray pairs() 1:   " .. arrayToString(pairsOrder(mixedArray)))
print("mixedArray pairs() 2:   " .. arrayToString(pairsOrder(mixedArray)))

print("")
local letterToNumber = { a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9, j = 10 }
print("letterToNumber declaration: { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8, i=9, j=10 }")
print("letterToNumber pairs() 1:   " .. arrayToString(pairsOrder(letterToNumber)))
print("letterToNumber pairs() 2:   " .. arrayToString(pairsOrder(letterToNumber)))

print("")
local reverseLetterToNumber = { j = 10, i = 9, h = 8, g = 7, f = 6, e = 5, d = 4, c = 3, b = 2, a = 1 }
print("reverseLetterToNumber declaration: { j=10, i=9, h=8, g=7, f=6, e=5, d=4, c=3, b=2, a=1 }")
print("reverseLetterToNumber pairs() 1:   " .. arrayToString(pairsOrder(reverseLetterToNumber)))
print("reverseLetterToNumber pairs() 2:   " .. arrayToString(pairsOrder(reverseLetterToNumber)))

print("")
local numberToLetter = {
  [1] = "a",
  [2] = "b",
  [3] = "c",
  [4] = "d",
  [5] = "e",
  [6] = "f",
  [7] = "g",
  [8] = "h",
  [9] = "i",
  [10] = "j"
}
print("numberToLetter declaration: { [1]=a, [2]=b, [3]=c, [4]=d, [5]=e, [6]=f, [7]=g, [8]=h, [9]=i, [10]=j }")
print("numberToLetter pairs() 1:   " .. arrayToString(pairsOrder(numberToLetter)))
print("numberToLetter pairs() 2:   " .. arrayToString(pairsOrder(numberToLetter)))

print("")
local reverseNumberToLetter = {
  [10] = "j",
  [9] = "i",
  [8] = "h",
  [7] = "g",
  [6] = "f",
  [5] = "e",
  [4] = "d",
  [3] = "c",
  [2] = "b",
  [1] = "a"
}
print("reverseNumberToLetter declaration: { [10]=j, [9]=i, [8]=h, [7]=g, [6]=f, [5]=e, [4]=d, [3]=c, [2]=b, [1]=a }")
print("reverseNumberToLetter pairs() 1:   " .. arrayToString(pairsOrder(reverseNumberToLetter)))
print("reverseNumberToLetter pairs() 2:   " .. arrayToString(pairsOrder(reverseNumberToLetter)))

print("")
print("Nils break #: #{ 1, 2, 3, nil, 5, nil } -> " .. #{ 1, 2, 3, nil, 5, nil })
