; second stage fox32os bootloader

    opton
    org 0x00000A00

    ; first word is the address for the first stage to load us to
    data.32 0x00000A00

; inputs:
; r0: boot disk ID
; r1: total memory
; r2: usable memory
entry:
    ; initialize environment, re-enable interrupts
    mov [boot_magic], rsp ; stage 1 gave us the magic bytes in rsp
    mov r20, boot2_end
    add r20, 768 ; give us 768 bytes of stack space
    mov rsp, r20
    ise

    ; pointers in registers to save space
    movz.16 r20, boot_disk_id
    movz.16 r21, memory_total
    movz.16 r22, memory_usable
    movz.16 r23, load_address
    movz.16 r24, system_dir
    movz.16 r30, print
    mov r31, [0xF0045008] ; ryfs_open

    ; stage 1 passed along some boot info, save it
    mov.8 [r20], r0 ; boot disk id
    mov [r21], r1   ; total memory
    mov [r22], r2   ; usable memory

    ; hello world!!
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
    movz.16 r0, load_file_struct
    call [0xF0045018] ; ryfs_get_size
    mov r1, [r22]
    sub r1, r0
    sub r1, 1024 ; 1024 bytes of padding after kernel for initial kernel stack
    and.8 r1, 0xF0 ; make the address a nice even number
    mov [r23], r1

    ; load it into memory
    movz.16 r0, load_file_struct
    call [0xF0045014] ; ryfs_read_whole_file

    ; relocate it and off we go!!
    movz.16 r0, reloc_str
    call r30
    mov r0, [r23]
    rcall.16 fxf_reloc
    mov r3, [r23]
    mov [r23], r0 ; save entry address
    movz.16 r0, booting_str
    call r30
    movz.8 r0, [r20]
    mov r1, [r21]
    mov r2, [r22]
    icl
    mov rsp, [boot_magic] ; the kernel expects rsp to equal the magic bytes
    jmp [r23]

error_str: data.str "error" data.8 10 data.8 0
error:
    movz.16 r0, error_str
    push r0
    call r30
    pop r0
    jmp [0xF0040018] ; panic

print:
    out 0, [r0]
    inc r0
    cmp.8 [r0], 0x00
    ifnz rjmp.8 print
    ret

; relocate a FXF binary
; inputs:
; r0: pointer to memory buffer containing a FXF binary
; outputs:
; r0: relocation address
fxf_reloc:
    ; calculate relocation address
    mov r5, [r0+8] ; FXF_CODE_PTR
    add r5, r0

    ; get the number of entries in the reloc table
    mov r1, [r0+12] ; FXF_RELOC_SIZE
    srl r1, 2
    mov r31, r1

    ; get the pointer to the table
    mov r1, [r0+16] ; FXF_RELOC_PTR
    add r1, r0

    ; get the pointer to the code
    mov r2, [r0+8] ; FXF_CODE_PTR
    add r2, r0

    ; loop over the reloc table entries and relocate the code
fxf_reloc_loop:
    ; get the reloc table entry
    mov r3, [r1]

    ; point to the location in the code
    mov r4, r2
    add r4, r3

    ; relocate
    add [r4], r5

    ; increment the reloc table pointer
    inc r1, 4
    loop fxf_reloc_loop

    ; return relocation address
    mov r0, r5

    ret

system_dir_name: data.strz "system  dir"
load_file_name: data.strz "kernel  fxf"

splash_str: data.strz "boot2 load "
reloc_str: data.strz "reloc "
booting_str: data.str "jump" data.8 10 data.8 0

load_file_struct: data.fill 0, 32
boot_disk_id:     data.fill 0, 1
memory_total:     data.fill 0, 4
memory_usable:    data.fill 0, 4
system_dir:       data.fill 0, 4
load_address:     data.fill 0, 4
boot_magic:       data.fill 0, 4

boot2_end:
