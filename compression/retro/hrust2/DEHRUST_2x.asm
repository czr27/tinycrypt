;                 +--------------------+
;                 :Hrust Library v2.03 :
;   DEHRUST       : (C) Dmitry Pyankov :
;                 :   hrumer@mail.ru   :
;                 :      23.07.99      :
;                 +--------------------+
;HL - FROM, DE - TO
;Нерелоцируемый!
;
;+SLAC    Spectre
;+POP AF  Alone Coder
;-EXA     Spectre

;        ORG #6000

DEHRUST INC HL
        INC HL
        INC HL ;SKIP "HR2"
        LD A,(HL)
        INC HL
        PUSH DE
        LD C,(HL)
        INC HL
        LD B,(HL)
        INC HL
        DEC BC

        EX DE,HL
        ADD HL,BC
        EX DE,HL

        LD C,(HL)
        INC HL
        LD B,(HL)
        ADD HL,BC

        SBC HL,DE
        ADD HL,DE
        JR C,$+4
        LD D,H
        LD E,L
        PUSH BC
        LDDR 
        POP BC

        EX DE,HL
        RLA 
        JR NC,DPCYES
        POP DE
        INC HL
        LDIR 
        RET 

DPCYES  LD DE,7
        ADD HL,DE

        PUSH HL
        EXX 
        POP HL
        POP DE

        LD B,6
        DEC HL
        LD A,(HL)
        PUSH AF
        INC SP
        DJNZ $-4

        EXX 
        LD DE,#1003
        LD C,#80

DPC1    LD A,(HL)
        INC HL
        EXX 
        LD (DE),A
        INC DE
DPC0    EXX 
DPC0A
        CALL SLAC
        JR C,DPC1

        LD B,#01
DPC4    LD A,%01000000
DPC2
        CALL SLAC
        RLA 
        JR NC,DPC2

        CP E ;3
        JR C,DPC3
        ADD A,B
        LD B,A
        XOR D ;#10
        JR NZ,DPC4
DPC3    ADD A,B
        CP 4
        JR Z,DPC5 ;B<>1;B=4
        ADC A,#FF
DPC8A   CP 2
DPC8    EXX 
        LD C,A
        LD H,#FF
        EXX 
        JR C,DPC9 ;B=1

        JR Z,DPC12

        CALL SLAC
        JR C,DPC12

        ;B>=4
        LD A,%01111111
        LD B,E ;3
        DJNZ DPC9A1 ;JR...B=2
DPC9A2  DJNZ DPC5A2
        LD B,A
        SBC A,A

DPC9B   CALL SLAC
        RLA 
        DEC A
        INC B
        JR NZ,DPC9B
        CP #FF-30
        JR NZ,$+4
        LD A,(HL)
        INC HL

        EXX 
        LD H,A
        EXX 

DPC12   LD A,(HL)
        INC HL
DPC11   EXX 
        LD L,A
        ADD HL,DE
        LDIR 
        JR DPC0

DPC5A2  ADD A,6
        RLA 
        LD B,A
DPC5C   LD A,(HL)
        INC HL
        EXX 
        LD (DE),A
        INC DE
        EXX 
        DJNZ DPC5C
        JR DPC0A

DPC5    ;B=4
        CALL SLAC
        LD A,D ;%00010000
        JR NC,DPC5A1

        LD A,(HL)
        INC HL
        CP D ;16
        JR NC,DPC8A
        OR A
        JR Z,DPC6

        EXX 
        LD B,A
        EXX 
        LD A,(HL)
        INC HL
        JR DPC8

DPC9    ;B=1
        LD A,%00111111
DPC5A1  ;B=4
DPC9A1  ;B=2
DPC10   CALL SLAC
        RLA 
        JR NC,DPC10
        DJNZ DPC9A2
        JR DPC11

SLAC    SLA C
        RET NZ
        LD C,(HL)
        INC HL
        RL C
        RET 

DPC6    ;LD HL,#2758
        EXX 
        LD B,6
        DEC SP
        POP AF
        LD (DE),A
        INC DE
        DJNZ $-4
        RET 

        DISPLAY "LENGHT: ",$-DEHRUST