$ErrorActionPreference = "Stop"

function Test-Python {
    param([string] $Path)

    if (-not $Path) {
        return $false
    }
    if ($Path -like "*\Microsoft\WindowsApps\*") {
        return $false
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    & $Path --version *> $null
    return $LASTEXITCODE -eq 0
}

$candidates = @()

if ($env:CP_PYTHON) {
    $candidates += $env:CP_PYTHON
}

$candidates += @(
    "C:\msys64\mingw64\bin\python.exe",
    "C:\msys64\ucrt64\bin\python.exe",
    "D:\software\programming\msys2\mingw64\bin\python.exe",
    "D:\software\programming\msys2\ucrt64\bin\python.exe"
)

$wherePython = where.exe python 2>$null
if ($LASTEXITCODE -eq 0) {
    $candidates += $wherePython
}

$pyLauncher = Get-Command py.exe -ErrorAction SilentlyContinue
if ($pyLauncher) {
    $pyPath = & $pyLauncher.Source -3 -c "import sys; print(sys.executable)" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $candidates += $pyPath
    }
}

foreach ($candidate in $candidates) {
    if (Test-Python $candidate) {
        Write-Output $candidate
        exit 0
    }
}

exit 1
