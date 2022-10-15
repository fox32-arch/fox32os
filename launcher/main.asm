; launcher

entry:
    ; set up the menu bar
    call enable_menu_bar
    call clear_menu_bar
    mov r0, menu_items_root
    mov r1, 0xFFFFFFFF
    call draw_menu_bar_root_items

    ; open the wallpaper file and draw it
    mov r0, wallpaper_file_name
    mov r1, 0
    mov r2, wallpaper_file_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp skip_wallpaper

    ; read the wallpaper file directly into the background framebuffer
    mov r0, 1228800 ; 640x480x4
    mov r1, wallpaper_file_struct
    mov r2, 0x02000000
    call ryfs_read
skip_wallpaper:
    ; build a list of FXF files and add them to the menu
    call get_fxf_files
    call add_fxf_files_to_launcher_menu

event_loop:
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
    jmp event_loop

quit_launcher:
    call disable_menu_bar
    call end_current_task
    jmp hang

allocate_error:
    mov r0, allocate_error_str
    mov r1, 16
    mov r2, 32
    mov r3, 0xFFFFFFFF
    mov r4, 0xFF000000
    call draw_str_to_background
hang:
    rjmp hang
allocate_error_str: data.str "error while allocating memory" data.8 0

wallpaper_file_name: data.str "wallpaprraw"
wallpaper_file_struct: data.32 0 data.32 0

    #include "about.asm"
    #include "file.asm"
    #include "launch.asm"
    #include "menu.asm"

    ; include system defs
    #include "../../fox32rom/fox32rom.def"
    #include "../fox32os.def"
