; FXF launcher helper routines

; FIXME: this should really use the `launch_fxf_from_open_file` routine
;        it will need some work to ensure things like the debug prefix works though

; launch an FXF binary from a shell entry
; inputs:
; r0: pointer to FXF binary name
; outputs:
; none, does not return if task started successfully
; returns if FXF file not found
launch_fxf:
launch_fxf_check_suspend_prefix:
    ; if the name was prefixed with a '*' character then
    ; clear a flag to have the shell return control immediately
    cmp.8 [r0], '*'
    ifnz mov.8 [launch_fxf_yield_should_suspend], 1
    ifnz jmp launch_fxf_check_debug_prefix
    inc r0
    mov.8 [launch_fxf_yield_should_suspend], 0
    jmp launch_fxf_no_prefix
launch_fxf_check_debug_prefix:
    ; if the name was prefixed with a '%' character then
    ; set a flag to cause a breakpoint at the beginning of the
    ; program
    cmp.8 [r0], '%'
    ifnz mov.8 [launch_fxf_debug_mode], 0
    ifnz jmp launch_fxf_no_prefix
    inc r0
    mov.8 [launch_fxf_debug_mode], 1
launch_fxf_no_prefix:
    ; copy the name into the launch_fxf_name buffer
    mov r1, launch_fxf_name
    call copy_string
    mov r0, launch_fxf_name
    call string_length
    add r0, launch_fxf_name
    dec r0, 4
    cmp [r0], 0x6678662E
    ifnz call launch_fxf_add_ext

    ; open the file
    call get_current_disk_id
    mov r1, r0
    mov r0, launch_fxf_name
    mov r2, launch_fxf_struct
    call open
    cmp r0, 0
    ifz ret

    ; if this is not FXF version 0, then there is a bss section
    mov r0, 3
    mov r1, launch_fxf_struct
    call seek
    mov r0, 1
    mov r1, launch_fxf_struct
    mov r2, launch_fxf_temp
    call read
    cmp.8 [launch_fxf_temp], 0
    ifz mov [launch_fxf_temp], 0
    ifz jmp launch_fxf_continue
    mov r0, 0x14
    mov r1, launch_fxf_struct
    call seek
    mov r0, 4
    mov r1, launch_fxf_struct
    mov r2, launch_fxf_temp
    call read
launch_fxf_continue:
    mov r0, 0
    mov r1, launch_fxf_struct
    call seek
    ; allocate memory for the binary
    mov r0, launch_fxf_struct
    call get_size
    add r0, [launch_fxf_temp] ; add bss size found above
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

    ; push the arguments, their pointers, and the terminal stream struct pointer to the task's stack
    call shell_parse_arguments
    push r3
    push r2
    push r1
    push r0
    mov r1, [launch_fxf_stack_ptr]
    add r1, 65024 ; point to the end of the stack - argument string space
    mov r31, 4
launch_fxf_copy_args_loop:
    pop r0
    cmp r0, 0
    ifz jmp launch_fxf_copy_args_done
    call copy_string
    call string_length
    add r1, r0
    inc r1
launch_fxf_copy_args_done:
    loop launch_fxf_copy_args_loop
    mov r0, [launch_fxf_stack_ptr]
    add r0, 65024 ; point to the end of the stack - argument string space
    mov r1, 0
    mov r31, 4
launch_fxf_get_arg_ptrs_loop:
    cmp.8 [r0], 0
    ifz push 0
    ifnz push r0
    call shell_tokenize
    loop launch_fxf_get_arg_ptrs_loop
    pop r3
    pop r2
    pop r1
    pop r0

    mov r4, rsp
    ; disable interrupts, because if an interrupt tried to use the stack
    ; during this then that probably wouldn't end well
    icl
    mov rsp, [launch_fxf_stack_ptr]
    add rsp, 65024 ; point to the end of the stack - argument string space
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
    push r0
    call get_current_directory
    movz.16 r5, r0
    sla r5, 16
    call get_current_disk_id
    mov.16 r5, r0
    pop r0
    mov r1, r0
    call get_unused_task_id
    mov.8 [launch_fxf_task_id], r0
    mov r2, [launch_fxf_stack_ptr]
    add r2, 65004 ; point to the end of the stack (stack grows down!!)
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
    ifz pop r0 ; discard
    ifz pop r0 ; discard
    ifz pop r0 ; discard
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

launch_fxf_add_ext:
    mov r0, launch_fxf_name
    call string_length
    add r0, launch_fxf_name
    mov r1, r0
    mov r0, fxf_str
    call copy_string
    ret

fxf_str: data.strz ".fxf"
launch_fxf_name: data.fill 0, 128
launch_fxf_struct: data.fill 0, 32
launch_fxf_task_id: data.8 0
launch_fxf_binary_ptr: data.32 0
launch_fxf_stack_ptr: data.32 0
launch_fxf_temp: data.32 0

launch_fxf_yield_should_suspend: data.8 0
launch_fxf_debug_mode: data.8 0

out_of_memory_string: data.str "failed to allocate for new task!" data.8 10 data.8 0
