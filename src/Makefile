DC = dmd
FLAGS = -O

BIN = dynvm
BIN_TEST = dynvm-test

# Source files
SRC =                    \
datastruct/stack.d       \
main.d                   \
dasm/instructions.d      \
dasm/literal.d           \
dasm/code_obj.d          \
dasm/assembler.d         \
interpret/dyn_obj.d      \
interpret/stack_frame.d  \
interpret/state.d        \
interpret/interpreter.d  \

ALL = $(BIN)
all: $(ALL)

$(BIN): $(SRC)
	$(DC) $(FLAGS) -of$(BIN) $(SRC)

test: $(SRC)
	$(DC) $(FLAGS) -unittest -of$(BIN_TEST) $(SRC)
	time ./$(BIN_TEST)

clean:
	rm -f $(BIN) $(BIN_TEST) *.o
