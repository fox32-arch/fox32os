; fox32os bootloader

    org 0x00000800

const LOAD_ADDRESS: 0x03000000

    ; fox32rom passed the boot disk id in r0, save it
    mov.8 [boot_disk_id], r0

    ; open kernel.fxf
    mov r1, r0
    mov r0, kernel_file_name
    mov r2, kernel_file_struct
    mov r3, 0 ; FIXME: THIS IS HARDCODED TO THE ROOT DIRECTORY!!!!!
    call [0xF0045008] ; ryfs_open
    cmp r0, 0
    ifz jmp error

    ; load it into memory
    mov r0, kernel_file_struct
    mov r1, LOAD_ADDRESS
    call [0xF0045014] ; ryfs_read_whole_file

    ; relocate it and off we go!!
    mov r0, LOAD_ADDRESS
    call fxf_reloc
    mov r1, r0
    movz.8 r0, [boot_disk_id]
    jmp r1

error:
    mov r0, error_str
    movz.8 r1, 16
    movz.8 r2, 16
    mov r3, 0xFFFFFFFF
    movz.8 r4, 0
    call [0xF0042004] ; draw_str_to_background
    rjmp 0

kernel_file_name: data.strz "kernel  fxf"
kernel_file_struct: data.fill 0, 32
error_str: data.strz "failed to open kernel file"
boot_disk_id: data.8 0

    #include "reloc.asm"

    ; bootable magic bytes
    org.pad 0x000009FC
    data.32 0x523C334C
