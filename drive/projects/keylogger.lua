-- window({
--   width = 60,
--   height = 10,
--   title = tostr(pid())
-- })

function _update()
  --[[ readtext() requires window focus
    while peektext() do
      c = readtext()
      printh("read text: " .. c)
    end
  ]]

  --[[ key() requires window focus
    if key("k") then
      printh("k")
    end
  ]]
end
