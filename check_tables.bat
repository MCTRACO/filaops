@echo off
cd /d C:\BLB3D_Production\backend
C:\BLB3D_Production\backend\venv\Scripts\python.exe C:\BLB3D_Production\check_tables.py > C:\BLB3D_Production\tables_output.txt 2>&1
