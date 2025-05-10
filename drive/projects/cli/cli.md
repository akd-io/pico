# Picotron CLI Documentation

This file attempts to document all CLI arguments, enriching the official documentation with its hidden features.

## Picotron CLI arguments:

- `picotron`
  - Run Picotron normally.
- `picotron -x <path/to/my/script.lua>`
  - Added in `0.1.1`.
  - Run the specified file in headless mode.
  - The path is relative to your host OS's current working directory.
  - Your code will be copied to and run from `/ram/host_argv.lua`.
  - `pwd()` of a headless script returns `/ram`.
  - `env()` of a headless script returns:
    ```
    {
      "parent_pid" = 1,
      "argv" = {
        0 = "/ram/host_argv.lua",
      },
      "fileview" = [],
    }
    ```
  - We still don't know how to pass arguments to headless scripts.
  - Found with the help of `_maxine_` on Discord.
  - Later found to have been under `0.1.1` in the [changelog](https://www.lexaloffle.com/dl/docs/picotron_changelog.txt).
  - [Changelog](https://www.lexaloffle.com/dl/docs/picotron_changelog.txt):
    - `0.1.1`:
      - `Added: headless script execution: picotron -x foo.lua (experimental! foo.lua must be inside picotron's drive)`
- `picotron -home <path/to/my/home>`
  - Added in `0.1.1`.
  - Specify a home folder where `config.txt` and the default drive is stored.
  - The path is relative to your host OS's current working directory.
  - [Changelog](https://www.lexaloffle.com/dl/docs/picotron_changelog.txt):
    - `0.1.1`:
      - `Added: picotron -home foo // to specify a home folder where config.txt / default drive is stored`
    - `0.1.1c`:
      - `Fixed: "picotron -home foo" host crashes when foo doesn't exist`
- `picotron -gif_len n`
  - Not tested yet.
  - Presumably the length of recorded gifs.
  - Unit of `n` is unknown.
  - Found by `_maxine_` on Discord.
  - Not mentioned in the [Changelog](https://www.lexaloffle.com/dl/docs/picotron_changelog.txt).
  - It is currently unknown, when this argument was added.
    - TODO: Analyze this using `strings` on the binaries in [`/versions/out/`](/versions/out/).
- `picotron -use_system_rom`
  - Functionality currently unknown.
  - Found by `_maxine_` on Discord.
  - Not mentioned in the [Changelog](https://www.lexaloffle.com/dl/docs/picotron_changelog.txt).
  - It is currently unknown, when this argument was added.
    - TODO: Analyze this using `strings` on the binaries in [`/versions/out/`](/versions/out/).

## Unimplemented CLI arguments

These CLI arguments were suspected to work, as Pico-8 supports them, but were tested without success:

- `-width n`
  - `-width 100` does not change the window width
  - `-width 1000` does not change the window width
- `-height n`
  - `-height 100` does not change the window height
  - `-height 1000` does not change the window height
- `-windowed n`
  - No difference observed between `-windowed 0` and `-windowed 1`
- `-volume n`
  - Boot sound still plays at `-volume 0`
- `-run <path>`
  - Not tested with `.p64`.
  - `.lua` files don't seem to work. Boots to desktop as normal
- `-p`
  - Not tested with `.p64`.
  - Doesn't seem to work with `-x`
    - These all yield a normal `env()`:
      - `picotron -x projects/env/env.lua -p test`
      - `picotron -p test -x projects/env/env.lua`
      - Even `picotron -x projects/env/env.lua test`, without `-p`

All Pico-8 cli args for reference:

```
pico8 [switches] [filename.p8]

-width n                set the window width
-height n               set the window height
-windowed n             set windowed mode off (0) or on (1)
-volume n               set audio volume 0..256
-joystick n             joystick controls starts at player n (0..7)
-pixel_perfect n        1 for unfiltered screen stretching at integer scales (on by default)
-preblit_scale n        scale the display by n before blitting to screen (useful with -pixel_perfect 0)
-draw_rect x,y,w,h      absolute window coordinates and size to draw pico-8's screen
-run filename           load and run a cartridge
-x filename             execute a PICO-8 cart headless and then quit (experimental!)
-export param_str       run EXPORT command in headless mode and exit (see notes under export)
-p param_str            pass a parameter string to the specified cartridge
-splore                 boot in splore mode
-home path              set the path to store config.txt and other user data files
-root_path path         set the path to store cartridge files
-desktop path           set a location for screenshots and gifs to be saved
-screenshot_scale n     scale of screenshots.  default: 3 (368x368 pixels)
-gif_scale n            scale of gif captures. default: 2 (256x256 pixels)
-gif_len n              set the maximum gif length in seconds (1..120)
-gui_theme n            use 1 for a higher contrast editor colour scheme
-timeout n              how many seconds to wait before downloads timeout (default: 30)
-software_blit n        use software blitting mode off (0) or on (1)
-foreground_sleep_ms n  how many milliseconds to sleep between frames.
-background_sleep_ms n  how many milliseconds to sleep between frames when running in background
-accept_future n        1 to allow loading cartridges made with future versions of PICO-8
-global_api n           1 to leave api functions in global scope (useful for debugging)
```
