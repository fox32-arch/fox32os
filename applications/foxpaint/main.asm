; mouse painting demo

    mov r0, window_struct
    mov r1, window_title
    mov r2, 640
    mov r3, 448
    mov r4, 0
    mov r5, 16
    mov r6, menu_items_root
    mov r7, 0
    call new_window

event_loop:
    mov r0, window_struct
    call get_next_window_event

    ; was the mouse clicked?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call mouse_click_event

    ; was the mouse released?
    cmp r0, EVENT_TYPE_MOUSE_RELEASE
    ifz mov.8 [is_drawing], 0

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

    ; should the menu be closed?
    cmp r0, EVENT_TYPE_MENU_ACK
    ifz call menu_ack_event

    cmp.8 [is_drawing], 0
    ifnz call draw_pixel

    call yield_task
    jmp event_loop

mouse_click_event:
    push r0

    ; first, check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_or_close_window

    ; if not, enable the drawing flag
    mov.8 [is_drawing], 1

    pop r0
    ret

menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; canvas
    cmp r2, 0
    ifz call canvas_menu_click_event

    ; brush
    cmp r2, 1
    ifz call brush_menu_click_event

    ; color
    cmp r2, 2
    ifz call color_menu_click_event

    ret

menu_ack_event:
    push r0

    mov r0, menu_items_root
    call close_menu

    pop r0
    ret

canvas_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; clear to black
    cmp r3, 0
    ifz call clear_canvas_black

    ; clear to white
    cmp r3, 1
    ifz call clear_canvas_white

    ret

brush_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; 2x2
    cmp r3, 0
    ifz mov.8 [brush_size], 2

    ; 4x4
    cmp r3, 1
    ifz mov.8 [brush_size], 4

    ; 8x8
    cmp r3, 2
    ifz mov.8 [brush_size], 8

    ; 16x16
    cmp r3, 3
    ifz mov.8 [brush_size], 16

    ret

color_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; black
    cmp r3, 0
    ifz mov [color], 0xFF000000

    ; white
    cmp r3, 1
    ifz mov [color], 0xFFFFFFFF

    ; red
    cmp r3, 2
    ifz mov [color], 0xFF0000FF

    ; green
    cmp r3, 3
    ifz mov [color], 0xFF00FF00

    ; blue
    cmp r3, 4
    ifz mov [color], 0xFFFF0000

    ret

draw_pixel:
    mov r0, window_struct
    call get_window_overlay_number
    mov r2, r0
    mov r5, r0
    call get_mouse_position
    call make_coordinates_relative_to_overlay
    movz.8 r2, [brush_size]
    movz.8 r3, [brush_size]
    mov r4, [color]
    call draw_filled_rectangle_to_overlay

    ret

clear_canvas_black:
    mov r0, 0xFF000000
    mov r1, window_struct
    call fill_window

    ret

clear_canvas_white:
    mov r0, 0xFFFFFFFF
    mov r1, window_struct
    call fill_window

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

window_title: data.str "FoxPaint" data.8 0
window_struct: data.fill 0, 36

menu_items_root:
    data.8 3                                                      ; number of menus
    data.32 menu_items_canvas_list data.32 menu_items_canvas_name ; pointer to menu list, pointer to menu name
    data.32 menu_items_brush_list data.32 menu_items_brush_name   ; pointer to menu list, pointer to menu name
    data.32 menu_items_color_list data.32 menu_items_color_name   ; pointer to menu list, pointer to menu name
menu_items_canvas_name:
    data.8 6 data.str "Canvas" data.8 0x00 ; text length, text, null-terminator
menu_items_brush_name:
    data.8 5 data.str "Brush"  data.8 0x00 ; text length, text, null-terminator
menu_items_color_name:
    data.8 5 data.str "Color"  data.8 0x00 ; text length, text, null-terminator
menu_items_canvas_list:
    data.8 2                                        ; number of items
    data.8 16                                       ; menu width (usually longest item + 2)
    data.8 14 data.str "Clear to Black" data.8 0x00 ; text length, text, null-terminator
    data.8 14 data.str "Clear to White" data.8 0x00 ; text length, text, null-terminator
menu_items_brush_list:
    data.8 4                              ; number of items
    data.8 7                              ; menu width (usually longest item + 2)
    data.8 3 data.str "2x2"   data.8 0x00 ; text length, text, null-terminator
    data.8 3 data.str "4x4"   data.8 0x00 ; text length, text, null-terminator
    data.8 3 data.str "8x8"   data.8 0x00 ; text length, text, null-terminator
    data.8 5 data.str "16x16" data.8 0x00 ; text length, text, null-terminator
menu_items_color_list:
    data.8 5                              ; number of items
    data.8 7                              ; menu width (usually longest item + 2)
    data.8 5 data.str "Black" data.8 0x00 ; text length, text, null-terminator
    data.8 5 data.str "White" data.8 0x00 ; text length, text, null-terminator
    data.8 3 data.str "Red"   data.8 0x00 ; text length, text, null-terminator
    data.8 5 data.str "Green" data.8 0x00 ; text length, text, null-terminator
    data.8 4 data.str "Blue"  data.8 0x00 ; text length, text, null-terminator

is_drawing: data.8 0
brush_size: data.8 4
color: data.32 0xFFFFFFFF

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
