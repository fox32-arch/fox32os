; set the font to be used by future fox32rom draw calls

    pop [stream_ptr]
    pop [file_name_ptr]

    cmp [file_name_ptr], 0
    ifz call end_current_task

    call get_current_disk_id
    mov r1, r0
    mov r0, [file_name_ptr]
    mov r2, file_struct
    call open
    cmp r0, 0
    ifz call end_current_task
    mov r0, file_struct
    call get_size
    push r0
    call allocate_memory
    cmp r0, 0
    ifz call end_current_task
    mov [font_buffer_ptr], r0
    pop r0
    mov r1, file_struct
    mov r2, [font_buffer_ptr]
    call read

    mov r0, [font_buffer_ptr]
    call set_font

    call end_current_task

stream_ptr: data.32 0
file_name_ptr: data.32 0
file_struct: data.fill 0, 32
font_buffer_ptr: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
