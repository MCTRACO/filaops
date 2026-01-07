# FilaOps Windows Installer

This folder contains everything needed to build a Windows installer for FilaOps.

## Prerequisites

1. **Inno Setup 6.x** - Download from https://jrsoftware.org/isinfo.php
2. **Icon file** - Place `filaops.ico` in `assets/` folder

## Building the Installer

### Option 1: GUI
1. Open `FilaOpsSetup.iss` in Inno Setup Compiler
2. Click Build → Compile
3. Find output in `output/FilaOpsSetup-{version}.exe`

### Option 2: Command Line
```cmd
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" FilaOpsSetup.iss
```

## What the Installer Does

1. **Checks for Docker Desktop** - Shows instructions if not installed
2. **Copies FilaOps files** - Backend, frontend, docker-compose, etc.
3. **Creates .env** - Copies from .env.example if not exists
4. **Creates shortcuts**:
   - Start Menu: FilaOps, Start, Stop, Open
   - Desktop icon (optional)
   - Startup entry (optional)
5. **Launches FilaOps** - Optional post-install

## Scripts Included

| Script | Purpose |
|--------|---------|
| `Check-Docker.ps1` | Verifies Docker Desktop is installed and running |
| `Start-FilaOps.ps1` | Starts containers, waits for healthy, opens browser |
| `Stop-FilaOps.ps1` | Stops containers gracefully |
| `Open-FilaOps.ps1` | Opens browser, starts containers if needed |
| `Update-FilaOps.ps1` | Updates to latest version with backup |

## Creating the Launcher EXE

The `FilaOpsLauncher.exe` is a simple wrapper that:
1. Checks if FilaOps is running
2. If yes: opens browser
3. If no: runs Start-FilaOps.ps1

You can create this using:

### Option A: PowerShell to EXE converter
Use PS2EXE: https://github.com/MScholtes/PS2EXE

```powershell
Install-Module ps2exe
Invoke-PS2EXE -InputFile "scripts\Open-FilaOps.ps1" -OutputFile "scripts\FilaOpsLauncher.exe" -IconFile "assets\filaops.ico" -NoConsole
```

### Option B: Simple batch file wrapper
Create `FilaOpsLauncher.bat`:
```batch
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\Open-FilaOps.ps1"
```

Then convert to EXE with Bat to Exe Converter.

## Customization

### Version
Update `#define MyAppVersion` in `FilaOpsSetup.iss`

### Icon
Replace `assets/filaops.ico` with your icon (256x256 recommended)

### Publisher Info
Update `#define MyAppPublisher` and URLs in `FilaOpsSetup.iss`

## Testing

Before distributing:

1. Test on a clean Windows VM
2. Test with Docker Desktop not installed (should show instructions)
3. Test with Docker Desktop stopped (should prompt to start)
4. Test upgrade path using Update-FilaOps.ps1
5. Test uninstall (should stop containers first)

## File Structure

```
installer/
├── FilaOpsSetup.iss      # Inno Setup script
├── README.md             # This file
├── assets/
│   └── filaops.ico       # Application icon
├── scripts/
│   ├── Check-Docker.ps1
│   ├── Start-FilaOps.ps1
│   ├── Stop-FilaOps.ps1
│   ├── Open-FilaOps.ps1
│   ├── Update-FilaOps.ps1
│   └── FilaOpsLauncher.exe
└── output/               # Built installers go here
    └── FilaOpsSetup-x.x.x.exe
```
