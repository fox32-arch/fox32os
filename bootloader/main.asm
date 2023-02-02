; fox32os bootloader

    org 0x00000800

const LOAD_ADDRESS: 0x03000000

    ; open kernel.fxf
    mov r0, kernel_file_name
    movz.8 r1, 0
    mov r2, kernel_file_struct
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
    jmp r0

error:
    mov r0, error_str
    movz.8 r1, 16
    movz.8 r2, 16
    mov r3, 0xFFFFFFFF
    movz.8 r4, 0
    call [0xF0042004] ; draw_str_to_background
    rjmp 0

kernel_file_name: data.strz "kernel  fxf"
kernel_file_struct: data.32 0 data.32 0
error_str: data.strz "failed to open kernel.fxf"

    #include "reloc.asm"
