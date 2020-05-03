win:
	yasm -fwin32 smx.asm -osmx.obj
	cl /O2 /Os test.c smx.obj
nix:
	as smx.s -osmx.o
	gcc test.c smx.o -otest
