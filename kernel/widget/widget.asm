; widget management routines

; widget types
const WIDGET_TYPE_BUTTON:     0x00000000
const WIDGET_TYPE_TEXTBOX_SL: 0x00000001
const WIDGET_TYPE_LABEL:      0x00000002

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
    mov r10, [r0+32]
draw_widgets_to_window_next:
    ; check widget type
    add r10, 8
    cmp [r10], WIDGET_TYPE_BUTTON
    ifz call draw_widgets_to_window_button
    cmp [r10], WIDGET_TYPE_TEXTBOX_SL
    ifz call draw_widgets_to_window_textbox_sl
    cmp [r10], WIDGET_TYPE_LABEL
    ifz call draw_widgets_to_window_label

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
    push r7

    ; put button parameters in registers for the drawing routine
    mov r1, [r10+4] ; text_ptr
    mov r2, [r10+8] ; foreground_color
    mov r3, [r10+12] ; background_color
    movz.16 r4, [r10+16] ; width
    movz.16 r7, [r10+18] ; height
    movz.16 r5, [r10+20] ; x_pos
    movz.16 r6, [r10+22] ; y_pos
    call draw_button_widget

    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    ret
draw_widgets_to_window_textbox_sl:
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r10

    ; put textbox_sl parameters in registers for the drawing routine
    mov r1, [r10+4] ; buffer_ptr
    mov r2, [r10+8] ; foreground_color
    mov r3, [r10+12] ; background_color
    movz.16 r4, [r10+16] ; width
    movz.16 r5, [r10+20] ; x_pos
    movz.16 r6, [r10+22] ; y_pos
    mov r7, [r0+36] ; check active widget ID
    sub r10, 4
    cmp [r10], [r7+4]
    ifz mov r7, 1
    ifnz mov r7, 0
    call draw_textbox_sl_widget

    pop r10
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    ret
draw_widgets_to_window_label:
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7

    ; put label parameters in registers for the drawing routine
    mov r1, [r10+4] ; text_ptr
    mov r2, [r10+8] ; foreground_color
    mov r3, [r10+12] ; background_color
    movz.16 r4, [r10+20] ; x_pos
    movz.16 r5, [r10+22] ; y_pos
    call draw_label_widget

    pop r7
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
    mov r0, [r0+32]
    push r0
handle_widget_click_check_type:
    add rsp, 4
    push r0

    add r0, 8
    ; check widget type
    cmp [r0], WIDGET_TYPE_BUTTON
    ifz jmp handle_widget_click_button
    cmp [r0], WIDGET_TYPE_TEXTBOX_SL
    ifz jmp handle_widget_click_textbox_sl
handle_widget_click_done:
    pop r0

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
    push r13
    push r21
    push r22

    ; get button width
    add r0, 16
    movz.16 r10, [r0]

    ; get button height
    add r0, 2
    movz.16 r13, [r0]
    cmp r13, 16
    iflt mov r13, 16

    ; get button X coordinate
    add r0, 2
    movz.16 r11, [r0]

    ; get button Y coordinate
    add r0, 2
    movz.16 r12, [r0]

    ; calculate button's right side coordinate
    mov r21, r11
    add r21, r10

    ; calculate button's bottom right corner coordinate
    mov r22, r12
    add r22, r13

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
    pop r13
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

    ; set active widget pointer
    mov r0, [rsp]
    mov [r30+36], r0

    jmp handle_widget_click_done
handle_widget_click_button_no_click:
    pop r22
    pop r21
    pop r13
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
handle_widget_click_textbox_sl:
    push r0
    push r10
    push r11
    push r12
    push r13
    push r21
    push r22

    ; get textbox width
    add r0, 16
    movz.16 r10, [r0]

    ; get textbox height
    mov r13, TEXTBOX_SL_HEIGHT

    ; get textbox X coordinate
    add r0, 4
    movz.16 r11, [r0]

    ; get textbox Y coordinate
    add r0, 2
    movz.16 r12, [r0]

    ; calculate textbox's right side coordinate
    mov r21, r11
    add r21, r10

    ; calculate textbox's bottom right corner coordinate
    mov r22, r12
    add r22, r13

    ; check if r1 is between r11 and r21
    ; and if r2 is between r12 and r22
    cmp r1, r11
    iflt jmp handle_widget_click_textbox_sl_no_click
    cmp r1, r21
    ifgt jmp handle_widget_click_textbox_sl_no_click
    cmp r2, r12
    iflt jmp handle_widget_click_textbox_sl_no_click
    cmp r2, r22
    ifgt jmp handle_widget_click_textbox_sl_no_click

    ; if we reach this point then the textbox was clicked!!
    pop r22
    pop r21
    pop r13
    pop r12
    pop r11
    pop r10

    ; set active widget pointer
    mov r0, [rsp+4]
    mov [r30+36], r0

    pop r0

    ; redraw the textbox
    mov r10, r0
    mov r0, r30
    call draw_widgets_to_window_textbox_sl

    jmp handle_widget_click_done
handle_widget_click_textbox_sl_no_click:
    pop r22
    pop r21
    pop r13
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

; handle key-down events for the active widget
; inputs:
; r0: pointer to window struct
; r1: key scancode
; outputs:
; none
handle_widget_key_down:
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

    ; get pointer to current widget
    mov r0, [r0+36]
handle_widget_key_down_check_type:
    ; check widget type
    cmp [r0+8], WIDGET_TYPE_TEXTBOX_SL
    ifz jmp handle_widget_key_down_textbox_sl
handle_widget_key_down_done:
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
handle_widget_key_down_textbox_sl:
    ; r0: pointer to textbox widget struct
    ; r1: key scancode
    ; r30: pointer to window struct

    mov r2, [r0+12] ; r2: pointer to text buffer
    movz.16 r3, [r0+26] ; r3: max length of buffer
    push r0
    mov r0, r2
    call string_length
    mov r4, r0 ; r4: current length of text buffer
    pop r0

    cmp.8 r1, KEY_CTRL
    ifz jmp handle_widget_key_down_done
    cmp.8 r1, KEY_LSHIFT
    ifz push handle_widget_key_down_done
    ifz jmp shift_pressed
    cmp.8 r1, KEY_RSHIFT
    ifz push handle_widget_key_down_done
    ifz jmp shift_pressed
    cmp.8 r1, KEY_CAPS
    ifz push handle_widget_key_down_done
    ifz jmp caps_pressed

    ; convert scancode to ascii
    push r0
    mov r0, r1
    call scancode_to_ascii
    mov r1, r0
    pop r0

    ; if this is a backspace, delete a char
    cmp r1, 8
    ifz jmp handle_widget_key_down_textbox_sl_backspace

    ; insert character at the end
    dec r3
    cmp r4, r3
    ifgteq jmp handle_widget_key_down_done
    add r2, r4 ; point to end of text buffer
    mov.8 [r2], r1
    mov.8 [r2+1], 0

    ; redraw the textbox
    mov r10, r0
    add r10, 8
    mov r0, r30
    call draw_widgets_to_window_textbox_sl

    jmp handle_widget_key_down_done
handle_widget_key_down_textbox_sl_backspace:
    ; delete character at the end
    dec r4
    add r2, r4 ; point to end of text buffer
    mov.8 [r2], 0

    ; redraw the textbox
    mov r10, r0
    add r10, 8
    mov r0, r30
    call draw_widgets_to_window_textbox_sl

    jmp handle_widget_key_down_done

; handle key-up events for the active widget
; inputs:
; r0: pointer to window struct
; r1: key scancode
; outputs:
; none
handle_widget_key_up:
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

    ; get pointer to current widget
    mov r0, [r0+36]
handle_widget_key_up_check_type:
    ; check widget type
    cmp [r0+8], WIDGET_TYPE_TEXTBOX_SL
    ifz jmp handle_widget_key_up_textbox_sl
handle_widget_key_up_done:
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
handle_widget_key_up_textbox_sl:
    cmp.8 r1, KEY_LSHIFT
    ifz push handle_widget_key_up_done
    ifz jmp shift_released
    cmp.8 r1, KEY_RSHIFT
    ifz push handle_widget_key_up_done
    ifz jmp shift_released
    cmp.8 r1, KEY_CAPS
    ifz push handle_widget_key_up_done
    ifz jmp caps_pressed

    jmp handle_widget_key_up_done

    ; include widget types
    #include "widget/button.asm"
    #include "widget/label.asm"
    #include "widget/textbox_sl.asm"
