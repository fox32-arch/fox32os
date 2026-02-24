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
    push r2
    push r3
    push r4
    push r29
    push r30
    push r31
    ; INTERNAL REGISTER MAPPINGS
    ; r2 = Width
    ; r3 = Height
    ; r4 = Scratch Register
    ; r29 = Bytes per Pixel
    ; r30 = Line Size
    ; r31 = Counter

    ; Check the BMP's magic number
    movz.16 r4, [r0]
    cmp r4, 0x4D42
    ifnz movz.8 r0, 0
    ifnz movz.8 r1, BMP_BAD_MAGIC
    ifnz rjmp bmp_decode.tail
    ; Ensure that we support the BPP
    movz.16 r29, [r0+28]
    srl r29, 3
    cmp r29, 3
    iflt movz.8 r0, 0
    iflt movz.8 r1, BMP_BPP_UNSUPPORTED
    iflt rjmp bmp_decode.tail
    ; Ensure that the BMP has no compression
    mov.32 r4, [r0+30]
    cmp r4, 3
    ifz rjmp bmp_decode.skip_compression_check
    cmp r4, 0
    ifnz movz.8 r0, 0
    ifnz movz.8 r1, BMP_COMPRESSION_UNSUPPORTED
    ifnz rjmp bmp_decode.tail
bmp_decode.skip_compression_check:
    ; Retrieve the width and height
    mov.32 r2, [r0+18]
    mov.32 r3, [r0+22]
    cmp r3, 0x80000000
    ifgteq movz.8 r0, 0
    ifgteq movz.8 r1, BMP_NEGATIVE_SIZE_UNSUPPORTED
    ifgteq rjmp bmp_decode.tail

    ; Calculate the size of a line
    mov r30, r2
    mov r4, r29
    mul r30, r4
    mov r4, r30
    srl r30, 2
    sla r30, 2
    and r4, 0x3
    cmp r4, 0
    ifnz add r30, 4
    ; Increment r0 to the first pixel
    mov.32 r4, [r0+10]
    add r0, r4
    ; Set the Counter
    mov r31, r3
    ; Allocate a buffer if one wasn't provided
    cmp r1, 0
    ifnz rjmp bmp_decode.skip_alloc
    push r0
    mov r0, r2
    mul r0, r3
    sla r0, 2
    call allocate_memory
    mov r1, r0
    pop r0
    cmp r1, 0
    ifz movz.8 r0, 0
    ifz movz r1, BMP_ALLOC_FAILURE
    ifz rjmp bmp_decode.tail
bmp_decode.skip_alloc:
    push r1
bmp_decode.line_loop:
    push r0
    ; Calculate the line position
    mov r4, r31
    dec r4
    mul r4, r30
    add r0, r4
    push r31
    mov r31, r2
bmp_decode.pixel_loop:
    ; If this is a 32-bit image, add the alpha channel, otherwise set it to 255
    cmp r29, 4
    ifnz movz.8 r4, 0xff
    ifz movz.8 r4, [r0+3]
    sla r4, 8
    ; Retrieve the other channels for the pixel
    mov.8 r4, [r0]
    sla r4, 8
    mov.8 r4, [r0+1]
    sla r4, 8
    mov.8 r4, [r0+2]
    ; Blit the pixel to the output buffer
    mov.32 [r1], r4
    add r1, 4
    add r0, r29
    rloop bmp_decode.pixel_loop
    ; Line loop tail
    pop r31
    pop r0
    rloop bmp_decode.line_loop
    pop r1
    movz.32 r0, r3
    sla r0, 16
    mov.16 r0, r2
bmp_decode.tail:
    pop r31
    pop r30
    pop r29
    pop r4
    pop r3
    pop r2
    ret

bmp_encode:
    ; TODO: Implement encoder for BMP
    ret

    #include "../../fox32os.def"
    #include "../../../fox32rom/fox32rom.def"