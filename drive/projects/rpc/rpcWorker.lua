local environment = env()
local options = environment.rpc

local packedResult = pack(_ENV[options.funcName](unpack(options.funcArgs)))

if (options.doReturn) then
  local msg = {
    rpc = {}
  }
  for k, v in pairs(options) do
    msg.rpc[k] = v
  end
  msg.rpc._packedResult = packedResult
  send_message(environment.parent_pid, msg)
end
