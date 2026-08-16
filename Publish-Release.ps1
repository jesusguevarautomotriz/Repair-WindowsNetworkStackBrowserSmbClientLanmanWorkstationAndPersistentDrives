# Publish-Release.ps1
param(
    [string]$CommitMessage = "Automated release update"
)

# 1. Ensure git changes are committed
git add .
git commit -m $CommitMessage
git push origin main

# 2. Fetch the latest tag from remote or local
$latestTag = git describe --tags --abbrev=0 2>$null

if (-not $latestTag) {
    # Fallback if no tags exist yet
    $newTag = "26.08_experimental_v0.0.1"
} else {
    Write-Host "Latest existing tag: $latestTag" -ForegroundColor Cyan
    
    # Extract the patch number using regex (e.g., v0.0.3 -> 3)
    if ($latestTag -match 'v0\.0\.(\d+)$') {
        $currentPatch = [int]$Matches[1]
        $nextPatch = $currentPatch + 1
        $newTag = "26.08_experimental_v0.0.$nextPatch"
    } else {
        Write-Error "Could not parse patch version from tag: $latestTag. Please create the tag manually."
        exit
    }
}

Write-Host "Generated new automated tag: $newTag" -ForegroundColor Green

# 3. Create the GitHub Release automatically using GitHub CLI
$scriptFileName = "Repair-WindowsNetworkStackBrowserSmbClientLanmanWorkstationAndPersistentDrives.ps1"
gh release create $newTag $scriptFileName --title "$newTag" --notes "Automated release containing recent diagnostic improvements and script enhancements." --prerelease

Write-Host "Successfully published release: $newTag" -ForegroundColor Cyan