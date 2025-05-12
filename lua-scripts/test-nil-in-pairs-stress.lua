-- Based on similar file from pico8 repo
-- picotron -x test-nil-in-pairs-stress.lua

local values = { 1, 2, 3, "a", "b", "c", nil, false, true, {}, function() end }

local arrayLength = 20

function generateArray(length)
  local result = {}
  for i = 1, length do
    result[i] = rnd(values)
  end
  return result
end

function extractIndicesUsingIpairs(table)
  local result = {}
  for i, v in ipairs(table) do
    --print("i: " .. tostr(i) .. " v: " .. tostr(v))
    add(result, i)
  end
  return result
end

function extractIndicesUsingPairs(table)
  local result = {}
  for i, v in pairs(table) do
    --print("i: " .. tostr(i) .. " v: " .. tostr(v))
    add(result, i)
  end
  return result
end

function extractIndicesUsingForArrayLength(table)
  local result = {}
  for i = 1, arrayLength do
    --print("i: " .. tostr(i) .. " v: " .. tostr(v))
    -- TODO: Is this correct? extractIndicesUsingPairs doesn't check for nil values.
    -- TODO: Can adding nil have side effects? Test.
    if (table[i] ~= nil) then
      add(result, i)
    end
  end
  return result
end

function arrayToStringUsingIpairs(array)
  local result = ""
  for i, v in ipairs(array) do
    result = result .. tostr(v) .. " "
  end
  return result
end

function arrayToStringUsingForArrayLength(array)
  local result = ""
  for i = 1, arrayLength do
    result = result .. tostr(array[i]) .. " "
  end
  return result
end

function compareArraysUsingIpairs(array1, array2)
  for i, v in ipairs(array1) do
    if (v ~= array2[i]) then
      return false
    end
  end
  return true
end

local minFailingArrayLength = arrayLength
local maxFailingArrayLength = 0
local failingArrays = {}
local numTests = 1000
for testi = 1, 1000 do
  local randomArray = generateArray(arrayLength)
  --print("array: " .. arrayToStringUsingFor(array))
  local pairsIndices = extractIndicesUsingPairs(randomArray)
  --print("pairs: " .. arrayToStringUsingIpairs(pairsIndices))
  local forIndices = extractIndicesUsingForArrayLength(randomArray)
  --print("for:   " .. arrayToStringUsingIpairs(forIndices))
  if not compareArraysUsingIpairs(pairsIndices, forIndices) then
    failingArrays[#failingArrays + 1] = randomArray
    if #pairsIndices < minFailingArrayLength then
      minFailingArrayLength = #pairsIndices
    end
    if #pairsIndices > maxFailingArrayLength then
      maxFailingArrayLength = #pairsIndices
    end
  end
end

--print("")
--print("Failing arrays (" .. #failingArrays .. "):")
--for i, array in ipairs(failingArrays) do
--  print("array: " .. arrayToStringUsingFor(array))
--  local pairsIndices = extractIndicesUsingPairs(array)
--  print("pairs: " .. arrayToStringUsingIpairs(pairsIndices))
--  local forIndices = extractIndicesUsingForArrayLength(array)
--  print("for:   " .. arrayToStringUsingIpairs(forIndices))
--end

print("")
print("Total failing arrays: " .. #failingArrays .. "/" .. numTests .. " (" .. (#failingArrays / numTests * 100) .. "%)")
print("Min failing array length: " .. minFailingArrayLength)
print("Max failing array length: " .. maxFailingArrayLength)

print("")
print("Example array with successful pairs extract:")
local array = { 1, 2, 3, nil, nil, nil, 4, 5, 6, nil, nil, nil, "a", "b", "c", nil, nil, nil, 7, 8 }
print("array: " .. arrayToStringUsingForArrayLength(array))
print("#array: " .. #array)
local ipairsIndices = extractIndicesUsingIpairs(array)
print("non-nil indices using ipairs:          " .. arrayToStringUsingIpairs(ipairsIndices))
local pairsIndices = extractIndicesUsingPairs(array)
print("non-nil indices using pairs:           " .. arrayToStringUsingIpairs(pairsIndices))
local forIndices = extractIndicesUsingForArrayLength(array)
print("non-nil indices using for arrayLength: " .. arrayToStringUsingIpairs(forIndices))

print("")
print("Example array with successful pairs extract but incorrect #array:")
local array = { 1, 2, 3, nil, nil, nil, 4, 5, 6, nil, nil, nil, "a", "b", "c", 7, 8, nil, nil, nil }
print("array: " .. arrayToStringUsingForArrayLength(array))
print("#array: " .. #array)                                         -- 3 (fail)
print("select(\"#\",unpack(array): " .. select("#", unpack(array))) -- 3 (fail)
print("pack(unpack(array)).n: " .. pack(unpack(array)).n)           -- 3 (fail)
local ipairsIndices = extractIndicesUsingIpairs(array)
print("non-nil indices using ipairs:          " .. arrayToStringUsingIpairs(ipairsIndices))
local pairsIndices = extractIndicesUsingPairs(array)
print("non-nil indices using pairs:           " .. arrayToStringUsingIpairs(pairsIndices))
local forIndices = extractIndicesUsingForArrayLength(array)
print("non-nil indices using for arrayLength: " .. arrayToStringUsingIpairs(forIndices))
