pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- rpg
-- by akd

#include lib/shallow_copy.lua

--[[
  How to spend 256b to store the rpg character?

  2^4 = 16
  2^8 = 255
  2^16 = 65,536
  2^24 = 16,777,216
  2^32 = 4,294,967,296

  4 bytes: Experience points
  12 bytes: (bitfield) 96 skill points (can likely be compressed if skills have dependencies)

  Loot is tough. It would be nice to have a proper loot system. With item types, tiered affixes (no affix value ranges tho), and rarity. But it takes a lot of space.

  Sample item:
  Strong boots of haste (Magic, 2 affixes)
  T2 Str: +4 Strength
  T3 Agility: +6% Movement speed

  Assuming a pool of 16 stat types, each with 16 tiers, an item could be coded using:
  4 bits: specifying the item's slot type
  2 bytes: 16 bit flag specifying what stat types are on the item
  4 bytes: 8x4 bits specifying the item's tier (1-16) in each of the max 8 stat types present on the item (as specified in the bit flag before)

  With 9 item slot types, 10 active at a time,
  (Helmet, amulet, body, belt, boots, gloves, 2x rings, main hand, off hand)
  That makes 10 x 6.5 bytes = 65 bytes used to store equipment.

  65 bytes: Equipment

  It would be nice to have at least double that in inventory. 65 x 2 = 130 bytes.

  130 bytes: Inventory

  4 + 12 + 65 + 130 = 211

  Maybe we are missing some world progress data?
]]

-- 16 equipment types (4 bits)
local equipment_types = { "main-hand", "off-hand", "head", "body", "waist", "legs", "feet", "neck", "amulet", "ring" }
local affix_tiers = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 }
local affix_type_keys = {
  "health",
  "flatDamage",
  "percentDamage",
  "attackSpeed",
  "criticalChance",
  "criticalDamage",
  "movementSpeed",
  "dodgeChance"
}
local num_affix_types = #affix_type_keys
local affix_types = {
  health = {
    shortName = function(tier) return "t" .. tier .. " hp" end,
    value = function(tier) return 5 * tier end,
    str = function(tier, value) return "+" .. value .. " hp" end,
    longStr = function(tier, value) return "+" .. value .. " health points" end
  },
  flatDamage = {
    shortName = function(tier) return "t" .. tier .. " fd" end,
    value = function(tier) return 3 * tier end,
    str = function(tier, value) return "+" .. value .. " dmg" end,
    longStr = function(tier, value) return "+" .. value .. " damage" end
  },
  percentDamage = {
    shortName = function(tier) return "t" .. tier .. " pd" end,
    value = function(tier) return 3 * tier end,
    str = function(tier, value) return "+" .. value .. "% dmg" end,
    longStr = function(tier, value) return "+" .. value .. "% damage" end
  },
  attackSpeed = {
    shortName = function(tier) return "t" .. tier .. " as" end,
    value = function(tier) return 1 * tier end,
    str = function(tier, value) return "+" .. value .. "% att. sp." end,
    longStr = function(tier, value) return "+" .. value .. "% attack speed" end
  },
  criticalChance = {
    shortName = function(tier) return "t" .. tier .. " cc" end,
    value = function(tier) return 1 * tier end,
    str = function(tier, value) return "+" .. value .. "% crit ch." end,
    longStr = function(tier, value) return "+" .. value .. "% critical chance" end
  },
  criticalDamage = {
    shortName = function(tier) return "t" .. tier .. " cd" end,
    value = function(tier) return 3 * tier end,
    str = function(tier, value) return "+" .. value .. "% crit dmg" end,
    longStr = function(tier, value) return "+" .. value .. "% critical damage" end
  },
  movementSpeed = {
    shortName = function(tier) return "t" .. tier .. " ms" end,
    value = function(tier) return 2 * tier end,
    str = function(tier, value) return "+" .. value .. "% move sp." end,
    longStr = function(tier, value) return "+" .. value .. "% movement speed" end
  },
  dodgeChance = {
    shortName = function(tier) return "t" .. tier .. " dc" end,
    value = function(tier) return ceil(0.5 * tier) end,
    str = function(tier, value) return "+" .. value .. "% dodge ch." end,
    longStr = function(tier, value) return "+" .. value .. "% dodge chance" end
  }
}
local max_affixes_per_item = 6

function generateItem()
  local equipment_type = rnd(equipment_types)

  local availableAffixesBag = shallow_copy(affix_type_keys)
  local numAffixes = ceil(rnd(max_affixes_per_item))
  local affixes = {}
  for i = 1, numAffixes do
    local affix_type = rnd(availableAffixesBag)
    local tier = rnd(affix_tiers)
    affixes[affix_type] = tier
    del(availableAffixesBag, affix_type)
  end
  return {
    equipment_type = equipment_type,
    affixes = affixes
  }
end

local item = generateItem()

local f = -1
function _update60()
  f += 1

  -- Every 5 seconds
  if f % 300 == 0 then
    item = generateItem()
  end
end

function _draw()
  cls()
  local tier = 0
  for key, val in pairs(item.affixes) do
    tier = tier + val
  end
  print("t" .. tier .. " " .. item.equipment_type, 10, 10)
  local y = 20
  for affix_type, affix_tier in pairs(item.affixes) do
    local affix_data = affix_types[affix_type]
    local affix_value = affix_data.value(affix_tier)
    print("t" .. affix_tier .. " " .. affix_data.str(affix_tier, affix_value), 10, y)
    y = y + 8
  end
end

__gfx__
00000000080800000000700000007000000070000000700000007000000700006777600000000000000000000000000000000000000000000000000000000000
00000000888880000007000000070000000700000007000000070000067660007ccc700000000000000000000000000000000000000000000000000000000000
0000000088888000f0700000f0700000f0700000f0700000f0700000007000007ccc700000000000000000000000000000000000000000000000000000000000
00000000088800000f0000000f0000000f0000000f0000000f0000007776000007c7000000000000000000000000000000000000000000000000000000000000
0000000000800000f0f00000f0f00000f0f00000f0f00000f0f00000000700000070000000000000000000000000000000000000000000000000000000000000
