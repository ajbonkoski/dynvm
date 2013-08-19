DC = dmd
#DC = ldc2
#DC = gdc

DEBUG_FLAGS = -O -unittest -debug -gc
RELEASE_FLAGS = -O -release -inline -noboundscheck
#RELEASE_FLAGS = -O3 -release -m64
PROFILE_FLAGS = -O -profile -release -inline -noboundscheck

DYNVM_BIN = ../bin/dynvm
DYNVM_DEBUG_BIN = ../bin/dynvm-debug
DYNVM_PROFILE_BIN = ../bin/dynvm-profile
DYNVM_OBJ = ../bin/dynvm.o ../bin/dynvm-debug.o ../bin/dynvm-profile.o
DYNVM_SRC =              \
common/common.d          \
datastruct/stack.d       \
datastruct/hashtable.d   \
main.d                   \
hlasm/instructions.d     \
hlasm/literal.d          \
hlasm/code_obj.d         \
hlasm/assembler.d        \
vm/dyn_obj.d             \
vm/stack_frame.d         \
vm/state.d               \
vm/interpreter.d         \


DEBUG = $(DYNVM_DEBUG_BIN)
debug:  $(DEBUG)
	rm -f $(DYNVM_BIN) $(DYNVM_PROFILE_BIN)

PROFILE = $(DYNVM_PROFILE_BIN)
profile:  $(PROFILE)
	rm -f $(DYNVM_BIN) $(DYNVM_DEBUG_BIN)

RELEASE = $(DYNVM_BIN)
release: $(RELEASE)
	rm -f $(DYNVM_DEBUG_BIN) $(DYNVM_PROFILE_BIN)

all: $(DYNVM_DEBUG_BIN) $(DYNVM_PROFILE_BIN) $(DYNVM_BIN)

$(DYNVM_BIN): $(DYNVM_SRC)
	$(DC) $(RELEASE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_DEBUG_BIN): $(DYNVM_SRC)
	$(DC) $(DEBUG_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

$(DYNVM_PROFILE_BIN): $(DYNVM_SRC)
	$(DC) $(PROFILE_FLAGS) -of$@ $^
	rm -f $(DYNVM_OBJ)

clean:
	rm -f $(RELEASE) $(DEBUG) $(PROFILE) $(DYNVM_OBJ) *.o
