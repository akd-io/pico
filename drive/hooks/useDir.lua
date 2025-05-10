include("/lib/describe.lua")

-- TODO: Implement timeout option that invalidates cache items X seconds old.
-- TODO: Return an invalidate() function that can be used to invalidate all paths.
-- TODO: Return an invalidate(path) function that can be used to invalidate a single path.
-- TODO: More inspiration from useQuery?
-- TODO: useDirs should return an array not an object?
-- TODO: placeholderData?

function useDirs(paths)
  local hookInstanceId = tostring(useState({})) -- Keep using `tostring`. `tostr(useState({}))` returns `0x0`, as `setState` is passed as `tostr`'s second param.
  --printh("[useDir] hookInstanceId: " .. hookInstanceId)

  --- Path to PID map
  ---@type table<string,number?>
  local workerIDs = useState({})

  --- Path to {result, loading} map
  ---@type table<string,{ result?: table, loading: boolean }>
  local states, setStates = useState({})

  useMemo(function()
    --printh("useDirs: paths param changed!")
    -- TODO: Traverse workerIDs instead of paths to kill workers that are no longer needed
    -- TODO: Also remove states of irrelevant paths, unless a specific cache option is set?

    for path in all(paths) do
      if (states[path] == nil) then
        states[path] = {
          result = nil,
        }
      end
      states[path].loading = true

      if (workerIDs[path] != nil) then
        -- Kill worker
        --printh("Killing worker for path " .. path)
        send_message(2, { event = "kill_process", proc_id = workerIDs[path] })
      end
      workerIDs[path] = create_process("/hooks/useDirWorker.lua", { argv = { path, hookInstanceId } })
      --printh("Spawned worker: " .. tostr(workerIDs[path]))
    end
  end, { paths })

  useMemo(function()
    --printh("useDirs: Initial render: Setting up on_event.")
    on_event(
      "dir_result",
      function(msg)
        if (hookInstanceId != msg.hookInstanceId) then
          -- TODO: Is it possible to only call on_event once per application, while keeping the closure???
          -- TODO: So we don't have to do this?
          --printh("Wrong hook instance. Am " .. hookInstanceId .. " but got " .. msg.hookInstanceId)
          return
        end
        --printh("Received dir_result:"
        --printh(describe(msg))
        local path = msg.path
        local packedLsResult = msg.packedLsResult
        --printh(describe(packedLsResult))
        local a, b, c = unpack(packedLsResult, 1, packedLsResult.n)
        --printh("a: " .. tostr(a))
        --printh("b: " .. tostr(b))
        --printh("c: " .. tostr(c))

        local newStates = shallowCopy(states)
        newStates[path].result = a
        newStates[path].loading = false
        states = setStates(newStates)

        workerIDs[path] = nil
      end
    )
  end, {})

  return states
end

function useDir(path)
  local stabilePaths = useMemo(function()
    return { path }
  end, { path })

  return useDirs(stabilePaths)[path]
end
