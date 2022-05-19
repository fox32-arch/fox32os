| Byte Range            | Description                |
| :-------------------: | -------------------------- |
| 0x00000000-0x00000002 | "FXF" magic bytes          |
| 0x00000003            | header version (must be 0) |
| 0x00000004-0x00000007 | code size                  |
| 0x00000008-0x0000000B | pointer to code            |
| 0x0000000C-0x0000000F | `extern` table size        |
| 0x00000010-0x00000013 | pointer to `extern` table  |
| 0x00000014-0x00000017 | `global` table size        |
| 0x00000018-0x0000001B | pointer to `global` table  |
| 0x0000001C-0x0000001F | reloc table size           |
| 0x00000020-0x00000023 | pointer to reloc table     |
