win:
		yasm -fwin32 gx.asm -ogx.obj
		cl /nologo /O2 /Os test.c gx.obj   
nix:
		as gx.s -ogx.o
		gcc -Wall -O2 -Os test.c gx.o -otest	 	    