--[[

	events.lua
	part of head.lua

]]

do

	local _read_message = _read_message


	local message_hooks = {}
	local message_subscriber = {}
	local mouse_x = 0
	local mouse_y = 0
	local mouse_b = 0
	local wheel_x = 0
	local wheel_y = 0


	local ident = math.random()

	local key_state={}
	local last_key_state={}
	local repeat_key_press_t={}

	local frame_keypressed_result={}
	local scancode_blocked = {} -- deleteme -- not used or needed   //  update: maybe do? ancient sticky keys problem

	function mouse()
		-- printh("@mouse() result: "..tostr(mouse_x).." ident:"..ident)
		return mouse_x, mouse_y, mouse_b, wheel_x, wheel_y -- wheel is since last frame
	end 


	--[[

		// 3 levels of keyboard mapping:

		1. raw key names  //  key("a")
	
			"a" means the key to the right of capslock
			defaults to US layout, patched by /appdata/system/scancodes.pod
			example: tracker music input -- layout should physically match a piano

		2. mapped key names  // key("a")

			"a" means the key with "a" written on it
			e.g. the key to the right of tab on a typical azerty keyboard
			defaults to raw key names (US), patched by /appdata/system/keycodes.pod
			example: key"f" to flip sprite horiontally should respond to the key with "f" written on it

		3. text entry  // readtext()

			"a" is a unicode string triggered by pressing a when shift is not held (-> SDL_TEXTINPUT event)
			ctrl-a or enter does not trigger a textinput event; need to read with mapped key names
			defaults to host OS keyboard layout and text entry method; not currently configurable inside Picotron
	]]
	

	local name_to_scancode_raw =
	{
		a=4,b=5,c=6,d=7,e=8,f=9,g=10,h=11,i=12,j=13,k=14,l=15,m=16,n=17,o=18,p=19,q=20,r=21,s=22,t=23,u=24,v=25,w=26,x=27,y=28,z=29,
		left=80,right=79,up=82,down=81,
		lctrl=224,rctrl=228,lshift=225,rshift=229,lalt=226,ralt=230,
		["1"]=30,["2"]=31,["3"]=32,["4"]=33,["5"]=34,["6"]=35,["7"]=36,["8"]=37,["9"]=38,["0"]=39,
		f1 = 58, f2 = 59, f3 = 60, f4 = 61, f5 = 62, f6 = 63, f7 = 64, f8 = 65, f9 = 66, f10 = 67,
		["<"]=54,[">"]=55, -- [","]=54,["."]=55, -- alternative names? feels like a bad idea. use most distinctive option

		["["]=47,["]"]=48,["-"]=45,["+"]=46,["~"]=53,[":"]=51,["'"]=52,
		--["\\"]=49, -- to do: why does this break esc on robot?
		["/"]=56, [","]=54,["."]=55, 
		space=44,tab=43,enter=40,pageup=75,pagedown=78,backspace=42,del=76,insert=73,home=74,["end"]=77,escape=41,

		-- windows / command (apple) / meta
		lgui=227, rgui=231
	}


	-- patch with /settings/scancodes
	-- 57 for ctrl on robot. to do: allow multiple mappings?

	local patch_scancodes = fetch"/appdata/system/scancodes.pod"
	if patch_scancodes then
		for k,v in pairs(patch_scancodes) do
			name_to_scancode_raw[k] = v
		end
	end

	local name_to_scancode0 = unpod(pod(name_to_scancode_raw))
	local name_to_scancode  = unpod(pod(name_to_scancode_raw))

	local patch_keycodes = fetch"/appdata/system/keycodes.pod"
	if patch_keycodes then
		for k,v in pairs(patch_keycodes) do
			name_to_scancode[k] = name_to_scancode0[v] or v -- can use raw name or scancode directly
			-- printh("mapping keycode "..k.." to "..name_to_scancode[k])
		end
	end

	-- scancodes map to themselves unless explicitly remapped
	-- (avoids an extra "or scancode" in get_scacode)


	for i=0,511 do
		name_to_scancode[i]     = name_to_scancode[i]     or i
		name_to_scancode_raw[i] = name_to_scancode_raw[i] or i
	end

	-- backwards lookup (not currently used)

	local scancode_to_name = {}
	for k,v in pairs(name_to_scancode) do
		scancode_to_name[v] = k
	end


	local function get_scancode(scancode, raw)
		local scancode = (raw and name_to_scancode_raw or name_to_scancode)[scancode]
		--[[
		if (scancode_blocked[scancode]) then
			-- unblock when not down. to do: could do this proactively and not just when queried 
			if (key_state[scancode] != 1) scancode_blocked[scancode] = nil 
			return 0 
		end
		]]
		return scancode
	end



	--[[

		keyp(scancode, raw)

			raw means: use US layout; same physical layout regardless of locale.
			use for things like music keyboard layout in tracker

			otherwise: map via appdata/system/scancodes.pod (should be "kbd_layout.pod"?)

		-- frame_keypressed_result is determined before each call to _update()
		--  (e.g. ctrl-r shouldn't leave a keypress of 'r' to be picked up by tracker. consumed by window manager)

	]]

	function keyp(scancode, raw)

		scancode = get_scancode(scancode, raw)

		-- keep returning same result until end of frame
		if (frame_keypressed_result[scancode]) return frame_keypressed_result[scancode]

		-- first press
		if (key_state[scancode] and not last_key_state[scancode]) then
			repeat_key_press_t[scancode] = time() + 0.5
			frame_keypressed_result[scancode] = true
			return true
		end

		-- repeat
		if (key_state[scancode] and repeat_key_press_t[scancode] and time() > repeat_key_press_t[scancode]) then
			repeat_key_press_t[scancode] = time() + 0.04
			frame_keypressed_result[scancode] = true
			return true
		end

		return false
	end
	
	
	function key(scancode, raw)
		-- to do: efficiency

		-- "ctrl" is special -- can mean option key on apple (for option-c / ctrl-c means the same thing)
		if (scancode == "ctrl") then 
		return 
			key("lctrl") or key("rctrl") or 
			key("lgui")  or key("rgui")
		end
		if (scancode == "shift") then return key("lshift") or key("rshift") end
		if (scancode == "alt") then return key("lalt") or key("ralt") end

		scancode = get_scancode(scancode, raw)
		return key_state[scancode]
	end



	-- clear state until end of frame
	-- (mapped keys only -- can't be used with raw scancodes)
	function clear_key(scancode)
		scancode = get_scancode(scancode)
		frame_keypressed_result[scancode] = nil
		key_state[scancode] = nil
	end

	
	local text_queue={}

	function readtext(clear_remaining)
		local ret=text_queue[1]

		for i=1,#text_queue do -- to do: use table operation
			text_queue[i] = text_queue[i+1] -- includes last nil
		end

		if (clear_remaining) text_queue = {}
		return ret
	end

	function peektext(i)
		return text_queue[i or 1]
	end

	-- when window gains or loses focus
	local function reset_kbd_state()
		--printh("resetting kbd")
		text_queue={}
		key_state={}
		last_key_state={}

		-- block all keys
		--[[
			scancode_blocked = {}
			for k,v in pairs(name_to_scancode) do
				scancode_blocked[v] = true
			end
		]]

	end


--[[
	deleteme -- don't need. app can just listen to gained/lost focus themselves. 
	local _window_has_focus = false

	function window_has_focus()
		return _window_has_focus
	end
]]
	
	local future_messages = {}

	--[[
		called once per _update
	]]
	
	function _process_event_messages()

		frame_keypressed_result = {}

		wheel_x = 0
		wheel_y = 0


--[[		for i=0,511 do
			last_key_state[i] = key_state[i]
		end
]]

		last_key_state = unpod(pod(key_state))

		local future_index = 1

		repeat
			
			local msg = _read_message()

			if (msg and msg._delay) msg._open_t = time() + msg._delay

			-- future messages: when _open_t is specified, open message at that time

			if (not msg and future_index <= #future_messages) then
				-- look for next future message that is ready to be received
				while (future_index <= #future_messages and future_messages[future_index]._open_t >= time()) do
					future_index += 1
				end
				msg = deli(future_messages, future_index)
			elseif (msg and msg._open_t and time() < msg._open_t) then
				-- don't process yet! put in queue of future messages
				add(future_messages, msg)
				msg = nil
			end

			
			if (msg) then

			--	printh(ser(msg))

				local blocked_by_hook = false

				if (message_hooks[msg.event]) then
					for i = 1, #message_hooks[msg.event] do
						blocked_by_hook = blocked_by_hook or message_hooks[msg.event][i](msg)
					end
				end

				if (not blocked_by_hook) then
					for i=1,#message_subscriber do
						blocked_by_hook = message_subscriber[i](msg)
						if (blocked_by_hook) then break end
					end

				end

				if (not blocked_by_hook) then

					-- 2. system

					if (msg.event == "mouse") then

						mouse_x = msg.mx
						mouse_y = msg.my
						mouse_b = msg.mb
						
					end

					if (msg.event == "mousewheel") then
						wheel_x = msg.wheel_x or 0
						wheel_y = msg.wheel_y or 0

					end

					if (msg.event == "keydown") then
						key_state[msg.scancode] = 1
						--printh("@@ keydown scancode: "..msg.scancode)
					end

					if (msg.event == "keyup") then
						key_state[msg.scancode] = nil
					end

					if (msg.event == "textinput" and #text_queue < 1024) then
						-- max buffer: 256 key presses
						text_queue[#text_queue+1] = msg.text;
					end

					if (msg.event == "gained_focus") then
						--_window_has_focus = true -- deleteme
						reset_kbd_state()
					end

					if (msg.event == "lost_focus") then
						--_window_has_focus = false -- deleteme
						reset_kbd_state()
					end

					if (msg.event == "gained_visibility") then
						poke(0x547f, peek(0x547f) | 0x1)
					end

					if (msg.event == "lost_visibility") then
						if (pid() > 3) poke(0x547f, peek(0x547f) & ~0x1) -- safety: only userland processes can lose visibility
					end

					if (msg.event == "resize") then
						-- throw out old display and create new one. can adjust a single dimension
						if (get_display()) then
							-- sometimes want to use resize message to also adjust window position so that
							-- e.g. width and x visibly change at the same frame to avoid jitter (ref: window resizing widget)
							window{width = msg.width, height = msg.height, x = msg.x, y = msg.y}
						end
					end

				end
			end

		until not msg
	end


	-----
	-- only one hook per event. simplifies logic.

	function on_event(event, f)
		if (not message_hooks[event]) message_hooks[event] = {}
		add(message_hooks[event], f)
	end

	-- kernel space for now -- used by wm (jettisoned)
	function _subscribe_to_events(f)
		add(message_subscriber, f)
	end

end


