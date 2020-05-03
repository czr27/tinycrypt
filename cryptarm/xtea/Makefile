win:
		yasm -fwin32 xteax.asm -oxteax.obj
		cl /nologo /O2 /Os test.c xteax.obj   
nix:
		as xteax.s -oxteax.o
		gcc -Wall -O2 -Os test.c xteax.o -otest	 	    