{
This specific code is probably not what you want; it is a test harness
for the code in LZ4_8088.ASM.  See that file, as well as LZ4_8088.TXT
for additional background and details.
}

program lz4decomp;

uses
  ztimer;

function lz4_decompress(inb,outb:pointer):word; external;
function lz4_decompress_small(inb,outb:pointer):word; external;

{$L LZ4_8088}

Function BuffersEqual(p1,p2:pointer;size:word):word; assembler;
{compares two buffers; reports 0 if equal, or offset where not}
asm
  push ds
  lds si,p1
  les di,p2
  mov cx,size
  xor ax,ax {assume test will be successful}
  cld
  repe cmpsb
  cmp cx,0
  je @done
  mov ax,size {if cx<>0 then buffers are not equal}
  sub ax,cx
  dec ax {to report offset instead of absolute location}
@done:
  pop ds
end;


const
  bufsize=65536-16; {turbo pascal heap limitation prevents full 64KiB}

type
  barray=array[0..bufsize-1] of byte;

var
  inf,outf:file;
  inbuf,outbuf:^barray;
  ins,outs:string;
  oldsize,newsize,decompsize:word;
  lzdecomptime,copytime:longint;

begin
  if paramcount<1 then begin
    writeln('Usage: lz4decom filename    (do NOT provide .lz4 extension)');
    halt(1);
  end;
  getmem(inbuf,bufsize); fillchar(inbuf^,sizeof(inbuf),$ff);
  getmem(outbuf,bufsize); fillchar(outbuf^,sizeof(outbuf),$ff);

  ins:=paramstr(1)+'.lz4';
  outs:=paramstr(1)+'.out';
  assign(inf,ins);
  reset(inf,1);
  blockread(inf,inbuf^,bufsize,oldsize);
  close(inf);

  write('Decompressing ',ins,'... ');
  _lztimeron;
  decompsize:=lz4_decompress(inbuf,outbuf);
  _lztimeroff;
  writeln('Done.  ',decompsize,' bytes of output in: ',_lztimercount);

  writeln('(small)');
  write('Decompressing ',ins,'... ');
  _lztimeron;
  decompsize:=lz4_decompress_small(inbuf,outbuf);
  _lztimeroff;
  writeln('Done.  ',decompsize,' bytes of output in: ',_lztimercount);

  lzdecomptime:=_lztimercount;
  if decompsize>0
    then begin
      {writeln('Writing data to 'paramstr(1),'.out');}
      assign(outf,outs);
      rewrite(outf,1);
      blockwrite(outf,outbuf^,decompsize);
      close(outf);
    end else writeln('Decompression failed!');

  {compare to REP MOVS by copying output buffer to input buffer}
  _lztimeron;
  asm
    mov cx,decompsize
    les di,outbuf
    push ds
    lds si,inbuf
    shr cx,1
    rep movsw
    adc cx,cx
    rep movsb
    pop ds
  end;
  _lztimeroff;
  copytime:=_lztimercount;
  writeln('memcpy took: ',copytime,'. decomp is ',
  lzdecomptime/copytime:3:2
  ,'x slower than memcopy.');

end.
