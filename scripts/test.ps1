# Runs the ClipConvertCore test suite on Windows.
#
# Swift on Windows needs more environment than the installer sets up, and none
# of it survives between shells. Without this script `swift test` fails in three
# separate ways, each with an error that does not name the real cause:
#
#   1. "swift is not recognized"          - the toolchain is not on PATH
#   2. "could not find CLI tool 'link'"   - the MSVC linker is not on PATH
#   3. "unable to load standard library"  - SDKROOT is unset
#
# Usage, from the repository root:
#   .\scripts\test.ps1
#   .\scripts\test.ps1 --filter DetectionTests
#
# Any arguments are passed straight through to `swift test`.

$ErrorActionPreference = "Stop"

# 1. Toolchain, from the registry rather than the current shell, so this works
#    in a terminal that was open before Swift was installed.
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")

# 2. Swift runtime DLLs. Needed to run the compiled test binary, not to build it.
$runtime = "$env:LOCALAPPDATA\Programs\Swift\Runtimes\6.4.0\usr\bin"
if (Test-Path $runtime) {
    $env:Path = "$runtime;" + $env:Path
}

# 3. The Windows Swift SDK. The toolchain does not infer this location.
$sdk = "$env:LOCALAPPDATA\Programs\Swift\Platforms\6.4.0\Windows.platform\Developer\SDKs\Windows.sdk"
if (Test-Path $sdk) {
    $env:SDKROOT = $sdk
} else {
    Write-Warning "Windows SDK not found at $sdk - if the build fails to find the standard library, this path has moved (check for a different Swift version under $env:LOCALAPPDATA\Programs\Swift\Platforms)."
}

# 4. MSVC build environment, for link.exe. vcvars64.bat only sets variables in
#    its own cmd process, so we run it and import what it changed.
$vcvars = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022" `
    -Filter vcvars64.bat -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $vcvars) {
    throw "vcvars64.bat not found. Install the Visual Studio 2022 Build Tools with the C++ workload:`n  winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override `"--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended`""
}

cmd /c "`"$vcvars`" >nul 2>&1 && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        Set-Item -Path "env:$($matches[1])" -Value $matches[2] -ErrorAction SilentlyContinue
    }
}

Push-Location $PSScriptRoot\..
try {
    # swift writes progress ("Building for debugging...") to stderr. Under
    # ErrorActionPreference = "Stop", Windows PowerShell turns any native
    # stderr line into a terminating error, so a perfectly good test run
    # reports failure. Relax it for the call and use the exit code, which is
    # the only reliable success signal here.
    $ErrorActionPreference = "Continue"
    swift test @args
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
