; disk vfs stream routines

disk1_vfs_stream_name: data.strz "disk1"

; open a disk id 1 stream
; inputs:
; r2: file struct: pointer to a blank file struct (stream)
; outputs:
; r0: non-zero
open_stream_disk1:
    push r2

    mov.8 [r2], 0                ; write file_reserved_1
    inc r2
    mov.16 [r2], 0               ; write file_reserved_2
    add r2, 2
    mov [r2], 0                  ; write file_seek_offset
    add r2, 4
    mov.8 [r2], 1                ; write file_system_type
    inc r2
    mov [r2], disk1_stream_read  ; write file_read_call
    add r2, 4
    mov [r2], disk1_stream_write ; write file_write_call
    add r2, 4
    in [r2], 0x80001001          ; write file_size
    add r2, 4
    mov [r2], 0                  ; write file_reserved_3
    add r2, 4
    mov [r2], 0                  ; write file_reserved_4
    add r2, 4
    mov [r2], 0                  ; write file_reserved_5

    pop r2
    mov r0, 1
    ret

; read a byte from disk 1
; inputs:
; r0: seek offset
; outputs:
; r0: byte
disk1_stream_read:
    push r1
    push r2

    push r0
    div r0, 512
    mov r1, 1
    mov r2, TEMP_SECTOR_BUF
    call read_sector
    pop r0
    rem r0, 512
    add r0, TEMP_SECTOR_BUF
    movz.8 r0, [r0]

    pop r2
    pop r1
    ret

; write a byte to disk 1
; inputs:
; r0: pointer to source buffer
; r1: seek offset
; outputs:
; none
disk1_stream_write:
    push r0
    push r1
    push r2

    push r0
    push r1
    div r1, 512
    mov r0, r1
    mov r1, 1
    mov r2, TEMP_SECTOR_BUF
    call read_sector
    pop r1
    pop r0
    push r1
    rem r1, 512
    add r1, TEMP_SECTOR_BUF
    mov.8 [r1], [r0]
    pop r0
    div r0, 512
    mov r1, 1
    mov r2, TEMP_SECTOR_BUF
    call write_sector

    pop r2
    pop r1
    pop r0
    ret
