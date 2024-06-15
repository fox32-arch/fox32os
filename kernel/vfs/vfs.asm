; virtual filesystem routines

const TEMP_SECTOR_BUF: 0x01FFF808

; file struct for file:
;   file_disk:         1 byte
;   file_first_sector: 2 bytes
;   file_seek_offset:  4 bytes
;   file_system_type:  1 byte (0x00 for RYFS)
;   file_reserved_1:   4 bytes
;   file_reserved_2:   4 bytes
;   file_reserved_3:   4 bytes
;   file_reserved_4:   4 bytes
;   file_reserved_5:   4 bytes
;   file_reserved_6:   4 bytes

; file struct for stream:
;   file_reserved_1:  1 byte
;   file_reserved_2:  2 bytes
;   file_seek_offset: 4 bytes
;   file_system_type: 1 byte (0x01 for stream)
;   file_read_call:   4 bytes
;   file_write_call:  4 bytes
;   file_size:        4 bytes
;   file_reserved_3:  4 bytes
;   file_reserved_4:  4 bytes
;   file_reserved_5:  4 bytes

; open a file from a RYFS-formatted disk, or a named stream
; inputs:
; r0: pointer to file name string (8.3 format if file, for example "testfile.txt" or "test.txt")
; r1: disk ID (ignored if stream)
; r2: file struct: pointer to a blank file struct (8 bytes if file, 20 bytes if stream)
; outputs:
; r0: if file: first file sector, or zero if file wasn't found
;     if stream: non-zero if stream opened, or zero if not
open:
    cmp.8 [r0], ':'
    ifz jmp open_stream
    call convert_filename
    cmp r0, 0
    ifz ret
    jmp ryfs_open
open_stream:
    push r1

    inc r0

    ; disk0
    mov r1, disk0_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk0

    ; disk1
    mov r1, disk1_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk1

    ; disk2
    mov r1, disk2_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk2

    ; disk3
    mov r1, disk3_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk3

    ; fb
    mov r1, framebuffer_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_fb

    ; ofb0 - ofb31
    push r2
    mov r1, overlay_vfs_stream_name
    mov r2, 3
    call compare_memory_bytes
    pop r2
    ifz pop r1
    ifz jmp open_stream_ofb

    ; ramdisk
    mov r1, ramdisk_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_ramdisk

    ; romdisk
    mov r1, romdisk_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_romdisk

    ; serial
    mov r1, serial_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_serial

    pop r1
    mov r0, 0
    ret

; create a file on a RYFS-formatted disk, or open a named stream
; if target file already exists, it will be deleted and then re-created as a blank file
; inputs:
; r0: pointer to file name string (8.3 format if file, for example "testfile.txt" or "test.txt")
; r1: disk ID (ignored if stream)
; r2: file struct: pointer to a blank file struct (8 bytes if file, 20 bytes if stream)
; r3: target file size
; outputs:
; r0: if file: first file sector, or zero if file couldn't be created
;     if stream: non-zero if stream opened, or zero if not
create:
    cmp.8 [r0], ':'
    ifz jmp open_stream
    call convert_filename
    cmp r0, 0
    ifz ret
    jmp ryfs_create

; delete a file on a RYFS-formatted disk
; inputs:
; r0: file struct: pointer to a filled file struct
; outputs:
; none
delete:
    cmp r0, 0
    ifz ret
    jmp ryfs_delete

; copy a file's contents
; inputs:
; r0: source file struct: pointer to a filled file struct
; r1: destination file struct: pointer to a filled file struct
; outputs:
; none
copy:
    mov [copy_source_struct_ptr], r0
    mov [copy_dest_struct_ptr], r1
    call get_size
    mov [copy_buffer_size], r0
    call allocate_memory
    mov [copy_buffer_ptr], r0

    mov r0, [copy_buffer_size]
    mov r1, [copy_source_struct_ptr]
    mov r2, [copy_buffer_ptr]
    call read
    mov r0, [copy_buffer_size]
    mov r1, [copy_dest_struct_ptr]
    mov r2, [copy_buffer_ptr]
    call write

    mov r0, [copy_buffer_ptr]
    call free_memory

    ret
copy_source_struct_ptr: data.32 0
copy_dest_struct_ptr: data.32 0
copy_buffer_ptr: data.32 0
copy_buffer_size: data.32 0

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

; get the exact size of the specified file
; inputs:
; r0: pointer to file struct
; outputs:
; r0: size in bytes
get_size:
    push r1
    push r0
    add r0, 7
    movz.8 r1, [r0]
    pop r0
    cmp.8 r1, 0x00
    ifz pop r1
    ifz jmp ryfs_get_size
    cmp.8 r1, 0x01
    ifz pop r1
    ifz jmp stream_get_size
    pop r1
    ret
stream_get_size:
    add r0, 16
    mov r0, [r0]

    ret

; read specified number of bytes into the specified buffer
; inputs:
; r0: number of bytes to read
; r1: pointer to file struct
; r2: pointer to destination buffer
; outputs:
; none
read:
    cmp r0, 0
    ifz ret
    cmp r1, 0
    ifz ret
    cmp r2, 0
    ifz ret
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
    push r0
    push r1
    push r2
stream_read_loop:
    call stream_read_char

    call save_state_and_yield_task

    inc r2
    dec r0
    ifnz jmp stream_read_loop

    pop r2
    pop r1
    pop r0
    ret
stream_read_char:
    push r0
    push r1
    push r2

    ; call [file_read_call] with seek offset in r0
    add r1, 3
    mov r0, [r1]
    add r1, 5
    call [r1]

    ; put the result into [r2]
    pop r2
    mov.8 [r2], r0

    ; increment the seek offset
    sub r1, 5
    inc [r1]

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
    cmp r0, 0
    ifz ret
    cmp r1, 0
    ifz ret
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp call_ryfs_write
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_write
    pop r3
    ret
call_ryfs_write:
    ; `ryfs_write`, despite being written in okameron, clobbers r2 for some reason?
    push r2
    call ryfs_write
    pop r2
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
    add r3, 3
    mov r0, r2
    mov r1, [r3]
    add r3, 9
    call [r3]

    ; increment the seek offset
    sub r3, 9
    inc [r3]

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

    ; named streams
    #include "vfs/disk0.asm"
    #include "vfs/disk1.asm"
    #include "vfs/disk2.asm"
    #include "vfs/disk3.asm"
    #include "vfs/fb.asm"
    #include "vfs/ofb.asm"
    #include "vfs/ramdisk.asm"
    #include "vfs/romdisk.asm"
    #include "vfs/serial.asm"
