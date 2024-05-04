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

CompareString:
    call compare_string
    ifz mov r0, 1
    ifnz mov r0, 0
    ret

brk:
    brk
    ret

eventArgs: data.fill 0, 32
terminalStreamPtr: data.32 0
arg0Ptr: data.32 0
arg1Ptr: data.32 0
arg2Ptr: data.32 0
arg3Ptr: data.32 0

menuItemsRoot:
    data.8 1                                                  ; number of menus
    data.32 menu_items_file_list data.32 menu_items_file_name ; pointer to menu list, pointer to menu name
menu_items_file_name:
    data.8 4 data.strz "File" ; text length, text, null-terminator
menu_items_file_list:
    data.8 1                           ; number of items
    data.8 14                          ; menu width (usually longest item + 2)
    data.8 12 data.strz "Open File..." ; text length, text, null-terminator

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
