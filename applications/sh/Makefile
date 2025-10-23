OUTPUT = system/sh.fxf

include ../application.mk

all: ../../base_image/$(OUTPUT)

../../base_image/$(OUTPUT): main.asm $(wildcard *.asm */*.asm)
	$(FOX32ASM) $< $@
