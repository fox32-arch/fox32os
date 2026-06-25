OBJECTS = os.o rom.o
OUTPUT = ../base_image/develop/lib/fox.lib

JACKAL_ROOT = ../meta/jackal
JKL = $(JACKAL_ROOT)/bin/jkl.exe
XRASM = $(JACKAL_ROOT)/bin/xrasm.exe
XRLINK = $(JACKAL_ROOT)/bin/xrlink.exe

RTLLIB = $(JACKAL_ROOT)/Rtl/build/fox32/Rtl.lib

.SUFFIXES: .o .asm .hjk .jkl

all: $(OUTPUT)

$(OUTPUT): $(OBJECTS)
	target=fox32 $(XRLINK) link -fragment $@ $(OBJECTS) $(RTLLIB)
	cp os.hjk ../base_image/develop/lib/
	cp rom.hjk ../base_image/develop/lib/
	cp rtl.hjk ../base_image/develop/lib/
	cp keys.hjk ../base_image/develop/lib/
	cp guistart.asm ../base_image/develop/lib/
	cp $(RTLLIB) ../base_image/develop/lib/rtl.lib
.jkl.asm:
	$(JKL) target=fox32 $< $@
.asm.o:
	$(XRASM) target=fox32 $< $@

clean:
	rm -f $(OBJECTS) $(OUTPUT)

.PHONY: clean
