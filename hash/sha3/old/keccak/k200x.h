
#define K200X_SIZE 210

char K200X[] = {
  /* 0000 */ "\x60"                         /* pushad                        */
  /* 0001 */ "\x8b\x74\x24\x24"             /* mov esi, [esp+0x24]           */
  /* 0005 */ "\x60"                         /* pushad                        */
  /* 0006 */ "\x89\xe7"                     /* mov edi, esp                  */
  /* 0008 */ "\xe8\x33\x00\x00\x00"         /* call 0x40                     */
  /* 000D */ "\x00\x01"                     /* add [ecx], al                 */
  /* 000F */ "\x02\x03"                     /* add al, [ebx]                 */
  /* 0011 */ "\x04\x00"                     /* add al, 0x0                   */
  /* 0013 */ "\x01\x02"                     /* add [edx], eax                */
  /* 0015 */ "\x03\x01"                     /* add eax, [ecx]                */
  /* 0017 */ "\x82\x8a\x00\x8b\x01\x81\x09" /* or byte [edx-0x7efe7500], 0x9 */
  /* 001E */ "\x8a\x88\x09\x0a\x8b\x8b"     /* mov cl, [eax-0x7474f5f7]      */
  /* 0024 */ "\x89\x03"                     /* mov [ebx], eax                */
  /* 0026 */ "\x02\x80\x0a\x07\x0b\x11"     /* add al, [eax+0x110b070a]      */
  /* 002C */ "\x12\x03"                     /* adc al, [ebx]                 */
  /* 002E */ "\x05\x10\x08\x15\x18"         /* add eax, 0x18150810           */
  /* 0033 */ "\x04\x0f"                     /* add al, 0xf                   */
  /* 0035 */ "\x17"                         /* pop ss                        */
  /* 0036 */ "\x13\x0d\x0c\x02\x14\x0e"     /* adc ecx, [0xe14020c]          */
  /* 003C */ "\x16"                         /* push ss                       */
  /* 003D */ "\x09\x06"                     /* or [esi], eax                 */
  /* 003F */ "\x01\x5d\x31"                 /* add [ebp+0x31], ebx           */
  /* 0042 */ "\xc0\x50\x6a\x05"             /* rcl byte [eax+0x6a], 0x5      */
  /* 0046 */ "\x59"                         /* pop ecx                       */
  /* 0047 */ "\x60"                         /* pushad                        */
  /* 0048 */ "\xac"                         /* lodsb                         */
  /* 0049 */ "\x32\x46\x04"                 /* xor al, [esi+0x4]             */
  /* 004C */ "\x32\x46\x09"                 /* xor al, [esi+0x9]             */
  /* 004F */ "\x32\x46\x0e"                 /* xor al, [esi+0xe]             */
  /* 0052 */ "\x32\x46\x13"                 /* xor al, [esi+0x13]            */
  /* 0055 */ "\xaa"                         /* stosb                         */
  /* 0056 */ "\xe2\xf0"                     /* loop 0x48                     */
  /* 0058 */ "\x61"                         /* popad                         */
  /* 0059 */ "\x31\xc0"                     /* xor eax, eax                  */
  /* 005B */ "\x0f\xb6\x5c\x05\x04"         /* movzx ebx, byte [ebp+eax+0x4] */
  /* 0060 */ "\x0f\xb6\x54\x05\x01"         /* movzx edx, byte [ebp+eax+0x1] */
  /* 0065 */ "\x8a\x1c\x1f"                 /* mov bl, [edi+ebx]             */
  /* 0068 */ "\x8a\x14\x17"                 /* mov dl, [edi+edx]             */
  /* 006B */ "\xd0\xc2"                     /* rol dl, 1                     */
  /* 006D */ "\x30\xd3"                     /* xor bl, dl                    */
  /* 006F */ "\x30\x1c\x06"                 /* xor [esi+eax], bl             */
  /* 0072 */ "\x04\x05"                     /* add al, 0x5                   */
  /* 0074 */ "\x3c\x19"                     /* cmp al, 0x19                  */
  /* 0076 */ "\x72\xf7"                     /* jb 0x6f                       */
  /* 0078 */ "\x2c\x18"                     /* sub al, 0x18                  */
  /* 007A */ "\xe2\xdf"                     /* loop 0x5b                     */
  /* 007C */ "\x8a\x5e\x01"                 /* mov bl, [esi+0x1]             */
  /* 007F */ "\x8d\x4c\x01\xfc"             /* lea ecx, [ecx+eax-0x4]        */
  /* 0083 */ "\x80\xe1\x07"                 /* and cl, 0x7                   */
  /* 0086 */ "\xd2\xc3"                     /* rol bl, cl                    */
  /* 0088 */ "\x8a\x54\x05\x16"             /* mov dl, [ebp+eax+0x16]        */
  /* 008C */ "\x86\x1c\x16"                 /* xchg [esi+edx], bl            */
  /* 008F */ "\x40"                         /* inc eax                       */
  /* 0090 */ "\x3c\x1d"                     /* cmp al, 0x1d                  */
  /* 0092 */ "\x75\xeb"                     /* jnz 0x7f                      */
  /* 0094 */ "\x31\xc0"                     /* xor eax, eax                  */
  /* 0096 */ "\x60"                         /* pushad                        */
  /* 0097 */ "\x01\xc6"                     /* add esi, eax                  */
  /* 0099 */ "\xa5"                         /* movsd                         */
  /* 009A */ "\xa4"                         /* movsb                         */
  /* 009B */ "\x61"                         /* popad                         */
  /* 009C */ "\x99"                         /* cdq                           */
  /* 009D */ "\x8a\x5c\x15\x01"             /* mov bl, [ebp+edx+0x1]         */
  /* 00A1 */ "\x8a\x4c\x15\x02"             /* mov cl, [ebp+edx+0x2]         */
  /* 00A5 */ "\x8a\x1c\x1f"                 /* mov bl, [edi+ebx]             */
  /* 00A8 */ "\xf6\xd3"                     /* not bl                        */
  /* 00AA */ "\x22\x1c\x0f"                 /* and bl, [edi+ecx]             */
  /* 00AD */ "\x8d\x0c\x10"                 /* lea ecx, [eax+edx]            */
  /* 00B0 */ "\x30\x1c\x0e"                 /* xor [esi+ecx], bl             */
  /* 00B3 */ "\x42"                         /* inc edx                       */
  /* 00B4 */ "\x80\xfa\x05"                 /* cmp dl, 0x5                   */
  /* 00B7 */ "\x75\xe4"                     /* jnz 0x9d                      */
  /* 00B9 */ "\x00\xd0"                     /* add al, dl                    */
  /* 00BB */ "\x3c\x19"                     /* cmp al, 0x19                  */
  /* 00BD */ "\x72\xd7"                     /* jb 0x96                       */
  /* 00BF */ "\x58"                         /* pop eax                       */
  /* 00C0 */ "\x8a\x54\x05\x09"             /* mov dl, [ebp+eax+0x9]         */
  /* 00C4 */ "\x30\x16"                     /* xor [esi], dl                 */
  /* 00C6 */ "\x40"                         /* inc eax                       */
  /* 00C7 */ "\x3c\x12"                     /* cmp al, 0x12                  */
  /* 00C9 */ "\x0f\x85\x74\xff\xff\xff"     /* jnz 0x43                      */
  /* 00CF */ "\x61"                         /* popad                         */
  /* 00D0 */ "\x61"                         /* popad                         */
  /* 00D1 */ "\xc3"                         /* ret                           */
};