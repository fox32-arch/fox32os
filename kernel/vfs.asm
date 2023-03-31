; virtual filesystem routines

; file struct for file:
;   file_disk:         1 byte
;   file_first_sector: 2 bytes
;   file_seek_offset:  4 bytes
;   file_system_type:  1 byte (0x00 for RYFS)

; file struct for stream:
;   file_reserved_1:  1 byte
;   file_reserved_2:  2 bytes
;   file_seek_offset: 4 bytes
;   file_system_type: 1 byte (0x01 for stream)
;   file_read_call:   4 bytes
;   file_write_call:  4 bytes

; open a file from a RYFS-formatted disk
; inputs:
; r0: pointer to file name string (8.3 format, for example "testfile.txt" or "test.txt")
; r1: disk ID
; r2: file struct: pointer to a blank file struct
; outputs:
; r0: first file sector, or zero if file wasn't found
open:
    call convert_filename
    cmp r0, 0
    ifz ret
    jmp ryfs_open

; seek specified file to the specified offset
; inputs:
; r0: byte offset
; r1: pointer to file struct
; outputs:
; none
seek:
    jmp ryfs_seek

; get the seek offset of the specified file
; inputs:
; r0: pointer to file struct
; outputs:
; r0: byte offset
tell:
    jmp ryfs_tell

; read specified number of bytes into the specified buffer
; inputs:
; r0: number of bytes to read
; r1: pointer to file struct
; r2: pointer to destination buffer
; outputs:
; r0: number of bytes left to read (streams can read short)
read:
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp ryfs_read
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_read
    pop r3
    ret
stream_read:
    push r1
    push r2

stream_read_loop:
    call stream_read_char
    call yield_task

    cmp.8 [r2], 0
    ifz jmp stream_read_out

    inc r2
    dec r0
    ifnz jmp stream_read_loop

stream_read_out:
    pop r2
    pop r1
    ret

stream_read_char:
    push r0
    push r1
    push r2

    ; call [file_read_call] with seek offset in r0
    add r1, 2
    mov r0, [r1]
    add r1, 6
    call [r1]

    ; put the result into [r2]
    pop r2
    mov.8 [r2], r0

    pop r1
    pop r0
    ret

; write specified number of bytes into the specified file
; inputs:
; r0: number of bytes to write
; r1: pointer to file struct
; r2: pointer to source buffer
; outputs:
; none
write:
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp ryfs_write
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_write
    pop r3
    ret
stream_write:
    push r31
    push r2

    mov r31, r0 ; number of bytes to write = loop count
stream_write_loop:
    call stream_write_char
    inc r2
    loop stream_write_loop

    pop r2
    pop r31
    ret

stream_write_char:
    push r0
    push r1
    push r3

    ; call [file_write_call] with pointer to src buf in r0 and seek offset in r1
    mov r3, r1
    add r3, 2
    mov r0, r2
    mov r1, [r3]
    add r3, 10
    call [r3]

    pop r3
    pop r1
    pop r0
    ret

; convert a user-friendly filename (test.txt) to the internal representation (test    txt)
; inputs:
; r0: pointer to null-terminated input string
; outputs:
; r0: pointer to null-terminated output string, or zero if failure
convert_filename:
    push r1
    push r2
    push r3
    push r31

    ; check the length of the filename to ensure it isn't too long
    mov r1, r0
    call string_length
    cmp r0, 12
    ifgt jmp convert_filename_fail
    cmp r0, 0
    ifz jmp convert_filename_fail

    ; fill the output string buffer with spaces and a null-terminator
    mov r2, convert_filename_output_string
    mov r31, 11
convert_filename_space_loop:
    mov.8 [r2], ' '
    inc r2
    loop convert_filename_space_loop
    mov.8 [r2], 0

    mov r2, convert_filename_output_string
    mov r3, 0

    ; r0: input filename length
    ; r1: pointer to input filename
    ; r2: pointer to output filename
    ; r3: number of characters processed
convert_filename_copy_loop:
    cmp.8 [r1], '.'
    ifz jmp convert_filename_found_ext
    mov.8 [r2], [r1]
    inc r1
    inc r2
    inc r3
    cmp r3, r0
    ifz jmp convert_filename_done
    iflt jmp convert_filename_copy_loop
convert_filename_found_ext:
    cmp r3, 0
    ifz jmp convert_filename_fail
    cmp r3, 8
    ifgt jmp convert_filename_fail

    mov r2, convert_filename_output_string
    add r2, 8
    inc r1
    cmp.8 [r1], 0
    ifz jmp convert_filename_fail
    mov.8 [r2], [r1]
    inc r1
    inc r2
    cmp.8 [r1], 0
    ifz jmp convert_filename_done
    mov.8 [r2], [r1]
    inc r1
    inc r2
    cmp.8 [r1], 0
    ifz jmp convert_filename_done
    mov.8 [r2], [r1]
convert_filename_done:
    mov r0, convert_filename_output_string
    pop r31
    pop r3
    pop r2
    pop r1
    ret
convert_filename_fail:
    mov r0, 0
    pop r31
    pop r3
    pop r2
    pop r1
    ret
convert_filename_output_string: data.fill 0, 12
