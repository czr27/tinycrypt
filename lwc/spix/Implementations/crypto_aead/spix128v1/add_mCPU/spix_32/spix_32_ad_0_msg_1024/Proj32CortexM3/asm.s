/* Reference implementation of SPIX32 (l_ad=0, l_m=16)
 Written by:
 Yunjie Yi <yunjie.yi@uwaterloo.ca>
 */

        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start

;; initialization
        PUSH {R9, R10, R11}
        
        LDR R11,=0x20000000

        LDR R10, =0xf
        STR R10, [R11, #0]
        LDR R10, =0x47
        STR R10, [R11, #4]
        LDR R10, =0x4
        STR R10, [R11, #8]
        LDR R10, =0xb2
        STR R10, [R11, #12]
        LDR R10, =0x43
        STR R10, [R11, #16]
        LDR R10, =0xb5
        STR R10, [R11, #20]
        LDR R10, =0xf1
        STR R10, [R11, #24]
        LDR R10, =0x37
        STR R10, [R11, #28]
        LDR R10, =0x44
        STR R10, [R11, #32]
        LDR R10, =0x96
        STR R10, [R11, #36]
        LDR R10, =0x73
        STR R10, [R11, #40]
        LDR R10, =0xee
        STR R10, [R11, #44]
        LDR R10, =0xe5
        STR R10, [R11, #48]
        LDR R10, =0x4c
        STR R10, [R11, #52]
        LDR R10, =0xb
        STR R10, [R11, #56]
        LDR R10, =0xf5
        STR R10, [R11, #60]
        LDR R10, =0x47
        STR R10, [R11, #64]
        LDR R10, =0x7
        STR R10, [R11, #68]
        LDR R10, =0xb2
        STR R10, [R11, #72]
        LDR R10, =0x82
        STR R10, [R11, #76]
        LDR R10, =0xb5
        STR R10, [R11, #80]
        LDR R10, =0xa1
        STR R10, [R11, #84]
        LDR R10, =0x37
        STR R10, [R11, #88]
        LDR R10, =0x78
        STR R10, [R11, #92]
        LDR R10, =0x96
        STR R10, [R11, #96]
        LDR R10, =0xa2
        STR R10, [R11, #100]
        LDR R10, =0xee
        STR R10, [R11, #104]
        LDR R10, =0xb9
        STR R10, [R11, #108]
        LDR R10, =0x4c
        STR R10, [R11, #112]
        LDR R10, =0xf2
        STR R10, [R11, #116]
        LDR R10, =0xf5
        STR R10, [R11, #120]
        LDR R10, =0x85
        STR R10, [R11, #124]
        LDR R10, =0x7
        STR R10, [R11, #128]
        LDR R10, =0x23
        STR R10, [R11, #132]
        LDR R10, =0x82
        STR R10, [R11, #136]
        LDR R10, =0xd9
        STR R10, [R11, #140]

        LDR R11,=0x20000100

        LDR R10, =0x8
        STR R10, [R11, #0]
        LDR R10, =0x64
        STR R10, [R11, #4]
        LDR R10, =0x86
        STR R10, [R11, #8]
        LDR R10, =0x6b
        STR R10, [R11, #12]
        LDR R10, =0xe2
        STR R10, [R11, #16]
        LDR R10, =0x6f
        STR R10, [R11, #20]
        LDR R10, =0x89
        STR R10, [R11, #24]
        LDR R10, =0x2c
        STR R10, [R11, #28]
        LDR R10, =0xe6
        STR R10, [R11, #32]
        LDR R10, =0xdd
        STR R10, [R11, #36]
        LDR R10, =0xca
        STR R10, [R11, #40]
        LDR R10, =0x99
        STR R10, [R11, #44]
        LDR R10, =0x17
        STR R10, [R11, #48]
        LDR R10, =0xea
        STR R10, [R11, #52]
        LDR R10, =0x8e
        STR R10, [R11, #56]
        LDR R10, =0x0f
        STR R10, [R11, #60]
        LDR R10, =0x64
        STR R10, [R11, #64]
        LDR R10, =0x4
        STR R10, [R11, #68]
        LDR R10, =0x6b
        STR R10, [R11, #72]
        LDR R10, =0x43
        STR R10, [R11, #76]
        LDR R10, =0x6f
        STR R10, [R11, #80]
        LDR R10, =0xf1
        STR R10, [R11, #84]
        LDR R10, =0x2c
        STR R10, [R11, #88]
        LDR R10, =0x44
        STR R10, [R11, #92]
        LDR R10, =0xdd
        STR R10, [R11, #96]
        LDR R10, =0x73
        STR R10, [R11, #100]
        LDR R10, =0x99
        STR R10, [R11, #104]
        LDR R10, =0xe5
        STR R10, [R11, #108]
        LDR R10, =0xea
        STR R10, [R11, #112]
        LDR R10, =0x0b
        STR R10, [R11, #116]
        LDR R10, =0x0f
        STR R10, [R11, #120]
        LDR R10, =0x47
        STR R10, [R11, #124]
        LDR R10, =0x4
        STR R10, [R11, #128]
        LDR R10, =0xb2
        STR R10, [R11, #132]
        LDR R10, =0x43
        STR R10, [R11, #136]
        LDR R10, =0xb5
        STR R10, [R11, #140]
       
        
        POP {R9, R10, R11}

;; finished inilitiazation


;;store KEY and Nonce:--------    location: 20000400
        LDR R11,=0x20000400
        
        LDR R10, =0x00000000    ;k0
        STR R10, [R11, #0]
        LDR R10, =0x00000000
        STR R10, [R11, #4]  
        
        LDR R10, =0x00000000     ;k1
        STR R10, [R11, #8]
        LDR R10, =0x00000000
        STR R10, [R11, #12]
        
        LDR R10, =0x00000000    ;N0
        STR R10, [R11, #24]
        LDR R10, =0x00000000
        STR R10, [R11, #28]

        LDR R10, =0x00000000     ;;N1
        STR R10, [R11, #32]
        LDR R10, =0x00000000
        STR R10, [R11, #36]
        
;;finished store KEY and Nonice:--------- 


;;store Ms:--------         location: 20000600
        LDR R11,=0x20000600
        
        LDR R10, =0x00000000    ;M0
        STR R10, [R11, #0]
        LDR R10, =0x00000000
        STR R10, [R11, #4]
        
        LDR R10, =0x00000000    ;M1
        STR R10, [R11, #8]
        LDR R10, =0x00000000
        STR R10, [R11, #12] 

;;finished store Ms:---------




;; load initial values
        LDR R11,=0x20000400
       
        LDR R7, =0x00000000    ;;load Nonce 0
        LDR R6, =0x00000000   
        
        LDR R5, =0x00000000 ;;load key0
        LDR R4, =0x00000000
        
        LDR R3, =0x00000000  ;;load Nonce 1
        LDR R2, =0x00000000     
        
        LDR R1, =0x00000000;;loaf key1      
        LDR R0, =0x00000000  
        

        ;;Text zone
        ;;TEST zone end
        BL FFUNAE


main    B       main ;; Program finished, LOOP


;;this is the mode 
FFUNAE
        PUSH {LR}
        LDR R11,=18   ;; u = 18
        BL FFUN3
        BL FFUNKEY
        BL FFUNM
        BL FFUNKEY

        
        POP {LR}
        BX lr

;;this is the key absorption part in the mode
FFUNKEY
        PUSH {LR}
        
        LDR R11,=0x20000400        
        LDR R9, [R11, #0]      ;;xor with key 0 
        LDR R8, [R11, #4]         
        EOR R5, R5, R9
        EOR R1, R1, R8
        EOR R0, R0, #0x00000000

        LDR R11,=18   ;; u = 18
        BL FFUN3
        
        LDR R11,=0x20000400        
        LDR R9, [R11, #8]      ;;xor with key 1
        LDR R8, [R11, #12]         ;;C[7]-C[4]       
        EOR R5, R5, R9
        EOR R1, R1, R8
        EOR R0, R0, #0x00000000

        LDR R11,=18   ;; u = 18
        BL FFUN3

        POP {LR}
        BX lr
        
     
        
;;this is the message absorption part in the mode         
FFUNM
        PUSH {LR}

        LDR R12,=0
        LDR R10,=16   ;; S = 16
WHILE8  CMP R12,R10
        BGE NEXT8
             
        LDR R11,=0x20000600        
        LDR R9, [R11, #0]      ;;xor with key 1
        LDR R8, [R11, #4]         ;;C[7]-C[4]       
        EOR R5, R5, R9
        EOR R1, R1, R8
        EOR R0, R0, #0x00000002

        LDR R11,=9   ;; u = 9
        BL FFUN3
     
        ADD R12, R12, #1
        B WHILE8
NEXT8 

        POP {LR}
        BX lr
        


;;this is permutation box        
FFUN3   ;;LOOP the sliscp-light ;;pass [R7, R6], [R5, R4], [R3, R2], [R1, R0], and data stored at 20000000-200000xx and 20000100-200001xx
        PUSH {R9, R10, LR}
        LDR R9,=0x20000000
        LDR R10, =0x00    ;record the offset; used in FFUN2 and FFUN3
        STR R10, [R9, #160]
        
        LDR R10,=0
WHILE2  CMP R10,R11
        BGE NEXT2
        BL FFUN2
        ADD R10, R10, #1
        B WHILE2
NEXT2   
        POP {R9, R10, LR}
        BX lr
        
;;this is permutation round
FFUN2   ;;pass [R7, R6], [R5, R4], [R3, R2], [R1, R0], and data stored at 20000000-200000xx and 20000100-200001xx
        PUSH {R8, R9, R10, R11, R12, LR}

        LDR R11,=0x20000000
        LDR R10, [R11, #160] ;;load the counter from 20..100 + #160
        LDR R12, [R11, R10] ;R12 stores the t
        BL FFUN ;;finish the h on the left side
        
        LDR R11,=0x20000100
        LDR R9, [R11, R10]
        EOR R7, R7, #0xFFFFFFFF
        ORR R9, R9, #0xFFFFFF00
        EOR R6, R6, R9 ;;R7 and R6 finished EOR with SC
 
        ADD R10, R10, #4 ;;then operate the right handside
        
        LDR R9, [R11, R10]
        EOR R3, R3, #0xFFFFFFFF
        ORR R9, R9, #0xFFFFFF00
        EOR R2, R2, R9 ;;R3 and R2 finished EOR with SC        
        
        LDR R11,=0x20000000
        LDR R12, [R11, R10] ;R12 stores the t
        MOV R9, R5
        MOV R8, R4
        MOV R5, R1
        MOV R4, R0
        BL FFUN ;;finish the h on the left side
        
        ADD R10, R10, #4 ;;then store the value to counter       
        STR R10, [R11, #160] ;save the counter foe the next run FUNN2
        
        EOR R7,R7,R9
        EOR R6,R6,R8
        EOR R3,R3,R5
        EOR R2,R2,R4
        
        MOV R1,R7
        MOV R0,R6
        MOV R7,R9
        MOV R6,R8
        
        MOV R9,R5  ;;Swap two values
        MOV R8,R4
        MOV R5,R3
        MOV R4,R2
        MOV R3,R9
        MOV R2,R8
        
        POP {R8, R9, R10, R11, R12, LR}        
        BX lr
        
        
;;this is Simeck box
FFUN    ;;Make Round for the siemckR, pass R4, R5, R12, where R12 is the "rc" 
        PUSH {R10, R11, LR}
        LDR R10,=0
        LDR R11,=8   ;; u = 8
WHILE   CMP R10,R11
        BGE NEXT1
        BL SimeckR
        ADD R10, R10, #1
        B WHILE
NEXT1   
        POP {R10, R11, LR}
        BX lr
;;funn end


;; this is Simeck round
SimeckR     ;;PASS R5, R4, R12 in, where R12 is the "rc"
        PUSH {R8,R9,LR}
        ROR R8, R5, #27  ;;=32-5 a
        AND R8, R8, R5  ;;32-0
        ROR R9, R5, #31 ;;=32-1
        EOR R8, R8, R9 ;;pass the value from left side to right of the figure 1
        EOR R8, R8, R4 ;;wait to EOR rc
        MOV R4, R5
        
        ;LDR R9, =0x1  ;;redefine R9, try to get 111..11x where x is the last bit of R12
        ;AND R9, R9, R12 ; Then R9 = 0000...000X in bit
        ;ORR R9, R9, #0xFFFFFFFE ;;Then R9 = 111...11X in bit
        ORR R9, R12, #0xFFFFFFFE ;;Correct?
        EOR R5, R8, R9 ;finish the one round
        LSR R12, r12, #1
        POP {R8,R9,LR}       
        BX lr                ; Return from subroutine

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
