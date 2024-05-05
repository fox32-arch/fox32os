; fox32os kernel

    opton

const LOAD_ADDRESS: 0x03000000

const FOX32OS_VERSION_MAJOR: 0
const FOX32OS_VERSION_MINOR: 2
const FOX32OS_VERSION_PATCH: 0

const FOX32OS_API_VERSION: 1

const REQUIRED_FOX32ROM_API_VERSION: 2

const SYSTEM_STACK:     0x01FFF800
const BACKGROUND_COLOR: 0xFF674764
const TEXT_COLOR:       0xFFFFFFFF

    jmp entry

    ; system jump table
    org.pad 0x00000010
jump_table:
    data.32 get_os_version
    data.32 get_os_api_version
    data.32 get_current_disk_id
    data.32 set_current_disk_id
    data.32 get_boot_disk_id

    ; FXF jump table
    org.pad 0x00000110
    data.32 parse_fxf_binary
    data.32 launch_fxf_from_disk
    data.32 launch_fxf_from_open_file

    ; task jump table
    org.pad 0x00000210
    data.32 new_task
    data.32 yield_task
    data.32 end_current_task
    data.32 get_current_task_id
    data.32 get_unused_task_id
    data.32 is_task_id_used
    data.32 save_state_and_yield_task
    data.32 sleep_task

    ; memory jump table
    org.pad 0x00000310
    data.32 allocate_memory
    data.32 free_memory

    ; window jump table
    org.pad 0x00000410
    data.32 new_window
    data.32 destroy_window
    data.32 new_window_event
    data.32 get_next_window_event
    data.32 draw_title_bar_to_window
    data.32 move_window
    data.32 fill_window
    data.32 get_window_overlay_number
    data.32 start_dragging_window
    data.32 new_messagebox
    data.32 get_active_window_struct
    data.32 set_window_flags

    ; VFS jump table
    org.pad 0x00000510
    data.32 open
    data.32 seek
    data.32 tell
    data.32 read
    data.32 write
    data.32 get_size
    data.32 create
    data.32 delete
    data.32 copy

    ; widget jump table
    org.pad 0x00000610
    data.32 draw_widgets_to_window
    data.32 handle_widget_click

    ; resource jump table
    org.pad 0x00000710
    data.32 get_resource
jump_table_end:

    ; initialization code
entry:
    ; before doing anything, check if we are running on top of an existing instance of the kernel
    ; we can do this by comparing our load address to the known load address that the bootloader loads us to
    ; only the high 16 bits are checked
    rcall 6
    pop r1
    mov.16 r1, 0
    cmp r1, LOAD_ADDRESS
    ifz jmp entry_ok

    ; if it appears that we're running on top of an existing kernel, then show a messagebox and exit
    ; call the messagebox routines of the existing kernel
    mov r0, 0
    mov r1, kernelception_error_str
    mov r2, 0
    mov r3, 64
    mov r4, 64
    mov r5, 184
    call [0x00000C34] ; new_messagebox
    call [0x00000A18] ; end_current_task
    rjmp 0

entry_ok:
    mov rsp, SYSTEM_STACK

    ; save the boot disk id that the bootloader passed in r0
    mov.8 [boot_disk_id], r0
    mov.8 [current_disk_id], r0

    ; clear the background
    mov r0, BACKGROUND_COLOR
    call fill_background

    ; check for the required fox32rom API version
    mov r0, get_rom_api_version
    add r0, 2
    mov r0, [r0]
    cmp [r0], 0
    ifz jmp api_version_too_low_error
    call get_rom_api_version
    cmp r0, REQUIRED_FOX32ROM_API_VERSION
    iflt jmp api_version_too_low_error

    ; initialize the memory allocator
    call initialize_allocator

    ; draw the bottom bar
    mov r0, bottom_bar_str_0
    mov r1, 8
    mov r2, 448
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    call draw_str_to_background
    mov r0, bottom_bar_patterns
    mov r1, 1
    mov r2, 16
    call set_tilemap
    mov r1, 0
    mov r2, 464
    mov r31, 640
draw_bottom_bar_loop:
    mov r4, r31
    rem r4, 2
    cmp r4, 0
    ifz mov r0, 0
    ifnz mov r0, 1
    call draw_tile_to_background
    inc r1
    loop draw_bottom_bar_loop
    mov r0, 10
    mov r1, 464
    mov r2, 20
    mov r3, 16
    mov r4, 0xFFFFFFFF
    call draw_filled_rectangle_to_background
    mov r0, bottom_bar_str_1
    mov r1, 12
    mov r2, 464
    mov r3, 0xFF000000
    mov r4, 0xFFFFFFFF
    call draw_str_to_background
    mov r0, bottom_bar_str_2
    mov r1, 488
    mov r2, 464
    mov r3, 0xFF000000
    mov r4, 0xFFFFFFFF
    mov r10, FOX32OS_VERSION_MAJOR
    mov r11, FOX32OS_VERSION_MINOR
    mov r12, FOX32OS_VERSION_PATCH
    call draw_format_str_to_background

    ; copy the jump table to 0x00000810
    mov r0, jump_table
    mov r1, 0x00000810
    mov r2, jump_table_end
    sub r2, jump_table
    call copy_memory_bytes

    ; check if a disk is inserted as disk 1
    ; if so, skip checking startup.bat and just run disk 1
    in r31, 0x80001001
    cmp r31, 0
    ifnz jmp boot_disk_1
try_startup:
    mov r0, serial_stream
    mov r2, serial_stream_struct
    call open

    mov r0, startup_bat
    movz.8 r1, [boot_disk_id]
    mov r2, startup_bat_check_struct
    call open
    cmp r0, 0
    ifz jmp emergency_shell

    ; run `sh startup.bat` with IO redirected to :serial
    mov r0, sh_fxf
    movz.8 r1, [boot_disk_id]
    mov r2, serial_stream_struct
    mov r3, startup_bat
    mov r4, 0
    mov r5, 0
    mov r6, 0
    call launch_fxf_from_disk
    cmp r0, 0xFFFFFFFF
    ifz jmp startup_error

no_other_tasks:
    ; start the event manager task
    call start_event_manager_task

    ; jump back to it without adding this "task" (not really a task) into the queue.
    ; end_current_task_no_mark_no_free is used specifically because it doesn't mark
    ;   the current task (still set to 0) as unused, and it doesn't free the memory
    ;   block.
    ; this does not return.
    call end_current_task_no_mark_no_free

emergency_shell:
    mov r0, sh_fxf
    movz.8 r1, [boot_disk_id]
    mov r2, serial_stream_struct
    mov r3, 0
    mov r4, 0
    mov r5, 0
    mov r6, 0
    call launch_fxf_from_disk
    cmp r0, 0xFFFFFFFF
    ifz jmp startup_error
    jmp no_other_tasks

; try loading the raw contents of disk 1 as an FXF binary
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
    cmp r0, 0
    ifz jmp disk_1_is_not_fxf
    mov r3, r1
    mov r1, r0
    mov r0, 0
    mov r2, rsp
    sub r2, 4
    mov r4, 0 ; don't attempt to free any stack block if the task ends
    call new_task
    jmp no_other_tasks

; disk 1 was found to not be a valid FXF binary
; free the memory allocated for it and instead just keep it mounted as a disk
disk_1_is_not_fxf:
    mov r0, r5
    call free_memory
    jmp try_startup

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

api_version_too_low_error:
    mov r0, BACKGROUND_COLOR
    call fill_background

    mov r0, api_error_str
    mov r1, 16
    mov r2, 464
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    mov r10, FOX32OS_VERSION_MAJOR
    mov r11, FOX32OS_VERSION_MINOR
    mov r12, FOX32OS_VERSION_PATCH
    call draw_format_str_to_background
    rjmp 0

get_boot_disk_id:
    movz.8 r0, [boot_disk_id]
    ret

get_current_disk_id:
    movz.8 r0, [current_disk_id]
    ret

set_current_disk_id:
    mov.8 [current_disk_id], r0
    ret

get_os_version:
    mov r0, FOX32OS_VERSION_MAJOR
    mov r1, FOX32OS_VERSION_MINOR
    mov r2, FOX32OS_VERSION_PATCH
    ret

get_os_api_version:
    mov r0, FOX32OS_API_VERSION
    ret

    #include "allocator.asm"
    #include "fxf/fxf.asm"
    #include "res.asm"
    #include "task.asm"
    #include "vfs/vfs.asm"
    #include "widget/widget.asm"
    #include "window/window.asm"

bottom_bar_str_0: data.strz "FOX"
bottom_bar_str_1: data.strz "32"
bottom_bar_str_2: data.strz " OS version %u.%u.%u "
startup_error_str: data.strz "fox32 - OS version %u.%u.%u - sh.fxf is missing?"
memory_error_str: data.strz "fox32 - OS version %u.%u.%u - not enough memory to perform operation!"
api_error_str: data.strz "fox32 - OS version %u.%u.%u - fox32rom API version too low!"
kernelception_error_str: data.strz "Error: kernelception?"
bottom_bar_patterns:
    ; 1x16 tile
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF

    ; 1x16 tile
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764
    data.32 0xFFFFFFFF
    data.32 0xFF674764

current_disk_id: data.8 0
boot_disk_id: data.8 0
sh_fxf: data.strz "sh.fxf"
startup_bat: data.strz "startup.bat"
startup_bat_check_struct: data.fill 0, 32
serial_stream: data.strz ":serial"
serial_stream_struct: data.fill 0, 32

    #include "../../fox32rom/fox32rom.def"

kernel_bottom:
