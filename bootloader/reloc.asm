; FXF relocation routines

const FXF_CODE_SIZE:   0x00000004
const FXF_CODE_PTR:    0x00000008
const FXF_RELOC_SIZE:  0x0000000C
const FXF_RELOC_PTR:   0x00000010

; relocate a FXF binary
; inputs:
; r0: pointer to memory buffer containing a FXF binary
; outputs:
; r0: relocation address
fxf_reloc:
    ; calculate relocation address
    mov r5, r0
    add r5, FXF_CODE_PTR
    mov r5, [r5]
    add r5, r0

    ; get the number of entries in the reloc table
    mov r1, r0
    add r1, FXF_RELOC_SIZE
    mov r1, [r1]
    div r1, 4
    mov r31, r1

    ; get the pointer to the table
    mov r1, r0
    add r1, FXF_RELOC_PTR
    mov r1, [r1]
    add r1, r0

    ; get the pointer to the code
    mov r2, r0
    add r2, FXF_CODE_PTR
    mov r2, [r2]
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
    add r1, 4
    loop fxf_reloc_loop

    ; return relocation address
    mov r0, r5

    ret
