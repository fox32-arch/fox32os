; clear command

shell_clear_command_string: data.strz "clear"

shell_clear_command:
    movz.8 r0, FILL_TERM
    call print_character_to_terminal
    movz.8 r0, 0
    call print_character_to_terminal
    call print_character_to_terminal

    movz.8 r0, MOVE_CURSOR
    call print_character_to_terminal
    movz.8 r0, 0
    call print_character_to_terminal
    movz.8 r0, 0
    call print_character_to_terminal

    ret
