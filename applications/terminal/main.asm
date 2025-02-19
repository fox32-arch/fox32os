; terminal

    opton

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

    ; fill the window with the "black" color
    mov r0, [colors]
    mov r1, window_struct
    call fill_window

    ; start an instance of sh.fxf
    call get_boot_disk_id
    mov r1, r0
    mov r0, sh_fxf_name
    mov r2, stream_struct
    mov r3, 0
    mov r4, 0
    mov r5, 0
    mov r6, 0
    call launch_fxf_from_disk
    cmp r0, 0xFFFFFFFF
    ifz jmp sh_fxf_missing
    mov.8 [shell_task_id], r0

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
    cmp.8 [read_buffer_ack], 1
    ifz mov.8 [read_buffer], 0
    ifz mov.8 [read_buffer_ack], 0
    rjmp event_loop

mouse_down:
    ; check if we are attempting to drag or close the window
    cmp r2, 16
    iflt jmp drag_window

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

    call scancode_to_ascii
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
    iflt jmp close_window
    mov r0, window_struct
    call start_dragging_window
    jmp event_loop_end

close_window:
    mov r0, window_struct
    call destroy_window
    call end_current_task
    jmp event_loop_end

sh_fxf_missing:
    mov r0, sh_fxf_missing_str
    call print_str_to_terminal
sh_fxf_missing_yield_loop:
    call yield_task
    rjmp sh_fxf_missing_yield_loop

window_title: data.strz "Terminal"
window_struct: data.fill 0, 40

sh_fxf_name: data.strz "/system/sh.fxf"
sh_fxf_missing_str: data.str "sh could not be launched! hanging here" data.8 10 data.8 0

shell_task_id: data.8 0

stream_struct:
    data.8  0x00
    data.16 0x0000
    data.32 0x00000000
    data.8  0x01
    data.32 stream_get_input
    data.32 stream_write_to_terminal
    data.32 0x00000000
    data.32 0x00000000
    data.32 0x00000000
    data.32 0x00000000

    #include "stream.asm"
    #include "text.asm"

    ; include system defs
    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
