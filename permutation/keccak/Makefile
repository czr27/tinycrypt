test:
	gcc -Wall -Os -DK200 test.c keccak.c -ok200
	gcc -Wall -Os -DK400 test.c keccak.c -ok400
	gcc -Wall -Os -DK800 test.c keccak.c -ok800
	gcc -Wall -Os test.c keccak.c -ok1600
clean:
	rm *.o k200 k400 k800 k1600
