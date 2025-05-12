function useCartPaths(categoryPaths, cartCachePodFilePath)
  local cache = useState(function()
    if (fstat(cartCachePodFilePath)) then
      local cache = fetch(cartCachePodFilePath)
      -- TODO: Check against cache schema. Refresh if invalid.
      -- TODO: Refresh if stale.
      return cache
    end
    return nil
  end)

  if cache then
    -- TODO: At some point we should implement refresh functionality,
    -- TODO: and this early return will become problematic, because
    -- TODO: not returning here will cause hooks call count to change.
    assert(type(cache) == "table", "cache should be a table, got " .. type(cache))
    -- TODO: Check against cache schema. Refresh if invalid.
    return cache
  end

  local categoryDirs = useDirs(categoryPaths)
  --printh("[useCartPaths] Count categoryDirs: " .. #categoryDirs)
  --printh("[useCartPaths] categoryDirs: " .. describe(categoryDirs))

  local categoryDirsLoaded = useMemo(function()
    --printh("[useCartPaths] categoryDirs changed!")
    return objectEvery(categoryDirs, function(categoryDir)
      return categoryDir.loading == false
    end)
  end, deps(categoryDirs))

  local categoryPagePaths = useMemo(function()
    --printh("[useCartPaths] categoryDirsLoaded changed!")
    --printh("[useCartPaths] categoryDirsLoaded = " .. tostr(categoryDirsLoaded))
    local categoryPagePaths = {}
    for categoryPath in all(categoryPaths) do
      categoryPagePaths[categoryPath] = {}
    end

    if not categoryDirsLoaded then
      return categoryPagePaths
    end

    for categoryPath in all(categoryPaths) do
      local categoryDir = categoryDirs[categoryPath]
      for categoryPageName in all(categoryDir.result) do
        local pagePath = categoryPath .. "/" .. categoryPageName
        add(categoryPagePaths[categoryPath], pagePath)
      end
    end
    return categoryPagePaths
  end, deps(categoryDirsLoaded))

  -- TODO: Wrap categoryPageDirs in useMemo? Why is this not done atm?
  local categoryPageDirs = {}
  local categoryPageDirsDep = {}
  for categoryPath in all(categoryPaths) do
    local pagePaths = categoryPagePaths[categoryPath]
    categoryPageDirs[categoryPath] = useDirs(pagePaths)
    add(categoryPageDirsDep, categoryPageDirs[categoryPath])
    categoryPageDirsDep.n = (categoryPageDirsDep.n or 0) + 1
  end

  --printh("[useCartPaths] #categoryPageDirsDep = " .. #categoryPageDirsDep)
  local pageDirsLoaded = useMemo(function()
    --printh("[useCartPaths] categoryPageDirsDep changed!")
    --printh("[useCartPaths] categoryPageDirsDep = " .. describe(categoryPageDirsDep))
    if not categoryDirsLoaded then return false end
    return objectEvery(categoryPaths, function(categoryPath)
      local pageDirs = categoryPageDirs[categoryPath]
      return objectEvery(pageDirs, function(pageDir)
        return pageDir.loading == false
      end)
    end)
  end, categoryPageDirsDep) -- TODO: `categoryPageDirsDep` is an array and is not wrapped in {} on purpose. But is this a safe deps array in edge cases too? That is, is it impossible to for its length to change.

  -- TODO: Add component tree logging to react to let us see what dependency array changes length between renders.
  -- TODO: Wait, maybe some dep array gets a nil value, changing its length?

  local allCartPaths = useMemo(function()
    --printh("[useCartPaths] pageDirsLoaded changed!")
    --printh("[useCartPaths] pageDirsLoaded = " .. tostr(pageDirsLoaded))

    ---@type table<string, string[]>
    local allCartPaths = {}
    for categoryPath in all(categoryPaths) do
      allCartPaths[categoryPath] = {}
    end

    if not pageDirsLoaded then
      return allCartPaths
    end

    for categoryPath in all(categoryPaths) do
      local pagePaths = categoryPagePaths[categoryPath]
      for pagePath in all(pagePaths) do
        local pageDir = categoryPageDirs[categoryPath][pagePath]
        for cartFile in all(pageDir.result) do
          local cartPath = pagePath .. "/" .. cartFile
          add(allCartPaths[categoryPath], cartPath)
        end
      end
    end

    -- TODO: Consider mapping all cart paths from `bbs://category/page/cart.p64` to `bbs://cart.p64`, so new updates categories can't invalidate a cart url.
    -- TODO: - Or maybe this is bad, as we will lose the opportunity to sort per category then. Users can just map to `bbs://cart.p64` themselves.
    -- TODO: - Map to local cart cache folder if we end up supporting that? Will also lose the opportunity to sort per category.
    -- TODO: - Maybe we should export both (`bbs://category/page/cart.p64` or `/ram/explore-cache/carts/cart.p64`) AND `bbs://cart.p64`?

    --printh("[useCartPaths] allCartPaths = " .. describe(allCartPaths))

    store(cartCachePodFilePath, allCartPaths)

    -- TODO: Return {"loading", loaded, total} instead of {category1:{},category2={},category3={}} while pending?
    return allCartPaths
  end, deps(pageDirsLoaded))

  return allCartPaths
end
