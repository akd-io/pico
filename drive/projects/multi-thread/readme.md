- `send-message-cpu-usage.lua` showed us that `send_message` is pretty expensive.
  - Consider seeing if it's possible to communicate in diffs instead of full messages.
  - Consider if it's worth trying to spawn 50 borderless windows in exact locations to make a large canvas.
    - Could communicate over the file system, with 50 files, one for each process/window.
      - If trying to replicate [Zep's particle cart](https://www.lexaloffle.com/bbs/?tid=144356),
        consider if it's possible to structure the files and windows like a KD-tree to ensure an equal amount of particles per file/process.
