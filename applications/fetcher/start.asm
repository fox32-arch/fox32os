    opton

    pop [terminalStreamPtr]
    pop [arg0Ptr]
    pop [arg1Ptr]
    pop [arg2Ptr]
    pop [arg3Ptr]

    call Main
    call end_current_task

GetNextWindowEvent:
    push r8
    call get_next_window_event
    mov r8, eventArgs
    mov [r8+0], r0
    mov [r8+4], r1
    mov [r8+8], r2
    mov [r8+12], r3
    mov [r8+16], r4
    mov [r8+20], r5
    mov [r8+24], r6
    mov [r8+28], r7
    pop r8
    ret

IsRomDiskAvailable:
    call is_romdisk_available
    ifz mov r0, 1
    ifnz mov r0, 0
    ret

brk:
    brk
    ret

PortIn:
    in r0, r0
    ret

eventArgs: data.fill 0, 32
terminalStreamPtr: data.32 0
arg0Ptr: data.32 0
arg1Ptr: data.32 0
arg2Ptr: data.32 0
arg3Ptr: data.32 0

browserFileListFriendly:
    data.32 browserFile0
    data.32 browserFile1
    data.32 browserFile2
    data.32 browserFile3
    data.32 browserFile4
    data.32 browserFile5
    data.32 browserFile6
    data.32 browserFile7
    data.32 browserFile8
    data.32 browserFile9
    data.32 browserFile10
    data.32 browserFile11

browserFile0: data.fill 0, 13
browserFile1: data.fill 0, 13
browserFile2: data.fill 0, 13
browserFile3: data.fill 0, 13
browserFile4: data.fill 0, 13
browserFile5: data.fill 0, 13
browserFile6: data.fill 0, 13
browserFile7: data.fill 0, 13
browserFile8: data.fill 0, 13
browserFile9: data.fill 0, 13
browserFile10: data.fill 0, 13
browserFile11: data.fill 0, 13

browserMenuItemsRoot:
    data.8 1                                                      ; number of menus
    data.32 menu_items_system_list data.32 menu_items_system_name ; pointer to menu list, pointer to menu name
menu_items_system_name:
    data.8 6 data.strz "System" ; text length, text, null-terminator
menu_items_system_list:
    data.8 1                   ; number of items
    data.8 7                   ; menu width (usually longest item + 2)
    data.8 5 data.strz "About" ; text length, text, null-terminator

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
