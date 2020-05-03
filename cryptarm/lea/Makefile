win:
		yasm -fwin32 leax.asm -oleax.obj
		cl /nologo /O2 /Os test.c leax.obj   
nix:
		as leax.s -oleax.o
		gcc -Wall -O2 -Os test.c leax.o -otest	 	    