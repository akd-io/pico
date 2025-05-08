--[[pod_format="raw",created="2024-03-14 04:10:03",modified="2024-03-14 04:20:48",revision=8]]

-- load settings
local sdat = fetch"/appdata/system/settings.pod"
if not sdat then
	-- install defaults
	sdat = fetch"/system/misc/default_settings.pod"
	store("/appdata/system/settings.pod", sdat)
end

-- install default desktop items
local ff = ls("/desktop")
if (not ff or #ff == 0) then
	mkdir ("/desktop") -- just in case
	store("/desktop/drive.loc", fetch("/system/misc/drive.loc"))
	store("/desktop/readme.txt", fetch("/system/misc/readme.txt"))
--	cp("/system/misc/drive.loc", "/desktop/drive.loc")
--	cp("/system/misc/readme.txt", "/desktop/readme.txt")
end

-- present working cartridge
store("/ram/system/pwc.pod", "/untitled.p64")


-- custom startup could opt to run different window / program manager
create_process("/system/pm/pm.lua")
create_process("/system/wm/wm.lua")


-- starting userland programs (with blank untitled files)

-- open editors and create default cart layout
mkdir "/ram/cart/gfx"
mkdir "/ram/cart/map"
mkdir "/ram/cart/sfx"

-- default file name are used by the automatic resource loader
-- (in many cases only these 4 files are needed in a cartridge)

create_process("/system/apps/code.p64", {argv={"/ram/cart/main.lua"}})
create_process("/system/apps/gfx.p64", {argv={"/ram/cart/gfx/0.gfx"}})
create_process("/system/apps/map.p64", {argv={"/ram/cart/map/0.map"}})
create_process("/system/apps/sfx.p64", {argv={"/ram/cart/sfx/0.sfx"}})


-- new desktop workspace

local sdat = fetch"/appdata/system/settings.pod"
local wallpaper = (sdat and sdat.wallpaper) or "/system/wallpapers/pattern.p64"

create_process(wallpaper, {window_attribs = {workspace = "new", desktop_path = "/desktop", wallpaper=true}})


create_process("/system/tooltray/tooltray.p64", {window_attribs = {workspace = "tooltray", desktop_path = "/appdata/system/desktop2", wallpaper = true}})

-- to do: timezones
create_process("/system/tooltray/clock.lua", {window_attribs = {workspace = "tooltray", x=370, y=7, width=75, height=20}})

create_process("/system/tooltray/eyes.lua", {window_attribs = {workspace = "tooltray", x=445, y=2, width=32, height=16}})


create_process("/system/apps/terminal.lua", 
	{
		window_attribs = {
			fullscreen = true,
			pwc_output = true, -- run programs in this window
			immortal   = true  -- no close pulldown
		},
		immortal   = true -- exit() is a NOP
	}
)


-- aliases

mount("/system/util/dir.lua","/system/util/ls.lua")   
mount("/system/util/edit.lua","/system/util/open.lua") 


-- daisy chain 

if fstat("/appdata/system/startup.lua") then 
	create_process("/appdata/system/startup.lua")
end





