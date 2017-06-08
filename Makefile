.DELETE_ON_ERROR:

.PHONY: compile
compile:

pkg.name := $(shell json -e 'this.q = this.name + "-" + this.version' q < manifest.json)
out := _build
cache := $(out)/.cache
ext := $(out)/ext

mkdir = @mkdir -p $(dir $@)
copy = cp $< $@

define compile-push
compile: $(1)
compile.all += $(1)
endef

node_modules: package.json
	npm i
	touch $@

$(eval $(call compile-push, node_modules))



coffee.src := $(wildcard src/*.coffee)
coffee.dest := $(patsubst src/%.coffee, $(cache)/%.js, $(coffee.src))

$(cache)/%.js: src/%.coffee
	$(mkdir)
	node_modules/.bin/coffee -c -o $(dir $@) $<

$(eval $(call compile-push, $(coffee.dest)))



vendor.src := $(wildcard vendor/*)
vendor.dest := $(addprefix $(out)/, $(vendor.src))

$(vendor.dest): $(out)/%: %
	$(mkdir)
	$(copy)

$(eval $(call compile-push, $(vendor.dest)))

$(ext)/options.html: src/options.html
	$(mkdir)
	$(copy)
	echo $@ > $(dir $@)/debug.txt

$(eval $(call compile-push, $(ext)/options.html))

static.src := $(wildcard icons/* manifest.json)
static.dest := $(addprefix $(ext)/, $(static.src))

$(static.dest): $(ext)/%: %
	$(mkdir)
	$(copy)

$(eval $(call compile-push, $(static.dest)))



bundles.src := $(cache)/background.js $(cache)/options.js
bundles.dest := $(patsubst $(cache)/%, $(ext)/%, $(bundles.src))

-include $(bundles.src:.js=.d)

# browserify 14.4.0
define make-depend
@echo Generating $(basename $<).d
@printf '%s: ' $@ > $(basename $<).d
@browserify --no-bundle-external --list $< \
        | sed s,$(CURDIR)/,, | sed s,$<,, | tr '\n' ' ' \
        >> $(basename $<).d
endef

# only works w/ browserify 2.6.0, hahaha
$(bundles.dest): $(ext)/%: $(cache)/%
	node_modules/.bin/browserify $< -o $@
	$(make-depend)

$(eval $(call compile-push, $(bundles.dest)))



# crx generation
.PHONY: crx
crx: $(out)/$(pkg.name).crx

$(out)/$(pkg.name).zip: $(compile.all)
	$(mkdir)
	cd $(ext) && zip -x debug.txt -qr $(CURDIR)/$@ *

%.crx: %.zip private.pem
	./zip2crx $< private.pem

# sf

.PHONY: upload
upload:
	scp $(out)/$(pkg.name).crx gromnitsky@web.sourceforge.net:/home/user-web/gromnitsky/htdocs/js/chrome/



.PHONY: test
test:
	node_modules/.bin/mocha --compilers coffee:coffee-script -u tdd test
