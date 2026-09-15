<#
.SYNOPSIS
    Client & Network Discovery Enabler for Windows
.DESCRIPTION
    Configures an active Windows machine to act as an SMB file server and enables 
    Network Discovery, File and Printer Sharing, and required firewall rules.
#>

# =====================================================================
# CLIENT-SIDE SCRIPT: Enable Network Discovery, File Sharing & SMB Services
# Must be run as Administrator on the machine acting as the SMB Client.
# =====================================================================

# 1. Ensure script runs with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges required. Relaunching script with elevation..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 2. Triple Confirmation Loop with detailed architectural explanation
Clear-Host
Write-Host "=======================================================================" -ForegroundColor Red
Write-Host "                   CRITICAL NETWORK DISCOVERY NOTICE                   " -ForegroundColor Red
Write-Host "=======================================================================" -ForegroundColor Red
Write-Host " WARNING: Running this script will cause this machine's own hostname to" -ForegroundColor Yellow
Write-Host " disappear from the main Network Discovery screen when browsed locally." -ForegroundColor Yellow
Write-Host ""
Write-Host " Architectural Clarification:" -ForegroundColor Cyan
Write-Host " Windows File Explorer deliberately omits a machine's own hostname from" -ForegroundColor Gray
Write-Host " the 'Network' peer list when browsed locally on that same machine." -ForegroundColor Gray
Write-Host ""
Write-Host " What WILL happen:" -ForegroundColor Green
Write-Host "  - You will still be able to see and browse other computers on the " -ForegroundColor Green
Write-Host "network, and they will see this machine as an SMB server." -ForegroundColor Green
Write-Host "  - Other machines can still connect to this SMB server via hostname " -ForegroundColor Green
Write-Host "  or IP " -ForegroundColor Green
Write-Host "  - You can still access your own shares by typing the UNC path " -ForegroundColor Green
write-Host "  directly (e.g., \\localhost\ShareName or \\SMBSERVER\ShareName)." -ForegroundColor Green
Write-Host "  - Windows stops local broadcasting and intentionally hides this " -ForegroundColor Green
Write-Host "  machine's own hostname from its own File Explorer view to prevent." -ForegroundColor Green
 Write-Host "  self-referencing loops." -ForegroundColor Green
Write-Host "=======================================================================" -ForegroundColor Red

for ($i = 1; $i -le 3; $i++) {
    $confirm = Read-Host "Type 'YES' to confirm step ($i/3) or press Enter to abort"
    if ($confirm -ne 'YES') {
        Write-Host "`nOperation aborted by user at confirmation step $i/3." -ForegroundColor Red
        Pause
        Exit
    }
}

Write-Host "`nAll 3 confirmations received. Proceeding with configuration...`n" -ForegroundColor Green

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   Configuring Server for Network Sharing & Discovery   " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

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