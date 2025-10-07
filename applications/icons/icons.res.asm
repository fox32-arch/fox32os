const ICON_SIZE_16x16: 1024
const ICON_SIZE_32x32: 4096

    ; format: "RES" magic bytes, version, number of resource IDs
    data.str "RES" data.8 0 data.8 9

    ; format: 3 character null-terminated ID, pointer to data, size
    data.strz "ICN" data.32 ICN data.32 35
    data.strz "IC2" data.32 IC2 data.32 30
    data.strz "dir" data.32 dir data.32 ICON_SIZE_32x32
    data.strz "dsk" data.32 dsk data.32 ICON_SIZE_32x32
    data.strz "fnt" data.32 fnt data.32 ICON_SIZE_32x32
    data.strz "fxf" data.32 fxf data.32 ICON_SIZE_32x32
    data.strz "mnu" data.32 mnu data.32 ICON_SIZE_16x16
    data.strz "msc" data.32 msc data.32 ICON_SIZE_32x32
    data.strz "ssc" data.32 ssc data.32 ICON_SIZE_32x32

ICN:
    data.strz "icons by https://twistedlogic.space"
IC2:
    data.strz "icons by https://www.finlee.ee"
dir:
    #include "dir.inc"
dsk:
    #include "dsk.inc"
fnt:
    #include "fnt.inc"
fxf:
    #include "fxf.inc"
mnu:
    #include "mnu.inc"
msc:
    #include "msc.inc"
ssc:
    #include "ssc.inc"
