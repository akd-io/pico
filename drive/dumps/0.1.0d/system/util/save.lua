--[[pod_format="raw",created="2024-03-23 17:34:07",modified="2024-03-23 17:36:35",revision=4]]
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

if (not save_as) then
	print("error: filenames can only include letters, numbers, or ._-")
	exit()
end


if (save_as:sub(1,10) == "/ram/cart/") then
	print("error: can not save the working cartridge inside itself.")
	print("try \"cd /\" first")
	exit()
end

if (save_as:sub(1,8) == "/system/") then
	print("** warning ** saving to /system will not persist to disk")
end


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


-- set runtime version metadata
-- when loading a cartridge, runtime should be greater or equal to this
-- (splore: refuse to run; otherwise: show a warning)
store_metadata("/ram/cart", {runtime = stat(5)})

-- copy /ram/cart to present working cartridge
local result = cp("/ram/cart", save_as)


if (result) then
	print(result)
	exit(1)
end

store("/ram/system/pwc.pod", save_as)

-- temporary warning for 0.1
-- don't want /system to be write-only because want to allow things like sedit
if (save_as:sub(1,8) == "/system/") then
	notify("saved "..save_as.."    *** note: changes to /system are in ram only ***")
end


print("saved "..save_as)

