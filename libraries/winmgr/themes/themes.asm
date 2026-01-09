; color themes

; set the title bar theme tiles
; inputs:
; r0: pointer to theme struct
; outputs:
; none
set_title_bar_theme:
    mov [title_bar_theme_ptr], r0
    ret

; set the title bar theme tiles using a built-in theme
; inputs:
; r0: offset into the theme list
; outputs:
; none
set_internal_title_bar_theme:
    mul r0, 4
    add r0, theme_list
    mov [title_bar_theme_ptr], [r0]
    ret

; get a pointer to the title bar theme struct
; inputs:
; none
; outputs:
; r0: pointer to theme struct
get_title_bar_theme:
    mov r0, [title_bar_theme_ptr]
    ret

title_bar_theme_ptr: data.32 window_title_bar_transparent_theme

theme_list:
    data.32 window_title_bar_transparent_theme
    data.32 window_title_bar_orange_theme
    data.32 window_title_bar_purple_theme
    data.32 0

#include "themes/orange.inc"
#include "themes/purple.inc"
#include "themes/transparent.inc"
