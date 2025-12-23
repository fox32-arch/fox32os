# FXF

| Byte Range            | Description                             |
| :-------------------: | --------------------------------------- |
| 0x00000000-0x00000002 | "FXF" magic bytes                       |
| 0x00000003            | header version (0 for no bss, else bss) |
| 0x00000004-0x00000007 | code size                               |
| 0x00000008-0x0000000B | pointer to code                         |
| 0x0000000C-0x0000000F | reloc table size                        |
| 0x00000010-0x00000013 | pointer to reloc table                  |
| 0x00000014-0x00000017 | bss allocation size (if version != 0)   |

# APP

| Byte Range            | Description                               |
| :-------------------: | ----------------------------------------- |
| 0x00000000-0x00000002 | "APP" magic bytes                         |
| 0x00000003            | zero                                      |
| 0x00000004-0x00000007 | code entry point                          |
| 0x00000008-0x0000000B | short name string pointer (max 12 chars)  |
| 0x0000000C-0x0000000F | description string pointer (max 50 chars) |
| 0x00000010-0x00000013 | author string pointer (max 50 chars)      |
| 0x00000014-0x00000017 | version string pointer (max 8 chars)      |
| 0x00000018-0x0000001B | 32x32 (32 bpp) icon pointer               |
