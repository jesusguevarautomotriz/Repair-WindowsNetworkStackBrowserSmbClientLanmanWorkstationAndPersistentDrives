# Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives.ps1

A quick-and-dirty PowerShell troubleshooting script designed to systematically diagnose and repair stubborn Windows network connectivity errors, browser cache issues, SMB client services (`LanmanWorkstation`), firewall rules, and persistent network drives.

> **⚠️ Disclaimer & Scope:** 
> This script is provided **strictly for experimental testing, troubleshooting, and personal use**. It is **not** validated, tested, or suitable for business production environments, corporate deployments, or enterprise security-grade infrastructures. Use at your own discretion in personal lab or home environments.

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
1. Go to the [Releases Page](https://github.com/jesusguevarautomotriz/Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives/releases) and download the script asset or source code archive (`.zip` / `.tar.gz`) from the latest `26.08_experimental_v0.0.2` release.
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

## 🤖 Acknowledgments

* **Development & Assistance:** The logic, structure, and code formatting of this script were developed and refined through human direction and technical collaboration with **AI assistance (Google Gemini)**.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPL v3)**. See the [LICENSE](LICENSE) file for details.