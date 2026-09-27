-- picomos NES runner helper for MAME.
--
-- The NES has no KERNAL, no ROM CHROUT, no console. picomos routes
-- printf/puts through picolibc -> nes_putc (stdio_hook.c) -> __putchar
-- (putchar.c), which stores each byte to $401B — an unused APU/IO
-- MMIO address that the emulator side of the world can safely
-- interpret as debug output. This lua installs a write-tap at $401B
-- and mirrors every byte written to the emulator subprocess's
-- stdout. `picomos_add_test` consumes that stream via CTest's
-- PASS_REGULAR_EXPRESSION — no screen scraping, no PPU parsing.
--
-- The convention (and address choice) is inherited from
-- llvm-mos-sdk (Apache-2.0 WITH LLVM-exception), which uses the same
-- $401B hook in its NES platform putchar implementation.
--
-- Works without `-debug`. The tap object MUST be stashed in _G so Lua
-- garbage collection doesn't quietly reclaim it after a few frames.

local cpu = manager.machine.devices[":maincpu"]
local program = cpu.spaces["program"]

_G.picomos_stdout_tap = program:install_write_tap(
    0x401B, 0x401B, "picomos-stdout",
    function(offset, data, mask)
        local c = data & 0xff
        if c == 0x0A or c == 0x0D then
            io.write("\n")
        elseif c >= 0x20 and c <= 0x7E then
            io.write(string.char(c))
        end
        io.flush()
        return data
    end)
