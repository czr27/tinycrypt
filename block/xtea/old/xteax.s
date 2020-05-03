
// XTEA in ARMv6 assembly
// @m0dexp

  .text
  .align  2
  .global xtea_encryptx

  // xtea_encryptx(void *key, void *data);

xtea_encryptx:
  // save registers
  push  {r4, r5, r6, r7, r8, lr}
  // 64 rounds by default  
  mov   r2, #64              // r2 holds number of rounds
  // load plaintext
  ldm   r1, {r4, r8}         // r4=v0, r8=v1
  mov   r3, #0               // r3 holds the sum 
  ldr   r6, =#0x9E3779B9     // r6 holds the constant  
.L2:  
  mov   r7, r3               // r7 = sum
  tst   r2, #1               // if (i & 1)
  // the next 2 only execute if (i % 2) is not zero  
  addne r3, r3, r6           // sum += 0x9E3779B9;  
  lsrne r7, r3, #11          // r7 = sum >> 11
  and   r7, r7, #3           // r7 %= 4
  ldr   r7, [r0, r7, asl #2] // r7 = key[r7];
  add   r5, r3, r7           // r5 = sum + t 
  mov   r7, r8, asl #4       // r7 = (v1 << 4)
  eor   r7, r7, r8, lsr #5   // r7 ^= (r8 >> 5)  
  add   r7, r7, r8           // r7 += v1  
  eor   r7, r7, r5           // r7 ^= r5  
  add   r4, r7, r4           // r7 += v0
  // XCHG(v0, v1)
  mov   r5, r4               // r5 = v0
  mov   r4, r8               // v0 = v1
  mov   r8, r5               // v1 = r5
  subs  r2, r2, #1           // i--
  bne   .L2                  // i>0
.L8:
  stm   r1, {r4, r8}         // save ciphertext
                             // restore registers 
  pop   {r4, r5, r6, r7, r8, pc}  
