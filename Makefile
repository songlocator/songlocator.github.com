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

deploy:
	(cd build/; git push origin gh-pages)

build-js:
	r.js -o ./build.js

build: clean-build
	mkdir -p build
	cp -rf css js swf ./build/

clean-build:
	rm -rf build/css build/js build/swf
