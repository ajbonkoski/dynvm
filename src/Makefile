SUBDIRS = frontends

DC = dmd

DEBUG_FLAGS = -O -unittest
RELEASE_FLAGS = -O -release -inline -noboundscheck
PROFILE_FLAGS = -O -profile

#FLAGS = $(DEBUG_FLAGS)
#FLAGS = $(RELEASE_FLAGS)
#FLAGS = $(PROFILE_FLAGS)

DYNVM_BIN = bin/dynvm
DYNVM_DEBUG_BIN = bin/dynvm-debug
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

DEBUG = $(DYNVM_DEBUG_BIN) $(TESTER_BIN)
debug:  $(DEBUG)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done

RELEASE = $(DYNVM_BIN) $(TESTER_BIN)
release: $(RELEASE)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done

$(DYNVM_BIN): $(DYNVM_SRC)
	$(DC) $(RELEASE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_DEBUG_BIN): $(DYNVM_SRC)
	$(DC) $(DEBUG_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(TESTER_BIN): $(TESTER_SRC)
	$(DC) $(RELEASE_FLAGS) -of$@ $^
	rm -f $(TESTER_OBJ)

# test: $(SRC)
# 	$(DC) $(FLAGS) -unittest -of$(BIN_TEST) $(SRC)
# 	time ./$(BIN_TEST)

clean:
	rm -f $(RELEASE) $(DEBUG) $(BIN_TEST) *.o
	for dir in $(SUBDIRS); do \
	echo $$dir ; $(MAKE) -C $$dir clean || exit 2; done
