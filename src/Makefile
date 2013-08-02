SUBDIRS = frontends

DC = dmd
FLAGS = -O -unittest

BIN = dynvm
BIN_TEST = dynvm-test

# Source files
SRC =                    \
common/common.d          \
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
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done

$(BIN): $(SRC)
	$(DC) $(FLAGS) -of$(BIN) $(SRC)

test: $(SRC)
	$(DC) $(FLAGS) -unittest -of$(BIN_TEST) $(SRC)
	time ./$(BIN_TEST)

clean:
	rm -f $(BIN) $(BIN_TEST) *.o
	for dir in $(SUBDIRS); do \
	echo $$dir ; $(MAKE) -C $$dir clean || exit 2; done
