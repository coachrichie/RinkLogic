[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$version = "8.29.1"
$archiveName = "gitleaks_${version}_windows_x64.zip"
$expectedSha256 = "e4b7d556f0cddbe23d10d8fac2ab0f29f68f019091c6599ffbeaa8a4fb71ac78"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$installDirectory = Join-Path $repositoryRoot ".tools\gitleaks"
$archivePath = Join-Path $installDirectory $archiveName
$downloadUrl = "https://github.com/gitleaks/gitleaks/releases/download/v$version/$archiveName"

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath
    $actualSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256) {
        throw "Gitleaks archive checksum mismatch."
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $installDirectory -Force
}
finally {
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
}

$executable = Join-Path $installDirectory "gitleaks.exe"
if (-not (Test-Path -LiteralPath $executable)) {
    throw "Gitleaks executable was not installed."
}

& $executable version
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
