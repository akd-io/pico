--[[pod_format="raw",created="2025-03-28 22:10:21",modified="2025-03-28 22:10:21",revision=0]]
--[[

	gui.lua

	standard gui library
	// "standard" means included by head.lua

	super-minimal -- similar to codo gui.  ** well-defined and freeze early

	goal: scrollbox full of buttons and input boxes
	-> need attributes like clip_to_parent clip_to_self
		// or perhaps: stack of draw states? push_draw_state(). and/or push_clip()
		// needs to also apply when determining pointer element though. overcomplicated.
		// update: not that complicated! implemented in playground 10

	events:
		click, doubleclick, drag, release
		tap // on release when mouse hasn't moved
		mousewheel

]]


do
	local GuiElement={} -- helper class; never used externally

	local next_id = 0

	-- 0.1.1e: moved here so can be used by helper class
	-- 0.1.1f: only used for constructing msg tbl in helper
	-- grabbed once per frame at start of update_all (once for each gui, but is harmless)
	local global_mx, global_my, global_mb = 0,0,0
	
	-- 0.1.1e a dummy draw function always exists; simplifies clipping / hiding logic
	function GuiElement:draw() end


	function GuiElement:new(el)
		el = el or {}
		setmetatable(el, self)
		self.__index = self

		-- test: deleteme
		--if (not el.draw) el.draw = function() end

		-- el.debug_id = next_id -- for debugging
		next_id = next_id + 1

		-- time of creation
		-- sometimes don't want to interact with newly created elements
		el.t0 = time()

		-- commented: too confusing to have a default position / size when accidentally not specified on creation 
		-- to do: only useful if make crashes inside gui.lua more readable though!
--[[
		el.x = el.x or 43
		el.y = el.y or 43
		el.width = el.width or 43
		el.height = el.height or 43
]]

		el.z  = el.z or 0
		el.sx = el.x or 0 -- will be calculated on update
		el.sy = el.y or 0

		if (el.clip_to_parent == nil) then
			el.clip_to_parent = true
		end

		-- to do: update when used with relative sizes
		el.width0  = el.width
		el.height0 = el.height

		el.child = el.child or {}

		return el
	end

	-- child can be null to create new element
	function GuiElement:attach(child)
		child = child or {}		
		child = GuiElement:new(child)
		child.parent = self
		child.head = self.head or self -- also updated in update_absolute_position (ref: wm manually reattaches subtrees, messing up head)

		-- calculate relative size immediately -- might be used while calculating other elements
		if (child.width_rel)  child.width  = self.width  * child.width_rel  + (child.width_add  and child.width_add  or 0) 
		if (child.height_rel) child.height = self.height * child.height_rel + (child.height_add and child.height_add or 0)

		return add(self.child, child)

	end

	function GuiElement:has_keyboard_focus()
		-- to do: assert(typeof(this)=="table");   might accidentally self.has_keyboard_focus() instead of self:has_keyboard_focus()
		return self.head.keyboard_focus_el == self
	end

	function GuiElement:set_keyboard_focus(val)
		-- to do: assert(typeof(this)=="table");   might accidentally self.set_keyboard_focus() instead of self:set_keyboard_focus()
		if (val == true) then
			self.head.keyboard_focus_el = self
		elseif (self.head.keyboard_focus_el == self) then
			-- only set to nil if was this element (don't clobber a different element's focus)
			self.head.keyboard_focus_el = nil
		end

	end


	--[[

		g = create_gui()
		p = g:attach_pulldown({x = ..})
		p:attach_pulldown_item("Hey", func)

	]]
	function GuiElement:attach_pulldown(el)

		local p = self:attach(el)

		function p:draw(ev)

			local flat_top = false -- when false, can generalise to dismissable dialogue. probably too leaky though.
			local x0 = 1
			local y0 = flat_top and -1 or 1
			local x1 = el.width-2
			local y1 = el.height-2
			
			rectfill(x0,y0, x1,y1, 7)

			local border_col = 1
			
			line(x0+1, y1+1, x1-1, y1+1, border_col)
			line(x0-1, y0+1, x0-1, y1-1, border_col)
			line(x1+1, y0+1, x1+1, y1-1, border_col)
			if (not flat_top) then
				-- top border and corners
				line(x0+1, y0-1, x1-1, y0-1, border_col)
				pset(x0,y0,border_col)
				pset(x1,y0,border_col)
			end
			-- bottom corners
			pset(x0,y1,border_col)
			pset(x1,y1,border_col)

		end

		-- no items yet
		p.item_y = 4
		p.item_h = 12
		p.height = 10 -- extra 2px at the bottom feels better
		
		return p
	end

	function GuiElement:attach_pulldown_item(el)

		-- deleteme
		-- 0.1.1e: commented; (see https://www.lexaloffle.com/bbs/?tid=145205 "attach_pulldown_item's loss of event handlers")
		-- was there a reason to make a copy rather than reuse el (like the rest of the gui library)? seems not.
		-- local item = unpod(pod(el)) -- copy attributes

		local item = el or {}
		
		-- need to copy function separately
		item.action     = el.action

		-- default attrib values
		item.label      = item.label or "???"
		item.x          = item.x or 1
		item.y          = item.y or self.item_y
		item.width      = item.width or self.width-2  -- (-2 to fit inside 1px black border)
		item.height     = item.height or self.item_h


		item.draw = function(self, ev)
			if (ev.has_pointer and not self.divider) rectfill(0,0,self.width-1, self.height-1, 13)
			if (self.divider) then
				line(4,4, self.width-5, 4, 6)
			else
				local xx = 6
				local yy = 3
				if (self.icon) then
					pal(7,1)
					spr(self.icon, xx, 3)
					pal(7,7) -- hrrrm
					xx += 14
				end

				print(self.label, xx, yy, 1)

				if (self.shortcut) then
					local ww = print(self.shortcut, 0,-1000)
					-- to do: adapt greyed out colour (make pulldown themeable)
					print("\f6"..self.shortcut, self.width - ww - 6, yy)
				end
			end
		end
		
		-- run and close
		item.tap = function(self)
			if (self.action) then
				self.action()
				if not self.stay_open then
					if (self.onclose) then self.onclose() end -- to do: deleteme (not needed?)
					if (self.parent.onclose) then self.parent.onclose() end
					del(self.parent.parent.child, self.parent) -- close pulldown
				end
			end
			return true
		end

		-- don't propagate clicks -- will e.g. cause app menu modal to always be dismissed
		item.click = function(self)
			return true		
		end

		local item_h = self.item_h
		if (el.divider) item_h -= 4 -- line break is shorter
		self.item_y += item_h
		self.height += item_h
		self.height0 = self.height

		return self:attach(item)
	end

	--[[
		attach_field  //  ** placeholder

		needs a get() and set() callback

		** maybe fields are always too specialised; leave up to client
		   but nice to have a drop-in starting point if can make it general enough
	]]
	function GuiElement:attach_field(el)
		local el = self:attach(el)

		function el:draw()
			str = type(self.get == "function") and self:get() or "---"
			if (self:has_keyboard_focus()) str = self.str
			local ww,hh = print(str,0,-1000)
			rectfill(0,0,self.width-1,self.height-1, self:has_keyboard_focus() and 8 or 0)
			print(str,self.width-ww-1,1,6)
			if (self.label) then
				clip()
				local ww = print(self.label,0,-1000)
				print(self.label, -ww, 1, 13)
			end
		end

		function el:click()
			self:set_keyboard_focus(true)
			readtext(true)
			self.str = "" -- starting editing new string
		end


		function el:update()
			if (self:has_keyboard_focus()) then

				while (peektext()) do
					self.str = self.str .. readtext()
				end

				if (keyp("backspace")) self.str = sub(self.str,1,-2)

				if (keyp("enter")) then
					if (type(self.set) == "function") self:set(self.str)
					self:set_keyboard_focus(false)
				end

			end
		end


		return el
	end


	--[[
		attach_scrollbars() // to do: horizontal bar (or generalise to 2d)

		assume that self is a container element, where 
			child[1] is the element to be scrolled
			child[2] is the scrollbar

		example:

		g = create_gui()
		my_container = g:attach(my_container_attribs)
		my_container:attach(my_contents)
		my_container:attach_scrollbars()

		to allow mousewheel scrolling, still need to process messages from contents:

			function contents:mousewheel(msg)
				self.y += msg.wheel_y * 32 -- scroll speed is arbitrary
			end

			** to do: mousewheel event should propagate up to parent though (if not defined)
	]]

	function GuiElement:attach_scrollbars(attribs)

		--if no children, attach to parent! to do: standardise
		local container = self

		local bar_w = 8

		local attribs = attribs or {} 

		-- pick out only attributes relevant to scrollbar (autohide)
		-- caller could adjust them after though -- to do: perhaps should just spill everything in attribs as starting values
		local scrollbar = {
			x = 0, justify = "right",
			y = 0,
			width = bar_w,
			height = container.height,
			height_rel = 1.0,
			autohide = attribs.autohide,
			bar_y = 0,
			bar_h = 0,
			cursor = "grab",

			update = function(self, msg)
				local container = self.parent
				local contents  = container.child[1]
				local h0 = self.height
				local h1 = contents.height
				local bar_h = max(9, h0 / h1 * h0)\1  -- bar height; minimum 9 pixels
				local emp_h = h0 - bar_h - 1          -- empty height (-1 for 1px boundary at bottom)
				local max_y = max(0, contents.height - container.height)

				self.scroll_spd = max_y / emp_h
				if (max_y > 0) then
					self.bar_y = flr(- emp_h * contents.y / max_y)
					self.bar_h = bar_h
				else
					self.bar_y = 0
					self.bar_h = 0
				end

				if (self.autohide) then
					self.hidden = contents.height <= container.height
				end

				-- hack: match update height same frame 
				-- otherwise /almost/ works because gets squashed by virtue of height being relative to container, but a frame behind
				-- (doesn't work in some cases! to do: nicer way to solve this?)
				-- self.squash_to_clip = container.squash_to_clip 

				-- 0.1.1e: always clamp
				contents.x = mid(0, contents.x, container.width  - contents.width)
				contents.y = mid(0, contents.y, container.height - contents.height)

			end,
			
			draw = function(self, msg)
				local bgcol = 13
				local fgcol = 6

				rectfill(0, 0, self.width-1, self.height-1, bgcol | (fgcol << 8)) 
				if (self.bar_h > 0) rectfill(1, self.bar_y+1, self.width-2, self.bar_y + self.bar_h-1, fgcol)

				-- lil grip thing; same colour as background
				local yy = self.bar_y + self.bar_h/2
				line(2, yy-1, self.width-3, yy-1, bgcol)
				line(2, yy+1, self.width-3, yy+1, bgcol)

				-- rounded (to do: rrect)
				pset(1,self.bar_y + 1,bgcol)
				pset(self.width-2, self.bar_y + 1, bgcol)
				pset(1,self.bar_y + self.bar_h-1,bgcol)
				pset(self.width-2, self.bar_y + self.bar_h-1,bgcol)
				
			end,
			drag = function(self, msg)
				local content = self.parent.child[1]
				content.y -= msg.dy * self.scroll_spd
				-- clamp
				content.y = mid(0, content.y, -max(0, content.height - container.height))

			end,
			click = function(self, msg)
				local content = self.parent.child[1]
				
				-- click above / below to pageup / pagedown
				if (msg.my < self.bar_y) content.y += self.parent.height
				if (msg.my > self.bar_y + self.bar_h) content.y -= self.parent.height
			end
		}

		-- standard mousewheel support when attach scroll bar
		-- speed: 32 pixels // to do: maybe should be a system setting?
		function container:mousewheel(msg)
			local content = self.child[1]
			if (not content) return

			local old_x = content.x
			local old_y = content.y

			if (key("ctrl")) then
				content.x += msg.wheel_y * 32 
			else
				content.y += msg.wheel_y * 32 
			end

			-- clamp
			content.y = mid(0, content.y, -max(0, content.height - container.height))


			-- 0.1.1e: consume event (e.g. for nested scrollables)
			return true

			-- experimental: consume only if scrolled
			--if (old_x ~= content.x or old_y ~= content.y) return true 
			
		end

		return container:attach(scrollbar)

	end


	function GuiElement:attach_button(el)
		el.label = el.label or "[label]"
		el.width = el.width or #el.label * 5 + 10 -- to do: calculate width with current font
		el.height = el.height or 14
		el.cursor = "pointer"

		local b = self:attach(el)

		function b:draw(msg)
			local bgcol  = el.bgcol or 0x0706
			local fgcol  = el.fgcol or 0x0e01
			local border = el.border or bgcol
			if (msg.has_pointer) then
				bgcol  >>= 8
				fgcol  >>= 8
				border >>= 8
			end

			local yy = 0
			if (msg.mb > 0 and msg.has_pointer) yy = yy + 1

			local x0,y0,x1,y1 = 0,yy,self.width-1,yy+self.height-2

			
			if (el.border) then
				-- border: default corner radius 2 (to do: rrect)
				rectfill(x0+1,y0+1,x1-1,y1-1, bgcol)
				color(border)
				pset(x0+1,y0+1)
				pset(x0+1,y1-1)
				pset(x1-1,y0+1)
				pset(x1-1,y1-1)
				line(x0+2,y0,x1-2,y0)
				line(x0+2,y1,x1-2,y1)			
				line(x0,y0+2,x0,y1-2)
				line(x1,y0+2,x1,y1-2)
			else
				-- no border; default corner radius 1
				rectfill(x0+1,y0,x1-1,y0, bgcol)
				rectfill(x0,y0+1,x1,y1-1, bgcol)
				rectfill(x0+1,y1,x1-1,y1, bgcol)
			end

			print(self.label, self.width/2 - #self.label * 2.5, 3 + yy, fgcol)
		end

		return b

	end

	local attach_text_editor = nil 
	function GuiElement:attach_text_editor(...)
		-- lazily load the text editor
		if (not attach_text_editor) attach_text_editor = include("/system/lib/gui_ed.lua")
		return attach_text_editor(self, ...)
	end


	function GuiElement:detach(el)
		if (not el) then
			-- can just detach()
			return del(self.parent.child, self)
		end
		return del(self.child, el)
	end

	-- bring as far foward as will go before find an element with higher z
	function GuiElement:bring_to_front()
		p = self.parent
		if (not p) then return end

		for i=1,#p.child-1 do
			if (p.child[i] == self and p.child[i].z >= p.child[i+1].z) then
				p.child[i],p.child[i+1] = p.child[i+1],p.child[i]
			end
		end
	end

	-- push as far back as will go before find an element with lower z
	function GuiElement:push_to_back()
		p = self.parent
		if (not p) then return end

		for i=#p.child,2,-1 do
			
			if (p.child[i] == self and p.child[i].z <= p.child[i-1].z) then
				p.child[i],p.child[i-1] = p.child[i-1],p.child[i]
			end
		end
	end

	-- event propagates to children only when specified with msg.propagate_to_children (used for draw, update)
	-- normally don't want to propagate -- e.g. just click on pointer element

	function GuiElement:event(msg)

		if (not msg) then return end

		-- this helper is not scoped to a particular Gui -- need to pass in pointer_element via head
	
		if (self.head.pointer_element == self) then
			local mx, my = mouse()
			msg.has_pointer = (mx >= self.sx and my >= self.sy and mx < self.sx + self.width and my < self.sy + self.height)
		else
			msg.has_pointer = nil
		end

		local fin = false
		local cl,ct,cw,ch,cc

		-- call event handler if it exists
		if (type(self[msg.event]) == "function") then

			if (self.hidden) then

				-- no callbacks, no propagation to children
				fin = true

				-- exception: update callback is called on hidden elements but does not propagate to children
				-- means element can update own hidden state. ref: scrollbars autohide
				if (msg.event == "update") then
					self[msg.event](self, msg)
				end
			else

				-- 0.1.1e: always set mx,my,mb in message // was confused when tried to use if from an update callback
				-- to do: settle on which events get which state values
				-- local mx, my, mb = mouse() 
				msg.mx, msg.my = global_mx - self.sx, global_my - self.sy
				msg.mb = global_mb

				if (msg.event == "draw") then
					-- draw is special: optionally clip children and set camera position
					-- [experimental: also, can skip if outside]

					cl,ct,cw,ch,cc = clip(self.sx, self.sy, self.width, self.height, self.clip_to_parent)

					camera(-self.sx, -self.sy)

					--[[
						-- commented. works, but is too complex and spooky if it goes wrong
						-- when efficiency is needed, implement custom layer that handles longs lists etc (ref:filenav)
						if (self.clip_to_parent and cc) then
							-- clipped out -- can skip. and don't bother drawing children (implied clip_to_parent)
							fin = true
						else
							fin = self[msg.event](self, msg)
						end
					]]


					-- 0.1.1c: only bother drawing when state that this element depends on has changed
					-- to do: perhaps could draw (or blit to) own userdata if requested
					-- ** EXPERIMENTAL **
					if (self.draw_dependency) then

						local state_str = self:draw_dependency()
						if (state_str ~= self.last_state_str) then
							fin = self.draw(self, msg)
							self.last_state_str = state_str
						else
							-- -> can skip drawing this entire branch
							fin = true
						end
					else
						fin = self.draw(self, msg)
					end
				else

					-- generic callback (not "draw")

					fin = self[msg.event](self, msg)

				end
			end

		end

		if (not fin) then

			if (msg.propagate_to_children) then

				-- propagate to children (have to explicitly set in message)
				-- used for draw, update

				for i=1,#self.child do
					local c = self.child[i]
					if (c and c.event) then 
						c:event(msg)
					end
				end
			else

				-- default: propagate to parents   //   e.g. can mousewheel anywhere in scrollbox to scroll 
				-- block this by returning true from callback

				if (self.parent) self.parent:event(msg)

			end
		end

		

		-- restore clipping, camera state if needed
		if (cl) then
			clip(cl,ct,cw,ch)
			camera() -- to do: backup and restore
		end

	end


	-- Gui: class factory, extends GuiElement
	-- was Gui, now create_gui (consistent with create_undo_stack)

	function create_gui(head_el)

		head_el = head_el or {}

		head_el.head = head_el
		
		head_el.x = head_el.x or 0
		head_el.y = head_el.y or 0
		head_el.z = head_el.z or 0

		-- by default, occupy entire display adaptively
		if (not head_el.width)  head_el.width_rel  = 1.0
		if (not head_el.height) head_el.height_rel = 1.0

		head_el.width = head_el.width or 480
		head_el.height = head_el.height or 270

		local gui = GuiElement:new(head_el)

		local mx, my, mb, wheel_x, wheel_y = 0,0,0,0,0 -- 0.1.1f: made local again; sometimes want to clobber this state per-gui
		local last_mx, last_my, last_mb = 0,0,0
		local dx, dy = 0
		local start_mx, start_my,start_el,tap0_mx,tap0_my = 0,0,nil,0,0
		local drag_t = 0
		local dragging_el = nil

		-- don't pay attention to mouse button until it is first recorded as not pressed
		-- avoids complications when e.g. button is held on creation (generating click event)
		local block_mb = true

		-- to do: shouldn't need this? can use has_pointer()?
		function gui:get_pointer_element()
			return gui.pointer_element
		end

		function gui:get_keyboard_focus_element()
			return gui.keyboard_focus_el
		end

--[[
		-- commented; don't really want to have brittle iterator code in the window manager during dev
		-- breaks easily while experimenting with cpu model -> can't debug from inside
		-- (and turns out, don't really need this)
		function iter(tree)

			local function traverse(node)
				coroutine.yield(node)
				for i=1,#node.child do
				    traverse(node.child[i])
				end
			end

			local c = coroutine.create(function() traverse(tree) end)
		 
			return function()
				local _, value  = coresume(c) -- wrapped version needed in order to reconstruct call tree
--				local _, value  = coroutine.resume(c)
				return value
			end
		end
]]

		-- to do: rename: "evaluate_element"?
		local function update_absolute_position(el, px0, py0, px1, py1)
				
				-- hack: update head so that tree structure can change (should that be allowed? wm does it!)
				el.head = el.parent.head or el

				-- optimisation: shouldn't need to calculate for hidden elements
				if (el.hidden) return

				local px = el.parent.sx or 0
				local py = el.parent.sy or 0
				local elx = el.x or 0 -- necessary! to do: review .x .y existence
				local ely = el.y or 0
				
				-- set clipping rectangle to union of self and parent clipping // dupe from el_at_xy_recursive
				local sx0, sy0 = el.sx, el.sy
				local sx1 = sx0 + el.width
				local sy1 = sy0 + el.height
				if (el.clip_to_parent) then
					sx0 = mid(px0, sx0, px1)
					sy0 = mid(py0, sy0, py1)
					sx1 = mid(px0, sx1, px1)
					sy1 = mid(py0, sy1, py1)
				end

				-- relative size (might get squashed)
				if (el.width_rel)  el.width  = el.parent.width  * el.width_rel  + (el.width_add or 0)   el.width0 = el.width
				if (el.height_rel) el.height = el.parent.height * el.height_rel + (el.height_add or 0)  el.height0 = el.height


				-- confining and squashing
				if (el.confine_to_clip or el.squash_to_clip or el.confine_to_parent or el.squash_to_parent) then
					-- similar to confine_to_parent, but use px0, py0, px1, py1 relative to parent sx, sy
					local x0 = px0 - el.parent.sx
					local y0 = py0 - el.parent.sy
					local x1 = px1 - el.parent.sx
					local y1 = py1 - el.parent.sy

					-- when confine_*() or squash_*() is used on an element, the width and height attrs change meaning to "evaluated size".
					-- to change the size of such elements, modify width0, height0 instead  //  wm does this
					el.width  = el.width0
					el.height = el.height0

					-- squash first because might still want to confine afterwards due to minimum width, height

					if (el.squash_to_parent) then
						-- adjust size to fit 
						if (elx < 0) then
							el.width += elx
							elx = 0
						end
						if (ely < 0) then
							el.height += ely
							ely = 0
						end
						el.width = max(el.min_width,   min(el.width, el.parent.width - elx))
						el.height = max(el.min_height, min(el.height, el.parent.height - ely))
						
					end

					-- ditto

					if (el.squash_to_clip) then
						-- adjust size to fit 
						--printh("squash_to_clip: "..pod{x0,y0,x1,y1})
						if (elx < x0) then
							el.width = max(el.min_width, el.width - (x0 - elx))
							--printh("squash left: adjust elx "..elx.." to x0:"..x0)
							elx = x0
						end
						if (ely < y0) then
							el.height = max(el.min_height, el.height - (y0 - ely))
							ely = y0
						end
						el.width  = max(el.min_width,  min(el.width,  x1 - elx))
						el.height = max(el.min_height, min(el.height, y1 - ely))
					end

					-- confine_to_parent: reposition so that element remains inside parent
					-- (when oversized, set x / y to 0 -- can use with squash_to_parent)

					if (el.confine_to_parent) then
						-- bump left, up
						elx = min(elx, el.parent.width - el.width)
						ely = min(ely, el.parent.height - el.height)
						-- bump right, down 
						elx = max(0, elx)
						ely = max(0, ely)
					end
					
					if (el.confine_to_clip) then
						-- bump left, up
						elx = min(elx, x1 - el.width)
						ely = min(ely, y1 - el.height)
						-- bump right, down 
						elx = max(x0, elx)
						ely = max(y0, ely)
					end

					
				end

				
				if (el.justify == "right") then
--					printh("justify right  el.x,width,parent.width: "..pod{el.x, el.width, el.parent.width})
				end

				-- apply justification by modifying parent position
				if (el.justify or el.vjustify) -- faster test: unusually false
				then
					if (el.justify == "right")  then px = px + el.parent.width - el.width end
					if (el.justify == "center") then px = px + el.parent.width/2 - el.width/2 end
					if (el.vjustify == "bottom") then py = py + el.parent.height - el.height end
					if (el.vjustify == "center") then py = py + el.parent.height/2 - el.height/2 end
				end

				-- add parent position
				el.sx = (px + elx) \ 1
				el.sy = (py + ely) \ 1

				for i=1, #el.child do
					update_absolute_position(el.child[i], sx0, sy0, sx1, sy1)
				end

		end


		local function update_absolute_positions()

			-- dummy parent to reduce logic in update_absolute_position()

			gui.parent = {
				x=0, y=0,
				width = get_display():width(),
				height = get_display():height()
			}

--			update_absolute_position(head_el) -- head_el /is/ the gui

			-- in case squash_*() or confine_*() is used, need to calculate clipping rectangle -- same pattern as el_at_xy()
			-- using sfx.p64 instrument editor to measure: ~15% cpu increase
			-- to do: flatten gui tree once and iterate over that? do later when gui has settled down
			if (head_el.sx) then -- safety; should always be set already
				update_absolute_position(head_el, head_el.sx, head_el.sy, head_el.sx + head_el.width, head_el.sy + head_el.height)
			end

			gui.parent = nil

		end


		local function el_at_xy_recursive(el, px0, py0, px1, py1, x, y) --, depth)

			-- was needed due to superyield L->top borking bug -- can guarantee now?
			--[[
			if (not el or not el.sx or not el.sy) then printh("*** bad el in el_at_xy_recursive") return end
			if (depth > 64) then printh("*** max depth el_at_xy_recursive") return end
			]]

			-- ghost is drawn but can't interact
			if (el.hidden or el.ghost) return nil

			local best_el = nil

			local sx0, sy0 = el.sx, el.sy
			local sx1 = sx0 + el.width
			local sy1 = sy0 + el.height

			-- clip by parent -- events should also be clipped when not visibly interacting

			if (el.clip_to_parent) then
				sx0 = mid(px0, sx0, px1)
				sy0 = mid(py0, sy0, py1)
				sx1 = mid(px0, sx1, px1)
				sy1 = mid(py0, sy1, py1)
			end

			--printh("el_at_xy_recursive "..pod{tostring(el), {x, y}, {sx0, sy0, sx1, sy1}})

			local is_inside = (x >= sx0 and x < sx1 and y >= sy0 and y < sy1)
	
			-- last element in tree (so prefers leaf nodes). matches visual order

			if (is_inside and (not el.test_point or el:test_point(x - el.sx, y - el.sy))) then
				best_el = el
			end
			
			-- only search children when inside
			-- (unless clip_to_parent is false, in which case children could be anywhere)
			-- 0.1.1e: fixed; was "if (true or is_inside.." -- thx Eiyeron!
			-- need to test for every child; is the /child/ that might not be clipped and should be clickable
			-- https://www.lexaloffle.com/bbs/?tid=145205 // "Scrollbar content are clickable past their parents"
			for i=1, #el.child do
				if (is_inside or not el.child[i].clip_to_parent) then
					--best_el = el_at_xy_recursive(el.child[i], sx0, sy0, sx1, sy1, x, y, depth + 1) or best_el -- debug
					best_el = el_at_xy_recursive(el.child[i], sx0, sy0, sx1, sy1, x, y) or best_el
				end
			end
			
			return best_el
		
		end

		-- x, y are relative to TLC of gui
		function gui:el_at_xy(x, y)
			local el = nil

			--[[
				don't interact with gui a moment after it was created; avoid complex edge cases
				e.g. dragging while regenerate gui -> don't want to immediately pick up whatever
				is under the cursor. (confusing)
			]]
			-- 0.1.0c: commented; pushes complexity to other places! e.g. drop file into newly opened window
			--if (time() < gui.t0 + 0.2) return false

			-- no element when outside of gui itself (head element)
			el = el_at_xy_recursive(gui, gui.x, gui.y, gui.x + gui.width, gui.y + gui.height, x, y, 0)
			--el = el_at_xy_recursive(gui, 0, 0, 480, 270, x, y ,0)
			
			--printh("--> el_at_xy: "..tostring(el).."  //  "..pod{el.sx,el.sy,el.width,el.height})
			return el

		end

		-- deleteme
		function gui:el_at_pointer(x,y)
			printh("** FIXME: el_at_pointer -> el_at_xy")
			return gui:el_at_xy(x,y)
		end

		-- sometimes want to make an element that isn't attached [yet]
		-- e.g. scroll box contents
		function gui:new(el)
			return GuiElement:new(el)
		end

		

		--[[
					0x5480 ~ 0x5bff     (64) indexed display palette
					0x54c0 ~ 0x553f     (128) picotron misc draw state
		]]
		local draw_state = userdata("i64", 24) -- 192 bytes

		function gui:draw_all()

			update_absolute_positions()

			local el=self
			local msg = el and { mx = mx - el.sx, my = my - el.sy, mb = mb} or {}

			msg.event = "draw"
			msg.propagate_to_children = true

			-- should gui be responsible for preserving draw state?
			draw_state:peek(0x5480, 0, 24) -- back up 192 bytes of draw state
			clip() camera()
			self:event(msg)
			draw_state:poke(0x5480) -- restore

		end


		-- update_all mean update the whole gui tree -- is typically called onced from _update
		function gui:update_all()

			last_mx, last_my, last_mb = mx, my, mb
			mx, my, mb, wheel_x, wheel_y = mouse() -- screen space
			global_mx, global_my, global_mb = mouse() -- optimisation: only fetch once per frame; for constructing msg

			dx = mx - last_mx
			dy = my - last_my

			if (block_mb and mb == 0) block_mb = false
			if (block_mb) then
				-- consider mouse state to be junk when mb hasn't been 0 yet
				mx,my,mb = 0,0,0
			end

			update_absolute_positions()

			-- if dragging something, always pay attention only to that
			-- (even if drag outside of that element)

			local el = dragging_el or gui:el_at_xy(mx, my)

			-- can be nil
			gui.pointer_element = el 


			-- check for hidden parent
			
			local el2 = el
			while (el2) do
				if (el2.hidden) el = nil -- found; don't send any messages
				el2 = el2.parent
			end



			----------------- update cursor --------------------------------------------------------------


			gui.mouse_cursor_gfx = (el and el.cursor) or false -- use false so that can send in a message

			if (pid() > 3) then
				if (gui.last_mouse_cursor_gfx != gui.mouse_cursor_gfx) then
					window{cursor = gui.mouse_cursor_gfx}
				end
				gui.last_mouse_cursor_gfx = gui.mouse_cursor_gfx
			end


			----------------- standard messages: only send to element at pointer -----------------------

			-- construct generic message with state information
			local msg = el and {
				mx = mx - el.sx, 
				my = my - el.sy, 
				mb=mb, dx=dx, dy=dy
			} or {}


			

			
			local do_double_click = false
			local do_double_tap = false

			local dx = start_mx - mx
			local dy = start_my - my

			-- mouse down: could be click or click + double-click
			if el and last_mb == 0 and mb > 0 then


				-- mouse buttons needs to match: clicking left and then right quickly should not trigger double click/tap
				if ((el.last_click_t and time() - el.last_click_t < 0.4) and 
					mb == el.last_click_mb and
					dx*dx + dy*dy < 4*4
				) then
					do_double_click = true
					-- (send message later -- would click message to be sent first)
				end


				-- click
				-- two click messages for every double click -- because might only care about rapid clicks and not double clicks
				
				-- mousedown (and not second click in a double click): send click and start drag
				
				start_mx = mx
				start_my = my
				start_el = el -- to do: use this to discard some interactions that should start and end on the same element (no gui refresh midway)
				drag_t = time()
				dragging_el = el	
				-- commented: need to explicitly set, so that it is possible to know if there 	
				-- is an element that is actively consuming keyboard input via gui:get_keyboard_focus_element
				--gui.keyboard_focus_el = el 
				el.last_click_t = time()
				el.last_click_mb = mb

				-- 0.1.0h clicking anywhere removes keyboard focus [but can be immediately regained by the element being clicked on]
				-- this allows any textfield to be clicked outside of to remove focus. ref: renaming instrument / map layer
				-- to do: is that behaviour ever unwanted? should be optional?
				el.head.keyboard_focus_el = nil

				msg.event="click" el:event(msg)
				

			end

			-- mouseup: send release and possibly tap
			if (el and last_mb > 0 and mb == 0) then

				-- tap if mouse position hasn't moved more than 4 pixels
				--local dx = start_mx - mx
				--local dy = start_my - my

				-- only tap when close to position-at-mousedown within one second, and element existed for 200ms or more
				-- 0.1.1e: tap must be within 0.3 seconds (was 1.0 -- too slow; could be meant as a drag)
				-- ref: filenav doubleclick to enter folder -> don't want tap on newly created interface
				if (dx*dx + dy*dy < 4*4 and time() < drag_t + 0.3 and t() > el.t0 + 0.2) then

					msg.event="tap" msg.last_mb = last_mb el:event(msg)

					-- also send a doubletap if second tap (using same mouse button)
					if (el.last_tap_t and time() - el.last_tap_t < 0.4 and last_mb == el.last_tap_mb and
							(tap0_mx-mx)^2 + (tap0_my-my)^2 < 4*4 -- close to original tap position
						) then
						do_double_tap = true
					else
						el.last_tap_t = time()
						el.last_tap_mb = last_mb
					end

					tap0_mx = mx
					tap0_my = my

				end

				-- common to want to know where drag started from
				msg.mx0 = start_mx - el.sx
				msg.my0 = start_my - el.sy

				-- release
				msg.event="release" el:event(msg)
			end

			-- hover. maybe don't need?
			if (el and mb == 0) then
				msg.event="hover" el:event(msg)
			end

			-- drag
			if (dragging_el) then

				-- if (last_mb > 0 and mb > 0) then -- only start dragging the frame after mouse button becomes active
				if (mb > 0) then  -- what's wrong with dragging from first frame? need that interactivity! e.g. pick up colour in sprite editor
					msg.event="drag" 
					-- common to want to know where drag started from
					msg.mx0 = start_mx - dragging_el.sx -- 0.1.1f: was el.sx, el.sy
					msg.my0 = start_my - dragging_el.sy

					-- locked pointer? use that for dx, dy. ref: instrument designer envelope knob
					if (peek(0x5f2d) & 0x4) > 0 then
						local locked_dx, locked_dy = mouselock()
						msg.dx = locked_dx
						msg.dy = locked_dy
					end

					dragging_el:event(msg)
					--printh("dragging_el: "..tostring(dragging_el))
				elseif (mb == 0) then            -- .. but stop dragging immediately when mouse button released

					dragging_el = nil

					-- auto unlock mouse on release
					if ((peek(0x5f2d) & 0x8) > 0) poke(0x5f2d, peek(0x5f2d) & ~0x4)
				end
			end

			-- doubleclick sent after click / drag (e.g. in text editor, don't want to deselect what the double click selected)
			if (do_double_click) then
				msg.event="doubleclick" el:event(msg)
				el.last_click_t = 0
			end

			-- doubletap message comes after second tap message
			if (do_double_tap) then
				msg.event="doubletap" el:event(msg)
			end

			-- mousewheel event
			
			if (el and (wheel_x ~= 0 or wheel_y ~= 0)) then
				msg.wheel_x = wheel_x
				msg.wheel_y = wheel_y
				msg.event="mousewheel" el:event(msg)
			end
	
			----------------- send update message to gui tree -----------------------

			msg.event="update" msg.propagate_to_children = true self:event(msg)


		end


		return gui
	end

end
