DC = dmd
FLAGS = -O

BIN = dynvm
BIN_TEST = dynvm-test

# Source files
SRC =               \
main.d

ALL = $(BIN)
all: $(ALL)

$(BIN): $(SRC)
	$(DC) $(FLAGS) -of$(BIN) $(SRC)

test: $(SRC)
	$(DC) $(FLAGS) -unittest -of$(BIN_TEST) $(SRC)
	time ./$(BIN_TEST)

clean:
	rm -f $(BIN) $(BIN_TEST) *.o
