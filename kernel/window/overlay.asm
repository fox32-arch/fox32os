; overlay routines for window management

; given a position on screen, find which enabled overlay (if any) is covering it
; if multiple overlays are covering the same position, the highest priority one will be returned
; overlays 31, 30, and 29 (mouse cursor, menu bar, menu) are ignored
; inputs:
; r0: X coordinate
; r1: Y coordinate
; outputs:
; r0: overlay number, or 0xFFFFFFFF if none
find_overlay_convering_position:
    push r2
    push r31

    mov r31, 29
find_overlay_convering_position_loop:
    mov r2, r31
    dec r2
    call check_if_enabled_overlay_covers_position
    ifz jmp find_overlay_convering_position_found
    loop find_overlay_convering_position_loop
    ; none found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF
    pop r31
    pop r2
    ret
find_overlay_convering_position_found:
    ; found one, return its overlay number
    mov r0, r2
    pop r31
    pop r2
    ret

; swap two overlays. this has the effect of swapping their priorities
; this does *not* effect the enable status of either overlay
; FIXME: this could use the stack instead
; inputs:
; r0: overlay number
; r1: overlay number
; outputs:
; none
swap_overlays:
    push r10

    ; save first overlay
    mov r10, r0
    or r10, 0x80000000
    in [overlay_0_position], r10
    mov r10, r0
    or r10, 0x80000100
    in [overlay_0_size], r10
    mov r10, r0
    or r10, 0x80000200
    in [overlay_0_ptr], r10

    ; save second overlay
    mov r10, r1
    or r10, 0x80000000
    in [overlay_1_position], r10
    mov r10, r1
    or r10, 0x80000100
    in [overlay_1_size], r10
    mov r10, r1
    or r10, 0x80000200
    in [overlay_1_ptr], r10

    ; swap
    mov r10, r1
    or r10, 0x80000000
    out r10, [overlay_0_position]
    mov r10, r1
    or r10, 0x80000100
    out r10, [overlay_0_size]
    mov r10, r1
    or r10, 0x80000200
    out r10, [overlay_0_ptr]
    mov r10, r0
    or r10, 0x80000000
    out r10, [overlay_1_position]
    mov r10, r0
    or r10, 0x80000100
    out r10, [overlay_1_size]
    mov r10, r0
    or r10, 0x80000200
    out r10, [overlay_1_ptr]

    pop r10
    ret

overlay_0_position: data.32 0x00000000
overlay_0_size:     data.32 0x00000000
overlay_0_ptr:      data.32 0x00000000
overlay_1_position: data.32 0x00000000
overlay_1_size:     data.32 0x00000000
overlay_1_ptr:      data.32 0x00000000
