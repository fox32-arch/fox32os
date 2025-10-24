RYFS := ../../meta/ryfs/ryfs.py
OKAMERON := ../../meta/okameron/okameron.lua

JACKAL_ROOT = ../../meta/jackal
JKL = $(JACKAL_ROOT)/bin/jkl.exe
XRASM = $(JACKAL_ROOT)/bin/xrasm.exe
XRLINK = $(JACKAL_ROOT)/bin/xrlink.exe
RTLLIB = $(JACKAL_ROOT)/Rtl/build/fox32/Rtl.lib

ifeq (, $(shell which fox32asm))
FOX32ASM ?= ../../../fox32asm/target/release/fox32asm
else
FOX32ASM ?= fox32asm
endif

ifeq (, $(shell which gfx2inc))
GFX2INC ?= ../../../tools/gfx2inc/target/release/gfx2inc
else
GFX2INC ?= gfx2inc
endif

ifeq ($(shell uname), Darwin)
REALPATH ?= grealpath
else
REALPATH ?= realpath
endif
