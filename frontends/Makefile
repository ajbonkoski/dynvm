# Only add your directories to this folder if you are 100% sure that
# it will always compile without warnings.

SUBDIRS = simple_lua


all:
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done

clean:
	for dir in $(SUBDIRS); do \
	echo $$dir ; $(MAKE) -C $$dir clean || exit 2; done
