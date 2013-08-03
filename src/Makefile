SUBDIRS = frontends

DC = dmd
FLAGS = -O -unittest

DYNVM_BIN = bin/dynvm
DYNVM_OBJ = bin/dynvm.o
DYNVM_SRC =               \
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

TESTER_BIN = bin/tester
TESTER_OBJ = bin/tester.o
TESTER_SRC =             \
tester_src/main.d        \


ALL = $(DYNVM_BIN) $(TESTER_BIN)
all: $(ALL)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done

$(DYNVM_BIN): $(DYNVM_SRC)
	$(DC) $(FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(TESTER_BIN): $(TESTER_SRC)
	$(DC) $(FLAGS) -of$@ $^
	rm -f $(TESTER_OBJ)

# test: $(SRC)
# 	$(DC) $(FLAGS) -unittest -of$(BIN_TEST) $(SRC)
# 	time ./$(BIN_TEST)

clean:
	rm -f $(ALL) $(BIN_TEST) *.o
	for dir in $(SUBDIRS); do \
	echo $$dir ; $(MAKE) -C $$dir clean || exit 2; done
