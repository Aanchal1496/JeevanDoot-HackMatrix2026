@echo off
REM Start the JeevanDoot backend server.
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
    echo Creating virtual environment...
    python -m venv .venv
)
call .venv\Scripts\activate.bat
python -m pip install -r requirements.txt
echo Starting JeevanDoot backend on http://localhost:8000
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
