# Get the interface with IPv4 address starting with 10.0.2.x
$interface = Get-NetIPConfiguration | Where-Object {
    $_.IPv4Address.IPAddress -like "10.0.2.*"
}

# Check if the interface was found
if ($interface) {
    # Set a higher metric (lower priority) for the identified interface
    Set-NetIPInterface -InterfaceIndex $interface.InterfaceIndex -InterfaceMetric 100
    Write-Host "Set InterfaceIndex $($interface.InterfaceIndex) with IPv4 10.0.2.x to a lower priority (Metric 74)."
} else {
    Write-Host "No interface found with IPv4 address starting with 10.0.2.x."
}


# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Check if Chocolatey is already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    # Retry logic for Chocolatey installation
    $retries = 5
    $success = $false

    for ($i = 1; $i -le $retries; $i++) {
        try {
            Write-Host "Attempting to install Chocolatey (Attempt $i)..."
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $success = $true
            break
        } catch {
            Write-Host "Failed to download Chocolatey. Retrying in 10 seconds..."
            Start-Sleep -Seconds 10
        }
    }

    if (-not $success) {
        throw "Failed to install Chocolatey after $retries attempts."
    }
} else {
    Write-Host "Chocolatey is already installed."
}

# Install Sysmon (only if not already installed)
if (-not (choco list --local-only sysmon | Select-String "sysmon")) {
    Write-Host "Installing Sysmon..."
    # Install Sysmon
    choco install sysmon -y

    # Wait for Sysmon installation to complete
    Start-Sleep -Seconds 10

    # Navigate to Sysmon directory and install with auto-accept
    $sysmonPath = "C:\ProgramData\chocolatey\bin"
    if (Test-Path $sysmonPath) {
        Push-Location $sysmonPath
        Write-Host "Installing Sysmon..."
        # Auto-accept EULA and install
        Start-Process -FilePath ".\Sysmon.exe" -ArgumentList "-i", "-accepteula" -Wait -NoNewWindow
        Pop-Location
    } else {
        Write-Host "Sysmon path not found at $sysmonPath"
        throw "Sysmon installation failed"
    }
} else {
    Write-Host "Sysmon is already installed."
}

Start-Sleep -Seconds 10

# Install PowerShell 7 (only if not already installed)
$psVersion = "7.1.4"
if (-not (choco list --local-only powershell-core | Select-String $psVersion)) {
    Write-Host "Installing PowerShell 7.1.4..."
    choco install powershell-core --version=$psVersion -y
} else {
    Write-Host "PowerShell 7.1.4 is already installed."
}

Start-Sleep -Seconds 10

# Add PowerShell 7 to PATH (Optional for easier access, only if not already in PATH)
$envPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
$pwshPath = "C:\Program Files\PowerShell\7"
if ($envPath -notlike "*$pwshPath*") {
    Write-Host "Adding PowerShell 7 to PATH..."
    [System.Environment]::SetEnvironmentVariable("PATH", "$envPath;$pwshPath", [System.EnvironmentVariableTarget]::Machine)
} else {
    Write-Host "PowerShell 7 is already in PATH."
}

Start-Sleep -Seconds 10

# Download OpenBAS installer using curl and execute with PowerShell 7
Write-Host "Installing OpenBAS with PowerShell 7..."
Set-Location C:\Windows\Temp
if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') { $architecture = 'x86_64' }
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { $architecture = 'arm64' }
if ([string]::IsNullOrEmpty($architecture)) { throw "Architecture $env:PROCESSOR_ARCHITECTURE is not supported yet, please create a ticket in openbas github project" }
Stop-Service -Force -Name "OBAS Agent Service"
Invoke-WebRequest -Uri "http://10.0.2.2:8080/api/agent/package/openbas/windows/${architecture}" -OutFile "openbas-installer.exe"

Start-Sleep -Seconds 10

& "$pwshPath\pwsh.exe" -ExecutionPolicy Bypass -NoProfile -Command "& {Set-Location C:\Windows\Temp; ./openbas-installer.exe /S ~OPENBAS_URL="http://10.0.2.2:8080" ~ACCESS_TOKEN="35356353-f346-4fbd-817a-a3d52522a2d4" ~UNSECURED_CERTIFICATE=false ~WITH_PROXY=false; Start-Sleep -Seconds 1.5; rm -force ./openbas-installer.exe} "

# Add folder exclusions
Add-MpPreference -ExclusionPath "C:\Program Files (x86)\Filigran\OBAS Agent"
Add-MpPreference -ExclusionPath "C:\Program Files (x86)\Filigran\OBAS Agent\openbas-agent.exe"

# Add file exclusion
Add-MpPreference -ExclusionProcess "C:\Program Files (x86)\Filigran\OBAS Agent\openbas-agent.exe"

# Add hash exclusions
Add-MpPreference -ExclusionPath "68c1795fb45cb9b522d6cf48443fdc37"
Add-MpPreference -ExclusionPath "5f87d06f818ff8cba9e11e8cd1c6f9d990eca0f8"
Add-MpPreference -ExclusionPath "6b180913acb8cdac3fb8d3154a2f6a0bed13c056a477f4f94c4679414ec13b9f"
Add-MpPreference -ExclusionPath "6185b7253eedfa6253f26cd85c4bcfaf05195219b6ab06b43d9b07279d7d0cdd3c957bd58d36058d7cde405bc8c5084f3ac060a6080bfc18a843738d3bee87fd"

# Verify exclusions
Get-MpPreference | Select-Object -Property ExclusionPath, ExclusionProcess

# Verify network configuration
Write-Host "Final network configuration:"
Get-NetIPInterface | Where-Object {$_.AddressFamily -eq "IPv4"} | Select-Object InterfaceAlias, InterfaceMetric
