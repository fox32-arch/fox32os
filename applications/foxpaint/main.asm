; simple paint application

    opton

    mov r0, canvas_window_struct
    mov r1, canvas_window_title
    mov r2, 512
    mov r3, 448
    mov r4, 0
    mov r5, 16
    mov r6, menu_items_root
    mov r7, 0
    call new_window

    mov r0, tools_window_struct
    mov r1, tools_window_title
    mov r2, 128
    mov r3, 128
    mov r4, 512
    mov r5, 16
    mov r6, menu_items_root
    mov r7, color_button_black_widget
    call new_window

    mov r0, 0xFFFFFFFF
    mov r1, tools_window_struct
    call fill_window

    mov r0, tools_window_struct
    call get_window_overlay_number
    mov r5, r0
    mov r0, 16
    mov r1, 32
    mov r2, 96
    mov r3, 96
    mov r4, 0xFF888888
    call draw_filled_rectangle_to_overlay

    mov r0, color_section_text
    mov r1, 32
    mov r2, 48
    mov r3, [color]
    not r3
    or r3, 0xFF000000
    mov r4, [color]
    call draw_str_to_overlay

    mov r0, tools_window_struct
    call draw_widgets_to_window

event_loop:
    ; canvas events
    mov r0, canvas_window_struct
    call get_next_window_event

    ; was the mouse clicked?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call canvas_mouse_click_event

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


    ; tools events
    mov r0, tools_window_struct
    call get_next_window_event

    ; was the mouse clicked?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call tools_mouse_click_event

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

    ; did the user click a button?
    cmp r0, EVENT_TYPE_BUTTON_CLICK
    ifz call tools_button_click_event

    cmp.8 [is_drawing], 0
    ifnz call draw_pixel

    call yield_task
    jmp event_loop

canvas_mouse_click_event:
    push r0

    ; first, check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_or_close_canvas_window

    ; if not, enable the drawing flag
    mov.8 [is_drawing], 1

    pop r0
    ret

tools_mouse_click_event:
    push r0

    ; first, check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_or_close_tools_window

    ; then, handle widget clicks
    mov r0, tools_window_struct
    call handle_widget_click

    pop r0
    ret

menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; file
    cmp r2, 0
    ifz call file_menu_click_event

    ; canvas
    cmp r2, 1
    ifz call canvas_menu_click_event

    ; brush
    cmp r2, 2
    ifz call brush_menu_click_event

    ret

menu_ack_event:
    push r0

    mov r0, menu_items_root
    call close_menu

    pop r0
    ret

file_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; open image
    cmp r3, 0
    ifz call open_image

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

tools_button_click_event:
    ; r1 contains the ID of the clicked button

    ; colors

    ; black
    cmp r1, 0
    ifz mov [color], 0xFF000000

    ; white
    cmp r1, 1
    ifz mov [color], 0xFFFFFFFF

    ; red
    cmp r1, 2
    ifz mov [color], 0xFF0000FF

    ; green
    cmp r1, 3
    ifz mov [color], 0xFF00FF00

    ; blue
    cmp r1, 4
    ifz mov [color], 0xFFFF0000

    ; redraw the "color" text in the clicked color
    mov r0, tools_window_struct
    call get_window_overlay_number
    mov r5, r0
    mov r0, color_section_text
    mov r1, 32
    mov r2, 48
    mov r3, [color]
    not r3
    or r3, 0xFF000000
    mov r4, [color]
    call draw_str_to_overlay

    ret

draw_pixel:
    mov r0, canvas_window_struct
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

open_image:
    push r3

    ; hack lol
    mov r0, menu_items_root
    call close_menu

    call get_boot_disk_id
    mov r1, r0
    mov r0, fetcher_filename
    mov r2, 0
    mov r3, fetcher_open_arg
    mov r4, selected_filename
    mov r5, selected_disk
    mov r6, 0
    call launch_fxf_from_disk
open_image_wait:
    push r0
    call yield_task
    pop r0
    call is_task_id_used
    ifnz jmp open_image_wait
open_image_draw:
    mov r0, 0xE0000 ; 512x448x4
    call allocate_memory
    cmp r0, 0
    ifz pop r3
    ifz ret
    mov [selected_file_buffer_ptr], r0
    mov r0, selected_filename
    mov r1, [selected_disk]
    mov r2, selected_file_struct
    call open
    cmp r0, 0
    ifz pop r3
    ifz ret
    mov r0, 0xE0000 ; 512x448x4
    mov r1, selected_file_struct
    mov r2, [selected_file_buffer_ptr]
    call read
    mov r0, [selected_file_buffer_ptr]
    mov r1, 512
    mov r2, 448
    call set_tilemap
    mov r0, canvas_window_struct
    call get_window_overlay_number
    mov r3, r0
    mov r0, 0
    mov r1, 0
    mov r2, 16
    call draw_tile_to_overlay
    mov r0, [selected_file_buffer_ptr]
    call free_memory

    pop r3
    ret

clear_canvas_black:
    mov r0, 0xFF000000
    mov r1, canvas_window_struct
    call fill_window

    ret

clear_canvas_white:
    mov r0, 0xFFFFFFFF
    mov r1, canvas_window_struct
    call fill_window

    ret

drag_or_close_canvas_window:
    cmp r1, 8
    iflteq jmp close_canvas_window
    mov r0, canvas_window_struct
    call start_dragging_window
    pop r0
    ret
close_canvas_window:
    mov r0, canvas_window_struct
    call destroy_window
    mov r0, tools_window_struct
    call destroy_window
    call end_current_task

drag_or_close_tools_window:
    cmp r1, 8
    iflteq pop r0
    iflteq ret
    mov r0, tools_window_struct
    call start_dragging_window
    pop r0
    ret

canvas_window_title: data.strz "FoxPaint canvas"
canvas_window_struct: data.fill 0, 40

tools_window_title: data.strz "FoxPaint tools"
tools_window_struct: data.fill 0, 40

color_section_text: data.strz "Color "
color_button_black_widget:
    data.32 color_button_white_widget ; next_ptr
    data.32 0                         ; id
    data.32 WIDGET_TYPE_BUTTON        ; type
    data.32 color_button_text         ; text_ptr
    data.32 0xFFFFFFFF                ; foreground_color
    data.32 0xFF000000                ; background_color
    data.16 16                        ; width
    data.16 0                         ; reserved
    data.16 32                        ; x_pos
    data.16 64                        ; y_pos
color_button_white_widget:
    data.32 color_button_red_widget   ; next_ptr
    data.32 1                         ; id
    data.32 WIDGET_TYPE_BUTTON        ; type
    data.32 color_button_text         ; text_ptr
    data.32 0xFFFFFFFF                ; foreground_color
    data.32 0xFFFFFFFF                ; background_color
    data.16 16                        ; width
    data.16 0                         ; reserved
    data.16 48                        ; x_pos
    data.16 64                        ; y_pos
color_button_red_widget:
    data.32 color_button_green_widget ; next_ptr
    data.32 2                         ; id
    data.32 WIDGET_TYPE_BUTTON        ; type
    data.32 color_button_text         ; text_ptr
    data.32 0xFFFFFFFF                ; foreground_color
    data.32 0xFF0000FF                ; background_color
    data.16 16                        ; width
    data.16 0                         ; reserved
    data.16 64                        ; x_pos
    data.16 64                        ; y_pos
color_button_green_widget:
    data.32 color_button_blue_widget  ; next_ptr
    data.32 3                         ; id
    data.32 WIDGET_TYPE_BUTTON        ; type
    data.32 color_button_text         ; text_ptr
    data.32 0xFFFFFFFF                ; foreground_color
    data.32 0xFF00FF00                ; background_color
    data.16 16                        ; width
    data.16 0                         ; reserved
    data.16 32                        ; x_pos
    data.16 80                        ; y_pos
color_button_blue_widget:
    data.32 0                         ; next_ptr
    data.32 4                         ; id
    data.32 WIDGET_TYPE_BUTTON        ; type
    data.32 color_button_text         ; text_ptr
    data.32 0xFFFFFFFF                ; foreground_color
    data.32 0xFFFF0000                ; background_color
    data.16 16                        ; width
    data.16 0                         ; reserved
    data.16 48                        ; x_pos
    data.16 80                        ; y_pos
color_button_text: data.strz "  "

menu_items_root:
    data.8 3                                                      ; number of menus
    data.32 menu_items_file_list data.32 menu_items_file_name     ; pointer to menu list, pointer to menu name
    data.32 menu_items_canvas_list data.32 menu_items_canvas_name ; pointer to menu list, pointer to menu name
    data.32 menu_items_brush_list data.32 menu_items_brush_name   ; pointer to menu list, pointer to menu name
menu_items_file_name:
    data.8 4 data.strz "File" ; text length, text, null-terminator
menu_items_canvas_name:
    data.8 6 data.strz "Canvas" ; text length, text, null-terminator
menu_items_brush_name:
    data.8 5 data.strz "Brush" ; text length, text, null-terminator
menu_items_file_list:
    data.8 1                             ; number of items
    data.8 15                            ; menu width (usually longest item + 2)
    data.8 13 data.strz "Open Image..."  ; text length, text, null-terminator
menu_items_canvas_list:
    data.8 2                             ; number of items
    data.8 16                            ; menu width (usually longest item + 2)
    data.8 14 data.strz "Clear to Black" ; text length, text, null-terminator
    data.8 14 data.strz "Clear to White" ; text length, text, null-terminator
menu_items_brush_list:
    data.8 4                   ; number of items
    data.8 7                   ; menu width (usually longest item + 2)
    data.8 3 data.strz "2x2"   ; text length, text, null-terminator
    data.8 3 data.strz "4x4"   ; text length, text, null-terminator
    data.8 3 data.strz "8x8"   ; text length, text, null-terminator
    data.8 5 data.strz "16x16" ; text length, text, null-terminator
menu_items_color_list:
    data.8 5                   ; number of items
    data.8 7                   ; menu width (usually longest item + 2)
    data.8 5 data.strz "Black" ; text length, text, null-terminator
    data.8 5 data.strz "White" ; text length, text, null-terminator
    data.8 3 data.strz "Red"   ; text length, text, null-terminator
    data.8 5 data.strz "Green" ; text length, text, null-terminator
    data.8 4 data.strz "Blue"  ; text length, text, null-terminator

is_drawing: data.8 0
brush_size: data.8 4
color: data.32 0xFFFFFFFF

fetcher_filename: data.strz "fetcher.fxf"
fetcher_open_arg: data.strz "open"
selected_filename: data.fill 0, 13
selected_disk: data.32 0
selected_file_struct: data.fill 0, 32
selected_file_buffer_ptr: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
