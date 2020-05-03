;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sparkle512_arm.asm: ARM Asm implementation of the SPARKLE512 permutation. ;;
;; This file is part of the SPARKLE submission to NIST's LW Crypto Project.  ;;
;; Version 1.0.1 (2019-06-29), see <http://www.cryptolux.org/> for updates.  ;;
;; Authors: The SPARKLE Group (C. Beierle, A. Biryukov, L. Cardoso dos       ;;
;; Santos, J. Groszschaedl, L. Perrin, A. Udovenko, V. Velichkov, Q. Wang).  ;;
;; License: GPLv3 (see LICENSE file), other licenses available upon request. ;;
;; Copyright (C) 2019 University of Luxembourg <http://www.uni.lu/>.         ;;
;; ------------------------------------------------------------------------- ;;
;; This program is free software: you can redistribute it and/or modify it   ;;
;; under the terms of the GNU General Public License as published by the     ;;
;; Free Software Foundation, either version 3 of the License, or (at your    ;;
;; option) any later version. This program is distributed in the hope that   ;;
;; it will be useful, but WITHOUT ANY WARRANTY; without even the implied     ;;
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the  ;;
;; GNU General Public License for more details. You should have received a   ;;
;; copy of the GNU General Public License along with this program. If not,   ;;
;; see <http://www.gnu.org/licenses/>.                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    
    AREA sparkle_arm, CODE, READONLY
    ALIGN 2
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; REGISTER NAMES AND CONSTANTS ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;; register sta holds the start address of array <state>
sta RN r0
;; register ns holds the parameter <ns>, i.e. the number of steps
ns RN r1
;; register scnt holds the step counter (for loop termination)
scnt RN r2
;; register rca holds the start address of array <rcon>
rca RN lr
;; register c0w holds the 1st word of the array <rcon>
c0w RN r3
;; register c1w holds the 2nd word of the array <rcon>
c1w RN r4
;; register c2w holds the 3rd word of the array <rcon>
c2w RN r3
;; register c2w holds the 4th word of the array <rcon>
c3w RN r4
;; register x0w holds the 1st word of the array <state>
x0w RN r5
;; register y0w holds the 2nd word of the array <state>
y0w RN r6
;; register x1w holds the 3rd word of the array <state>
x1w RN r7
;; register y1w holds the 4th word of the array <state>
y1w RN r8
;; register x2w holds the 5th word of the array <state>
x2w RN r9
;; register y2w holds the 6th word of the array <state>
y2w RN r10
;; register x3w holds the 7th word of the array <state>
x3w RN r11
;; register y3w holds the 8th word of the array <state>
y3w RN r12
;; register c4w holds the 5th word of the array <rcon>
c4w RN r11
;; register c5w holds the 6th word of the array <rcon>
c5w RN r12
;; register c6w holds the 7th word of the array <rcon>
c6w RN r11
;; register c7w holds the 8th word of the array <rcon>
c7w RN r12
;; register x4w holds the 9th word of the array <state>
x4w RN r3
;; register y4w holds the 10th word of the array <state>
y4w RN r4
;; register x5w holds the 11th word of the array <state>
x5w RN r5
;; register y5w holds the 12th word of the array <state>
y5w RN r6
;; register x6w holds the 13th word of the array <state>
x6w RN r7
;; register y6w holds the 14th word of the array <state>
y6w RN r8
;; register x7w holds the 15th word of the array <state>
x7w RN r9
;; register y7w holds the 16th word of the array <state>
y7w RN r10
;; register tmpx holds the XOR of the x-words of array <state>
tmpx RN r1
;; register tmpy holds the XOR of the y-words of array <state>
tmpy RN r2
;; register l0w holds a word from the left of array <state>
l0w RN r11
;; register l1w holds a word from the left of array <state>
l1w RN r12
    
;; round constants  
RCON DCD 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, \
         0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; MACROS FOR SPARKLE512 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    PROLOGUE_512
    push    {r4-r12,lr}
    ldr     rca, =RCON
    ldmia.w sta!, {x0w-y3w}
    MEND
    
    MACRO
    EPILOGUE_512
    stmdb.w sta!, {x0w-y3w}
    pop     {r4-r12,pc}
    MEND
    
    MACRO
    ADD_STEP_CNT_512
    and     c0w, scnt, #7
    ldr.w   c0w, [rca, c0w, lsl #2]
    eor     y0w, y0w, c0w
    eor     y1w, y1w, scnt
    MEND
    
    MACRO
    ARX_BOX $xi, $yi, $ci
    add     $xi, $xi, $yi, ror #31
    eor     $yi, $yi, $xi, ror #24
    eor     $xi, $xi, $ci
    add     $xi, $xi, $yi, ror #17
    eor     $yi, $yi, $xi, ror #17
    eor     $xi, $xi, $ci
    add     $xi, $xi, $yi
    eor     $yi, $yi, $xi, ror #31
    eor     $xi, $xi, $ci
    add     $xi, $xi, $yi, ror #24
    eor     $yi, $yi, $xi, ror #16
    eor     $xi, $xi, $ci
    MEND
    
    MACRO
    QUA_XOR $tx, $x0, $x1, $x2, $x3
    eor     $tx, $x0, $x1
    eor     $tx, $tx, $x2
    eor     $tx, $tx, $x3
    MEND
    
    MACRO
    ARXBOX_LAYER_512
    ;; ARX-box computations for the four left-side branches (i.e. x[0]-y[3]).
    ;; Only two round constants can be loaded at a time (no register space).
    ldmia.w rca!, {c0w-c1w}
    ARX_BOX x0w, y0w, c0w
    ARX_BOX x1w, y1w, c1w
    ldmia.w rca!, {c2w-c3w}
    ARX_BOX x2w, y2w, c2w
    ARX_BOX x3w, y3w, c3w
    ;; tmpx and tmpy are computed in three steps; the first is a quadruple XOR,
    ;; i.e. tmpx = x[0] ^ x[1] ^ x[2] ^ x[3], tmpy = y[0] ^ y[1] ^ y[2] ^ y[3].
    QUA_XOR tmpx, x0w, x1w, x2w, x3w
    QUA_XOR tmpy, y0w, y1w, y2w, y3w
    ;; Left-side branches (i.e. x[0]-y[3]) are written to memory and right-side
    ;; branches (i.e. x[4]-y[7]) are loaded from memory, two words at a time.
    ldmia.w sta, {x4w-y4w}
    stmia.w sta!, {x0w-y0w}
    ldmia.w sta, {x5w-y5w}
    stmia.w sta!, {x1w-y1w}
    ldmia.w sta, {x6w-y6w}
    stmia.w sta!, {x2w-y2w}
    ldmia.w sta, {x7w-y7w}
    stmia.w sta!, {x3w-y3w}
    ;; ARX-box computations for the four right-side branches (i.e. x[4]-y[7]).
    ;; Only two round constants can be loaded at a time (no register space).
    ldmia.w rca!, {c4w-c5w}
    ARX_BOX x4w, y4w, c4w
    ARX_BOX x5w, y5w, c5w
    ldmia.w rca!, {c6w-c7w}
    ARX_BOX x6w, y6w, c6w
    ARX_BOX x7w, y7w, c7w
    sub     rca, rca, #32
    MEND
    
    MACRO
    LINEAR_LAYER_512
    ;; Second step (out of three steps) of the computation of tmpx and tmpy:
    ;; tmpx = tmpx ^ (tmpx << 16) and tmpy = tmpy ^ (tmpy << 16).
    eor     tmpx, tmpx, tmpx, lsl #16
    eor     tmpy, tmpy, tmpy, lsl #16
    ;; First part of Feistel round: left-side branches are loaded from memory
    ;; (using l0w, l1w) and XORed with the right-side branches.
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
    ;; Branch permutation: 1-branch left-rotation of the right-side branches
    ;; along with a swap of the left and right branches (via register writes).
    ;; Also combined with the branch permutation is the second Feistel part,
    ;; which consists of a 16-bit rotation of tmpx and tmpx (this is the third
    ;; and final step of the computation of tmpx and tmpx), as well as the XOR
    ;; of tmpx and tmpy with the result of the first Feistel part.
    eor     y3w, y4w, tmpx, ror #16
    eor     x3w, x4w, tmpy, ror #16
    eor     y2w, y7w, tmpx, ror #16
    eor     x2w, x7w, tmpy, ror #16
    eor     y1w, y6w, tmpx, ror #16
    eor     x1w, x6w, tmpy, ror #16
    eor     y0w, y5w, tmpx, ror #16
    eor     x0w, x5w, tmpy, ror #16
    MEND
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; SPARKLE512 PERMUTATION (BRANCH-UNROLLED) ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;; Function prototype:
;; -------------------
;; void sparkle512_arm(uint32_t *state, int ns)
;;
;; Parameters:
;; -----------
;; state: pointer to an uint32_t-array containing the 16 state words
;; ns: number of steps
;;
;; Return value:
;; -------------
;; None
    
    EXPORT sparkle512_arm
sparkle512_arm FUNCTION
    PROLOGUE_512            ;; push callee-saved registers
    mov scnt, #0            ;; clear step-counter
loop_512
    ADD_STEP_CNT_512        ;; macro to add step-counter to state
    push {ns-scnt}          ;; push ns and step-counter (we need registers!)
    ARXBOX_LAYER_512        ;; macro for the arxbox layer
    LINEAR_LAYER_512        ;; macro for the linear layer
    pop {ns-scnt}           ;; restore ns and step-counter from stack
    add scnt, #1            ;; increment step-counter
    teq scnt, ns            ;; test whether step-counter equals ns
    bne loop_512            ;; if not then jump back to start of loop
    EPILOGUE_512            ;; pop callee-saved registers
    ENDFUNC
    
    
    END
