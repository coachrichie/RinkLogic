[CmdletBinding()]
param(
    [ValidateSet("Ring1", "Ring2")]
    [string]$Ring = "Ring1",
    [switch]$UnitTest,
    [switch]$BuildOnly
)

$ErrorActionPreference = "Stop"
if ($UnitTest -and $BuildOnly) {
    throw "UnitTest and BuildOnly are mutually exclusive."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$matrixPath = Join-Path $repoRoot "watch-v2\device-matrix.json"
if (-not (Test-Path -LiteralPath $matrixPath)) {
    throw "Device matrix not found: $matrixPath"
}

$matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
$devices = @($matrix.devices | Where-Object {
    $_.ring -like "$Ring*" -and $_.status -eq "release-enabled"
})
if ($devices.Count -eq 0) {
    throw "No release-enabled devices found for $Ring."
}

$results = @()
foreach ($entry in $devices) {
    $started = Get-Date
    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $PSScriptRoot "watch-v2-build.ps1"),
        "-Device", $entry.id,
        "-DistanceModel", "PersonalCalibrationBeta"
    )
    if ($UnitTest) { $arguments += "-UnitTest" }
    & powershell @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $($entry.id)."
    }
    $results += [ordered]@{
        id = $entry.id
        ring = $entry.ring
        displayClass = $entry.displayClass
        inputClass = $entry.inputClass
        unitTest = [bool]$UnitTest
        status = "passed"
        elapsedSeconds = [math]::Round(((Get-Date) - $started).TotalSeconds, 2)
    }
}

[ordered]@{
    ring = $Ring
    deviceCount = $results.Count
    unitTest = [bool]$UnitTest
    results = $results
} | ConvertTo-Json -Depth 5 -Compress
