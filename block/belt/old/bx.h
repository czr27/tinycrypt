
// Target architecture : X86 32

#define BX2_SIZE 210

char BX2[] = {
  /* 0000 */ "\x60"                 /* pushal                              */
  /* 0001 */ "\x8b\x7c\x24\x24"     /* mov    edi, dword ptr [esp + 0x24]  */
  /* 0005 */ "\x8b\x74\x24\x28"     /* mov    esi, dword ptr [esp + 0x28]  */
  /* 0009 */ "\x31\xc0"             /* xor    eax, eax                     */
  /* 000B */ "\x56"                 /* push   esi                          */
  /* 000C */ "\x50"                 /* push   eax                          */
  /* 000D */ "\x57"                 /* push   edi                          */
  /* 000E */ "\x50"                 /* push   eax                          */
  /* 000F */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0010 */ "\x93"                 /* xchg   eax, ebx                     */
  /* 0011 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0012 */ "\x91"                 /* xchg   eax, ecx                     */
  /* 0013 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0014 */ "\x92"                 /* xchg   eax, edx                     */
  /* 0015 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0016 */ "\x96"                 /* xchg   eax, esi                     */
  /* 0017 */ "\xe8\x5f\x00\x00\x00" /* call   0x7b                         */
  /* 001C */ "\x60"                 /* pushal                              */
  /* 001D */ "\x8b\x74\x24\x0c"     /* mov    esi, dword ptr [esp + 0xc]   */
  /* 0021 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0022 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0023 */ "\x92"                 /* xchg   eax, edx                     */
  /* 0024 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0025 */ "\x50"                 /* push   eax                          */
  /* 0026 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0027 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 0028 */ "\x97"                 /* xchg   eax, edi                     */
  /* 0029 */ "\xad"                 /* lodsd  eax, dword ptr [esi]         */
  /* 002A */ "\xff\x46\xfc"         /* inc    dword ptr [esi - 4]          */
  /* 002D */ "\x83\xe0\x07"         /* and    eax, 7                       */
  /* 0030 */ "\x03\x14\x87"         /* add    edx, dword ptr [edi + eax*4] */
  /* 0033 */ "\xb0\x04"             /* mov    al, 4                        */
  /* 0035 */ "\x80\xea\x0a"         /* sub    dl, 0xa                      */
  /* 0038 */ "\x74\x30"             /* je     0x6a                         */
  /* 003A */ "\x80\xd2\x0a"         /* adc    dl, 0xa                      */
  /* 003D */ "\x0f\xb6\xca"         /* movzx  ecx, dl                      */
  /* 0040 */ "\xb2\x1d"             /* mov    dl, 0x1d                     */
  /* 0042 */ "\x51"                 /* push   ecx                          */
  /* 0043 */ "\xb1\x74"             /* mov    cl, 0x74                     */
  /* 0045 */ "\x88\xd3"             /* mov    bl, dl                       */
  /* 0047 */ "\x80\xe3\x63"         /* and    bl, 0x63                     */
  /* 004A */ "\x88\xdf"             /* mov    bh, bl                       */
  /* 004C */ "\xd0\xef"             /* shr    bh, 1                        */
  /* 004E */ "\x30\xfb"             /* xor    bl, bh                       */
  /* 0050 */ "\x88\xdf"             /* mov    bh, bl                       */
  /* 0052 */ "\xc0\xef\x02"         /* shr    bh, 2                        */
  /* 0055 */ "\x30\xfb"             /* xor    bl, bh                       */
  /* 0057 */ "\x88\xdf"             /* mov    bh, bl                       */
  /* 0059 */ "\xc0\xef\x04"         /* shr    bh, 4                        */
  /* 005C */ "\x30\xfb"             /* xor    bl, bh                       */
  /* 005E */ "\xc0\xe3\x07"         /* shl    bl, 7                        */
  /* 0061 */ "\xd0\xea"             /* shr    dl, 1                        */
  /* 0063 */ "\x08\xda"             /* or     dl, bl                       */
  /* 0065 */ "\xe2\xde"             /* loop   0x45                         */
  /* 0067 */ "\x59"                 /* pop    ecx                          */
  /* 0068 */ "\xe2\xd8"             /* loop   0x42                         */
  /* 006A */ "\xc1\xca\x08"         /* ror    edx, 8                       */
  /* 006D */ "\x48"                 /* dec    eax                          */
  /* 006E */ "\x75\xc5"             /* jne    0x35                         */
  /* 0070 */ "\x59"                 /* pop    ecx                          */
  /* 0071 */ "\xd3\xc2"             /* rol    edx, cl                      */
  /* 0073 */ "\x89\x54\x24\x1c"     /* mov    dword ptr [esp + 0x1c], edx  */
  /* 0077 */ "\x61"                 /* popal                               */
  /* 0078 */ "\xc2\x08\x00"         /* ret    8                            */
  /* 007B */ "\x5d"                 /* pop    ebp                          */
  /* 007C */ "\x6a\x05"             /* push   5                            */
  /* 007E */ "\x53"                 /* push   ebx                          */
  /* 007F */ "\xff\xd5"             /* call   ebp                          */
  /* 0081 */ "\x31\xc1"             /* xor    ecx, eax                     */
  /* 0083 */ "\x6a\x15"             /* push   0x15                         */
  /* 0085 */ "\x56"                 /* push   esi                          */
  /* 0086 */ "\xff\xd5"             /* call   ebp                          */
  /* 0088 */ "\x31\xc2"             /* xor    edx, eax                     */
  /* 008A */ "\x6a\x0d"             /* push   0xd                          */
  /* 008C */ "\x51"                 /* push   ecx                          */
  /* 008D */ "\xff\xd5"             /* call   ebp                          */
  /* 008F */ "\x29\xc3"             /* sub    ebx, eax                     */
  /* 0091 */ "\x6a\x15"             /* push   0x15                         */
  /* 0093 */ "\x8d\x04\x11"         /* lea    eax, dword ptr [ecx + edx]   */
  /* 0096 */ "\x50"                 /* push   eax                          */
  /* 0097 */ "\xff\xd5"             /* call   ebp                          */
  /* 0099 */ "\x97"                 /* xchg   eax, edi                     */
  /* 009A */ "\x58"                 /* pop    eax                          */
  /* 009B */ "\x40"                 /* inc    eax                          */
  /* 009C */ "\x50"                 /* push   eax                          */
  /* 009D */ "\x31\xc7"             /* xor    edi, eax                     */
  /* 009F */ "\x01\xf9"             /* add    ecx, edi                     */
  /* 00A1 */ "\x29\xfa"             /* sub    edx, edi                     */
  /* 00A3 */ "\x6a\x0d"             /* push   0xd                          */
  /* 00A5 */ "\x52"                 /* push   edx                          */
  /* 00A6 */ "\xff\xd5"             /* call   ebp                          */
  /* 00A8 */ "\x01\xc6"             /* add    esi, eax                     */
  /* 00AA */ "\x6a\x15"             /* push   0x15                         */
  /* 00AC */ "\x53"                 /* push   ebx                          */
  /* 00AD */ "\xff\xd5"             /* call   ebp                          */
  /* 00AF */ "\x31\xc1"             /* xor    ecx, eax                     */
  /* 00B1 */ "\x6a\x05"             /* push   5                            */
  /* 00B3 */ "\x56"                 /* push   esi                          */
  /* 00B4 */ "\xff\xd5"             /* call   ebp                          */
  /* 00B6 */ "\x31\xc2"             /* xor    edx, eax                     */
  /* 00B8 */ "\x87\xcb"             /* xchg   ebx, ecx                     */
  /* 00BA */ "\x87\xf2"             /* xchg   edx, esi                     */
  /* 00BC */ "\x87\xd1"             /* xchg   ecx, edx                     */
  /* 00BE */ "\x58"                 /* pop    eax                          */
  /* 00BF */ "\x50"                 /* push   eax                          */
  /* 00C0 */ "\x3c\x08"             /* cmp    al, 8                        */
  /* 00C2 */ "\x75\xb8"             /* jne    0x7c                         */
  /* 00C4 */ "\x58"                 /* pop    eax                          */
  /* 00C5 */ "\x58"                 /* pop    eax                          */
  /* 00C6 */ "\x58"                 /* pop    eax                          */
  /* 00C7 */ "\x5f"                 /* pop    edi                          */
  /* 00C8 */ "\x91"                 /* xchg   eax, ecx                     */
  /* 00C9 */ "\xab"                 /* stosd  dword ptr es:[edi], eax      */
  /* 00CA */ "\x96"                 /* xchg   eax, esi                     */
  /* 00CB */ "\xab"                 /* stosd  dword ptr es:[edi], eax      */
  /* 00CC */ "\x93"                 /* xchg   eax, ebx                     */
  /* 00CD */ "\xab"                 /* stosd  dword ptr es:[edi], eax      */
  /* 00CE */ "\x92"                 /* xchg   eax, edx                     */
  /* 00CF */ "\xab"                 /* stosd  dword ptr es:[edi], eax      */
  /* 00D0 */ "\x61"                 /* popal                               */
  /* 00D1 */ "\xc3"                 /* ret                                 */
};