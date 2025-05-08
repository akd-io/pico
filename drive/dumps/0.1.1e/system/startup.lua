

-- load settings
local sdat = fetch"/appdata/system/settings.pod"
if type(sdat) ~= "table" -- doesn't exist or needs to be mended
then
	-- install defaults
	sdat = fetch"/system/misc/default_settings.pod"
	if (stat(317) > 0) then
		sdat.wallpaper = "/system/wallpapers/pattern.p64"
		sdat.theme = "/system/themes/classic.theme"
	end
	store("/appdata/system/settings.pod", sdat)
end

-- settings added since first release should default to a non-nil value

if (sdat.anywhen == nil) then
	sdat.anywhen = true
	store("/appdata/system/settings.pod", sdat)
end

if (sdat.pixel_scale == nil) then
	sdat.pixel_scale = 2
	store("/appdata/system/settings.pod", sdat)
end


-- install default desktop items (always re-install for player)
local ff = ls("/desktop")
if (not ff or #ff == 0 or stat(317) > 0) then
	mkdir ("/desktop") -- just in case
	cp("/system/misc/drive.loc", "/desktop/drive.loc")
	cp("/system/misc/readme.txt", "/desktop/readme.txt")
end

-- mend drive shortcut (could save over it by accident in 0.1.0b)
-- 0.1.0c: also fix missing icon metadata
if fstat("/desktop/drive.loc") then
	local dd,mm = fetch("/desktop/drive.loc")
	if (not dd or not dd.location or not mm or not mm.icon) cp("/system/misc/drive.loc", "/desktop/drive.loc")
end
if fstat("/desktop/readme.txt") then
	local dd,mm = fetch("/desktop/readme.txt") -- fetch_metadata not defined yet
	if (not mm or not mm.icon or mm.pod_format ~= "raw") cp("/system/misc/readme.txt", "/desktop/readme.txt")
end


-- present working cartridge
local num = 0
local num=0
while (fstat("/untitled"..num..".p64") and num < 64) num += 1
store("/ram/system/pwc.pod", "/untitled"..num..".p64")


-- custom startup could opt to run different window / program manager
create_process("/system/pm/pm.lua")
create_process("/system/wm/wm.lua")

if (stat(315) > 0) then
	-- headless script
	create_process(stat(316))
	return
end

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
local system_meta = _fetch_metadata_from_file("/system/.info.pod") or {}
if (system_meta.version ~= system_version) then
	printh("** version mismatch // /system: "..system_meta.version.." expects binaries: "..system_version)
	send_message(3, {event="report_error", content = "** system version mismatch **"})
	send_message(3, {event="report_error", content = "/system version is: "..system_meta.version})
	send_message(3, {event="report_error", content = "this build expects: "..system_version})
end
------------------------------------------------------------------------------------------------


-- starting userland programs (with blank untitled files)

-- open editors and create default cart layout
mkdir "/ram/cart/gfx"
mkdir "/ram/cart/map"
mkdir "/ram/cart/sfx"

-- default file name are used by the automatic resource loader
-- (in many cases only these 4 files are needed in a cartridge)

if stat(317) == 0 then -- no tool workspaces for exports / bbs player
	create_process("/system/apps/code.p64", {argv={"/ram/cart/main.lua"}})
	create_process("/system/apps/gfx.p64", {argv={"/ram/cart/gfx/0.gfx"}})
	create_process("/system/apps/map.p64", {argv={"/ram/cart/map/0.map"}})
	create_process("/system/apps/sfx.p64", {argv={"/ram/cart/sfx/0.sfx"}})
end

-- new desktop workspace

local sdat = fetch"/appdata/system/settings.pod"
local wallpaper = (sdat and sdat.wallpaper) or "/system/wallpapers/pattern.p64"
if (not fstat(wallpaper)) wallpaper = "/system/wallpapers/pattern.p64"

-- start in desktop workspace (so show_in_workspace = true)
create_process(wallpaper, {window_attribs = {workspace = "new", desktop_path = "/desktop", wallpaper=true, show_in_workspace=true}})

create_process("/system/misc/tooltray.p64", {window_attribs = {workspace = "tooltray", desktop_path = "/appdata/system/desktop2", wallpaper = true}})

if stat(317) == 0 then -- no fullscreen terminal for exports / bbs player
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
end


-- aliases

mount("/system/util/dir.lua","/system/util/ls.lua")   
mount("/system/util/edit.lua","/system/util/open.lua") 

-- populate tooltray with widgets

create_process("/system/misc/load_widgets.lua")



if stat(317) > 0 then 
	-- player startup
	-- mount /system and anything in /cart using fstat

	function fstat_all(path)
		local l = ls(path)
		if (l) then
			for i=1,#l do
				local k = fstat(path.."/"..l[i])
				if (k == "folder") fstat_all(path.."/"..l[i])
			end
		end
	end
	fstat_all("/system")
	fstat_all("/cart")

	-- no more cartridge mounting (exports are only allowed to load/run the carts they were exported with)
	
	if ((stat(317) & 0x3) == 0x3) then -- player that has embedded rom
		-- printh("** sending signal 39: disabling mounting **")
		_signal(39) 
	end

	create_process("/system/misc/load_player.lua")

	-- (don't need custom startup.lua -- the exported / bbs cart itself can play that role)

elseif fstat("/appdata/system/startup.lua") then 

	-- userland startup

	create_process("/appdata/system/startup.lua")

end




