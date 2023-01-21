; virtual filesystem routines

; file struct for file:
;   file_disk:         1 byte
;   file_first_sector: 2 bytes
;   file_seek_offset:  4 bytes
;   file_system_type:  1 byte (0x00 for RYFS)

; file struct for stream:
;   file_reserved_1:  1 byte
;   file_reserved_2:  2 bytes
;   file_reserved_4:  4 bytes
;   file_system_type: 1 byte (0x01 for stream)
;   file_read_call:   4 bytes
;   file_write_call:  4 bytes

; open a file from a RYFS-formatted disk
; inputs:
; r0: pointer to file name string (8.3 format, for example "test    txt" for test.txt)
; r1: disk ID
; r2: file struct: pointer to a blank file struct
; outputs:
; r0: first file sector, or zero if file wasn't found
open:
    jmp ryfs_open

; seek specified file to the specified offset
; inputs:
; r0: byte offset
; r1: pointer to file struct
; outputs:
; none
seek:
    push r1
    add r1, 7
    cmp.8 [r1], 0x00
    pop r1
    ifz jmp ryfs_seek
    ret

; get the seek offset of the specified file
; inputs:
; r0: pointer to file struct
; outputs:
; r0: byte offset
tell:
    push r0
    add r0, 7
    cmp.8 [r0], 0x00
    pop r0
    ifz jmp ryfs_tell
    ret

; read specified number of bytes into the specified buffer
; inputs:
; r0: number of bytes to read (ignored if file struct is a stream)
; r1: pointer to file struct
; r2: pointer to destination buffer (always 4 bytes if file struct is a stream)
; outputs:
; none
read:
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp ryfs_read
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_read
    pop r3
    ret
stream_read:
    push r0
    push r1
    push r2

    ; call [file_read_call]
    add r1, 8
    call [r1]

    ; put the result into [r2]
    pop r2
    mov [r2], r0

    pop r1
    pop r0
    ret

; write specified number of bytes into the specified file
; inputs:
; r0: number of bytes to write (ignored if file struct is a stream)
; r1: pointer to file struct
; r2: pointer to source buffer (always 4 bytes if file struct is a stream)
; outputs:
; none
write:
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp ryfs_write
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_write
    pop r3
    ret
stream_write:
    push r0
    push r1

    ; call [file_write_call] with pointer to src buf in r0
    add r1, 12
    mov r0, r2
    call [r1]

    pop r1
    pop r0
    ret
