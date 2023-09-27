@echo off
cmd /c start /min "" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "$env:userprofile\AppData\Roaming\c.ps1"
pause