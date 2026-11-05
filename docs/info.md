<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The project contains one IHP `RM_IHPSG13_1P_256x16_c2_bm_bist` SRAM macro (256 words of 16 bits) and a small command interface around it. On every rising clock edge, `ui_in[7:6]` selects a command:

| `ui_in[7:6]` | Command | `uio_in` |
| ------------ | ------- | -------- |
| `00` | read: the SRAM reads the word at the address register | - |
| `01` | set the address register | address |
| `10` | write the low byte of the addressed word | data |
| `11` | write the high byte of the addressed word | data |

The inputs are registered before they reach the SRAM, so a command takes effect one clock cycle after it is sampled. `uo_out` shows the low byte (`ui_in[0]` = 0) or the high byte (`ui_in[0]` = 1) of the last word the SRAM read. After a set address command, the word appears on `uo_out` three clock cycles later.

## How to test

1. Reset the design.
2. Write a word: set the address (`ui_in` = `0x40`, address on `uio_in`), then write the low byte (`ui_in` = `0x80`, data on `uio_in`) and the high byte (`ui_in` = `0xC0`, data on `uio_in`), one clock cycle each.
3. Read it back: set the address, then keep `ui_in` at `0x00` for three clock cycles and read the low byte on `uo_out`. Set `ui_in` to `0x01` to see the high byte.

## External hardware

None.
