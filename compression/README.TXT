
                            freenrv2b compression
                            ---------------------

    upx  executable packer is distributed in two forms: in binary, linked with
    nrv  compression  library,  and in source form, containing ucl compression
    library.

    both  nrv and ucl libraries uses the same packing codes, and, as such, the
    same data unpacking algorithms (nrv2b,nrv2d,nrv2e).

    but nrv compression library packs data with better ratio than ucl, and upx
    author keeps nrv sources in secret.

    so  i  decided  to code some algo which will use the same unpacker and the
    same  packing  codes  as  nrv2b,  but  will  pack data better than ucl/nrv
    libraries, no matter how much time packing process will take.

    such  an algorithm works slow, especially when data size is large, or when
    data  contains  many  equal  substrings  or  characters. but it works fast
    enough  on  <50k  data sizes, packer uses ~1400 bytes, unpacker uses about
    ~100  bytes  (the  same as unpacker in the upx'ed files), so its ideal for
    virii ;-)

    pack_src.cpp            -- free nrv2b algorithm sources
    pack.exe && unpack.exe  -- command line packer/unpacker
    unpack.asi              -- unpack(), ~100 bytes
    pack1.asi, pack1.bin    -- pack(), ~2000 bytes
    pack2.asi, pack2.bin    -- self-extracting pack(), ~1400 bytes
