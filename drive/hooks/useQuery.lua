-- TODO: Replace processes with coroutines, once fetch yields again.
-- TODO: Implement `useQueries`, and make `useQuery` simply wrap it
-- TODO: Implement timeout option that invalidates cache items X seconds old.
-- TODO: Return an invalidate() function that can be used to invalidate all queries.
-- TODO: Return an invalidate(path) function that can be used to invalidate a single query.
-- TODO: More inspiration from useQuery?
-- TODO: useQueries should return an array not an object?
-- TODO: placeholderData?

--include("/lib/describe.lua")

function useQuery(url)
  local privateState = useState({
    workerID = nil
  })
  local state = useState({})

  useMemo(function()
    on_event(
      "fetch_result",
      function(msg)
        --printh("[useQuery] "..describe(msg))
        local packedFetchResult = msg.packedFetchResult
        --printh("[useQuery] "..describe(packedFetchResult))
        local a, b, c = unpack(packedFetchResult, 1, packedFetchResult.n)
        --printh("a: " .. tostr(a))
        --printh("b: " .. tostr(b))
        --printh("c: " .. tostr(c))
        state.result = a
        state.meta = b
        state.error = c
        state.loading = false
        privateState.workerID = nil
      end
    )
  end, {})

  useMemo(function()
    if (privateState.workerID != nil) then
      -- Kill worker
      --printh("Killing worker")
      send_message(2, { event = "kill_process", proc_id = privateState.workerID })
    end

    -- TODO: I believe there is a race condition here.
    -- TODO: Find out when events are processed. I believe we should process them on this line manually if possible.
    -- TODO: Otherwise, an "old" event might be processed right after this next process is created,
    -- TODO: 1. Resetting the workerID, making it impossible to kill the process.
    -- TODO: 2. overriding the result and loading with an old result.

    -- TODO: As simple as __process_event_messages() ???
    -- TODO: This depends if __process_event_messages() processes messages for all processes, or just this one.
    -- TODO: If it's only this one, I think we are still in trouble.
    -- TODO: The kill_process from above won't be processed until the start of next frame (pm has process id 2)
    -- TODO: So even though we queued the worker to die, it still has one last frame left to finish,
    -- TODO: in which it could finish and queue an outdated message to this process.
    -- TODO: If __process_event_messages processes messages for all processes, then we are good.

    -- TODO: Upon reading the __process_event_messages source,
    -- TODO: It seems to only process events local to the current process, and `events.lua` is added to the foot of the script of every process.

    -- TODO: Maybe we can earmark every worker process with a unique id, maybe the number of runs of this useMemo hook (times url has changed)
    -- TODO: We can then filter events by this id.

    state.result = nil
    state.meta = nil
    state.error = nil
    state.loading = true
    privateState.workerID = create_process("useQueryWorker.lua", { argv = { url } })
    --printh("workerID: " .. tostr(privateState.workerID))
  end, { url })

  return state
end
