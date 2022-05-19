; FXF routines

; parse and relocate an FXF binary loaded in memory
; inputs:
; r0: pointer to memory buffer containing an FXF binary
; outputs:
; none
execute_fxf_binary:
    ; TODO: check the magic bytes and header version

    call fxf_reloc

    jmp r0

    #include "fxf/reloc.asm"

const FXF_CODE_SIZE:   0x00000004
const FXF_CODE_PTR:    0x00000008
const FXF_EXTERN_SIZE: 0x0000000C
const FXF_EXTERN_PTR:  0x00000010
const FXF_GLOABL_SIZE: 0x00000014
const FXF_GLOBAL_PTR:  0x00000018
const FXF_RELOC_SIZE:  0x0000001C
const FXF_RELOC_PTR:   0x00000020
