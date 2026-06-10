; pride flags :3

    #include "../gui_app.inc"
app_name: data.strz "Pride Flags" ; max 12 chars
app_desc: data.strz "LGBTQIA+ Pride Flags" ; max 50 chars
app_author: data.strz "fox32 contributors (github.com/fox32-arch)" ; max 50 chars
app_version: data.strz "0.0.0" ; max 8 chars
app_icon:
    #include "icon.inc"

    opton
app_entry:
    mov r0, window_struct
    mov r1, window_title
    mov r2, 256
    mov r3, 125
    mov r4, 64
    mov r5, 64
    mov r6, menu_items_root
    mov r7, 0
    call new_window

    mov r0, trans_flag
    call draw_flag

event_loop:
    mov r0, window_struct
    call get_next_window_event

    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call mouse_click_event

    cmp r0, EVENT_TYPE_MENU_BAR_CLICK
    ifz mov r0, menu_items_root
    ifz call menu_bar_click_event

    cmp r0, EVENT_TYPE_MENU_UPDATE
    ifz call menu_update_event

    cmp r0, EVENT_TYPE_MENU_CLICK
    ifz jmp menu_click_event

    cmp r0, EVENT_TYPE_MENU_ACK
    ifz jmp menu_ack_event
event_loop_end:
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
    call app_exit

menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; flag
    cmp r2, 0
    ifz call flag_menu_click_event

    jmp event_loop_end

menu_ack_event:
    mov r0, menu_items_root
    call close_menu

    jmp event_loop_end

flag_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; rainbow
    cmp r3, 0
    ifz push event_loop_end
    ifz mov r0, rainbow_flag
    ifz jmp draw_flag

    ; transgender
    cmp r3, 1
    ifz push event_loop_end
    ifz mov r0, trans_flag
    ifz jmp draw_flag

    jmp event_loop_end

; inputs:
; r0: pointer to flag struct
draw_flag:
    movz.8 r31, [r0]
    inc r0
    push r0
    mov r0, 0
    mov r1, window_struct
    call fill_window
    mov r0, window_struct
    call get_window_overlay_number
    mov r5, r0
    pop r0
draw_flag_loop:
    push r0
    movz.16 r1, [r0+2]
    movz.16 r2, [r0+4]
    movz.16 r3, [r0+6]
    mov r4, [r0+8]
    movz.16 r0, [r0]
    call draw_filled_rectangle_to_overlay
    pop r0
    add r0, 12
    rloop draw_flag_loop
    ret

window_title: data.strz "Queer Pride!"
window_struct: data.fill 0, 40

menu_items_root:
    data.8 1                                                  ; number of menus
    data.32 menu_items_flag_list data.32 menu_items_flag_name ; pointer to menu list, pointer to menu name
menu_items_flag_name:
    data.8 6 data.strz "Flag" ; text length, text, null-terminator
menu_items_flag_list:
    data.8 2                          ; number of items
    data.8 13                         ; menu width (usually longest item + 2)
    data.8 7  data.strz "Rainbow"     ; text length, text, null-terminator
    data.8 11 data.strz "Transgender" ; text length, text, null-terminator

    #include "flags/rainbow.asm"
    #include "flags/trans.asm"

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
