-- picotron -x test-nil-arrays.lua

print("#{ 1, nil, nil }")
--print(#{ 1, 2, 3 })     -- 3
--print(#{ 1, nil, 3 })   -- 3
print(#{ 1, nil, nil }) -- 1

print("")
print("customCountPairs({ 1, nil, nil })")
function customCountPairs(arr)
  local count = 0
  for _ in pairs(arr) do
    count = count + 1
  end
  return count
end

--print(customCountPairs({ 1, 2, 3 }))     -- 3
--print(customCountPairs({ 1, nil, 3 }))   -- 2
print(customCountPairs({ 1, nil, nil })) -- 1

print("")
print("customCountIpairs({ 1, nil, nil })")
function customCountIpairs(arr)
  local count = 0
  for _ in ipairs(arr) do
    count = count + 1
  end
  return count
end

--print(customCountIpairs({ 1, 2, 3 }))     -- 3
--print(customCountIpairs({ 1, nil, 3 }))   -- 1
print(customCountIpairs({ 1, nil, nil })) -- 1

print("")
print("#table.pack(1, nil, nil)")
--print(#table.pack(1, 2, 3))     -- 3
--print(#table.pack(1, nil, 3))   -- 3
print(#table.pack(1, nil, nil)) -- 1

print("")
print("table.pack(1, nil, nil).n")
--print(table.pack(1, 2, 3).n)     -- 3
--print(table.pack(1, nil, 3).n)   -- 3
print(table.pack(1, nil, nil).n) -- 3

print("")
print("select(\"#\", 1, nil, nil)")
--print(select("#", 1, 2, 3))     -- 3
--print(select("#", 1, nil, 3))   -- 3
print(select("#", 1, nil, nil)) -- 3

print("")
print("select(\"#\", ...): (... = 1, nil, nil)")
function func(...)
  print(select("#", ...))
end

--func(1, 2, 3)     -- 3
--func(1, nil, 3)   -- 3
func(1, nil, nil) -- 3
