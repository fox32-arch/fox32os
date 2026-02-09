; FXF launching routines

; launch an FXF binary from an already opened file
; inputs:
; r0: pointer to file struct
; r1: reserved
; r2: argument 0
; r3: argument 1
; r4: argument 2
; r5: argument 3
; r6: argument 4
; outputs:
; r0: task ID of the new task, or 0xFFFFFFFF if error
launch_fxf_from_open_file:
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    push r2
    push r3
    push r4
    push r5
    push r6

    mov [launch_fxf_struct_ptr], r0
    mov [launch_fxf_name_ptr], launch_fxf_unnamed_str
    jmp launch_fxf_from_open_file_1

; launch an FXF binary from a file on disk
; inputs:
; r0: pointer to FXF binary name (8.3 format, for example "testfile.fxf" or "test.fxf")
; r1: disk ID
; r2: argument 0
; r3: argument 1
; r4: argument 2
; r5: argument 3
; r6: argument 4
; outputs:
; r0: task ID of the new task, or 0xFFFFFFFF if error
launch_fxf_from_disk:
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    push r2
    push r3
    push r4
    push r5
    push r6

    ; open the file
    mov [launch_fxf_struct_ptr], launch_fxf_struct
    mov [launch_fxf_name_ptr], r0
    mov r2, [launch_fxf_struct_ptr]
    call open
    cmp r0, 0
    ifz jmp launch_fxf_from_disk_file_error

    ; grab the last part of the file path (excluding extension) to use as the task name
    mov [launch_fxf_task_name], 0x20202020
    mov [launch_fxf_task_name_high], 0x20202020
    mov r0, [launch_fxf_name_ptr]
    call string_length
    add r0, [launch_fxf_name_ptr]
    sub r0, 5
    mov r1, 1
    mov r31, 8
launch_fxf_from_disk_build_task_name_loop:
    cmp.8 [r0], '/'
    ifz rjmp.16 launch_fxf_from_disk_build_task_name_loop_copy
    cmp r0, [launch_fxf_name_ptr]
    iflteq rjmp.16 launch_fxf_from_disk_build_task_name_loop_copy
    cmp.8 [r0], '.'
    ifnz inc r1
    dec r0
    rloop.16 launch_fxf_from_disk_build_task_name_loop
launch_fxf_from_disk_build_task_name_loop_copy:
    cmp.8 [r0], '/'
    ifnz rjmp.8 launch_fxf_from_disk_build_task_name_loop_copy_1
    inc r0
    dec r1
launch_fxf_from_disk_build_task_name_loop_copy_1:
    mov r2, r1
    mov r1, launch_fxf_task_name
    call copy_memory_bytes
launch_fxf_from_open_file_1:
    ; if this is not FXF version 0, then there is a bss section
    mov r0, 3
    mov r1, [launch_fxf_struct_ptr]
    call seek
    mov r0, 1
    mov r1, [launch_fxf_struct_ptr]
    mov r2, launch_fxf_bss_size
    call read
    cmp.8 [launch_fxf_bss_size], 0
    ifz mov [launch_fxf_bss_size], 0
    ifz jmp launch_fxf_continue
    mov r0, FXF_BSS_SIZE
    mov r1, [launch_fxf_struct_ptr]
    call seek
    mov r0, 4
    mov r1, [launch_fxf_struct_ptr]
    mov r2, launch_fxf_bss_size
    call read
launch_fxf_continue:
    mov r0, 0
    mov r1, [launch_fxf_struct_ptr]
    call seek
    ; allocate memory for the binary
    mov r0, [launch_fxf_struct_ptr]
    call get_size
    add r0, [launch_fxf_bss_size]
    call allocate_memory
    cmp r0, 0
    ifz jmp launch_fxf_from_disk_allocate_error
    mov [launch_fxf_binary_ptr], r0

    ; read the file into memory
    mov r0, [launch_fxf_struct_ptr]
    mov r1, [launch_fxf_binary_ptr]
    call ryfs_read_whole_file

    ; allocate a 64KiB stack
    mov r0, 65536
    call allocate_memory
    cmp r0, 0
    ifz jmp launch_fxf_from_disk_allocate_error
    mov [launch_fxf_stack_ptr], r0

    ; push the arguments to the task's stack
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    mov r5, rsp
    icl
    mov rsp, [launch_fxf_stack_ptr]
    add rsp, 65536 ; point to the end of the stack (stack grows down!!)
    push r4
    push r3
    push r2
    push r1
    push r0
    sub rsp, 65516
    mov [launch_fxf_stack_ptr], rsp
    mov rsp, r5
    ise

    ; relocate the binary
    mov r0, [launch_fxf_binary_ptr]
    call parse_fxf_binary
    cmp r0, 0
    ifz jmp launch_fxf_from_disk_reloc_error

    ; check for app header
    mov r1, app_magic
    mov r2, 3
    call compare_memory_bytes
    ifz mov r0, [r0+APP_ENTRY_POINT] ; grab entry point if the header exists

    ; create a new task
    mov r1, r0
    call get_unused_task_id
    mov.8 [launch_fxf_task_id], r0
    mov r2, [launch_fxf_stack_ptr]
    add r2, 65516 ; point to the end of the stack (stack grows down!!)
    mov r3, [launch_fxf_binary_ptr]
    mov r4, [launch_fxf_stack_ptr]
    movz.16 r5, [current_directory]
    sla r5, 16
    mov.8 r5, [current_disk_id]
    mov r6, launch_fxf_task_name
    call new_task

    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    movz.8 r0, [launch_fxf_task_id]
    ret
launch_fxf_from_disk_allocate_error:
    mov r0, launch_fxf_allocate_error_string
    call panic
launch_fxf_from_disk_file_error:
    pop r6 ; remove extra copies of arguments from stack
    pop r5
    pop r4
    pop r3
    pop r2

    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    mov r0, 0xFFFFFFFF
    ret
launch_fxf_from_disk_reloc_error:
    mov r0, [launch_fxf_binary_ptr]
    call free_memory
    mov r0, [launch_fxf_stack_ptr]
    call free_memory

    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    mov r0, 0xFFFFFFFF
    ret

launch_fxf_struct_ptr: data.32 0
launch_fxf_struct: data.fill 0, 32
launch_fxf_task_id: data.8 0
launch_fxf_binary_ptr: data.32 0
launch_fxf_stack_ptr: data.32 0
launch_fxf_bss_size: data.32 0

launch_fxf_name_ptr: data.32 0
launch_fxf_unnamed_str: data.strz "unnamed#"
launch_fxf_task_name: data.fill 0, 4
launch_fxf_task_name_high: data.fill 0, 4
launch_fxf_task_name_top: data.8 0

launch_fxf_allocate_error_string: data.strz "Failed to allocate memory for a new task"
