--[[
  TODOs:
  - Terminal
    - waits for last command to finish before writing new ">" prompt.
    - intelligent scroll position.
    - writing `cd /projects/` and then pressing tab doesn't append another `/` but instead shows completion options as `cd /` + tab does. Tab should just always try to auto-complete, even at `cd ` with no chars written, and print ls result when it's unclear what it should autocomplete to.
      - How hard is it to make a plugin system for command line tools to add custom completions to the terminal?
        - Maybe learn more here: https://www.reddit.com/r/commandline/s/H1H08fHvbD
    - appearance settings.
]]
