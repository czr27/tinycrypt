@echo off
if exist %1.exe del %1.exe
icl /c /MD /Ox /G7 -Qprof_use %1.cpp
if not exist %1.obj goto quit
link %1.obj kernel32.lib /SUBSYSTEM:CONSOLE
if exist %1.obj del %1.obj
::upx --best %1.exe
:quit
