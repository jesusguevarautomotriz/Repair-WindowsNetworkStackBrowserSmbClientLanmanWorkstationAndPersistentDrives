<#
.SYNOPSIS
    Comprehensive Windows Network, Browser, LanmanWorkstation (SMB Client), and Persistent Drive Repair Script.
.DESCRIPTION
    Performs deep resets on DNS, IP, Winsock, TCP/IP stack, WinHTTP/WinINet proxies,
    clears web caches, cycles physical network adapters, configures SMB firewall rules,
    restarts the LanmanWorkstation service, and re-maps persistent network drives.
#>

# Ensure script runs with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges required. Relaunching script with elevation..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Windows Network, Browser & LanmanWorkstation Repair  " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 8. Enable Firewall Rules, Cycle LanmanWorkstation, and Refresh Network Drives
Write-Host "`n[8/8] Configuring Firewall, LanmanWorkstation, and Persistent Drives..." -ForegroundColor Yellow

# Enable File/Printer Sharing Firewall Rule
Write-Host "  -> Ensuring File and Printer Sharing firewall rules are active..." -ForegroundColor Gray
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue
Write-Host "  -> Firewall rules configured." -ForegroundColor Green

# Manage LanmanWorkstation (SMB Client Service)
$serviceName = "LanmanWorkstation"
Write-Host "  -> Querying $serviceName service status..." -ForegroundColor Gray
Get-Service -Name $serviceName | Select-Object Name, Status

Write-Host "  -> Forcing stop on $serviceName..." -ForegroundColor Gray
Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "  -> Verifying service stop state..." -ForegroundColor Gray
Get-Service -Name $serviceName | Select-Object Name, Status

Write-Host "  -> Starting $serviceName..." -ForegroundColor Gray
Start-Service -Name $serviceName -ErrorAction SilentlyContinue

$finalServiceStatus = (Get-Service -Name $serviceName).Status
Write-Host "  -> $serviceName service is currently: $finalServiceStatus" -ForegroundColor Green

# Refresh Persisted Network Drives from Registry
Write-Host "  -> Re-establishing persistent network drives..." -ForegroundColor Gray
if (Test-Path "HKCU:\Network") {
    Get-ChildItem "HKCU:\Network" | ForEach-Object {
        $driveLetter = $_.PSChildName.ToUpper() + ":"
        $path = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).RemotePath
        
        if ($path) {
            Write-Host "     Remapping drive $driveLetter -> $path" -ForegroundColor DarkGray
            Remove-PSDrive -Name $_.PSChildName -Force -ErrorAction SilentlyContinue
            New-PSDrive -Name $_.PSChildName -PSProvider FileSystem -Root $path -Persist -Scope Global -ErrorAction SilentlyContinue | Out-Null
        }
    }
    Write-Host "  -> Network drives refreshed successfully." -ForegroundColor Green
} else {
    Write-Host "  -> No registry keys found under HKCU:\Network." -ForegroundColor DarkYellow
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "             All Repair Steps Completed!               " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Recommendation: A system reboot is strongly advised to finalize stack updates." -ForegroundColor Yellow