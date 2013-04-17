BROWSERIFY := ../node_modules/.bin/browserify
COFFEE := ../node_modules/.bin/coffee
MAKEDEPEND := make-commonjs-depend

out := ../lib
html := $(wildcard *.html)
out_html := $(patsubst %.html,$(out)/%.html,$(wildcard *.html))

# main entry source points that will go to $(out) after browserfying
src := background.coffee options.coffee
# contains all generated js inter-dependencies
JS_DEPS := js.mk

out_js := $(patsubst %.coffee,$(out)/%.js,$(src))
temp_js := $(patsubst %.coffee,%.js,$(wildcard *.coffee))

.PHONY: depend compile clean

all: compile

depend: $(temp_js)
	$(MAKEDEPEND) *.js -o $(JS_DEPS)

-include $(JS_DEPS)

$(out)/background.js: background.js
$(out)/options.js: options.js

%.js: %.coffee
	$(COFFEE) -c $<

$(out)/%.js: %.js
	@mkdir -p `dirname $@`
	$(BROWSERIFY) $(basename $<).js -o $@

$(out)/%.html: %.html
	cp $< $@

compile: $(temp_js) $(out_js) $(out_html)

clean:
	rm -f $(out_js) $(temp_js) $(out_html) $(JS_DEPS)

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
