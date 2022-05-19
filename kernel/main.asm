; fox32os kernel

    org 0x00000800

const FOX32OS_VERSION_MAJOR: 0
const FOX32OS_VERSION_MINOR: 1
const FOX32OS_VERSION_PATCH: 0

const BACKGROUND_COLOR: 0xFF674764
const TEXT_COLOR:       0xFFFFFFFF

    ; initialization code
entry:
    ; clear the background
    mov r0, BACKGROUND_COLOR
    call fill_background

draw_startup_text:
    mov r0, startup_str
    mov r1, 16
    mov r2, 464
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    mov r10, FOX32OS_VERSION_MAJOR
    mov r11, FOX32OS_VERSION_MINOR
    mov r12, FOX32OS_VERSION_PATCH
    call draw_format_str_to_background

    ; open startup.cfg
    mov r0, startup_file
    mov r1, 0
    mov r2, startup_file_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp startup_error

    ; load the first 11 bytes of startup.cfg, overwriting the "startup cfg" string
    mov r0, 11
    mov r1, startup_file_struct
    mov r2, startup_file
    call ryfs_read

    ; open the actual startup file
    mov r0, startup_file
    mov r1, 0
    mov r2, startup_file_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp startup_error

    ; read the startup file into memory starting at the bottom of the kernel
    mov r0, startup_file_struct
    mov r1, kernel_bottom
    call ryfs_read_whole_file

    ; relocate and execute it!!!
    mov r0, kernel_bottom
    call execute_fxf_binary

    rjmp 0

startup_error:
    mov r0, startup_error_str
    mov r1, 16
    mov r2, 16
    mov r3, TEXT_COLOR
    mov r4, 0x00000000
    call draw_str_to_background
    rjmp 0

    #include "allocator.asm"
    #include "fxf/fxf.asm"

startup_str: data.str "fox32 - OS version %u.%u.%u" data.8 0

startup_file: data.str "startup cfg"
startup_error_str: data.str "startup.cfg is invalid" data.8 0
startup_file_struct: data.32 0 data.32 0

    #include "../../fox32rom/fox32rom.def"

kernel_bottom:
