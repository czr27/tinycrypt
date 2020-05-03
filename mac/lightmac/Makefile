test:
	gcc -Wall -DAES aes.c lightmac.c test.c -olm_aes
	gcc -Wall -DPRESENT present.c lightmac.c test.c -olm_present
clean:
	rm *.o lm_aes lm_present
