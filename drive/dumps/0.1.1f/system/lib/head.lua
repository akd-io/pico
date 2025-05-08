--[[pod_format="raw",created="2025-04-27 15:57:53",modified="2025-04-27 15:57:53",revision=0]]
-- **** head.lua should not have any metadata; breaks load during bootstrapping // to do: why? ****
--[[

	head.lua -- kernal space header for each process
	(c) Lexaloffle Games LLP

]]

do

-- need to define global function env before running head
-- happens in create_process (inject env pod into source) and boot.lua (dummy empty environment) 
local _env = env

local _pid = pid

local _stop = _stop
local _print_p8scii = _print_p8scii
local _map_ram = _map_ram
local _ppeek = _ppeek
local _create_process_from_code = _create_process_from_code
local _unmap_ram = _unmap_ram
local _get_process_display_size = _get_process_display_size
local _run_process_slice = _run_process_slice
local _fetch_metadata_from_file = _fetch_metadata_from_file

local _blit_process_video = _blit_process_video
local _set_spr = _set_spr
local _ppeek4 = _ppeek4
local _set_draw_target = _set_draw_target
local _get_process_list = _get_process_list
local _pod = _pod
local _kill_process = _kill_process
local _read_message = _read_message
local _draw_map = _draw_map
local _halt = _halt
local _mkdir = _mkdir

local _signal = _signal
local _unmap
local _split = split
local _printh = _printh
local _tostring  = tostring

local _send_message  = _send_message


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

	-- window draw mask, interaction mask 
	poke(0x547d,0x0,0x0)

	-- audio 
	poke(0x5538,
		0x40,0x40, -- (1.0) global volume for sfx, music
		0x40,0x40, -- (1.0) default volume parameters when not given to sfx(), music()
		0x03,0x03  -- base address for sfx, music (0x30000, 0x30000)
	)

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

-- for rate limiting
local create_process_t = 0
local create_process_n = 0

-- returns process id on success, otherwise: nil, err_msg
function create_process(prog_name_p, env_patch, do_debug)

	-- sandboxed programs can not create processes
	if _env().sandbox and ((stat(307) & 0x1) == 0) then -- sandboxed program that is not a trusted system app

		-- placeholder exceptions: can open file picker / can open notebook for docs
		-- picocalendar uses open.lua to open text files
		-- perhaps all of these can be replaced with "open()"? (which runs /util/open.lua)

		local grant_exception = false

		if (prog_name_p == "/system/apps/filenav.p64") grant_exception = true -- sandboxed filenav! ._.
		if (prog_name_p == "/system/apps/notebook.p64") grant_exception = true -- some carts use this I think
		if (prog_name_p == "/system/util/open.lua") grant_exception = true  --  can also use open()
		-- if (prog_name_p:prot() == "bbs") grant_exception = true -- to do: can launch any other bbs app! (should be part of a pico-8 style stack with navigation?)

		if (not grant_exception) then
			-- printh("## create_process denied from sandboxed program: "..prog_name_p)
			return nil, "sandboxed process can not create_process()"
		end

		-- printh("[create_process] granting exception in sandbox: "..prog_name_p)

		-- rate limiting // prevent bbs cart from process-bombing
	
		if (time() > create_process_t + 60) then
			-- reset every minute
			create_process_t = time()
			create_process_n = 0
		end
		if (create_process_n >= 10) then
			-- limit: 10 per minute
			return nil, "sandboxed process can not create_process() more than 10 / minute"
		end
		create_process_n += 1

	end


	local prog_name = fullpath(prog_name_p)
	local running_pwc = prog_name == "/ram/cart/main.lua" or (env_patch and env_patch.corun_program == "/ram/cart/main.lua")

	
	-- .p64 files: find boot file in root of .p64 (and thus set default path there too)
	local boot_file = prog_name
	local metadata

	if  string.sub(prog_name,-4) == ".p64"     or 
		string.sub(prog_name,-8) == ".p64.rom" or
		string.sub(prog_name,-8) == ".p64.png"
	then

		-- bbs:// -- normalise by stripping path paths
		-- where should this happen? need for favourites too
		if (prog_name:prot() == "bbs") then
			prog_name = "bbs://"..prog_name:basename()
			--printh("normalised bbs prog path to: "..prog_name)
		end

		boot_file = prog_name.."/main.lua"

	end

	------------------------------------------ locate metadata ------------------------------------------

	-- look for metadata inside p64 / folder
	local metadata = _fetch_metadata_from_file(prog_name.."/.info.pod")

	-- special case: co-running /ram/cart from terminal
	if not metadata and running_pwc then
		local fn2 = "/ram/cart/.info.pod"
		metadata = _fetch_metadata_from_file(fn2)
	end
	
	-- maybe running main.lua directly inside a cart (or /ram/cart/main.lua)
	if (not metadata and prog_name:basename() == "main.lua") then
		metadata = _fetch_metadata_from_file(boot_file:dirname().."/.info.pod")
	end

	-- no metadata found -> default is {}
	if (not metadata) metadata = {}

	-- check for future cartridge
	-- applies to carts / folders -- lua files don't have this metadata
	if (type(metadata.runtime) == "number" and metadata.runtime > stat(5)) then
		notify("** cartridge has future runtime version: "..prog_name_p)
		return -- to do: allow_future
	end

	------------------------------------------ locate metadata ------------------------------------------

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

--	new_env.prog_name = prog_name -- 0.1.1e: removed; now stored in argv[0]
--	new_env.title = get_short_prog_name(prog_name)  --  0.1.1e: removed; doesn't mean much and creates ambiguity
	new_env.parent_pid = _pid()
	new_env.argv = type(new_env.argv) == "table" and new_env.argv or {} -- guaranteed to exist at least as an empty table
	--if (type(new_env.argv) ~= "table") printh("@@ type(new_env.argv):"..type(new_env.argv).."  "..pod(new_env.argv))
	new_env.argv[0] = prog_name -- e.g. /system/apps/gfx.p64

	if (not new_env.sandbox and prog_name:prot() == "bbs") then
		new_env.sandbox = "bbs"
		local ext = prog_name:ext()
		if (ext and ext:is_cart()) new_env.bbs_id = prog_name:basename():sub(1,-(#ext+2)) -- foo-3
	end

	
	-- grab sandbox from cartridge metadata if not already set in environment
	-- (can opt to turn sandboxing off in env_patch with {sandbox=false}; or otherwise override sandbox specified in metadata)
	if (not new_env.sandbox and metadata.sandbox and metadata.bbs_id) then
		new_env.sandbox = metadata.sandbox -- "bbs"
		new_env.bbs_id = metadata.bbs_id
	end


	-- created by sandboxed program -> inherit fileview  (e.g. open filenav -> should have same /appdata mapping)
	if (not new_env.sandbox and _env().sandbox) then
		new_env.sandbox = "bbs_companion"
		new_env.bbs_id = _env().bbs_id
	end


	-- sandboxed cart must have a bbs_id for /appdata to map to
	if (new_env.sandbox == "bbs" and not new_env.bbs_id) then
		-- printh("** bad bbs_id -- can't sandbox") 
		return nil, "bad bbs_id -- can't sandbox"
	end


	new_env.fileview = new_env.fileview or {}

	-- only "trusted system apps" (currently /system/*) can pass in a custom fileview
	if (stat(307) & 0x1) == 0 then
		new_env.fileview = {}
	end

	-- printh("creating process "..prog_name_p.." with starting fileview: "..pod{new_env.fileview})
	-- printh("creating process "..prog_name_p.." with sandbox: "..pod{new_env.sandbox})
	
	-- create fileview / rules for sandbox

	if (new_env.sandbox == "bbs") then

		-- essential read access
		add(new_env.fileview, {location = "/system", mode = "R"}) -- read libraries and resources
		add(new_env.fileview, {location = prog_name, mode = "R"}) -- cart/program can read itself (to do: allow running main.lua directly? probably no need)
		add(new_env.fileview, {location = "/ram/shared", mode = "R"}) -- can always read /ram/shared

		-- deleteme -- shouldn't need to read system settings
--		add(new_env.fileview, {location = "/appdata/system", mode = "R"}) -- read settings

		-- partial view of processes.pod
		add(new_env.fileview, {location = "/ram/system/processes.pod", mode = "X"})

		-- partial view of /desktop metadata (only icon x,y available; ref: bbs://desktop_pet.p64)
		add(new_env.fileview, {location = "/desktop/.info.pod", mode = "X"})
		
		-- can read/write /ram/cart 
		--[[
			UPDATE: user must grant write permission explicitly by choosing file in filenav
			(filenav has the authority to extend another process's fileview)
			means default file location (/ram/cart/gfx/0.pal) needs to be bumped to /appdata, but that's
			not a terrible thing esp when just quickly trying out a tool ~ get a persistent demo file.
		]]
		-- add(new_env.fileview, {location = "/ram/cart", mode = "RW"})

		-- but can read it if running /ram/cart/main.lua (e.g. using bbs dummy id during dev)

		if (running_pwc) add(new_env.fileview, {location = "/ram/cart", mode = "R"})

		-- (dev) read/write mounted bbs:// cart while sandboxed
		-- deleteme -- only needed in kernal space in fs.lua
		--add(new_env.fileview, {location = "/ram/bbs/"..new_env.bbs_id..".p64.png", mode = "RW"})

		-- any carts can read/write /appdata/shared \m/
		add(new_env.fileview, {location = "/appdata/shared", mode = "RW"})

		-- any other /appdata path should be mapped to /appdata/bbs/bbs_id
		local bbs_id_base = split(new_env.bbs_id, "-", false)[1] -- don't include the version part
		_mkdir("/appdata/bbs") -- safety; should already exist (boot creates)
		--_mkdir("/appdata/bbs/"..bbs_id_base) -- to do: only create when actually about to write something?
		add(new_env.fileview, {location = "/appdata", mode = "RW", target="/appdata/bbs/"..bbs_id_base})

	end

	-- bbs_comapnion e.g. open filenav / notebook from bbs cart. always a trusted app from /system
	-- the companion program has full access, except should have same /appdata mapping as parent process
	if (new_env.sandbox == "bbs_companion") then

		new_env.fileview={}

		-- same /appdata mapping as parent process
		local bbs_id_base = split(_env().bbs_id, "-", false)[1] -- don't include the version part
		_mkdir("/appdata/bbs")
		_mkdir("/appdata/bbs/"..bbs_id_base) -- create on launch in case want to browse it with filenav
		add(new_env.fileview, {location = "/appdata", mode = "RW", target="/appdata/bbs/"..bbs_id_base})

		-- printh("created companion mapping for /appdata: ".."/appdata/bbs/"..bbs_id_base)

		-- everything else is allowed (e.g. filenav can freely browse drive and choose where to load / save file)
		add(new_env.fileview, {location = "*", mode = "RW"})
	end

	--printh("new_env.fileview: "..pod{new_env.fileview})


	
	
	----


	local str = [[

		-- environment for new process; use _pod to generate immutable version
		-- (generates new table every time it is called)
		env = function() 
			return ]].._pod(new_env,0x0)..[[
		end
		_env = env

		local head_code = load(fetch("/system/lib/head.lua"), "@/system/lib/head.lua", "t", _ENV)
		if (not head_code) then printh"*** ERROR: could not load head. borked file system / out of pfile slots? ***" end
		head_code()

		include("/system/lib/legacy.lua")
		
		include("/system/lib/api.lua")		
		include("/system/lib/events.lua")

		include("/system/lib/fs.lua") -- depends on events
		
		include("/system/lib/socket.lua")
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

	-- printh("create_process with env: "..pod(new_env))

	local proc_id = _create_process_from_code(str, get_short_prog_name(prog_name), prog_name)

	
	if (not proc_id) then
		
		return nil
	end

--	printh("$ created process "..proc_id..": "..prog_name.." ppath:"..program_path)

	if (env_patch and env_patch.window_attribs and env_patch.window_attribs.pwc_output) then
		store("/ram/system/pop.pod", proc_id) -- present output process
	end

	if (env_patch and env_patch.blocking) then
		-- this process should stop running until proc_id is completed
		-- (update: is that actually useful?)
	end


	return proc_id

end


function open(loc)
	if (type(loc)~="string") return

	-- works for sandboxed carts, but open.lua will be run in a bbs_companion sandbox
	--> can open anything that is accessible to calling processes's fileview
	create_process("/system/util/open.lua",{argv={loc}})
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

	---------------------------------------------------------------------------------------------------

	local first_set_window_call = true

	local function set_window_1(attribs)

		-- to do: shouldn't be needed by window manager itself (?)
		-- to what extent should the wm be considered a visual application that happens to be running in kernel?
		-- if (_pid() <= 3) return

		attribs = attribs or {}


		-- on first call, observe attributes from env().window_attribs
		-- they **overwrite** any same key attributes passed to set_window
		-- (includes pwc_output set by window manager)

		if (first_set_window_call) then

			first_set_window_call = false
		
			if type(_env().window_attribs) == "table" then
				for k,v in pairs(_env().window_attribs) do
					attribs[k] = v
				end
			end

			-- set the program this window was created with (for workspace matching)

--			attribs.prog = _env().prog_name
			attribs.prog = _env().argv[0]


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

		_send_message(3, {event="set_window", attribs = attribs})

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
				_send_message(3, {event="move_window", dx=attribs.dx, dy=attribs.dy})
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
		_send_message(2, {event="kill_process", proc_id=_pid()})
		_halt() -- stop executing immediately
	end

	-- stop executing in a resumable way 
	-- use for debugging via terminal: stop when something of interest happens and then inspect state
	function stop(txt, ...)
		if (txt) print(txt, ...)

		_send_message(_pid(), {event="halt"}) -- same as pressing escape; goes to terminal
		yield() -- get out of terminal callback (only works if not inside a coroutine ** and doesn't resume at that point **)
	end

	_stop = stop

	-- any process can kill any other process!
	-- deleteme -- send a message to process manager instead. process manager might want to decline.
	--[[
	function kill_process(proc_id, exit_code)
		_send_message(2, {event="kill_process", proc_id=proc_id, exit_code = exit_code})
	end
	]]

	


	
	function printh(str)
		_printh(string.format("[%03d] %s", _pid(), _tostring(str)))
	end

	

	function print(str, x, y, col)

		if (y or (get_display() and not _is_terminal_command)) then
			return _print_p8scii(str, x, y, col)
		end

		if (stat(315) > 0) then
			_printh(_tostring(str)) 
		else
			-- when print_to_proc_id is not set, send to self (e.g. printing to terminal)
			-- printh("printing to "..tostring(_env().print_to_proc_id or _pid()))
			_send_message(_env().print_to_proc_id or _pid(), {event="print",content=_tostring(str)})
		end

	end


	unpack = table.unpack
	pack = table.pack
	

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

	string.split = _split

	function string:path()
		return _split(self,"#",false)[1]
	end

	function string:hloc()
		return _split(self,"#",false)[2]
	end

	function string:basename()
		local segs = _split(self:path(),"/",false)
		return segs[#segs]
	end

	function string:dirname()
		local segs = _split(self:path(),"/",false)
		return self:sub(1,-#segs[#segs]-2)
	end

	-- max 8 chars
	-- to do: check is all lowercase alphanumeric chars
	function string:prot()
		local segs = _split(self:path(),":",false)
		return (type(segs[2]) == "string" and segs[2]:sub(1,2) == "//") and #segs[1] <= 8 and segs[1] or nil
	end

	function string:is_cart()
		return self=="p64" or self=="p64.png" or self=="p64.rom"
	end


	-- PICO-8 style string indexing;  ("abcde")[2] --> "b"  
	-- to do: implement in lvm.c?
	local string_mt_index=getmetatable('').__index
	local _strindex = _strindex
	getmetatable('').__index = function(str,i) 
		return string_mt_index[i] or _strindex(str,i)
	end

	--[[
		include()

		shorthand for: fetch(filename)()  //  so always relative to pwd()

		// not really an include, but for users who don't care about the difference, serves the same purpose
		// and is used in the same way: a bunch of include("foo.lua") at the start of main.lua

		related reading: Lua Module Function Critiqued // old module system deprecated in 5.2 in favor of require()
			// avoids multiple module authors writing to the same global environment
			http://lua-users.org/wiki/LuaModuleFunctionCritiqued
			https://web.archive.org/web/20170703165506/https://lua-users.org/wiki/LuaModuleFunctionCritiqued
	]]

	local included_files = {}

	function include(filename)
		local filename = fullpath(filename)
		local src = fetch(filename)

		-- temporary safety: each file can only be included up to 256 times
		-- to do: why do recursive includes cause a system-level out of memory before a process memory error?
		if (included_files[filename] and included_files[filename] > 256) then
			--printh("** too many includes of "..filename)
			--printh(stat(0))
			return nil
		end
		included_files[filename] = included_files[filename] and included_files[filename]+1 or 1


		if (type(src) ~= "string") then 
			if (_pid() <= 3) printh("** could not include "..filename)
			notify("could not include "..filename)
			_stop()
		end

		-- https://www.lua.org/manual/5.4/manual.html#pdf-load
		-- chunk name (for error reporting), mode ("t" for text only -- no binary chunk loading), _ENV upvalue
		-- @ is a special character that tells debugger the string is a filename
		local func,err = load(src, "@"..filename, "t", _ENV)

		-- syntax error while loading
		if (not func) then 
			_send_message(3, {event="report_error", content = "*syntax error"})
			_send_message(3, {event="report_error", content = _tostring(err)})
			_stop()
		end

		return func() -- 0.1.1e: allow private modules (used to return true)
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

	-- 0.1.1e: only 32 banks (was &0x3fff). bits 0xe000 reserved for orientation (flip x,y,diagonal)
	function get_spr(index)
		return _spr[flr(index) & 0x1fff]
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
		UNDO = include("/system/lib/undo.lua")
	end
	return UNDO:new(...)
end


--------------------------------------------------------------------------------------------------------------------------------
--    Coroutines
--------------------------------------------------------------------------------------------------------------------------------

-- aliases
yield = coroutine.yield
cocreate = coroutine.create
costatus = coroutine.status

local _coresume = coroutine.resume -- used internally
local _yielded_to_escape_slice = _yielded_to_escape_slice

--[[

	coresume wrapper needed to preserve and restore call stack
	when interuppting program due to cpu / memory limits

]]

function coresume(c,...)
	
	_yielded_to_escape_slice(0)
	local res,err =_coresume(c,...)
	--printh("coresume() -> _yielded_to_escape_slice():"..tostring(_yielded_to_escape_slice()))
	while (_yielded_to_escape_slice() and costatus(c) == "suspended") do
		_yielded_to_escape_slice(0)
		res,err = _coresume(c,...)
	end
	_yielded_to_escape_slice(0)

	-- ** test: report runtime errors inside coroutines no matter where they were run from?
	--[[
	if (err) then
		send_message(3, {event="report_error", content = "*runtime error"})
		send_message(3, {event="report_error", content = err})
		send_message(3, {event="report_error", content = debug.traceback()})
	end
	]]

	return res,err
end

-- 0.1.1e library version should do the same
coroutine.resume = coresume


--------------------------------------------------------------------------------------------------------------------------------

--[[
	
	notify("syntax error: ...", "error")
	-> shows up in /ram/log/error, as a tab in infobar (shown in code editor workspace)
	
	can also use logger.p64 to view / manage logs
	how to do realtime feed with atomic file access? perhaps via messages to logger? [sent by program manager]

]]
function notify(msg_str)

	-- notify user and add to infobar history
	_send_message(3, {event="user_notification", content = msg_str})

	-- logged by window manager
	-- _send_message(3, {event="log", content = msg_str})
	
	-- web debug
	if (stat(318)==1) printh("@notify: "..msg_str.."\n")
end

--[[
	send_message()

	security concern: 
	userland apps may perform dangerous actions in response to messages, not realising they can be triggered by arbitrary bbs carts
	-> sandboxed processes can only send messages to self, or to /system processes (0.1.1e)
		-- e.g. sandboxed terminal can send terminal set_haltable_proc_id to wm, or request a screenshot capture
		-- assumption: /system programs can all handle arbitrary messages safely
		-- to do: should accept message going to process 2, but then reject most/all of them from those handlers. clearer
]]
function send_message(proc_id, msg, ...)

	if 
		not _env().sandbox or                         -- userland processes can send messages anywhere
		proc_id == _pid() or                          -- can always send message to self
		(stat(307) & 0x1) == 1 or                     -- can always send message if is bundled /system app (filenav)
		proc_id == 3 or                               -- can always send message to wm
		-- special case: sandboxed app can set map/gfx palette via pm; (to do: how to generalise this safely?)
		msg.event == "set_palette" or -- used by #okpal
		(msg.event == "broadcast" and msg.msg and msg.msg.event == "set_palette") -- not sure if used in the wild
	then
		_send_message(proc_id, msg, ...)
	else
		--printh("send_message() declined: "..pod(msg))
	end

end



init_runtime_state()


end



