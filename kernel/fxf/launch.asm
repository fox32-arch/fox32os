; FXF launching routines

; launch an FXF binary from a file on disk
; inputs:
; r0: pointer to FXF binary name (8.3 format, for example "testfile.fxf" or "test.fxf")
; r1: argument 0
; r2: argument 1
; r3: argument 2
; r4: argument 3
; r5: argument 4
; outputs:
; none
launch_fxf_from_disk:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; open the file
    mov r1, 0
    mov r2, launch_fxf_struct
    call open
    cmp r0, 0
    ifz jmp allocate_error

    ; allocate memory for the binary
    mov r0, launch_fxf_struct
    call ryfs_get_size
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [launch_fxf_binary_ptr], r0

    ; read the file into memory
    mov r0, launch_fxf_struct
    mov r1, [launch_fxf_binary_ptr]
    call ryfs_read_whole_file

    ; allocate a 64KiB stack
    mov r0, 65536
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [launch_fxf_stack_ptr], r0

    ; push the arguments to the task's stack
    mov r4, rsp
    mov rsp, [launch_fxf_stack_ptr]
    add rsp, 65536 ; point to the end of the stack (stack grows down!!)
    push r5
    push r4
    push r3
    push r2
    push r1
    sub rsp, 65516
    mov [launch_fxf_stack_ptr], rsp
    mov rsp, r4

    ; relocate the binary
    mov r0, [launch_fxf_binary_ptr]
    call parse_fxf_binary

    ; create a new task
    mov r1, r0
    call get_unused_task_id
    mov r2, [launch_fxf_stack_ptr]
    add r2, 65516 ; point to the end of the stack (stack grows down!!)
    mov r3, [launch_fxf_binary_ptr]
    mov r4, [launch_fxf_stack_ptr]
    call new_task
allocate_error:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

launch_fxf_struct: data.fill 0, 8
launch_fxf_binary_ptr: data.32 0
launch_fxf_stack_ptr: data.32 0
