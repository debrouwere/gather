all: build

.PHONY: build
build:
	coffee --output lib --compile src

clean:
	rm -rf lib

.PHONY: test
test: build
	rm -f examples/staff.json
	mocha test \
		--require should \
		--compilers coffee:coffee-script/register
