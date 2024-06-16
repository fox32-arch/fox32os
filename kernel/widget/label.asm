; label widget routines

; label widget struct:
; data.32 next_ptr         - pointer to next widget, or 0 for none
; data.32 id               - the ID number of this widget
; data.32 type             - the type of this widget
; data.32 text_ptr         - pointer to null-terminated text string
; data.32 foreground_color - text foreground color
; data.32 background_color - text background color
; data.16 reserved_1
; data.16 reserved_2
; data.16 x_pos            - X coordinate of this widget
; data.16 y_pos            - Y coordinate of this widget

const LABEL_WIDGET_STRUCT_SIZE: 32 ; 8 words = 32 bytes

; draw a label widget to a window
; inputs:
; r0: pointer to window struct
; r1: pointer to a null-terminated string
; r2: foreground color
; r3: background color
; r4: X coordinate
; r5: Y coordinate
; outputs:
; none
draw_label_widget:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5

    call get_window_overlay_number
    push r4
    mov r4, r3
    mov r3, r2
    mov r2, r5
    mov r5, r0
    mov r0, r1
    pop r1
    call draw_str_to_overlay

    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret
