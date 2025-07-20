; disk format utility

    opton

    pop [stream]
    pop [disk]
    pop [name]
    cmp [name], 0
    ifz jmp usage_error

    mov r0, [disk]
    mov r1, 10
    call string_to_int
    mov [disk], r0
    cmp r0, 3
    ifgt jmp disk_error

    mov r0, [name]
    call string_length
    cmp r0, 8
    ifgt jmp name_error

    mov r0, [disk]
    mov r1, r0
    or r1, 0x80001000 ; disk size
    in r1, r1
    sra r1, 9 ; divide by 512
    cmp r1, 0
    ifz jmp disk_size_error
    mov r2, [name]
    call ryfs_format

    mov r0, done_str
    call print

    call end_current_task

disk_error:
    mov r0, disk_error_str
    rjmp error
disk_size_error:
    mov r0, disk_size_error_str
    rjmp error
name_error:
    mov r0, name_error_str
    rjmp error
usage_error:
    mov r0, usage_error_str
error:
    call print
    call end_current_task

; print a null-terminated string to the stream
; inputs:
; r0: pointer to string
print:
    push r0
    push r1
    push r2

    mov r2, r0
    call string_length
    mov r1, [stream]
    call write

    pop r2
    pop r1
    pop r0
    ret

done_str: data.str "done" data.8 10 data.8 0
disk_error_str: data.str "disk ID must be <= 3" data.8 10 data.8 0
disk_size_error_str: data.str "bad disk size" data.8 10 data.8 0
name_error_str: data.str "name must be <= 8 characters" data.8 10 data.8 0
usage_error_str: data.str "usage: format <disk ID> <root dir name>" data.8 10 data.8 0
stream: data.32 0
disk: data.32 0
name: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
