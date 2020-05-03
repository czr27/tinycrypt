.syntax unified
.thumb
.cpu cortex-m3

//////////////////////////////////////////////////////////////////////////////;
// sparkle256_arm.asm: ARM Asm implementation of the SPARKLE256 permutation. //
// This file is part of the SPARKLE submission to NIST's LW Crypto Project.  //
// Version 1.0.1 (2019-06-29), see <http://www.cryptolux.org/> for updates.  //
// Authors: The SPARKLE Group (C. Beierle, A. Biryukov, L. Cardoso dos       //
// Santos, J. Groszschaedl, L. Perrin, A. Udovenko, V. Velichkov, Q. Wang).  //
// License: GPLv3 (see LICENSE file), other licenses available upon request. //
// Copyright (C) 2019 University of Luxembourg <http://www.uni.lu/>.         //
// ------------------------------------------------------------------------- //
// This program is free software: you can redistribute it and/or modify it   //
// under the terms of the GNU General Public License as published by the     //
// Free Software Foundation, either version 3 of the License, or (at your    //
// option) any later version. This program is distributed in the hope that   //
// it will be useful, but WITHOUT ANY WARRANTY; without even the implied     //
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the  //
// GNU General Public License for more details. You should have received a   //
// copy of the GNU General Public License along with this program. If not,   //
// see <http://www.gnu.org/licenses/>.                                       //
//////////////////////////////////////////////////////////////////////////////;
    
    
/*----------------------------------------------------------------------------*/
/*                        Register names and constants                        */
/*----------------------------------------------------------------------------*/

// register sta holds the start address of array <state>
#define sta r0
// register scnt holds the step counter (for loop termination)
#define scnt r0
// register ns holds the parameter <ns>, i.e. the number of steps
#define ns r1
// register rca holds the start address of array <rcon>
#define rca r2
// register c0w holds one word of the array <rcon>
#define c0w r3
// register c1w holds another word of the array <rcon>
#define c1w r4
// register x0w holds the first word of the array <state>
#define x0w r5
// register y0w holds the second word of the array <state>
#define y0w r6
// register x1w holds the third word of the array <state>
#define x1w r7
// register y1w holds the fourth word of the array <state>
#define y1w r8
// register x2w holds the fifth word of the array <state>
#define x2w r9
// register y2w holds the sixth word of the array <state>
#define y2w r10
// register x3w holds the seventh word of the array <state>
#define x3w fp
// register y3w holds the eighth word of the array <state>
#define y3w ip
// register tmpx holds a temporary value
#define tmpx r3
// register tmpy holds another temorary value
#define tmpy r4

/*----------------------------------------------------------------------------*/
/*                              Round Constants                               */
/*----------------------------------------------------------------------------*/

RCON:
    .word 0xB7E15162
    .word 0xBF715880
    .word 0x38B4DA56
    .word 0x324E7738
    .word 0xBB1185EB
    .word 0x4F7C7B57
    .word 0xCFBFA1C8
    .word 0xC2B3293D

/*----------------------------------------------------------------------------*/
/*                                   MACROS                                   */
/*----------------------------------------------------------------------------*/

.macro     PROLOGUE_256
    push    {r4-r12}
    ldr     rca, =RCON
    ldm.w   sta, {x0w-y3w}
    push    {sta}
.endm

.macro     EPILOGUE_256
    pop     {sta}
    stm.w   sta, {x0w-y3w}
    pop     {r4-r12}
    bx      lr
.endm

.macro     ADD_STEP_CNT_256
    and     c0w, scnt, #7
    ldr     c0w, [rca, c0w, lsl #2]
    eor     y0w, y0w, c0w
    eor     y1w, y1w, scnt
.endm

.macro     ARX_BOX xi:req, yi:req, ci:req
    add     \xi, \xi, \yi, ror #31
    eor     \yi, \yi, \xi, ror #24
    eor     \xi, \xi, \ci
    add     \xi, \xi, \yi, ror #17
    eor     \yi, \yi, \xi, ror #17
    eor     \xi, \xi, \ci
    add     \xi, \xi, \yi
    eor     \yi, \yi, \xi, ror #31
    eor     \xi, \xi, \ci
    add     \xi, \xi, \yi, ror #24
    eor     \yi, \yi, \xi, ror #16
    eor     \xi, \xi, \ci
.endm

.macro     ARXBOX_LAYER_256
    ldmia   rca!, {c0w, c1w}
    ARX_BOX x0w, y0w, c0w
    ARX_BOX x1w, y1w, c1w
    ldmia   rca!, {c0w, c1w}
    ARX_BOX x2w, y2w, c0w
    ARX_BOX x3w, y3w, c1w
    sub     rca, rca, #16
.endm

.macro     LINEAR_LAYER_256
    // First part of Feistel round: tmpx and tmpy are computed and XORED to the
    // y-words and x-words of the right-side branches (i.e. to y[2], y[3] and
    // to x[2], x[3]). Note that y[3] and x[3] are stored in register tmpx and
    // tmpy (and not in register y3w and x3w) to reduce the execution time of
    // the subsequent branch permutation.
    eor     tmpx, x0w, x1w
    eor     tmpx, tmpx, tmpx, lsl #16
    eor     y2w, y2w, tmpx, ror #16
    eor     tmpx, y3w, tmpx, ror #16
    eor     tmpy, y0w, y1w
    eor     tmpy, tmpy, tmpy, lsl #16
    eor     x2w, x2w, tmpy, ror #16
    eor     tmpy, x3w, tmpy, ror #16
    // Branch permutation: 1-branch left-rotation of the right-side branches
    // along with a swap of the left and right branches (via register writes).
    // Also combined with the branch permutation is the second Feistel part,
    // in which the left-side branches are XORed with the result of the first
    // Feistel part.
    mov     y3w, y1w
    eor     y1w, y2w, y0w
    mov     y2w, y0w
    eor     y0w, tmpx, y3w
    mov     x3w, x1w
    eor     x1w, x2w, x0w
    mov     x2w, x0w
    eor     x0w, tmpy, x3w
.endm


/*----------------------------------------------------------------------------*/
/*                 SPARKLE256 PERMUTATIONS (BRANCH-UNROLLED)                  */
/*----------------------------------------------------------------------------*/


//Function prototype:
// -------------------
// void sparkle256/384/512_arm(uint32_t *state, int ns)
//
// Parameters:
// -----------
// state: pointer to an uint32-array containing 8/12/16 state words
// ns: number of steps
//
// Return value:
// -------------
// None
/*
.align	1
.p2align 2,,3
.thumb_func
.fpu softvfp
*/
.global sparkle256_arm
.type sparkle256_arm, %function
sparkle256_arm:
    PROLOGUE_256           // push callee-saved registers
    mov scnt, #0           // clear step-counter
.L1:
    ADD_STEP_CNT_256       // macro to add step-counter to state
    ARXBOX_LAYER_256       // macro for the arxbox layer
    LINEAR_LAYER_256       // macro for the linear layer
    add scnt, #1           // increment step-counter
    teq scnt, ns           // test whether step-counter equals ns
    bne .L1                // if not then jump back to start of loop
    EPILOGUE_256           // pop callee-saved registers
