; settings

    #include "../gui_app.inc"
app_name: data.strz "Settings" ; max 12 chars
app_desc: data.strz "Configure fox32os" ; max 50 chars
app_author: data.strz "fox32 contributors (github.com/fox32-arch)" ; max 50 chars
app_version: data.strz "0.0.0" ; max 8 chars
const app_icon: 0

    opton
app_entry:
    mov r0, window_struct
    mov r1, window_title
    mov r2, 136
    mov r3, 108
    mov r4, 32
    mov r5, 32
    mov r6, 0
    mov r7, widgets
    call new_window

    mov r0, window_struct
    call draw_widgets_to_window

event_loop:
    mov r0, window_struct
    call get_next_window_event

    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call mouse_click_event

    cmp r0, EVENT_TYPE_BUTTON_CLICK
    ifz call button_click_event
event_loop_end:
    call yield_task
    rjmp event_loop

mouse_click_event:
    push r0

    ; check if we are attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_or_close_window

    ; check if we are clicking on a widget
    mov r0, window_struct
    call handle_widget_click

    pop r0
    ret

drag_or_close_window:
    cmp r1, 8
    iflteq jmp close_window
    mov r0, window_struct
    call start_dragging_window
    pop r0
    ret
close_window:
    mov r0, window_struct
    call destroy_window
    call app_exit

button_click_event:
    ; r1 contains the ID of the clicked button

    ; theme buttons
    cmp r1, 1
    iflt jmp button_click_event_not_theme
    cmp r1, 3
    ifgt jmp button_click_event_not_theme
    dec r1
    mov r0, r1
    call set_internal_title_bar_theme
    mov r0, window_struct
    call draw_title_bar_to_window
button_click_event_not_theme:
    ret

window_title: data.strz "Settings"
window_struct: data.fill 0, 40

widgets:
theme_label:
    data.32 transparent_theme_button ; next_ptr
    data.32 0                  ; id
    data.32 WIDGET_TYPE_LABEL  ; type
    data.32 theme_label_text   ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFFFFFFF         ; background_color
    data.16 0                  ; reserved
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 28                 ; y_pos
theme_label_text: data.strz "Window Theme:"
transparent_theme_button:
    data.32 orange_theme_button ; next_ptr
    data.32 1                  ; id
    data.32 WIDGET_TYPE_BUTTON ; type
    data.32 transparent_theme_button_text ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFDDDDDD         ; background_color
    data.16 104                ; width
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 48                 ; y_pos
transparent_theme_button_text: data.strz "transparent"
orange_theme_button:
    data.32 purple_theme_button ; next_ptr
    data.32 2                  ; id
    data.32 WIDGET_TYPE_BUTTON ; type
    data.32 orange_theme_button_text ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFDDDDDD         ; background_color
    data.16 104                ; width
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 68                 ; y_pos
orange_theme_button_text: data.strz "orange"
purple_theme_button:
    data.32 0                  ; next_ptr
    data.32 3                  ; id
    data.32 WIDGET_TYPE_BUTTON ; type
    data.32 purple_theme_button_text ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFDDDDDD         ; background_color
    data.16 104                ; width
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 88                 ; y_pos
purple_theme_button_text: data.strz "purple"

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
