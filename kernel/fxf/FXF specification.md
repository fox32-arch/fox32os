| Byte Range            | Description                |
| :-------------------: | -------------------------- |
| 0x00000000-0x00000002 | "FXF" magic bytes          |
| 0x00000003            | header version (must be 0) |
| 0x00000004-0x00000007 | code size                  |
| 0x00000008-0x0000000B | pointer to code            |
| 0x0000000C-0x0000000F | reloc table size           |
| 0x00000010-0x00000013 | pointer to reloc table     |
