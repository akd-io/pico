local e = env()
local path = e.argv[1]
local hookInstanceId = e.argv[2]

-- TODO: Refactor into a general purpose worker.
-- TODO: Worker takes `funcName` string, `args` array, and `return` boolean.
-- TODO: Runs `funcName` with `args` and messages the parent process with the
-- TODO: result before exiting if `return` is true.
-- TODO: Event will include `funcName`, `args`, and `packedResult`, where `packedResult` is the result of `pack(result)`.
-- TODO: IMPORTANT: What DX makes it easy to identify a worker-call? We can add
-- TODO: a unique ID to the event, and the worker can include that ID in the event it sends back.
-- TODO: But what DX makes it easy to generate and set the ID when calling from parent?

send_message(e.parent_pid, {
  event = "dir_result",
  path = path,
  packedLsResult = pack(ls(path)),
  hookInstanceId = hookInstanceId
})
