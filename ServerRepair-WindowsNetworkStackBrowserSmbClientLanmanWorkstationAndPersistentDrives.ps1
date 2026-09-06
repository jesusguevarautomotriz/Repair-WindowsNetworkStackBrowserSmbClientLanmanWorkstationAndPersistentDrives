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

# 1. Flush DNS Resolver Cache
Write-Host "`n[1/8] Flushing DNS Resolver Cache..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
Write-Host "  -> DNS cache cleared successfully." -ForegroundColor Green

# 2. Release and Renew IP Address
Write-Host "`n[2/8] Releasing and Renewing IP Address..." -ForegroundColor Yellow
ipconfig /release | Out-Null
Start-Sleep -Seconds 2
ipconfig /renew | Out-Null
Write-Host "  -> IP configuration updated successfully." -ForegroundColor Green

# 3. Reset Winsock Catalog
Write-Host "`n[3/8] Resetting Winsock Catalog (Socket Layer Repair)..." -ForegroundColor Yellow
netsh winsock reset | Out-Null
Write-Host "  -> Winsock catalog reset successfully." -ForegroundColor Green

# 4. Reset TCP/IP Stack
Write-Host "`n[4/8] Resetting TCP/IP Stack..." -ForegroundColor Yellow
netsh int ip reset | Out-Null
Write-Host "  -> TCP/IP stack reset successfully." -ForegroundColor Green

# 5. Reset WinHTTP Proxy Settings
Write-Host "`n[5/8] Resetting WinHTTP Proxy Configuration..." -ForegroundColor Yellow
netsh winhttp reset proxy | Out-Null
Write-Host "  -> WinHTTP proxy cleared successfully." -ForegroundColor Green

# 6. Reset WinINet Proxy & Clear Temporary Web Files
Write-Host "`n[6/8] Clearing WinINet Cache and Resetting Internet Options..." -ForegroundColor Yellow
Start-Process -FilePath "RunDll32.exe" -ArgumentList "InetCpl.cpl,ClearMyTracksByProcess 255" -Wait -NoNewWindow
Write-Host "  -> Web cache and proxy parameters wiped." -ForegroundColor Green

# 7. Restart Active Physical Network Adapters
Write-Host "`n[7/8] Cycling Active Physical Network Adapters..." -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Virtual|VPN|Bluetooth|Loopback' }

if ($adapters) {
    foreach ($adapter in $adapters) {
        Write-Host "  -> Restarting adapter: $($adapter.Name)" -ForegroundColor Gray
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        Start-Sleep -Seconds 1
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false
    }
    Write-Host "  -> Network adapters recycled successfully." -ForegroundColor Green
} else {
    Write-Host "  -> No active physical adapters found to cycle." -ForegroundColor DarkYellow
}

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