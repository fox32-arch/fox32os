; FXF relocation routines

; relocate a FXF binary
; inputs:
; r0: pointer to memory buffer containing a FXF binary
; outputs:
; r0: relocation address
fxf_reloc:
    push r1
    push r2
    push r3
    push r4
    push r5

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
    cmp r31, 0
    ifz mov r0, r5
    ifz pop r5
    ifz pop r4
    ifz pop r3
    ifz pop r2
    ifz pop r1
    ifz ret

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

    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    ret
