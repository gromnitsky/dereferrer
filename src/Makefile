BROWSERIFY := ../node_modules/.bin/browserify
COFFEE := ../node_modules/.bin/coffee

out := ../lib
out_js := $(patsubst %.coffee,$(out)/%.js,$(wildcard *.coffee))
temp_js := $(patsubst %.coffee,%.js,$(wildcard *.coffee))
html := $(wildcard *.html)
out_html := $(patsubst %.html,$(out)/%.html,$(wildcard *.html))

.PHONY: compile clean

all: compile

$(out)/%.js: %.coffee
	@mkdir -p `dirname $@`
	$(COFFEE) -c -o . $<
	$(BROWSERIFY) $(basename $<).js -o $@
	@rm $(basename $<).js

$(out)/%.html: %.html
	cp $< $@

compile: $(out_js) $(out_html)

clean:
	rm -f $(out_js) $(temp_js) $(out_html)

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
