; FXF launcher helper routines

; launch an FXF binary from a shell entry
; inputs:
; r0: pointer to FXF binary name
; outputs:
; none, does not return if task started successfully
; returns if FXF file not found
launch_fxf:
    ; clear the first 8 characters of the launch_fxf_name buffer
    push r0
    mov r0, launch_fxf_spaces
    mov r1, launch_fxf_name
    mov r2, 8
    call copy_memory_bytes
    pop r0

    ; if the name was prefixed with a '*' character then
    ; clear a flag to have the shell return control immediately
    cmp.8 [r0], '*'
    ifnz mov.8 [launch_fxf_yield_should_suspend], 1
    ifnz jmp launch_fxf_no_prefix
    inc r0
    mov.8 [launch_fxf_yield_should_suspend], 0
launch_fxf_no_prefix:
    ; copy the name into the launch_fxf_name buffer
    mov r1, launch_fxf_name
    mov r31, 8
launch_fxf_name_loop:
    mov.8 [r1], [r0]
    inc r0
    inc r1
    cmp.8 [r0], 0
    ifz jmp launch_fxf_name_loop_done
    loop launch_fxf_name_loop
launch_fxf_name_loop_done:
    ; open the file
    mov r0, launch_fxf_name
    movz.8 r1, [shell_current_disk]
    mov r2, launch_fxf_struct
    call ryfs_open
    cmp r0, 0
    ifz ret

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

    ; push the argument pointers and terminal stream struct pointer to the task's stack
    call shell_parse_arguments
    mov r4, rsp
    mov rsp, [launch_fxf_stack_ptr]
    add rsp, 65536 ; point to the end of the stack (stack grows down!!)
    push r3
    push r2
    push r1
    push r0
    push [shell_terminal_stream_struct_ptr]
    sub rsp, 65516
    mov [launch_fxf_stack_ptr], rsp
    mov rsp, r4

    ; relocate the binary
    mov r0, [launch_fxf_binary_ptr]
    call parse_fxf_binary

    ; create a new task
    mov r1, r0
    call get_unused_task_id
    mov.8 [launch_fxf_task_id], r0
    mov r2, [launch_fxf_stack_ptr]
    add r2, 65516 ; point to the end of the stack (stack grows down!!)
    mov r3, [launch_fxf_binary_ptr]
    mov r4, [launch_fxf_stack_ptr]
    call new_task

    ; fall-through to launch_fxf_yield_loop

; loop until the launched task ends
launch_fxf_yield_loop:
    cmp.8 [launch_fxf_yield_should_suspend], 0
    ifz jmp shell_task_return
    movz.8 r0, [launch_fxf_task_id]
    call is_task_id_used
    ifz jmp shell_task_return
    call yield_task
    rjmp launch_fxf_yield_loop

allocate_error:
    mov r0, out_of_memory_string
    call print_str_to_terminal
    ret

launch_fxf_name: data.str "        fxf"
launch_fxf_spaces: data.str "        "
launch_fxf_struct: data.32 0 data.32 0
launch_fxf_task_id: data.8 0
launch_fxf_binary_ptr: data.32 0
launch_fxf_stack_ptr: data.32 0

launch_fxf_yield_should_suspend: data.8 0

out_of_memory_string: data.str "failed to allocate for new task!" data.8 10 data.8 0
