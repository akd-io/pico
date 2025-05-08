local e = env()
local url = e.argv[1]
send_message(e.parent_pid, {
  event = "fetch_result",
  packedFetchResult = pack(fetch(url))
})
