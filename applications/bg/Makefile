OUTPUT = system/bg.fxf
BMP_OUTPUT = user/bg.bmp

include ../application.mk

all: ../../base_image/$(OUTPUT) ../../base_image/$(BMP_OUTPUT)

../../base_image/$(OUTPUT): main.asm
	$(FOX32ASM) $< $@
../../base_image/$(BMP_OUTPUT): bg.bmp
	cp $< $@
