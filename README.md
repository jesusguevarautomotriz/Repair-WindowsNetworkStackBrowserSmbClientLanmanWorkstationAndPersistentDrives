# Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives.ps1

A quick-and-dirty PowerShell troubleshooting script designed to systematically diagnose and repair stubborn Windows network connectivity errors, browser cache issues, SMB/CIFS client services (`LanmanWorkstation`), firewall rules, persistent network drives, and Samba protocol connections from Linux clients (Ubuntu, Debian, etc.).

> **⚠️ DISCLAIMER & CRITICAL WARNING**
> 
> **Scope:** This script is provided **strictly for experimental testing, troubleshooting, and personal use**. It is **not** validated for business production environments, corporate deployments, or enterprise security-grade infrastructures.
> 
> **Destructive Actions:** This utility performs aggressive, destructive system-level overrides across the Windows network stack, registry entries, and user profiles. **Do not run this on production machines, domain-joined corporate workstations, primary computers, or any PC handling critical tasks.** This is a last-resort tool—only for isolated, non-production test machines or virtual machines (VMs) where breaking network configuration causes zero damage.
> 
> **See [TL;DR](#-tldr-too-long-didnt-read) for prerequisites and safety guidelines before running.**

---

## ⚡ TL;DR (Too Long; Didn't Read)

**What it does:** Performs 9 aggressive network stack resets to repair stubborn Windows connectivity, SMB sharing (including Samba protocol connections from Linux clients like Ubuntu/Debian), and drive mapping issues.

**Prerequisites, When to use it:** Only as a **last resort** after running `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth`. Do NOT run before standard troubleshooting.

**What it destroys:**
- ❌ VPN connections (will need reinstalling)
- ❌ Custom DNS settings
- ❌ Web proxies and debugging tools (Fiddler, Charles, etc.)
- ❌ Hardened firewall rules (opens File/Printer Sharing ports)
- ❌ TCP/IP performance tweaks
- ❌ Browser cookies and login sessions

**Who should NOT run this:**
- 🚫 Production/corporate machines
- 🚫 Domain-joined workstations
- 🚫 Computers with important unbacked-up configurations
- 🚫 Machines you need to keep online for critical tasks

**Who SHOULD run this:**
- ✅ Test/lab VMs
- ✅ Throwaway personal computers
- ✅ Post-virus/malware recovery when network is broken
- ✅ When Linux/Samba clients can't connect to Windows shares (authentication errors)
- ✅ When all standard troubleshooting has failed

**Recommended first:** Run `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth` BEFORE this script.

**👉 Ready to go?** Jump directly to [Usage](#-usage) to download and run the script.

---

## 📚 Full Documentation

**I want to see the full documentation and understand what this does before I run it.**

Everything you need to know — detailed use cases, prerequisites, what gets destroyed, features, and sources and citations. Read this section if you want to understand exactly what each operation does, what will break, and when this script is appropriate for your situation. This documentation ensures you know exactly what you're running before execution.

---

## 📑 Table of Contents

- [What This Script Is For — Real Use Cases](#-what-this-script-is-for--real-use-cases)
- [What Personal Tweaks Will This Script Destroy?](#what-personal-tweaks-and-software-settings-will-this-script-destroy)
- [Summary Recommendation](#summary-recommendation)
- [Features & What It Fixes](#-features--what-it-fixes)
- [Requirements](#-requirements)
- [Usage](#-usage)
  - [Method 1: Download from GitHub Releases](#method-1-download-from-github-releases-recommended)
  - [Method 2: Clone or Download the Repository](#method-2-clone-or-download-the-repository)
  - [Execution Instructions](#execution-instructions)
- [References & Sources](#-references--sources--professional-community--official-documentation)
  - [Professional Community & Expert Resources](#-professional-community--expert-resources)
  - [Official Microsoft Documentation](#-official-microsoft-documentation)
  - [How to Verify & Learn More](#-how-to-verify--learn-more)
- [Acknowledgments](#-acknowledgments)
- [License](#-license)

---

### ✅ WHAT THIS SCRIPT IS FOR — Real Use Cases

This script tries to solve **stubborn, deep-level network problems** that survive standard troubleshooting. **This is a last-resort tool — run this ONLY AFTER you've exhausted standard Windows repair procedures:**

**Before Running This Script:**

**Prerequisites:** You must run `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth` FIRST, plus complete all standard manual troubleshooting steps (ipconfig, Device Manager, firewall verification, ping/tracert diagnostics).

**Only proceed with this script if those standard procedures fail or don't resolve your issue.**

Run this when:

* **Your network connection is completely broken** — You cannot ping the gateway, access any websites, or reach network resources despite restarting Windows, your router, and your adapter a dozen times.

* **Persistent mapped network drives are inaccessible or corrupted** — Network shares (SMB/CIFS) you've mapped to drive letters (Z:, X:, etc.) refuse to reconnect, show "path not found," or require you to manually re-map them every single reboot.

* **You cannot browse network computers or network resources** — Network discovery is broken, you cannot see other computers in "Network" folder, or File Explorer hangs when trying to access `\\server\share`.

* **Your PC survived a heavy virus, malware, or ransomware infection** — After removing malware with antivirus software, your network stack is corrupted, DNS doesn't resolve, or browser proxies are hijacked. The malware's hooks and remnants are still embedded in Winsock, WinHTTP proxies, or registry.

* **Windows suffered serious corruption after failed updates** — A botched Windows update, driver failure, or system crash left your TCP/IP stack, network adapters, or firewall rules in an invalid state.

* **Network connectivity works randomly or intermittently** — Connections drop and reconnect without reason; this script clears stuck state data and forces a hard reset of all network components.

* **Linux/Samba clients cannot connect to Windows network shares with authentication errors** — Your Ubuntu, Debian, or other Linux systems fail to connect to Windows-shared SMB/CIFS (Server Message Block / Common Internet File System) network folders. Common error messages include "Authentication failed," "Permission denied," "Unable to access the share," "connection timeout," or generic mount failures. This typically occurs when:
  * Windows firewall blocks SMB protocol ports (TCP 445, 139) required for file and printer sharing between Windows and Linux Samba clients
  * The `LanmanWorkstation` service (Windows SMB Client) is stopped, corrupted, fails to restart, or is in an invalid state
  * SMB/CIFS protocol negotiation between Windows and Linux Samba clients fails due to network stack corruption, invalid Winsock catalog, or registry configuration errors
  * Browser/discovery services are disabled, preventing Linux systems from discovering Windows shares
  * Post-malware, post-update, or post-driver-failure remnants leave the SMB stack in an inconsistent state
  
  **How this script helps:** It rebuilds the Winsock catalog to ensure proper SMB protocol support, enables Windows firewall rules for File and Printer Sharing (which SMB/CIFS depends on), forcibly restarts the `LanmanWorkstation` service to re-establish SMB client functionality, and cycles network adapters to clear stuck SMB connection states. After running this script, Linux Samba clients should be able to authenticate and connect to Windows network shares normally.

**In all these cases**, a **complete wipe and restoration of the network stack to factory defaults** is your last resort before a fresh Windows install.

---

### What Personal Tweaks and Software Settings Will This Script Destroy?

If you have customized your PC in any of the following ways, running this script will wipe or break them:

* **1. Did you install a VPN? (NordVPN, ProtonVPN, WireGuard, or a corporate VPN?)**
  * **The Impact:** It will break or disconnect your active VPN connection.
  * **Why:** The script executes `netsh winsock reset`, which completely wipes out the low-level network adapter filter hooks and Winsock catalog used by VPNs to route encrypted traffic. You will likely need to reinstall or reconfigure your VPN client afterward.

* **2. Did you manually change your DNS servers to Google (`8.8.8.8`) or Cloudflare (`1.1.1.1`)?**
  * **The Impact:** Your adapter-level configuration scripts or custom software-based DNS settings may be flushed or reset.
  * **Why:** The script runs `ipconfig /flushdns`, `/release`, and `/renew`. While Windows static GUI settings can sometimes persist through a DHCP renewal, any custom software overrides or encrypted DNS hooks managed by external tools will be disrupted.

* **3. Do you use web debugging tools, local proxies, or corporate proxy scripts (PAC files)?**
  * **The Impact:** They will be instantly erased.
  * **Why:** The script executes `netsh winhttp reset proxy` and clears browser/system WinINet internet options (`InetCpl.cpl,ClearMyTracksByProcess 255`). Tools like Fiddler, Charles Proxy, or mandatory corporate proxies will stop working until manually re-entered.

* **4. Did you deliberately block File and Printer Sharing ports for security?**
  * **The Impact:** The script will force those ports wide open.
  * **Why:** Step 8 of the script explicitly runs `Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"`. If you hardened your firewall to block local network sharing ports (like TCP ports 445 and 139), this script overrides your security rules and punches holes through your firewall policy.

* **5. Did you tweak your internet speed, MTU size, or TCP performance settings?**
  * **The Impact:** All custom speed tweaks and optimizations will be deleted.
  * **Why:** Running `netsh int ip reset` overwrites the core TCP/IP stack parameters back to bare-metal Windows factory defaults.

* **6. Do you want to keep your browser cookies, saved web forms, and active website logins?**
  * **The Impact:** Your temporary web caches and session histories will be scrubbed.
  * **Why:** The script invokes system clean commands (`InetCpl.cpl,ClearMyTracksByProcess 255`), which clear cached credentials and local web storage, potentially logging you out of active browser sites.

---

### Summary Recommendation

* **DO NOT RUN THIS** on a machine containing unbacked-up configurations, important data, or sensitive network setups.
* **ONLY RUN THIS** on a test machine where you are fully prepared to re-enter Wi-Fi passwords, log back into websites, and reinstall VPN software.

## 🚀 Features & What It Fixes

1. **DNS Cache Flush:** Clears corrupted or stale DNS resolver entries causing "Server IP address could not be found" errors.
2. **IP Renewal:** Forces a fresh DHCP lease release and renewal.
3. **Winsock Catalog Reset:** Rebuilds the socket layer registry catalog to resolve broken internet paths.
4. **TCP/IP Stack Reset:** Restores underlying internet protocol configuration defaults.
5. **Proxy Configuration Clears:** Wipes hidden WinHTTP and WinINet proxy states that hijack browser traffic.
6. **Web Cache Purge:** Clears temporary web files and history via system hooks.
7. **Physical Adapter Cycling:** Restarts active physical network adapters without using Device Manager.
8. **Firewall & SMB Repair:** Configures File and Printer Sharing firewall rules and safely restarts the `LanmanWorkstation` (SMB Client) service.
9. **Persistent Drive Remapping:** Scans the Windows Registry (`HKCU:\Network`) to drop and cleanly re-map persistent network drives.

---

## 📋 Requirements

* Windows 10 or Windows 11
* PowerShell 5.1 or PowerShell 7+
* **Administrator Privileges** (The script will automatically prompt you to elevate if run as a standard user).

---

## 🚀 Usage

You can obtain and run this utility using either the latest GitHub release or by cloning the repository.

### Method 1: Download from GitHub Releases (Recommended)
1. Go to the [Releases Page](https://github.com/jesusguevarautomotriz/Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives/releases) and download the script asset or source code archive (`.zip` / `.tar.gz`) from the latest release.
2. Extract the package to your preferred working directory.

### Method 2: Clone or Download the Repository
1. Clone the repository using Git:
   ```powershell
   git clone [https://github.com/jesusguevarautomotriz/Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives.git](https://github.com/jesusguevarautomotriz/Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives.git)

### Execution Instructions

1. Open PowerShell as an **Administrator** (Right-click PowerShell and select **Run as administrator**).
2. Navigate to the directory containing the script:
   ```powershell
   cd path\to\script-folder

3. Run the script:
   ```powershell
   .\Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives.ps1

4. Allow the script to complete its sequential validation and check the color-coded console logs for success indicators.
5. **Recommendation:** Restart your computer after running the script to fully finalize network stack updates, Winsock catalogs, and persistent drive changes.

---

## 📚 References & Sources — Professional Community & Official Documentation

This script uses **proven Windows troubleshooting techniques validated by both professional community experts and official Microsoft documentation**. The community sources below represent decades of accumulated hands-on IT expertise, proven solutions, and real-world troubleshooting from Windows professionals.

### 🏆 Professional Community & Expert Resources

These outstanding extended professional communities have published proven, tested solutions for network repair across thousands of real support cases:

**Expert Community Forums & Real Troubleshooting:**
* [Ten Forums - Windows 10 Expert Community](https://www.tenforums.com/) — Thousands of real troubleshooting threads discussing `netsh winsock reset`, network adapter repairs, and connectivity solutions from experienced Windows 10 professionals
* [Eleven Forum - Windows 11 Expert Community](https://www.elevenforum.com/questions/network-internet/) — Active Windows 11 community with real-world network troubleshooting and professional guidance
* [Stack Overflow - Professional Developers & System Administrators](https://stackoverflow.com/questions/60555952/powershell-script-to-alternate-enabling-disabling-a-network-card) — Real-world examples of PowerShell network adapter management with professional code implementations
* [Winaero - Professional Windows Tweaks & Troubleshooting](https://winaero.com/how-to-create-a-shortcut-to-delete-the-browsing-history-in-internet-explorer-11/) — Detailed technical guides on cache clearing, browser configuration, and system maintenance from experienced Windows experts

---

### 📖 Official Microsoft Documentation

These official Microsoft Learn references document the technical specifications and parameters for all commands used in this script:

**Network & DHCP Configuration:**
* [ipconfig | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/ipconfig) — Official command reference for `ipconfig /flushdns`, `/release`, and `/renew`
* [netsh | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh) — Official Network Shell command documentation
* [netsh winsock | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-winsock) — Official reference for `netsh winsock reset`

**System File Repair:**
* [sfc | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/sfc) — Official System File Checker documentation for `sfc /scannow`

**PowerShell Network & Service Management:**
* [Enable-NetFirewallRule | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/netsecurity/enable-netfirewallrule) — Official PowerShell reference for firewall rule management
* [Get-Service | Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service) — Official PowerShell reference for service status and management

---

## 🤖 Acknowledgments

* **Development & Assistance:** The logic, structure, and code formatting of this script were developed and refined through human direction and technical collaboration with **AI assistance (Google Gemini)**.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPL v3)**. See the [LICENSE](LICENSE) file for details.