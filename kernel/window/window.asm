; window management routines

; window struct:
; data.32 framebuffer_ptr    - pointer to this window's framebuffer
; data.32 event_queue_ptr    - current event queue pointer
; data.32 event_queue_bottom - pointer to beginning of this window's event queue
; data.32 title_ptr          - pointer to null-terminated title string
; data.16 width              - width of this window
; data.16 height             - height of this window, not including the title bar
; data.16 x_pos              - X coordinate of this window (top left corner of title bar)
; data.16 y_pos              - Y coordinate of this window (top left corner of title bar)
; data.8  overlay            - overlay number of this window
; data.8  reserved_1
; data.16 reserved_2
; data.32 reserved_3

const WINDOW_STRUCT_SIZE: 32 ; 8 words = 32 bytes
const TITLE_BAR_HEIGHT: 16

; create a new window and allocate memory as required
; inputs:
; r0: pointer to empty 32 byte window struct
; r1: pointer to null-terminated title string
; r2: window width
; r3: window height, not including the title bar
; r4: initial X coordinate (top left corner of title bar)
; r5: initial Y coordinate (top left corner of title bar)
; outputs:
; none
new_window:
    push r1
    push r2
    push r3
    push r4
    push r5
    push r10
    push r11
    push r12

    ; first, set up the initial struct values
    ; title string
    mov r10, r0
    add r10, 12
    mov [r10], r1
    ; window size
    add r10, 4
    mov.16 [r10], r2
    add r10, 2
    mov.16 [r10], r3
    ; window position
    add r10, 2
    mov.16 [r10], r4
    add r10, 2
    mov.16 [r10], r5

    ; then, allocate memory for the framebuffer
    ; the space required is width * (height + TITLE_BAR_HEIGHT) * 4
    mov r10, r2
    mov r11, r3
    add r11, TITLE_BAR_HEIGHT
    mul r10, r11
    mul r10, 4
    push r0
    mov r0, r10
    call allocate_memory
    cmp r0, 0
    ifz jmp memory_error
    mov r10, r0
    pop r0
    mov [r0], r10
    mov r12, r10

    ; then, allocate memory for the event queue
    ; 32 events * 8 entries per event * 4 bytes per word = 1024 bytes
    push r0
    mov r0, 1024
    call allocate_memory
    cmp r0, 0
    ifz jmp memory_error
    mov r11, r0
    pop r0
    mov r10, r0
    add r10, 8
    mov [r10], r11
    sub r10, 4
    mov [r10], r11

    ; then, find an overlay to use for this window
    push r0
    call get_unused_overlay
    mov r11, r0
    pop r0
    mov r10, r0
    add r10, 24
    mov.8 [r10], r11

    ; then, set the properties of the overlay
    push r0
    push r1
    push r2
    mov r0, r4
    mov r1, r5
    mov r2, r11
    call move_overlay
    pop r2
    pop r1
    mov r0, r2
    mov r1, r3
    add r1, TITLE_BAR_HEIGHT
    mov r2, r11
    call resize_overlay
    mov r0, r12
    mov r1, r11
    call set_overlay_framebuffer_pointer
    mov r0, r11
    call enable_overlay
    mov r0, 0xFF000000
    mov r1, r11
    call fill_overlay
    pop r0

    ; then, draw the title bar
    call draw_title_bar_to_window

    ; finally, add this window to the window list
    push r0
    mov r0, 0x00000000
    call search_for_window_list_entry
    mov.8 [active_window_offset], r0
    mul r0, 4
    add r0, window_list
    pop r1
    mov [r0], r1

    pop r12
    pop r11
    pop r10
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    ret

; destroy a window and free memory used by it
; note that this does not free the memory used by the window struct itself
; inputs:
; r0: pointer to window struct
; outputs:
; none
destroy_window:
    push r0
    push r1

    mov r1, r0

    ; free framebuffer memory
    mov r0, [r1]
    call free_memory

    ; free event queue memory
    add r1, 8
    mov r0, [r1]
    call free_memory

    ; disable the window's overlay
    add r1, 16
    movz.8 r0, [r1]
    call disable_overlay

    ; remove the window from the window list
    sub r1, 24
    mov r0, r1
    call search_for_window_list_entry
    mul r0, 4
    add r0, window_list
    mov [r0], 0

    ; set the active window to whatever entry is found first
    call search_for_nonempty_window_list_entry
    mov.8 [active_window_offset], r0

    pop r1
    pop r0
    ret

; call this if the user clicks on a window's title bar
; inputs:
; r0: pointer to window struct
; outputs:
; none
start_dragging_window:
    push r0
    push r1
    push r2
    push r4

    mov r2, r0
    mov r4, r0
    add r4, 16
    movz.16 r4, [r4]
    div r4, 2
start_dragging_window_loop:
    call get_mouse_position
    sub r0, r4
    sub r1, 8
    call move_window

    call get_mouse_button
    bts r0, 2
    ifnz jmp start_dragging_window_loop

    pop r4
    pop r2
    pop r1
    pop r0
    ret

; move a window
; r0: X position
; r1: Y position
; r2: pointer to window struct
move_window:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    ; prevent windows from being moved off-screen
    add r2, 16
    movz.16 r3, [r2]
    add r2, 2
    movz.16 r4, [r2]
    mov r5, 640
    mov r6, 480
    sub r5, r3
    sub r6, r4

    cmp r0, 0x80000000
    ifgt mov r0, 0
    cmp r1, 0x80000000
    ifgt mov r1, 0

    cmp r0, r5
    ifgt mov r0, r5
    cmp r1, r6
    ifgt mov r1, r6

    ; move the window
    add r2, 2
    mov.16 [r2], r0
    add r2, 2
    mov.16 [r2], r1
    add r2, 2
    movz.8 r2, [r2]
    call move_overlay

    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

; swap two windows
; inputs:
; r0: pointer to window struct
; r1: pointer to window struct
; outputs:
; none
swap_windows:
    push r0
    push r1
    push r2
    push r3

    mov r2, r0
    mov r3, r1

    add r2, 24
    movz.8 r0, [r2]
    add r3, 24
    movz.8 r1, [r3]
    call swap_overlays
    movz.8 [r2], r1
    movz.8 [r3], r0

    pop r3
    pop r2
    pop r1
    pop r0
    ret

; fill a whole window with a color
; inputs:
; r0: color
; r1: pointer to window struct
; outputs:
; none
fill_window:
    push r1
    push r2

    mov r2, r1

    add r1, 24
    movz.8 r1, [r1]
    call fill_overlay

    mov r0, r2
    call draw_title_bar_to_window

    pop r2
    pop r1
    ret

; get the overlay used by a window
; DO NOT CACHE THIS VALUE, it can change any time the window order changes
; inputs:
; r0: pointer to window struct
; outputs:
; r0: overlay number
get_window_overlay_number:
    add r0, 24
    movz.8 r0, [r0]

    ret

; draw a window's title bar
; inputs:
; r0: pointer to window struct
; outputs:
; none
draw_title_bar_to_window:
    push r0
    push r3
    push r4
    push r10
    push r11
    push r12
    push r31

    ; get the title string
    add r0, 12
    mov r12, [r0]

    ; get the width of this window
    add r0, 4
    movz.16 r11, [r0]

    ; get overlay number of this window
    add r0, 8
    movz.8 r10, [r0]

    ; save the old tilemap
    call get_tilemap
    push r0
    push r1
    push r2

    ; set the tilemap to our 1x16 tile patterns
    mov r0, window_title_bar_patterns
    mov r1, 1
    mov r2, 16
    call set_tilemap

    mov r1, 0
    mov r2, 0
    mov r3, r10
    mov r31, r11
draw_title_bar_to_window_loop:
    mov r4, r31
    rem r4, 2
    cmp r4, 0
    ifz mov r0, 0
    ifnz mov r0, 1
    call draw_tile_to_overlay
    inc r1
    loop draw_title_bar_to_window_loop

    ; restore the old tilemap
    pop r2
    pop r1
    pop r0
    call set_tilemap

    ; draw the title text
    mov r0, r12
    mov r1, 8
    mov r2, 0
    mov r3, 0xFF000000
    mov r4, 0xFFFFFFFF
    mov r5, r10
    call draw_str_to_overlay

    ; draw the close button
    mov r0, 1
    mov r1, 4
    mov r2, 6
    mov r3, 8
    mov r4, 0xFFFFFFFF
    mov r5, r10
    call draw_filled_rectangle_to_overlay
    mov r0, 2
    mov r1, 5
    mov r2, 4
    mov r3, 6
    mov r4, 0xFF000000
    mov r5, r10
    call draw_filled_rectangle_to_overlay

    pop r31
    pop r12
    pop r11
    pop r10
    pop r4
    pop r3
    pop r0
    ret

; add an event to the active window
; inputs:
; r0-r7: event
; outputs:
; none
add_event_to_active_window:
    push r0
    movz.8 r0, [active_window_offset]
    call window_list_offset_to_struct
    mov r8, r0
    pop r0
    call new_window_event

    ret

; add a mouse event to the active window if the mouse was clicked inside the active window
; if so, automatically convert the X and Y coords to be relative to the window
; inputs:
; r0-r7: event
; outputs:
; none
add_mouse_event_to_active_window:
    push r0
    push r2
    push r10
    push r11
    push r12

    ; save X and Y coords of the click and the event type
    mov r10, r1
    mov r11, r2
    mov r12, r0

    ; get the window's overlay number
    movz.8 r0, [active_window_offset]
    call window_list_offset_to_struct
    call get_window_overlay_number

    ; check if the window's overlay covers the clicked position
    mov r2, r0
    mov r0, r10
    mov r1, r11
    call check_if_overlay_covers_position
    ; if it doesn't, then end here
    ifnz jmp add_mouse_event_to_active_window_end
    ; if it does, then make the X and Y coords relative to the overlay
    call make_coordinates_relative_to_overlay

    ; add the event
    mov r2, r1
    mov r1, r0
    mov r0, r12
    call add_event_to_active_window
add_mouse_event_to_active_window_end:
    pop r12
    pop r11
    pop r10
    pop r2
    pop r0
    ret

; search for an entry in the window list
; inputs:
; r0: entry (pointer to window struct)
; outputs:
; r0: window list offset, or 0xFFFFFFFF if not found
search_for_window_list_entry:
    push r1
    push r2
    push r31

    mov r1, window_list
    mov r2, 0
    mov r31, 31
search_for_window_list_entry_loop:
    cmp [r1], r0
    ifz jmp search_for_window_list_entry_found
    inc r2
    add r1, 4
    loop search_for_window_list_entry_loop
    ; not found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF

    pop r31
    pop r2
    pop r1
    ret
search_for_window_list_entry_found:
    ; found the entry, return its offset
    mov r0, r2

    pop r31
    pop r2
    pop r1
    ret

; search for the first non-empty entry in the window list
; inputs:
; none
; outputs:
; r0: window list offset, or 0xFFFFFFFF if not found
search_for_nonempty_window_list_entry:
    push r1
    push r2
    push r31

    mov r1, window_list
    mov r2, 0
    mov r31, 31
search_for_nonempty_window_list_entry_loop:
    cmp [r1], 0
    ifnz jmp search_for_nonempty_window_list_entry_found
    inc r2
    add r1, 4
    loop search_for_nonempty_window_list_entry_loop
    ; not found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF

    pop r31
    pop r2
    pop r1
    ret
search_for_nonempty_window_list_entry_found:
    ; found the entry, return its offset
    mov r0, r2

    pop r31
    pop r2
    pop r1
    ret

; given an overlay number, get the window struct of the window associated with that overlay
; inputs:
; r0: overlay number
; outputs:
; r0: pointer to window struct, or 0x00000000 if not found
get_window_with_overlay:
    push r1
    push r2
    push r3
    push r31

    mov r1, window_list
    mov r31, 31
get_window_with_overlay_loop:
    mov r2, [r1]
    add r2, 24
    cmp.8 [r2], r0
    ifz jmp get_window_with_overlay_found
    add r1, 4
    loop get_window_with_overlay_loop
    ; not found, return 0
    mov r0, 0

    pop r31
    pop r3
    pop r2
    pop r1
    ret
get_window_with_overlay_found:
    ; found the entry, return the pointer to its struct
    mov r0, [r1]

    pop r31
    pop r3
    pop r2
    pop r1
    ret

; get a window struct pointer from the window list
; inputs:
; r0: window list offset
; outputs:
; r0: pointer to window struct
window_list_offset_to_struct:
    mul r0, 4
    add r0, window_list
    mov r0, [r0]
    ret

window_title_bar_patterns:
    ; 1x16 tile
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF

    ; 1x16 tile
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000
    data.32 0xFFFFFFFF
    data.32 0x00000000

active_window_offset: data.8 0xFF
window_list: data.fill 0, 124 ; 31 window structs * 4 bytes each

    #include "window/event.asm"
    #include "window/event_manager_task.asm"
    #include "window/overlay.asm"
