-- picomos c64 runner helper for MAME. Does two things every run:
--
-- 1. Auto-RUN after boot. MAME's `-quik` loads a PRG into RAM and
--    fixes the BASIC pointers but doesn't type RUN;
--    `-autoboot_command 'run\n'` doesn't fire on the c64 driver in
--    tested MAME versions. We inject "RUN<CR>" into the KERNAL
--    keyboard buffer ($0277-$0280, count at $00C6) ~3 emulated
--    seconds after boot, which BASIC's main loop reads as if typed.
--
-- 2. Mirror KERNAL CHROUT ($FFD2) to the parent process's stdout.
--    A read-tap on $FFD2 fires each time the CPU fetches the first
--    instruction byte of CHROUT — i.e. on every JSR/JMP into it.
--    At that instant the accumulator holds the byte-to-print in
--    PETSCII. We translate a minimal ASCII-safe subset and write
--    each character to stdout. `picomos_add_test` uses this stream
--    to check EXPECT patterns via CTest's PASS_REGULAR_EXPRESSION
--    without any screen-scraping.
--
-- Works without `-debug` (memory taps are available at all times);
-- the emulator stays fully headless.

local cpu     = manager.machine.devices[":u7"]
local program = cpu.spaces["program"]

-- Auto-RUN keyboard-buffer injection.
local injected = false
emu.register_periodic(function()
    if injected then return end
    if manager.machine.time.seconds < 3 then return end
    program:write_u8(0x0277, 0x52)  -- 'R'
    program:write_u8(0x0278, 0x55)  -- 'U'
    program:write_u8(0x0279, 0x4E)  -- 'N'
    program:write_u8(0x027A, 0x0D)  -- <RETURN>
    program:write_u8(0x00C6, 4)
    injected = true
end)

-- CHROUT mirror.
--
-- Our program's puts() calls CHROUT with the raw ASCII byte, so 'H'
-- appears here as 0x48 — 1:1 with source-level characters. (The C64
-- screen would render lowercase as uppercase glyphs because of the
-- boot charset; the tap sidesteps that entirely.) We remap only the
-- one control code that matters — $0D CR → \n so puts()'s newline
-- shows up as a line break in captured output. Anything outside the
-- printable range is dropped; the KERNAL emits several such codes
-- during its power-on banner (cursor moves, colour changes).
--
-- The tap object MUST be kept alive — Lua garbage collection would
-- otherwise reclaim it after a few frames and the hook silently
-- stops firing. Stashing it in _G defeats that.
_G.picomos_chrout_tap = program:install_read_tap(
    0xFFD2, 0xFFD2, "picomos-chrout",
    function(offset, data, mask)
        local a = cpu.state["A"].value
        local ch
        if     a == 0x0D                     then ch = "\n"
        elseif a >= 0x20 and a <= 0x7E       then ch = string.char(a)
        end
        if ch then
            io.write(ch)
            io.flush()
        end
        return data
    end)
