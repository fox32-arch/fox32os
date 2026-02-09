; GUI application header and support routines

    opton

    data.strz "APP"
    data.32 _gui_entry
    data.32 app_name ; pointer to string of max 12 chars
    data.32 app_desc ; pointer to string of max 50 chars
    data.32 app_author ; pointer to string of max 50 chars
    data.32 app_version ; pointer to string of max 8 chars
    data.32 app_icon ; pointer to 32x32 (32 bpp) icon graphic

; one directory up relative to the main.asm files including this
#include "../gui_only.inc"
