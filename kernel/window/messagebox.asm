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
; outputs:
; none
new_messagebox:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5

    push r2
    push r1
    push r0

    ; save the currently active window offset
    mov.8 [messagebox_old_active_window_offset], [active_window_offset]

    ; create the window
    mov r0, messagebox_window_struct
    mov r1, messagebox_window_title
    mov r2, r5
    mov r5, r4
    mov r4, r3
    mov r3, 72
    mov r6, 0
    mov r7, messagebox_ok_button_widget
    call new_window

    ; fill the window with white and don't redraw the titlebar
    mov r0, messagebox_window_struct
    call get_window_overlay_number
    mov r1, r0
    mov r0, 0xFFFFFFFF
    call fill_overlay

    ; draw the button widget
    mov r0, messagebox_window_struct
    call draw_widgets_to_window

    ; draw the strings
    mov r0, messagebox_window_struct
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

messagebox_event_loop:
    mov r0, messagebox_window_struct
    call get_next_window_event

    ; was the mouse clicked?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz mov r0, messagebox_window_struct
    ifz push messagebox_event_loop
    ifz jmp handle_widget_click

    ; did the user click a button?
    cmp r0, EVENT_TYPE_BUTTON_CLICK
    ifz jmp messagebox_ok_clicked

    call save_state_and_yield_task
    jmp messagebox_event_loop

messagebox_ok_clicked:
    mov r0, messagebox_window_struct
    call destroy_window

    ; restore the old active window offset
    mov.8 [active_window_offset], [messagebox_old_active_window_offset]

    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

messagebox_window_title: data.strz "Messagebox"
messagebox_window_struct: data.fill 0, 40
messagebox_ok_button_widget:
    data.32 0                        ; next_ptr
    data.32 0                        ; id
    data.32 WIDGET_TYPE_BUTTON       ; type
    data.32 messagebox_ok_button_str ; text_ptr
    data.32 0xFFFFFFFF               ; foreground_color
    data.32 0xFF000000               ; background_color
    data.16 32                       ; width
    data.16 0                        ; reserved
    data.16 8                        ; x_pos
    data.16 64                       ; y_pos
messagebox_ok_button_str: data.strz "OK"
messagebox_old_active_window_offset: data.8 0
