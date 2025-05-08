--[[pod_format="raw",created="2024-03-24 14:56:58",modified="2024-03-24 14:56:58",revision=0]]


-- iterators need to be in lua to avoid c boundary yielding

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

-- pico-8 style sub // to do: move to c

function sub(str, p0, p1)
	if (type(str) ~= "string") then return end
	if (p1 ~= nil and type(p1) != "number") p1 = p0 -- get character at pos
	return string.sub(str, p0, p1)
end


-- pico-8 compatibility (but as_hex works differently; no fractional part)
-- weird to have 2 slightly different ways to write the same thing, but tostr(foo,1) is too handy for getting hex numbers

local _tostring = tostring
function tostr(val, as_hex)
	if (as_hex) then
		if (type(val) != "number") printh(pod(val))
		return string.format("0x%x", tonumber(val) or 0)
	else
		return _tostring(val)
	end
end

-- deleteme -- moved to c functions
--[[

-- pico-8 compatibility
local _tonumber = tonumber
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


function mid(a,b,c)
	b = b or 0
	c = c or 0
	if a < b then
		return a < c and min(b,c) or min(a,b)
	else
		return b < c and min(a,c) or min(a,b)
	end
end
]]




