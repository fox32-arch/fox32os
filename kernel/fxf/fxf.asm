; FXF routines

; parse and relocate an FXF binary loaded in memory
; inputs:
; r0: pointer to memory buffer containing an FXF binary
; outputs:
; r0: relocation address or 0 on error
parse_fxf_binary:
    push r1
    push r2
    mov r1, fxf_magic
    mov r2, 3
    call compare_memory_bytes
    pop r2
    pop r1
    ifnz mov r0, 0
    ifnz ret

    call fxf_reloc

    ret

fxf_magic: data.str "FXF"

    #include "fxf/launch.asm"
    #include "fxf/reloc.asm"

const FXF_CODE_SIZE:   0x00000004
const FXF_CODE_PTR:    0x00000008
const FXF_RELOC_SIZE:  0x0000000C
const FXF_RELOC_PTR:   0x00000010
const FXF_BSS_SIZE:    0x00000014
