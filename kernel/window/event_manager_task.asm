; task that manages window events

; start a task which handles passing system events into the correct window event queue
; inputs:
; none
; outputs:
; none
start_event_manager_task:
    ; allocate 256 bytes for the stack
    mov r0, 256
    call allocate_memory
    add r0, 256                     ; add 256 so the stach pointer is at the end of the stack block (stack grows down)
    mov r10, r0

    ; then start the task
    call get_unused_task_id
    mov r1, event_manager_task_loop ; initial instruction pointer
    mov r2, r10                     ; initial stack pointer
    mov r3, 0                       ; pointer to task code block to free when task ends
                                    ; (zero since we don't want to free any code blocks when the task ends)
    mov r4, r10                     ; pointer to task stack block to free when task ends
    sub r4, 256                     ; point to the start of the stack block that we allocated above
    call new_task

    ret

event_manager_task_loop:
    call get_next_event

    ; HACK: put menu bar events back into the system event queue
    cmp r0, EVENT_TYPE_MENU_BAR_CLICK
    ifz call new_event
    cmp r0, EVENT_TYPE_MENU_CLICK
    ifz call new_event
    cmp r0, EVENT_TYPE_MENU_UPDATE
    ifz call new_event

    cmp.8 [active_window_offset], 0xFF
    ifz rjmp event_manager_task_loop_end

    ; mouse
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call event_manager_task_mouse_event
    cmp r0, EVENT_TYPE_MOUSE_RELEASE
    ifz call event_manager_task_mouse_event

    ; keyboard
    cmp r0, EVENT_TYPE_KEY_DOWN
    ifz call add_event_to_active_window
    cmp r0, EVENT_TYPE_KEY_UP
    ifz call add_event_to_active_window
event_manager_task_loop_end:
    call yield_task
    rjmp event_manager_task_loop

event_manager_task_mouse_event:
    push r0
    push r1
    push r2

    ; find which overlay was clicked on
    mov r0, r1
    mov r1, r2
    call find_overlay_convering_position
    cmp r0, 0xFFFFFFFF
    ifz pop r2
    ifz pop r1
    ifz pop r0
    ifz ret
    push r0

    ; get the overlay number of the active window
    movz.8 r0, [active_window_offset]
    call window_list_offset_to_struct
    call get_window_overlay_number

    ; check if the click was inside the active window
    ; otherwise, activate the clicked window
    pop r1
    cmp r0, r1
    ifnz jmp event_manager_task_mouse_event_inactive_window_was_clicked

    pop r2
    pop r1
    pop r0
    call add_mouse_event_to_active_window
    ret
event_manager_task_mouse_event_inactive_window_was_clicked:
    mov r2, r1
    mov r1, r0
    mov r0, r2

    ; r0: clicked window overlay number
    ; r1: currently active window overlay number

    ; get the window structs of the two windows
    call get_window_with_overlay
    mov r2, r0
    mov r0, r1
    call get_window_with_overlay
    mov r1, r2

    ; give up if a window was not found for this overlay
    cmp r0, 0x00000000
    ifz pop r2
    ifz pop r1
    ifz pop r0
    ifz ret
    cmp r1, 0x00000000
    ifz pop r2
    ifz pop r1
    ifz pop r0
    ifz ret

    ; swap the two
    call swap_windows

    ; mark the clicked window as the active window
    mov r0, r1
    call search_for_window_list_entry
    mov.8 [active_window_offset], r0

    pop r2
    pop r1
    pop r0
    ret
