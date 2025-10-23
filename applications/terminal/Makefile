OUTPUT = apps/terminal.fxf

include ../application.mk

all: ../../base_image/$(OUTPUT)

../../base_image/$(OUTPUT): main.asm $(wildcard *.asm)
	$(FOX32ASM) $< $@
