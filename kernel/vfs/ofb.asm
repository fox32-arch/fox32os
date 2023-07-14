; overlay framebuffer vfs stream routines

overlay_vfs_stream_name: data.strz "ofb"

; open an overlay framebuffer stream
; inputs:
; r0: pointer to null-terminated string "ofbXX" where XX is 0 - 31
; r2: file struct: pointer to a blank file struct (stream)
; outputs:
; r0: non-zero if valid overlay
open_stream_ofb:
    push r1
    push r2

    add r0, 3
    mov r1, 10
    call string_to_int
    cmp r0, 31
    ifgt mov r0, 0
    ifgt pop r2
    ifgt pop r1
    ifgt ret

    mov.8 [r2], r0             ; write file_overlay
    inc r2
    mov.16 [r2], 0             ; write file_reserved_2
    add r2, 2
    mov [r2], 0                ; write file_seek_offset
    add r2, 4
    mov.8 [r2], 1              ; write file_system_type
    inc r2
    mov [r2], ofb_stream_read  ; write file_read_call
    add r2, 4
    mov [r2], ofb_stream_write ; write file_write_call
    add r2, 4
    or r0, 0x80000100
    in r0, r0
    mov r1, r0
    srl r1, 16
    mul r1, r0
    mov [r2], r1               ; write file_size
    add r2, 4
    mov [r2], 0                ; write file_reserved_3
    add r2, 4
    mov [r2], 0                ; write file_reserved_4
    add r2, 4
    mov [r2], 0                ; write file_reserved_5

    pop r2
    pop r1
    mov r0, 1
    ret

; read a byte from an overlay framebuffer
; inputs:
; r0: seek offset
; r1: pointer to file struct + 8
; outputs:
; r0: byte
ofb_stream_read:
    push r1
    push r2

    ; get overlay framebuffer pointer in r2
    sub r1, 8 ; point to file_overlay (file_reserved_1)
    movz.8 r1, [r1]
    or r1, 0x80000200
    in r2, r1

    ; get overlay size in r1
    sub r1, 0x100
    in r1, r1
    push r0
    mov r0, r1
    srl r0, 16
    and r1, 0x0000FFFF
    mul r1, r0
    mul r0, 4
    pop r0

    ; ensure the seek offset is less than the overlay size
    cmp r0, r1
    ifgteq mov r0, r1
    ifgteq dec r0

    ; fetch the byte
    add r0, r2
    movz.8 r0, [r0]

    pop r2
    pop r1
    ret

; write a byte to an overlay framebuffer
; inputs:
; r0: pointer to source buffer
; r1: seek offset
; r3: pointer to file struct + 12
; outputs:
; none
ofb_stream_write:
    push r1
    push r2
    push r3
    push r4

    ; get overlay framebuffer pointer in r2
    sub r3, 12 ; point to file_overlay (file_reserved_1)
    movz.8 r3, [r3]
    or r3, 0x80000200
    in r2, r3

    ; get overlay size in r4
    sub r3, 0x100
    in r4, r3
    push r0
    mov r0, r4
    srl r0, 16
    and r4, 0x0000FFFF
    mul r4, r0
    mul r4, 4
    pop r0

    ; ensure the seek offset is less than the overlay size
    cmp r1, r4
    ifgteq mov r1, r4
    ifgteq dec r1

    ; write the byte
    add r2, r1
    mov.8 [r2], [r0]

    pop r4
    pop r3
    pop r2
    pop r1
    ret
