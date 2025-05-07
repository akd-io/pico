local lsRPC = createRPC({
  funcName = "ls",
  --- event is optional.
  --- The default is `rpc_response_<funcName>`.
  --- If you need several event handlers targeting the same function, this allows you to specify a custom event.
  event = "my_custom_event",
  onEvent = function(msg)
    --- RPC adds the helper function `msg.rpc.unpackResult()`, which unpacks the result of the remote function call.
    --- This is because `unpack(array)` has some edge cases around non-trailing nil values, `{nil, 123}` for example.
    local result = msg.rpc.unpackResult()

    --- RPC adds `msg.rpc._packedResult` if you really need the packed result.
    --- Its use is discouraged, for the reasons stated above.
    local packedResult = msg.rpc._packedResult

    --- `id` was added in the call down below, and is sent back unchanged by the worker.
    local id = msg.rpc.id
  end,
})

--- `lsRPC` is now a function that you can call.
--- Its only argument is an env patch table.
lsRPC({
  --- `funcArgs` is special and used to pass arguments to the worker function.
  funcArgs = { "/" },
  --- Hereafter, you can pass any env patch you want.
  --- The worker will send all of these back to you in the response.
  id = "root",
})
