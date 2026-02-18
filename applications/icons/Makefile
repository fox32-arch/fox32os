OUTPUT = system/icons.res

include ../application.mk

all: ../../base_image/$(OUTPUT)

ICONS8 := \
	lnk.inc

ICONS16 := \
	mnu.inc

ICONS32 := \
	dir.inc \
	dsk.inc \
	fnt.inc \
	fxf.inc \
	msc.inc \
	ssc.inc

%.inc: %.8.png
	$(GFX2INC) 8 8 $< $@
%.inc: %.16.png
	$(GFX2INC) 16 16 $< $@
%.inc: %.32.png
	$(GFX2INC) 32 32 $< $@
../../base_image/$(OUTPUT): icons.res.asm $(ICONS8) $(ICONS16) $(ICONS32)
	$(FOX32ASM) $< $@
