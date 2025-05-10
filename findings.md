# Picotron findings

Here I try to document hidden and undocumented features, as well as differences to Pico-8.

## Command line arguments

See [`cli.md`](drive/projects/cli/cli.md).

## Builtins (`_ENV`)

- Many builtins are not documented in the official Picotron manual.
  - These include: `_VERSION`, `kernal_path`, `kpath`, `cocreate`, `collectgarbage`, `costatus`, `error`, `getmetatable`, `ipairs`, `next`, `norm`, `pack`, `pcall`, `pid`, `rawequal`, `rawget`, `rawlen`, `rawset`, `select`, `setmetatable`, `sgn`, `tokenoid`, `tonum`, `tonumber`, `tostring`, `unpack`, `warn`, `yield`, `USERDATA`, `_G`, `coroutine`, `debug`, `math`, `string`, `table`, `utf8`

Find our builtins documentation effort in ahai64's [`ahai64/picotron` repo](https://github.com/ahai64/picotron).

For a direct link to the typings visit the [`library` directory](https://github.com/ahai64/picotron/tree/main/library).

Also see the [overview of missing types](https://github.com/ahai64/picotron/issues/5).

## `stat()`

See [`stats.md`](drive/projects/stat/stats.md).

## `_signal()`

See [`signal.md`](drive/projects/signal/signal.md)

## Operators, shorthand assignment operators, and metamethods

### Official Picotron Shorthand documentation

The [official docs](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Picotron_Shorthand) includes:

- [Short `if`/`while` statements](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Shorthand_If_)

  > `if .. then .. end` statements, and `while .. then .. end` can be written on a single line:
  > `if (not b) i=1 j=2`
  > Is equivalent to:
  > `if not b then i=1 j=2 end`
  > Note that brackets around the short-hand condition are required, unlike the expanded version.

- [Shorthand assignment operators](https://www.lexaloffle.com/dl/docs/picotron_manual.html#Shorthand_Assignment_Operators)

  > Shorthand assignment operators can also be used if the whole statement is on one line. They can be constructed by appending a '=' to any binary operator, including arithmetic (+=, -= ..), bitwise (&=, |= ..) or the string concatenation operator (..=)
  > a += 2 -- equivalent to: a = a + 2

- [`!=` operator](https://www.lexaloffle.com/dl/docs/picotron_manual.html#!=operator:~:text=%E2%96%A0-,!%3D%20operator,-Not%20shorthand%2C%20but)
  > Not shorthand, but Picotron also accepts `!=` instead of `~=` for "not equal to"
  >
  > ```
  > print(1 != 2) -- true
  > print("foo" == "foo") -- true (string are interned)
  > ```

### All know operators

This section covers all known operators in Picotron.

In the texts below, the term "shorthand" is itself short for "shorthand assignment operator", and are non-standard operators implemented by Picotron.

Most of this documentation is also covered in the [3.4 Expressions](https://www.lua.org/manual/5.4/manual.html#3.4) and [Metatables and Metamethods](https://www.lua.org/manual/5.4/manual.html#2.4) sections of the Lua 5.4 manual.

#### Arithmetic operators

[3.4.1 – Arithmetic Operators](https://www.lua.org/manual/5.4/manual.html#3.4.1)

##### Binary arithmetic operators

| Name           | Operator    | Shorthand | Metamethod |
| -------------- | ----------- | --------- | ---------- |
| Addition       | `+`         | `+=`      | `__add`    |
| Subtraction    | `-`         | `-=`      | `__sub`    |
| Multiplication | `*`         | `*=`      | `__mul`    |
| Division       | `/`         | `/=`      | `__div`    |
| Floor division | `//` or `\` | `\=`      | `__idiv`   |
| Exponentiation | `^`         | `^=`      | `__pow`    |
| Modulus        | `%`         | `%=`      | `__mod`    |

Note: Together with shorthands, operator `\` is non-standard.

##### Unary arithmetic operators

| Name  | Operator | Metamethod |
| ----- | -------- | ---------- |
| Minus | `-`      | `__unm`    |

#### Bitwise operators

[3.4.2 – Bitwise Operators](https://www.lua.org/manual/5.4/manual.html#3.4.2)

##### Binary bitwise operators

| Name        | Operator    | Shorthand | Metamethod |
| ----------- | ----------- | --------- | ---------- |
| And         | `&`         | `&=`      | `__band`   |
| Or          | `\|`        | `\|=`     | `__bor`    |
| Xor         | `~` or `^^` | `^^=`     | `__bxor`   |
| Right shift | `>>`        | `>>=`     | `__shr`    |
| Left shift  | `<<`        | `<<=`     | `__shl`    |

Note:

- Together with shorthands, `^^` is non-standard.
- Picotron uses `^^=` instead of `~=` for the xor shorthand assignment operator, as `~=` would overlap with the "not equal" relational operator.
- Picotron does not support the following Pico-8 bitwise operators:
  - `>>>`: Short for `LSHR(X, N)`, logical right shift (zeros comes in from the left)
  - `<<>`: Short for `ROTL(X, N)`, rotate all bits in x left by n places
  - `>><`: Short for `ROTR(X, N)`, rotate all bits in x right by n places

##### Unary bitwise operators

| Name | Operator | Metamethod |
| ---- | -------- | ---------- |
| Not  | `~`      | `__bnot`   |

#### Relational operators

[3.4.4 – Relational Operators](https://www.lua.org/manual/5.4/manual.html#3.4.4)

| Name             | Operator     | Metamethod                   |
| ---------------- | ------------ | ---------------------------- |
| Less than        | `<`          | `__lt`                       |
| Greater than     | `>`          | ? - Not listed in lua manual |
| Less or equal    | `<=`         | `__le`                       |
| Greater or equal | `>=`         | ? - Not listed in lua manual |
| Not equal        | `~=` or `!=` | ? - not listed in lua manual |
| Equal            | `==`         | `__eq`                       |

Note: Operator `!=` is non-standard.

#### Logical operators

[3.4.5 – Logical Operators](https://www.lua.org/manual/5.4/manual.html#3.4.5)

| Name | Operator |
| ---- | -------- |
| And  | `and`    |
| Or   | `or`     |
| Not  | `not`    |

#### String concatenation operator

[3.4.6 – Concatenation](https://www.lua.org/manual/5.4/manual.html#3.4.6)

| Name                 | Operator | Shorthand | Metamethod |
| -------------------- | -------- | --------- | ---------- |
| String concatenation | `..`     | `..=`     | `__concat` |

Note: Shorthand `..=` is non-standard.

#### Length operator

[3.4.7 – The Length Operator](https://www.lua.org/manual/5.4/manual.html#3.4.7)

| Name   | Operator | Metamethod |
| ------ | -------- | ---------- |
| Length | `#`      | `__len`    |

#### Miscellaneous unary Picotron operators

Picotron has a couple of additional unary operators that are syntactic sugar to access frequently used Picotron-functions.

| Name        | Operator | Metamethod | Function equivalent |
| ----------- | -------- | ---------- | ------------------- |
| Print       | `?`      | n/a        | `print()`           |
| 64-bit peek | `*`      | n/a        | `peek8()`           |

Great example of `?` and `*` by [`abledbody` on Discord](https://discord.com/channels/1068899948592107540/1068901222947504199/1369198990322700318):

```
> ?string.format("%016X", *0x5000)
001D2B5300000000
```

Thanks go to `abledbody` for mentioning these operators were missing, and providing the example.

### Other metamethods

[2.4 – Metatables and Metamethods](https://www.lua.org/manual/5.4/manual.html#2.4)

Metamethods not mentioned in the operator sections above are listed below here:

- `__index`: The indexing access operation `table[key]`.
- `__newindex`: The indexing assignment `table[key] = value`.
- `__call`: The call operation `func(args)`.

## Miscellaneous findings

- Correct interface for `window()` is `window(width,height,attribs)`
- `window()` supports `x` and `y` to set position, and `dx` and `dy` to move the window by an offset.
- `_update` runs at 60 fps. `_update60` is not a thing in Picotron.
- `soundsdotzip`'s [message](https://discord.com/channels/1068899948592107540/1068899949670056038/1357357611602805030) mentioned `store("screenshot.png",get_display())` to save a screenshot.
- `_maxine_`'s [message](https://discord.com/channels/1068899948592107540/1218583323459453029/1357377785047552341) mentioned `store("/desktop/trash.loc", {location="/ram/compost"})`
  1. `.loc` files are shortcuts, and you can make your own.
  2. `/ram/compost` is the location used by `/system/apps/filenav.p64`'s `delete_selected_files()` function.
- No `//` comment syntax as in Pico-8. Only `--` comments.
  - In Lua 5.4, and Picotron, `//` is the floor division operator.
- Binary notation, `0b010101`, is supported.
- `kutuptilkisi`'s [message](https://discord.com/channels/1068899948592107540/1358151110917099785/1358858160412037414) taught me you can override the `/system` folder permanently.

## Data dumps

### Builtins - `_ENV`

See [`builtins.txt`](drive/projects/builtins/builtins.txt) for full list of all userland builtins.

Generated by [`builtins.lua`](drive/projects/builtins/builtins.lua).

#### Non-jettisoned Builtins

Using [head-remove-jettison.lua](drive/projects/patcher/head-remove-jettison.lua) we can remove the `jettison.lua` include from `/system/lib/head.lua` and get access to the builtins otherwise only available to system apps.

See [`builtins-jailbroken.txt`](drive/projects/builtins/builtins-jailbroken.txt) for the full list of all userland and system builtins.

Generated by [`builtins.lua`](drive/projects/builtins/builtins.lua) after running [`head-remove-jettison.lua`](drive/projects/patcher/head-remove-jettison.lua).

### Environment - `env()`

See [`env.txt`](drive/dumps/env.txt) for sample object returned by `env()`. Generated by [`env.lua`](drive/projects/env/env.lua) as part of [`dump.lua`](drive/projects/dump/dump.lua).

### Ram - `/ram`

See [`/ram`](drive/dumps/ram) folder for a dump of all files in Picotron's `/ram` folder. Generated by [`dump.lua`](drive/projects/dump/dump.lua).

### System - `/system`

See [`/system`](drive/dumps/system) folder for a dump of all files in Picotron's `/system` folder. Generated by [`dump.lua`](drive/projects/dump/dump.lua).

## Feedback

### ([Reported](https://www.lexaloffle.com/bbs/?pid=164952#p)) `print()` or `_update()` doesn't run in `.lua` file run from terminal

The following script runs well when hitting `CTRL+R` in the editor.

But it shows no logs in the Picotron terminal, or host terminal, when run from the Picotron terminal.

```lua
function _update()
  print("update")
  printh("update")
end
```

### ([Reported](https://www.lexaloffle.com/bbs/?pid=164952#p)) Present working directory

Contrary to expectation, `pwd()` points to script location, while `env().path` points to the directory from which the script was run.

However, `/system/util/pwd.lua` interprets present working directory to mean the directory from which the script was run, and uses `env().path` to determine it.

`/ram/system/processes.pod` also interprets present working directory to mean the directory from which the script was run, and uses the value equivalent to `env().path` for the `pwd` property.

### ([Reported](https://www.lexaloffle.com/bbs/?pid=164952#p)) `mkdir()`

Current behavior:

- On success, mkdir() returns nil.
- On failure, mkdir() returns "mkdir failed".

Expected behavior:

On failure, mkdir() throws an error?

Or mkdir() returns `success, error`, where `success` is a boolean and `error` is an error message.

I've only tried mkdir() failing when trying to create a directory in a directory that doesn't exist. A specific error message for that scenario would be great.

A possible fix could also be to make mkdir() recursive by default.
