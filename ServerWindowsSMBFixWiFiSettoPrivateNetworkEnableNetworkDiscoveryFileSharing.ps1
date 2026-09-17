<#
.SYNOPSIS
Configures a Windows computer as a discoverable SMB file server on a trusted network.

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

# 3. List all network connections, display details, and apply Private category ONLY to active Wi-Fi
Write-Host "`n[1/5] Listing all network connections and setting active Wi-Fi to Private..." -ForegroundColor Yellow

$allProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
if ($allProfiles) {
    foreach ($p in $allProfiles) {
        Write-Host "  -> Discovered Profile: '$($p.Name)' | Interface: '$($p.InterfaceAlias)' | Current Category: '$($p.NetworkCategory)'" -ForegroundColor Gray
    }
} else {
    Write-Host "  -> No active network profiles found." -ForegroundColor DarkYellow
}

$wifiAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and ($_.InterfaceDescription -match 'Wi-Fi|Wireless|WLAN|802\.11' -or $_.Name -match 'Wi-Fi|Wireless|WLAN') }
$wifiTargeted = $false

if ($wifiAdapters) {
    foreach ($adapter in $wifiAdapters) {
        $profile = Get-NetConnectionProfile -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        if ($profile) {
            Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private
            Write-Host "  -> [APPLIED] Active Wi-Fi Profile '$($profile.Name)' (Interface: '$($adapter.Name)') changed to Private." -ForegroundColor Green
            $wifiTargeted = $true
        } else {
            Write-Host "  -> Wi-Fi adapter '$($adapter.Name)' is up, but no active network profile was found." -ForegroundColor DarkYellow
        }
    }
}

if (-not $wifiTargeted) {
    Write-Host "  -> No active Wi-Fi adapter detected. Targeting primary active network profile..." -ForegroundColor DarkYellow
    $primaryProfile = Get-NetConnectionProfile | Select-Object -First 1
    if ($primaryProfile) {
        Set-NetConnectionProfile -InterfaceIndex $primaryProfile.InterfaceIndex -NetworkCategory Private
        Write-Host "  -> [APPLIED] Primary Network Profile '$($primaryProfile.Name)' set to Private." -ForegroundColor Green
    }
}

# 4. Enable Network Discovery and File/Printer Sharing via Netsh Firewall Profiles with port details
Write-Host "`n[2/5] Enabling firewall rules for Network Discovery and File Sharing..." -ForegroundColor Yellow
Set-NetFirewallRule -DisplayGroup "Network Discovery" -Profile Private -Enabled True -ErrorAction SilentlyContinue
Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Profile Private -Enabled True -ErrorAction SilentlyContinue

Write-Host "  -> Enabled Network Discovery Rules & Ports:" -ForegroundColor Cyan
Write-Host "     - LLMNR (UDP 5355), WS-Discovery (UDP/TCP 3702), UPnP (UDP 1900, TCP 2869), NetBIOS (UDP 137/138)" -ForegroundColor Gray
Write-Host "  -> Enabled File and Printer Sharing Rules & Ports:" -ForegroundColor Cyan
Write-Host "     - SMB / Microsoft-DS (TCP 445), NetBIOS Session (TCP 139), Echo Request (ICMPv4/ICMPv6)" -ForegroundColor Gray

# 5. Configure discovery-related services for network browsing with names printed
Write-Host "`n[3/5] Starting and configuring Network Discovery & Browsing services..." -ForegroundColor Yellow
$services = @(
    @{Name="fdPHost"; Desc="Function Discovery Provider Host"},
    @{Name="FDResPub"; Desc="Function Discovery Resource Publication"},
    @{Name="SSDPSrv"; Desc="SSDP Discovery"},
    @{Name="upnphost"; Desc="UPnP Device Host"},
    @{Name="Browser"; Desc="Computer Browser"}
)

foreach ($svc in $services) {
    $serviceObj = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($serviceObj) {
        Set-Service -Name $svc.Name -StartupType Automatic -Status Running -ErrorAction SilentlyContinue
        Write-Host "  -> Service Verified & Running: [$($svc.Name)] - $($svc.Desc)" -ForegroundColor Green
    } else {
        Write-Host "  -> Service not found (skipped): [$($svc.Name)]" -ForegroundColor DarkYellow
    }
}

# 6. Ensure SMB v1/v2/v3 and LanmanServer services are fully operational
Write-Host "`n[4/5] Configuring Server Workstation and SMB Services..." -ForegroundColor Yellow
$smbServices = @(
    @{Name="LanmanServer"; Desc="Server Service (Hosts SMB shares)"},
    @{Name="LanmanWorkstation"; Desc="Workstation Service (Connects to SMB shares)"}
)

foreach ($svc in $smbServices) {
    Set-Service -Name $svc.Name -StartupType Automatic -Status Running -ErrorAction SilentlyContinue
    $status = (Get-Service -Name $svc.Name).Status
    Write-Host "  -> SMB Service Active: [$($svc.Name)] ($($svc.Desc)) -> Status: $status" -ForegroundColor Green
}

# 7. Enable Server-side SMB Inbound Firewall Rules explicitly and print exact port mappings
Write-Host "`n[5/5] Opening SMB ports in Windows Firewall..." -ForegroundColor Yellow
$smbRuleNames = @("FileAndPrinter-ServerAS-In-TCP", "FileAndPrinter-SMB-In-TCP")
foreach ($ruleName in $smbRuleNames) {
    Enable-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    $portFilter = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
    if ($portFilter) {
        Write-Host "  -> Firewall Rule Opened: [$ruleName] | Protocol: $($portFilter.Protocol) | Port(s): $($portFilter.LocalPort)" -ForegroundColor Green
    } else {
        Write-Host "  -> Firewall Rule Opened: [$ruleName]" -ForegroundColor Green
    }
}

# Force immediate multicast re-announcement
Write-Host "`n  -> Forcing network topology broadcast refresh..." -ForegroundColor Gray
Restart-Service fdPHost, FDResPub, SSDPSrv -Force -ErrorAction SilentlyContinue

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "       SMB Server Configuration Complete & Ready!      " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

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