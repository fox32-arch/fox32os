; set the font to be used by future fox32rom draw calls

    pop [stream_ptr]
    pop [file_name_ptr]

    cmp [file_name_ptr], 0
    ifz rjmp arg_error

    call get_current_disk_id
    mov r1, r0
    mov r0, [file_name_ptr]
    mov r2, file_struct
    call open
    cmp r0, 0
    ifz rjmp file_error
    mov r0, file_struct
    call get_size
    push r0
    call allocate_memory
    cmp r0, 0
    ifz rjmp memory_error
    mov [font_buffer_ptr], r0
    pop r0
    mov r1, file_struct
    mov r2, [font_buffer_ptr]
    call read

    mov r0, [font_buffer_ptr]
    call set_font

    call end_current_task

arg_error:
    mov r0, arg_error_str
    rjmp.8 error
file_error:
    mov r0, file_error_str
    rjmp.8 error
memory_error:
    mov r0, memory_error_str
error:
    mov r2, r0
    call string_length
    mov r1, [stream_ptr]
    call write

    call end_current_task

stream_ptr: data.32 0
file_name_ptr: data.32 0
file_struct: data.fill 0, 32
font_buffer_ptr: data.32 0

arg_error_str: data.str "usage: loadfont <file path>" data.8 10 data.8 0
file_error_str: data.str "could not open file" data.8 10 data.8 0
memory_error_str: data.str "not enough available memory" data.8 10 data.8 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
