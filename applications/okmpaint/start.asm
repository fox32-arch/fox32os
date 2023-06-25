    call Main
    call end_current_task

DrawPixel:
    mov r0, canvasWindow
    call get_window_overlay_number
    mov r2, r0
    mov r5, r0
    call get_mouse_position
    call make_coordinates_relative_to_overlay
    movz.8 r2, [size]
    movz.8 r3, [size]
    mov r4, [color]
    call draw_filled_rectangle_to_overlay
    ret

GetNextWindowEvent:
    push r8
    call get_next_window_event
    mov r8, eventArgs
    mov [r8], r0
    add r8, 4
    mov [r8], r1
    add r8, 4
    mov [r8], r2
    add r8, 4
    mov [r8], r3
    add r8, 4
    mov [r8], r4
    add r8, 4
    mov [r8], r5
    add r8, 4
    mov [r8], r6
    add r8, 4
    mov [r8], r7
    pop r8
    ret

eventArgs: data.fill 0, 32

menuItemsRoot:
    data.8 3                                                      ; number of menus
    data.32 menu_items_canvas_list data.32 menu_items_canvas_name ; pointer to menu list, pointer to menu name
    data.32 menu_items_brush_list data.32 menu_items_brush_name   ; pointer to menu list, pointer to menu name
    data.32 menu_items_color_list data.32 menu_items_color_name   ; pointer to menu list, pointer to menu name
menu_items_canvas_name:
    data.8 6 data.strz "Canvas" ; text length, text, null-terminator
menu_items_brush_name:
    data.8 5 data.strz "Brush" ; text length, text, null-terminator
menu_items_color_name:
    data.8 5 data.strz "Color" ; text length, text, null-terminator
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

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
