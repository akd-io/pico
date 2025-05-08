--[[pod_format="raw",created="2025-04-05 23:35:09",modified="2025-04-06 01:11:08",revision=2]]

local test = 0b10101

local a, b = 3, 2

-- ARITHMETIC OPERATORS
printh("Binary arithmetic operators:")
a, b = 3, 2
printh("a = " .. a .. " | b = " .. b)
printh("a + b = " .. a + b)
printh("a - b = " .. a - b)
printh("a * b = " .. a * b)
printh("a / b = " .. a / b)
printh("a // b = " .. a // b)
printh("a \\ b = " .. a \ b)
printh("a ^ b = " .. a ^ b)
printh("a % b = " .. a % b)

printh("")
printh("Binary arithmetic shorthand assignment operators:")
a, b = 10, 3
printh("a = " .. a .. " | b = " .. b)
printh("a += b")
a += b
printh("a = " .. a .. " | b = " .. b)
printh("a -= b")
a -= b
printh("a = " .. a .. " | b = " .. b)
printh("a *= b")
a *= b
printh("a = " .. a .. " | b = " .. b)
printh("a /= b")
a /= b
printh("a = " .. a .. " | b = " .. b)
printh("a \\= b")
a \= b
printh("a = " .. a .. " | b = " .. b)
printh("a //= b is not supported")
--a //= b -- Uncomment and run in Picotron for syntax error
printh("a ^= b")
a ^= b
printh("a = " .. a .. " | b = " .. b)
printh("a %= b")
a %= b
printh("a = " .. a .. " | b = " .. b)

printh("")
printh("Unary arithmetic operators:")
a = 3
printh("-a = " .. -a)


-- BITWISE OPERATORS
printh("")
printh("Binary bitwise operators:")
a, b = 0x3, 0x2
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
printh("a & b = " .. tostr(a & b,true))
printh("a | b = " .. tostr(a | b,true))
printh("a ~ b = " .. tostr(a ~ b,true))
printh("a ^^ b = " .. tostr(a ^^ b,true))
printh("a >> b = " .. tostr(a >> b,true))
printh("a << b = " .. tostr(a << b,true))

printh("")
printh("Bitwise shorthand assignment operators:")
a, b = 0x3, 0x2
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
printh("a &= b")
a &= b
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
printh("a |= b")
a |= b
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
printh("a ~= b is not supported. Picotron uses ^^= instead of ~= for the xor shorthand assignment operator, as ~= would overlap with the \"not equal\" relational operator.")
--a ~= b -- Uncomment and run in Picotron for syntax error
printh("a ^^= b")
a ^^= b
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
printh("a >>= b")
a >>= b
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
printh("a <<= b")
a <<= b
printh("a = " .. tostr(a,true) .. " | b = " .. tostr(b,true))
-- Unsupported binary operators from Pico-8:
printh("a >>> b from Pico-8 is not supported")
--a >>> b -- Uncomment and run in Picotron for syntax error
-- >>> aka. LSHR(X, N) -- LOGICAL RIGHT SHIFT (ZEROS COMES IN FROM THE LEFT)
printh("a <<> b from Pico-8 is not supported")
--a <<> b -- Uncomment and run in Picotron for syntax error
-- <<> aka. ROTL(X, N) -- ROTATE ALL BITS IN X LEFT BY N PLACES
printh("a >>< b from Pico-8 is not supported")
--a >>< b -- Uncomment and run in Picotron for syntax error
-- >>< aka. ROTR(X, N) -- ROTATE ALL BITS IN X RIGHT BY N PLACES

printh("")
printh("Unary bitwise operators:")
a = 0x3
printh("a = " .. tostr(a,true))
printh("~a = " .. tostr(~a,true))
printh("!a is not supported.")
--printh("!a = " .. tostr(!a)) -- Uncomment and run in Picotron for syntax error.


-- RELATIONAL OPERATORS
printh("")
printh("Relational operators:")
a, b = 3, 2
printh("a = " .. a .. " | b = " .. b)
printh("a < b = " .. tostr(a < b))
printh("a > b = " .. tostr(a > b))
printh("a <= b = " .. tostr(a <= b))
printh("a >= b = " .. tostr(a >= b))
printh("a ~=b = " .. tostr(a ~= b))
printh("a != b = " .. tostr(a != b))
printh("a == b = " .. tostr(a == b))


-- LOGICAL OPERATORS
printh("")
printh("Logical operators:")
a, b = true, false
printh("a = " .. tostr(a) .. " | b = " .. tostr(b))
printh("a and b = " .. tostr(a and b))
printh("a or b = " .. tostr(a or b))
printh("not a = " .. tostr(not a))


-- CONCATENATION OPERATOR
printh("")
printh("Concatenation operator:")
a, b = "hello", "world"
printh("a = \"" .. tostr(a) .. "\" | b = \"" .. tostr(b).."\"")
printh("a .. b = \"" .. (a .. b).. "\"")

printh("")
printh("Concatenation shorthand assignment operator:")
a, b = "hello", "world"
printh("a = \"" .. tostr(a) .. "\" | b = \"" .. tostr(b).."\"")
printh("a ..= b")
a ..= b
printh("a = \"" .. tostr(a) .. "\" | b = \"" .. tostr(b).."\"")


-- LENGTH OPERATOR
printh("")
printh("Length operator:")
a = "hello"
printh("a = \"" .. tostr(a) .. "\"")
printh("#a = " .. #a)

-- MISCELLANEOUS UNARY PICOTRON OPERATORS
printh("")
printh("Miscellaneous unary Picotron operators:")
printh("?\"hello\": (prints \"hello\" in the picotron console, not host os console)")
?"hello"
printh("*5000 = "..(*0x5000))
printh("string.format(\"%016X\", *0x5000) = "..string.format("%016X", *0x5000))
