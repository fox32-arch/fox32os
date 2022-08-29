; file helper routines

; get a list of FXF files on disk 0
; inputs:
; none
; outputs:
; r0: pointer to file name buffer
; r1: number of files
get_fxf_files:
    push r2
    push r31

    ; allocate a 341 byte array for the file name buffer
    mov r0, 341
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [all_file_list_ptr], r0

    ; read the list of files into the buffer
    mov r1, 0
    call ryfs_get_file_list
    mov [number_of_all_files], r0

    ; allocate a 341 byte buffer for the FXF file name buffer
    mov r0, 341
    call allocate_memory
    cmp r0, 0
    ifz jmp allocate_error
    mov [fxf_file_list_ptr], r0

    mov r0, [all_file_list_ptr]
    mov r1, [fxf_file_list_ptr]
    mov [number_of_fxf_files], 0
    mov r31, [number_of_all_files]
get_fxf_files_loop:
    push r0
    push r1
    add r0, 8
    mov r1, fxf_ext
    mov r2, 3
    call compare_memory_bytes
    ifnz jmp get_fxf_files_loop_not_fxf
    inc [number_of_fxf_files]
    pop r1
    pop r0
    mov r2, 11
    call copy_memory_bytes
    add r0, 11
    add r1, 11
    loop get_fxf_files_loop
    jmp get_fxf_files_end
get_fxf_files_loop_not_fxf:
    pop r1
    pop r0
    add r0, 11
    loop get_fxf_files_loop
get_fxf_files_end:
    ; free the "all files" buffer
    mov r0, [all_file_list_ptr]
    call free_memory

    ; return pointer to file name buffer and number of files
    mov r0, [fxf_file_list_ptr]
    mov r1, [number_of_fxf_files]

    pop r31
    pop r2
    ret

; all files
all_file_list_ptr:   data.32 0
number_of_all_files: data.32 0

; FXF files only
fxf_file_list_ptr:   data.32 0
number_of_fxf_files: data.32 0
fxf_ext:             data.str "fxf"
