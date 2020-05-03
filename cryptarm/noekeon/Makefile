win:
		yasm -fwin32 nz.asm -onz.obj
		yasm -fbin -DBIN nz.asm -onz.bin
		cl /nologo /O2 /Os test.c nz.obj   
nix:
		as nz.s -onz.o
		gcc -Wall -O2 -Os test.c nz.o -otest	 	    