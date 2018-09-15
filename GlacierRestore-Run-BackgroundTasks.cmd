@echo off
set scriptfile=%~dp0.scripts\%~n0.ps1
echo.
echo Execute '%scriptfile%' %*
echo.
Powershell.exe -executionpolicy remotesigned -Command ". '%scriptfile%' -AutoRequestArchives -Verbose:$false %*"
if %errorlevel% EQU 0 goto OK
pause
:OK