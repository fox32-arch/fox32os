OUTPUT = apps/foxpaint.fxf

include ../application.mk

all: ../../base_image/$(OUTPUT)

icon.inc: icon.png
	$(GFX2INC) 32 32 $< $@

../../base_image/$(OUTPUT): main.asm icon.inc
	$(FOX32ASM) $< $@
