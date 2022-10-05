; fox32os kernel

    org 0x00000800

const FOX32OS_VERSION_MAJOR: 0
const FOX32OS_VERSION_MINOR: 1
const FOX32OS_VERSION_PATCH: 0

const SYSTEM_STACK:     0x01FFF800
const BACKGROUND_COLOR: 0xFF674764
const TEXT_COLOR:       0xFFFFFFFF

    jmp entry

jump_table:
    ; system jump table
    org.pad 0x00000810
    data.32 get_os_version

    ; FXF jump table
    org.pad 0x00000910
    data.32 parse_fxf_binary

    ; task jump table
    org.pad 0x00000A10
    data.32 new_task
    data.32 yield_task
    data.32 end_current_task
    data.32 get_current_task_id
    data.32 get_unused_task_id
    data.32 is_task_id_used

    ; memory jump table
    org.pad 0x00000B10
    data.32 allocate_memory
    data.32 free_memory

    ; window jump table
    org.pad 0x00000C10
    data.32 new_window
    data.32 destroy_window
    data.32 new_window_event
    data.32 get_next_window_event
    data.32 draw_title_bar_to_window
    data.32 move_window
    data.32 fill_window
    data.32 get_window_overlay_number
    data.32 start_dragging_window

    ; initialization code
entry:
    mov rsp, SYSTEM_STACK

    ; clear the background
    mov r0, BACKGROUND_COLOR
    call fill_background

    ; initialize the memory allocator
    call initialize_allocator

    ; draw the startup text
    mov r0, startup_str
    mov r1, 16
    mov r2, 464
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    mov r10, FOX32OS_VERSION_MAJOR
    mov r11, FOX32OS_VERSION_MINOR
    mov r12, FOX32OS_VERSION_PATCH
    call draw_format_str_to_background

    ; check if a disk is inserted as disk 1
    ; if so, skip checking startup.cfg and just run disk 1
    in r31, 0x80001001
    cmp r31, 0
    ifnz jmp boot_disk_1

    ; open startup.cfg
    mov r0, startup_cfg
    mov r1, 0
    mov r2, startup_cfg_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp boot_disk_1

    ; load a startup task
load_startup_task:
    ; load 11 bytes of startup.cfg into startup_file
    mov r0, 11
    mov r1, startup_cfg_struct
    mov r2, startup_file
    call ryfs_read

    ; open the actual startup file
    mov r0, startup_file
    mov r1, 0
    mov r2, startup_file_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp boot_disk_1

    ; allocate memory for the startup file
    mov r0, startup_file_struct
    call ryfs_get_size
    call allocate_memory
    cmp r0, 0
    ifz jmp memory_error
    mov [startup_file_binary_ptr], r0

    ; allocate 64KiB for the startup file's stack
    mov r0, 65536
    call allocate_memory
    cmp r0, 0
    ifz jmp memory_error
    mov [startup_file_stack_ptr], r0

    ; read the startup file into memory
    mov r0, startup_file_struct
    mov r1, [startup_file_binary_ptr]
    call ryfs_read_whole_file

    ; relocate and execute it as a new task
    mov r0, r1
    call parse_fxf_binary
    mov r3, r1
    mov r1, r0
    movz.8 r0, [next_task_id]
    mov r2, [startup_file_stack_ptr]
    add r2, 65536
    sub r2, 4
    mov r4, [startup_file_stack_ptr]
    call new_task

    ; when the startup file yields for the first time, we'll end up back here
    ; now, check to see if startup.cfg has any other entries
    ; we do this by checking to see if the size of startup.cfg is less than or equal to 12 * next_task_id bytes
    inc.8 [next_task_id]
    mov r0, startup_cfg_struct
    call ryfs_get_size
    movz.8 r1, [next_task_id]
    mul r1, 12
    cmp r0, r1
    iflteq jmp no_other_tasks

    ; seek forward one byte to skip the linefeed
    mov r0, startup_cfg_struct
    call ryfs_tell
    inc r0
    mov r1, startup_cfg_struct
    call ryfs_seek

    ; load the next task
    jmp load_startup_task

no_other_tasks:
    ; start the event manager task
    call start_event_manager_task

    ; jump back to it without adding this "task" (not really a task) into the queue.
    ; end_current_task_no_mark_no_free is used specifically because it doesn't mark
    ;   the current task (still set to 0) as unused, and it doesn't free the memory
    ;   block.
    ; this does not return.
    call end_current_task_no_mark_no_free

; if startup.cfg is invalid, try loading the raw contents of disk 1 as an FXF binary
; if disk 1 is not inserted, then fail
boot_disk_1:
    ; check if a disk is inserted as disk 1
    in r31, 0x80001001
    cmp r31, 0
    ifz jmp startup_error

    ; a disk is inserted, load it!!

    ; allocate memory for the startup file
    ; r31 contains disk size
    mov r0, r31
    call allocate_memory
    cmp r0, 0
    ifz jmp memory_error

    div r31, 512
    inc r31

    mov r2, r0         ; destination pointer
    mov r5, r0
    mov r0, 0          ; sector counter
    mov r3, 0x80003001 ; command to read a sector from disk 1 into memory
    mov r4, 0x80002000 ; command to set the location of the buffer
boot_disk_1_loop:
    out r4, r2         ; set the memory buffer location
    out r3, r0         ; read the current sector into memory
    inc r0             ; increment sector counter
    add r2, 512        ; increment the destination pointer
    loop boot_disk_1_loop

    mov r1, r5
    mov r0, r5
    call parse_fxf_binary
    mov r3, r1
    mov r1, r0
    movz.8 r0, [next_task_id]
    mov r2, rsp
    sub r2, 4
    mov r4, 0 ; don't attempt to free any stack block if the task ends
    call new_task
    call end_current_task_no_mark_no_free

startup_error:
    mov r0, BACKGROUND_COLOR
    call fill_background

    mov r0, startup_error_str
    mov r1, 16
    mov r2, 464
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    mov r10, FOX32OS_VERSION_MAJOR
    mov r11, FOX32OS_VERSION_MINOR
    mov r12, FOX32OS_VERSION_PATCH
    call draw_format_str_to_background
    rjmp 0

memory_error:
    mov r0, BACKGROUND_COLOR
    call fill_background

    mov r0, memory_error_str
    mov r1, 16
    mov r2, 464
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    mov r10, FOX32OS_VERSION_MAJOR
    mov r11, FOX32OS_VERSION_MINOR
    mov r12, FOX32OS_VERSION_PATCH
    call draw_format_str_to_background
    rjmp 0

get_os_version:
    mov r0, FOX32OS_VERSION_MAJOR
    mov r1, FOX32OS_VERSION_MINOR
    mov r2, FOX32OS_VERSION_PATCH
    ret

    #include "allocator.asm"
    #include "fxf/fxf.asm"
    #include "task.asm"
    #include "window/window.asm"

startup_str: data.str "fox32 - OS version %u.%u.%u" data.8 0
startup_error_str: data.str "fox32 - OS version %u.%u.%u - startup.cfg is invalid!" data.8 0
memory_error_str: data.str "fox32 - OS version %u.%u.%u - not enough memory to perform operation!" data.8 0

next_task_id: data.8 0
startup_cfg: data.str "startup cfg"
startup_cfg_struct: data.32 0 data.32 0
startup_file: data.str "           "
startup_file_struct: data.32 0 data.32 0
startup_file_binary_ptr: data.32 0
startup_file_stack_ptr: data.32 0

    #include "../../fox32rom/fox32rom.def"

kernel_bottom:
