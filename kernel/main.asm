; fox32os kernel

    opton

const BOOT_MAGIC: 0x523C334C

const FOX32OS_VERSION_MAJOR: 0
const FOX32OS_VERSION_MINOR: 4
const FOX32OS_VERSION_PATCH: 0
const FOX32OS_API_VERSION: 3

const REQUIRED_FOX32ROM_API_VERSION: 4

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
    data.32 open_library
    data.32 close_library
    data.32 get_current_directory
    data.32 set_current_directory

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
    data.32 get_task_queue

    ; memory jump table
    org.pad 0x00000310
    data.32 allocate_memory
    data.32 free_memory
    data.32 heap_usage

    ; VFS jump table
    org.pad 0x00000410
    data.32 open
    data.32 seek
    data.32 tell
    data.32 read
    data.32 write
    data.32 get_size
    data.32 create
    data.32 delete
    data.32 copy
    data.32 get_dir_name
    data.32 get_parent_dir
    data.32 create_dir

    ; resource jump table
    org.pad 0x00000510
    data.32 get_resource
    data.32 get_res_in_fxf
jump_table_end:

    ; initialization code
entry:
    ; validate magic bytes
    ; the bootloader puts them in rsp as under normal circumstances rsp will never be this high
    cmp rsp, BOOT_MAGIC
    ifz jmp entry_ok

    ; if it appears that we're running on top of an existing kernel, then just exit
    jmp [0x00000A18] ; end_current_task of the existing kernel

entry_ok:
    ; r0: boot disk id
    ; r1: total memory
    ; r2: usable memory (i.e. memory not used by fox32rom)
    ; r3: kernel base address
    mov rsp, kernel_end
    add rsp, 1024 ; the bootloader left us 1024 bytes of memory after the kernel
    mov.8 [boot_disk_id], r0
    mov.8 [current_disk_id], r0
    mov [memory_top], r3
    ise

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

    ; install exception handlers
    mov [0x00000400], task_crash_handler ; exception 0x00 - divide by zero
    mov [0x00000404], task_crash_handler ; exception 0x01 - invalid opcode
    mov [0x00000408], task_crash_handler ; exception 0x02 - page fault read
    mov [0x0000040C], task_crash_handler ; exception 0x03 - page fault write

    ; install interrupt handlers
    mov [0x000003FC], kernel_vsync_handler ; interrupt 0xFF

    ; initialize the memory allocator
    call initialize_allocator

    ; initialize the menu bar overlay
    call enable_menu_bar
    call clear_menu_bar

    ; draw the splash string
    mov r0, splash_str
    mov r1, 16
    mov r2, 464
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
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

try_startup:
    mov r0, serial_stream
    mov r2, serial_stream_struct
    call open

    ; search each disk for a startup.bat and execute them in a shell
    ; if the boot disk has none, open an 'emergency' shell on serial
    mov r10, 0 ; disk ID
try_startup_loop:
    mov r0, startup_bat
    mov r1, r10
    mov r2, startup_bat_check_struct
    call open
    ; if startup.bat exists, pass it as the first argument to shell
    cmp r0, 0
    ifnz jmp try_startup_loop_format
    ; if this is the boot disk, pass no arguments for emergency shell
    ; otherwise, skip opening a shell
    cmp.8 r10, [boot_disk_id]
    ifnz jmp try_startup_loop_final
    mov r3, 0
    jmp try_startup_loop_launch
try_startup_loop_format:
    mov r3, disk_startup_bat
    mov r0, r10
    add r0, '0'
    mov.8 [r3], r0
try_startup_loop_launch:
    mov r0, sh_fxf
    movz.8 r1, [boot_disk_id]
    mov r2, serial_stream_struct
    ; r3 either is null or points to "N:startup.bat"
    mov r4, 0
    mov r5, 0
    mov r6, 0
    call launch_fxf_from_disk
    cmp r0, 0xFFFFFFFF
    ifz jmp startup_error
try_startup_loop_final:
    inc r10
    cmp r10, 6
    iflt jmp try_startup_loop

no_other_tasks:
    ; jump back to it without adding this "task" (not really a task) into the queue.
    ; end_current_task_no_mark_no_free is used specifically because it doesn't mark
    ;   the current task (still set to 0) as unused, and it doesn't free the memory
    ;   block.
    ; this does not return.
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

get_current_directory:
    movz.16 r0, [current_directory]
    ret

set_current_directory:
    mov.16 [current_directory], r0
    ret

get_os_version:
    mov r0, FOX32OS_VERSION_MAJOR
    mov r1, FOX32OS_VERSION_MINOR
    mov r2, FOX32OS_VERSION_PATCH
    ret

get_os_api_version:
    mov r0, FOX32OS_API_VERSION
    ret

const DEFAULT_CURSOR_FRAMEBUFFER_PTR: 0x00000020
set_default_cursor:
    push r0
    push r1
    push r2

    mov r0, 8
    mov r1, 12
    mov r2, 31
    call resize_overlay
    mov r0, [DEFAULT_CURSOR_FRAMEBUFFER_PTR]
    mov r1, 31
    call set_overlay_framebuffer_pointer

    pop r2
    pop r1
    pop r0
    ret

; inputs:
; r0: number of frames to keep the busy cursor (0 for infinite)
set_busy_cursor:
    push r0
    push r1
    push r2

    mov r0, 18
    mov r1, 12
    mov r2, 31
    call resize_overlay
    mov r0, busy_cursor
    mov r1, 31
    call set_overlay_framebuffer_pointer

    pop r2
    pop r1
    pop r0
    mov [cursor_change_counter], r0
    ret

    #include "allocator.asm"
    #include "crash.asm"
    #include "fxf/fxf.asm"
    #include "lbr/lbr.asm"
    #include "res.asm"
    #include "task.asm"
    #include "vfs/vfs.asm"
    #include "vsync.asm"

busy_cursor:
    #include "cursor/busy.inc"

splash_str: data.strz "fox32os version %u.%u.%u"
startup_error_str: data.strz "fox32os version %u.%u.%u - sh.fxf is missing?"
memory_error_str: data.strz "fox32os version %u.%u.%u - not enough memory to perform operation!"
api_error_str: data.strz "fox32os version %u.%u.%u - fox32rom API version too low!"
kernelception_error_str: data.strz "Error: kernelception?"

boot_disk_id: data.8 0
sh_fxf: data.strz "/system/sh.fxf"
disk_startup_bat: data.str "N:"
startup_bat: data.strz "/system/startup.bat"
startup_bat_check_struct: data.fill 0, 32
serial_stream: data.strz ":serial"
serial_stream_struct: data.fill 0, 32

    #include "../../fox32rom/fox32rom.def"

kernel_end:
