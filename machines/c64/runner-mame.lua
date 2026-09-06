-- picomos c64 runner helper for MAME.
--
-- MAME's `-quik` device loads a PRG into RAM and adjusts BASIC pointers,
-- but doesn't RUN it — the user is expected to type RUN. `-autoboot_command
-- 'run\n'` does not fire on the c64 driver in current MAME versions
-- (tested 0.283).
--
-- After ~3 emulated seconds (long enough for the KERNAL power-on banner
-- and BASIC READY prompt), we inject "RUN<CR>" directly into the C64's
-- keyboard buffer:
--
--   $0277-$0280   10-byte KERNAL keyboard buffer (PETSCII)
--   $00C6         pending-character count
--
-- BASIC's main loop reads from the buffer as if the user typed it, so
-- the program launches on its own.

local injected = false

emu.register_periodic(function()
    if injected then return end
    if manager.machine.time.seconds < 3 then return end
    local mem = manager.machine.devices[":u7"].spaces["program"]
    mem:write_u8(0x0277, 0x52)   -- 'R'
    mem:write_u8(0x0278, 0x55)   -- 'U'
    mem:write_u8(0x0279, 0x4E)   -- 'N'
    mem:write_u8(0x027A, 0x0D)   -- RETURN
    mem:write_u8(0x00C6, 4)
    injected = true
end)
