import os
import sys

# Set working directory
os.chdir(r"C:\BLB3D_Production\backend")

# Add to path
sys.path.insert(0, r"C:\BLB3D_Production\backend")

# Run alembic via subprocess
import subprocess
result = subprocess.run(
    [r"C:\BLB3D_Production\backend\venv\Scripts\python.exe", "-m", "alembic", "heads"],
    cwd=r"C:\BLB3D_Production\backend",
    capture_output=True,
    text=True
)

print("STDOUT:", result.stdout)
print("STDERR:", result.stderr)
print("RETURN CODE:", result.returncode)
