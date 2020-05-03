;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sparkle384_arm.asm: ARM Asm implementation of the SPARKLE384 permutation. ;;
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
;; register c0w holds a round constant (i.e. a word of array <rcon>)
c0w RN r0
;; register ns holds the parameter <ns>, i.e. the number of steps
ns RN r1
;; register rca holds the start address of array <rcon>
rca RN r1
;; register x0w holds the 1st word of the array <state>
x0w RN r2
;; register y0w holds the 2nd word of the array <state>
y0w RN r3
;; register x1w holds the 3rd word of the array <state>
x1w RN r4
;; register y1w holds the 4th word of the array <state>
y1w RN r5
;; register x2w holds the 5th word of the array <state>
x2w RN r6
;; register y2w holds the 6th word of the array <state>
y2w RN r7
;; register x3w holds the 7th word of the array <state>
x3w RN r8
;; register y3w holds the 8th word of the array <state>
y3w RN r9
;; register x4w holds the 9th word of the array <state>
x4w RN r10
;; register y4w holds the 10th word of the array <state>
y4w RN r11
;; register x5w holds the 11th word of the array <state>
x5w RN r12
;; register y5w holds the 12th word of the array <state>
y5w RN lr
;; register tmpx holds a temporary value
tmpx RN r0
;; register tmpy holds another temorary value
tmpy RN r1
    
;; round constants  
RCON DCD 0xB7E15162, 0xBF715880, 0x38B4DA56, 0x324E7738, \
         0xBB1185EB, 0x4F7C7B57, 0xCFBFA1C8, 0xC2B3293D
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; MACROS FOR SPARKLE384 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    MACRO
    PROLOGUE_384
    push    {r4-r12,lr}
    ldmia.w sta!, {x0w-x5w,y5w}
    push    {sta}
    MEND
    
    MACRO
    EPILOGUE_384
    pop     {sta}
    stmdb.w sta!, {x0w-x5w,y5w}
    pop     {r4-r12,lr}
    bx      lr
    MEND
    
    MACRO
    ADD_STEP_CNT_384
    ldr     rca, =RCON
    eor     y1w, y1w, scnt
    and     scnt, scnt, #7
    ldr.w   c0w, [rca, scnt, lsl #2]
    eor     y0w, y0w, c0w
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
    ARXBOX_LAYER_384
    ;; ARX-box computations for the three left-side branches (i.e. x[0]-y[2]).
    ;; ldr.w   c0w, [rca, #0]
    movw    c0w, #0x5162
    movt    c0w, #0xB7E1
    ARX_BOX x0w, y0w, c0w
    ;; ldr.w   c0w, [rca, #4]
    movw    c0w, #0x5880
    movt    c0w, #0xBF71
    ARX_BOX x1w, y1w, c0w
    ;; ldr.w   c0w, [rca, #8]
    movw    c0w, #0xDA56
    movt    c0w, #0x38B4
    ARX_BOX x2w, y2w, c0w
    ;; ARX-box computations for the three right-side branches (i.e. x[3]-y[5]).
    ;; ldr.w   c0w, [rca, #12]
    movw    c0w, #0x7738
    movt    c0w, #0x324E
    ARX_BOX x3w, y3w, c0w
    ;; ldr.w   c0w, [rca, #16]
    movw    c0w, #0x85EB
    movt    c0w, #0xBB11
    ARX_BOX x4w, y4w, c0w
    ;; ldr.w   c0w, [rca, #20]
    movw    c0w, #0x7B57
    movt    c0w, #0x4F7C
    ARX_BOX x5w, y5w, c0w
    MEND
    
    MACRO
    LINEAR_LAYER_384
    ;; First part of Feistel round: tmpx and tmpy are computed and XORED to the
    ;; y-words and x-words of the right-side branches (i.e. to y[3], y[4], y[5]
    ;; and to x[3], x[4], x[5]). Note that y[5] and x[5] are stored in register
    ;; tmpx and tmpy (and not in register y5w and x5w) to reduce the execution
    ;; time of the subsequent branch permutation.
    eor     tmpx, x0w, x1w
    eor     tmpx, tmpx, x2w
    eor     tmpx, tmpx, tmpx, lsl #16
    eor     y3w, y3w, tmpx, ror #16
    eor     y4w, y4w, tmpx, ror #16
    eor     tmpx, y5w, tmpx, ror #16
    eor     tmpy, y0w, y1w
    eor     tmpy, tmpy, y2w
    eor     tmpy, tmpy, tmpy, lsl #16
    eor     x3w, x3w, tmpy, ror #16
    eor     x4w, x4w, tmpy, ror #16
    eor     tmpy, x5w, tmpy, ror #16
    ;; Branch permutation: 1-branch left-rotation of the right-side branches
    ;; along with a swap of the left and right branches (via register writes).
    ;; Also combined with the branch permutation is the second Feistel part,
    ;; in which the left-side branches are XORed with the result of the first
    ;; Feistel part.
    mov     y5w, y2w
    eor     y2w, y3w, y0w
    mov     y3w, y0w
    eor     y0w, y4w, y1w
    mov     y4w, y1w
    eor     y1w, tmpx, y5w
    mov     x5w, x2w
    eor     x2w, x3w, x0w
    mov     x3w, x0w
    eor     x0w, x4w, x1w
    mov     x4w, x1w
    eor     x1w, tmpy, x5w
    MEND
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; SPARKLE384 PERMUTATION (BRANCH-UNROLLED) ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;; Function prototype:
;; -------------------
;; void sparkle384_arm(uint32_t *state, int ns)
;;
;; Parameters:
;; -----------
;; state: pointer to an uint32_t-array containing the 12 state words
;; ns: number of steps
;;
;; Return value:
;; -------------
;; None
    
    EXPORT sparkle384_arm
sparkle384_arm FUNCTION
    PROLOGUE_384            ;; push callee-saved registers
    mov scnt, #0            ;; clear step-counter
loop_384
    push {scnt-ns}          ;; push ns and step-counter (we need registers!)
    ADD_STEP_CNT_384        ;; macro to add step-counter to state
    ARXBOX_LAYER_384        ;; macro for the arxbox layer
    LINEAR_LAYER_384        ;; macro for the linear layer
    pop {scnt-ns}           ;; restore ns and step-counter from stack
    add scnt, #1            ;; increment step-counter
    teq scnt, ns            ;; test whether step-counter equals ns
    bne loop_384            ;; if not then jump back to start of loop
    EPILOGUE_384            ;; pop callee-saved registers
    ENDFUNC
    
    
    END
