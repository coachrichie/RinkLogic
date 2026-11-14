[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [string]$Assignment,
    [switch]$DescribeConfiguration
)

$ErrorActionPreference = 'Stop'
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DistributionName = 'RinkLogic-Beta7-Test-Assistant'
$PyInstallerVersion = '6.22.3'
$Questionnaire = 'tester_assistant/resources/questionnaire.de.json'
$DeviceMatrix = 'watch-v2/device-matrix.json'
$ExampleAssignment = Join-Path $RepositoryRoot 'docs/testing/beta-test-assignment.example.json'

function Invoke-Git([string[]]$Arguments) {
    $value = & git -C $RepositoryRoot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed"
    }
    return ($value | Out-String).Trim()
}

function Get-OutputDirectory {
    if ($OutputDirectory) {
        return [System.IO.Path]::GetFullPath($OutputDirectory)
    }
    $commit = Invoke-Git @('rev-parse', '--short=12', 'HEAD')
    return Join-Path ([System.IO.Path]::GetTempPath()) "$DistributionName-$commit"
}

function Assert-OutputOutsideRepository([string]$Path) {
    $root = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $candidate = [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $inside = $candidate.Equals($root, [System.StringComparison]::OrdinalIgnoreCase) -or
        $candidate.StartsWith(
            $root + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    if ($inside) {
        throw 'OutputDirectory must be outside the tracked source tree.'
    }
}

function Get-AssignmentPath {
    if (-not $Assignment) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $Assignment -PathType Leaf)) {
        throw 'Unsupported assignment: file does not exist.'
    }
    return (Resolve-Path -LiteralPath $Assignment).Path
}

function Assert-SupportedAssignment([string]$Path) {
    $validationCode = @'
import sys
from pathlib import Path
from tester_assistant.assignment import Assignment
Assignment.load(Path(sys.argv[1]))
'@
    & python -c $validationCode $Path
    if ($LASTEXITCODE -ne 0) {
        throw 'Unsupported assignment: it does not satisfy the Beta-7 contract.'
    }
}

function Get-Configuration([string]$OutputPath, [string]$AssignmentPath) {
    $includedFiles = @($Questionnaire, $DeviceMatrix)
    if ($AssignmentPath) {
        $includedFiles += 'embedded-assignment.json'
    }
    return [ordered]@{
        python_version = '3.12'
        pyinstaller_version = $PyInstallerVersion
        entry_point = 'tester_assistant.app:main'
        mode = 'one-folder-windowed-clean-no-upx'
        distribution = $DistributionName
        resources = @($Questionnaire, $DeviceMatrix)
        outputs = @('build-manifest.json', 'SHA256SUMS.txt')
        output_directory = $OutputPath
        assignment = if ($AssignmentPath) { $AssignmentPath } else { $null }
        included_files = $includedFiles
    }
}

try {
    Push-Location $RepositoryRoot
    $output = Get-OutputDirectory
    Assert-OutputOutsideRepository $output
    $assignmentPath = Get-AssignmentPath
    if ($assignmentPath) {
        Assert-SupportedAssignment $assignmentPath
        if (
            $env:GITHUB_ACTIONS -eq 'true' -and
            -not [System.IO.Path]::GetFullPath($assignmentPath).Equals(
                [System.IO.Path]::GetFullPath($ExampleAssignment),
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            throw 'CI may embed only the committed synthetic example assignment.'
        }
    }

    if ($DescribeConfiguration) {
        Get-Configuration $output $assignmentPath | ConvertTo-Json -Depth 5 -Compress
        exit 0
    }

    $status = Invoke-Git @('status', '--porcelain', '--untracked-files=all')
    if ($status) {
        throw 'Refusing to build from a dirty Git worktree.'
    }

    $commit = Invoke-Git @('rev-parse', 'HEAD')
    $distributionPath = Join-Path $output $DistributionName
    if (Test-Path -LiteralPath $distributionPath) {
        throw "Distribution directory already exists: $distributionPath"
    }

    $pythonVersion = (& python -c 'import platform; print(platform.python_version())').Trim()
    if ($LASTEXITCODE -ne 0 -or -not $pythonVersion.StartsWith('3.12.')) {
        throw "Packaging requires Python 3.12; found $pythonVersion."
    }
    $pyinstallerVersion = (& python -m PyInstaller --version).Trim()
    if ($LASTEXITCODE -ne 0 -or $pyinstallerVersion -ne $PyInstallerVersion) {
        throw "Packaging requires PyInstaller $PyInstallerVersion; found $pyinstallerVersion."
    }

    $temporaryBuild = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) ("rinklogic-beta7-build-" + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $output -Force
    $null = New-Item -ItemType Directory -Path $temporaryBuild
    try {
        $launcher = Join-Path $temporaryBuild 'tester_assistant_entry.py'
        [System.IO.File]::WriteAllText(
            $launcher,
            "from tester_assistant.app import main`nraise SystemExit(main())`n",
            [System.Text.UTF8Encoding]::new($false)
        )
        $arguments = @(
            '-m', 'PyInstaller',
            '--noconfirm', '--onedir', '--windowed', '--clean', '--noupx',
            '--name', $DistributionName,
            '--paths', $RepositoryRoot,
            '--distpath', $output,
            '--workpath', (Join-Path $temporaryBuild 'work'),
            '--specpath', (Join-Path $temporaryBuild 'spec'),
            '--add-data', "$(Join-Path $RepositoryRoot $Questionnaire);tester_assistant/resources",
            '--add-data', "$(Join-Path $RepositoryRoot $DeviceMatrix);watch-v2",
            '--hidden-import', 'fitdecode',
            $launcher
        )
        & python @arguments
        if ($LASTEXITCODE -ne 0) {
            throw 'PyInstaller failed.'
        }

        if ($assignmentPath) {
            Copy-Item -LiteralPath $assignmentPath -Destination (
                Join-Path $distributionPath 'embedded-assignment.json'
            )
        }

        if ($env:SOURCE_DATE_EPOCH) {
            $builtAt = [DateTimeOffset]::FromUnixTimeSeconds(
                [long]$env:SOURCE_DATE_EPOCH
            ).UtcDateTime
        } else {
            $commitDate = Invoke-Git @('show', '-s', '--format=%cI', 'HEAD')
            $builtAt = [DateTimeOffset]::Parse($commitDate).UtcDateTime
        }
        $manifest = [ordered]@{
            app_version = '0.2.0-beta.7'
            internal_version = 7
            fit_schema = 12
            commit = $commit
            source_date_utc = $builtAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
            dirty = $false
            python_version = $pythonVersion
            pyinstaller_version = $pyinstallerVersion
            mode = 'one-folder-windowed-clean-no-upx'
            questionnaire = $Questionnaire
            device_matrix = $DeviceMatrix
            assignment_embedded = [bool]$assignmentPath
            assignment_source = if (-not $assignmentPath) {
                'none'
            } elseif ($env:GITHUB_ACTIONS -eq 'true') {
                'synthetic-example'
            } else {
                'local-validated'
            }
        }
        $manifestPath = Join-Path $distributionPath 'build-manifest.json'
        $manifestJson = $manifest | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText(
            $manifestPath,
            $manifestJson + "`n",
            [System.Text.UTF8Encoding]::new($false)
        )

        $files = Get-ChildItem -LiteralPath $distributionPath -File -Recurse |
            Where-Object { $_.Name -ne 'SHA256SUMS.txt' } |
            Sort-Object FullName
        $hashLines = foreach ($file in $files) {
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $relative = [System.IO.Path]::GetRelativePath(
                $distributionPath,
                $file.FullName
            ).Replace('\', '/')
            "$hash  $relative"
        }
        [System.IO.File]::WriteAllLines(
            (Join-Path $distributionPath 'SHA256SUMS.txt'),
            [string[]]$hashLines,
            [System.Text.UTF8Encoding]::new($false)
        )
    } catch {
        Remove-Item -LiteralPath $distributionPath -Recurse -Force -ErrorAction SilentlyContinue
        throw
    } finally {
        Remove-Item -LiteralPath $temporaryBuild -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
} finally {
    Pop-Location -ErrorAction SilentlyContinue
}
