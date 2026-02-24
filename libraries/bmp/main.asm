    opton

jump_table:
    data.32 bmp_decode
    data.32 bmp_encode
    data.32 0x00000000 ; end jump table

;;;;;;;; Constants
const BMP_BAD_MAGIC: 1
const BMP_ALLOC_FAILURE: 2
const BMP_BPP_UNSUPPORTED: 3
const BMP_NEGATIVE_SIZE_UNSUPPORTED: 4
const BMP_COMPRESSION_UNSUPPORTED: 5

;;;;;;;; Decodes a BMP Image and emits the output to the specified destination
; r0: Raw BMP File Data
; r1: Output Buffer (0x0 = Allocate Buffer, other value will write to the specified address)
;;; Output
; r0: Width & Height (0-15: Width, 16-31: Height)
; r1: in(r0) > 0:  Output Buffer
;     out(r0) = 0: Error Code
bmp_decode:
    push r31
    push r2
    push r3
    push r4
    push r5
    ; INTERNAL REGISTER MAPPINGS
    ; r2 = Width
    ; r3 = Height
    ; r4 = Scratch Register 1

    ; Check the BMP's magic number
    movz.16 r4, [r0]
    cmp r4, 0x4D42
    ifnz movz.8 r0, 0
    ifnz movz.8 r1, BMP_BAD_MAGIC
    ifnz rjmp bmp_decode.tail
    ; Ensure that we support the BPP
    movz.16 r4, [r0+28]
    cmp r4, 24
    iflt movz.8 r0, 0
    iflt movz.8 r1, BMP_BPP_UNSUPPORTED
    iflt rjmp bmp_decode.tail
    ; Ensure that the BMP has no compression
    mov.32 r4, [r0+30]
    cmp r4, 0
    ifnz movz.8 r0, 0
    ifnz movz.8 r1, BMP_COMPRESSION_UNSUPPORTED
    ifnz rjmp bmp_decode.tail
    ; Retrieve the width and height
    mov.32 r2, [r0+18]
    mov.32 r3, [r0+22]
    cmp r3, 0x80000000
    ifgteq movz.8 r0, 0
    ifgteq movz.8 r1, BMP_NEGATIVE_SIZE_UNSUPPORTED
    ifgteq rjmp bmp_decode.tail

    ; Allocate a buffer if one wasn't provided
    cmp r1, 0
    ifnz rjmp bmp_decode.skip_alloc
    push r0
    mov r0, r31
    call allocate_memory
    mov r1, r0
    pop r0
    cmp r1, 0
    ifz movz.8 r0, 0
    ifz movz r1, BMP_ALLOC_FAILURE
    ifz rjmp bmp_decode.tail
bmp_decode.skip_alloc:
    ; Set the Counter
    mov r31, r3
    ; 
    push r1
bmp_decode.line_loop:
    push r0
    push r31
    mov r31, r2
bmp_decode.pixel_loop:
    pop r31
    rloop bmp_decode.line_loop
    pop r1
    movz.32 r0, r3
    sla r0, 16
    mov.16 r0, r2
bmp_decode.tail:
    pop r5
    pop r4
    pop r3
    pop r2
    pop r31
    ret

bmp_encode:
    ; TODO: Implement encoder for BMP
    ret

    #include "../../fox32os.def"
    #include "../../../fox32rom/fox32rom.def"