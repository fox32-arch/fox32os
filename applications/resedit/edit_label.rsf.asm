const WIDGET_TYPE_BUTTON:     0x00000000
const WIDGET_TYPE_TEXTBOX_SL: 0x00000001
const WIDGET_TYPE_LABEL:      0x00000002

    ; format: "RES"/"RSF" magic bytes, version, number of resource IDs
    ;         if "RES", no relocations; if "RSF", relocations applied
    data.str "RSF" data.8 0 data.8 2

    ; format: 3 character null-terminated ID, pointer to data, size
    data.strz "WIN" data.32 win data.32 40
    data.strz "WID" data.32 wid data.32 256 ; FIXME: actual size?

; WIN resource layout (40 bytes):
;    data.fill 0, 32 - null-terminated window title
;    data.16 width   - width of this window
;    data.16 height  - height of this window, not including the title bar
;    data.16 x_pos   - X coordinate of this window (top left corner of title bar)
;    data.16 y_pos   - Y coordinate of this window (top left corner of title bar)
win:
    data.str "Edit Label" data.fill 0, 22 ; 32 byte window title
    data.16 128 ; width
    data.16 256 ; height
    data.16 384 ; x_pos
    data.16 64  ; y_pos

wid:
ok_button:
    data.32 text_label         ; next_ptr
    data.32 0                  ; id
    data.32 WIDGET_TYPE_BUTTON ; type
    data.32 ok_button_text     ; text_ptr
    data.32 0xFFFFFFFF         ; foreground_color
    data.32 0xFF000000         ; background_color
    data.16 32                 ; width
    data.16 0                  ; reserved
    data.16 80                 ; x_pos
    data.16 32                 ; y_pos
ok_button_text: data.strz "OK"
text_label:
    data.32 text_textbox       ; next_ptr
    data.32 1                  ; id
    data.32 WIDGET_TYPE_LABEL  ; type
    data.32 text_label_text    ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFFFFFFF         ; background_color
    data.16 0                  ; reserved
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 32                 ; y_pos
text_label_text: data.strz "Text:"
text_textbox:
    data.32 x_label            ; next_ptr
    data.32 2                  ; id
    data.32 WIDGET_TYPE_TEXTBOX_SL ; type
    data.32 text_textbox_buffer ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFAAAAAA         ; background_color
    data.16 96                 ; width
    data.16 12                 ; buffer_max
    data.16 16                 ; x_pos
    data.16 52                 ; y_pos
text_textbox_buffer: data.fill 0, 12
x_label:
    data.32 x_textbox          ; next_ptr
    data.32 3                  ; id
    data.32 WIDGET_TYPE_LABEL  ; type
    data.32 x_label_text       ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFFFFFFF         ; background_color
    data.16 0                  ; reserved
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 72                 ; y_pos
x_label_text: data.strz "X position:"
x_textbox:
    data.32 y_label            ; next_ptr
    data.32 4                  ; id
    data.32 WIDGET_TYPE_TEXTBOX_SL ; type
    data.32 x_textbox_buffer   ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFAAAAAA         ; background_color
    data.16 96                 ; width
    data.16 12                 ; buffer_max
    data.16 16                 ; x_pos
    data.16 92                 ; y_pos
x_textbox_buffer: data.fill 0, 12
y_label:
    data.32 y_textbox          ; next_ptr
    data.32 5                  ; id
    data.32 WIDGET_TYPE_LABEL  ; type
    data.32 y_label_text       ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFFFFFFF         ; background_color
    data.16 0                  ; reserved
    data.16 0                  ; reserved
    data.16 16                 ; x_pos
    data.16 112                ; y_pos
y_label_text: data.strz "Y position:"
y_textbox:
    data.32 0                  ; next_ptr
    data.32 6                  ; id
    data.32 WIDGET_TYPE_TEXTBOX_SL ; type
    data.32 y_textbox_buffer   ; text_ptr
    data.32 0xFF000000         ; foreground_color
    data.32 0xFFAAAAAA         ; background_color
    data.16 96                 ; width
    data.16 12                 ; buffer_max
    data.16 16                 ; x_pos
    data.16 132                ; y_pos
y_textbox_buffer: data.fill 0, 12
