-- picotron -x test-nil-array-length.lua

print("#{ 1, nil, nil }")
--print(#{ 1, 2, 3 })     -- 3
--print(#{ 1, nil, 3 })   -- 3
print(#{ 1, nil, nil }) -- 1

print("")
print("#{ [1]=1, [2]=nil, [3]=nil }")
--print(#{ [1]=1, [2]=2, [3]=3 })     -- 3
--print(#{ [1]=1, [2]=nil, [3]=3 })   -- 3
print(#{ [1] = 1, [2] = nil, [3] = nil }) -- 1

print("")
