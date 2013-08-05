

ALL = fib
all: $(ALL)

fib: fib.c
	gcc -O3 -std=gnu99 $^ -o $@
	objdump -D $@ > $@.dis

clean:
	rm -f $(ALL) *.dis

