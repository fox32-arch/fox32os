; about dialog

const BACKGROUND_COLOR: 0xFF674764

; show the about dialog
; inputs:
; none
; outputs:
; none
about_dialog:
    call disable_menu_bar

    ; create the window
    mov r0, about_dialog_window_struct
    mov r1, about_dialog_window_title
    mov r2, 288
    mov r3, 128
    mov r4, 64
    mov r5, 64
    mov r6, 0
    call new_window

    ; fill the window with the fox32 purple color
    mov r0, BACKGROUND_COLOR
    mov r1, about_dialog_window_struct
    call fill_window

    mov r0, about_dialog_window_struct
    call get_window_overlay_number

    ; draw strings
    mov r5, r0
    mov r0, about_dialog_window_launcher_string
    mov r1, 4
    mov r2, 20
    mov r3, 0xFFFFFFFF
    mov r4, BACKGROUND_COLOR
    call draw_str_to_overlay
    call get_os_version
    mov r10, r0
    mov r11, r1
    mov r12, r2
    mov r0, about_dialog_window_os_version_string
    mov r1, 4
    mov r2, 36
    mov r3, 0xFFFFFFFF
    mov r4, BACKGROUND_COLOR
    call draw_format_str_to_overlay
    call get_rom_version
    mov r10, r0
    mov r11, r1
    mov r12, r2
    mov r0, about_dialog_window_rom_version_string
    mov r1, 4
    mov r2, 52
    mov r3, 0xFFFFFFFF
    mov r4, BACKGROUND_COLOR
    call draw_format_str_to_overlay
    mov r0, about_dialog_window_made_by_string_1
    mov r1, 4
    mov r2, 104
    mov r3, 0xFFFFFFFF
    mov r4, BACKGROUND_COLOR
    call draw_str_to_overlay
    mov r0, about_dialog_window_made_by_string_2
    mov r1, 180
    mov r2, 120
    mov r3, 0xFFFFFFFF
    mov r4, BACKGROUND_COLOR
    call draw_str_to_overlay

about_dialog_event_loop:
    mov r0, about_dialog_window_struct
    call get_next_window_event

    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz jmp about_dialog_mouse_down

about_dialog_event_loop_end:
    call yield_task
    rjmp about_dialog_event_loop

about_dialog_mouse_down:
    ; check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp about_dialog_drag_or_close_window

    jmp about_dialog_event_loop_end

about_dialog_drag_or_close_window:
    cmp r1, 8
    iflteq jmp about_dialog_close_window
    mov r0, about_dialog_window_struct
    call start_dragging_window
    jmp about_dialog_event_loop_end
about_dialog_close_window:
    mov r0, about_dialog_window_struct
    call destroy_window
    call enable_menu_bar
    jmp event_loop

about_dialog_window_title: data.str "About" data.8 0
about_dialog_window_struct: data.fill 0, 32

about_dialog_window_launcher_string: data.str "Launcher - the fox32os FXF launcher" data.8 0
about_dialog_window_made_by_string_1: data.str "fox32 - the computer made with love" data.8 0
about_dialog_window_made_by_string_2: data.str "by Ry and Lua" data.8 0
about_dialog_window_os_version_string: data.str "fox32os version %u.%u.%u" data.8 0
about_dialog_window_rom_version_string: data.str "fox32rom version %u.%u.%u" data.8 0
