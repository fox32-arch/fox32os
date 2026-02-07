; dir command

shell_dir_command_string: data.strz "dir"

shell_dir_command:
    mov r0, shell_dir_command_header_string
    call print_str_to_terminal

    call get_current_disk_id
    mov.8 [shell_dir_command_file_disk], r0
    call get_current_directory
    mov.16 [shell_dir_command_file_dir], r0
    call shell_parse_arguments
    cmp r0, 0
    ifnz call shell_dir_command_open_dir
    cmp.16 [shell_dir_command_file_dir], 0
    ifz ret

    mov r0, shell_dir_command_list_buffer
    movz.8 r1, [shell_dir_command_file_disk]
    movz.16 r2, [shell_dir_command_file_dir]
    call ryfs_get_file_list
    cmp r0, 0
    ifz ret

    mov r31, r0
    mov r3, 0
shell_dir_command_loop:
    ; copy one file name from the list buffer to the file buffer
    mov r0, shell_dir_command_list_buffer
    add r0, r3
    mov r1, shell_dir_command_file_buffer
    mov r2, 8
    call copy_memory_bytes
    add r1, 8
    mov.8 [r1], 0

    ; copy file type from the list buffer to the type buffer
    mov r0, shell_dir_command_list_buffer
    add r0, r3
    add r0, 8
    mov r1, shell_dir_command_type_buffer
    mov r2, 3
    call copy_memory_bytes
    add r1, 3
    mov.8 [r1], 0

    ; dirs are colored in blue
    cmp [shell_dir_command_type_buffer], [shell_dir_command_dir_type_str]
    ifz mov r0, shell_dir_command_color_blue
    ifz call print_str_to_terminal
    ; fxfs are colored in red
    cmp [shell_dir_command_type_buffer], [shell_dir_command_fxf_type_str]
    ifz mov r0, shell_dir_command_color_red
    ifz call print_str_to_terminal
    ; bats are colored in yellow
    cmp [shell_dir_command_type_buffer], [shell_dir_command_bat_type_str]
    ifz mov r0, shell_dir_command_color_yellow
    ifz call print_str_to_terminal

    ; print the file name to the terminal
    mov r0, shell_dir_command_file_buffer
    call print_str_to_terminal

    ; space
    mov r0, ' '
    call print_character_to_terminal

    ; print the file type to the terminal
    mov r0, shell_dir_command_type_buffer
    call print_str_to_terminal

    ; reset the color
    mov r0, shell_dir_command_color_white
    call print_str_to_terminal

    ; two spaces
    mov r0, ' '
    call print_character_to_terminal
    call print_character_to_terminal

    ; get and print the file size
    ; skip if this is a dir
    cmp [shell_dir_command_type_buffer], [shell_dir_command_dir_type_str]
    ifz jmp shell_dir_command_skip_file
    ; call ryfs_open instead of open because this uses the internal filename style
    mov r0, shell_dir_command_list_buffer
    add r0, r3
    movz.8 r1, [shell_dir_command_file_disk]
    mov r2, shell_dir_command_temp_file_struct
    push r3
    movz.16 r3, [shell_dir_command_file_dir]
    call ryfs_open
    pop r3
    cmp r0, 0
    ifz jmp shell_dir_command_skip_file
    mov r0, shell_dir_command_temp_file_struct
    call get_size
    call print_decimal_to_terminal
shell_dir_command_skip_file:
    ; new line
    mov r0, 10
    call print_character_to_terminal
    ; reset the color
    mov r0, shell_dir_command_color_white
    call print_str_to_terminal

    ; point to next file name in the buffer
    add r3, 11
    loop shell_dir_command_loop

    ret

; FIXME: this assumes the passed name is always on the current disk
shell_dir_command_open_dir:
    push r0
    call get_current_disk_id
    mov r1, r0
    pop r0
    mov r2, shell_dir_command_temp_file_struct
    call open
    mov.16 [shell_dir_command_file_dir], r0
    ; `open` may have used a different disk depending on the path
    ; first byte of the file struct is the disk ID
    mov r0, shell_dir_command_temp_file_struct
    mov.8 [shell_dir_command_file_disk], [r0]
    ret

shell_dir_command_list_buffer: data.fill 0, 341
shell_dir_command_file_buffer: data.fill 0, 9
shell_dir_command_type_buffer: data.fill 0, 4
shell_dir_command_dir_type_str: data.strz "dir"
shell_dir_command_fxf_type_str: data.strz "fxf"
shell_dir_command_bat_type_str: data.strz "bat"
shell_dir_command_file_dir: data.fill 0, 2
shell_dir_command_file_disk: data.fill 0, 1
shell_dir_command_temp_file_struct: data.fill 0, 32
shell_dir_command_header_string:
    data.8 SET_COLOR data.8 0x60 data.8 1 ; set the color to cyan
    data.str "file     type size" data.8 10
shell_dir_command_color_white:
    data.8 SET_COLOR data.8 0x70 data.8 1 ; set the color to white
    data.8 0
shell_dir_command_color_blue:
    data.8 SET_COLOR data.8 0x40 data.8 1 ; set the color to blue
    data.8 0
shell_dir_command_color_green:
    data.8 SET_COLOR data.8 0x20 data.8 1 ; set the color to green
    data.8 0
shell_dir_command_color_red:
    data.8 SET_COLOR data.8 0x10 data.8 1 ; set the color to red
    data.8 0
shell_dir_command_color_yellow:
    data.8 SET_COLOR data.8 0x30 data.8 1 ; set the color to yellow
    data.8 0
