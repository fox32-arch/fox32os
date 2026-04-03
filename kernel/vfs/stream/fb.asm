; framebuffer vfs stream routines

framebuffer_vfs_stream_name: data.strz "fb"

; open a framebuffer stream
; inputs:
; r2: file struct: pointer to a blank file struct (stream)
; outputs:
; r0: non-zero
open_stream_fb:
    push r2

    mov.8 [r2], 0             ; write file_reserved_1
    inc r2
    mov.16 [r2], 0            ; write file_reserved_2
    add r2, 2
    mov [r2], 0               ; write file_seek_offset
    add r2, 4
    mov.8 [r2], 1             ; write file_system_type
    inc r2
    mov [r2], fb_stream_read  ; write file_read_call
    add r2, 4
    mov [r2], fb_stream_write ; write file_write_call
    add r2, 4
    mov [r2], 0x0012C000      ; write file_size
    add r2, 4
    mov [r2], 0               ; write file_reserved_3
    add r2, 4
    mov [r2], 0               ; write file_reserved_4
    add r2, 4
    mov [r2], 0               ; write file_reserved_5

    pop r2
    mov r0, 1
    ret

; read a byte from the framebuffer
; inputs:
; r0: seek offset
; outputs:
; r0: byte
fb_stream_read:
    add r0, 0x02000000
    cmp r0, 0x0212C000
    ifgteq mov r0, 0x0212BFFF
    movz.8 r0, [r0]
    ret

; write a byte to the framebuffer
; inputs:
; r0: pointer to source buffer
; r1: seek offset
; outputs:
; none
fb_stream_write:
    add r1, 0x02000000
    cmp r1, 0x0212C000
    ifgteq mov r1, 0x0212BFFF
    mov.8 [r1], [r0]
    ret
