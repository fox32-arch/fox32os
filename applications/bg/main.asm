; background image utility

    ; open the background file and draw it
    ; if the file can't be opened, then just exit
    call get_current_disk_id
    mov r1, r0
    mov r0, bg_file_name
    mov r2, bg_file_struct
    call open
    cmp r0, 0
    ifz call end_current_task

    ; read the background file directly into the background framebuffer
    mov r0, 1228800 ; 640x480x4
    mov r1, bg_file_struct
    mov r2, 0x02000000
    call read

    call end_current_task

bg_file_name: data.str "bg      raw"
bg_file_struct: data.fill 0, 8

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
