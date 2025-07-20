; copy a minimal fox32os installation to a disk

    opton

    pop [stream]
    pop [disk]
    cmp [disk], 0
    ifz jmp usage_error

    mov r0, [disk]
    mov r1, 10
    call string_to_int
    mov [disk], r0
    cmp r0, 5
    ifgt jmp disk_error

    ; create /system
    mov r0, system_dir_str
    mov r1, [disk]
    mov r2, file_struct
    call create_dir
    cmp r0, 0
    ifz jmp file_error

    ; create /apps
    mov r0, apps_dir_str
    mov r1, [disk]
    mov r2, file_struct
    call create_dir
    cmp r0, 0
    ifz jmp file_error

    ; create /user
    mov r0, user_dir_str
    mov r1, [disk]
    mov r2, file_struct
    call create_dir
    cmp r0, 0
    ifz jmp file_error

    ; copy minimum usable system
    mov r31, NUM_FILES
    mov r0, files_to_copy
copy_loop:
    push r0
    mov r0, [r0]
    call copy_file
    pop r0
    inc r0, 4
    loop copy_loop

    mov r0, boot_sector_str
    call print

    mov r0, 512
    call allocate_memory
    cmp r0, 0
    ifz jmp memory_error
    push r0
    mov r2, r0
    call get_boot_disk_id
    mov r1, r0
    mov r0, 0
    call read_sector
    mov r1, [disk]
    call write_sector
    pop r0
    call free_memory

    mov r0, done_str
    call print

    call end_current_task

memory_error:
    mov r0, memory_error_str
    rjmp error
disk_error:
    mov r0, disk_error_str
    rjmp error
file_error:
    mov r0, file_error_str
    rjmp error
usage_error:
    mov r0, usage_error_str
error:
    call print
    call end_current_task

; copy a file from the boot disk to the destination disk
; inputs:
; r0: path for both files (e.g. "/system/kernel.fxf")
copy_file:
    push r10
    mov r10, r0

    mov r0, copying_str
    call print
    mov r0, r10
    call print
    mov r0, lf_str
    call print

    call get_boot_disk_id
    mov r1, r0
    mov r2, file_struct
    mov r0, r10
    call open
    cmp r0, 0
    ifz jmp file_error

    mov r0, file_struct
    call get_size
    mov r3, r0
    mov r0, r10
    mov r1, [disk]
    mov r2, dest_file_struct
    call create
    cmp r0, 0
    ifz jmp file_error

    mov r0, file_struct
    mov r1, dest_file_struct
    call copy

    pop r10
    ret

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
memory_error_str: data.str "failed to allocate memory" data.8 10 data.8 0
disk_error_str: data.str "disk ID must be <= 5" data.8 10 data.8 0
file_error_str: data.str "failed to copy files" data.8 10 data.8 0
copying_str: data.strz "copying "
boot_sector_str: data.str "copying boot1" data.8 10 data.8 0
lf_str: data.8 10 data.8 0
usage_error_str: data.str "usage: sysdisk <disk ID>" data.8 10 data.8 0
stream: data.32 0
disk: data.32 0
system_dir_str: data.strz "/system"
apps_dir_str: data.strz "/apps"
user_dir_str: data.strz "/user"
file_struct: data.fill 0, 32
dest_file_struct: data.fill 0, 32

const NUM_FILES: 8
files_to_copy:
    data.32 boot2_path
    data.32 kernel_path
    data.32 startup_bat_path
    data.32 sh_path
    data.32 format_path
    data.32 ted_path
    data.32 sysdisk_path
    data.32 terminal_path

boot2_path: data.strz "/system/boot2.bin"
kernel_path: data.strz "/system/kernel.fxf"
startup_bat_path: data.strz "/system/startup.bat"
sh_path: data.strz "/system/sh.fxf"
format_path: data.strz "/system/format.fxf"
ted_path: data.strz "/system/ted.fxf"
sysdisk_path: data.strz "/system/sysdisk.fxf"
terminal_path: data.strz "/apps/terminal.fxf"

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
