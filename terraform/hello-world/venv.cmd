@echo off
setlocal

cls

REM Get the name of the current directory
for %%I in (.) do set venv_prompt=%%~nxI

REM Check if .venv exists
if not exist ".venv\" (
    echo Creating virtual environment...
    python -m venv .venv --prompt %venv_prompt%
    call .venv\Scripts\activate
    echo Updating pip and setuptools
    python -m pip install --upgrade pip setuptools
    echo Installing dependencies...
    if exist requirements-local.txt (
        pip install -r requirements-local.txt
    ) else (
        echo No requirements-local.txt found. Skipping package installation.
    )
) else (
    echo Virtual environment found.
    call .venv\Scripts\activate
    echo Updating pip and setuptools
    python -m pip install --upgrade pip setuptools
    echo Updating dependencies...
    if exist requirements-local.txt (
        pip install --upgrade -r requirements-local.txt
    ) else (
        echo No requirements-local.txt found. Skipping package update.
    )
)

cmd /k

endlocal
