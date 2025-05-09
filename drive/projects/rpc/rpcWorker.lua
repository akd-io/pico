local environment = env()
local options = environment.rpc

--printh("[rpcWorker] Function name: " .. options.funcName)
--printh("[rpcWorker] Function args: " .. table.concat(options.funcArgs, ", "))
--printh("[rpcWorker] Event: " .. tostr(options.event))
--printh("[rpcWorker] Do return: " .. tostr(options.doReturn))
local func = _ENV[options.funcName]
local _packedResult = pack(func(unpack(options.funcArgs)))

if (options.doReturn) then
  local msg = {
    event = options.event,
    rpc = {}
  }
  for k, v in pairs(options) do
    msg.rpc[k] = v
  end
  msg.rpc._packedResult = _packedResult
  --printh("[rpcWorker] Packed result: " .. pod(_packedResult))
  --printh("[rpcWorker] Sending message to parent process " .. environment.parent_pid .. " with event " .. options.event .. ".")
  --printh("[rpcWorker] Msg: " .. msg)
  send_message(environment.parent_pid, msg)
end
