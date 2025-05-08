--[[pod_format="raw",created="2024-03-11 18:02:01",modified="2024-03-11 18:22:35",revision=4]]
--[[
	foot.lua
]]

-- init first; might set window inside _init
-- only problem: no visual feedback while _init does a lot of work. maybe need to spin the picotron button gfx!
if (_init) then _init() end


--[[
	every program runs in headless until window() called, either
		- explicitly by program
		- automatically, when _draw exists (but window doesn't) just before entering main loop

	handle the second case here
]]

if (_draw and not get_display()) then

	-- create window (use fullscreen by default unless overridden by env().window_attribs)
	window()

end



-- mainloop
-- only loop if there is a _draw or _update
-- logic here applies to window manager too!

-- printh("entering mainloop at cpu:"..stat(1))

while (_draw or _update) do


	-- called once before every _update()  --  otherwise keyp() returns true for multiple _update calls
	_process_event_messages()

	-- set a hold_frame flag here and unset after mainloop completes (in flip) 
	-- window manager can decide to discard half-drawn frame. --> PICO-8 semantics
	-- moved to start of mainloop so that _update() can also be halfway through
	-- drawing something (perhaps to a different target) without it being exposed

	poke(0x547f, peek(0x547f) | 0x2)

	-- to do: process can be run in background when not visible
	-- @0x547f:0x1 currently means "window is visible", and apps only run when visible


	if (_update and (peek(0x547f) & 0x1) > 0) then

		-- always exactly one call to _update_buttons() before each _update() (allows keyp to work)
		_update_buttons() _update()

		local fps = stat(7)
		if (fps < 60) _process_event_messages() _update_buttons() _update()
		if (fps < 30) _process_event_messages() _update_buttons() _update()

		-- below 20fps, just start running slower. It might be that _update is slow, not _draw.
	end


	if (_draw and (peek(0x547f) & 0x1) > 0) then

		_draw()

		flip() -- unsets 0x547f:0x2
	else
		-- safety: draw next frame. // to do: why is this ever 0 for kernel processes? didn't received gained_visibility message?
		if (pid() <= 3) poke(0x547f, peek(0x547f) | 0x1)

		flip() -- no more computation this frame, and show whatever is in video memory
	end

end
