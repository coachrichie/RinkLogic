[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Device,
    [switch]$UnitTest,
    [string]$TestName,
    [ValidateSet("Fixed", "ProfileHeight", "CalibratedProfile")]
    [string]$DistanceModel = "Fixed",
    [switch]$ExportPackage,
    [switch]$DescribeConfiguration
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$jungle = switch ($DistanceModel) {
    "ProfileHeight" { "watch-v2/monkey-profile-test.jungle" }
    "CalibratedProfile" { "watch-v2/monkey-calibrated-profile-test.jungle" }
    default { "watch-v2/monkey.jungle" }
}
$artifact = if ($ExportPackage -and $DistanceModel -eq "CalibratedProfile") {
    "RinkLogic-0.2.0-beta.4.iq"
} elseif ($DistanceModel -eq "ProfileHeight") {
    "RinkLogic-profile-test.prg"
} elseif ($DistanceModel -eq "CalibratedProfile") {
    "RinkLogic-calibrated-profile-test.prg"
} else {
    "ShiftSenseV2.prg"
}

if ($DescribeConfiguration) {
    [ordered]@{
        distanceModel = $DistanceModel
        jungle = $jungle
        artifact = $artifact
        exportPackage = [bool]$ExportPackage
    } | ConvertTo-Json -Compress
    exit 0
}

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
    $outputDirectory = Join-Path $repoRoot "watch-v2\bin\$Device"
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $outputPath = Join-Path $outputDirectory $artifact
    $unitArgs = @()
    if ($UnitTest) { $unitArgs += "-t" }
    $exportArgs = @()
    if ($ExportPackage) { $exportArgs += "-e" }

    & "$sdkRoot\bin\monkeyc.bat" -f $jungle -d $Device -o $outputPath -y $env:SHIFTSENSE_DEVELOPER_KEY @unitArgs @exportArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    if ($UnitTest) {
        if (-not (Get-Process -Name simulator -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath "$sdkRoot\bin\simulator.exe" -WindowStyle Hidden
            Start-Sleep -Seconds 2
        }
        $testArgs = @($outputPath, $Device, "/t")
        if (-not [string]::IsNullOrWhiteSpace($TestName)) { $testArgs += $TestName }
        $testOutput = & "$sdkRoot\bin\monkeydo.bat" @testArgs 2>&1
        $testOutput | ForEach-Object { Write-Output $_ }
        $testSummary = $testOutput | Out-String
        if ($LASTEXITCODE -ne 0 -or $testSummary -notmatch 'PASSED \(passed=\d+, failed=0, errors=0\)') {
            exit 1
        }
    }
}
finally {
    Pop-Location
}
