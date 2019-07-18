all: ide

.PHONY: lua
lua:
	cd lua && cp src/luaconf.h.orig src/luaconf.h && make macosx

ide: watch.c ide.m
	cc -fobjc-arc -framework Cocoa -x objective-c -Ilua/src -Llua/src -llua -o ide watch.c ide.m
