win:
		yasm -fwin32 xoo.asm -oxoo.obj
		yasm -fbin -DBIN xoo.asm -oxoo.bin
		cl /nologo /O2 /Os test.c xoo.obj   
nix:
		as xoo.s -oxoo.o
		gcc -Wall -O2 -Os test.c xoo.o -otest	 	    