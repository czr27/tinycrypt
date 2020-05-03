win:
		yasm -fwin32 ckey.asm -ockey.obj
		yasm -fbin -DBIN ckey.asm -ockey.bin
		cl /nologo /O2 /Os test.c ckey.obj   
nix:
		as ckey.s -ockey.o
		gcc -Wall -O2 -Os test.c ckey.o -otest	 	    