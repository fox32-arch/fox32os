; first stage fox32os bootloader

    opton
    org 0x00000800

const BOOT_MAGIC: 0x523C334C

    ; pointers in registers to save space
    movz.16 r20, boot_disk_id
    movz.16 r21, memory_total
    movz.16 r22, memory_usable
    movz.16 r23, load_address
    movz.16 r24, system_dir
    movz.16 r30, print
    mov r31, [0xF0045008] ; ryfs_open

    ; fox32rom passed along some boot info, save it
    mov.8 [r20], r0 ; boot disk id
    mov [r21], r1   ; total memory
    mov [r22], r2   ; usable memory

    ; old builds of fox32rom don't provide this info, so assume 64 MiB
    or r1, r1
    ifz mov [r21], 0x04000000
    ifz mov [r22], 0x01FFF800

    ; print memory size
    mov r0, [r21]
    rcall.16 print_mem
    out 0, '/'
    mov r0, [r22]
    rcall.16 print_mem
    out 0, 10

    ; hello world!
    movz.16 r0, splash_str
    call r30

    ; open /system
    movz.16 r0, system_dir_name
    movz.8 r1, [r20]
    movz.16 r2, load_file_struct
    movz.8 r3, 1 ; root dir
    push r1
    push r2
    call r31 ; ryfs_open
    or r0, r0
    ifz rjmp.16 error
    mov [r24], r0

    ; open /system/boot2.bin
    movz.16 r0, load_file_name
    pop r2
    pop r1
    mov r3, [r24]
    call r31 ; ryfs_open
    or r0, r0
    ifz rjmp.16 error

    ; calculate where to load it
    movz.8 r0, 4
    movz.16 r1, load_file_struct
    mov r2, load_address
    call [0xF0045010] ; ryfs_read

    ; go back to the beginning
    movz.8 r0, 0
    movz.16 r1, load_file_struct
    call [0xF004500C] ; ryfs_seek

    ; load it into memory
    movz.16 r0, load_file_struct
    mov r1, [load_address]
    call [0xF0045014] ; ryfs_read_whole_file

    ; off we go!!
    movz.8 r0, [r20]
    mov r1, [r21]
    mov r2, [r22]
    icl
    mov rsp, BOOT_MAGIC ; stage 2 (and the kernel) expects rsp to equal the magic bytes
    mov r3, [r23]
    inc r3, 4 ; skip past address word
    jmp r3

system_dir_name: data.strz "system  dir"
load_file_name: data.strz "boot2   bin"

splash_str: data.strz "boot1 load "

print_decimal:
    mov r10, rsp
    mov r12, r0

    push.8 0
print_decimal_loop:
    push r12
    div r12, 10
    pop r13
    rem r13, 10
    mov r11, r13
    add.8 r11, '0'
    push.8 r11
    or r12, r12
    ifnz rjmp.8 print_decimal_loop
    mov r0, rsp
    call r30

    mov rsp, r10
    ret

print:
    out 0, [r0]
    inc r0
    cmp.8 [r0], 0x00
    ifnz rjmp.8 print
    ret

print_mem:
    srl r0, 10
    rcall.16 print_decimal
    out 0, 'K'
    ret

error_str: data.str "error" data.8 10 data.8 0
error:
    movz.16 r0, error_str
    push r0
    call r30
    pop r0
    jmp [0xF0040018] ; panic

    ; bootable magic bytes
    org.pad 0x000009FC
    data.32 BOOT_MAGIC

    org 0x00001000
load_file_struct:
    org 0x00001020
boot_disk_id:
    org 0x00001021
memory_total:
    org 0x00001025
memory_usable:
    org 0x00001029
system_dir:
    org 0x0000102D
load_address:
