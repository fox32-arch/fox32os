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
; data.16 flags              - flags for this window
; data.32 menu_bar_ptr       - pointer to this window's menu bar root struct, or 0 for none
; data.32 first_widget_ptr   - pointer to this window's first widget
; data.32 active_widget_ptr  - pointer to the currently active widget

const WINDOW_STRUCT_SIZE: 40 ; 10 words = 40 bytes
const TITLE_BAR_HEIGHT: 16
const TITLE_BAR_TEXT_FOREGROUND: 0xFF000000
const TITLE_BAR_TEXT_BACKGROUND: 0xFFFFFFFF
const WINDOW_FLAG_ALWAYS_BACKGROUND: 1
const WINDOW_FLAG_CREATED_FROM_RES:  32768

; create a new window and allocate memory as required
; inputs:
; r0: pointer to empty 40 byte window struct
; r1: pointer to null-terminated title string
; r2: window width
; r3: window height, not including the title bar
; r4: initial X coordinate (top left corner of title bar)
; r5: initial Y coordinate (top left corner of title bar)
; r6: pointer to menu bar root struct, or 0x00000000 for no menu bar
; r7: pointer to first widget, or 0x00000000 for no widgets
; outputs:
; none
new_window:
    push r0
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
    ; menu bar root struct pointer
    add r10, 6
    mov [r10], r6
    ; first widget pointer
    add r10, 4
    mov [r10], r7
    ; active widget pointer
    add r10, 4
    mov [r10], 0

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
    mov r0, 0xFFFFFFFF
    mov r1, r11
    call fill_overlay
    pop r0

    ; then, draw the title bar
    call draw_title_bar_to_window

    ; then, draw the menu bar
    push r0
    call enable_menu_bar
    mov r0, r6
    call clear_menu_bar
    mov r1, 0xFFFFFFFF
    cmp r0, 0
    ifnz call draw_menu_bar_root_items
    pop r0

    ; if the current active window is on a higher overlay, swap
    push r0
    call get_window_overlay_number ; get the overlay number of the new window
    mov r10, r0
    mov.8 r0, [active_window_offset] ; get the active window's overlay number
    cmp r0, 0xFF ; is there no active window?
    ifnz jmp new_window_active_window
    pop r0
    jmp new_window_skip_swap
new_window_active_window:
    mul r0, 4
    add r0, window_list
    mov r1, [r0]
    mov r0, r1
    call get_window_overlay_number
    mov r11, r0
    pop r0
    cmp r11, r10 ; if the active window is on a higher overlay, swap
    ifnc call swap_windows
new_window_skip_swap:

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
    pop r0
    ret

; create a new window and draw its contents from a resource file loaded in memory
; inputs:
; r0: pointer to empty 40 byte window struct
; r1: pointer to memory buffer containing a RES binary
; outputs:
; none
;
; WIN resource layout (40 bytes):
;    data.fill 0, 32 - null-terminated window title
;    data.16 width   - width of this window
;    data.16 height  - height of this window, not including the title bar
;    data.16 x_pos   - X coordinate of this window (top left corner of title bar)
;    data.16 y_pos   - Y coordinate of this window (top left corner of title bar)
new_window_from_resource:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8

    push r0
    mov r8, r1

    ; get the WIN resource
    mov r0, r8
    mov r1, new_window_from_resource_win_str
    mov r2, 40
    call get_resource
    mov [new_window_from_resource_win_ptr], r0

    ; get the MNU resource
    mov r0, r8
    mov r1, new_window_from_resource_mnu_str
    mov r2, 16384 ; set the max size
    call get_resource
    mov [new_window_from_resource_mnu_ptr], r0

    ; get the WID resource
    mov r0, r8
    mov r1, new_window_from_resource_wid_str
    mov r2, 16384 ; set the max size
    call get_resource
    mov [new_window_from_resource_wid_ptr], r0

    ; create the window
    pop r0
    mov r8, [new_window_from_resource_win_ptr]
    mov r1, r8 ; first 32 bytes are the window title
    movz.16 r2, [r8+32] ; width
    movz.16 r3, [r8+34] ; height
    movz.16 r4, [r8+36] ; x_pos
    movz.16 r5, [r8+38] ; y_pos
    mov r6, [new_window_from_resource_mnu_ptr]
    mov r7, [new_window_from_resource_wid_ptr]
    call new_window

    ; set the flag that tells `destroy_window` to free our allocations
    mov r1, r0
    mov r0, WINDOW_FLAG_CREATED_FROM_RES
    call set_window_flags

    ; draw the window's widgets
    mov r0, r1
    call draw_widgets_to_window

    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret
new_window_from_resource_win_str: data.strz "WIN"
new_window_from_resource_win_ptr: data.32 0
new_window_from_resource_mnu_str: data.strz "MNU"
new_window_from_resource_mnu_ptr: data.32 0
new_window_from_resource_wid_str: data.strz "WID"
new_window_from_resource_wid_ptr: data.32 0

; destroy a window and free memory used by it
; note that this does not free the memory used by the window struct itself
; inputs:
; r0: pointer to window struct
; outputs:
; none
destroy_window:
    push r0
    push r1
    push r2

    mov r2, r0

    ; remove the window from the window list
    call search_for_window_list_entry
    mul r0, 4
    add r0, window_list
    mov [r0], 0

    ; set the active window to whatever entry is found first
    call search_for_nonempty_window_list_entry
    mov.8 [active_window_offset], r0
    cmp r0, 0xFFFFFFFF
    ifz jmp destroy_window_no_more_windows

    ; swap newly active window with the window about to be destroyed
    call window_list_offset_to_struct
    mov r1, r2
    call swap_windows

    ; set the menu bar for the newly active window
    mov r0, r2
    call get_window_menu_bar_root_struct
    call enable_menu_bar
    call clear_menu_bar
    mov r1, 0xFFFFFFFF
    cmp r0, 0
    ifnz call draw_menu_bar_root_items
destroy_window_no_more_windows:
    ; if this window was created from a RES, free the resource data
    movz.16 r0, [r2+26]
    and r0, WINDOW_FLAG_CREATED_FROM_RES
    cmp r0, 0
    ifz jmp destroy_window_not_res

    ; free WIN resource
    mov r0, [r2+12]
    cmp r0, 0
    ifnz call free_memory

    ; free MNU resource
    mov r0, [r2+28]
    cmp r0, 0
    ifnz call free_memory

    ; free WID resource
    mov r0, [r2+32]
    cmp r0, 0
    ifnz call free_memory
destroy_window_not_res:
    ; free framebuffer memory
    mov r0, [r2]
    call free_memory

    ; free event queue memory
    add r2, 8
    mov r0, [r2]
    call free_memory

    ; disable the window's overlay
    add r2, 16
    movz.8 r0, [r2]
    call disable_overlay

    pop r2
    pop r1
    pop r0
    ret

; call this if the user clicks on a window's title bar
; inputs:
; r0: 16-bit flags value
; r1: pointer to window struct
; outputs:
; none
set_window_flags:
    push r1

    add r1, 26
    mov.16 [r1], r0

    pop r1
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
    push r5

    mov r2, r0
    mov r4, r0
    mov r5, r0
    add r4, 20
    add r5, 22
    movz.16 r4, [r4]
    movz.16 r5, [r5]
    call get_mouse_position
    sub r0, r4
    sub r1, r5
    mov r4, r0
    mov r5, r1
start_dragging_window_loop:
    call get_mouse_position
    sub r0, r4
    sub r1, r5
    call move_window

    call get_mouse_button
    bts r0, 2
    ifnz jmp start_dragging_window_loop

    pop r5
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

; get the menu bar root struct used by a window
; inputs:
; r0: pointer to window struct
; outputs:
; r0: pointer to menu bar root struct, or 0x00000000 for no menu bar
get_window_menu_bar_root_struct:
    add r0, 28
    mov r0, [r0]

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
    mov r3, TITLE_BAR_TEXT_FOREGROUND
    mov r4, TITLE_BAR_TEXT_BACKGROUND
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

; add a mouse event to an inactive window if the mouse was clicked inside the window
; if so, automatically convert the X and Y coords to be relative to the window
; inputs:
; r0-r7: event
; r8: pointer to window struct
; outputs:
; none
add_mouse_event_to_inactive_window:
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
    mov r0, r8
    call get_window_overlay_number

    ; check if the window's overlay covers the clicked position
    mov r2, r0
    mov r0, r10
    mov r1, r11
    call check_if_overlay_covers_position
    ; if it doesn't, then end here
    ifnz jmp add_mouse_event_to_inactive_window_end
    ; if it does, then make the X and Y coords relative to the overlay
    call make_coordinates_relative_to_overlay

    ; add the event
    mov r2, r1
    mov r1, r0
    mov r0, r12
    call new_window_event
add_mouse_event_to_inactive_window_end:
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
; this skips over items that have the "always background" flag set
; inputs:
; none
; outputs:
; r0: window list offset, or 0xFFFFFFFF if not found
search_for_nonempty_window_list_entry:
    push r1
    push r2
    push r3
    push r31

    mov r1, window_list
    mov r2, 0
    mov r31, 31
search_for_nonempty_window_list_entry_loop:
    cmp [r1], 0
    ifz jmp search_for_nonempty_window_list_entry_loop_skip
    mov r3, [r1]
    add r3, 26
    movz.16 r3, [r3]
    and r3, WINDOW_FLAG_ALWAYS_BACKGROUND
    cmp r3, 0
    ifz jmp search_for_nonempty_window_list_entry_found
search_for_nonempty_window_list_entry_loop_skip:
    inc r2
    add r1, 4
    loop search_for_nonempty_window_list_entry_loop
    ; not found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF

    pop r31
    pop r3
    pop r2
    pop r1
    ret
search_for_nonempty_window_list_entry_found:
    ; found the entry, return its offset
    mov r0, r2

    pop r31
    pop r3
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

; get a pointer to the active window struct
; inputs:
; none
; outputs:
; r0: pointer to current window struct, or zero if none
get_active_window_struct:
    movz.8 r0, [active_window_offset]
    cmp.8 r0, 0xFF
    ifz mov r0, 0
    ifz ret
    call window_list_offset_to_struct
    ret

window_title_bar_patterns:
    ; 1x16 tile
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND

    ; 1x16 tile
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000
    data.32 TITLE_BAR_TEXT_BACKGROUND
    data.32 0x00000000

active_window_offset: data.8 0xFF
window_list: data.fill 0, 124 ; 31 window structs * 4 bytes each

    #include "window/event.asm"
    #include "window/event_manager_task.asm"
    #include "window/messagebox.asm"
    #include "window/overlay.asm"
