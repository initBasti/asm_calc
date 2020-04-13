LINK=ld
ASM=nasm

LINK_FLAG=-m elf_i386
ASM_FLAG=-f elf32 -g

SRC=src
OBJ=obj
BIN=bin

BIN_NAME=$(BIN)/calc

SOURCES=$(wildcard $SRC/*.asm)
OBJECTS=$(SOURCES:$SRC/*.asm=$OBJ/*.o)

all: $(BIN_NAME)

$(BIN_NAME): $(OBJECTS)
	$(LINK) $(LINK_FLAG) $< -o $@

$(OBJECTS): $(SOURCES)
	$(ASM) $(ASM_FLAG) $< -o $@
