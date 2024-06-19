; messagebox routines

; create a messagebox at the specified coordinates
; the calling task will not regain control until the user clicks the OK button
; inputs:
; r0: pointer to null-terminated first line string
; r1: pointer to null-terminated second line string
; r2: pointer to null-terminated third line string
; r3: X coordinate
; r4: Y coordinate
; r5: width in pixels
; r6: pointer to destination text buffer
; r7: destination text buffer length
; outputs:
; none
new_inputbox:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7

    push r2
    push r1
    push r0

    ; save the currently active window offset
    mov.8 [inputbox_old_active_window_offset], [active_window_offset]

    ; fill in the textbox widget pointers
    mov r0, inputbox_ok_textbox_sl_widget
    mov [r0+12], r6 ; text buffer
    mov [r0+28], r7 ; buffer size
    mul r7, 8
    mov [r0+24], r7 ; textbox width

    ; create the window
    mov r0, inputbox_window_struct
    mov r1, inputbox_window_title
    mov r2, r5
    mov r5, r4
    mov r4, r3
    mov r3, 72
    mov r6, 0
    mov r7, inputbox_ok_button_widget
    call new_window

    ; fill the window with white and don't redraw the titlebar
    mov r0, inputbox_window_struct
    call get_window_overlay_number
    mov r1, r0
    mov r0, 0xFFFFFFFF
    call fill_overlay

    ; draw the widgets
    mov r0, inputbox_window_struct
    call draw_widgets_to_window

    ; draw the strings
    mov r0, inputbox_window_struct
    call get_window_overlay_number
    mov r5, r0
    pop r0
    mov r1, 8
    mov r2, 8
    mov r3, 0xFF000000
    mov r4, 0xFFFFFFFF
    call draw_str_to_overlay
    pop r0
    mov r1, 8
    add r2, 16
    call draw_str_to_overlay
    pop r0
    mov r1, 8
    add r2, 16
    call draw_str_to_overlay

inputbox_event_loop:
    mov r0, inputbox_window_struct
    call get_next_window_event

    ; was the mouse clicked?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz mov r0, inputbox_window_struct
    ifz push inputbox_event_loop
    ifz jmp handle_widget_click

    ; did the user press a key?
    cmp r0, EVENT_TYPE_KEY_DOWN
    ifz mov r0, inputbox_window_struct
    ifz call handle_widget_key_down
    cmp r0, EVENT_TYPE_KEY_UP
    ifz mov r0, inputbox_window_struct
    ifz call handle_widget_key_up

    ; did the user click a button?
    cmp r0, EVENT_TYPE_BUTTON_CLICK
    ifz jmp inputbox_ok_clicked

    call save_state_and_yield_task
    jmp inputbox_event_loop

inputbox_ok_clicked:
    mov r0, inputbox_window_struct
    call destroy_window

    ; restore the old active window offset
    mov.8 [active_window_offset], [inputbox_old_active_window_offset]

    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

inputbox_window_title: data.strz "Inputbox"
inputbox_window_struct: data.fill 0, 40
inputbox_ok_button_widget:
    data.32 inputbox_ok_textbox_sl_widget ; next_ptr
    data.32 0                        ; id
    data.32 WIDGET_TYPE_BUTTON       ; type
    data.32 messagebox_ok_button_str ; text_ptr
    data.32 0xFFFFFFFF               ; foreground_color
    data.32 0xFF000000               ; background_color
    data.16 32                       ; width
    data.16 0                        ; reserved
    data.16 8                        ; x_pos
    data.16 64                       ; y_pos
inputbox_ok_button_str: data.strz "OK"
inputbox_ok_textbox_sl_widget:
    data.32 0                        ; next_ptr
    data.32 1                        ; id
    data.32 WIDGET_TYPE_TEXTBOX_SL   ; type
    data.32 0                        ; text_ptr
    data.32 0xFF000000               ; foreground_color
    data.32 0xFFAAAAAA               ; background_color
    data.16 0                        ; width
    data.16 0                        ; buffer_max
    data.16 40                       ; x_pos
    data.16 64                       ; y_pos
inputbox_old_active_window_offset: data.8 0
