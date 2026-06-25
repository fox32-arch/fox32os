RYFS := meta/ryfs/ryfs.py
NEWSDK := meta/jackal
JKL := $(NEWSDK)/bin/jkl.exe

ifeq (, $(shell which fox32asm 2>/dev/null))
FOX32ASM ?= ../fox32asm/target/release/fox32asm
else
FOX32ASM ?= fox32asm
endif

ifeq ($(shell uname), Darwin)
REALPATH ?= grealpath
else
REALPATH ?= realpath
endif

IMAGE_SIZE := 16777216
ROM_IMAGE_SIZE := 196608
BOOTLOADER := bootloader/boot1.bin
BOOT_STAGE2 := bootloader/boot2.bin

FILES = \
	base_image/system/boot2.bin \
	base_image/system/startup.bat \
	base_image/system/icons.res \
	base_image/system/kernel.fxf \
	base_image/system/sh.fxf \
	base_image/system/barclock.fxf \
	base_image/system/filer.fxf \
	base_image/system/filetype.res \
	base_image/system/serial.fxf \
	base_image/system/bg.fxf \
	base_image/system/format.fxf \
	base_image/system/sysdisk.fxf \
	base_image/system/ted.fxf \
	base_image/system/loadfont.fxf \
	base_image/system/tasks.fxf \
	base_image/apps/terminal.fxf \
	base_image/apps/pride.fxf \
	base_image/apps/foxpaint.fxf \
	base_image/apps/hjkl.fxf \
	base_image/apps/settings.fxf \
	base_image/user/bg.qoi \
	base_image/develop/jkl.fxf \
	base_image/develop/xrasm.fxf \
	base_image/develop/xrlink.fxf \
	base_image/develop/lib/fox.lib \
	base_image/develop/lib/os.hjk \
	base_image/develop/lib/rom.hjk \
	base_image/develop/lib/rtl.hjk \
	base_image/develop/lib/keys.hjk \
	base_image/develop/lib/guistart.asm

# files that shouldn't be removed on `make clean`
CONST_FILES = \
	base_image/develop/demos/readme.txt \
	base_image/develop/demos/make.bat \
	base_image/develop/demos/window.jkl

ROM_FILES = \
	base_image/system/boot2.bin \
	base_image/system/startup.bat \
	base_image/system/icons.res \
	base_image/system/kernel.fxf \
	base_image/system/sh.fxf \
	base_image/system/barclock.fxf \
	base_image/system/filer.fxf \
	base_image/system/filetype.res \
	base_image/system/serial.fxf \
	base_image/system/bg.fxf \
	base_image/system/format.fxf \
	base_image/system/sysdisk.fxf \
	base_image/system/ted.fxf \
	base_image/system/loadfont.fxf \
	base_image/system/tasks.fxf \
	base_image/apps/pride.fxf \
	base_image/apps/terminal.fxf \
	base_image/apps/hjkl.fxf \
	base_image/apps/settings.fxf

all: \
	$(JKL) \
	base_image/system/library \
	base_image/system/font \
	base_image/apps \
	base_image/user \
	base_image/develop/lib \
	fox32os.img #romdisk.img

$(JKL):
	cd $(NEWSDK) && ./bootstrap.sh 2>/dev/null
	cd $(NEWSDK) && ./buildall.sh 4 2>/dev/null

$(NEWSDK)/build/fox32os/jkl.fxf: $(JKL) FORCE
	cd $(NEWSDK) && ./bin/xrbt.exe ./build.xrbt PLATFORM=fox32os TRG_XR17032=0 Jackal
$(NEWSDK)/build/fox32os/xrasm.fxf: $(JKL) FORCE
	cd $(NEWSDK) && ./bin/xrbt.exe ./build.xrbt PLATFORM=fox32os TRG_XR17032=0 XrAsm
$(NEWSDK)/build/fox32os/xrlink.fxf: $(JKL) FORCE
	cd $(NEWSDK) && ./bin/xrbt.exe ./build.xrbt PLATFORM=fox32os TRG_XR17032=0 XrLink

base_image/system/library: FORCE
	mkdir -p base_image/system/library
	$(MAKE) -C libraries
base_image/system/font: FORCE
	mkdir -p base_image/system/font
	$(MAKE) -C fonts
base_image/apps:
	mkdir -p base_image/apps
base_image/user/desktop:
	mkdir -p base_image/user/desktop
base_image/develop/lib:
	mkdir -p base_image/develop/lib

bootloader/boot1.bin: bootloader/boot1.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@
bootloader/boot2.bin: bootloader/boot2.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@
base_image/system/boot2.bin: bootloader/boot2.bin
	cp $< $@
base_image/system/startup.bat: base_image/system/startup.bat.default
	cp $< $@
base_image/develop/%.fxf: $(NEWSDK)/build/fox32os/%.fxf
	cp $< $@
base_image/develop/lib/fox.lib: $(NEWSDK)/build/fox32os/jkl.fxf $(NEWSDK)/build/fox32os/xrasm.fxf $(NEWSDK)/build/fox32os/xrlink.fxf
	cd jkl && $(MAKE)

base_image/system/kernel.fxf: FORCE
	$(MAKE) -C kernel
base_image/system/%.fxf: base_image/develop/lib/fox.lib FORCE
	$(MAKE) -C applications/$*
base_image/system/icons.res: FORCE
	$(MAKE) -C applications/icons
base_image/apps/%.fxf: base_image/develop/lib/fox.lib FORCE
	$(MAKE) -C applications/$*

applications/hjkl/hjkl.fxf: $(JKL) FORCE
	$(MAKE) -C applications/hjkl hjkl.fxf \
		JACKAL=../../$(NEWSDK)/bin/jkl.exe \
		XRASM=../../$(NEWSDK)/bin/xrasm.exe \
		XRLINK=../../$(NEWSDK)/bin/xrlink.exe \
		RTLLIB=../../$(NEWSDK)/Rtl/build/fox32/Rtl.lib
base_image/apps/hjkl.fxf: applications/hjkl/hjkl.fxf
	cp $< $@

FORCE: ;

fox32os.img: $(BOOTLOADER) $(FILES) $(wildcard libraries/*/*.asm)
	$(RYFS) -s $(IMAGE_SIZE) -l boot -b $(BOOTLOADER) create $@.tmp
	$(RYFS) newdir -q $@.tmp system.dir
	$(RYFS) newdir -q -d system $@.tmp library.dir
	$(RYFS) newdir -q -d system $@.tmp font.dir
	$(RYFS) newdir -q $@.tmp apps.dir
	$(RYFS) newdir -q $@.tmp user.dir
	$(RYFS) newdir -q -d user $@.tmp desktop.dir
	$(RYFS) newdir -q $@.tmp develop.dir
	$(RYFS) newdir -q -d develop $@.tmp demos.dir
	$(RYFS) newdir -q -d develop $@.tmp lib.dir
	for file in base_image/system/library/*.lbr; do $(RYFS) add -q -d /system/library $@.tmp $$file; done
	for file in base_image/system/font/*.fnt; do $(RYFS) add -q -d /system/font $@.tmp $$file; done
	for file in base_image/user/desktop/*; do $(RYFS) add -q -d /user/desktop $@.tmp $$file; done
	$(foreach file, $(FILES), $(RYFS) add -q -d $(patsubst %/,%,$(dir $(shell $(REALPATH) --relative-to base_image/ $(file)))) $@.tmp $(file);)
	$(foreach file, $(CONST_FILES), $(RYFS) add -q -d $(patsubst %/,%,$(dir $(shell $(REALPATH) --relative-to base_image/ $(file)))) $@.tmp $(file);)
	mv $@.tmp $@

romdisk.img: $(BOOTLOADER) $(ROM_FILES) $(wildcard libraries/*/*.asm)
	$(RYFS) -s $(ROM_IMAGE_SIZE) -l romdisk -b $(BOOTLOADER) create $@.tmp
	$(RYFS) newdir -q $@.tmp system.dir
	$(RYFS) newdir -q -d system $@.tmp library.dir
	$(RYFS) newdir -q -d system $@.tmp font.dir
	$(RYFS) newdir -q $@.tmp apps.dir
	$(RYFS) newdir -q $@.tmp user.dir
	$(RYFS) newdir -q -d user $@.tmp desktop.dir
	$(RYFS) newdir -q $@.tmp develop.dir
	$(RYFS) newdir -q -d develop $@.tmp demos.dir
	$(RYFS) newdir -q -d develop $@.tmp lib.dir
	for file in base_image/system/library/*.lbr; do $(RYFS) add -q -d /system/library $@.tmp $$file; done
	for file in base_image/user/desktop/*; do $(RYFS) add -q -d /user/desktop $@.tmp $$file; done
	$(foreach file, $(ROM_FILES), $(RYFS) add -q -d $(patsubst %/,%,$(dir $(shell $(REALPATH) --relative-to base_image/ $(file)))) $@.tmp $(file);)
	$(foreach file, $(CONST_FILES), $(RYFS) add -q -d $(patsubst %/,%,$(dir $(shell $(REALPATH) --relative-to base_image/ $(file)))) $@.tmp $(file);)
	mv $@.tmp $@

clean:
	cd libraries && $(MAKE) clean
	cd fonts && $(MAKE) clean
	cd jkl && $(MAKE) clean
	cd $(NEWSDK) && ./bin/xrbt.exe ./build.xrbt PLATFORM=fox32os CLEANUP=1 all
	$(MAKE) -C applications/hjkl clean
	$(MAKE) -C applications/filer clean
	rm -f fox32os.img romdisk.img $(FILES)

.PHONY: clean
