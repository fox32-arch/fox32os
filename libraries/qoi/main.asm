; Quite Okay Image Format Version 1.0 compliant Encoder/Decoder implementation
; At the moment, we only have a decoder, however space is reserved on the jump table for encoding
    opton

jump_table:
    data.32 qoi_decode
    data.32 qoi_encode
    data.32 0x00000000 ; end jump table

;;;;;;;; Decodes a QOI Image and emits the output to the specified destination
; r0: Raw QOI File Data
; r1: Output Buffer (0x0 = Allocate Buffer, other value will write to the specified address)
;;; Output
; r0: Width & Height
; r1: Output Buffer (if input was 0x0)
qoi_decode:
    push r31
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7
    push r8
    ; INTERNAL REGISTER MAPPINGS
    ; r0 = Input pointer
    ; r1 = Output pointer
    ; r2 = Width
    ; r3 = Height
    ; r4 = Previous Pixel (RGBA)
    ; r5 = Tag Byte or Scratch Register 1
    ; r6 = Scratch Register 2
    ; r7 = Scratch Register 3
    ; r8 = Scratch Register 4
    ; r31 = Counter (for loop instructions)

    ; Do a quick check to make sure the magic number is valid
    mov r5, [r0]
    cmp r5, 0x66696f71 ; "qoif"
    ifnz movz.8 r0, 0
    ifnz jmp qoi_decode.tail

    ; Clear the LUT before we start decoding the image
    mov r5, color_lut
    mov r31, 64
qoi_decode.lut_clear_loop:
    mov.32 [r5], 0
    add r5, 4
    rloop qoi_decode.lut_clear_loop

    ; Get the Width (is in Big Endian)
    movz.8 r2, [r0+4]
    sla r2, 8
    mov.8 r2, [r0+5]
    sla r2, 8
    mov.8 r2, [r0+6]
    sla r2, 8
    mov.8 r2, [r0+7]
    ; Get the Height (is in Big Endian)
    movz.8 r3, [r0+8]
    sla r3, 8
    mov.8 r3, [r0+9]
    sla r3, 8
    mov.8 r3, [r0+10]
    sla r3, 8
    mov.8 r3, [r0+11]
    ; Set the Counter
    mov r31, r2
    mul r31, r3
    ; Allocate a buffer if one wasn't provided
    cmp r1, 0
    ifnz jmp qoi_decode.skip_alloc
    push r0
    mov r0, r31
    call allocate_memory
    mov r1, r0
    pop r0
    cmp r1, 0
    ifz mov r0, 0
    ifz jmp qoi_decode.tail
qoi_decode.skip_alloc:
    push r1
    ; Set the Input Pointer
    add r0, 14
    ; Set the previous pixel
    mov r4, 0xff000000
qoi_decode.main_loop:
    ; Read the tag, then branch to the right label based on that value
    movz.8 r5, [r0]
    inc r0
    cmp r5, 0xfe
    ifz rjmp qoi_decode.op_rgb
    cmp r5, 0xff
    ifz rjmp qoi_decode.op_rgba
    mov r6, r5
    and r6, 0xC0
    cmp r6, 0
    ifz rjmp qoi_decode.op_index
    cmp r6, 0x40
    ifz rjmp qoi_decode.op_diff
    cmp r6, 0x80
    ifz rjmp qoi_decode.op_luma
    rjmp qoi_decode.op_run
qoi_decode.op_rgb:
    ; Sets the color to a specified RGB color, preserving the alpha value of the previous color
    mov r6, r4
    and r6, 0xff000000
    movz.8 r4, [r0+2]
    sla r4, 8
    mov.8 r4, [r0+1]
    sla r4, 8
    mov.8 r4, [r0+0]
    or r4, r6
    ; Blit pixel to buffer
    mov.32 [r1], r4
    add r1, 4
    ; OP_RGB tail
    add r0, 3
    rjmp qoi_decode.main_loop_tail
qoi_decode.op_rgba:
    ; Sets the color to a specified RGBA color, that's it
    movz.8 r4, [r0+3]
    sla r4, 8
    mov.8 r4, [r0+2]
    sla r4, 8
    mov.8 r4, [r0+1]
    sla r4, 8
    mov.8 r4, [r0]
    ; Blit pixel to buffer
    mov.32 [r1], r4
    add r1, 4
    ; OP_RGBA tail
    add r0, 4
    rjmp qoi_decode.main_loop_tail
qoi_decode.op_index:
    ; Retrieve a previously used color from the Color LUT
    and.8 r5, 0x3f
    sla r5, 2
    add r5, color_lut
    mov.32 r4, [r5]
    ; Blit pixel to buffer
    mov.32 [r1], r4
    add r1, 4
    rjmp qoi_decode.main_loop_tail
qoi_decode.op_diff:
    ; This tag is pretty large, but all it does is change the channel values by a very small increment
    and.8 r5, 0x3f
    mov r6, r5
    mov r7, r5
    ; Blue channel
    and.8 r7, 0x03
    sub r7, 2 ; -2 + r7
    mov r8, r4
    srl r8, 16
    and.32 r8, 0xff
    add r8, r7
    and.32 r8, 0xff
    mov r7, r8
    sla r7, 16
    ; Green channel
    srl r6, 2
    and.8 r6, 0x03
    sub r6, 2  ; -2 + r6
    mov r8, r4
    srl r8, 8
    and.32 r8, 0xff
    add r8, r6
    and.32 r8, 0xff
    mov r6, r8
    sla r6, 8
    ; Red channel
    srl r5, 4
    and.8 r5, 0x03
    sub r5, 2  ; -2 + r5
    movz.8 r8, r4
    add r8, r5
    and.32 r8, 0xff
    mov r5, r8
    ; Calculate final color
    or r5, r6
    or r5, r7
    and r4, 0xff000000
    or r4, r5
    ; Blit pixel to buffer
    mov.32 [r1], r4
    add r1, 4
    rjmp qoi_decode.main_loop_tail
qoi_decode.op_luma:
    ; First get the difference for the green channel
    and.8 r5, 0x3f
    sub r5, 32
    ; Calculate the number we'll add to the red and blue channels
    ; This is done by taking the nibble associated with the channel from the next byte,
    ; applying the channel's bias, and then adding r5 to its total.
    ; r6 = Blue
    ; r7 = Red
    movz.8 r6, [r0]
    inc r0 
    movz.8 r7, r6
    srl r7, 4
    and r7, 0xf
    and r6, 0xf
    sub r7, 8
    sub r6, 8
    add r7, r5
    add r6, r5
    ; Add the channels from the previous color to our current differences
    ; Blue Channel
    mov r8, r4
    srl r8, 16
    and r8, 0xff
    add r6, r8
    and r6, 0xff
    sla r6, 16
    ; Red Channel
    movz.8 r8, r4
    add r7, r8
    and r7, 0xff
    ; Green Channel
    movz.16 r8, r4
    srl r8, 8
    add r5, r8
    and r5, 0xff
    sla r5, 8
    ; Calculate the final color
    or r5, r6
    or r5, r7
    and r4, 0xff000000
    or r4, r5
    ; Blit pixel to buffer
    mov.32 [r1], r4
    add r1, 4
    rjmp qoi_decode.main_loop_tail
qoi_decode.op_run:
    and r5, 0x3f
    sub r31, r5
    inc r5
    push r31
    mov r31, r5
qoi_decode.op_run_loop:
    mov.32 [r1], r4
    add r1, 4
    rloop qoi_decode.op_run_loop
    pop r31
qoi_decode.main_loop_tail:
    ; Calculate the index of our color and add it to the Color LUT
    call qoi_compute_index
    sla r5, 2
    add r5, color_lut
    mov.32 [r5], r4
    rloop qoi_decode.main_loop
    pop r1
    movz.32 r0, r3
    sla r0, 16
    mov.16 r0, r2
qoi_decode.tail:
    pop r8
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r31
    ret

qoi_encode:
    ; TODO: Implement encoder for QOI
    ret

;;;;;;;; Internal function used to compute the index for the Color LUT
; r4 = Pixel
;;; Output
; r5 = Index
qoi_compute_index:
    push r1 ; Red
    push r2 ; Green
    push r3 ; Blue
    push r4 ; Alpha
    ; Extract Channels
    mov r1, r4
    and r1, 0xff
    mov r2, r4
    srl r2, 8
    and r2, 0xff
    mov r3, r4
    srl r3, 16
    and r3, 0xff
    srl r4, 24
    and r4, 0xff
    ; Calculate the index
    mul r1, 3
    mul r2, 5
    mul r3, 7
    mul r4, 11
    mov r5, r1
    add r5, r2
    add r5, r3
    add r5, r4
    rem r5, 64
    pop r4
    pop r3
    pop r2
    pop r1
    ret

color_lut: data.fill 0, 256 ; 64 color LUT

    #include "../../fox32os.def"
    #include "../../../fox32rom/fox32rom.def"