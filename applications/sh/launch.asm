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

launch_fxf_check_suspend_prefix:
    ; if the name was prefixed with a '*' character then
    ; clear a flag to have the shell return control immediately
    cmp.8 [r0], '*'
    ifnz mov.8 [launch_fxf_yield_should_suspend], 1
    ifnz jmp launch_fxf_check_debug_prefix
    inc r0
    mov.8 [launch_fxf_yield_should_suspend], 0
    jmp launch_fxf_check_disk_prefix
launch_fxf_check_debug_prefix:
    ; if the name was prefixed with a '%' character then
    ; set a flag to cause a breakpoint at the beginning of the
    ; program
    cmp.8 [r0], '%'
    ifnz mov.8 [launch_fxf_debug_mode], 0
    ifnz jmp launch_fxf_check_disk_prefix
    inc r0
    mov.8 [launch_fxf_debug_mode], 1
launch_fxf_check_disk_prefix:
    ; if the name was prefixed with a digit character and a ':' character then
    ; use that as the disk ID
    mov.8 [launch_fxf_disk_to_use], 0xFF
    cmp.8 [r0+1], ':'
    ifnz jmp launch_fxf_no_prefix
    mov.8 [launch_fxf_disk_to_use], [r0]
    sub.8 [launch_fxf_disk_to_use], '0'
    inc r0, 2
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
    call get_current_disk_id
    cmp.8 [launch_fxf_disk_to_use], 0xFF
    ifz mov r1, r0
    ifnz movz.8 r1, [launch_fxf_disk_to_use]
    mov r0, launch_fxf_name
    mov r2, launch_fxf_struct
    call ryfs_open
    cmp r0, 0
    ifz ret

    ; allocate memory for the binary
    mov r0, launch_fxf_struct
    call get_size
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
    ; disable interrupts, because if an interrupt tried to use the stack
    ; during this then that probably wouldn't end well
    icl
    mov rsp, [launch_fxf_stack_ptr]
    add rsp, 65536 ; point to the end of the stack (stack grows down!!)
    push r3
    push r2
    push r1
    push r0
    push [shell_stream_struct_ptr]
    ; if we are in debug mode, push interrupt return info onto the stack
    cmp.8 [launch_fxf_debug_mode], 0
    ifz jmp launch_fxf_skip_push_reti_info
    push 0 ; return address, will be filled in once we have start address
    mov r1, rsp ; save address of return address to fill in later
    push.8 0x04 ; enable interrupts upon return
    push 0 ; don't care about exception parameter
launch_fxf_skip_push_reti_info:
    mov rsp, r4
    ise

    ; relocate the binary
    mov r0, [launch_fxf_binary_ptr]
    call parse_fxf_binary
    ; if we are in debug mode, fill in the return adress with the relocation
    ; address of the loaded binary
    cmp.8 [launch_fxf_debug_mode], 0
    ifz jmp launch_fxf_skip_fill_reti_addr
    mov [r1], r0
    ; set initial ip to launch_fxf_debug_start
    mov r0, launch_fxf_debug_start
launch_fxf_skip_fill_reti_addr:

    ; create a new task
    mov r1, r0
    call get_unused_task_id
    mov.8 [launch_fxf_task_id], r0
    mov r2, [launch_fxf_stack_ptr]
    add r2, 65516 ; point to the end of the stack (stack grows down!!)
    ; if we are in debug mode, there are 9 extra bytes on top of the stack
    cmp.8 [launch_fxf_debug_mode], 0
    ifnz sub r2, 9
    mov r3, [launch_fxf_binary_ptr]
    mov r4, [launch_fxf_stack_ptr]
    call new_task

    ; fall-through to launch_fxf_yield_loop

; loop until the launched task ends
launch_fxf_yield_loop:
    cmp.8 [launch_fxf_yield_should_suspend], 0
    ifz pop r0 ; pop our return addr off the stack so we return 2 levels up. this is cursed
    ifz ret
    movz.8 r0, [launch_fxf_task_id]
    call is_task_id_used
    ifz jmp shell_task_return
    call yield_task
    rjmp launch_fxf_yield_loop

allocate_error:
    mov r0, out_of_memory_string
    call print_str_to_terminal
    ret

; entry point for a program started in debug mode
launch_fxf_debug_start:
    icl
    ; jump indirect through system exception vector
    jmp [0x00000410]

launch_fxf_name: data.str "        fxf"
launch_fxf_spaces: data.str "        "
launch_fxf_struct: data.fill 0, 32
launch_fxf_task_id: data.8 0
launch_fxf_binary_ptr: data.32 0
launch_fxf_stack_ptr: data.32 0

launch_fxf_yield_should_suspend: data.8 0
launch_fxf_debug_mode: data.8 0
launch_fxf_disk_to_use: data.8 0xFF

out_of_memory_string: data.str "failed to allocate for new task!" data.8 10 data.8 0
