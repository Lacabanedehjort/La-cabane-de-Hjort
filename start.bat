@echo off

:: Verifier que Git Bash est installe
if not exist "C:\Program Files\Git\bin\bash.exe" (
    echo.
    echo  [ERREUR] Git n'est pas installe sur ce PC.
    echo.
    echo  Pour installer Git :
    echo  1. Va sur https://git-scm.com/download/win
    echo  2. Telecharge et installe Git pour Windows
    echo  3. Relance ce fichier start.bat
    echo.
    pause
    exit /b 1
)

:: Lancer le script dans Git Bash
set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:=/%
set SCRIPT_DIR=%SCRIPT_DIR::=%
start "La Cabane de Hjort - Deploy" "C:\Program Files\Git\bin\bash.exe" -l -c "cd '/%SCRIPT_DIR%' && bash scripts/build-deploy.sh; read -p 'Appuie sur Entree pour fermer...'"