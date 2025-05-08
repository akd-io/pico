function useLabels(cartPaths, labelCachePodFilePath)
  local memLabelCache = useState(function()
    if (fstat(labelCachePodFilePath)) then
      local cache = fetch(labelCachePodFilePath)
      -- TODO: Check against cache schema. Refresh if invalid.
      -- TODO: Refresh if stale.
      return cache
    end
    return {}
  end)

  -- TODO: Remove labels from cache when off screen and not to be displayed in a prev/next press or two.
  -- TODO: Refactor to use `useQueries`? The `qoiDecode` func call is hopefully cheap, so it's just the fetching that slow? 🤞

  local labels = useMemo(function()
    local labels = {}
    for cartPath in all(cartPaths) do
      if not memLabelCache[cartPath] then
        local pathSegments = cartPath:split("/")
        local safeCartPath = "bbs://" .. pathSegments[#pathSegments]
        local labelQoiString = fetch(safeCartPath .. "/label.qoi")
        memLabelCache[cartPath] = qoiDecode(labelQoiString)
      end
      add(labels, memLabelCache[cartPath])
    end
    return labels
  end, { cartPaths })

  useMemo(function()
    -- On initial render, store cache
    store(labelCachePodFilePath, memLabelCache)
  end, {})

  return labels
end
