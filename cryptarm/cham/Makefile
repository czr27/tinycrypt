win:
		yasm -fwin32 chx.asm -ochx.obj
		cl /nologo /O2 /Os test.c chx.obj
nix:
		as chx.s -ochx.o
		gcc -Wall -O2 -Os test.c chx.o -otest
gnu:
		yasm -fbin -DBIN chx.asm -ochx.bin
		yasm -felf32 chx.asm -ochx.o
		gcc -m32 -Os test.c chx.o -otest
