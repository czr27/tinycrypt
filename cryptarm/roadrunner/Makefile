win:
		yasm -fwin32 rrx.asm -orrx.obj
		cl /nologo /O2 /Os test.c rrx.obj   
nix:
		as rrx.s -orrx.o
		gcc -Wall -O2 -Os test.c rrx.o -otest	 	    