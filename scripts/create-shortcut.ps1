# FilaOps Desktop Shortcut Creator
# Run this script to create a desktop shortcut for FilaOps

param(
    [string]$InstallPath = "C:\BLB3D_Production"
)

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\FilaOps.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoExit -Command `"cd $InstallPath; docker-compose up`""
$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.IconLocation = "$InstallPath\docs\filaops.ico"
$Shortcut.Description = "Start FilaOps ERP"
$Shortcut.Save()

Write-Host "Desktop shortcut created!" -ForegroundColor Green
Write-Host "Double-click 'FilaOps' on your desktop to start the application."
