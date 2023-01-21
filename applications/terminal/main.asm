; terminal

    ; create the window
    mov r0, window_struct
    mov r1, window_title
    mov r2, 320
    mov r3, 400
    mov r4, 32
    mov r5, 32
    mov r6, 0
    mov r7, 0
    call new_window

    ; start an instance of sh.fxf
    call get_unused_task_id
    mov.8 [shell_task_id], r0
    mov r1, stream_struct
    call new_shell_task

event_loop:
    mov r0, window_struct
    call get_next_window_event

    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz jmp mouse_down

    cmp r0, EVENT_TYPE_KEY_DOWN
    ifz jmp key_down

    cmp r0, EVENT_TYPE_KEY_UP
    ifz jmp key_up

event_loop_end:
    movz.8 r0, [shell_task_id]
    call is_task_id_used
    ifz jmp close_window
    call yield_task
    mov.8 [read_buffer], 0
    rjmp event_loop

mouse_down:
    ; check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_window

    jmp event_loop_end

key_down:
    mov r0, r1

    cmp.8 r0, KEY_CTRL
    ifz jmp event_loop_end
    cmp.8 r0, KEY_LSHIFT
    ifz push event_loop_end
    ifz jmp shift_pressed
    cmp.8 r0, KEY_RSHIFT
    ifz push event_loop_end
    ifz jmp shift_pressed
    cmp.8 r0, KEY_CAPS
    ifz push event_loop_end
    ifz jmp caps_pressed

    mov.8 [read_buffer], r0

    jmp event_loop_end

key_up:
    mov r0, r1

    cmp.8 r0, KEY_CTRL
    ifz jmp event_loop_end
    cmp.8 r0, KEY_LSHIFT
    ifz push event_loop_end
    ifz jmp shift_released
    cmp.8 r0, KEY_RSHIFT
    ifz push event_loop_end
    ifz jmp shift_released

    jmp event_loop_end

drag_window:
    cmp r1, 8
    iflteq jmp event_loop_end
    mov r0, window_struct
    call start_dragging_window
    jmp event_loop_end

close_window:
    mov r0, window_struct
    call destroy_window
    call end_current_task
    jmp event_loop_end

window_title: data.str "Terminal" data.8 0
window_struct: data.fill 0, 36

shell_task_id: data.8 0

stream_struct:
    data.8  0x00
    data.16 0x00
    data.32 0x00
    data.8  0x01
    data.32 stream_get_input
    data.32 stream_write_to_terminal

    #include "stream.asm"
    #include "task.asm"
    #include "text.asm"

    ; include system defs
    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
