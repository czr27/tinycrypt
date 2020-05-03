win:
		yasm -fwin32 spk.asm -ospk.obj
		cl /nologo /O2 /Os test.c spk.obj   
nix:
		as spk.s -ospk.o
		gcc -Wall -O2 -Os test.c spk.o -otest	 	    