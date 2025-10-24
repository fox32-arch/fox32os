OUTPUT = system/filer.fxf

include ../application.mk

OBJECTS = filer.o window.o desktop.o sys/os.o sys/rom.o
.SUFFIXES: .o .asm .jkl

all: ../../base_image/$(OUTPUT)

../../base_image/$(OUTPUT): $(OBJECTS)
	target=fox32 $(XRLINK) link $@ $(OBJECTS) $(RTLLIB)
.jkl.asm:
	$(JKL) target=fox32 $< $@
.asm.o:
	$(XRASM) target=fox32 $< $@

clean:
	rm -f $(OBJECTS)

.PHONY: clean
