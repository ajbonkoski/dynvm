DC = dmd
FLAGS = -O

BIN = dynvm-asm
BIN_TEST = dynvm-asm-test

# Source files
SRC =                    \
dasm/instructions.d      \
dasm/code_obj.d          \
dasm/assembler.d         \

ALL = $(BIN)
all: $(ALL)

$(BIN): $(SRC)
	$(DC) $(FLAGS) -of$(BIN) $(SRC)

test: $(SRC)
	$(DC) $(FLAGS) -unittest -of$(BIN_TEST) $(SRC)
	time ./$(BIN_TEST)

clean:
	rm -f $(BIN) $(BIN_TEST) *.o
