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

    cmp [active_window], 0
    ifz rjmp event_manager_task_loop_end

    ; mouse
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call add_mouse_event_to_active_window
    cmp r0, EVENT_TYPE_MOUSE_RELEASE
    ifz call add_mouse_event_to_active_window

    ; keyboard
    cmp r0, EVENT_TYPE_KEY_DOWN
    ifz call add_event_to_active_window
    cmp r0, EVENT_TYPE_KEY_UP
    ifz call add_event_to_active_window
event_manager_task_loop_end:
    call yield_task
    rjmp event_manager_task_loop
