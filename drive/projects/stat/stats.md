# `stat()` Documentation

This file attempts to document all `stat()` codes, enriching the official documentation with its hidden features.

## TODO

- Try logging stats above 0..1000.
- Try logging state below 0.
- Try logging several return values from stat(), as some stats are known to return multiple values.
  - Try logging `#pack(stat(i))`, to get number of returned values.

## Table of Contents

- [Results](#results)
- [Official `stat()` documentation](#official-stat-documentation)
  - [`stat()` section](#stat-section)
  - [HTML Export Size Limit section](#html-export-size-limit-section)
  - [Mixer state section](#mixer-state-section)
- [Undocumented stats gathered from `stat.lua` script](#undocumented-stats-gathered-from-statlua-script)
- [Source search](#source-search)
  - [All unique `stat()` calls](#all-unique-stat-calls)
  - [Undocumented unique `stat()` calls](#undocumented-unique-stat-calls)
  - [Code searches](#code-searches)
    - [301 Search](#301-search)
    - [302 Search](#302-search)
    - [307 Search](#307-search)
    - [315 Search](#315-search)
    - [316 Search](#316-search)
    - [317 Search](#317-search)
    - [318 Search](#318-search)
    - [320 Search](#320-search)
    - [321 Search](#321-search)
    - [330 Search](#330-search)
    - [987 Search](#987-search)
    - [988 Search](#988-search)

## Results

- `stat(0)` memory usage (triggers a garbage collection)
- `stat(1)` cpu usage (try to stay under ~0.9 to maintain 60fps)
  - TODO: Incorporate Maxine's [message on 1](https://discord.com/channels/1068899948592107540/1358151110917099785/1366241940471025704).
- `stat(2)` reserved
- `stat(3)` raw mememory usage (no GC, so value jumps around)
  - TODO: Incorporate Maxine's [message on 3](https://discord.com/channels/1068899948592107540/1358151110917099785/1366130509784285334).
- `stat(5)` runtime, system version
- `stat(7)` operating fps (60,30,20,15)
- `stat(86)` epoch time
- `stat(87)` timezone delta in seconds
- `stat(101)` web: player cart id (when playing a bbs cart; nil otherwise)
- `stat(150)` web: window.location.href
- `stat(151)` web: stat(150) up to the end of the window.location.pathname
- `stat(152)` web: window.location.host
- `stat(153)` web: window.location.hash
- `stat(301)` (undocumented)
  - Seems to indicate CPU usage, across processes, since some event.
  - Maybe since the `flip()` in `boot.lua`'s main loop?
  - TODO: Incorporate Maxine's [message on 301](https://discord.com/channels/1068899948592107540/1358151110917099785/1366241940471025704).
  - See [code references](#301-search)
- `stat(302, keycode)` (undocumented)
  - Returns a human-readable name for the given keycode.
  - Seems to surface SDL's [GetKeyName](https://wiki.libsdl.org/SDL2/SDL_GetKeyName) function.
  - Thanks to `@_maxine_`'s [message](https://discord.com/channels/1068899948592107540/1358151110917099785/1366167587209089045) on Discord.
  - See [code references](#302-search)
- `stat(307)` (undocumented)
  - Returns `1.0` if filepath starts with `/system/`.
  - Thanks to `@_maxine_`'s [message](https://discord.com/channels/1068899948592107540/1358151110917099785/1366825534167847013) on Discord.
  - Used in `head.lua` to determine if a program is a "trusted system app".
  - In my testing, `stat(307)` also returns `1.0` in user-made scripts located in `/system/`.
  - The code in `head.lua` specifically checks `stat(307) & 0x1`, which might indicate `stat(307)` was a bitfield in past versions, and `0b1` was code for "trusted system apps".
    - TODO: Find out if `stat(307)` was a bitfield in past versions.
  - See [code references](#307-search)
- `stat(308)` (undocumented)
  - Observed value `1973.0` and `2334.0` in `stat.lua` output.
  - No code references.
- `stat(309)` (undocumented)
  - Observed value `60531740.0` and `63912031.0` in `stat.lua` output.
  - No code references.
- `stat(310)` (undocumented)
  - Observed value `551.0`, `565.0` and `3689.0` in `stat.lua` output.
  - Same [decompiled code](https://discord.com/channels/1068899948592107540/1358151110917099785/1368473041113452614) as for `stat(311)` below, but passing `2` to `pdisk_count_slots_by_kind()` instead of `0`.
  - No code references.
- `stat(311)` (undocumented)
  - Functionality unknown.
  - Observed value `15833.0`, `15819.0` and `12342.0` in `stat.lua` output.
  - [Decompiled code](https://discord.com/channels/1068899948592107540/1358151110917099785/1368470004063932467) by `@_maxine_` reads:
    ```
      if (stat_type != UNDOCUMENTED_311) goto LAB_00460c7f;
      tmp_int0 = pdisk_count_slots_by_kind(0);
      result_num = (lua_Number)tmp_int0;
    ```
  - No code references.
- `stat(312)` (undocumented)
  - Observed value `4096.0` in `stat.lua` output.
  - No code references.
- `stat(313)` (undocumented)
  - Observed value `626688.0` in `stat.lua` output.
  - TODO: Incorporate Maxine's [message on 313](https://discord.com/channels/1068899948592107540/1358151110917099785/1366496145844731996).
  - No code references.
- `stat(314)` (undocumented)
  - Returns the value of pi, the mathematical constant.
  - Observed value `3.1415926535898` in `stat.lua` output.
  - No code references.
- `stat(315)` (undocumented)
  - Presence of the `-x` CLI argument when running headless using `picotron -x <path/to/my/script.lua>`.
  - Found with the help of `@_maxine_` on Discord.
  - See [code references](#315-search)
- `stat(316)` (undocumented)
  - The path specified when running headless using `picotron -x <path/to/my/script.lua>`.
  - Found with the help of `@_maxine_` on Discord.
  - See [code references](#316-search)
- `stat(317)` (undocumented)
  - Returns:
    - `3.0` when running as a `.bin` or `.html` export.
    - `1.0` when running on the BBS web player.
    - `0.0` otherwise.
  - See [`test-317.lua`](./test-317/test-317.lua) for more details.
  - Found with the help of `@_maxine_` on Discord.
  - See [code references](#317-search)
- `stat(318)` (undocumented)
  - Returns:
    - `1.0` when running as a `.html` export or in the BBS web player.
    - `0.0` otherwise.
  - See [`test-317.lua`](./test-317/test-317.lua) for more details.
  - See [code references](#318-search)
- `stat(320)` (undocumented)
  - Returns `1.0` during video capture, and `0.0` otherwise.
  - See [code references](#320-search)
- `stat(321)` (undocumented)
  - Returns length of video capture in frames while recording, and `0.0` otherwise.
  - See [code references](#321-search)
- `stat(322)` (undocumented)
  - Returns `1.0` during audio capture, and `0.0` otherwise.
  - Audio capture can be started and stopped with `CTRL+0`.
  - Audio files are saved in an unknown format with a `.raw` extension however.
  - Found by `@_maxine_` on Discord [here](https://discord.com/channels/1068899948592107540/1358151110917099785/1366298848590434376).
  - See [code references](#321-search)
  - See also `_signal(16)` in the [`_signal()` Documentation](../signal/signal.md#results)
- `stat(330)` (undocumented)
  - Returns `1.0` when Picotron's battery saver is active, and `0.0` otherwise.
  - It does not simply reflect the `battery_saver` property of the system settings file at `appdata/system/settings.pod`. Rather, it reflects whether the actual functionality of the battery saver feature is currently active.
  - Our current understanding is that battery saver will cap calls to `_update()` and `_draw()` to 30 times per second, when there has been no user input for 500 milliseconds.
  - Both key presses, mouse button presses, mouse movement, and moving the Picotron window, seems to count as user input, and resets the 500ms timer.
  - See also: [`test-330.lua`](./test-330.lua), or a gif of it [here](https://discord.com/channels/1068899948592107540/1358151110917099785/1368733765290950706).
  - Found with the help of `@_maxine_`'s [message](https://discord.com/channels/1068899948592107540/1358151110917099785/1366547309399249028) on Discord.
  - TODO: Test if battery saver just caps `_update()` and `_draw()` to 30 times per second, or if it halves updates and draws in cases of exceeding the 0.9 CPU usage threshold.
  - See [code references](#330-search)
- `stat(400 + c, 0)` note is held (0 false 1 true)
- `stat(400 + c, 1)` channel instrument
- `stat(400 + c, 2)` channel vol
- `stat(400 + c, 3)` channel pan
- `stat(400 + c, 4)` channel pitch
- `stat(400 + c, 5)` channel bend
- `stat(400 + c, 6)` channel effect
- `stat(400 + c, 7)` channel effect_p
- `stat(400 + c, 8)` channel tick len
- `stat(400 + c, 9)` channel row
- `stat(400 + c, 10)` channel row tick
- `stat(400 + c, 11)` channel sfx tick
- `stat(400 + c, 12)` channel sfx index (-1 if none finished)
- `stat(400 + c, 13)` channel last played sfx index
- `stat(400 + c, 19, addr)` fetch stereo output buffer (returns number of samples)
- `stat(400 + c, 20 + n, addr)` fetch mono output buffer for a node n (0..7)
- `stat(464)` bitfield indicating which channels are playing a track (sfx)
- `stat(465, addr)` copy last mixer stereo output buffer output is written as int16's to addr. returns number of samples written.
- `stat(466)` which pattern is playing (-1 for no music)
- `stat(467)` return the index of the left-most non-looping music channel
- `stat(985)` (undocumented)
  - Observed value `1.0` in `stat.lua` output.
  - No code references.
- `stat(987)` (undocumented)
  - Observed value `201225.0`, `40211391.0`, and `61631102.0` in `stat.lua` output.
  - See [code references](#987-search)
- `stat(988)` (undocumented)
  - Returns `1.0` if both left and right control keys are held down, and `0.0` otherwise.
  - Found by `@kutuptilkisi` on Discord.
  - See [code references](#988-search)

## Official `stat()` documentation

### `stat()` section

From https://www.lexaloffle.com/dl/docs/picotron_manual.html#stat

> Get system status where x is:
>
> ```
>   0  memory usage        // triggers a garbage collection
>   1  cpu usage           // try to stay under ~0.9 to maintain 60fps)
>   2  reserved
>   3  raw mememory usage  // no GC, so value jumps around)
>   5  runtime, system version
>   7  operating fps (60,30,20,15)
>  86  epoch time
>  87  timezone delta in seconds
> 101  web: player cart id (when playing a bbs cart; nil otherwise)
> 150  web: window.location.href
> 151  web: stat(150) up to the end of the window.location.pathname
> 152  web: window.location.host
> 153  web: window.location.hash
> ```

### HTML Export Size Limit section

The HTML Export Size Limit section of the docs mention `stat(151)`, but its purpose it already documented in the `Stat()` section.

Included here for completeness.

From https://www.lexaloffle.com/dl/docs/picotron_manual.html#HTML_Export_Size_Limit

> The html exporter can handle carts that are up to 8MB in .p64.rom format (use "info" command to check). Beyond that size, fetch() can be used to download more data as needed using stat(151) to prepend the host and path the page is being served from: fetch(stat(151).."level2.pod").

### Mixer state section

From https://www.lexaloffle.com/dl/docs/picotron_manual.html#Querying_Mixer_State

> Global mixer state:
>
> ```
> stat(464)         -- bitfield indicating which channels are playing a track (sfx)
> stat(465, addr)   -- copy last mixer stereo output buffer output is written as
>                   -- int16's to addr. returns number of samples written.
> stat(466)         -- which pattern is playing (-1 for no music)
> stat(467)         -- return the index of the left-most non-looping music channel
> ```
>
> Per channel (c) state:
>
> ```
> stat(400 + c,  0) -- note is held (0 false 1 true)
> stat(400 + c,  1) -- channel instrument
> stat(400 + c,  2) -- channel vol
> stat(400 + c,  3) -- channel pan
> stat(400 + c,  4) -- channel pitch
> stat(400 + c,  5) -- channel bend
> stat(400 + c,  6) -- channel effect
> stat(400 + c,  7) -- channel effect_p
> stat(400 + c,  8) -- channel tick len
> stat(400 + c,  9) -- channel row
> stat(400 + c, 10) -- channel row tick
> stat(400 + c, 11) -- channel sfx tick
> stat(400 + c, 12) -- channel sfx index (-1 if none finished)
> stat(400 + c, 13) -- channel last played sfx index
> stat(400 + c, 19,     addr) -- fetch stereo output buffer (returns number of samples)
> stat(400 + c, 20 + n, addr) -- fetch mono output buffer for a node n (0..7)
> ```

## Undocumented stats gathered from `stat.lua` script

The following list contains stats gathered from [stat.lua](stat.lua), with documented stats removed.

```
308 = 1973.0,
309 = 60531740.0,
310 = 551.0,
311 = 15833.0,
312 = 4096.0,
313 = 626688.0,
314 = 3.1415926535898,
985 = 1.0,
987 = 201225.0,
```

`stat.txt` also has 400..415 set to -1.0. It's an expected range to get -1.0 per the [Mixer State](#mixer-state) section above.

But it seems there are 16 instead of the expected 8. Might just be because of stereo.

## Binary Ninja

From [`0.2.0c.bndb`](picotron/versions/bndbs/0.2.0c.bndb):

```
10006cb30    uint64_t _lua54_stat(uint64_t statArgs)

10006cb4b        int32_t arg1 = _p64_intp(statArgs, 1, 0)
10006cb62        int64_t arg2 = _p64_intp(statArgs, 2, 0)
10006cb6f        int32_t arg3
10006cb6f        uint64_t output[0x2]
10006cb6f        arg3, output = _p64_intp(statArgs, 3, 0)
10006cb7b        int32_t num_values_pushed_to_statArgs
10006cb7b
10006cb7b        if (arg1 u<= 7)
10006d286            switch (arg1)
10006cbad                case 0
10006cbad                    // stat(0)
10006cbad                    output = _lua_gc(*(_cproc + 0x158), 2, 0)
10006cbb2                    void* _cproc_1 = _cproc
10006cbd4                    output[0] = float.d(*(_cproc_1 + 0x36158) + *(_cproc_1 + 0x36148)
10006cbd4                        - *(_cproc_1 + 0x36150) + 0x80000)
10006cbd9                    *(_cproc_1 + 0x3616c) = arg2.d
10006cbdf                    goto label_10006cd2c
10006cc50                case 1
10006cc50                    // stat(1)
10006cc50                    output[0] = float.d(_cpu_cycles + *(_cproc + 0x288))
10006cc54                    output[0] = output[0] f/ 279620.0
10006cc5c                    goto label_10006cd2c
10006cb8e                case 2, 4, 6  // stat(2), stat(4), stat(6)
10006cb8e                    goto label_10006cbfb
10006cc7f                case 3
10006cc7f                    _lua_gc(*(_cproc + 0x158), 2, 0)  // stat(3)
10006cc9f                    int32_t r12_3 = _lua_gc(*(_cproc + 0x158), 3, 0) << 0xa
10006ccba                    int32_t rax_12
10006ccba                    rax_12, output = _lua_gc(*(_cproc + 0x158), 4, 0)
10006ccc2                    output[0] = float.d(rax_12 + r12_3)
10006ccc6                    goto label_10006cd2c
10006ccd0                case 5
10006ccd0                    _lua_pushinteger(statArgs, 0x11)  // stat(5)
10006ccdf                    _lua_pushstring(statArgs, "0.2.0c")
10006cce4                    num_values_pushed_to_statArgs = 2
10006ccf9                case 7
10006ccf9                    int32_t rax_15 = *(_cproc + 0x294)  // stat(7)
10006cd01                    int32_t rcx_7 = 0x3c
10006cd01
10006cd06                    if (rax_15 != 0)
10006cd06                        rcx_7 = rax_15
10006cd06
10006cd09                    output[0] = float.d(rcx_7)
10006cd09
10006cd1b                    if (data_1001d3250:8.d != 0)
10006cd1d                        output[0] = output[0] f* 0.5
10006cd1d
10006cd1b                    goto label_10006cd2c
10006cb7b        else if (arg1 != 86)
10006cbfb            label_10006cbfb:
10006cbfb
10006cbff            if (arg1 == 87)  // stat(87)
10006d3ba                output[0] = float.d(*_timezone)
10006d3ba
10006d3c3                if (arg1 != 101)
10006cc1a                    label_10006cc1a:
10006cc1a
10006cc1d                    if (arg1 - 150 u> 3)  // arg1 >= 154
10006d3d6                        uint64_t arg1_minus_301 = zx.q(arg1 - 301)
10006d3e0                        int64_t rax_69
10006d3e0                        int32_t rdi_46
10006d3e0
10006d3e0                        if (arg1_minus_301.d u> 12)
10006d498                            label_10006d498:
10006d498
10006d49f                            if (arg1 != 314)
10006d4ac                                if (arg1 == 315)
10006d4ac                                    goto label_case_315
10006d4ac
10006d4ac                                goto label_10006d4b2
10006d4ac
10006d592                            output = 0x400921fb54442d18
10006d592
10006d5a1                            if (arg1 == 315)  // stat(315)
10006d5ae                                label_case_315:
10006d5ae                                output = zx.o(0)
10006d5b1                                output[0] = float.d(data_1001d87bc)
10006d5b1
10006d5c0                                if (arg1 != 321)
10006d5c0                                    goto label_10006d4bf
10006d5c0
10006d5c0                                goto label_case_321
10006d5c0
10006d4b2                            label_10006d4b2:
10006d4b2
10006d4b9                            if (arg1 == 321)  // stat(321)
10006d5cd                                label_case_321:
10006d5cd
10006d5d1                                if (capture_buffer:8.d == 0)
10006d5f8                                    label_10006d5f8:
10006d5f8                                    output = _mm_xor_pd(output, output)
10006d5fc                                    goto label_10006cd2c
10006d5fc
10006d5d3                                int32_t rax_74 = capture_buffer:0xc.d
10006d5df                                output = zx.o(0)
10006d5e2                                output[0] = float.d(((rax_74 u>> 0x1f) + rax_74) s>> 1)
10006d5e6                                goto label_10006cd2c
10006d5e6
10006d4bf                            label_10006d4bf:
10006d4bf
10006d4c6                            if (arg1 == 320)  // stat(320)
10006d5f6                                if (capture_buffer:8.d == 0)
10006d5f6                                    goto label_10006d5f8
10006d5f6
10006d601                                output = 0x3ff0000000000000
10006d609                                goto label_10006cd2c
10006d609
10006d4d3                            if (arg1 != 316)
10006d4d3                                goto label_10006cd2c
10006d4d3
10006cc2d                            // stat(316)
10006cc2d                            _lua_pushstring(statArgs, &headless_script_path)
10006d46c                            num_values_pushed_to_statArgs = 1
10006d3e0                        else
10006d3f4                            switch (arg1_minus_301)
10006d3fd                                case 0
10006d3fd                                    output = zx.o(0)  // stat(301)
10006d400                                    output[0] = float.d(_get_total_frame_cycles())
10006d404                                    output[0] = output[0] f/ 279620.0
10006d40c                                    goto label_10006cd2c
10006d491                                case 1
10006d491                                    // stat(302)
10006d491                                    _lua_pushstring(statArgs, _os_key_from_scancode())
10006d46c                                    num_values_pushed_to_statArgs = 1
10006d3f4                                case 2, 3, 4, 5
10006d3f4                                    goto label_10006d498
10006d4f4                                case 6
10006d4f4                                    output = zx.o(0)  // stat(307)
10006d4f7                                    output[0] = float.d(*(_cproc + 336))
10006d4ff                                    goto label_10006cd2c
10006d506                                case 7
10006d506                                    // stat(308)
10006d506                                    rax_69 = _get_total_num_buffers()
10006d521                                    label_10006d521:
10006d521                                    uint128_t zmm1_1 = __subpd_xmmpd_mempd(
10006d521                                        __punpckldq_xmmdq_memdq(zx.o(rax_69),
10006d521                                            data_100123740),
10006d521                                        data_100123750)
10006d52d                                    output = _mm_unpackhi_pd(zmm1_1, zmm1_1.q)
10006d531                                    output[0] = output[0] f+ zmm1_1.q
10006d535                                    goto label_10006cd2c
10006d50f                                case 8
10006d50f                                    // stat(309)
10006d50f                                    rax_69 = _get_total_buffer_allocation()
10006d50f                                    goto label_10006d521
10006d53a                                case 9
10006d53a                                    rdi_46 = 2  // stat(310)
10006d548                                    label_10006d548:
10006d548                                    output = zx.o(0)
10006d54b                                    output[0] = float.d(_pdisk_count_slots_by_kind(rdi_46))
10006d54f                                    goto label_10006cd2c
10006d541                                case 10
10006d541                                    rdi_46 = 0  // stat(311)
10006d541                                    goto label_10006d548
10006d566                                case 11
10006d566                                    output = zx.o(0)  // stat(312)
10006d569                                    output[0] = float.d(
10006d569                                        *(_cproc + (sx.q(arg2.d s>> 12) << 2) + 33664))
10006d572                                    goto label_10006cd2c
10006d581                                case 12
10006d581                                    output = zx.o(0)  // stat(313)
10006d584                                    output[0] = float.d(*(_cproc + 0x36158))
10006d58d                                    goto label_10006cd2c
10006cc1d                    else
10006cc23                        // arg1 < 154
10006cc2d                        _lua_pushstring(statArgs, &data_100134ee8)
10006d46c                        num_values_pushed_to_statArgs = 1
10006d3c3                else
10006d3cc                    _lua_pushnil(statArgs)  // stat(101)
10006d46c                    num_values_pushed_to_statArgs = 1
10006cbff            else
10006cc05                output = _mm_xor_pd(output, output)  // arg1 != 87
10006cc05
10006cc0d                if (arg1 != 101)
10006cc0d                    goto label_10006cc1a
10006cc0d
10006d3cc                _lua_pushnil(statArgs)
10006d46c                num_values_pushed_to_statArgs = 1
10006cbe8        else
10006cbec            time_t rax_5
10006cbec            rax_5, output = _time(nullptr)  // stat(86)
10006cbf1            output[0] = float.d(rax_5)
10006cd2c            label_10006cd2c:
10006cd2c
10006cd33            if (arg1 != 322)
10006cd40                if (arg1 == 330)
10006cd40                    goto label_case_330
10006cd40
10006cd40                goto label_skip_330
10006cd40
10006d016            output = zx.o(0)  // stat(322)
10006d019            output[0] = float.d(is_capturing_audio)
10006d019
10006d027            if (arg1 == 330)  // stat(330)
10006d02d                label_case_330:
10006d02d                output = zx.o(0)
10006d030                output[0] = float.d(data_1001d3250:8.d)
10006d030
10006d045                if ((arg1 & 0xfffffff0) == 400)
10006d045                    goto label_case_400_and_401
10006d045
10006d045                goto label_not_case_400_or_401
10006d045
10006cd4c            label_skip_330:
10006cd4c
10006cd51            if ((arg1 & 0xfffffff0) != 400)
10006d04b                label_not_case_400_or_401:
10006d04b
10006d052                if (arg1 == 465)  // stat(465)
10006d0ff                    label_case_465:
10006d0ff                    _audio_op_start(*_cproc, 0)
10006d104                    data_1001d3290.d += 1
10006d125                    uint64_t output_1[0x2] = zx.o(0)
10006d128                    output_1[0] = float.d(_mudo_get_channel_state(0xffffffff, 0xffffffff,
10006d128                        &_audio_dat))
10006d136                    double zmm1_2 = output_1[0] f+ output_1[0]
10006d136
10006d142                    if (not(zmm1_2 f<= _mm_xor_pd(output_1, output_1)[0]))
10006d144                        int32_t rbx = 1
10006d149                        int64_t r13_2 = 0
10006d185                        int64_t zmm0
10006d185
10006d185                        do
10006d16a                            _poke2(arg3 + r13_2.d, sx.d(*(r13_2 + &_audio_dat)))
10006d177                            zmm0 = float.d(rbx)
10006d17b                            r13_2 += 2
10006d17f                            rbx += 1
10006d185                        while (zmm1_2 f> zmm0)
10006d185
10006d189                    _audio_op_end()
10006d18e                    output = 0x3fe0000000000000
10006d196                    output[0] = output[0] f* output_1[0]
10006d19f                    _spend_cpu(int.d(output[0]))
10006d1a4                    output = output_1
10006d1ad                    goto label_10006d1b4
10006cd51            else
10006cd61                label_case_400_and_401:
10006cd61                int64_t* _cproc_3 = _cproc
10006cd65                int64_t rdi_9 = *_cproc_3
10006cd65
10006cd6c                if (rdi_9 != data_1001d31e0:8)
10006d0d0                    output = -0x4010000000000000
10006d0d0
10006d0e6                    if (arg1 != 465)
10006d0e6                        goto label_10006d058
10006d0e6
10006d0e6                    goto label_case_465
10006d0e6
10006cd75                if (arg2.d s> 18)
10006d2a5                    _audio_op_start(rdi_9, 0)
10006d2b1                    data_1001d3288 += 1
10006d2ca                    uint64_t rax_54 =
10006d2ca                        _mudo_get_channel_state(arg1 - 400, arg2.d, &_audio_dat)
10006d2d3                    uint64_t output_2[0x2] = zx.o(0)
10006d2d6                    output_2[0] = float.d(rax_54)
10006d2e2                    uint64_t zmm1_4[0x2] = _audio_op_end()
10006d2e2
10006d2ee                    if (arg2.d != 19)
10006d34d                        label_10006d34d:
10006d34d
10006d350                        if (arg2.d - 20 u<= 7)
10006d35b                            output = output_2
10006d35b
10006d360                            if (rax_54 s> 0)
10006d362                                int32_t rbx_2 = 1
10006d367                                int64_t r12_5 = 0
10006d394                                int64_t i
10006d394
10006d394                                do
10006d379                                    _poke2(arg3 + r12_5.d, sx.d(*(r12_5 + &_audio_dat)))
10006d37e                                    output = output_2
10006d386                                    i = float.d(rbx_2)
10006d38a                                    r12_5 += 2
10006d38e                                    rbx_2 += 1
10006d394                                while (output[0] f> i)
10006d394
10006d360                            goto label_10006d3a1
10006d360
10006d445                        output = output_2
10006d445
10006d451                        if (arg1 == 465)
10006d451                            goto label_case_465
10006d2ee                    else
10006d2f0                        output = output_2  // arg2 == 19
10006d2f9                        uint64_t i_1 = output[0] f+ output[0]
10006d2f9
10006d305                        if (not(i_1 f<= _mm_xor_pd(zmm1_4, zmm1_4)[0]))
10006d30b                            int32_t rbx_1 = 1
10006d310                            int64_t r12_4 = 0
10006d310
10006d344                            do
10006d329                                _poke2(arg3 + r12_4.d, sx.d(*(r12_4 + &_audio_dat)))
10006d333                                output = zx.o(0)
10006d336                                output[0] = float.d(rbx_1)
10006d33a                                r12_4 += 2
10006d33e                                rbx_1 += 1
10006d344                            while (i_1 f> output[0])
10006d344
10006d344                            goto label_10006d34d
10006d344
10006d3a1                        label_10006d3a1:
10006d3a1
10006d3a8                        if (arg1 == 465)
10006d3a8                            goto label_case_465
10006cd75                else
10006cd89                    if (_cproc_3[0x6c21] != _cproc_3[0x4e])
10006cd97                        int64_t i_2 = 0
10006cd9b                        _audio_op_start(rdi_9, 0)
10006cda7                        data_1001d3284 += 1
10006cdad                        void* _cproc_2 = _cproc
10006cdb8                        *(_cproc_2 + 0x36108) = *(_cproc_2 + 0x270)
10006cdbf                        int32_t r13_1 = 0
10006cdbf
10006cfc9                        do
10006cde0                            *(_cproc + i_2 + 0x35908) =
10006cde0                                _mudo_get_channel_state(r13_1, 0, nullptr)
10006cdfa                            *(_cproc + i_2 + 0x3590c) =
10006cdfa                                _mudo_get_channel_state(r13_1, 1, nullptr)
10006ce14                            *(_cproc + i_2 + 0x35910) =
10006ce14                                _mudo_get_channel_state(r13_1, 2, nullptr)
10006ce2e                            *(_cproc + i_2 + 0x35914) =
10006ce2e                                _mudo_get_channel_state(r13_1, 3, nullptr)
10006ce48                            *(_cproc + i_2 + 0x35918) =
10006ce48                                _mudo_get_channel_state(r13_1, 4, nullptr)
10006ce62                            *(_cproc + i_2 + 0x3591c) =
10006ce62                                _mudo_get_channel_state(r13_1, 5, nullptr)
10006ce7c                            *(_cproc + i_2 + 0x35920) =
10006ce7c                                _mudo_get_channel_state(r13_1, 6, nullptr)
10006ce96                            *(_cproc + i_2 + 0x35924) =
10006ce96                                _mudo_get_channel_state(r13_1, 7, nullptr)
10006ceb0                            *(_cproc + i_2 + 0x35928) =
10006ceb0                                _mudo_get_channel_state(r13_1, 8, nullptr)
10006ceca                            *(_cproc + i_2 + 0x3592c) =
10006ceca                                _mudo_get_channel_state(r13_1, 9, nullptr)
10006cee4                            *(_cproc + i_2 + 0x35930) =
10006cee4                                _mudo_get_channel_state(r13_1, 10, nullptr)
10006cefe                            *(_cproc + i_2 + 0x35934) =
10006cefe                                _mudo_get_channel_state(r13_1, 11, nullptr)
10006cf18                            *(_cproc + i_2 + 0x35938) =
10006cf18                                _mudo_get_channel_state(r13_1, 12, nullptr)
10006cf32                            *(_cproc + i_2 + 0x3593c) =
10006cf32                                _mudo_get_channel_state(r13_1, 13, nullptr)
10006cf4c                            *(_cproc + i_2 + 0x35940) =
10006cf4c                                _mudo_get_channel_state(r13_1, 14, nullptr)
10006cf66                            *(_cproc + i_2 + 0x35944) =
10006cf66                                _mudo_get_channel_state(r13_1, 15, nullptr)
10006cf80                            *(_cproc + i_2 + 0x35948) =
10006cf80                                _mudo_get_channel_state(r13_1, 16, nullptr)
10006cf9a                            *(_cproc + i_2 + 0x3594c) =
10006cf9a                                _mudo_get_channel_state(r13_1, 17, nullptr)
10006cfb4                            *(_cproc + i_2 + 0x35950) =
10006cfb4                                _mudo_get_channel_state(r13_1, 18, nullptr)
10006cfbb                            r13_1 += 1
10006cfbe                            i_2 -= -0x80
10006cfc9                        while (i_2 != 0x800)
10006cfc9
10006cfd1                        _audio_op_end()
10006cfd6                        _cproc_3 = _cproc
10006cfd6
10006cff5                    output = zx.o(0)
10006cff8                    output[0] = float.d(*
10006cff8                        (&_cproc_3[zx.q(arg1 - 400) * 16] + (sx.q(arg2.d) << 2) + 0x35908))
10006cff8
10006d00f                    if (arg1 == 465)
10006d00f                        goto label_case_465
10006d00f
10006d058            label_10006d058:
10006d058
10006d05f            if (arg1 != 464)
10006d1b4                label_10006d1b4:
10006d1b4
10006d1bb                if (arg1 == 985)  // stat(985)
10006d20d                    output = zx.o(0)
10006d210                    output[0] = float.d(data_1001d3210:0xc.d)
10006d467                    _lua_pushnumber(statArgs, output[0])
10006d46c                    num_values_pushed_to_statArgs = 1
10006d1bb                else if (arg1 == 467)
10006d22b                    _audio_op_start(*_cproc, 0)  // stat(467)
10006d230                    data_1001d3290:4.d += 1
10006d238                    num_values_pushed_to_statArgs = 1
10006d24e                    _lua_pushinteger(statArgs, sx.q(_mudo_get_music_state(1)))
10006d255                    _audio_op_end()
10006d1c4                else if (arg1 != 466)
10006d266                    if (arg1 == 986)  // stat(986)
10006d268                        output = zx.o(0)
10006d26b                        output[0] = float.d(data_1001d31e0:4.d)
10006d26b
10006d279                    if (arg1 == 988)  // stat(988)
10006d413                        output = _start_frame()
10006d41d                        int32_t rax_63 = _os_key_state(0xe0)
10006d424                        int32_t rax_64
10006d424
10006d424                        if (rax_63 != 0)
10006d42b                            rax_64 = _os_key_state(0xe4)
10006d42b
10006d432                        if (rax_63 != 0 && rax_64 != 0)
10006d45c                            output = 0x3ff0000000000000
10006d432                        else
10006d434                            output = _mm_xor_pd(output, output)
10006d279                    else if (arg1 == 987)
10006d293                        output = zx.o(0)  // stat(987)
10006d296                        output[0] = float.d(_boot_get_time())
10006d296
10006d467                    _lua_pushnumber(statArgs, output[0])
10006d46c                    num_values_pushed_to_statArgs = 1
10006d1cd                else  // stat(466)
10006d1e2                    _audio_op_start(*_cproc, 0)
10006d1e7                    data_1001d3290:4.d += 1
10006d1fc                    _lua_pushinteger(statArgs, sx.q(_mudo_get_music_state(0)))
10006d203                    _audio_op_end()
10006d46c                    num_values_pushed_to_statArgs = 1
10006d05f            else
10006d06c                int64_t* _cproc_4 = _cproc  // stat(464)
10006d06c
10006d07d                if (_cproc_4[0x6c22] != _cproc_4[0x4e])
10006d084                    _audio_op_start(*_cproc_4, 0)
10006d089                    data_1001d3284 += 1
10006d091                    void* _cproc_5 = _cproc
10006d09b                    *(_cproc_5 + 0x36110) = *(_cproc_5 + 0x270)
10006d0ac                    *(_cproc + 0x36118) = _mudo_get_active_channels()
10006d0b4                    _audio_op_end()
10006d0b9                    _cproc_4 = _cproc
10006d0b9
10006d0c6                _lua_pushinteger(statArgs, sx.q(_cproc_4[0x6c23].d))
10006d46c                num_values_pushed_to_statArgs = 1
10006d46c
10006d483        return zx.q(num_values_pushed_to_statArgs)
```

## Source search

A search through a dump of `/ram` and `/system` using a VSCode Search Editor with the below settings yielded the results found in [search.txt](search.txt).

Search regex: `[^f]stat\(`

Files to include: `picotron/drive/dumps/`

Context lines: `1`

### All unique `stat()` calls

Pasting [search.txt](search.txt) into [regex101](https://regex101.com/), using regex `/stat\(.*?\)/gm`, can exporting the matches as plain text, [all-stat-calls.txt](all-stat-calls.txt) was generated.

Running VSCode's `> Delete Duplicate Lines` and `> Sort lines (natural)` on [all-stat-calls.txt](all-stat-calls.txt), gave the following list of all unique `stat()` calls:

```
stat()
stat(0)
stat(1)
stat(5)
stat(7)
stat(87)
stat(101)
stat(152)
stat(301)
stat(302, i)
stat(307)
stat(315)
stat(316)
stat(317)
stat(318)
stat(320)
stat(321)
stat(330)
stat(400 + ci_channel, 8)
stat(400 + ci_channel, 20 + node_index, tick_addr)
stat(400 + i, 9)
stat(400 + i, 12)
stat(400 + stat(467)
stat(400+i,1 )
stat(400+i,1)
stat(400+i,9 )
stat(400+i,12)
stat(400+i,19,0x90000)
stat(464)
stat(465,0,0xe0000)
stat(466)
stat(987)
stat(988)
stat(wallpaper)
```

Note:

- `stat()` was from a comment, and irrelevant.
- `stat(400 + stat(467)` was cut short. Full call from source is `stat(400 + stat(467), 9)`
- `stat(wallpaper)`'s full source is `fstat(wallpaper)`, and irrelevant.

### Undocumented unique `stat()` calls

This list takes the previous list, and removed officially documented ones.

```
stat(301)
stat(302, i)
stat(307)
stat(315)
stat(316)
stat(317)
stat(318)
stat(320)
stat(321)
stat(330)
stat(987)
stat(988)
```

### Code searches

#### 301 Search

Search regex: `[^f]stat\(301`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
6 results - 1 file

picotron/drive/dumps/latest/system/boot.lua:
   90  	local keep_going = true
   91: 	local remaining = allotment - stat(301)
   92  	local slices = 0

  199
  200: 	local userland_cpu = 0.98 - wm_cpu_max - stat(301)
  201: 	local cpu0 = stat(301)
  202

  204
  205: 	local cpu1 = stat(301)
  206

  239
  240: 	local cpu2 = stat(301)
  241

  253
  254: 	flip() -- reset cpu_cycles for next frame? doesn't matter now that using stat(301) though.
  255
```

#### 302 Search

Search regex: `[^f]stat\(302`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
1 result - 1 file

picotron/drive/dumps/latest/system/lib/events.lua:
  151  	for i=1,255 do
  152: 		local mapped_name = stat(302, i)
  153  		if (mapped_name and mapped_name ~= "") then
```

#### 307 Search

Search regex: `[^f]stat\(307`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
5 results - 2 files

picotron/drive/dumps/latest/system/apps/filenav.p64:
  3029
  3030: 				-- printh("clicked on file; {intention, open_with, fullpath(filename), stat(307)}"..pod{intention, env().open_with, fullpath(filename), stat(307)})
  3031

picotron/drive/dumps/latest/system/lib/head.lua:
   203  	-- sandboxed programs can not create processes
   204: 	if _env().sandbox and ((stat(307) & 0x1) == 0) then -- sandboxed program that is not a trusted system app
   205

   363  	-- only "trusted system apps" (currently /system/*) can pass in a custom fileview
   364: 	if (stat(307) & 0x1) == 0 then
   365  		new_env.fileview = {}

  1064  		proc_id == _pid() or                          -- can always send message to self
  1065: 		(stat(307) & 0x1) == 1 or                     -- can always send message if is bundled /system app (filenav)
  1066  		proc_id == 3 or                               -- can always send message to wm
```

#### 315 Search

Search regex: `[^f]stat\(315`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
4 results - 4 files

picotron/drive/dumps/latest/system/boot.lua:
  170  	-- to do: use time() for better sync
  171: 	if not played_boot_sound and stat(987) >= sfx_delay and stat(315) == 0 then
  172  		played_boot_sound = true

picotron/drive/dumps/latest/system/startup.lua:
  59
  60: if (stat(315) > 0) then
  61  	-- headless script

picotron/drive/dumps/latest/system/lib/head.lua:
  778
  779: 		if (stat(315) > 0) then
  780  			_printh(_tostring(str))

picotron/drive/dumps/latest/system/pm/pm.lua:
  17  	-- headless script: shutdown when no userland processes remaining
  18: 	if (stat(315) > 0 and #_get_process_list() <= 3) _signal(33)
  19
```

#### 316 Search

Search regex: `[^f]stat\(316`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
1 result - 1 file

picotron/drive/dumps/latest/system/startup.lua:
  61  	-- headless script
  62: 	create_process(stat(316))
  63  	return
```

#### 317 Search

Search regex: `[^f]stat\(317`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
20 results - 4 files

picotron/drive/dumps/latest/system/startup.lua:
    8  	sdat = fetch"/system/misc/default_settings.pod"
    9: 	if (stat(317) > 0) then
   10  		sdat.wallpaper = "/system/wallpapers/pattern.p64"

   30  local ff = ls("/desktop")
   31: if (not ff or #ff == 0 or stat(317) > 0) then
   32  	mkdir ("/desktop") -- just in case
   33  	cp("/system/misc/drive.loc", "/desktop/drive.loc")
   34: 	if ((stat(317) & 0x2) == 0) cp("/system/misc/readme.txt", "/desktop/readme.txt") -- no readme for exports
   35  end

   72
   73: if (stat(317) & 0x2) > 0 then
   74  	-- export

  141
  142: if stat(317) == 0 then -- no tool workspaces for exports / bbs player
  143  	create_process("/system/apps/code.p64", {argv={"/ram/cart/main.lua"}})

  152  local wallpaper = (sdat and sdat.wallpaper) or "/system/wallpapers/pattern.p64"
  153: if ((stat(317) & 0x1) ~= 0) wallpaper = nil -- placeholder: exports do not observe wallpaper to avoid exported runtime/cart mismatch in exp/shared
  154  if (not fstat(wallpaper)) wallpaper = "/system/wallpapers/pattern.p64"

  160
  161: if stat(317) == 0 then -- no fullscreen terminal for exports / bbs player
  162  	create_process("/system/apps/terminal.lua",

  180
  181: if stat(317) > 0 then
  182  	-- player startup

  198
  199: 	if ((stat(317) & 0x3) == 0x3) then -- player that has embedded rom
  200  		-- printh("** sending signal 39: disabling mounting **")

picotron/drive/dumps/latest/system/lib/fs.lua:
   92  		-- bbs web player
   93: 		if ((stat(317) & 0x3) == 0x1) then
   94  			if (stat(152) == "localhost") return "http://localhost" -- dev

   98  		-- any other exports: bbs:// is not supported (to do: explicit error codepath -- just disable bbs:// ? )
   99: 		if ((stat(317) & 0x1) > 0) return ""
  100

  106  		-- bbs web player: just use get_cart for now -- later: use cdn
  107: 		if ((stat(317) & 0x3) == 0x1) return get_bbs_host().."/bbs/get_cart.php?cat=8&lid="..bbs_id
  108  		-- exports: bbs:// otherwise not supported
  109: 		if (stat(317) > 0) return ""
  110  		-- binaries: use cdn

picotron/drive/dumps/latest/system/pm/pm.lua:
  21  	-- to do: this test no longer works
  22: 	if (stat(317) > 0 and #_get_process_list() <= 3) _signal(33)
  23

picotron/drive/dumps/latest/system/wm/wm.lua:
   836  	if (not win) return false
   837: 	return win.fullscreen and win.player_cart and (stat(317)&0x3) == 0x3 and not win.can_escape_fullscreen
   838  end

  2221  	if (not sent_presentable_signal) then
  2222: 		if (stat(317) > 0) then
  2223  			-- exported cartridge / bbs player: show when a window is open, active (0x1) and not holding frame (0x2)

  2407  	-- deleteme -- happens when window manager sends signal(37) (wm_is_presentable)
  2408: 	-- if (time() == 1.5 and stat(317) == 0) set_workspace(5)
  2409

  2455  		-- 3 minutes; to do: store in settings.pod
  2456: 		if (stat(317) & 0x1) == 0 then -- placeholder: no screensaver for exports / bbs player (older exported runtimes can end up running newer screensavers)
  2457  			if ((time() > last_input_activity_t + 180 or test_screensaver_t0) and not screensaver_proc_id)

  2567
  2568: 		if stat(317) > 0 then
  2569  			-- exported player or bbs player: reset cart if it is active

  3939  	-- bbs:// not available for exports (and hide for bbs player)
  3940: 	if (stat(317) == 0) then
  3941  		-- to do: cartridges should launch splore (doubles as Favourites). Naming matches "Files" -- the objects you want to look through
```

#### 318 Search

Search regex: `[^f]stat\(318`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
6 results - 3 files

picotron/drive/dumps/latest/system/lib/events.lua:
  448
  449: 		elseif stat(318) == 1 then
  450  			-- web: when ctrl-v, pretend the v didn't happen.

picotron/drive/dumps/latest/system/lib/head.lua:
  1046  	-- web debug
  1047: 	if (stat(318)==1) printh("@notify: "..msg_str.."\n")
  1048  end

picotron/drive/dumps/latest/system/wm/wm.lua:
   957  	if (haltable_proc_id == win.proc_id) has_exit = false    -- running /ram/cart via ctrl+r; just press escape instead
   958: 	if (win.player_cart and stat(318) == 1) has_exit = false -- running entry point cart / bbs cart under web (nothing to exit to)
   959

   961  		add(win.pmenu, {label = "Exit Cartridge", action = function()
   962: 			if is_fullscreen_export(win) and stat(318) == 0 then
   963  				-- 0.2.0b playing the entry point cart in a binary export -> quit to host OS

  2251  			sent_presentable_signal = true
  2252: 			-- if (stat(318) > 0) printh("@@ forced signal 37")
  2253  		end

  3978  	-- no need to shutdown on web
  3979: 	if (stat(318) == 0) add(item, {"\^:082a494141221c00 Shutdown", function() send_message(2, {event="shutdown"}) end})
  3980
```

#### 320 Search

Search regex: `[^f]stat\(320`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
3 results - 1 file

picotron/drive/dumps/latest/system/wm/wm.lua:
  2257  	-- show gif capture (don't draw inside captured area!)
  2258: 	if (stat(320) > 0) then
  2259  		local x,y,width,height,scale = peek2(0x40,5)

  2716  	-- finish capturing gif
  2717: 	if (stat(320) > 0) then
  2718  		if (key("ctrl") and dkeyp("9") or stat(321) >= max_gif_frames()) then

  3918
  3919: 	if (stat(320) > 0) then
  3920  		add(item, {"\^:06ff81b5b181ff00 End Recording", function() _signal(19) end})
```

#### 321 Search

Search regex: `[^f]stat\(321`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
4 results - 1 file

picotron/drive/dumps/latest/system/wm/wm.lua:
  2261
  2262: 		polaroid(x,y,x+width-1,y+height-1, stat(321), max_gif_frames())
  2263  --[[

  2270  		local maxf = max_gif_frames()
  2271: 		local q = stat(321) * 32 / maxf
  2272  		local x0 = x + width - 40

  2275  		if (width > 100) then
  2276: 			print("\014frame "..flr(stat(321)).." / "..maxf, x+4,y+height+3, 7)
  2277  		else

  2717  	if (stat(320) > 0) then
  2718: 		if (key("ctrl") and dkeyp("9") or stat(321) >= max_gif_frames()) then
  2719  			_signal(19)
```

#### 330 Search

Search regex: `[^f]stat\(330`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
1 result - 1 file

picotron/drive/dumps/latest/system/wm/wm.lua:
  2288  	-- debug: show when battery saver is being applied
  2289: 	-- if (stat(330) > 0) circfill(20,20,10,8) circfill(20,20,5,1)
  2290
```

#### 987 Search

Search regex: `[^f]stat\(987`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
1 result - 1 file

picotron/drive/dumps/latest/system/boot.lua:
  170  	-- to do: use time() for better sync
  171: 	if not played_boot_sound and stat(987) >= sfx_delay and stat(315) == 0 then
  172  		played_boot_sound = true
```

#### 988 Search

Search regex: `[^f]stat\(988`

Files to include: `picotron/drive/dumps/latest/system/`

Context lines: `1`

```
1 result - 1 file

picotron/drive/dumps/latest/system/startup.lua:
  106  	flip()
  107: 	if (stat(988) > 0) bypass = true _signal(35)
  108  end
```
