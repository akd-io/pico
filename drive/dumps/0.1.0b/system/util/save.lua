--[[
	save

		copy from /ram/cart to present working cartridge location
		e.g.
		cp("/ram/cart", "/mycart.p64")

]]

cd(env().path)

local argv = env().argv or {}

local save_as = argv[1] or fetch("/ram/system/pwc.pod") or "/untitled.p64"
save_as = fullpath(save_as)

-- add extension when none is given (to do: how to save to a regular folder with no extension in name? maybe just don't do that?)
if (sub(save_as, -4) ~= ".p64" and sub(save_as, -8) ~= ".p64.rom" and sub(save_as, -8) ~= ".p64.png") then
	save_as ..= ".p64"
end

-- save all files and metadata
-- hack: need to wait to complete at each step. to do: need the concept of a blocking message
send_message(3, {event="save_working_cart_files"})
for i=1,12 do flip() end
send_message(3, {event="save_open_locations_metadata"})
for i=1,4 do flip() end

-- copy /ram/cart to present working cartridge
local result = cp("/ram/cart", save_as)


if (result) then
	print(result)
	exit(1)
end

store("/ram/system/pwc.pod", save_as)

print("saved "..save_as)

