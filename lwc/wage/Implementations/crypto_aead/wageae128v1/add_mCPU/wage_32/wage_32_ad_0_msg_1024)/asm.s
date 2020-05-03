/* Reference implementation of WAGE32_(l_ad=0, l_m=16)
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


        PUSH {R10, R11}

;;Pre-save VECTOR 1:________  WG
        LDR R11,=0x20000000
        ADD R11, R11, #0x1000
                
        LDR R10, =0x00
        STR R10, [R11, #0]
        LDR R10, =0x12
        STR R10, [R11, #4]
        LDR R10, =0x0A
        STR R10, [R11, #8]
        LDR R10, =0x4B
        STR R10, [R11, #12]
        LDR R10, =0x66
        STR R10, [R11, #16]
        LDR R10, =0x0C
        STR R10, [R11, #20]
        LDR R10, =0x48
        STR R10, [R11, #24]
        LDR R10, =0x73
        STR R10, [R11, #28]
        LDR R10, =0x79
        STR R10, [R11, #32]
        LDR R10, =0x3E
        STR R10, [R11, #36]
        LDR R10, =0x61
        STR R10, [R11, #40]
        LDR R10, =0x51
        STR R10, [R11, #44]
        LDR R10, =0x01
        STR R10, [R11, #48]
        LDR R10, =0x15
        STR R10, [R11, #52]
        LDR R10, =0x17
        STR R10, [R11, #56]
        LDR R10, =0x0E
        STR R10, [R11, #60]
        LDR R10, =0x7E
        STR R10, [R11, #64]
        LDR R10, =0x33
        STR R10, [R11, #68]
        LDR R10, =0x68
        STR R10, [R11, #72]
        LDR R10, =0x36
        STR R10, [R11, #76]
        LDR R10, =0x42
        STR R10, [R11, #80]
        LDR R10, =0x35
        STR R10, [R11, #84]
        LDR R10, =0x37
        STR R10, [R11, #88]
        LDR R10, =0x5E
        STR R10, [R11, #92]
        LDR R10, =0x53
        STR R10, [R11, #96]
        LDR R10, =0x4C
        STR R10, [R11, #100]
        LDR R10, =0x3F
        STR R10, [R11, #104]
        LDR R10, =0x54
        STR R10, [R11, #108]
        LDR R10, =0x58
        STR R10, [R11, #112]
        LDR R10, =0x6E
        STR R10, [R11, #116]
        LDR R10, =0x56
        STR R10, [R11, #120]
        LDR R10, =0x2A
        STR R10, [R11, #124]
        LDR R10, =0x1D
        STR R10, [R11, #128]
        LDR R10, =0x25
        STR R10, [R11, #132]
        LDR R10, =0x6D
        STR R10, [R11, #136]
        LDR R10, =0x65
        STR R10, [R11, #140]
        LDR R10, =0x5B
        STR R10, [R11, #144]
        LDR R10, =0x71
        STR R10, [R11, #148]
        LDR R10, =0x2F
        STR R10, [R11, #152]
        LDR R10, =0x20
        STR R10, [R11, #156]
        LDR R10, =0x06
        STR R10, [R11, #160]
        LDR R10, =0x18
        STR R10, [R11, #164]
        LDR R10, =0x29
        STR R10, [R11, #168]
        LDR R10, =0x3A
        STR R10, [R11, #172]
        LDR R10, =0x0D
        STR R10, [R11, #176]
        LDR R10, =0x7A
        STR R10, [R11, #180]
        LDR R10, =0x6C
        STR R10, [R11, #184]
        LDR R10, =0x1B
        STR R10, [R11, #188]
        LDR R10, =0x19
        STR R10, [R11, #192]
        LDR R10, =0x43
        STR R10, [R11, #196]
        LDR R10, =0x70
        STR R10, [R11, #200]
        LDR R10, =0x41
        STR R10, [R11, #204]
        LDR R10, =0x49
        STR R10, [R11, #208]
        LDR R10, =0x22
        STR R10, [R11, #212]
        LDR R10, =0x77
        STR R10, [R11, #216]
        LDR R10, =0x60
        STR R10, [R11, #220]
        LDR R10, =0x4F
        STR R10, [R11, #224]
        LDR R10, =0x45
        STR R10, [R11, #228]
        LDR R10, =0x55
        STR R10, [R11, #232]
        LDR R10, =0x02
        STR R10, [R11, #236]
        LDR R10, =0x63
        STR R10, [R11, #240]
        LDR R10, =0x47
        STR R10, [R11, #244]
        LDR R10, =0x75
        STR R10, [R11, #248]
        LDR R10, =0x2D
        STR R10, [R11, #252]
        LDR R10, =0x40
        STR R10, [R11, #256]
        LDR R10, =0x46
        STR R10, [R11, #260]
        LDR R10, =0x7D
        STR R10, [R11, #264]
        LDR R10, =0x5C
        STR R10, [R11, #268]
        LDR R10, =0x7C
        STR R10, [R11, #272]
        LDR R10, =0x59
        STR R10, [R11, #276]
        LDR R10, =0x26
        STR R10, [R11, #280]
        LDR R10, =0x0B
        STR R10, [R11, #284]
        LDR R10, =0x09
        STR R10, [R11, #288]
        LDR R10, =0x03
        STR R10, [R11, #292]
        LDR R10, =0x57
        STR R10, [R11, #296]
        LDR R10, =0x5D
        STR R10, [R11, #300]
        LDR R10, =0x27
        STR R10, [R11, #304]
        LDR R10, =0x78
        STR R10, [R11, #308]
        LDR R10, =0x30
        STR R10, [R11, #312]
        LDR R10, =0x2E
        STR R10, [R11, #316]
        LDR R10, =0x44
        STR R10, [R11, #320]
        LDR R10, =0x52
        STR R10, [R11, #324]
        LDR R10, =0x3B
        STR R10, [R11, #328]
        LDR R10, =0x08
        STR R10, [R11, #332]
        LDR R10, =0x67
        STR R10, [R11, #336]
        LDR R10, =0x2C
        STR R10, [R11, #340]
        LDR R10, =0x05
        STR R10, [R11, #344]
        LDR R10, =0x6B
        STR R10, [R11, #348]
        LDR R10, =0x2B
        STR R10, [R11, #352]
        LDR R10, =0x1A
        STR R10, [R11, #356]
        LDR R10, =0x21
        STR R10, [R11, #360]
        LDR R10, =0x38
        STR R10, [R11, #364]
        LDR R10, =0x07
        STR R10, [R11, #368]
        LDR R10, =0x0F
        STR R10, [R11, #372]
        LDR R10, =0x4A
        STR R10, [R11, #376]
        LDR R10, =0x11
        STR R10, [R11, #380]
        LDR R10, =0x50
        STR R10, [R11, #384]
        LDR R10, =0x6A
        STR R10, [R11, #388]
        LDR R10, =0x28
        STR R10, [R11, #392]
        LDR R10, =0x31
        STR R10, [R11, #396]
        LDR R10, =0x10
        STR R10, [R11, #400]
        LDR R10, =0x4D
        STR R10, [R11, #404]
        LDR R10, =0x5F
        STR R10, [R11, #408]
        LDR R10, =0x72
        STR R10, [R11, #412]
        LDR R10, =0x39
        STR R10, [R11, #416]
        LDR R10, =0x16
        STR R10, [R11, #420]
        LDR R10, =0x5A
        STR R10, [R11, #424]
        LDR R10, =0x13
        STR R10, [R11, #428]
        LDR R10, =0x04
        STR R10, [R11, #432]
        LDR R10, =0x3C
        STR R10, [R11, #436]
        LDR R10, =0x34
        STR R10, [R11, #440]
        LDR R10, =0x1F
        STR R10, [R11, #444]
        LDR R10, =0x76
        STR R10, [R11, #448]
        LDR R10, =0x1E
        STR R10, [R11, #452]
        LDR R10, =0x14
        STR R10, [R11, #456]
        LDR R10, =0x23
        STR R10, [R11, #460]
        LDR R10, =0x1C
        STR R10, [R11, #464]
        LDR R10, =0x32
        STR R10, [R11, #468]
        LDR R10, =0x4E
        STR R10, [R11, #472]
        LDR R10, =0x7B
        STR R10, [R11, #476]
        LDR R10, =0x24
        STR R10, [R11, #480]
        LDR R10, =0x74
        STR R10, [R11, #484]
        LDR R10, =0x7F
        STR R10, [R11, #488]
        LDR R10, =0x3D
        STR R10, [R11, #492]
        LDR R10, =0x69
        STR R10, [R11, #496]
        LDR R10, =0x64
        STR R10, [R11, #500]
        LDR R10, =0x62
        STR R10, [R11, #504]
        LDR R10, =0x6F
        STR R10, [R11, #508]
      
        
;;Pre-save VECTOR 2:________  r           
        LDR R11,=0x20000000
        ADD R11, R11, #0x2000
                
        LDR R10, =0x00
        STR R10, [R11, #0]
        LDR R10, =0x78
        STR R10, [R11, #4]
        LDR R10, =0x01
        STR R10, [R11, #8]
        LDR R10, =0x79
        STR R10, [R11, #12]
        LDR R10, =0x02
        STR R10, [R11, #16]
        LDR R10, =0x7A
        STR R10, [R11, #20]
        LDR R10, =0x03
        STR R10, [R11, #24]
        LDR R10, =0x7B
        STR R10, [R11, #28]
        LDR R10, =0x04
        STR R10, [R11, #32]
        LDR R10, =0x7C
        STR R10, [R11, #36]
        LDR R10, =0x05
        STR R10, [R11, #40]
        LDR R10, =0x7D
        STR R10, [R11, #44]
        LDR R10, =0x06
        STR R10, [R11, #48]
        LDR R10, =0x7E
        STR R10, [R11, #52]
        LDR R10, =0x07
        STR R10, [R11, #56]
        LDR R10, =0x7F
        STR R10, [R11, #60]
        LDR R10, =0x08
        STR R10, [R11, #64]
        LDR R10, =0x70
        STR R10, [R11, #68]
        LDR R10, =0x09
        STR R10, [R11, #72]
        LDR R10, =0x71
        STR R10, [R11, #76]
        LDR R10, =0x0A
        STR R10, [R11, #80]
        LDR R10, =0x72
        STR R10, [R11, #84]
        LDR R10, =0x0B
        STR R10, [R11, #88]
        LDR R10, =0x73
        STR R10, [R11, #92]
        LDR R10, =0x0C
        STR R10, [R11, #96]
        LDR R10, =0x74
        STR R10, [R11, #100]
        LDR R10, =0x0D
        STR R10, [R11, #104]
        LDR R10, =0x75
        STR R10, [R11, #108]
        LDR R10, =0x0E
        STR R10, [R11, #112]
        LDR R10, =0x76
        STR R10, [R11, #116]
        LDR R10, =0x0F
        STR R10, [R11, #120]
        LDR R10, =0x77
        STR R10, [R11, #124]
        LDR R10, =0x10
        STR R10, [R11, #128]
        LDR R10, =0x68
        STR R10, [R11, #132]
        LDR R10, =0x11
        STR R10, [R11, #136]
        LDR R10, =0x69
        STR R10, [R11, #140]
        LDR R10, =0x12
        STR R10, [R11, #144]
        LDR R10, =0x6A
        STR R10, [R11, #148]
        LDR R10, =0x13
        STR R10, [R11, #152]
        LDR R10, =0x6B
        STR R10, [R11, #156]
        LDR R10, =0x14
        STR R10, [R11, #160]
        LDR R10, =0x6C
        STR R10, [R11, #164]
        LDR R10, =0x15
        STR R10, [R11, #168]
        LDR R10, =0x6D
        STR R10, [R11, #172]
        LDR R10, =0x16
        STR R10, [R11, #176]
        LDR R10, =0x6E
        STR R10, [R11, #180]
        LDR R10, =0x17
        STR R10, [R11, #184]
        LDR R10, =0x6F
        STR R10, [R11, #188]
        LDR R10, =0x18
        STR R10, [R11, #192]
        LDR R10, =0x60
        STR R10, [R11, #196]
        LDR R10, =0x19
        STR R10, [R11, #200]
        LDR R10, =0x61
        STR R10, [R11, #204]
        LDR R10, =0x1A
        STR R10, [R11, #208]
        LDR R10, =0x62
        STR R10, [R11, #212]
        LDR R10, =0x1B
        STR R10, [R11, #216]
        LDR R10, =0x63
        STR R10, [R11, #220]
        LDR R10, =0x1C
        STR R10, [R11, #224]
        LDR R10, =0x64
        STR R10, [R11, #228]
        LDR R10, =0x1D
        STR R10, [R11, #232]
        LDR R10, =0x65
        STR R10, [R11, #236]
        LDR R10, =0x1E
        STR R10, [R11, #240]
        LDR R10, =0x66
        STR R10, [R11, #244]
        LDR R10, =0x1F
        STR R10, [R11, #248]
        LDR R10, =0x67
        STR R10, [R11, #252]
        LDR R10, =0x20
        STR R10, [R11, #256]
        LDR R10, =0x58
        STR R10, [R11, #260]
        LDR R10, =0x21
        STR R10, [R11, #264]
        LDR R10, =0x59
        STR R10, [R11, #268]
        LDR R10, =0x22
        STR R10, [R11, #272]
        LDR R10, =0x5A
        STR R10, [R11, #276]
        LDR R10, =0x23
        STR R10, [R11, #280]
        LDR R10, =0x5B
        STR R10, [R11, #284]
        LDR R10, =0x24
        STR R10, [R11, #288]
        LDR R10, =0x5C
        STR R10, [R11, #292]
        LDR R10, =0x25
        STR R10, [R11, #296]
        LDR R10, =0x5D
        STR R10, [R11, #300]
        LDR R10, =0x26
        STR R10, [R11, #304]
        LDR R10, =0x5E
        STR R10, [R11, #308]
        LDR R10, =0x27
        STR R10, [R11, #312]
        LDR R10, =0x5F
        STR R10, [R11, #316]
        LDR R10, =0x28
        STR R10, [R11, #320]
        LDR R10, =0x50
        STR R10, [R11, #324]
        LDR R10, =0x29
        STR R10, [R11, #328]
        LDR R10, =0x51
        STR R10, [R11, #332]
        LDR R10, =0x2A
        STR R10, [R11, #336]
        LDR R10, =0x52
        STR R10, [R11, #340]
        LDR R10, =0x2B
        STR R10, [R11, #344]
        LDR R10, =0x53
        STR R10, [R11, #348]
        LDR R10, =0x2C
        STR R10, [R11, #352]
        LDR R10, =0x54
        STR R10, [R11, #356]
        LDR R10, =0x2D
        STR R10, [R11, #360]
        LDR R10, =0x55
        STR R10, [R11, #364]
        LDR R10, =0x2E
        STR R10, [R11, #368]
        LDR R10, =0x56
        STR R10, [R11, #372]
        LDR R10, =0x2F
        STR R10, [R11, #376]
        LDR R10, =0x57
        STR R10, [R11, #380]
        LDR R10, =0x30
        STR R10, [R11, #384]
        LDR R10, =0x48
        STR R10, [R11, #388]
        LDR R10, =0x31
        STR R10, [R11, #392]
        LDR R10, =0x49
        STR R10, [R11, #396]
        LDR R10, =0x32
        STR R10, [R11, #400]
        LDR R10, =0x4A
        STR R10, [R11, #404]
        LDR R10, =0x33
        STR R10, [R11, #408]
        LDR R10, =0x4B
        STR R10, [R11, #412]
        LDR R10, =0x34
        STR R10, [R11, #416]
        LDR R10, =0x4C
        STR R10, [R11, #420]
        LDR R10, =0x35
        STR R10, [R11, #424]
        LDR R10, =0x4D
        STR R10, [R11, #428]
        LDR R10, =0x36
        STR R10, [R11, #432]
        LDR R10, =0x4E
        STR R10, [R11, #436]
        LDR R10, =0x37
        STR R10, [R11, #440]
        LDR R10, =0x4F
        STR R10, [R11, #444]
        LDR R10, =0x38
        STR R10, [R11, #448]
        LDR R10, =0x40
        STR R10, [R11, #452]
        LDR R10, =0x39
        STR R10, [R11, #456]
        LDR R10, =0x41
        STR R10, [R11, #460]
        LDR R10, =0x3A
        STR R10, [R11, #464]
        LDR R10, =0x42
        STR R10, [R11, #468]
        LDR R10, =0x3B
        STR R10, [R11, #472]
        LDR R10, =0x43
        STR R10, [R11, #476]
        LDR R10, =0x3C
        STR R10, [R11, #480]
        LDR R10, =0x44
        STR R10, [R11, #484]
        LDR R10, =0x3D
        STR R10, [R11, #488]
        LDR R10, =0x45
        STR R10, [R11, #492]
        LDR R10, =0x3E
        STR R10, [R11, #496]
        LDR R10, =0x46
        STR R10, [R11, #500]
        LDR R10, =0x3F
        STR R10, [R11, #504]
        LDR R10, =0x47
        STR R10, [R11, #508]
        
;;Pre-save VECTOR 3:________ s-box
        LDR R11,=0x20000000
        ADD R11, R11, #0x3000
        
        LDR R10, =0x2E
        STR R10, [R11, #0]
        LDR R10, =0x1C
        STR R10, [R11, #4]
        LDR R10, =0x6D
        STR R10, [R11, #8]
        LDR R10, =0x2B
        STR R10, [R11, #12]
        LDR R10, =0x35
        STR R10, [R11, #16]
        LDR R10, =0x07
        STR R10, [R11, #20]
        LDR R10, =0x7F
        STR R10, [R11, #24]
        LDR R10, =0x3B
        STR R10, [R11, #28]
        LDR R10, =0x28
        STR R10, [R11, #32]
        LDR R10, =0x08
        STR R10, [R11, #36]
        LDR R10, =0x0B
        STR R10, [R11, #40]
        LDR R10, =0x5F
        STR R10, [R11, #44]
        LDR R10, =0x31
        STR R10, [R11, #48]
        LDR R10, =0x11
        STR R10, [R11, #52]
        LDR R10, =0x1B
        STR R10, [R11, #56]
        LDR R10, =0x4D
        STR R10, [R11, #60]
        LDR R10, =0x6E
        STR R10, [R11, #64]
        LDR R10, =0x54
        STR R10, [R11, #68]
        LDR R10, =0x0D
        STR R10, [R11, #72]
        LDR R10, =0x09
        STR R10, [R11, #76]
        LDR R10, =0x1F
        STR R10, [R11, #80]
        LDR R10, =0x45
        STR R10, [R11, #84]
        LDR R10, =0x75
        STR R10, [R11, #88]
        LDR R10, =0x53
        STR R10, [R11, #92]
        LDR R10, =0x6A
        STR R10, [R11, #96]
        LDR R10, =0x5D
        STR R10, [R11, #100]
        LDR R10, =0x61
        STR R10, [R11, #104]
        LDR R10, =0x00
        STR R10, [R11, #108]
        LDR R10, =0x04
        STR R10, [R11, #112]
        LDR R10, =0x78
        STR R10, [R11, #116]
        LDR R10, =0x06
        STR R10, [R11, #120]
        LDR R10, =0x1E
        STR R10, [R11, #124]
        LDR R10, =0x37
        STR R10, [R11, #128]
        LDR R10, =0x6F
        STR R10, [R11, #132]
        LDR R10, =0x2F
        STR R10, [R11, #136]
        LDR R10, =0x49
        STR R10, [R11, #140]
        LDR R10, =0x64
        STR R10, [R11, #144]
        LDR R10, =0x34
        STR R10, [R11, #148]
        LDR R10, =0x7D
        STR R10, [R11, #152]
        LDR R10, =0x19
        STR R10, [R11, #156]
        LDR R10, =0x39
        STR R10, [R11, #160]
        LDR R10, =0x33
        STR R10, [R11, #164]
        LDR R10, =0x43
        STR R10, [R11, #168]
        LDR R10, =0x57
        STR R10, [R11, #172]
        LDR R10, =0x60
        STR R10, [R11, #176]
        LDR R10, =0x62
        STR R10, [R11, #180]
        LDR R10, =0x13
        STR R10, [R11, #184]
        LDR R10, =0x05
        STR R10, [R11, #188]
        LDR R10, =0x77
        STR R10, [R11, #192]
        LDR R10, =0x47
        STR R10, [R11, #196]
        LDR R10, =0x4F
        STR R10, [R11, #200]
        LDR R10, =0x4B
        STR R10, [R11, #204]
        LDR R10, =0x1D
        STR R10, [R11, #208]
        LDR R10, =0x2D
        STR R10, [R11, #212]
        LDR R10, =0x24
        STR R10, [R11, #216]
        LDR R10, =0x48
        STR R10, [R11, #220]
        LDR R10, =0x74
        STR R10, [R11, #224]
        LDR R10, =0x58
        STR R10, [R11, #228]
        LDR R10, =0x25
        STR R10, [R11, #232]
        LDR R10, =0x5E
        STR R10, [R11, #236]
        LDR R10, =0x5A
        STR R10, [R11, #240]
        LDR R10, =0x76
        STR R10, [R11, #244]
        LDR R10, =0x41
        STR R10, [R11, #248]
        LDR R10, =0x42
        STR R10, [R11, #252]
        LDR R10, =0x27
        STR R10, [R11, #256]
        LDR R10, =0x3E
        STR R10, [R11, #260]
        LDR R10, =0x6C
        STR R10, [R11, #264]
        LDR R10, =0x01
        STR R10, [R11, #268]
        LDR R10, =0x2C
        STR R10, [R11, #272]
        LDR R10, =0x3C
        STR R10, [R11, #276]
        LDR R10, =0x4E
        STR R10, [R11, #280]
        LDR R10, =0x1A
        STR R10, [R11, #284]
        LDR R10, =0x21
        STR R10, [R11, #288]
        LDR R10, =0x2A
        STR R10, [R11, #292]
        LDR R10, =0x0A
        STR R10, [R11, #296]
        LDR R10, =0x55
        STR R10, [R11, #300]
        LDR R10, =0x3A
        STR R10, [R11, #304]
        LDR R10, =0x38
        STR R10, [R11, #308]
        LDR R10, =0x18
        STR R10, [R11, #312]
        LDR R10, =0x7E
        STR R10, [R11, #316]
        LDR R10, =0x0C
        STR R10, [R11, #320]
        LDR R10, =0x63
        STR R10, [R11, #324]
        LDR R10, =0x67
        STR R10, [R11, #328]
        LDR R10, =0x56
        STR R10, [R11, #332]
        LDR R10, =0x50
        STR R10, [R11, #336]
        LDR R10, =0x7C
        STR R10, [R11, #340]
        LDR R10, =0x32
        STR R10, [R11, #344]
        LDR R10, =0x7A
        STR R10, [R11, #348]
        LDR R10, =0x68
        STR R10, [R11, #352]
        LDR R10, =0x02
        STR R10, [R11, #356]
        LDR R10, =0x6B
        STR R10, [R11, #360]
        LDR R10, =0x17
        STR R10, [R11, #364]
        LDR R10, =0x7B
        STR R10, [R11, #368]
        LDR R10, =0x59
        STR R10, [R11, #372]
        LDR R10, =0x71
        STR R10, [R11, #376]
        LDR R10, =0x0F
        STR R10, [R11, #380]
        LDR R10, =0x30
        STR R10, [R11, #384]
        LDR R10, =0x10
        STR R10, [R11, #388]
        LDR R10, =0x22
        STR R10, [R11, #392]
        LDR R10, =0x3D
        STR R10, [R11, #396]
        LDR R10, =0x40
        STR R10, [R11, #400]
        LDR R10, =0x69
        STR R10, [R11, #404]
        LDR R10, =0x52
        STR R10, [R11, #408]
        LDR R10, =0x14
        STR R10, [R11, #412]
        LDR R10, =0x36
        STR R10, [R11, #416]
        LDR R10, =0x44
        STR R10, [R11, #420]
        LDR R10, =0x46
        STR R10, [R11, #424]
        LDR R10, =0x03
        STR R10, [R11, #428]
        LDR R10, =0x16
        STR R10, [R11, #432]
        LDR R10, =0x65
        STR R10, [R11, #436]
        LDR R10, =0x66
        STR R10, [R11, #440]
        LDR R10, =0x72
        STR R10, [R11, #444]
        LDR R10, =0x12
        STR R10, [R11, #448]
        LDR R10, =0x0E
        STR R10, [R11, #452]
        LDR R10, =0x29
        STR R10, [R11, #456]
        LDR R10, =0x4A
        STR R10, [R11, #460]
        LDR R10, =0x4C
        STR R10, [R11, #464]
        LDR R10, =0x70
        STR R10, [R11, #468]
        LDR R10, =0x15
        STR R10, [R11, #472]
        LDR R10, =0x26
        STR R10, [R11, #476]
        LDR R10, =0x79
        STR R10, [R11, #480]
        LDR R10, =0x51
        STR R10, [R11, #484]
        LDR R10, =0x23
        STR R10, [R11, #488]
        LDR R10, =0x3F
        STR R10, [R11, #492]
        LDR R10, =0x73
        STR R10, [R11, #496]
        LDR R10, =0x5B
        STR R10, [R11, #500]
        LDR R10, =0x20
        STR R10, [R11, #504]
        LDR R10, =0x5C
        STR R10, [R11, #508]

;; pre-save RC1 ____________________

        LDR R11,=0x20005000
        
        LDR R10, =0x3F
        STR R10, [R11, #0]
        LDR R10, =0x0F
        STR R10, [R11, #4]
        LDR R10, =0x03
        STR R10, [R11, #8]
        LDR R10, =0x40
        STR R10, [R11, #12]
        LDR R10, =0x10
        STR R10, [R11, #16]
        LDR R10, =0x04
        STR R10, [R11, #20]
        LDR R10, =0x41
        STR R10, [R11, #24]
        LDR R10, =0x30
        STR R10, [R11, #28]
        LDR R10, =0x0C
        STR R10, [R11, #32]
        LDR R10, =0x43
        STR R10, [R11, #36]
        LDR R10, =0x50
        STR R10, [R11, #40]
        LDR R10, =0x14
        STR R10, [R11, #44]
        LDR R10, =0x45
        STR R10, [R11, #48]
        LDR R10, =0x71
        STR R10, [R11, #52]
        LDR R10, =0x3C
        STR R10, [R11, #56]
        LDR R10, =0x4F
        STR R10, [R11, #60]
        LDR R10, =0x13
        STR R10, [R11, #64]
        LDR R10, =0x44
        STR R10, [R11, #68]
        LDR R10, =0x51
        STR R10, [R11, #72]
        LDR R10, =0x34
        STR R10, [R11, #76]
        LDR R10, =0x4D
        STR R10, [R11, #80]
        LDR R10, =0x73
        STR R10, [R11, #84]
        LDR R10, =0x5C
        STR R10, [R11, #88]
        LDR R10, =0x57
        STR R10, [R11, #92]
        LDR R10, =0x15
        STR R10, [R11, #96]
        LDR R10, =0x65
        STR R10, [R11, #100]
        LDR R10, =0x79
        STR R10, [R11, #104]
        LDR R10, =0x3E
        STR R10, [R11, #108]
        LDR R10, =0x2F
        STR R10, [R11, #112]
        LDR R10, =0x0B
        STR R10, [R11, #116]
        LDR R10, =0x42
        STR R10, [R11, #120]
        LDR R10, =0x70
        STR R10, [R11, #124]
        LDR R10, =0x1C
        STR R10, [R11, #128]
        LDR R10, =0x47
        STR R10, [R11, #132]
        LDR R10, =0x11
        STR R10, [R11, #136]
        LDR R10, =0x24
        STR R10, [R11, #140]
        LDR R10, =0x49
        STR R10, [R11, #144]
        LDR R10, =0x32
        STR R10, [R11, #148]
        LDR R10, =0x6C
        STR R10, [R11, #152]
        LDR R10, =0x5B
        STR R10, [R11, #156]
        LDR R10, =0x56
        STR R10, [R11, #160]
        LDR R10, =0x35
        STR R10, [R11, #164]
        LDR R10, =0x6D
        STR R10, [R11, #168]
        LDR R10, =0x7B
        STR R10, [R11, #172]
        LDR R10, =0x5E
        STR R10, [R11, #176]
        LDR R10, =0x37
        STR R10, [R11, #180]
        LDR R10, =0x0D
        STR R10, [R11, #184]
        LDR R10, =0x63
        STR R10, [R11, #188]
        LDR R10, =0x58
        STR R10, [R11, #192]
        LDR R10, =0x16
        STR R10, [R11, #196]
        LDR R10, =0x25
        STR R10, [R11, #200]
        LDR R10, =0x69
        STR R10, [R11, #204]
        LDR R10, =0x3A
        STR R10, [R11, #208]
        LDR R10, =0x6E
        STR R10, [R11, #212]
        LDR R10, =0x3B
        STR R10, [R11, #216]
        LDR R10, =0x4E
        STR R10, [R11, #220]
        LDR R10, =0x33
        STR R10, [R11, #224]
        LDR R10, =0x4C
        STR R10, [R11, #228]
        LDR R10, =0x53
        STR R10, [R11, #232]
        LDR R10, =0x54
        STR R10, [R11, #236]
        LDR R10, =0x55
        STR R10, [R11, #240]
        LDR R10, =0x75
        STR R10, [R11, #244]
        LDR R10, =0x7D
        STR R10, [R11, #248]
        LDR R10, =0x7F
        STR R10, [R11, #252]
        LDR R10, =0x1F
        STR R10, [R11, #256]
        LDR R10, =0x07
        STR R10, [R11, #260]
        LDR R10, =0x01
        STR R10, [R11, #264]
        LDR R10, =0x20
        STR R10, [R11, #268]
        LDR R10, =0x08
        STR R10, [R11, #272]
        LDR R10, =0x02
        STR R10, [R11, #276]
        LDR R10, =0x60
        STR R10, [R11, #280]
        LDR R10, =0x18
        STR R10, [R11, #284]
        LDR R10, =0x06
        STR R10, [R11, #288]
        LDR R10, =0x21
        STR R10, [R11, #292]
        LDR R10, =0x28
        STR R10, [R11, #296]
        LDR R10, =0x0A
        STR R10, [R11, #300]
        LDR R10, =0x62
        STR R10, [R11, #304]
        LDR R10, =0x78
        STR R10, [R11, #308]
        LDR R10, =0x1E
        STR R10, [R11, #312]
        LDR R10, =0x27
        STR R10, [R11, #316]
        LDR R10, =0x09
        STR R10, [R11, #320]
        LDR R10, =0x22
        STR R10, [R11, #324]
        LDR R10, =0x68
        STR R10, [R11, #328]
        LDR R10, =0x1A
        STR R10, [R11, #332]
        LDR R10, =0x66
        STR R10, [R11, #336]
        LDR R10, =0x39
        STR R10, [R11, #340]
        LDR R10, =0x2E
        STR R10, [R11, #344]
        LDR R10, =0x2B
        STR R10, [R11, #348]
        LDR R10, =0x4A
        STR R10, [R11, #352]
        LDR R10, =0x72
        STR R10, [R11, #356]
        LDR R10, =0x7C
        STR R10, [R11, #360]
        LDR R10, =0x5F
        STR R10, [R11, #364]
        LDR R10, =0x17
        STR R10, [R11, #368]
        LDR R10, =0x05
        STR R10, [R11, #372]
        LDR R10, =0x61
        STR R10, [R11, #376]
        LDR R10, =0x38
        STR R10, [R11, #380]
        LDR R10, =0x0E
        STR R10, [R11, #384]
        LDR R10, =0x23
        STR R10, [R11, #388]
        LDR R10, =0x48
        STR R10, [R11, #392]
        LDR R10, =0x12
        STR R10, [R11, #396]
        LDR R10, =0x64
        STR R10, [R11, #400]
        LDR R10, =0x59
        STR R10, [R11, #404]
        LDR R10, =0x36
        STR R10, [R11, #408]
        LDR R10, =0x2D
        STR R10, [R11, #412]
        LDR R10, =0x6B
        STR R10, [R11, #416]
        LDR R10, =0x5A
        STR R10, [R11, #420]
        LDR R10, =0x76
        STR R10, [R11, #424]
        LDR R10, =0x3D
        STR R10, [R11, #428]
        LDR R10, =0x6F
        STR R10, [R11, #432]
        LDR R10, =0x1B
        STR R10, [R11, #436]
        LDR R10, =0x46
        STR R10, [R11, #440]

;;Pre-save RC0:________
        LDR R11,=0x20006000
        
        LDR R10, =0x7F
        STR R10, [R11, #0]
        LDR R10, =0x1F
        STR R10, [R11, #4]
        LDR R10, =0x07
        STR R10, [R11, #8]
        LDR R10, =0x01
        STR R10, [R11, #12]
        LDR R10, =0x20
        STR R10, [R11, #16]
        LDR R10, =0x08
        STR R10, [R11, #20]
        LDR R10, =0x02
        STR R10, [R11, #24]
        LDR R10, =0x60
        STR R10, [R11, #28]
        LDR R10, =0x18
        STR R10, [R11, #32]
        LDR R10, =0x06
        STR R10, [R11, #36]
        LDR R10, =0x21
        STR R10, [R11, #40]
        LDR R10, =0x28
        STR R10, [R11, #44]
        LDR R10, =0x0A
        STR R10, [R11, #48]
        LDR R10, =0x62
        STR R10, [R11, #52]
        LDR R10, =0x78
        STR R10, [R11, #56]
        LDR R10, =0x1E
        STR R10, [R11, #60]
        LDR R10, =0x27
        STR R10, [R11, #64]
        LDR R10, =0x09
        STR R10, [R11, #68]
        LDR R10, =0x22
        STR R10, [R11, #72]
        LDR R10, =0x68
        STR R10, [R11, #76]
        LDR R10, =0x1A
        STR R10, [R11, #80]
        LDR R10, =0x66
        STR R10, [R11, #84]
        LDR R10, =0x39
        STR R10, [R11, #88]
        LDR R10, =0x2E
        STR R10, [R11, #92]
        LDR R10, =0x2B
        STR R10, [R11, #96]
        LDR R10, =0x4A
        STR R10, [R11, #100]
        LDR R10, =0x72
        STR R10, [R11, #104]
        LDR R10, =0x7C
        STR R10, [R11, #108]
        LDR R10, =0x5F
        STR R10, [R11, #112]
        LDR R10, =0x17
        STR R10, [R11, #116]
        LDR R10, =0x05
        STR R10, [R11, #120]
        LDR R10, =0x61
        STR R10, [R11, #124]
        LDR R10, =0x38
        STR R10, [R11, #128]
        LDR R10, =0x0E
        STR R10, [R11, #132]
        LDR R10, =0x23
        STR R10, [R11, #136]
        LDR R10, =0x48
        STR R10, [R11, #140]
        LDR R10, =0x12
        STR R10, [R11, #144]
        LDR R10, =0x64
        STR R10, [R11, #148]
        LDR R10, =0x59
        STR R10, [R11, #152]
        LDR R10, =0x36
        STR R10, [R11, #156]
        LDR R10, =0x2D
        STR R10, [R11, #160]
        LDR R10, =0x6B
        STR R10, [R11, #164]
        LDR R10, =0x5A
        STR R10, [R11, #168]
        LDR R10, =0x76
        STR R10, [R11, #172]
        LDR R10, =0x3D
        STR R10, [R11, #176]
        LDR R10, =0x6F
        STR R10, [R11, #180]
        LDR R10, =0x1B
        STR R10, [R11, #184]
        LDR R10, =0x46
        STR R10, [R11, #188]
        LDR R10, =0x31
        STR R10, [R11, #192]
        LDR R10, =0x2C
        STR R10, [R11, #196]
        LDR R10, =0x4B
        STR R10, [R11, #200]
        LDR R10, =0x52
        STR R10, [R11, #204]
        LDR R10, =0x74
        STR R10, [R11, #208]
        LDR R10, =0x5D
        STR R10, [R11, #212]
        LDR R10, =0x77
        STR R10, [R11, #216]
        LDR R10, =0x1D
        STR R10, [R11, #220]
        LDR R10, =0x67
        STR R10, [R11, #224]
        LDR R10, =0x19
        STR R10, [R11, #228]
        LDR R10, =0x26
        STR R10, [R11, #232]
        LDR R10, =0x29
        STR R10, [R11, #236]
        LDR R10, =0x2A
        STR R10, [R11, #240]
        LDR R10, =0x6A
        STR R10, [R11, #244]
        LDR R10, =0x7A
        STR R10, [R11, #248]
        LDR R10, =0x7E
        STR R10, [R11, #252]
        LDR R10, =0x3F
        STR R10, [R11, #256]
        LDR R10, =0x0F
        STR R10, [R11, #260]
        LDR R10, =0x03
        STR R10, [R11, #264]
        LDR R10, =0x40
        STR R10, [R11, #268]
        LDR R10, =0x10
        STR R10, [R11, #272]
        LDR R10, =0x04
        STR R10, [R11, #276]
        LDR R10, =0x41
        STR R10, [R11, #280]
        LDR R10, =0x30
        STR R10, [R11, #284]
        LDR R10, =0x0C
        STR R10, [R11, #288]
        LDR R10, =0x43
        STR R10, [R11, #292]
        LDR R10, =0x50
        STR R10, [R11, #296]
        LDR R10, =0x14
        STR R10, [R11, #300]
        LDR R10, =0x45
        STR R10, [R11, #304]
        LDR R10, =0x71
        STR R10, [R11, #308]
        LDR R10, =0x3C
        STR R10, [R11, #312]
        LDR R10, =0x4F
        STR R10, [R11, #316]
        LDR R10, =0x13
        STR R10, [R11, #320]
        LDR R10, =0x44
        STR R10, [R11, #324]
        LDR R10, =0x51
        STR R10, [R11, #328]
        LDR R10, =0x34
        STR R10, [R11, #332]
        LDR R10, =0x4D
        STR R10, [R11, #336]
        LDR R10, =0x73
        STR R10, [R11, #340]
        LDR R10, =0x5C
        STR R10, [R11, #344]
        LDR R10, =0x57
        STR R10, [R11, #348]
        LDR R10, =0x15
        STR R10, [R11, #352]
        LDR R10, =0x65
        STR R10, [R11, #356]
        LDR R10, =0x79
        STR R10, [R11, #360]
        LDR R10, =0x3E
        STR R10, [R11, #364]
        LDR R10, =0x2F
        STR R10, [R11, #368]
        LDR R10, =0x0B
        STR R10, [R11, #372]
        LDR R10, =0x42
        STR R10, [R11, #376]
        LDR R10, =0x70
        STR R10, [R11, #380]
        LDR R10, =0x1C
        STR R10, [R11, #384]
        LDR R10, =0x47
        STR R10, [R11, #388]
        LDR R10, =0x11
        STR R10, [R11, #392]
        LDR R10, =0x24
        STR R10, [R11, #396]
        LDR R10, =0x49
        STR R10, [R11, #400]
        LDR R10, =0x32
        STR R10, [R11, #404]
        LDR R10, =0x6C
        STR R10, [R11, #408]
        LDR R10, =0x5B
        STR R10, [R11, #412]
        LDR R10, =0x56
        STR R10, [R11, #416]
        LDR R10, =0x35
        STR R10, [R11, #420]
        LDR R10, =0x6D
        STR R10, [R11, #424]
        LDR R10, =0x7B
        STR R10, [R11, #428]
        LDR R10, =0x5E
        STR R10, [R11, #432]
        LDR R10, =0x37
        STR R10, [R11, #436]
        LDR R10, =0x0D
        STR R10, [R11, #440]



;;begin load value to the designated
        LDR R11,=0x20000000

        LDR R10, =0x00
        STR R10, [R11, #144]   ;;S36   -------- D9
        LDR R10, =0x00
        STR R10, [R11, #140]    ;;S35   -------- D8
        LDR R10, =0x00
        STR R10, [R11, #136]    ;;S34   --------D7
        LDR R10, =0x00
        STR R10, [R11, #132]    ;;S33
        LDR R10, =0x00
        STR R10, [R11, #128]    ;;S32
        LDR R10, =0x00
        STR R10, [R11, #124]    ;;S31
        LDR R10, =0x00
        STR R10, [R11, #120]    ;;S30
        LDR R10, =0x00
        STR R10, [R11, #116]    ;;S29
        LDR R10, =0x00
        STR R10, [R11, #112]    ;;S28   -------- D6
        LDR R10, =0x00
        STR R10, [R11, #108]    ;;S27   -------- D5
        LDR R10, =0x00
        STR R10, [R11, #104]    ;;S26
        LDR R10, =0x00
        STR R10, [R11, #100]    ;;S25
        LDR R10, =0x00
        STR R10, [R11, #96]    ;;S24
        LDR R10, =0x00
        STR R10, [R11, #92]    ;;S23
        LDR R10, =0x00
        STR R10, [R11, #88]    ;;S22
        LDR R10, =0x00
        STR R10, [R11, #84]    ;;S21
        LDR R10, =0x00
        STR R10, [R11, #80]    ;;S20
        LDR R10, =0x00
        STR R10, [R11, #76]    ;;S19
        LDR R10, =0x00
        STR R10, [R11, #72]    ;;S18   --------D4
        LDR R10, =0x00
        STR R10, [R11, #68]    ;;S17
        LDR R10, =0x00
        STR R10, [R11, #64]    ;;S16   --------D3
        LDR R10, =0x00
        STR R10, [R11, #60]    ;;S15   --------D2
        LDR R10, =0x00
        STR R10, [R11, #56]    ;;S14
        LDR R10, =0x00
        STR R10, [R11, #52]    ;;S13
        LDR R10, =0x00
        STR R10, [R11, #48]    ;;S12
        LDR R10, =0x00
        STR R10, [R11, #44]    ;;S11
        LDR R10, =0x00
        STR R10, [R11, #40]    ;;S10
        LDR R10, =0x00
        STR R10, [R11, #36]    ;;S9   --------D1
        LDR R10, =0x00
        STR R10, [R11, #32]    ;;S8  --------D0
        LDR R10, =0x00
        STR R10, [R11, #28]    ;;S7
        LDR R10, =0x00
        STR R10, [R11, #24]    ;;S6
        LDR R10, =0x00
        STR R10, [R11, #20]    ;;S5
        LDR R10, =0x00
        STR R10, [R11, #16]    ;;S4
        LDR R10, =0x00
        STR R10, [R11, #12]    ;;S3
        LDR R10, =0x00
        STR R10, [R11, #8]    ;;S2
        LDR R10, =0x00
        STR R10, [R11, #4]    ;;S1
        LDR R10, =0x00
        STR R10, [R11, #0]    ;;S0
        
        POP {R10, R11}
 ;;finish load value to the designated       

        BL FFUNAE


main    B       main ;; Program finished, LOOP


;;this is the mode 
FFUNAE
        PUSH {LR}
        
        BL FFUN3
        BL FFUNKEY
        BL FFUNM
        BL FFUNKEY
        
        POP {LR}
        BX lr

;;load data
LOADVAL
        PUSH {LR}
        LDR R11,=0x20000000

        LDR R9, [R11, #144]   ;;S36   -------- D9
        LDR R8, [R11, #140]    ;;S35   -------- D8
        LDR R7, [R11, #136]    ;;S34   --------D7
        LDR R6, [R11, #112]    ;;S28   -------- D6
        LDR R5, [R11, #108]    ;;S27   -------- D5
        LDR R4, [R11, #72]    ;;S18   --------D4
        LDR R3, [R11, #64]    ;;S16   --------D3
        LDR R2, [R11, #60]    ;;S15   --------D2
        LDR R1, [R11, #36]    ;;S9   --------D1
        LDR R0, [R11, #32]    ;;S8  --------D0
        LDR R10, [R11, #0]   ;;S0 for domain seperator absorb

        POP {LR}
        BX lr

;;save data        
STOREVAL
        PUSH {LR}
        LDR R11,=0x20000000

        STR R9, [R11, #144]   ;;S36   -------- D9
        STR R8, [R11, #140]    ;;S35   -------- D8
        STR R7, [R11, #136]    ;;S34   --------D7
        STR R6, [R11, #112]    ;;S28   -------- D6
        STR R5, [R11, #108]    ;;S27   -------- D5
        STR R4, [R11, #72]    ;;S18   --------D4
        STR R3, [R11, #64]    ;;S16   --------D3
        STR R2, [R11, #60]    ;;S15   --------D2
        STR R1, [R11, #36]    ;;S9   --------D1
        STR R0, [R11, #32]    ;;S8  --------D0
        STR R10, [R11, #0]    ;;S0 for domain seperator absorb

        POP {LR}
        BX lr


;;this is the key absorption part in the mode
FFUNKEY
        PUSH {LR}
        
        BL LOADVAL                 ;;XOR with Key0
        EOR R9, R9, #0x00000000         
        EOR R8, R8, #0x00000000
        EOR R7, R7, #0x00000000
        EOR R6, R6, #0x00000000         
        EOR R5, R5, #0x00000000
        EOR R4, R4, #0x00000000
        EOR R3, R3, #0x00000000         
        EOR R2, R2, #0x00000000
        EOR R1, R1, #0x00000000
        EOR R0, R0, #0x00000000         
        BL STOREVAL
        
        BL FFUN3
     

        BL LOADVAL               ;;XOR with Key1
        EOR R9, R9, #0x00000000
        EOR R8, R8, #0x00000000
        EOR R7, R7, #0x00000000
        EOR R6, R6, #0x00000000
        EOR R5, R5, #0x00000000
        EOR R4, R4, #0x00000000
        EOR R3, R3, #0x00000000
        EOR R2, R2, #0x00000000
        EOR R1, R1, #0x00000000
        EOR R0, R0, #0x00000000
        BL STOREVAL
        
        BL FFUN3

        POP {LR}
        BX lr
        

        
;;this is the message absorption part in the mode             
FFUNM
        PUSH {LR}

        LDR R12,=0
WHILEM  CMP R12,#16     ;;the value of lm in decimal number
        BGE NEXTM
        
        BL LOADVAL               ;;XOR with Key1
        EOR R9, R9, #0x00000000
        EOR R8, R8, #0x00000000
        EOR R7, R7, #0x00000000
        EOR R6, R6, #0x00000000
        EOR R5, R5, #0x00000000
        EOR R4, R4, #0x00000000
        EOR R3, R3, #0x00000000
        EOR R2, R2, #0x00000000
        EOR R1, R1, #0x00000000
        EOR R0, R0, #0x00000000
        EOR R10, R10, #0x00000002
        BL STOREVAL        
        
        BL FFUN3
        
        
        ADD R12, R12, #1
        B WHILEM
NEXTM

        POP {LR}
        BX lr
        
 ;;------------------------------permutation is below, and AE is above.

;;this is permutation box
FFUN3   ;;LOOP the WAGE
        PUSH {R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, LR}
        LDR R1,=0x00000004 ;;Memory jump factor
        LDR R2,=0x20000000 ;;factor for LDR, software does not allow <imm> value more than thousands
        LDR R12,=0
WHILE1  CMP R12,#111
        BGE NEXT1
        BL FFUN
        B WHILE1
NEXT1

        LDR R11,=0x20000000
        LDR R9,=0x200001bc

        LDR R10,[R9, #144]
        STR R10, [R11, #144]
        LDR R10,[R9, #140]
        STR R10, [R11, #140]
        LDR R10,[R9, #136]
        STR R10, [R11, #136]
        LDR R10,[R9, #132]
        STR R10, [R11, #132]
        LDR R10,[R9, #128]
        STR R10, [R11, #128]
        LDR R10,[R9, #124]
        STR R10, [R11, #124]
        LDR R10,[R9, #120]
        STR R10, [R11, #120]
        LDR R10,[R9, #116]
        STR R10, [R11, #116]
        LDR R10,[R9, #112]
        STR R10, [R11, #112]
        LDR R10,[R9, #108]
        STR R10, [R11, #108]
        LDR R10,[R9, #104]
        STR R10, [R11, #104]
        LDR R10,[R9, #100]
        STR R10, [R11, #100]
        LDR R10,[R9, #96]
        STR R10, [R11, #96]
        LDR R10,[R9, #92]
        STR R10, [R11, #92]
        LDR R10,[R9, #88]
        STR R10, [R11, #88]
        LDR R10,[R9, #84]
        STR R10, [R11, #84]
        LDR R10,[R9, #80]
        STR R10, [R11, #80]
        LDR R10,[R9, #76]
        STR R10, [R11, #76]
        LDR R10,[R9, #72]
        STR R10, [R11, #72]
        LDR R10,[R9, #68]
        STR R10, [R11, #68]
        LDR R10,[R9, #64]
        STR R10, [R11, #64]
        LDR R10,[R9, #60]
        STR R10, [R11, #60]
        LDR R10,[R9, #56]
        STR R10, [R11, #56]
        LDR R10,[R9, #52]
        STR R10, [R11, #52]
        LDR R10,[R9, #48]
        STR R10, [R11, #48]
        LDR R10,[R9, #44]
        STR R10, [R11, #44]
        LDR R10,[R9, #40]
        STR R10, [R11, #40]
        LDR R10,[R9, #36]
        STR R10, [R11, #36]
        LDR R10,[R9, #32]
        STR R10, [R11, #32]
        LDR R10,[R9, #28]
        STR R10, [R11, #28]
        LDR R10,[R9, #24]
        STR R10, [R11, #24]
        LDR R10,[R9, #20]
        STR R10, [R11, #20]
        LDR R10,[R9, #16]
        STR R10, [R11, #16]
        LDR R10,[R9, #12]
        STR R10, [R11, #12]
        LDR R10,[R9, #8]
        STR R10, [R11, #8]
        LDR R10,[R9, #4]
        STR R10, [R11, #4]
        LDR R10,[R9, #0]
        STR R10, [R11, #0]

        
        POP {R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, LR}
        BX lr



;;this is WG permutation round
FFUN     ;; wg 20001000,  r 20002000, s-box 20003000
        PUSH {LR}

        LDR R11,=0x20000000
        MUL R0, R12, R1
        ADD R11, R11, R0 ;;set index to the current loaction of the data in the memory

        LDR R10,[R11, #144]  ;;get current value of s36
        MUL R10, R10, R1
        ADD R0, R2, #0x1000  ;;
        LDR R10,[R0, R10] ;;get WG result of s36 save to the same register R10
        
        LDR R9,[R11, #124]  ;; s31
        EOR R10, R10, R9
        LDR R9,[R11, #120]  ;; s30  -- r9
        EOR R10, R10, R9
        LDR R8,[R11, #104]  ;; s26
        EOR R10, R10, R8
        LDR R8,[R11, #96]  ;; s24  --  r8
        EOR R10, R10, R8
        LDR R7,[R11, #76]  ;; s19  --  r7
        EOR R10, R10, R7
        LDR R6,[R11, #52]  ;; s13
        EOR R10, R10, R6
        LDR R6,[R11, #48]  ;; s12
        EOR R10, R10, R6
        LDR R6,[R11, #32]  ;; s8  -- r6
        EOR R10, R10, R6
        LDR R5,[R11, #24]  ;; s6
        EOR R10, R10, R5
        
        LDR R5,[R11, #0]  ;; XOR with s0
        MUL R5, R5, R1
        ADD R0, R2, #0x2000
        LDR R5,[R0, R5] ;;get r result of s0 save to the same register R5
        EOR R10, R10, R5

        
        MUL R0, R12, R1   ;;XOR with RC1
        ADD R0, R0, R2
        ADD R0, R0, #0x5000
        LDR R0,[R0, #0]
        EOR R10, R10, R0
;;R10 is the fb-out
        
        
        ;;begin update terms s30(r9) with <- s30 (r9) + S(s34(r5*))
        LDR R5,[R11, #136]  ;get s34 to r5
        MUL R5, R5, R1
        ADD R0, R2, #0x3000
        LDR R5,[R0, R5] ;;get s-box result of s34 save to the same register R5
        EOR R9, R9, R5
        ;;end  update terms s30

        ;;begin update terms s24(r8) with <- s24 (r8) + S(s27(r5*))
        LDR R5,[R11, #108]
        MUL R5, R5, R1
        ADD R0, R2, #0x3000
        LDR R5,[R0, R5] ;Type: s-box
        EOR R8, R8, R5
        ;;end  update terms s24

        ;;begin update terms s19(r7) with <- s19 (r7) + WG(s18(r5*))
        LDR R5,[R11, #72]
        MUL R5, R5, R1
        ADD R0, R2, #0x1000
        LDR R5,[R0, R5] ;Type: WG
        EOR R7, R7, R5
        
        MUL R0, R12, R1 ;;XOR with RC0
        ADD R0, R0, R2
        ADD R0, R0, #0x6000
        LDR R0,[R0, #0]
        EOR R7, R7, R0 ;;
        ;;end  update terms s19

        ;;begin update terms s11(r4) with <- s11 (r4) + S(s15(r5*))
        LDR R4,[R11, #44]
        LDR R5,[R11, #60]
        MUL R5, R5, R1
        ADD R0, R2, #0x3000
        LDR R5,[R0, R5] ;Type: s-box
        EOR R4, R4, R5
        ;;end  update terms s11

        ;;begin update terms s5(r3) with <- s5 (r3) + S(s8(r5*))
        LDR R3,[R11, #20]
        ADD R0, R2, #0x3000
        MUL R6, R6, R1   ;;R6 is the value of s8 from the load at f-out operation
        LDR R6,[R0, R6]  ;Type: s-box
        EOR R3, R3, R6
        ;;end  update terms s5
        
        
        STR R9, [R11, #120]
        STR R8, [R11, #96]
        STR R7, [R11, #76]
        STR R4, [R11, #44]
        STR R3, [R11, #20]
        
        ADD R12, R12, #1
        MUL R0, R12, R1
        ADD R0, R0, #144
        STR R10, [R2, R0]
        
        POP {LR}
        BX lr



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
