; vulpine window manager

const VULPINE_VERSION_MAJOR: 0
const VULPINE_VERSION_MINOR: 1
const VULPINE_VERSION_PATCH: 0

entry:
    call enable_menu_bar
    call clear_menu_bar
    mov r0, menu_items_root
    mov r1, 0xFFFFFFFF
    call draw_menu_bar_root_items

draw_wallpaper:
    ; open the wallpaper file and draw it
    mov r0, wallpaper_file_name
    mov r1, 0
    mov r2, wallpaper_file_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp event_loop

    ; read the wallpaper file directly into the background framebuffer
    mov r0, wallpaper_file_struct
    mov r1, 0x02000000
    call ryfs_read_whole_file

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

menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; system
    cmp r2, 0
    ifz call system_menu_click_event

    ret

system_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; shut down
    cmp r3, 0
    ifz icl
    ifz halt

    ret

wallpaper_file_name: data.str "wallpaprraw"
wallpaper_file_struct: data.32 0 data.32 0

menu_items_root:
    data.8 1                                                      ; number of menus
    data.32 menu_items_system_list data.32 menu_items_system_name ; pointer to menu list, pointer to menu name
menu_items_system_name:
    data.8 6  data.str "System"    data.8 0x00   ; text length, text, null-terminator
menu_items_system_list:
    data.8 1                                     ; number of items
    data.8 11                                    ; menu width (usually longest item + 2)
    data.8 9  data.str "Shut Down" data.8 0x00   ; text length, text, null-terminator

    ; include system defs
    #include "../../fox32rom/fox32rom.def"
    #include "../fox32os.def"
