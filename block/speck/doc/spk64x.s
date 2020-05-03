
// speck in armv6 assembly
// 
  .text
  .align  2
  .global speck64_encryptx

speck64_encryptx:
  push  {r2, r3, r4, r5, r6, r7, r8, lr}
  ldm   r0, {r2, r3, r4, r5}
  ldm   r1, {r6, r7}
  mov   r0, #0
.L2:
  // x0 = (ROTR32(x0, 8) + x1) ^ k0;
  add   r6, r7, r6, ror #8
  eor   r6, r6, r2
  
  // k1 = (ROTR32(k1, 8) + k0) ^ i;
  add   r3, r2, r3, ror #8
  eor   r3, r3, r0
  
  // x1 = ROTL32(x1, 3) ^ x0;  
  eor   r7, r6, r7, ror #29
  
  // k0 =  ROTL32(k0, 3) ^ k1;
  eor   r2, r3, r2, ror #29

  mov   r8, r4
  mov   r4, r5
  mov   r5, r8

  add   r0, r0, #1
  cmp   r0, #27
  bne   .L2
.L6:
  stm   r1, {r2, r3}
  pop   {r2, r3, r4, r5, r6, r7, r8, pc}
