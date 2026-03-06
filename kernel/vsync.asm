; vsync interrupt routine

kernel_vsync_handler:
    cmp [cursor_change_counter], 1
    ifz rjmp kernel_vsync_handler_reset_cursor
    cmp [cursor_change_counter], 0
    ifnz dec [cursor_change_counter]
    jmp system_vsync_handler
kernel_vsync_handler_reset_cursor:
    call set_default_cursor
    jmp system_vsync_handler

cursor_change_counter: data.32 0
