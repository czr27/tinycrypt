;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sparkle256_arm.asm: ARM Asm implementation of the SPARKLE256 permutation. ;;
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
;; register scnt holds the step counter (for loop termination)
scnt RN r0
;; register ns holds the parameter <ns>, i.e. the number of steps
ns RN r1
;; register rca holds the start address of array <rcon>
rca RN r2
;; register c0w holds the 1st word of the array <rcon>
c0w RN r3
;; register c1w holds the 2nd word of the array <rcon>
c1w RN r4
;; register c2w holds the 3rd word of the array <state>
c2w RN r3
;; register c3w holds the 4th word of the array <rcon>
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
;; register tmpx holds a temporary value
tmpx RN r3
;; register tmpy holds another temorary value
tmpy RN r4
    
;; round constants  
RCON DCD 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, \
         0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; MACROS FOR SPARKLE256 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    PROLOGUE_256
    push    {r4-r12}
    ldr     rca, =RCON
    ldm.w   sta, {x0w-y3w}
    push    {sta}
    MEND
    
    MACRO
    EPILOGUE_256
    pop     {sta}
    stm.w   sta, {x0w-y3w}
    pop     {r4-r12}
    bx      lr
    MEND
    
    MACRO
    ADD_STEP_CNT_256
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
    ARXBOX_LAYER_256
    ldmia.w rca!, {c0w, c1w}
    ARX_BOX x0w, y0w, c0w
    ARX_BOX x1w, y1w, c1w
    ldmia.w rca!, {c2w, c3w}
    ARX_BOX x2w, y2w, c2w
    ARX_BOX x3w, y3w, c3w
    sub     rca, rca, #16
    MEND
    
    MACRO
    LINEAR_LAYER_256
    ;; First part of Feistel round: tmpx and tmpy are computed and XORED to the
    ;; y-words and x-words of the right-side branches (i.e. to y[2], y[3] and
    ;; to x[2], x[3]). Note that y[3] and x[3] are stored in register tmpx and
    ;; tmpy (and not in register y3w and x3w) to reduce the execution time of
    ;; the subsequent branch permutation.
    eor     tmpx, x0w, x1w
    eor     tmpx, tmpx, tmpx, lsl #16
    eor     y2w, y2w, tmpx, ror #16
    eor     tmpx, y3w, tmpx, ror #16
    eor     tmpy, y0w, y1w
    eor     tmpy, tmpy, tmpy, lsl #16
    eor     x2w, x2w, tmpy, ror #16
    eor     tmpy, x3w, tmpy, ror #16
    ;; Branch permutation: 1-branch left-rotation of the right-side branches
    ;; along with a swap of the left and right branches (via register writes).
    ;; Also combined with the branch permutation is the second Feistel part,
    ;; in which the left-side branches are XORed with the result of the first
    ;; Feistel part.
    mov     y3w, y1w
    eor     y1w, y2w, y0w
    mov     y2w, y0w
    eor     y0w, tmpx, y3w
    mov     x3w, x1w
    eor     x1w, x2w, x0w
    mov     x2w, x0w
    eor     x0w, tmpy, x3w
    MEND
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; SPARKLE256 PERMUTATION (BRANCH-UNROLLED) ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;; Function prototype:
;; -------------------
;; void sparkle256_arm(uint32_t *state, int ns)
;;
;; Parameters:
;; -----------
;; state: pointer to an uint32_t-array containing the 8 state words
;; ns: number of steps
;;
;; Return value:
;; -------------
;; None
    
    EXPORT sparkle256_arm
sparkle256_arm FUNCTION
    PROLOGUE_256            ;; push callee-saved registers
    mov scnt, #0            ;; clear step-counter
loop_256
    ADD_STEP_CNT_256        ;; macro to add step-counter to state
    ARXBOX_LAYER_256        ;; macro for the arxbox layer
    LINEAR_LAYER_256        ;; macro for the linear layer
    add scnt, #1            ;; increment step-counter
    teq scnt, ns            ;; test whether step-counter equals ns
    bne loop_256            ;; if not then jump back to start of loop
    EPILOGUE_256            ;; pop callee-saved registers
    ENDFUNC
    
    
    END
