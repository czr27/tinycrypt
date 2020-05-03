win:
		yasm -fwin32 r5x.asm -or5x.obj
		yasm -fbin -DBIN r5x.asm -or5x.bin
		cl /nologo /O2 /Os test.c r5x.obj   
nix:
		as r5x.s -or5x.o
		gcc -Wall -O2 -Os test.c r5x.o -otest	 	    