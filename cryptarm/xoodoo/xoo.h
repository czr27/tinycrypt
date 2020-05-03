
#define XOODOO_SIZE 280

char XOODOO[] = {
  /* 0000 */ "\x55"                         /* push ebp                   */
  /* 0001 */ "\x8b\xec"                     /* mov ebp, esp               */
  /* 0003 */ "\x83\xec\x18"                 /* sub esp, 0x18              */
  /* 0006 */ "\x8b\x45\x08"                 /* mov eax, [ebp+0x8]         */
  /* 0009 */ "\x53"                         /* push ebx                   */
  /* 000A */ "\x56"                         /* push esi                   */
  /* 000B */ "\x57"                         /* push edi                   */
  /* 000C */ "\xc7\x45\x08\x00\x01\x00\x00" /* mov dword [ebp+0x8], 0x100 */
  /* 0013 */ "\x33\xff"                     /* xor edi, edi               */
  /* 0015 */ "\x8d\x50\x10"                 /* lea edx, [eax+0x10]        */
  /* 0018 */ "\x8b\x4a\xf0"                 /* mov ecx, [edx-0x10]        */
  /* 001B */ "\x33\x4a\x10"                 /* xor ecx, [edx+0x10]        */
  /* 001E */ "\x6a\x04"                     /* push 0x4                   */
  /* 0020 */ "\x33\x0a"                     /* xor ecx, [edx]             */
  /* 0022 */ "\xc1\xc1\x0e"                 /* rol ecx, 0xe               */
  /* 0025 */ "\x8b\xd9"                     /* mov ebx, ecx               */
  /* 0027 */ "\xc1\xcb\x09"                 /* ror ebx, 0x9               */
  /* 002A */ "\x33\xd9"                     /* xor ebx, ecx               */
  /* 002C */ "\x89\x5c\xbd\xe8"             /* mov [ebp+edi*4-0x18], ebx  */
  /* 0030 */ "\x5b"                         /* pop ebx                    */
  /* 0031 */ "\x47"                         /* inc edi                    */
  /* 0032 */ "\x03\xd3"                     /* add edx, ebx               */
  /* 0034 */ "\x3b\xfb"                     /* cmp edi, ebx               */
  /* 0036 */ "\x7c\xe0"                     /* jl 0x18                    */
  /* 0038 */ "\x33\xc9"                     /* xor ecx, ecx               */
  /* 003A */ "\x8d\x51\xff"                 /* lea edx, [ecx-0x1]         */
  /* 003D */ "\x83\xe2\x03"                 /* and edx, 0x3               */
  /* 0040 */ "\x8b\x54\x95\xe8"             /* mov edx, [ebp+edx*4-0x18]  */
  /* 0044 */ "\x31\x14\x88"                 /* xor [eax+ecx*4], edx       */
  /* 0047 */ "\x41"                         /* inc ecx                    */
  /* 0048 */ "\x83\xf9\x0c"                 /* cmp ecx, 0xc               */
  /* 004B */ "\x7c\xed"                     /* jl 0x3a                    */
  /* 004D */ "\x8b\x48\x1c"                 /* mov ecx, [eax+0x1c]        */
  /* 0050 */ "\x8b\x50\x10"                 /* mov edx, [eax+0x10]        */
  /* 0053 */ "\xc1\x40\x20\x0b"             /* rol dword [eax+0x20], 0xb  */
  /* 0057 */ "\xc1\x40\x24\x0b"             /* rol dword [eax+0x24], 0xb  */
  /* 005B */ "\xc1\x40\x28\x0b"             /* rol dword [eax+0x28], 0xb  */
  /* 005F */ "\xc1\x40\x2c\x0b"             /* rol dword [eax+0x2c], 0xb  */
  /* 0063 */ "\x89\x48\x10"                 /* mov [eax+0x10], ecx        */
  /* 0066 */ "\x8b\xca"                     /* mov ecx, edx               */
  /* 0068 */ "\x8b\x50\x14"                 /* mov edx, [eax+0x14]        */
  /* 006B */ "\x89\x48\x14"                 /* mov [eax+0x14], ecx        */
  /* 006E */ "\x8b\xca"                     /* mov ecx, edx               */
  /* 0070 */ "\x8b\x50\x18"                 /* mov edx, [eax+0x18]        */
  /* 0073 */ "\x89\x48\x18"                 /* mov [eax+0x18], ecx        */
  /* 0076 */ "\x8b\x4d\x08"                 /* mov ecx, [ebp+0x8]         */
  /* 0079 */ "\x89\x50\x1c"                 /* mov [eax+0x1c], edx        */
  /* 007C */ "\x0f\xb7\x09"                 /* movzx ecx, word [ecx]      */
  /* 007F */ "\x31\x08"                     /* xor [eax], ecx             */
  /* 0081 */ "\x8d\x48\x10"                 /* lea ecx, [eax+0x10]        */
  /* 0084 */ "\x89\x5d\xfc"                 /* mov [ebp-0x4], ebx         */
  /* 0087 */ "\x8b\x59\xf0"                 /* mov ebx, [ecx-0x10]        */
  /* 008A */ "\x8b\x11"                     /* mov edx, [ecx]             */
  /* 008C */ "\x8b\x79\x10"                 /* mov edi, [ecx+0x10]        */
  /* 008F */ "\xf7\xd3"                     /* not ebx                    */
  /* 0091 */ "\x23\xda"                     /* and ebx, edx               */
  /* 0093 */ "\x33\xdf"                     /* xor ebx, edi               */
  /* 0095 */ "\x89\x59\x10"                 /* mov [ecx+0x10], ebx        */
  /* 0098 */ "\x8b\xdf"                     /* mov ebx, edi               */
  /* 009A */ "\x89\x7d\xf8"                 /* mov [ebp-0x8], edi         */
  /* 009D */ "\x8b\x79\xf0"                 /* mov edi, [ecx-0x10]        */
  /* 00A0 */ "\xf7\xd3"                     /* not ebx                    */
  /* 00A2 */ "\x23\xdf"                     /* and ebx, edi               */
  /* 00A4 */ "\x33\xda"                     /* xor ebx, edx               */
  /* 00A6 */ "\xf7\xd2"                     /* not edx                    */
  /* 00A8 */ "\x23\x55\xf8"                 /* and edx, [ebp-0x8]         */
  /* 00AB */ "\x89\x19"                     /* mov [ecx], ebx             */
  /* 00AD */ "\x33\xd7"                     /* xor edx, edi               */
  /* 00AF */ "\x89\x51\xf0"                 /* mov [ecx-0x10], edx        */
  /* 00B2 */ "\x83\xc1\x04"                 /* add ecx, 0x4               */
  /* 00B5 */ "\xff\x4d\xfc"                 /* dec dword [ebp-0x4]        */
  /* 00B8 */ "\x75\xcd"                     /* jnz 0x87                   */
  /* 00BA */ "\xd1\x40\x10"                 /* rol dword [eax+0x10], 1    */
  /* 00BD */ "\xd1\x40\x14"                 /* rol dword [eax+0x14], 1    */
  /* 00C0 */ "\xd1\x40\x18"                 /* rol dword [eax+0x18], 1    */
  /* 00C3 */ "\xd1\x40\x1c"                 /* rol dword [eax+0x1c], 1    */
  /* 00C6 */ "\x8b\x48\x20"                 /* mov ecx, [eax+0x20]        */
  /* 00C9 */ "\x8b\x50\x24"                 /* mov edx, [eax+0x24]        */
  /* 00CC */ "\x8b\x78\x28"                 /* mov edi, [eax+0x28]        */
  /* 00CF */ "\x83\x45\x08\x02"             /* add dword [ebp+0x8], 0x2   */
  /* 00D3 */ "\xc1\xc1\x08"                 /* rol ecx, 0x8               */
  /* 00D6 */ "\xc1\xc2\x08"                 /* rol edx, 0x8               */
  /* 00D9 */ "\xc1\xc7\x08"                 /* rol edi, 0x8               */
  /* 00DC */ "\x89\x78\x20"                 /* mov [eax+0x20], edi        */
  /* 00DF */ "\x8b\x78\x2c"                 /* mov edi, [eax+0x2c]        */
  /* 00E2 */ "\xc1\xc7\x08"                 /* rol edi, 0x8               */
  /* 00E5 */ "\x81\x7d\x08\x18\x01\x00\x00" /* cmp dword [ebp+0x8], 0x118 */
  /* 00EC */ "\x89\x78\x24"                 /* mov [eax+0x24], edi        */
  /* 00EF */ "\x89\x48\x28"                 /* mov [eax+0x28], ecx        */
  /* 00F2 */ "\x89\x50\x2c"                 /* mov [eax+0x2c], edx        */
  /* 00F5 */ "\x0f\x8c\x18\xff\xff\xff"     /* jl 0x13                    */
  /* 00FB */ "\x5f"                         /* pop edi                    */
  /* 00FC */ "\x5e"                         /* pop esi                    */
  /* 00FD */ "\x5b"                         /* pop ebx                    */
  /* 00FE */ "\xc9"                         /* leave                      */
  /* 00FF */ "\xc3"                         /* ret                        */
  /* 0100 */ "\x58"                         /* pop eax                    */
  /* 0101 */ "\x00\x38"                     /* add [eax], bh              */
  /* 0103 */ "\x00\xc0"                     /* add al, al                 */
  /* 0105 */ "\x03\xd0"                     /* add edx, eax               */
  /* 0107 */ "\x00\x20"                     /* add [eax], ah              */
  /* 0109 */ "\x01\x14\x00"                 /* add [eax+eax], edx         */
  /* 010C */ "\x60"                         /* pushad                     */
  /* 010D */ "\x00\x2c\x00"                 /* add [eax+eax], ch          */
  /* 0110 */ "\x80\x03\xf0"                 /* add byte [ebx], 0xf0       */
  /* 0113 */ "\x00\xa0\x01\x12\x00"         /* invalid                    */
};