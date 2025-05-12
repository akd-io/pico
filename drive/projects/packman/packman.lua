--[[
  Packman
  - Package manager
  - GUI and CLI to manage packages.
  - Also allows managing apps, clis, daemons, etc.
    - Toggle sandbox.
    - Toggle jail break.
    - Toggle individual permission.
    - Toggle apps/etc. (destination folder created or deleted)
  - Package carts always saved in /packman/packages
  - Package.pod specifies apps, daemons, libs, cli commands and patches to be installed in their respective folders:
    - app: /apps (optionally runs on boot)
    - daemon: /daemons (optionally runs on boot)
    - cli: /appdata/system/utils
      - aliases too?
    - lib: /lib
    - patch: /patches
    - wallpapers: ?
    - screen savers: ?
    - TODO: Shouldn't there just be a way to specify fullpath destinations for cart-path files?
  - On install, ask users if they want to add a desktop shortcut. (If these run carts instead of opening them in Filenav)
  - package.pod:
    - Name
    - Author
    - Date
    - Version
    - Type (app/daemon/cli/lib/patch)
    - Dependencies
      - auto-installed deps will allow users to make packs of their favorite packages.
    - Unsandbox (Required/Optional/Unnecessary)
    - Permissions
      - read/write filesystem whitelist?
      - remote fetch?
      - Bbs fetch?
      - List of C-function app wants access to?
        - Required/Optional/Unnecessary for each permission here too?
    - IMPORTANT: Each app/cli/daemon/... can specify these properties. Ones not set are inherited from the root package config.
    - Does BBS allow carts in carts??
]]

--[[
  Package Manager app.
  TODOs:
  - Lists apps from BBS.
    - bbs:// protocol supports "new" and ??
    - bbs:// seems slow. If true, cache metadata and maybe small cart icons.
    - Check if `cp` command supports bbs:// protocol and as possible to download and unzip carts to get their metadata/icon without having to `load()` the cart as that might override other work.
    - Maybe ship the app with precompiled metadata not available through bbs:// protocol.
      - list of most liked carts on bbs. (Cart ID + icons)
  - Lists installed apps.
  - Lets you install, uninstall, update.
  - Lets you switch sandbox mode if possible.
  - Lets you load listed carts both sandboxed (default) and unsandboxed (load -u).
  - Maybe libraries can be saves to a special folder like `node_modules`.
    - As package manager knows what modules are installed, we could
      auto-generate types for a special `require` function.

  -- We can auto-generate types for packages as such:
  ---@param packageName "package1" | "package2"
  function require(packageName) end

  -- Developer experience:
  require("package1") -- OK - CTRL+Space even auto-completes.
  require("package2") -- OK
  require("package3") -- param-type-mismatch: Cannot assign `string` to parameter `"package1"|"package2"`.

  -- We can also list packages one per line like this:
  ---@param packageName "package1"
  ---          | "package2"
  ---          | "package3"
  function anotherRequire(packageName) end

  -- Developer experience:
  anotherRequire("package1") -- OK
  anotherRequire("package2") -- OK
  anotherRequire("package3") -- OK
  anotherRequire("package4") -- param-type-mismatch: Cannot assign `string` to parameter `"package1"|"package2"|"package3"`.
]]
include("/lib/describe.lua")
include("/lib/utils.lua")
include("/projects/react/react.lua")

include("app.lua")

local min_width = 200
local min_height = 100
width, height = 300, 200

window({
  width = width,
  height = height,
  min_width = min_width,
  min_height = min_height,
  resizeable = true,
  moveable = true,
  has_frame = true,
  title = "Packman"
})
on_event("resize", function(msg)
  width = msg.width
  height = msg.height
end)

function _draw()
  -- TODO: Remove
  -- If CTRL+R is pressed, restart process
  if (key "alt" and keyp "r") then
    send_message(2, { event = "restart_process", proc_id = pid() })
  end
  renderRoot(App)
end
