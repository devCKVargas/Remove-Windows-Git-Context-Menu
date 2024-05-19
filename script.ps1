# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting administrative privileges..."
    Start-Process -Verb RunAs -FilePath 'powershell' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Define variables
$keyString = "LegacyDisable"
$registryPaths = @(
    "HKEY_CLASSES_ROOT\Directory\shell\git_gui",
    "HKEY_CLASSES_ROOT\Directory\shell\git_shell",
    "HKEY_CLASSES_ROOT\LibraryFolder\background\shell\git_gui",
    "HKEY_CLASSES_ROOT\LibraryFolder\background\shell\git_shell",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\background\shell\git_gui",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Directory\background\shell\git_shell"
)

# Check if any registry key already exists
$existingKeys = @()
foreach ($path in $registryPaths) {
    if ($null -ne (Get-ItemProperty -Path "Registry::$path" -Name $keyString -ErrorAction SilentlyContinue)) {
        $existingKeys += $path
    }
}

# Prompt user if no existing keys found
if ($existingKeys.Count -eq 0) {
    $choice = Read-Host "Disable or Enable Git context menu? (D:Disable | E:Enable | No:Press Any key)"
} else {
    # Print existing keys
    $existingKeys | ForEach-Object {
        Write-Host "'LegacyDisable' already exists in $_" -ForegroundColor Yellow
    }
    # Prompt user for action
    $choice = Read-Host "Disable or Enable Git context menu? (D:Disable | E:Enable | No:Press Any key)"
}

# Process user choice
switch ($choice.ToLower()) {
    "d" {
        $operationSuccessful = $true
        # Disable registry keys
        foreach ($path in $registryPaths) {
            try {
                if ($null -eq (Get-ItemProperty -Path "Registry::$path" -Name $keyString -ErrorAction SilentlyContinue)) {
                    New-ItemProperty -Path "Registry::$path" -Name $keyString -Value "" -PropertyType String -Force
                    # Write-Host "Added '$keyString' in $path" -ForegroundColor Blue
                }
            } catch {
                Write-Error "Failed to disable: $_"
                $operationSuccessful = $false
            }
        }
        if ($operationSuccessful) {
            Write-Host "SUCCESS: Git context menu disabled!" -ForegroundColor Green
        }
    }
    "e" {
        $operationSuccessful = $true
        # Enable registry keys
        $enableChoice = Read-Host "Do you want to enable it all back? (Y:Yes | No:Press Any key)"
        if ($enableChoice.ToLower() -eq "y") {
            foreach ($path in $existingKeys) {
                try {
                    Remove-ItemProperty -Path "Registry::$path" -Name $keyString -ErrorAction Stop
                    # Write-Host "Removed '$keyString' from $path" -ForegroundColor Blue
                } catch {
                    Write-Error "Failed to enable: $_"
                    $operationSuccessful = $false
                }
            }
            if ($operationSuccessful) {
                Write-Host "SUCCESS: Git context menu is back!" -ForegroundColor Green
            }
        } else {
            Write-Host "No action taken." -ForegroundColor Yellow
        }
    }
    default {
        Write-Host "No action taken." -ForegroundColor Yellow
    }
}

Pause
