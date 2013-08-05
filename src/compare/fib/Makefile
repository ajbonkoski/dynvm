

ALL = fib fib.class
all: $(ALL)

fib: fib.c
	gcc -O3 -std=gnu99 $^ -o $@
	objdump -D $@ > $@.dis

fib.class: fib.java
	javac $^

clean:
	rm -f $(ALL) *.dis
