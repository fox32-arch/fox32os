; pride flags :3

    opton

    mov r0, window_struct
    mov r1, window_title
    mov r2, 256
    mov r3, 125
    mov r4, 64
    mov r5, 64
    mov r6, 0
    mov r7, 0
    call new_window

    mov r0, window_struct
    call get_window_overlay_number
    mov r5, r0
    mov r0, 0
    mov r1, 16
    mov r2, 256
    mov r3, 25
    mov r4, 0xFFFACE5B
    call draw_filled_rectangle_to_overlay
    add r1, 25
    mov r4, 0xFFB8A9F5
    call draw_filled_rectangle_to_overlay
    add r1, 25
    mov r4, 0xFFFFFFFF
    call draw_filled_rectangle_to_overlay
    add r1, 25
    mov r4, 0xFFB8A9F5
    call draw_filled_rectangle_to_overlay
    add r1, 25
    mov r4, 0xFFFACE5B
    call draw_filled_rectangle_to_overlay

event_loop:
    mov r0, window_struct
    call get_next_window_event

    ; did the user click somewhere in the window?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call mouse_click_event

    call yield_task
    rjmp event_loop

mouse_click_event:
    push r0

    ; check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_or_close_window

    pop r0
    ret

drag_or_close_window:
    cmp r1, 8
    iflteq jmp close_window
    mov r0, window_struct
    call start_dragging_window
    pop r0
    ret
close_window:
    mov r0, window_struct
    call destroy_window
    call end_current_task

window_title: data.strz "Trans Pride!"
window_struct: data.fill 0, 40

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
