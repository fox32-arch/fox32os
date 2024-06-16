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

    ; mouse
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call event_manager_task_mouse_event
    cmp r0, EVENT_TYPE_MOUSE_RELEASE
    ifz call event_manager_task_mouse_event

    cmp.8 [active_window_offset], 0xFF
    ifz rjmp event_manager_task_loop_end

    ; menu bar
    cmp r0, EVENT_TYPE_MENU_BAR_CLICK
    ifz call add_event_to_active_window
    cmp r0, EVENT_TYPE_MENU_CLICK
    ifz call add_event_to_active_window
    cmp r0, EVENT_TYPE_MENU_ACK
    ifz call add_event_to_active_window
    cmp r0, EVENT_TYPE_MENU_UPDATE
    ifz call add_event_to_active_window

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

    ; if a menu is open, don't continue
    ; this is hacky as fuck
    push r0
    in r0, 0x8000031D ; overlay 29: enable status
    cmp r0, 0
    ifnz pop r0
    ifnz pop r2
    ifnz pop r1
    ifnz pop r0
    ifnz ret
    pop r0

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
    cmp.8 r0, 0xFF
    ifz pop r1
    ifz jmp event_manager_task_mouse_event_inactive_window_was_clicked
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

    ; r0: currently active window struct
    ; r1: clicked window struct

    ; give up if a window was not found for the clicked overlay
    cmp r1, 0x00000000
    ifz pop r2
    ifz pop r1
    ifz pop r0
    ifz ret

    ; if there is no active window, but we reached this point,
    ; then assume the click was on an inactive window marked as "always background"
    ; it's probably bad to assume this, more checks would be good
    cmp r0, 0x00000000
    ifz jmp event_manager_task_mouse_event_inactive_window_was_clicked_no_change

    ; swap the two, if the "always background" flag is not set for the clicked window
    push r1
    add r1, 26
    movz.16 r1, [r1]
    and r1, WINDOW_FLAG_ALWAYS_BACKGROUND
    cmp r1, 0
    pop r1
    ifnz jmp event_manager_task_mouse_event_inactive_window_was_clicked_no_change
    call swap_windows

    ; mark the clicked window as the active window
    mov r0, r1
    call search_for_window_list_entry
    mov.8 [active_window_offset], r0

    ; set the menu bar for the newly active window
    call window_list_offset_to_struct
    call get_window_menu_bar_root_struct
    call enable_menu_bar
    call clear_menu_bar
    mov r1, 0xFFFFFFFF
    cmp r0, 0
    ifnz call draw_menu_bar_root_items

    pop r2
    pop r1
    pop r0
    call add_mouse_event_to_active_window
    ret
event_manager_task_mouse_event_inactive_window_was_clicked_no_change:
    mov [old_r8], r8
    mov r8, r1
    pop r2
    pop r1
    pop r0
    call add_mouse_event_to_inactive_window
    mov r8, [old_r8]
    ret
old_r8: data.32 0
