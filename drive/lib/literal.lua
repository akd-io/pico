local magicCharacters = "^$()%.[]*+-?" -- https://www.lua.org/manual/5.4/manual.html#6.4.1
local magicCharacterClass = "[" .. magicCharacters:gsub(".", "%%%1") .. "]"
function literal(str)
  -- Prepend every magic char with a `%` to escape it.
  return str:gsub(magicCharacterClass, "%%%1")
end
