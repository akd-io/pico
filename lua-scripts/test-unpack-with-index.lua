-- picotron -x lua-scripts/test-unpack-with-index.lua

printh("local result1, result2, result3 = unpack({ \"a\", \"b\", \"c\" }, 2)")
local result1, result2, result3 = unpack({ "a", "b", "c" }, 2)
printh(result1) -- b
printh(result2) -- c
printh(result3) -- nil

printh("local packed = pack(unpack({ \"a\", \"b\", \"c\" }, 2))")
local packed = pack(unpack({ "a", "b", "c" }, 2))
printh(packed[1]) -- b
printh(packed[2]) -- c
printh(packed[3]) -- nil
printh(packed.n)  -- 2
