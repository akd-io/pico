include("/lib/react.lua")
include("/hooks/useQuery.lua")

window({
  width = 240,
  height = 70,
})

local f = 0
function App()
  f += 1

  local state = useState({
    url = "http://localhost:3000/hello-world"
  })

  if (keyp("x")) then
    state.url =
        state.url == "http://localhost:3000/hello-world"
        and "http://localhost:3000/hello-world2"
        or "http://localhost:3000/hello-world"
  end

  local query = useQuery(state.url)

  cls()
  print("frame: " .. f)
  print("url: " .. tostr(state.url))
  print("result: " .. tostr(query.result))
  print("meta: " .. tostr(query.meta))
  print("error: " .. tostr(query.error))
  print("loading: " .. tostr(query.loading))
end

function _draw()
  renderRoot(App)
end
