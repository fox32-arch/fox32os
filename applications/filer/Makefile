OUTPUT = system/filer.fxf
OUTPUT_RES = system/filetype.res

include ../application.mk

OBJECTS = filer.o filetype.o window.o desktop.o newdir.o getinfo.o linkfile.o sys/os.o sys/rom.o
.SUFFIXES: .o .asm .jkl

all: ../../base_image/$(OUTPUT) ../../base_image/$(OUTPUT_RES)

../../base_image/$(OUTPUT): $(OBJECTS)
	target=fox32 $(XRLINK) link $@ $(OBJECTS) $(RTLLIB)
.jkl.asm:
	$(JKL) target=fox32 $< $@
.asm.o:
	$(XRASM) target=fox32 $< $@

../../base_image/$(OUTPUT_RES): filetype.res.asm
	$(FOX32ASM) $< $@

clean:
	rm -f $(OBJECTS)

.PHONY: clean
