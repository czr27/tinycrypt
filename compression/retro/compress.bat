@echo off

del /q *.appack & cd _corpus & echo === aplib ===
for %%f in (*) do (
	..\aplib\appack_r57shell.exe %%f ..\%%f.appack >nul  2>&1
)
cd ..

del /q *.exo & cd _corpus & echo === exomizer ===
for %%f in (*) do (
	..\exomizer\exomizer.exe raw %%f -o ..\%%f.exo >nul  2>&1
)
cd ..

del /q *.hrum & cd _corpus & echo === hrum ===
for %%f in (*) do (
	..\hrum\mhmt.exe -hrm %%f ..\%%f.hrum >nul  2>&1
)
cd ..

del /q *.hrust1 & cd _corpus & echo === hrust 1 ===
for %%f in (*) do (
	..\hrust1\oh1c.exe -r %%f ..\%%f.hrust1 >nul  2>&1
)
cd ..

del /q *.hrust2 & cd _corpus & echo === hrust 2 ===
for %%f in (*) do (
	..\hrust2\oh2c.exe %%f ..\%%f.hrust2 >nul  2>&1
)
cd ..

del /q *.lz4 *.lz4raw & cd _corpus & echo === lz4 ===
for %%f in (*) do (
	..\lz4\smallz4.exe -9 %%f ..\%%f.lz4 >nul  2>&1
	..\lz4\lz4-extract.exe < ..\%%f.lz4 > ..\%%f.lz4raw
)
cd ..

del /q *.megalz & cd _corpus & echo === megalz ===
for %%f in (*) do (
	..\megalz\mhmt.exe -mlz %%f ..\%%f.megalz >nul  2>&1
)
cd ..

del /q *.plet5 & cd _corpus & echo === pletter ===
for %%f in (*) do (
	..\pletter\pletter5.exe %%f ..\%%f.plet5 >nul  2>&1
)
cd ..

del /q *.pucrunch & cd _corpus & echo === pucrunch ===
for %%f in (*) do (
	..\pucrunch\apri_pucrunch.exe -d -c0 %%f ..\%%f.pucrunch >nul  2>&1
)
cd ..

del /q *.zx7 & cd _corpus & echo === zx7 ===
for %%f in (*) do (
	..\zx7\zx7.exe %%f ..\%%f.zx7 >nul  2>&1
)
cd ..

