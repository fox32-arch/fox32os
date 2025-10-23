OUTPUT = apps/foxpaint.fxf

include ../application.mk

all: ../../base_image/$(OUTPUT)

../../base_image/$(OUTPUT): main.asm
	$(FOX32ASM) $< $@
