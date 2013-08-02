
ALL = simple_lua.pegc
all: $(ALL)

simple_lua.pegc: simple_lua.peg
	pegvmc $^ > $@

clean:
	rm -f $(ALL) *.pegc *.pegcc *.pyc
