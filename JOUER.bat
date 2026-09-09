@echo off
set "GODOT=C:\Users\Utilisateur\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
set "GAME_DIR=%~dp0"

if not exist "%GODOT%" (
  echo Godot est introuvable:
  echo %GODOT%
  pause
  exit /b 1
)

start "" "%GODOT%" --path "%GAME_DIR%"
