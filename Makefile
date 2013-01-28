SASS = sass --compass
COFFEE = coffee -bc

all: js css
watch:
	@$(MAKE) -j2 watch-js watch-css

watch-css::
	$(SASS) --watch css

watch-js::
	$(COFFEE) --watch -o js js/*.coffee

css::
	$(SASS) css

js::
	$(COFFEE) -o js js/*.coffee

serve:
	static

develop:
	@$(MAKE) -j2 serve watch

bootstrap:
	bower install
