OUTPUT = system/bg.fxf
BMP_OUTPUT = user/bg/

include ../application.mk

all: ../../base_image/$(OUTPUT) ../../base_image/$(BMP_OUTPUT)

../../base_image/$(OUTPUT): main.asm fox1.qoi fox2.qoi fox3.qoi
	$(FOX32ASM) $< $@
	mkdir -p ../../base_image/$(BMP_OUTPUT)
	cp fox1.qoi fox2.qoi fox3.qoi ../../base_image/$(BMP_OUTPUT)
