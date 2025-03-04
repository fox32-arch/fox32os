; terminal

    opton

    pop r0
    pop r0
    cmp r0, 0
    ifz mov.8 [window_full_screen_flag], 0
    ifz rjmp continue
    mov r1, argument_full_str
    call compare_string
    ifz mov.8 [window_full_screen_flag], 1
continue:
    mov r0, 0
    call change_color
    call create_terminal_window

    ; start an instance of sh.fxf
    call get_boot_disk_id
    mov r1, r0
    mov r0, sh_fxf_name
    mov r2, stream_struct
    mov r3, 0
    mov r4, 0
    mov r5, 0
    mov r6, 0
    call launch_fxf_from_disk
    cmp r0, 0xFFFFFFFF
    ifz jmp sh_fxf_missing
    mov.8 [shell_task_id], r0

event_loop:
    mov r0, window_struct
    call get_next_window_event

    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz jmp mouse_down

    cmp r0, EVENT_TYPE_MENU_BAR_CLICK
    ifz mov r0, menu_items_root
    ifz call menu_bar_click_event

    cmp r0, EVENT_TYPE_MENU_UPDATE
    ifz call menu_update_event

    cmp r0, EVENT_TYPE_MENU_CLICK
    ifz jmp menu_click_event

    cmp r0, EVENT_TYPE_MENU_ACK
    ifz jmp menu_ack_event

    cmp r0, EVENT_TYPE_KEY_DOWN
    ifz jmp key_down

    cmp r0, EVENT_TYPE_KEY_UP
    ifz jmp key_up

event_loop_end:
    movz.8 r0, [shell_task_id]
    call is_task_id_used
    ifz jmp close_window
    call yield_task
    cmp.8 [read_buffer_ack], 1
    ifz mov.8 [read_buffer], 0
    ifz mov.8 [read_buffer_ack], 0
    rjmp event_loop

mouse_down:
    ; check if we are attempting to drag or close the window
    cmp r2, 16
    iflt jmp drag_window

    jmp event_loop_end

key_down:
    mov r0, r1

    cmp.8 r0, KEY_CTRL
    ifz jmp event_loop_end
    cmp.8 r0, KEY_LSHIFT
    ifz push event_loop_end
    ifz jmp shift_pressed
    cmp.8 r0, KEY_RSHIFT
    ifz push event_loop_end
    ifz jmp shift_pressed
    cmp.8 r0, KEY_CAPS
    ifz push event_loop_end
    ifz jmp caps_pressed

    call scancode_to_ascii
    mov.8 [read_buffer], r0

    jmp event_loop_end

key_up:
    mov r0, r1

    cmp.8 r0, KEY_CTRL
    ifz jmp event_loop_end
    cmp.8 r0, KEY_LSHIFT
    ifz push event_loop_end
    ifz jmp shift_released
    cmp.8 r0, KEY_RSHIFT
    ifz push event_loop_end
    ifz jmp shift_released

    jmp event_loop_end

menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; window
    cmp r2, 0
    ifz call window_menu_click_event

    ; colors
    cmp r2, 1
    ifz call colors_menu_click_event

    jmp event_loop_end

menu_ack_event:
    mov r0, menu_items_root
    call close_menu

    jmp event_loop_end

window_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; toggle full screen
    cmp r3, 0
    ifz call toggle_full_screen

    jmp event_loop_end

colors_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    mov r0, r3
    call change_color
    call redraw_terminal

    jmp event_loop_end

drag_window:
    cmp r1, 8
    iflt jmp close_window
    mov r0, window_struct
    call start_dragging_window
    jmp event_loop_end

close_window:
    mov r0, window_struct
    call destroy_window

    mov r0, [terminal_text_buf_ptr]
    cmp r0, 0
    ifnz call free_memory
    mov r0, [terminal_color_buf_ptr]
    cmp r0, 0
    ifnz call free_memory

    call end_current_task
    jmp event_loop_end

sh_fxf_missing:
    mov r0, sh_fxf_missing_str
    call print_str_to_terminal
sh_fxf_missing_yield_loop:
    call yield_task
    rjmp sh_fxf_missing_yield_loop

toggle_full_screen:
    push r0

    not.8 [window_full_screen_flag]
    call create_terminal_window

    ; the menu ack event seems to get lost due to
    ; the window being recreated, so fake it here
    call menu_ack_event

    pop r0
    ret

create_terminal_window:
    mov r0, [terminal_text_buf_ptr]
    cmp r0, 0
    ifnz call free_memory
    mov r0, [terminal_color_buf_ptr]
    cmp r0, 0
    ifnz call free_memory
    cmp [terminal_text_buf_ptr], 0
    ifnz mov r0, window_struct
    ifnz call destroy_window

    cmp.8 [window_full_screen_flag], 0
    ifz rjmp create_terminal_window_not_full

    mov r0, TERMINAL_WIDTH_FULL
    mul r0, TERMINAL_HEIGHT_FULL
    push r0
    call allocate_memory
    mov [terminal_text_buf_ptr], r0
    pop r0
    call allocate_memory
    mov [terminal_color_buf_ptr], r0

    mov.8 [terminal_width], TERMINAL_WIDTH_FULL
    mov.8 [terminal_height], TERMINAL_HEIGHT_FULL

    mov r0, window_struct
    mov r1, window_title
    mov r2, WINDOW_WIDTH_FULL
    mov r3, WINDOW_HEIGHT_FULL
    mov r4, 0
    mov r5, 0
    mov r6, menu_items_root
    mov r7, 0
    call new_window

    mov r0, WINDOW_FLAG_NO_TITLE_BAR
    mov r1, window_struct
    call set_window_flags

    ; fill the window with the "black" color
    mov r0, [colors]
    mov r1, window_struct
    call fill_window

    ret
create_terminal_window_not_full:
    mov r0, TERMINAL_WIDTH_NOT_FULL
    mul r0, TERMINAL_HEIGHT_NOT_FULL
    push r0
    call allocate_memory
    mov [terminal_text_buf_ptr], r0
    pop r0
    call allocate_memory
    mov [terminal_color_buf_ptr], r0

    mov.8 [terminal_width], TERMINAL_WIDTH_NOT_FULL
    mov.8 [terminal_height], TERMINAL_HEIGHT_NOT_FULL

    mov r0, window_struct
    mov r1, window_title
    mov r2, WINDOW_WIDTH_NOT_FULL
    mov r3, WINDOW_HEIGHT_NOT_FULL
    mov r4, 32
    mov r5, 32
    mov r6, menu_items_root
    mov r7, 0
    call new_window

    ; fill the window with the "black" color
    mov r0, [colors]
    mov r1, window_struct
    call fill_window

    ret

change_color:
    mul r0, 4
    add r0, color_table
    mov r0, [r0]
    mov r1, colors
    mov r2, 9
    call copy_memory_words
    ret

color_table:
    data.32 catppuccin
    data.32 sea
    data.32 c64
catppuccin:
    data.32 0xff2e1e1e ; black
    data.32 0xffa88bf3 ; red
    data.32 0xffa1e3a6 ; green
    data.32 0xffafe2f9 ; yellow
    data.32 0xfffab489 ; blue
    data.32 0xffaca0eb ; magenta
    data.32 0xffd5e294 ; cyan
    data.32 0xfff4d6cd ; white
    data.32 0x00000000 ; transparent
sea:
    data.32 0xff2f261d ; black
    data.32 0xff9d6534 ; red
    data.32 0xff8ac70f ; green
    data.32 0xffb4eb47 ; yellow
    data.32 0xff8e7157 ; blue
    data.32 0xff8ac70f ; magenta
    data.32 0xffcf9b6e ; cyan
    data.32 0xffb5aaa1 ; white
    data.32 0x00000000 ; transparent
c64:
    data.32 0xffaa3a48 ; black
    data.32 0xff003dc3 ; red
    data.32 0xff91ecb3 ; green
    data.32 0xff7cdfd5 ; yellow
    data.32 0xffb3b3b3 ; blue
    data.32 0xff7881c1 ; magenta
    data.32 0xffccc584 ; cyan
    data.32 0xffde7a86 ; white
    data.32 0x00000000 ; transparent

window_title: data.strz "Terminal"
window_struct: data.fill 0, 40

window_full_screen_flag: data.8 0
window_width: data.32 0
window_height: data.32 0
const WINDOW_WIDTH_NOT_FULL: 320
const WINDOW_HEIGHT_NOT_FULL: 400
const WINDOW_WIDTH_FULL: 640
const WINDOW_HEIGHT_FULL: 464

const TERMINAL_WIDTH_NOT_FULL: 40
const TERMINAL_HEIGHT_NOT_FULL: 25
const TERMINAL_WIDTH_FULL: 80
const TERMINAL_HEIGHT_FULL: 29

sh_fxf_name: data.strz "/system/sh.fxf"
sh_fxf_missing_str: data.str "sh could not be launched! hanging here" data.8 10 data.8 0

argument_full_str: data.strz "full"

shell_task_id: data.8 0

stream_struct:
    data.8  0x00
    data.16 0x0000
    data.32 0x00000000
    data.8  0x01
    data.32 stream_get_input
    data.32 stream_write_to_terminal
    data.32 0x00000000
    data.32 0x00000000
    data.32 0x00000000
    data.32 0x00000000

menu_items_root:
    data.8 2                                                      ; number of menus
    data.32 menu_items_window_list data.32 menu_items_window_name ; pointer to menu list, pointer to menu name
    data.32 menu_items_colors_list data.32 menu_items_colors_name ; pointer to menu list, pointer to menu name
menu_items_window_name:
    data.8 6 data.strz "Window" ; text length, text, null-terminator
menu_items_window_list:
    data.8 1                                 ; number of items
    data.8 20                                ; menu width (usually longest item + 2)
    data.8 18 data.strz "Toggle Full Screen" ; text length, text, null-terminator
menu_items_colors_name:
    data.8 6 data.strz "Colors" ; text length, text, null-terminator
menu_items_colors_list:
    data.8 3                                 ; number of items
    data.8 15                                ; menu width (usually longest item + 2)
    data.8 10 data.strz "Catppuccin"         ; text length, text, null-terminator
    data.8 13 data.strz "Base2Tone Sea"      ; text length, text, null-terminator
    data.8 3  data.strz "C64"                ; text length, text, null-terminator

    #include "stream.asm"
    #include "text.asm"

    ; include system defs
    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
