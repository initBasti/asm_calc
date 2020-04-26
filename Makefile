COMPILE=gcc
READ=gcc

COMPILE_FLAG=-Wall -Wextra -O3 -g
READ_FLAG=-Wall -Wextra -fverbose-asm -march=haswell -O3 -S

SRC=src
OBJ=obj
VER=verbose
BIN=bin

BIN_NAME=$(BIN)/calc

SOURCES=$(wildcard $(SRC)/*.S)
$(info $$SOURCES is [${SOURCES}])
#OBJECTS=$(SOURCES:$(SRC)/*.S=$(OBJ)/*.o)
#$(info $$OBJECTS is [${OBJECTS}])

all: $(BIN_NAME)

read: $(VER)/main_verbose $(VER)/print_verbose

$(BIN_NAME): $(SOURCES)
	$(COMPILE) $(COMPILE_FLAG) $^ -o $@

$(VER)/%_verbose: $(SRC)/%.S
	$(READ) $(READ_FLAG) $^ > $@ 2>&1

#$(OBJ)/%.o: $(SRC)/%.S
#	$(ASM) $(ASM_FLAG) $< -o $@

clean:
	rm $(OBJ)/*.o
	rm $(BIN)/*
	rm $(VER)/*
