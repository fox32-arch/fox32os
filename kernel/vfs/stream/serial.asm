; serial vfs stream routines

serial_vfs_stream_name: data.strz "serial"

; open a serial port stream
; inputs:
; r2: file struct: pointer to a blank file struct (stream)
; outputs:
; r0: non-zero
open_stream_serial:
    push r2

    mov.8 [r2], 0                 ; write file_reserved_1
    inc r2
    mov.16 [r2], 0                ; write file_reserved_2
    add r2, 2
    mov [r2], 0                   ; write file_seek_offset
    add r2, 4
    mov.8 [r2], 1                 ; write file_system_type
    inc r2
    mov [r2], serial_stream_read  ; write file_read_call
    add r2, 4
    mov [r2], serial_stream_write ; write file_write_call
    add r2, 4
    mov [r2], 0                   ; write file_size
    add r2, 4
    mov [r2], 0                   ; write file_reserved_3
    add r2, 4
    mov [r2], 0                   ; write file_reserved_4
    add r2, 4
    mov [r2], 0                   ; write file_reserved_5

    pop r2
    mov r0, 1
    ret

; read a byte from the serial port
; inputs:
; r0: seek offset (unused)
; outputs:
; r0: byte
serial_stream_read:
    in r0, 0
    ret

; write a byte to the serial port
; inputs:
; r0: pointer to source buffer
; r1: seek offset (unused)
; outputs:
; none
serial_stream_write:
    movz.8 r1, [r0]
    out 0, r1
    ret
