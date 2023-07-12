; button widget routines

; button widget struct:
; data.32 next_ptr         - pointer to next widget, or 0 for none
; data.32 id               - the ID number of this widget
; data.32 type             - the type of this widget
; data.32 text_ptr         - pointer to null-terminated text string
; data.32 foreground_color - text foreground color
; data.32 background_color - button background color
; data.16 width            - width of this button
; data.16 height           - height of this button
; data.16 x_pos            - X coordinate of this widget
; data.16 y_pos            - Y coordinate of this widget

const BUTTON_WIDGET_STRUCT_SIZE: 32 ; 8 words = 32 bytes

; draw a button widget to a window
; FIXME: this needs some major cleanup, this is like register soup
; inputs:
; r0: pointer to window struct
; r1: pointer to a null-terminated string
; r2: foreground color
; r3: background color
; r4: button width
; r5: X coordinate
; r6: Y coordinate
; r7: button height
draw_button_widget:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r7
    push r10
    push r20
    push r30
    push r31

    push r1
    mov r20, 0
draw_button_widget_strlen_loop:
    inc r1
    inc r20
    cmp.8 [r1], 0
    ifnz jmp draw_button_widget_strlen_loop
    pop r1

    mov r30, r5
    mov r31, r4
    div r4, 2
    mul r20, 8
    div r20, 2
    sub r4, r20
    add r5, r4

    call get_window_overlay_number
    mov r10, r0

    push r1
    push r2
    push r3
    push r4
    push r5
    mov r5, r0
    mov r2, r31
    mov r4, r3
    cmp r7, 16
    iflt mov r7, 16
    mov r3, r7
    mov r0, r30
    mov r1, r6
    call draw_filled_rectangle_to_overlay
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1

    mov r0, r1
    mov r4, r3
    mov r3, r2
    mov r1, r5
    mov r2, r6
    add r2, r7
    sub r2, 16
    mov r5, r10
    call draw_str_to_overlay

    pop r31
    pop r30
    pop r20
    pop r10
    pop r7
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret
