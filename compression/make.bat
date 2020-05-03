@echo off

if exist snippetupx.exe del snippetupx.exe
:: /FAs /Fa0.asm
tasm32 /m /ml /z unpack.asm
cl snippetupx.cpp unpack.obj stub.obj decompress.obj -O2 -Oi -Og -Ox     /Zm200 /Gf /MD /YX /link /SUBSYSTEM:CONSOLE
del snippetupx.obj
upx --best snippetupx.exe
