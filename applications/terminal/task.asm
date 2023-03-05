; sh.fxf launching routines

; start an instance of sh.fxf
; inputs:
; r0: task ID
; r1: pointer to stream struct
; outputs:
; none
new_shell_task:
    push r0
    push r1

    ; open the file
    call get_current_disk_id
    mov r1, r0
    mov r0, sh_fxf_name
    mov r2, sh_fxf_struct
    call open
    cmp r0, 0
    ifz jmp sh_fxf_missing

    ; allocate memory for the binary
    mov r0, sh_fxf_struct
    call ryfs_get_size
    call allocate_memory
    cmp r0, 0
    ifz jmp sh_fxf_missing
    mov [sh_fxf_binary_ptr], r0

    ; read the file into memory
    mov r0, sh_fxf_struct
    mov r1, [sh_fxf_binary_ptr]
    call ryfs_read_whole_file

    ; allocate a 64KiB stack
    mov r0, 65536
    call allocate_memory
    cmp r0, 0
    ifz jmp sh_fxf_missing
    mov [sh_fxf_stack_ptr], r0

    ; push the stream struct pointer to the shell's stack
    add r0, 65532
    pop r1
    mov [r0], r1
    mov r10, r0

    ; relocate the binary
    mov r0, [sh_fxf_binary_ptr]
    call parse_fxf_binary

    ; then start the task
    mov r1, r0                  ; initial instruction pointer
    pop r0                      ; task ID
    mov r2, r10                 ; initial stack pointer
    mov r3, [sh_fxf_binary_ptr] ; pointer to task code block to free when task ends
    mov r4, [sh_fxf_stack_ptr]  ; pointer to task stack block to free when task ends
    call new_task
    ret

sh_fxf_missing:
    mov r0, sh_fxf_missing_str
    call print_str_to_terminal
    rjmp 0

sh_fxf_name: data.str "sh      fxf"
sh_fxf_struct: data.fill 0, 8
sh_fxf_missing_str: data.strz "sh could not be launched!"
sh_fxf_binary_ptr: data.32 0
sh_fxf_stack_ptr: data.32 0
