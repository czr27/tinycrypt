.syntax unified
.thumb
.cpu cortex-m3
.align 8
/*----------------------------------------------------------------------------*/
/*                        Register names and constants                        */
/*----------------------------------------------------------------------------*/

// register sta holds the start address of array <state>
#define sta r0
// register ns holds the parameter <ns>, i.e. the number of steps
#define ns r1
// register scnt holds the step counter (for loop termination)
#define scnt r2
// register rca holds the start address of array <rcon>
#define rca lr
// register c0w holds the 1st word of the array <rcon>
#define c0w r3
// register c1w holds the 2nd word of the array <rcon>
#define c1w r4
// register c2w holds the 3rd word of the array <rcon>
#define c2w r3
// register c2w holds the 4th word of the array <rcon>
#define c3w r4
// register x0w holds the 1st word of the array <state>
#define x0w r5
// register y0w holds the 2nd word of the array <state>
#define y0w r6
// register x1w holds the 3rd word of the array <state>
#define x1w r7
// register y1w holds the 4th word of the array <state>
#define y1w r8
// register x2w holds the 5th word of the array <state>
#define x2w r9
// register y2w holds the 6th word of the array <state>
#define y2w r10
// register x3w holds the 7th word of the array <state>
#define x3w r11
// register y3w holds the 8th word of the array <state>
#define y3w r12
// register c4w holds the 5th word of the array <rcon>
#define c4w r11
// register c5w holds the 6th word of the array <rcon>
#define c5w r12
// register c6w holds the 7th word of the array <rcon>
#define c6w r11
// register c7w holds the 8th word of the array <rcon>
#define c7w r12
// register x4w holds the 9th word of the array <state>
#define x4w r3
// register y4w holds the 10th word of the array <state>
#define y4w r4
// register x5w holds the 11th word of the array <state>
#define x5w r5
// register y5w holds the 12th word of the array <state>
#define y5w r6
// register x6w holds the 13th word of the array <state>
#define x6w r7
// register y6w holds the 14th word of the array <state>
#define y6w r8
// register x7w holds the 15th word of the array <state>
#define x7w r9
// register y7w holds the 16th word of the array <state>
#define y7w r10
// register tmpx holds the XOR of the x-words of array <state>
#define tmpx r1
// register tmpy holds the XOR of the y-words of array <state>
#define tmpy r2
// register l0w holds a word from the left of array <state>
#define l0w r11
// register l1w holds a word from the left of array <state>
#define l1w r12

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
/*                                   Macros                                   */
/*----------------------------------------------------------------------------*/

.macro PROLOGUE_512
    push    {r4-r12,lr}
    ldr     rca, =RCON
    ldmia.w sta!, {x0w-y3w}
.endm

.macro EPILOGUE_512
    stmdb.w sta!, {x0w-y3w}
    pop     {r4-r12,pc}
.endm

.macro ADD_STEP_CNT_512
    and     c0w, scnt, #7
    ldr     c0w, [rca, c0w, lsl #2]
    eor     y0w, y0w, c0w
    eor     y1w, y1w, scnt
.endm

.macro ARX_BOX xi:req, yi:req, ci:req
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

.macro QUA_XOR tx:req, x0:req, x1:req, x2:req, x3:req
    eor     \tx, \x0, \x1
    eor     \tx, \tx, \x2
    eor     \tx, \tx, \x3
.endm

.macro ARXBOX_LAYER_512
    // ARX-box computations for the four left-side branches (i.e. x[0]-y[3]).
    // Only two round constants can be loaded at a time (no register space).
    ldmia.w rca!, {c0w-c1w}
    ARX_BOX x0w, y0w, c0w
    ARX_BOX x1w, y1w, c1w
    ldmia.w rca!, {c2w-c3w}
    ARX_BOX x2w, y2w, c2w
    ARX_BOX x3w, y3w, c3w
    // tmpx and tmpy are computed in three steps/ the first is a quadruple XOR,
    // i.e. tmpx = x[0] ^ x[1] ^ x[2] ^ x[3], tmpy = y[0] ^ y[1] ^ y[2] ^ y[3].
    QUA_XOR tmpx, x0w, x1w, x2w, x3w
    QUA_XOR tmpy, y0w, y1w, y2w, y3w
    // Left-side branches (i.e. x[0]-y[3]) are written to memory and right-side
    // branches (i.e. x[4]-y[7]) are loaded from memory, two words at a time.
    ldmia.w sta, {x4w-y4w}
    stmia.w sta!, {x0w-y0w}
    ldmia.w sta, {x5w-y5w}
    stmia.w sta!, {x1w-y1w}
    ldmia.w sta, {x6w-y6w}
    stmia.w sta!, {x2w-y2w}
    ldmia.w sta, {x7w-y7w}
    stmia.w sta!, {x3w-y3w}
    // ARX-box computations for the four right-side branches (i.e. x[4]-y[7]).
    // Only two round constants can be loaded at a time (no register space).
    ldmia.w rca!, {c4w-c5w}
    ARX_BOX x4w, y4w, c4w
    ARX_BOX x5w, y5w, c5w
    ldmia.w rca!, {c6w-c7w}
    ARX_BOX x6w, y6w, c6w
    ARX_BOX x7w, y7w, c7w
    sub     rca, rca, #32
.endm

.macro LINEAR_LAYER_512
    // Second step (out of three steps) of the computation of tmpx and tmpy:
    // tmpx = tmpx ^ (tmpx << 16) and tmpy = tmpy ^ (tmpy << 16).
    eor     tmpx, tmpx, tmpx, lsl #16
    eor     tmpy, tmpy, tmpy, lsl #16
    // First part of Feistel round: left-side branches are loaded from memory
    // (using l0w, l1w) and XORed to right-side branches, one branch at a time.
    ldmdb.w sta!, {l0w-l1w}
    eor     x7w, x7w, l0w
    eor     y7w, y7w, l1w
    ldmdb.w sta!, {l0w-l1w}
    eor     x6w, x6w, l0w
    eor     y6w, y6w, l1w
    ldmdb.w sta!, {l0w-l1w}
    eor     x5w, x5w, l0w
    eor     y5w, y5w, l1w
    ldmdb.w sta!, {l0w-l1w}
    eor     x4w, x4w, l0w
    eor     y4w, y4w, l1w
    // Second part of Feistel round: 1-branch left-rotation of the right-side
    // branches along with a swap of the left and right branches (via register
    // writes). Also combined with the second Feistel part is third and final
    // step of the computation of tmpx and tmpy, which is a 16-bit rotation.
    eor     y3w, y4w, tmpx, ror #16
    eor     x3w, x4w, tmpy, ror #16
    eor     y2w, y7w, tmpx, ror #16
    eor     x2w, x7w, tmpy, ror #16
    eor     y1w, y6w, tmpx, ror #16
    eor     x1w, x6w, tmpy, ror #16
    eor     y0w, y5w, tmpx, ror #16
    eor     x0w, x5w, tmpy, ror #16
.endm

/*----------------------------------------------------------------------------*/
/*                 SPARKLE512 PERMUTATIONS (BRANCH-UNROLLED)                  */
/*----------------------------------------------------------------------------*/


// Function prototype:
// -------------------
// void sparkle512_arm(uint32_t *state, int ns)
//
// Parameters:
// -----------
// state: pointer to an uint32-array containing the 16 state words
// ns: number of steps
//
// Return value:
// -------------
// None

/*.align	1
.p2align 2,,3
.syntax unified
.thumb
.thumb_func
.fpu softvfp
*/

.global sparkle512_arm
.type sparkle512_arm, %function
sparkle512_arm:
    PROLOGUE_512            // push callee-saved registers
    mov scnt, #0            // clear step-counter
.L1:
    ADD_STEP_CNT_512        // macro to add step-counter to state
    push {ns-scnt}          // push ns and step-counter (we need registers!)
    ARXBOX_LAYER_512        // macro for the arxbox layer
    LINEAR_LAYER_512        // macro for the linear layer
    pop {ns-scnt}           // restore ns and step-counter from stack
    add scnt, #1            // increment step-counter
    teq scnt, ns            // test whether step-counter equals ns
    bne .L1                 // if not then jump back to start of loop
    EPILOGUE_512            // pop callee-saved registers
