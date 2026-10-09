[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Device,
    [switch]$UnitTest,
    [string]$TestName
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sdkConfig = Join-Path $env:APPDATA "Garmin\ConnectIQ\current-sdk.cfg"

if (-not (Test-Path -LiteralPath $sdkConfig)) {
    throw "Connect IQ SDK configuration not found: $sdkConfig"
}

$sdkRoot = (Get-Content -LiteralPath $sdkConfig -Raw).Trim()
if (-not (Test-Path -LiteralPath (Join-Path $sdkRoot "bin\monkeyc.bat"))) {
    throw "Connect IQ compiler not found in active SDK: $sdkRoot"
}

if ([string]::IsNullOrWhiteSpace($env:SHIFTSENSE_DEVELOPER_KEY)) {
    throw "SHIFTSENSE_DEVELOPER_KEY must point to the Connect IQ developer key."
}

Push-Location $repoRoot
try {
    $outputDirectory = Join-Path $repoRoot "watch\bin\$Device"
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $unitArgs = @()
    if ($UnitTest) {
        $unitArgs += "-t"
    }

    & "$sdkRoot\bin\monkeyc.bat" -f watch\monkey.jungle -d $Device -o "watch\bin\$Device\ShiftSense.prg" -y $env:SHIFTSENSE_DEVELOPER_KEY @unitArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    if ($UnitTest) {
        if (-not (Get-Process -Name simulator -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath "$sdkRoot\bin\simulator.exe" -WindowStyle Hidden
            Start-Sleep -Seconds 2
        }

        $testArgs = @("watch\bin\$Device\ShiftSense.prg", $Device, "/t")
        if (-not [string]::IsNullOrWhiteSpace($TestName)) {
            $testArgs += $TestName
        }
        & "$sdkRoot\bin\monkeydo.bat" @testArgs
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
}
finally {
    Pop-Location
}
