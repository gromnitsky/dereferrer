BROWSERIFY := ../node_modules/.bin/browserify

out := ../lib
out_coffee := $(patsubst %.coffee,$(out)/%.js,$(wildcard *.coffee))

.PHONY: compile clean

all: compile

$(out)/%.js: %.coffee
	@mkdir -p `dirname $@`
	$(BROWSERIFY) -t coffeeify $< -o $@

compile: $(out_coffee)

clean:
	rm -f $(out_coffee)

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
