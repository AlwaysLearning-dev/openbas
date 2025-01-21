# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Retry logic for Chocolatey installation
$retries = 5
$success = $false

for ($i = 1; $i -le $retries; $i++) {
    try {
        Write-Host "Attempting to install Chocolatey (Attempt $i)..."
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
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

# Install Sysmon
choco install sysmon -y

# Install PowerShell 7
choco install powershell-core --version=7.1.4 -y

# Add PowerShell 7 to PATH (Optional for easier access)
$envPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
$pwshPath = "C:\Program Files\PowerShell\7"
if ($envPath -notlike "*$pwshPath*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$envPath;$pwshPath", [System.EnvironmentVariableTarget]::Machine)
}

# Download OpenBAS installer using curl and execute with PowerShell 7
Write-Host "Downloading OpenBAS installer..."
curl.exe -o C:\Windows\Temp\openbas_installer.ps1 "http://192.168.56.10:8080/api/agent/installer/openbas/windows/35356353-f346-4fbd-817a-a3d52522a2d4"

Write-Host "Installing OpenBAS with PowerShell 7..."
& "$pwshPath\pwsh.exe" -ExecutionPolicy Bypass -NoProfile -Command "& {Set-Location C:\Windows\Temp; .\openbas_installer.ps1}"

# Cleanup installer
Remove-Item C:\Windows\Temp\openbas_installer.ps1 -Force

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
