# fox32os Window Manager

fox32os uses fox32's overlay framebuffer feature to accelerate the rendering of
application windows. Each window uses one overlay, and the overlay ID it is
currently assigned is stored within the application's window struct.
An important thing to remember is that **the overlay ID assigned to your window
can change when your task resumes from a yield**. Overlay IDs are ordered based
on their drawing priority. Overlays are drawn to the screen starting at ID 0
and incrementing until ID 31. As such, a window assigned to overlay ID 0 will
be visually *behind* a window assigned overlay ID 1. Overlay IDs 29, 30, and 31
are reserved for the menu, menu bar, and mouse cursor respectively.

fox32rom includes numerous routines for drawing text and graphics to overlays.
These are the main way of drawing to a window. As an example, here is one way
to draw a string of text to a window:

```avrasm
    mov r0, window_struct
    call get_window_overlay_number

    ; r0 now contains the overlay ID used by our window
    ; this ID may be different after returning from a yield,
    ; so don't cache this value anywhere that may be used after a yield.

    mov r5, r0           ; overlay ID to draw to
    mov r0, hello_string ; addr of null-terminated string
    mov r1, 32           ; X position of the first character
    mov r2, 32           ; Y position of the first character
    mov r3, 0xFFFFFFFF   ; text foreground color
    mov r4, 0xFF000000   ; text background color
    call draw_str_to_overlay

    ...

hello_string: data.strz "hello world!!"
```
