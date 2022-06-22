; FXF routines

; parse and relocate an FXF binary loaded in memory
; inputs:
; r0: pointer to memory buffer containing an FXF binary
; outputs:
; r0: relocation address
parse_fxf_binary:
    ; TODO: check the magic bytes and header version

    call fxf_reloc

    ret

    #include "fxf/reloc.asm"

const FXF_CODE_SIZE:   0x00000004
const FXF_CODE_PTR:    0x00000008
const FXF_RELOC_SIZE:  0x0000000C
const FXF_RELOC_PTR:   0x00000010
