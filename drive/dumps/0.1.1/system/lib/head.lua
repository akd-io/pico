--[[pod_format="raw",created="2025-04-27 16:05:05",modified="2025-04-27 16:05:05",revision=0]]
--[[

	head.lua -- kernal space header for each process
	(c) Lexaloffle Games LLP

]]

do

-- bootstrap
local _env = function() return env() end

local _stop = _stop
local _print_p8scii = _print_p8scii
local _map_ram = _map_ram
local _ppeek = _ppeek
local _create_process_from_code = _create_process_from_code
local _unmap_ram = _unmap_ram
local _get_process_display_size = _get_process_display_size
local _run_process_slice = _run_process_slice

local _get_clipboard_text = _get_clipboard_text
local _blit_process_video = _blit_process_video
local _set_clipboard_text = _set_clipboard_text
local _req_clipboard_text = _req_clipboard_text
local _set_spr = _set_spr
local _ppeek4 = _ppeek4
local _set_draw_target = _set_draw_target
local _get_process_list = _get_process_list
local _pod = _pod
local _kill_process = _kill_process
local _read_message = _read_message
local _draw_map = _draw_map
local _halt = _halt


local _signal = _signal
local _unmap
local _split = split
local _printh = _printh
local _tostring  = tostring

-- sprites are owned by head -- process can assume exists
local _spr = {} 


function reset()

	-- reset palette (including scanline palette selection, rgb palette)

	pal()

	-- line drawing state

	memset(0x551f, 0, 9)

	-- bitplane masks

	poke(0x5508, 0x3f) -- read mask    //  masks raw draw colour (8-bit sprite pixel or parameter)
	poke(0x5509, 0x3f) -- write mask   //  determines which bits to write to
	poke(0x550a, 0x3f) -- target mask  //  (sprites)  applies to colour table lookup & selection
	poke(0x550b, 0x00) -- target mask  //  (shapes)   applies to colour table lookup & selection

	-- draw colour

	color(6)

	-- fill pattern 0x5500

	fillp()

	-- fonts (reset really does reset everthing!)

	poke(0x5f56, 0x40) -- primary font
	poke(0x5f57, 0x56) -- secondary font
	poke(0x4000,get(fetch"/system/fonts/lil.font"))
	poke(0x5600,get(fetch"/system/fonts/p8.font"))

	-- set tab width to be a multiple of char width

	poke(0x5606, (@0x5600) * 4)
	poke(0x5605, 0x2)             -- apply tabs relative to home

	-- mouselock event sensitivity, move sensitivity (64 means x1.0)
	poke(0x5f28, 64)
	poke(0x5f29, 64)


end


-- from sfx.p64 -- create default instrument 0. Want note(48) to do something useful out of the box.
-- later: more default instruments? copy PICO-8 set? (hrmf)
-- want to nudge users towards creating / curating their own starter set
-- a common set instruments that become the "picotron sound" will likely form either way // ref: jungle_flute.xi

local function clear_instrument(i)
	local addr = 0x40000 + i * 0x200
	memset(addr, 0, 0x200)
	
	-- node 0: root
	poke(addr + (0 * 32), -- node 0
	
			0,    -- parent (0x7)  op (0xf0)
			1,    -- kind (0x0f): 1 root  kind_p (0xf0): 0  -- wavetable_index
			0,    -- flags
			0,    -- unused extra
				
			-- MVALs:  kind/flags,  val0, val1, envelope_index
			
			0x2|0x4,0x20,0,0,  -- volume: mult. 0x40 is max (-0x40 to invert, 0x7f to overamp)
			0x1,0,0,0,     -- pan:   add. center
			0x1,0,0,0,     -- tune: +0 -- 0,48,0,0 absolute for middle c (c4) 261.6 Hz
			0x1,0,0,0,     -- bend: none
			-- following shouldn't be in root
			0x0,0,0,0,     -- wave: use wave 0 
			0x0,0,0,0      -- phase 
	)
	
	
	-- node 1: triangle wave
	poke(addr + (1 * 32), -- instrument 0, node 1
	
			0,    -- parent (0x7)  op (0xf0)
			2,    -- kind (0x0f): 2 osc  kind_p (0xf0): 0  -- wavetable_index
			0,    -- flags
			0,    -- unused extra
				
			-- MVALs:  kind/flags,  val0, val1, envelope_index
			
			0x2,0x20,0,0,  -- volume: mult. 0x40 is max (-0x40 to invert, 0x7f to overamp)
			0x1,0,0,0,     -- pan:   add. center
			0x21,0,0,0,    -- tune: +0 -- 0,48,0,0 absolute for middle c (c4) 261.6 Hz
			               -- tune is quantized to semitones with 0x20
			0x1,0,0,0,     -- bend: none
			0x0,0x40,0,0,  -- wave: triangle
			0x0,0,0,0      -- phase 
	)

end


local function init_runtime_state()

	-- experiment: always start with a display
	-- should be able to start drawing stuff in _init!
	-- extra 128k per process, but not many headless processes
--[[
	_disp = userdata("u8", 480, 270)
	memmap(0x10000, _disp)
	set_draw_target() -- reset target to display\
	poke2(0x5478, 480, 270)
	poke (0x547c, 0)  -- video mode
]]

	-- new seed on each run
	srand()

	-- default map
	memmap(userdata("i16", 32, 32), 0x100000)

	-- clear sprites
	_spr = {}

	-- default sfx: single inst 0
	clear_instrument(0)

	-- reset() does most of the work but is specific to draw state; sometimes want to reset() at start of _draw()!  (ref: jelpi)
	reset()

end


local function get_short_prog_name(p)
	if (not p) then return "no_prog_name" end
	p = _split(p, "/", false)
	p = _split(p[#p], ".", false)[1]
	return p
end


function create_process(prog_name, env_patch, do_debug)

	if (_env().sandboxed) return nil, "sandboxed process can not create_process()"

	prog_name = fullpath(prog_name)

	-- .p64 files: find boot file in root of .p64 (and thus set default path there too)
	local boot_file = prog_name
	if  string.sub(prog_name,-4) == ".p64"     or 
		string.sub(prog_name,-8) == ".p64.rom" or
		string.sub(prog_name,-8) == ".p64.png"
	then
		boot_file ..= "/main.lua"

		-- only check runtime on carts; not stored on lua files
		--[[
			** commented: fetch_metadata not available

		local meta = fetch_metadata(prog_name)
		if (meta and type(meta.runtime) == "number" and meta.runtime > stat(5)) then
			notify("** warning: running cartridge with future runtime version **")
		end
		]]
	end

--	printh("create_process "..prog_name.." ("..boot_file..") env: "..pod(env_patch))

	--===== construct new environment table if needed ======

--	local new_env = env() and unpod(pod(_env())) or {}
	local new_env = {} -- don't inherit anything! env means "launch parameters"

	-- default path is same directory as boot file
	local segs = _split(boot_file,"/",false)
	local program_path = string.sub(boot_file, 1, -#segs[#segs] - 2)


	-- add new attributes from env_patch (note: can copy trees)
	if (env_patch) then
		for k,v in pairs(env_patch) do
			new_env[k] = v
		end
	end


	-- when corunning, start in folder of corun program
	-- needs to happen here so that load_resources has the correct path
	-- to do: shouldn't terminal be able to have its own resources / includes?
	if (new_env.corun_program) then
		local ppath = fullpath(new_env.corun_program)
		local segs = _split(ppath,"/",false)
		program_path = string.sub(ppath, 1, -#segs[#segs] - 2)
	end


	
	-- add system env info

	new_env.prog_name = prog_name
	new_env.title = get_short_prog_name(prog_name)
	new_env.parent_pid = pid()
	new_env.argv = new_env.argv or {} -- guaranteed to exist at least as an empty table

	-- sandboxed cart must have a cart_id for /appdata to map to
	if (new_env.sandboxed and not new_env.cart_id) printh("bad cart_id -- can't sandbox") return nil
	if (new_env.sandboxed) then
		--printh("creating new sandboxed process with appdata: ".."/appdata/bbs/"..new_env.cart_id)
		mkdir("/appdata/bbs")
		-- mkdir("/appdata/bbs/"..new_env.cart_id) -- create on write;
	end


	local str = [[

		local head_code = load(fetch("/system/lib/head.lua"), "@/system/lib/head.lua", "t", _ENV)
		if (not head_code) then printh"*** ERROR: could not load head. borked file system / out of pfile slots? ***" end
		head_code()

		env = function() 
			return ]].._pod(new_env,0x0)..[[
		end

		include("/system/lib/legacy.lua")
		include("/system/lib/fs.lua")
		include("/system/lib/api.lua")		
		include("/system/lib/events.lua")
		include("/system/lib/gui.lua")
		include("/system/lib/app_menu.lua")
		include("/system/lib/wrangle.lua")
		include("/system/lib/theme.lua")

		_signal(38) -- start of userland code (for memory accounting)

		
		
		
		-- always start in program path
		cd("]]..program_path..[[")

		-- autoload resources (must be after setting pwd)
		include("/system/lib/resources.lua")

		-- to do: preprocess_file() here // update: no need!
		include("]]..boot_file..[[")

		-- footer; includes mainloop
		include("/system/lib/foot.lua")

	]]

	-- printh("create_process with env: "..pod(env))

	local proc_id = _create_process_from_code(str, get_short_prog_name(prog_name))

	
	if (not proc_id) then
		
		return nil
	end

--	printh("$ created process "..proc_id..": "..prog_name.." ppath:"..program_path)

	if (env_patch and env_patch.window_attribs and env_patch.window_attribs.pwc_output) then
		store("/ram/system/pop.pod", proc_id) -- present output process
	end

	if (env_patch and env_patch.blocking) then
		-- this process should stop running until proc_id is completed
		
	end


	return proc_id

end

-- manage process-level data: dispay, env

	-- hidden from userland program
	local _disp = nil
	local _target = nil
	local userdata_ref = {} -- hold mapped userdata references
	local _current_map = nil -- only really needed for handling automatic reference release

	-- default to display
	function set_draw_target(d)

		-- 0.1.0h: unmap existing target (garbage collection)
		_unmap(_target, 0x10000)
		
		d = d or _disp

		local ret = _target
		_target = d
		_set_draw_target(d)

		-- map to 0x10000 -- want to poke(0x10000) in terminal, or use specialised poke-based routines as usual
		-- draw target (and display data source) is reset to display after each _draw() in foot
		memmap(d, 0x10000)
		
		return ret

	end

	function get_draw_target()
		return _target
	end

	-- used to have a set_display to match, but only need get_display(). (keep name though; display() feels too ambiguous)
	function get_display()
		return _disp
	end

	-- starting environment: none; overwritten by injected process code
	function env() return {} end

	---------------------------------------------------------------------------------------------------

	local first_set_window_call = true

	local function set_window_1(attribs)

		-- to do: shouldn't be needed by window manager itself (?)
		-- to what extent should the wm be considered a visual application that happens to be running in kernel?
		-- if (pid() <= 3) return

		attribs = attribs or {}


		-- on first call, observe attributes from env().window_attribs
		-- they **overwrite** any same key attributes passed to set_window
		-- (includes pwc_output set by window manager)

		if (first_set_window_call) then

			first_set_window_call = false
		
			-- ** _env not defined yet!
			if type(_env().window_attribs) == "table" then
				for k,v in pairs(_env().window_attribs) do
					attribs[k] = v
				end
			end

			-- set the program this window was created with (for workspace matching)

			attribs.prog = _env().prog_name

			-- special case: when corunning a program under terminal, program name is /ram/cart/main.lua
			-- (search /ram/cart/main.lua in wrangle.lua -- works with workspace matching for tabs)

			if (attribs.prog == "/system/apps/terminal.lua") then
				attribs.prog = "/ram/cart/main.lua"
			end

			
			-- first call: decide on an initial window size so that can immediately create display

			-- default size: fullscreen (dimensions set below)
			if not attribs.tabbed and (not attribs.width or not attribs.height) then
				attribs.fullscreen = true
			end

			-- not fullscreen, tabbed or desktop, and (explicitly or implicitly) moveable -> assume regular moveable desktop window
			if (not attribs.fullscreen and not attribs.tabbed and not attribs.wallpaper and
				(attribs.moveable == nil or attribs.moveable == true)) 
			then
				if (attribs.has_frame  == nil) attribs.has_frame  = true
				if (attribs.moveable   == nil) attribs.moveable   = true
				if (attribs.resizeable == nil) attribs.resizeable = true
			end


			-- wallpaper has a default z of -1000
			if (attribs.wallpaper) then
				attribs.z = attribs.z or -1000 -- filenav is -999
			end


		end

		-- video mode implies fullscreen

		if (attribs.video_mode) then
			attribs.fullscreen = true
		end


		-- setting fullscreen implies a size and position

		if attribs.fullscreen then
			attribs.width = 480
			attribs.height = 270
			attribs.x = 0
			attribs.y = 0
		end

		-- setting tabbed implies a size and position  // but might be altered by wm

		if attribs.tabbed then
			attribs.fullscreen = nil
			attribs.width = 480
			attribs.height = 248+11
			attribs.x = 0
			attribs.y = 11
		end

		-- setting new display size
		if attribs.width and attribs.height then

			local scale = 1
			if (attribs.video_mode == 3) scale = 2 -- 240x135
			if (attribs.video_mode == 4) scale = 3 -- 160x90
			local new_display_w = attribs.width  / scale
			local new_display_h = attribs.height / scale


			local w,h = -1,-1
			if (get_display()) then
				w = get_display():width()
				h = get_display():height()
			end

			-- create new bitmap when display size changes
			if (w != new_display_w or h != new_display_h) then
				-- this used to call set_display(); moved inline as it should only ever happen here

				-- 0.1.0h: unmap existing display (garbage collcetion)
				_unmap(_disp, 0x10000)

				_disp = userdata("u8", new_display_w, new_display_h)
				memmap(_disp, 0x10000)
				set_draw_target() -- reset target to display

				-- set display attributes in ram
				poke2(0x5478, new_display_w)
				poke2(0x547a, new_display_h)

				poke (0x547c, attribs.video_mode or 0)

				poke(0x547f, peek(0x547f) & ~0x2) -- safety: clear hold_frame bit
				-- 0x547d is blitting mask; keep previous value
			end
		end

		send_message(3, {event="set_window", attribs = attribs})

	end

	-- set preferred size; wm can still override
	function window(w, h, attribs)

		-- this function wrangles parameters;
		-- set_window_1 doesn't do any further transformation / validation on parameters

		if (type(w) == "table") then
			attribs = w
			w,h = nil,nil

			-- special case: adjust position by dx, dy
			-- discard other 
			if (attribs.dx or attribs.dy) then
				send_message(3, {event="move_window", dx=attribs.dx, dy=attribs.dy})
				return
			end

		end

		attribs = attribs or {}
		attribs.width = attribs.width or w
		attribs.height = attribs.height or h

		return set_window_1(attribs)
	end
	
------- standard library   -----  (see also api.lua for temporary api implementation for functions that should be rewritten in C)

--  deleteme
--	load_54 = load
--	loadstring = load
--	load = load_object -- to do: don't use load for anything -- too ambiguous and confusing! just "fetch" 


	-- to do: remove use of _get_system_global when these values are standardized
--[[
	local sys_global = {
		pm_proc_id = 2,
		wm_proc_id = 3,
		cart_path = "/ram/cart"
	}
	function _get_system_global(k)
		if (sys_global[k]) return sys_global[k]
		printh("**** _get_system_global failed for key: "..k)
	end
]]

	-- fullscreen videomode with no cursor
	function vid(mode)
		window{
			video_mode = mode,
			cursor = 0
		}
	end

	-- immediately close program & window
	function exit(exit_code)
		if (_env().immortal) return
		
		--send_message(pid(), {event="halt"})
		send_message(2, {event="kill_process", proc_id=pid()})
		_halt() -- stop executing immediately
	end

	-- stop executing in a resumable way 
	-- use for debugging via terminal: stop when something of interest happens and then inspect state
	function stop(txt, ...)
		if (txt) print(txt, ...)

		send_message(pid(), {event="halt"}) -- same as pressing escape; goes to terminal
		yield() -- get out of terminal callback (only works if not inside a coroutine ** and doesn't resume at that point **)
	end

	-- any process can kill any other process!
	-- deleteme -- send a message to process manager instead. process manager might want to decline.
	--[[
	function kill_process(proc_id, exit_code)
		send_message(2, {event="kill_process", proc_id=proc_id, exit_code = exit_code})
	end
	]]

	-- 
	function get_clipboard()
		_req_clipboard_text()

		-- ** commented; can't support get_clipboard on web yet
		--flip() -- wait at least one frame (even on binary platforms -- just how it be)

		-- wait up to 10 frames for the browser to separately process ctrl-v (setting codo_textarea contents) 
		for i=1,10 do
			
			local ret = _get_clipboard_text()
			if (ret) then return ret end
			flip()
		end

		return nil -- could not fetch
	end

	function set_clipboard(...)
		return _set_clipboard_text(...)
	end




	
	function printh(str)
		_printh(string.format("[%03d] %s", pid(), _tostring(str)))
	end

	

	function print(str, x, y, col)

		if (y or (get_display() and not _is_terminal_command)) then
			return _print_p8scii(str, x, y, col)
		end

		if (stat(315) > 0) then
			_printh(_tostring(str)) 
		else
			-- when print_to_proc_id is not set, send to self (e.g. printing to terminal)
			send_message(_env().print_to_proc_id or pid(), {event="print",content=_tostring(str)})
		end

	end

	


	sub = string.sub

	-- get filename extension
	-- include double extensions; .p64.png is treated differently from .png
	-- "" is also a legit extension distinct from no extension ("wut." vs "wut")

	function string:ext()
		local loc = _split(self,"#",false)[1]
		-- max extension length: 16
		for i = 1,16 do
			if (string.sub(loc,-i,-i) == ".") then
				-- try to find double ext first e.g. .p8.png  but not .info.pod
				for j = i+1,16 do
					if (string.sub(loc,-j,-j) == "/") return string.sub(loc, -i + 1) -- path separator -> return just the single segment
					if (string.sub(loc,-j,-j) == "." and #loc > j) return string.sub(loc, -j + 1)
				end
				return string.sub(loc, -i + 1)
			end
		end
		return nil -- "no extension"
	end

	function string:path()
		return _split(self,"#")[1]
	end

	function string:hloc()
		return _split(self,"#")[2]
	end

	function string:basename()
		local segs = _split(self:path(),"/")
		return segs[#segs]
	end

	function string:dirname()
		local segs = _split(self:path(),"/")
		return self:sub(1,-#segs[#segs]-2)
	end

	function string:prot()
		local segs = _split(self:path(),":")
		return (type(segs[2]) == "string" and segs[2]:sub(1,2) == "//") and segs[1] or nil
	end

	-- PICO-8 style string indexing;  ("abcde")[2] --> "b"  
	-- to do: implement in lvm.c?
	local string_mt_index=getmetatable('').__index
	local _strindex = _strindex
	getmetatable('').__index = function(str,i) 
		return string_mt_index[i] or _strindex(str,i)
	end

	--[[
		** experimental -- perhaps a bad idea **  

		//  goal: want a simple, transparent, commonly used path for including code

		include is similar to require() but searches:
			1. current path (libraries bundled with program)
			2. /system/lib  (common libraries -- dunno what that would be though! font should be standard)
				// maybe should use pico-8 style #include so can manage .p64.png packaging automatically
				// could just rewrite #include filename as include "filename" in preprocessor! 

		** "include" is a bad name -- included code has scope and can't read parent locals

		related reading: Lua Module Function Critiqued // old module system deprecated in 5.2 in favor of require()
			// avoids multiple module authors writing to the same global environment

			http://lua-users.org/wiki/LuaModuleFunctionCritiqued
			https://web.archive.org/web/20170703165506/https://lua-users.org/wiki/LuaModuleFunctionCritiqued

	]]

	function include(filename)
		local filename = fullpath(filename)
		local src = fetch(filename)

		if (type(src) ~= "string") then 
			notify("could not include "..filename)
			stop()
			return
		end

		-- https://www.lua.org/manual/5.4/manual.html#pdf-load
		-- chunk name (for error reporting), mode ("t" for text only -- no binary chunk loading), _ENV upvalue
		-- @ is a special character that tells debugger the string is a filename
		local func,err = load(src, "@"..filename, "t", _ENV)

		-- syntax error while loading
		if (not func) then 
			send_message(3, {event="report_error", content = "*syntax error"})
			send_message(3, {event="report_error", content = _tostring(err)})

			stop()
			return
		end

--[[
		-- method 1. run as a coroutine
		--local res, err = coresume(cocreate(func))

		-- method 2: pcall
		--local res, err = pcall(func)

		if (not res) then
			notify(debug.traceback())
			notify(err) -- will show the filename the runtime error ocurred in			
			--notify(":: runtime error in "..filename)
			stop()
		end
		return res, err
]]

		-- call directly; allows complete stacktrace -- runtime error can be handled in general case
		
		-- hrrm
		-- if (filename:sub(1,12) ~= "/system/lib/") cd(filename:dirname())
			func()

		return true -- ok, no error including   -- to do: shouldn't a successful include just return nil?
	end
	
	
	function memmap(ud, addr, offset, len)
		if (type(addr) == "userdata") addr,ud = ud,addr -- legacy >_<
		if (_map_ram(ud, addr, offset, len)) then
			
			if (addr == 0x100000) then
				_unmap(_current_map, 0x100000) -- kick out old map
				_current_map = ud
			end
			userdata_ref[ud] = ud -- need to include a as a value on rhs to keep it held

			return ud -- 0.1.0h: allows things like pfxdat = fetch("tune.sfx"):memmap(0x30000)
		end
	end

	-- unmap by userdata
	-- ** this is the only way to release mapped userdata for collection **
	-- ** e.g. memmapping a userdata over an old one is not sufficient to free it for collection **
	function unmap(ud, addr, len)
		if _unmap_ram(ud, addr, len) then
			-- nothing left pointing into Lua object -> can release reference and be garbage collected 	
			userdata_ref[ud] = nil
		end
	end
	_unmap = unmap

--------------------------------------------------------------------------------------------------------------------------------
--    Sprite Registry
--------------------------------------------------------------------------------------------------------------------------------


	-- add or remove a sprite at index
	-- flags stored at 0xc000 (16k)
	function set_spr(index, s, flags_val)
		index &= 0x3fff
		_spr[index] = s    -- reference held by head
		_set_spr(index, s) -- notify process
		if (flags_val) poke(0xc000 + index, flags_val)
	end

	function get_spr(index)
		return _spr[flr(index) & 0x3fff]
	end


	function map(ud, b, ...)
		
		if (type(ud) == "userdata") then
			-- userdata is first parameter -- use that and set current map
			_draw_map(ud, b, ...)
		else
			-- pico-8 syntax
			_draw_map(_current_map, ud, b, ...)
		end
	end

	
	

--------------------------------------------------------------------------------------------------------------------------------
--    Undo
--------------------------------------------------------------------------------------------------------------------------------

function create_undo_stack(...)

	if (not UNDO) then
		include("/system/lib/undo.lua")
	end
	return UNDO:new(...)
end



--------------------------------------------------------------------------------------------------------------------------------
--    Coroutines
--------------------------------------------------------------------------------------------------------------------------------


yield = coroutine.yield
cocreate = coroutine.create
costatus = coroutine.status

local _coresume = coroutine.resume -- used internally

-- move to local; only used here
local _yielded_to_escape_slice = __yielded_to_escape_slice
__yielded_to_escape_slice = nil

--[[

	coresume wrapper needed to preserve and restore call stack
	when interuppting program due to cpu / memory limits

]]

function coresume(c,...)
	
	_yielded_to_escape_slice(0)
	local r0,r1 =_coresume(c,...)
	--printh("coresume() -> _yielded_to_escape_slice():"..tostring(_yielded_to_escape_slice()))
	while (_yielded_to_escape_slice() and costatus(c) == "suspended") do
		_yielded_to_escape_slice(0)
		r0,r1 = _coresume(c,...)
	end
	_yielded_to_escape_slice(0)
	return r0,r1
end


--------------------------------------------------------------------------------------------------------------------------------

--[[
	
	notify("syntax error: ...", "error")
	-> shows up in /ram/log/error, as a tab in infobar (shown in code editor workspace)
	
	can also use logger.p64 to view / manage logs
	how to do realtime feed with atomic file access? perhaps via messages to logger? [sent by program manager]

]]
function notify(msg_str)

	-- notify user and add to infobar history
	send_message(3, {event="user_notification", content = msg_str})

	-- logged by window manager
	-- send_message(3, {event="log", content = msg_str})
	
	-- printh("@notify: "..msg_str.."\n")
end



-- notifications

init_runtime_state()


end



