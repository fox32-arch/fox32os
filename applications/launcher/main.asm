; simple application launcher

    opton

    ; create the window
    mov r0, window_struct
    mov r1, window_title
    mov r2, 88
    mov r3, 0
    mov r4, 0
    mov r5, 464
    mov r6, 0
    mov r7, terminal_button_widget
    call new_window

    ; draw the buttons
    mov r0, window_struct
    call draw_widgets_to_window

    ; set the tilemap
    mov r0, icons
    mov r1, 16
    mov r2, 16
    call set_tilemap

    ; draw the icons
    mov r0, window_struct
    call get_window_overlay_number
    mov r3, r0
    mov r0, 0
    mov r1, 72
    mov r2, 0
    call draw_tile_to_overlay

event_loop:
    mov r0, window_struct
    call get_next_window_event

    ; was the mouse clicked?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz call mouse_click_event

    ; did the user click a button?
    cmp r0, EVENT_TYPE_BUTTON_CLICK
    ifz call button_click_event

    call yield_task
    jmp event_loop

mouse_click_event:
    push r0

    ; first, check if we are attempting to drag or close the window
    cmp r1, 72
    iflteq jmp drag_or_close_window

    ; then, handle widget clicks
    mov r0, window_struct
    call handle_widget_click

    pop r0
    ret

button_click_event:
    ; r1 contains the ID of the clicked button

    ; terminal
    cmp r1, 0
    ifz call get_current_disk_id
    cmp r1, 0
    ifz mov r1, r0
    ifz mov r0, terminal_button_fxf
    ifz mov r2, 0
    ifz mov r3, 0
    ifz mov r4, 0
    ifz mov r5, 0
    ifz call launch_fxf_from_disk

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
    call end_current_task

window_title: data.strz "Launcher"
window_struct: data.fill 0, 40

terminal_button_fxf: data.strz "terminal.fxf"
terminal_button_widget:
    data.32 0                  ; next_ptr
    data.32 0                  ; id
    data.32 WIDGET_TYPE_BUTTON ; type
    data.32 button_text        ; text_ptr
    data.32 0xFFFFFFFF         ; foreground_color
    data.32 0xFF000000         ; background_color
    data.16 16                 ; width
    data.16 0                  ; reserved
    data.16 72                 ; x_pos
    data.16 0                  ; y_pos
button_text: data.strz "  "

icons:
    #include "icons.inc"

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
