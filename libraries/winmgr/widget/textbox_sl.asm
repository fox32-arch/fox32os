; textbox_sl widget routines

; textbox_sl widget struct:
; data.32 next_ptr         - pointer to next widget, or 0 for none
; data.32 id               - the ID number of this widget
; data.32 type             - the type of this widget
; data.32 buffer_ptr       - pointer to null-terminated input string
; data.32 foreground_color - text foreground color
; data.32 background_color - textbox_sl background color
; data.16 width            - width of this textbox_sl
; data.16 buffer_max       - maximum input length including null-terminator
; data.16 x_pos            - X coordinate of this widget
; data.16 y_pos            - Y coordinate of this widget

const TEXTBOX_SL_WIDGET_STRUCT_SIZE: 32 ; 8 words = 32 bytes
const TEXTBOX_SL_HEIGHT: 20

; draw a textbox_sl widget to a window
; inputs:
; r0: pointer to window struct
; r1: pointer to a null-terminated input string
; r2: foreground color
; r3: background color
; r4: textbox_sl width
; r5: X coordinate
; r6: Y coordinate
; r7: non-zero if textbox is active
draw_textbox_sl_widget:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r10

    call get_window_overlay_number
    mov r10, r0

    push r1
    push r2
    push r3
    push r4
    push r5
    mov r0, r5
    mov r1, r6
    mov r2, r4
    mov r4, r3
    push r4
    cmp r7, 0
    ifz jmp draw_textbox_sl_widget_not_active
    not r4
    or r4, 0xFF000000
draw_textbox_sl_widget_not_active:
    mov r3, TEXTBOX_SL_HEIGHT
    mov r5, r10
    call draw_filled_rectangle_to_overlay
    sub r2, 4
    sub r3, 4
    add r0, 2
    add r1, 2
    pop r4
    call draw_filled_rectangle_to_overlay
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1

    mov r4, r3
    mov r3, r2
    mov r0, r1
    mov r1, r5
    add r1, 2
    mov r2, r6
    add r2, 2
    mov r5, r10
    call draw_str_to_overlay

    pop r10
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret
