; about dialog

; show the about dialog
; inputs:
; none
; outputs:
; none
about_dialog:
    ; return if the dialog overlay is already enabled
    in r0, 0x80000300
    cmp r0, 0
    ifnz ret

    ; set overlay position
    mov r0, 64
    mov r1, 64
    mov r2, 0
    call move_overlay

    ; set overlay size
    mov r0, 256
    mov r1, 128
    mov r2, 0
    call resize_overlay

    ; allocate memory for the overlay framebuffer
    mov r0, 131072 ; 256x128x4
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [about_dialog_framebuffer_ptr], r0
    mov r1, 0
    call set_overlay_framebuffer_pointer

    ; fill the overlay with all black
    mov r0, 0xFF000000
    mov r1, 0
    call fill_overlay

    ; enable it!!
    mov r0, 0
    call enable_overlay

about_dialog_event_loop:
    call get_next_event

    ; did the user click the menu bar?
    cmp r0, EVENT_TYPE_MENU_BAR_CLICK
    ifz mov r0, menu_items_root
    ifz call menu_bar_click_event

    ; is the user in a menu?
    cmp r0, EVENT_TYPE_MENU_UPDATE
    ifz call menu_update_event

    ; did the user click a menu item?
    cmp r0, EVENT_TYPE_MENU_CLICK
    ifz call menu_click_event

    call yield_task
    jmp about_dialog_event_loop

about_dialog_framebuffer_ptr: data.32 0
