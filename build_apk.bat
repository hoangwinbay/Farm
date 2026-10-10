@echo off
chcp 65001 > nul
echo ===================================================
echo   DANG DONG GOI APK FLUFFY FARM...
echo ===================================================

set GODOT_BIN=D:\Godot_v4.7.2-stable_win64.exe
set PROJECT_DIR=D:\Farm
set OUTPUT_APK=D:\Farm\build\Fluffy Farm.apk
set LDCONSOLE=D:\LDPlayer\LDPlayer9\ldconsole.exe

rem 1. Xuat file APK moi bang Godot
echo [1/3] Dang build file APK moi tu source code...
"%GODOT_BIN%" --headless --path "%PROJECT_DIR%" --export-release "Android" "%OUTPUT_APK%"
if %ERRORLEVEL% NEQ 0 (
    echo [LOI] Xuat APK that bai!
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Xuat APK thanh cong: %OUTPUT_APK%

rem 2. Tu dong cap nhat vao LDPlayer neu dang mo
if exist "%LDCONSOLE%" (
    echo [3/3] Dang tu dong cai dat va mo lai tren LDPlayer...
    "%LDCONSOLE%" installapp --name "LDPlayer" --filename "%OUTPUT_APK%" > nul 2>&1
    "%LDCONSOLE%" runapp --name "LDPlayer" --packagename "vn.quocdat.nongtraiviet" > nul 2>&1
    echo Da cap nhat va khoi dong game tren LDPlayer!
)

echo ===================================================
echo   HOAN TAT!
echo ===================================================
pause
