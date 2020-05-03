win:
		yasm -fwin32 r6x.asm -or6x.obj
		cl /nologo /O2 /Os test.c r6x.obj   
nix:
		as r6x.s -or6x.o
		gcc -Wall -O2 -Os test.c r6x.o -otest	 	    