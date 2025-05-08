--[[pod_format="raw",created="2025-04-14 14:02:50",modified="2025-04-14 14:05:08",revision=2]]
function mkdirr(path)
  local fullPath = fullpath(path)
  if fstat(fullPath) then
    return
  end

  local fullPathWithoutLeadingSlash = fullPath:sub(2)
  local parts = split(fullPathWithoutLeadingSlash, "/")
  local currentPath = ""
  for part in all(parts) do
    currentPath = currentPath .. "/" .. part
    if not fstat(currentPath) then
      mkdir(currentPath)
    end
  end
end
