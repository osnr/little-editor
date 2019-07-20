all: editor

.PHONY: lua
lua:
	cd lua && cp src/luaconf.h.orig src/luaconf.h && make macosx

editor: watch.c main.m
	cc -fobjc-arc -framework Cocoa -x objective-c -Ilua/src -Llua/src -llua -o editor watch.c main.m

clean:
	rm -f editor
