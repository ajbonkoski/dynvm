SUBDIRS = frontends

DC = dmd
#DC = ldc2
#DC = gdc

DEBUG_FLAGS = -O -unittest -debug
RELEASE_FLAGS = -O -release -inline -noboundscheck
PROFILE_FLAGS = -O -profile -release -inline -noboundscheck

DYNVM_BIN = bin/dynvm
DYNVM_DEBUG_BIN = bin/dynvm-debug
DYNVM_PROFILE_BIN = bin/dynvm-profile
DYNVM_OBJ = bin/dynvm.o
DYNVM_SRC =               \
common/common.d          \
datastruct/stack.d       \
datastruct/hashtable.d   \
main.d                   \
dasm/instructions.d      \
dasm/literal.d           \
dasm/code_obj.d          \
dasm/assembler.d         \
interpret/dyn_obj.d      \
interpret/stack_frame.d  \
interpret/state.d        \
interpret/interpreter.d  \

TESTER_FLAGS =
TESTER_BIN = bin/tester
TESTER_OBJ = bin/tester.o
TESTER_SRC =             \
tester_src/main.d        \

DEBUG = $(DYNVM_DEBUG_BIN) $(TESTER_BIN)
debug:  $(DEBUG)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	rm -f $(DYNVM_BIN) $(DYNVM_PROFILE_BIN)

PROFILE = $(DYNVM_PROFILE_BIN) $(TESTER_BIN)
profile:  $(PROFILE)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	rm -f $(DYNVM_BIN) $(DYNVM_DEBUG_BIN)

RELEASE = $(DYNVM_BIN) $(TESTER_BIN)
release: $(RELEASE)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	rm -f $(DYNVM_DEBUG_BIN) $(DYNVM_PROFILE_BIN)

all: $(DYNVM_DEBUG_BIN) $(DYNVM_PROFILE_BIN) $(DYNVM_BIN) $(TESTER_BIN)
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done

$(DYNVM_BIN): $(DYNVM_SRC)
	$(DC) $(RELEASE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_DEBUG_BIN): $(DYNVM_SRC)
	$(DC) $(DEBUG_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_PROFILE_BIN): $(DYNVM_SRC)
	$(DC) $(PROFILE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(TESTER_BIN): $(TESTER_SRC)
	$(DC) $(TESTER_FLAGS) -of$@ $^
	rm -f $(TESTER_OBJ)

clean:
	rm -f $(RELEASE) $(DEBUG) $(PROFILE) $(BIN_TEST) *.o
	for dir in $(SUBDIRS); do \
	echo $$dir ; $(MAKE) -C $$dir clean || exit 2; done
