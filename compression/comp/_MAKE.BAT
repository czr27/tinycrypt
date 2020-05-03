@echo off
set bccpath=x:\bc\bin\
del comp*.exe
%bccpath%bcc32.exe -4 -C -P -y -d -Ox -Dengine0 comp.c
ren comp.exe comp0.exe
%bccpath%bcc32.exe -4 -C -P -y -d -Ox -Dengine1 comp.c
ren comp.exe comp1.exe
%bccpath%bcc32.exe -4 -C -P -y -d -Ox -Dengine2 comp.c
ren comp.exe comp2.exe
%bccpath%bcc32.exe -4 -C -P -y -d -Ox -Dengine3 comp.c
ren comp.exe comp3.exe
del *.obj
set bccpath=
