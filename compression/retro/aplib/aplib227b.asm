; Se puede aumentar la velocidad m�s todav�a, expandiendo la rutina ap_getgamma
; de forma que pongamos inline los primeros pasos de la rutina, al precio de 15 bytes
; por cada bit optimizado (hasta el octavo, luego 17 hasta el 15 que ser�a el �ltimo).
; Aqu� pongo un ejemplo con 2 bits optimizados (227 bytes):

; You can increase the speed even more, expanding routine ap_getgamma put inline
; so that the first steps of the routine, at 15 bytes for each optimized bit (until the eighth,
; then 17 to 15 would be the last). Here I give you an example optimized with 2 bits (227 bytes):

; aPPack decompressor
; original source by dwedit
; very slightly adapted by utopian
; optimized by Metalbrain

;hl = source
;de = dest

depack:		;di
		;push	iy
		or	a
		ex	af, af'
		;call	unsafedepack
		;pop	iy
		;ret

unsafedepack:   ld      a,128
apbranch1:      ldi
aploop2:        ld      ixh,1
aploop:         add     a,a
                jr      nz,apnogetbit1
                ld      a,(hl)
                inc     hl
                rla
apnogetbit1:    jr      nc,apbranch1
                add     a,a
                jr      nz,apnogetbit2
                ld      a,(hl)
                inc     hl
                rla
apnogetbit2:    jr      nc,apbranch2
                add     a,a
                jr      nz,apnogetbit3
                ld      a,(hl)
                inc     hl
                rla
apnogetbit3:    jr      nc,apbranch3
                ld      bc,16      ;get an offset
apget4bits:     add     a,a
                jr      nz,apnogetbit4
                ld      a,(hl)
                inc     hl
                rla
apnogetbit4:    rl      c
                jr      nc,apget4bits
                jr      nz,apbranch4
                ex      de,hl
                ld      (hl),b      ;write a 0
                ex      de,hl
                inc     de
                jp      aploop2
apbranch4:      ex      af,af'
                ex      de,hl       ;write a previous byte (1-15 away from dest)
                sbc     hl,bc
                ld      a,(hl)
                add     hl,bc
                ld      (hl),a
                ex      af,af'
                ex      de,hl
                inc     de
                jp      aploop2

apbranch3:      ld      c,(hl)      ;use 7 bit offset, length = 2 or 3
                inc     hl
                ex      af,af'
                rr      c
                ret     z      ;if a zero is found here, it's EOF
                ld      a,2
                ld      b,0
                adc     a,b
                push    hl
                ld      iyh,b
                ld      iyl,c
                ld      h,d
                ld      l,e
                sbc     hl,bc
                ld      c,a
                ex      af,af'
                ldir
                pop     hl
                ld      ixh,b
                jp      aploop
apbranch2:      call    ap_getgamma   ;use a gamma code * 256 for offset, another gamma code for length
                dec     c
                ex      af,af'
                ld      a,c
                sub     ixh
                jr      z,ap_r0_gamma
                dec     a

                ;do I even need this code?
                ;bc=bc*256+(hl), lazy 16bit way
                ld      b,a
                ld      c,(hl)
                inc     hl
                ld      iyh,b
                ld      iyl,c

                push    bc

                call    ap_getgamma2

                ex      (sp),hl      ;bc = len, hl=offs
                push    de
                ex      de,hl

                ex      af,af'
                ld      a,4
                cp      d
                jr      nc,apskip2
                inc     bc
                or      a
apskip2:        ld      hl,127
                sbc     hl,de
                jr      c,apskip3
                inc     bc
                inc     bc
apskip3:        pop     hl      ;bc = len, de = offs, hl=junk
                push    hl
                or      a
                sbc     hl,de
                ex      af,af'
                pop     de      ;hl=dest-offs, bc=len, de = dest
                ldir
                pop     hl
                ld      ixh,b
                jp      aploop

ap_r0_gamma:    call    ap_getgamma2   ;and a new gamma code for length
                push    hl
                push    de
                ex      de,hl

                ld      d,iyh
                ld      e,iyl
                sbc     hl,de
                pop     de      ;hl=dest-offs, bc=len, de = dest
                ldir
                pop     hl
                ld      ixh,b
                jp      aploop

ap_getgamma2:   ex      af,af'
ap_getgamma:    ld      bc,1
                add     a,a
                jr      nz,apnogetbit5
                ld      a,(hl)
                inc     hl
                rla
apnogetbit5:    rl      c
                add     a,a
                jr      nz,apnogetbit6
                ld      a,(hl)
                inc     hl
                rla
apnogetbit6:    ret     nc
                add     a,a
                jr      nz,apnogetbit7
                ld      a,(hl)
                inc     hl
                rla
apnogetbit7:    rl      c
                add     a,a
                jr      nz,apnogetbit8
                ld      a,(hl)
                inc     hl
                rla
apnogetbit8:    ret     nc
ap_getgammaloop:add     a,a
                jr      nz,apnogetbit9
                ld      a,(hl)
                inc     hl
                rla
apnogetbit9:    rl      c
                rl      b
                add     a,a
                jr      nz,apnogetbit10
                ld      a,(hl)
                inc     hl
                rla
apnogetbit10:   jr      c,ap_getgammaloop
                ret