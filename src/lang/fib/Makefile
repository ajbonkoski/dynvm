NAME = fib

JAVA_RUN = '\#!/bin/bash\nMYDIR=$$(dirname $$(readlink -f $$0)); cd $$MYDIR && java $(NAME) $$@\n'
ALL = $(NAME) $(NAME).class $(NAME).java.run
all: $(ALL)

$(NAME): $(NAME).c
	gcc -O3 -std=gnu99 $^ -o $@
	objdump -D $@ > $@.dis

$(NAME).class: $(NAME).java
	javac $^

$(NAME).java.run:
	printf $(JAVA_RUN) > $@
	chmod +x $@

clean:
	rm -f $(ALL) *.dis
