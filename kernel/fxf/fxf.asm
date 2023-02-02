; FXF routines

; parse and relocate an FXF binary loaded in memory
; inputs:
; r0: pointer to memory buffer containing an FXF binary
; outputs:
; r0: relocation address or 0 on error
parse_fxf_binary:
    push r1
    mov r1, [r0]
    cmp r1, [fxf_magic]
    ifnz pop r1
    ifnz mov r0, 0
    ifnz ret
    pop r1

    call fxf_reloc

    ret

fxf_magic: data.strz "FXF"

    #include "fxf/reloc.asm"

const FXF_CODE_SIZE:   0x00000004
const FXF_CODE_PTR:    0x00000008
const FXF_RELOC_SIZE:  0x0000000C
const FXF_RELOC_PTR:   0x00000010
