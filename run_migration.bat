@echo off
cd /d C:\BLB3D_Production\backend
set DATABASE_URL=postgresql://postgres:Admin@localhost:5432/filaops_prod
echo Checking current migration... > C:\BLB3D_Production\migration_output.txt 2>&1
C:\BLB3D_Production\backend\venv\Scripts\python.exe -m alembic current >> C:\BLB3D_Production\migration_output.txt 2>&1
echo. >> C:\BLB3D_Production\migration_output.txt 2>&1
echo Migration history (last 10): >> C:\BLB3D_Production\migration_output.txt 2>&1
C:\BLB3D_Production\backend\venv\Scripts\python.exe -m alembic history -r -10:head >> C:\BLB3D_Production\migration_output.txt 2>&1
echo. >> C:\BLB3D_Production\migration_output.txt 2>&1
echo Heads: >> C:\BLB3D_Production\migration_output.txt 2>&1
C:\BLB3D_Production\backend\venv\Scripts\python.exe -m alembic heads >> C:\BLB3D_Production\migration_output.txt 2>&1
