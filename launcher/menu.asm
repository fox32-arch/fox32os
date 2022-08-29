; menu bar helper routines

; add all FXF files to the Launcher menu
; THIS FREES [r0], ONLY CALL THIS ONCE
; inputs:
; r0: pointer to file name buffer
; r1: number of files
; outputs:
; none
add_fxf_files_to_launcher_menu:
    push r0
    push r1
    push r2
    push r31

    mov r31, r1
    mov r1, menu_items_launcher_list
    mov.8 [r1], r31 ; set number of items
    add r1, 3 ; point to first string
    mov r2, 8 ; copy 8 bytes each
add_fxf_files_to_launcher_menu_loop:
    call copy_memory_bytes
    add r0, 11 ; point to next file name
    add r1, 10 ; point to next menu item string
    loop add_fxf_files_to_launcher_menu_loop

    pop r31
    pop r2
    pop r1
    pop r0
    call free_memory
    ret

menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    ; system
    cmp r2, 0
    ifz jmp system_menu_click_event

    ; launcher
    cmp r2, 1
    ifz jmp launch_fxf

    ret

system_menu_click_event:
    ; r2 contains the clicked root menu
    ; r3 contains the clicked menu item

    cmp r3, 0
    ifz jmp about_dialog

    ; shut down
    cmp r3, 1
    ifz icl
    ifz halt

    ret

menu_items_root:
    data.8 2                                                          ; number of menus
    data.32 menu_items_system_list   data.32 menu_items_system_name   ; pointer to menu list, pointer to menu name
    data.32 menu_items_launcher_list data.32 menu_items_launcher_name ; pointer to menu list, pointer to menu name
menu_items_system_name:
    data.8 6  data.str "System"    data.8 0x00 ; text length, text, null-terminator
menu_items_launcher_name:
    data.8 8  data.str "Launcher"  data.8 0x00 ; text length, text, null-terminator
menu_items_system_list:
    data.8 2                                   ; number of items
    data.8 11                                  ; menu width (usually longest item + 2)
    data.8 5  data.str "About"     data.8 0x00 ; text length, text, null-terminator
    data.8 9  data.str "Shut Down" data.8 0x00 ; text length, text, null-terminator
menu_items_launcher_list:                      ; reserve enough room for up to 28 items
    data.8 1                                   ; number of items
    data.8 10                                  ; menu width (usually longest item + 2)
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
    data.8 8  data.str "        "  data.8 0x00 ; text length, text, null-terminator
