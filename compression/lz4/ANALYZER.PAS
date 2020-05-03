{
LZ4 stream format stats generator
trixter@oldskool.org, 20130103
Prints the following stats for the first chunk in an LZ4 stream (assumes
the chunk is <64K):
  literal length: min, avg, max, number of runs
  match length: min, avg, max, number of runs
  offset: min, avg, max
  number of 1-byte RLEs (match where offset=1), average 1-byte RLE length
  number of 2-byte RLEs (match where offset=2), average 2-byte RLE length

This was written to help analyze the characteristics of LZ4 compressed stream
data to identify areas where the 8088 asm decompression routine could be
optimized.  Some insights gained from this analysis:

- Most lengths are under 15 so jumps should fall through favoring that
  condition.
  UPDATE: Correct! Big penalty for building up a length (two jumps) but
  since that is the uncommon case, the fall-through benefits the common case.

- RLE 2-byte runs do happen, but so infrequently and for so small an average
  run length that they should probably not be handled as a special case.
  Checking for that special case is likely eating more cycles than it is
  saving.  (Try removing them and seeing if robotron, which has 21 2-byte runs
  in it out of 8000+ events, gets faster or slower.)  I had assumed that
  sparse bitmaps with lots of repeating 2-byte sequences would have used
  these more, but the statistics contradict that assumption.
  UPDATE: After testing, removal made things slower. Left RLE 2-bytes in.

- Average match length is only 10, and setting up for a non-RLE run is
  very costly, so it is worth finding the break-even point for individual
  moves vs. a REP MOVS-style move.  After that point is found, it is worth
  finding an additional break-even point for a REP ES: MOVS vs. a traditional
  ds:si setup + REP MOVS move.
  UPDATE: Actual testing showed that only match lengths under 6 were faster
  and the ds:si+rep movs was faster for everything else.  Left it in.

}

program lz4stats;

uses
  objects;

type
  lz4_event=object(TObject)
    public
    min,          {minimum event value}
    avg,          {average event value}
    max,          {maximum event value}
    tot,          {total size of all values}
    num:longint;  {number of value events}
    Constructor Init;
    Destructor Done; virtual;
    Procedure Tally(val:word);
  end;

const
  bufsize=64260;
  csvoutput:boolean=false;
  c=',';

var
  l,m,o,rle1,rle2:lz4_event; {lengths, matches, offsets, 1-byte RLEs, 2-byte RLEs}
  f:file;
  buf:array[0..bufsize-1] of byte;
  numread,chunksize:word;
  ip:word; {input pointer}
  curllen,curmlen,curoffset:word;

Constructor lz4_event.init;
begin
  Inherited Init;
  min:=$ffff;
end;

Destructor lz4_event.done;
begin
  {Calc rest of stats and then print them out}
  if num <> 0
    then avg:=tot div num
    else begin
      avg:=0;
      min:=0;
    end;
  if not csvoutput then begin
    writeln('Min: ',min,'  Avg: ',avg,'  Max: ',max,'  Total: ',tot,'  # of events: ',num);
  end else begin
    write(c,min,c,avg,c,max,c,tot,c,num);
  end;
  Inherited Done;
end;

Procedure lz4_event.tally(val:word);
begin
  num:=num+1;
  tot:=tot+val;
  if min>val then min:=val;
  if max<val then max:=val;
end;

function bufwordval(w:word):word;
begin
  bufwordval:=(buf[w+1] SHL 8) OR buf[w];
end;

begin
  if paramcount<0 then begin
    writeln('Usage: analyzer filename.lz4 [csv]');
    writeln('If "csv" provided as second argument, output will be spreadsheet-friendly.');
    halt(1);
  end;
  assign(f,paramstr(1)); reset(f,1); blockread(f,buf,sizeof(buf),numread); close(f);
  if paramcount>1 then csvoutput:=true;
  l.init; m.init; o.init; rle1.init; rle2.init;
  ip:=4;
  chunksize:=bufwordval(ip);
  ip:=8;
  repeat
    {grab packed token}
    curllen:=buf[ip] SHR 4;
    curmlen:=buf[ip] AND $0F;
    inc(ip);

    {find total literal length}
    if curllen=$0F then repeat
      curllen:=curllen+buf[ip];
      inc(ip);
    until buf[ip-1]<>$ff;
    l.tally(curllen);

    {move past literals}
    ip:=ip+curllen;

    {last 5 bytes are always literals; are we done?}
    if ip >= (chunksize+8) then break;

    {grab offset}
    curoffset:=bufwordval(ip);
    ip:=ip+2;

    {find total match length}
    if curmlen=$0F then repeat
      curmlen:=curmlen+buf[ip];
      inc(ip);
    until buf[ip-1]<>$ff;
    {all matches are 4 + length, so adjust length}
    curmlen:=curmlen+4;

    {tally match length and match offset}
    case curoffset of
      1:rle1.tally(curmlen);
      2:rle2.tally(curmlen);
      else begin
        m.tally(curmlen);
        o.tally(curoffset);
      end;
    end;
  until ip >= (chunksize+8);

  if not csvoutput then begin
    writeln('====== ',paramstr(1),' Compressed size: ',chunksize,
      ' Decompressed size: ',l.tot+m.tot+rle1.tot+rle2.tot,' =====');
    writeln('_Generic cases_');
    write('  Literals:  '); l.done;
    write('  Matches:   '); m.done;
    write('  Offsets:   '); o.done;
    writeln('_8088-optimizable cases:_');
    write('  RLE 1-byte runs:  '); rle1.done;
    write('  RLE 2-byte runs:  '); rle2.done;
  end else begin
    {header}
    write('filename,compressed size,decompressed size,');
    write('literal min,literal avg,literal max,literal tot,literal num,');
    write('match min,match avg,match max,match tot,match num,');
    write('1-byte RLE min,1-byte RLE avg,1-byte RLE max,1-byte RLE tot,1-byte RLE num,');
    writeln('2-byte RLE min,2-byte RLE avg,2-byte RLE max,2-byte RLE tot,2-byte RLE num');
    {data}
    write(paramstr(1),c,chunksize,c,l.tot+m.tot+rle1.tot+rle2.tot);
    l.done;
    m.done;
    rle1.done;
    rle2.done;
    writeln;
  end;
end.
