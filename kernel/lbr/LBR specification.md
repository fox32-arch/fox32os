| Byte Range            | Description                             |
| :-------------------: | --------------------------------------- |
| 0x00000000-0x00000002 | "LBR" magic bytes                       |
| 0x00000003            | header version                          |
| 0x00000004-0x00000007 | code size                               |
| 0x00000008-0x0000000B | offset of code                          |
| 0x0000000C-0x0000000F | reloc table size                        |
| 0x00000010-0x00000013 | offset of reloc table                   |
| 0x00000014-0x00000017 | jump table size                         |
| 0x00000018-0x0000001B | offset of jump table                    |

note: the 32-bit word at (calculated absolute jump table address - 4 bytes) will be
overwritten by the LBR loader with the absolute address of the block of memory to
free when the library's reference count reaches zero. this allows the OS to pass the
address of the jump table around instead of needing to pass the actual block address.
the system call for closing a library simply needs to free *(jump table address - 4 bytes)
once the reference count reaches zero.
