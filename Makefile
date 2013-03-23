M4 := m4
JSON := json
MOCHA := node_modules/.bin/mocha

METADATA := package.json
PKG := $(shell $(JSON) -a -d- name version < $(METADATA))
PKG_FILES := $(shell $(JSON) files < $(METADATA) | $(JSON) -a)

OPTS :=

.PHONY: clobber clean manifest_clean compile_clean

all: test

test: compile
	$(MOCHA) --compilers coffee:coffee-script -u tdd test $(OPTS)

compile: node_modules manifest.json
	$(MAKE) -C src compile

include chrome.mk

compile_clean:
	$(MAKE) -C src clean

node_modules: package.json
	npm install
	touch $@

manifest.json: manifest.m4 $(METADATA)
	$(M4) $< > $@

manifest_clean:
	rm -f manifest.json

clean: manifest_clean compile_clean chrome_clean
	[ -r lib ] && rmdir lib; :

clobber: clean
	rm -rf node_modules

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
