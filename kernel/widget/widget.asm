; widget management routines

; widget types
const WIDGET_TYPE_BUTTON: 0x00000000

; widget struct:
; data.32 next_ptr - pointer to next widget, or 0 for none
; data.32 id       - the ID number of this widget
; data.32 type     - the type of this widget
; remaining entries vary depending on widget type

; draw all of a window's widgets to a window
; inputs:
; r0: pointer to window struct
; outputs:
; none
draw_widgets_to_window:
    push r10

    ; get pointer to first widget
    mov r10, r0
    add r10, 32
    mov r10, [r10]
draw_widgets_to_window_next:
    ; check widget type
    add r10, 8
    cmp [r10], WIDGET_TYPE_BUTTON
    ifz call draw_widgets_to_window_button

    ; point to the next widget, if any
    sub r10, 8
    mov r10, [r10]
    cmp r10, 0
    ifz jmp draw_widgets_to_window_done
    jmp draw_widgets_to_window_next
draw_widgets_to_window_done:
    pop r10
    ret
draw_widgets_to_window_button:
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r10

    ; put button parameters in registers for the drawing routine
    add r10, 4
    mov r1, [r10] ; text_ptr
    add r10, 4
    mov r2, [r10] ; foreground_color
    add r10, 4
    mov r3, [r10] ; background_color
    add r10, 4
    movz.16 r4, [r10] ; width
    add r10, 4
    movz.16 r5, [r10] ; x_pos
    add r10, 2
    movz.16 r6, [r10] ; y_pos
    call draw_button_widget

    pop r10
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    ret

; check if a widget was clicked and if so, add an event to the window's event queue
; inputs:
; r0: pointer to window struct
; r1: X coordinate of click
; r2: Y coordinate of click
; outputs:
; none
handle_widget_click:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8
    push r30

    mov r30, r0

    ; get pointer to first widget
    add r0, 32
    mov r0, [r0]
handle_widget_click_check_type:
    ; check widget type
    add r0, 8
    cmp [r0], WIDGET_TYPE_BUTTON
    ifz jmp handle_widget_click_button
handle_widget_click_done:
    pop r30
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret
handle_widget_click_button:
    push r0
    push r10
    push r11
    push r12
    push r21
    push r22

    ; get button width
    add r0, 16
    movz.16 r10, [r0]

    ; get button X coordinate
    add r0, 4
    movz.16 r11, [r0]

    ; get button Y coordinate
    add r0, 2
    movz.16 r12, [r0]

    ; calculate button's right side coordinate
    mov r21, r11
    add r21, r10

    ; calculate button's bottom right corner coordinate
    mov r22, r12
    add r22, 16

    ; check if r1 is between r11 and r21
    ; and if r2 is between r12 and r22
    cmp r1, r11
    iflt jmp handle_widget_click_button_no_click
    cmp r1, r21
    ifgt jmp handle_widget_click_button_no_click
    cmp r2, r12
    iflt jmp handle_widget_click_button_no_click
    cmp r2, r22
    ifgt jmp handle_widget_click_button_no_click

    ; if we reach this point then the button was clicked!!
    pop r22
    pop r21
    pop r12
    pop r11
    pop r10
    pop r0

    ; add a button click event to the window
    sub r0, 4
    mov r1, [r0] ; parameter 0: widget ID
    mov r2, 0
    mov r3, 0
    mov r4, 0
    mov r5, 0
    mov r6, 0
    mov r7, 0
    mov r8, r30
    mov r0, EVENT_TYPE_BUTTON_CLICK
    call new_window_event

    jmp handle_widget_click_done
handle_widget_click_button_no_click:
    pop r22
    pop r21
    pop r12
    pop r11
    pop r10
    pop r0

    ; get pointer to next widget
    sub r0, 8
    mov r0, [r0]

    ; if this is the last widget, then exit
    cmp r0, 0
    ifz jmp handle_widget_click_done

    ; retry
    jmp handle_widget_click_check_type

    ; include widget types
    #include "widget/button.asm"
