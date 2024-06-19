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

IsTaskIdUsed:
    call is_task_id_used
    ifz mov r0, 0
    ifnz mov r0, 1
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
    data.8 3                                                      ; number of menus
    data.32 menu_items_file_list data.32 menu_items_file_name     ; pointer to menu list, pointer to menu name
    data.32 menu_items_edit_list data.32 menu_items_edit_name     ; pointer to menu list, pointer to menu name
    data.32 menu_items_insert_list data.32 menu_items_insert_name ; pointer to menu list, pointer to menu name
menu_items_file_name:
    data.8 4 data.strz "File" ; text length, text, null-terminator
menu_items_file_list:
    data.8 2                     ; number of items
    data.8 9                     ; menu width (usually longest item + 2)
    data.8 7 data.strz "Open..." ; text length, text, null-terminator
    data.8 7 data.strz "Save..." ; text length, text, null-terminator
menu_items_edit_name:
    data.8 4 data.strz "Edit" ; text length, text, null-terminator
menu_items_edit_list:
    data.8 1                             ; number of items
    data.8 16                            ; menu width (usually longest item + 2)
    data.8 14 data.strz "Edit Widget..." ; text length, text, null-terminator
menu_items_insert_name:
    data.8 6 data.strz "Insert" ; text length, text, null-terminator
menu_items_insert_list:
    data.8 3                                  ; number of items
    data.8 21                                 ; menu width (usually longest item + 2)
    data.8 13 data.strz "Insert Button"       ; text length, text, null-terminator
    data.8 19 data.strz "Insert Textbox (SL)" ; text length, text, null-terminator
    data.8 12 data.strz "Insert Label"        ; text length, text, null-terminator

editLabelRes:
    #include "edit_label.rsf.asm"

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
