| Byte Range            | Description                             |
| :-------------------: | --------------------------------------- |
| 0x00000000-0x00000002 | "FXF" magic bytes                       |
| 0x00000003            | header version (0 for no bss, else bss) |
| 0x00000004-0x00000007 | code size                               |
| 0x00000008-0x0000000B | pointer to code                         |
| 0x0000000C-0x0000000F | reloc table size                        |
| 0x00000010-0x00000013 | pointer to reloc table                  |
| 0x00000014-0x00000017 | bss allocation size (if version != 0)   |
