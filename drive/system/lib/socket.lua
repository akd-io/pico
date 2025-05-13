--[[

	socket.lua

	** WIP -- backend not in release builds yet **

	sock = create_socket("tcp://1.2.3.4:1234") -- to do: "tcp://" too weird?
	?sock:status() -- non-blocking; might want to check for error later
	len = sock:write("hey")
	str = sock:read()
	sock:close()

]]

local Socket = {}

local _create_tcp_socket = _create_tcp_socket
local _close_socket = _close_socket
local _read_tcp_socket = _read_tcp_socket
local _write_tcp_socket = _write_tcp_socket

-- to do: should [also] happen when garbage collected 
-- (or just time out; don't usually want long idle connections on backend anyway)
function Socket:close()
	if (not self.id) return
	_close_socket(self.id)
end


function Socket:new(attribs)

	if (not _create_tcp_socket) return nil, "socket implementation not available"

	if (type(attribs) == "string") attribs = {addr = attribs}

	-- need an address. "*" for server?
	if (not attribs.addr) return nil, "no address specified"

	-- split protocol from address
	local prot = attribs.addr:prot()
	if (prot) then
		attribs.addr = sub(attribs.addr, #prot + 4)
		attribs.prot = prot
	end

	-- split port number from address
	local res = split(attribs.addr, ":", false)
	if (res[2]) then
		attribs.addr = res[1]
		attribs.port = res[2]
	end	

	local sock = attribs

	setmetatable(sock, self)
	self.__index = self

	-- printh(":new // attribs arg: "..pod(attribs))

	if (sock.prot == "tcp")
	then
		sock.id, err = _create_tcp_socket(attribs.port, attribs.addr)		
		if (not sock.id) then
			printh("[socket.lua] tcp socket creation failed")
			return nil, "_create_tcp_socket failed"
		end
		--printh("got sock.id: "..sock.id)
		return sock
	end
	
	return nil, "socket protocol not found"
end

function Socket:read()
	local res = _read_tcp_socket(self.id)
	return res
end

function Socket:write(dat)
	local res = _write_tcp_socket(self.id, dat)
	return res
end


function create_socket(...)
	return Socket:new(...)
end

