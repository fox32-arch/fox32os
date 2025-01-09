; FXF routines

; parse and relocate an LBR binary loaded in memory
; inputs:
; r0: pointer to memory buffer containing an LBR binary
; outputs:
; r0: jump table address or 0 on error
; r1: jump table size or 0 on error
parse_lbr_binary:
    push r1
    push r2
    mov r1, lbr_magic
    mov r2, 3
    call compare_memory_bytes
    pop r2
    pop r1
    ifnz mov r0, 0
    ifnz ret

    push r0
    call fxf_reloc
    pop r1
    cmp r0, 0
    ifz mov r1, 0
    ifz ret
    add r1, LBR_JUMP_SIZE
    mov r1, [r1]

    ret

lbr_magic: data.str "LBR"

    #include "lbr/open.asm"

const LBR_CODE_SIZE:   0x00000004
const LBR_CODE_PTR:    0x00000008
const LBR_RELOC_SIZE:  0x0000000C
const LBR_RELOC_PTR:   0x00000010
const LBR_JUMP_SIZE:   0x00000014
const LBR_JUMP_PTR:    0x00000018
