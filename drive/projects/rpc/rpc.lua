--[[
  - Change name from RPC.
    - RPC is aleady only true in a vague sense, as we're only communicating between processes.
    - But also, the call of the local function wont return the result of the remote function.
      It will be caught in by the event handler.
    - We can release a proper RPC library later, on top of a promise abstraction if I or someone else makes one.

  - In usage, it's possible to specify `id` in the env patch, which will be returned in the response.
    This is useful for identifying the response when multiple RPC calls are made in quick succession.
    - It would have been nice to redesign createRPC to include `id` in the event name, eg. `rpc_response_<funcName>_<id>`.
      - But this is not possible, as unsubscribing from events is not supported.
        We would end up with thousands of subscriptions if we did this.
]]

local seenEvents = {}

--- `createRPC` returns a function that can be called to invoke another function, specified by `createOptions.funcName`, in a worker thread.
---
--- `createRPC` will automatically wire up `on_event` using event `worker_response_<funcName>`
---
---@param createOptions {
---  funcName: string,
---  onEvent?: function,
---  event?: string,
---}
function createRPC(createOptions)
  assert(type(createOptions) == "table", "createOptions must be an object.")

  local funcName = createOptions.funcName
  assert(type(funcName) == "string", "createOptions.funcName must be a string.")

  local event = "rpc_response_" .. funcName

  if createOptions.onEvent then
    --printh("[rpc] createRPC: onEvent is specified.")
    assert(type(createOptions.onEvent) == "function", "createOptions.onEvent must be a function or nil.")

    local optionsEvent = createOptions.event -- For type inference
    if (optionsEvent) then
      assert(type(optionsEvent) == "string", "createOptions.event must be a string or nil.")
      event = optionsEvent
    end

    assert(not seenEvents[event], "createRPC was called twice with the same event name: " .. event)
    seenEvents[event] = true

    --printh("[rpc] createRPC: on_event(" .. event .. ")")
    on_event(event, function(msg)
      --printh("[rpc] Got event " .. msg.event .. " from process " .. msg._from)
      --printh("[rpc] Msg: " .. pod(msg))
      local function unpackResult()
        return unpack(msg.rpc._packedResult, 1, msg.rpc._packedResult.n)
      end
      --printh("[rpc] type(unpackResult) = " .. type(unpackResult))
      msg.rpc.unpackResult = unpackResult
      --printh("[rpc] Calling onEvent with msg: " .. pod(msg))
      createOptions.onEvent(msg)
    end)
  end

  ---@param callOptions {
  ---  funcArgs: table,
  ---}
  return function(callOptions)
    assert(type(callOptions) == "table", "callOptions must be an object.")
    assert(type(callOptions.funcArgs) == "table", "callOptions.funcArgs must be an array.")

    local rpc = {}
    for key, value in pairs(callOptions) do
      rpc[key] = value
    end

    rpc.funcName = funcName
    if createOptions.onEvent then
      rpc.event = event
      rpc.doReturn = true
    end
    -- TODO: Calculate path dynamically to be this file's dir + "/rpcWorker.lua"
    create_process("/projects/rpc/rpcWorker.lua", {
      rpc = rpc
    })
  end
end
