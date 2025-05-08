--[[pod_format="raw",created="2024-03-24 14:56:58",modified="2024-03-24 14:56:58",revision=0]]


local _fcopy = _fcopy
local _fdelete = _fdelete


-- some of these should be moved into c

function all(c) if (c == nil or #c == 0) then return function() end end
 	local i=1
 	local li=nil
 	return function()
 		if (c[i] == li) then i=i+1 end
 		while(c[i]==nil and i <= #c) do i=i+1 end
 		li=c[i]
 		return li
 	end
end


function foreach(c,_f)
	for i in all(c) do _f(i) end 
end


function sub(str, ...)
	if (type(str) ~= "string") then return end -- pico-8 behaviour
	return string.sub(str, ...)
end



-- pico-8 compatibility (but as_hex works differently; no fractional part)
-- weird to have 2 slightly different ways to write the same thing, but tostr(foo,1) is too handy for getting hex numbers
--> jettison tostring, tonumber for now! can add back later if need

local _tonumber = tonumber
local _tostring = tostring

function tostr(val, as_hex)
	if (as_hex) then
		return string.format("0x%x", val)
	else
		return _tostring(val)
	end
end

-- pico-8 compatibility
function tonum(...)
	return _tonumber(...)
end


function abs(a)
	if (type(a) != "number") a = 0
	return a >= 0 and a or -a
end

function sgn(a)
	if (type(a) != "number") a = 0
	return a >= 0 and 1 or -1
end

function max(a,b)
	if (type(a) != "number") a = 0
	if (type(b) != "number") b = 0
	return a > b and a or b
end

function min(a,b)
	if (type(a) != "number") a = 0
	if (type(b) != "number") b = 0
	return a < b and a or b
end

unpack = table.unpack
pack = table.pack

function mid(a,b,c)
	b = b or 0
	c = c or 0
	if a < b then
		return a < c and min(b,c) or min(a,b)
	else
		return b < c and min(a,c) or min(a,b)
	end
end

-- keep local copies so that they can be used internally, even if rm and/or rm are renamed in userland
local _cp = nil
local _rm = nil

function rm(f0)

	local attribs, size, origin = fstat(f0)

	if (not attribs) then
		-- does not exist
		return
	end

	if (attribs == "folder") then

		-- folder: first delete each entry using this function
		if (not origin) then -- dont recurse into origin!
			local l = ls(f0)
			for k,fn in pairs(l) do
				_rm(f0.."/"..fn)
			end
		end
		-- remove metadata (not listed)
		_rm(f0.."/.info.pod")

	end

	-- delete single file / now-empty folder
	return _fdelete(f0)
end

_rm = rm



--[[	
	cp(src, dest)
	if dest exists, is deleted!  (cp util / filenav copy operations can do safety)

]]
function cp(f0, f1)

	f0 = fullpath(f0)
	f1 = fullpath(f1)

	if (not f0)   return "could not resolve source path"
	if (not f1)   return "could not resolve destination path"
	if (f0 == f1) return "can not copy over self"

	local f0_type = fstat(f0)
	local f1_type = fstat(f1)

	if (not f0_type) then
		-- print(tostr(f0).." does not exist") 
		return
	end

	-- explicitly delete in case is a folder -- want to make sure contents are removed
	-- to do: should be an internal detail of delete_path()?
	if (f1_type) _rm(f1)

	-- folder: recurse
	if (f0_type == "folder") then

		-- 0.1.0c: can not copy inside itself   "cp /ram/cart /ram/cart/foo" or "cp /ram/cart/foo /ram/cart" 
		local minlen = min(#f0, #f1)
		if (sub(f1, 1, minlen) == sub(f0, 1, minlen)) then
			return "can not copy folder inside self" -- 2 different meanings!
		end

		-- get a cleared out root folder with fresh metadata
		mkdir(f1)

		-- copy each item (could also be a folder)

		local l = ls(f0)
		for k,fn in pairs(l) do
			local res = _cp(f0.."/"..fn, f1.."/"..fn)
			if (res) return res
		end

		-- copy metadata over if it exists (ls does not return dotfiles)
		_cp(f0.."/.info.pod", f1.."/.info.pod")

		return
	end

	-- binary copy single file
	_fcopy(f0, f1)

end

_cp = cp


--[[

	placeholder mv
	to do: safety! efficiency! errors! semantics!

	currently moving a mount copies it into a regular file and removes the mount;
	should be possible to rename/move mounts around?
	
]]
function mv(src, dest)

	if (fullpath(src) == fullpath(dest)) return
	_cp(src, dest)
	_rm(src)
end



