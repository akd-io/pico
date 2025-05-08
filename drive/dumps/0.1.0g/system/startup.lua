
-- load settings
local sdat = fetch"/appdata/system/settings.pod"
if not sdat then
	-- install defaults
	sdat = fetch"/system/misc/default_settings.pod"
	store("/appdata/system/settings.pod", sdat)
end

-- newer settings that should default to a non-nil value
if (sdat.anywhen == nil) then
	sdat.anywhen = true
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

-- mend drive shortcut (could save over it by accident in 0.1.0b)
local dd = fetch("/desktop/drive.loc")
if (dd and not dd.location) then
	store("/desktop/drive.loc", fetch("/system/misc/drive.loc"))
	notify("mended: /desktop/drive.loc")
end

-- present working cartridge
local num = 0
local num=0
while (fstat("/untitled"..num..".p64") and num < 64) num += 1
store("/ram/system/pwc.pod", "/untitled"..num..".p64")


-- custom startup could opt to run different window / program manager
create_process("/system/pm/pm.lua")
create_process("/system/wm/wm.lua")

------------------------------------------------------------------------------------------------
--   hold down lctrl + rctrl on boot to start with a minimal terminal setup
--   useful for recovering from borked /appdata/system/startup.lua
------------------------------------------------------------------------------------------------

-- give a guaranteed short window to skip

for i=1,20 do
	flip()
	if (stat(988) > 0) bypass = true _signal(35) 
end

if (bypass) then
	create_process("/system/apps/terminal.lua", 
		{
			window_attribs = {fullscreen = true, pwc_output = true, immortal = true},
			immortal   = true -- exit() is a NOP; separate from window attribute :/
		}
	)
	return
end

------------------------------------------------------------------------------------------------


local runtime_version, system_version = stat(5)
local system_meta = fetch_metadata("/system") or {}
if (system_meta.version ~= system_version) then
	printh("** version mismatch // /system: "..system_meta.version.." expects binaries: "..system_version)
	send_message(3, {event="report_error", content = "** system version mismatch **"})
	send_message(3, {event="report_error", content = "/system version is: "..system_meta.version})
	send_message(3, {event="report_error", content = "this build expects: "..system_version})
end



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
if (not fstat(wallpaper)) wallpaper = "/system/wallpapers/pattern.p64"

-- start in desktop workspace (so show_in_workspace = true)
create_process(wallpaper, {window_attribs = {workspace = "new", desktop_path = "/desktop", wallpaper=true, show_in_workspace=true}})

create_process("/system/tooltray/tooltray.p64", {window_attribs = {workspace = "tooltray", desktop_path = "/appdata/system/desktop2", wallpaper = true}})
create_process("/system/tooltray/clock.lua", {window_attribs = {workspace = "tooltray", x=366, y=7, width=75, height=20}})
create_process("/system/tooltray/eyes.lua", {window_attribs = {workspace = "tooltray", x=445, y=2, width=32, height=16}})


create_process("/system/apps/terminal.lua", 
	{
		window_attribs = {
			fullscreen = true,
			pwc_output = true,        -- run present working cartridge in this window
			immortal   = true         -- no close pulldown
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




