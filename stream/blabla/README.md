# BlaBla20

Like ChaCha20, but with the BLAKE2b permutation function.

C implementation of [BlaBla cipher](https://github.com/veorq/blabla) by Jean-Philippe Aumasson.

# Testing

Only tested on x86 architecture.

**GCC or MINGW**

    gcc -DTEST -O2 -Os blabla.c -oblabla

**MSVC**    

    cl /DTEST /O2 /Os blabla.c 