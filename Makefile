SUBDIRS = ddynasm frontends

debug:
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	echo src/ ; $(MAKE) $(SILENT) -C src/ debug || exit 2

release:
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	echo src/ ; $(MAKE) $(SILENT) -C src/ release || exit 2

prof:
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	echo src/ ; $(MAKE) $(SILENT) -C src/ profile || exit 2

all:
	@for dir in $(SUBDIRS) ; do \
	echo $$dir ; $(MAKE) $(SILENT) -C $$dir all || exit 2; done
	echo src/ ; $(MAKE) $(SILENT) -C src/ all || exit 2

clean:
	echo src/ ; $(MAKE) $(SILENT) -C src/ clean || exit 2

nuke:
	for dir in $(SUBDIRS); do \
	echo $$dir ; $(MAKE) -C $$dir clean || exit 2; done
	echo src/ ; $(MAKE) $(SILENT) -C src/ clean || exit 2
