RYFS := ../../meta/ryfs/ryfs.py
OKAMERON := ../../meta/okameron/okameron.lua
JKL := ../../meta/jackal/bin/jkl.exe

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
