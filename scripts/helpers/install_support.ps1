param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("paths", "find-python", "msys2")]
    [string] $Action,

    [string] $Root,
    [switch] $Check
)

$ErrorActionPreference = "Stop"

function Install-Paths {
    param([string] $Root, [switch] $Check)

    $candidates = @(
        (Join-Path $Root "scripts"),
        "C:\Program Files\Git\cmd",
        "C:\Program Files\Git\usr\bin",
        "C:\Program Files\Git\mingw64\libexec\git-core",
        "D:\software\programming\git\Git\cmd",
        "D:\software\programming\git\Git\usr\bin",
        "D:\software\programming\git\Git\mingw64\libexec\git-core",
        "C:\Program Files\Neovim\bin",
        "D:\software\programming\neovim\bin",
        "C:\msys64\mingw64\bin",
        "C:\msys64\ucrt64\bin",
        "D:\software\programming\msys2\mingw64\bin"
    )

    $existing = $candidates | Where-Object { Test-Path -LiteralPath $_ }
    if ($Check) {
        foreach ($path in $existing) {
            Write-Host "[CHECK] PATH candidate exists: $path"
        }
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $userPath) {
        $userPath = ""
    }

    $parts = $userPath -split ";" | Where-Object { $_ }
    foreach ($path in $existing) {
        $alreadyPresent = $parts | Where-Object {
            $_.TrimEnd("\") -ieq $path.TrimEnd("\")
        }

        if (-not $alreadyPresent) {
            $parts += $path
            Write-Host "[PATH] Added: $path"
        }
    }

    [Environment]::SetEnvironmentVariable("Path", ($parts -join ";"), "User")
}

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

function Find-Python {
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
            return
        }
    }

    exit 1
}

function Install-Msys2Toolchain {
    $shell = @(
        "C:\msys64\msys2_shell.cmd",
        "D:\software\programming\msys2\msys2_shell.cmd"
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

    if (-not $shell) {
        $fromPath = Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue
        if ($fromPath) {
            $shell = $fromPath.Source
        }
    }

    if (-not $shell) {
        throw "Could not find msys2_shell.cmd after installing MSYS2."
    }

    & $shell -mingw64 -defterm -no-start -here -c "pacman -Syu --noconfirm"
    if ($LASTEXITCODE -ne 0) {
        throw "pacman system update failed."
    }

    & $shell -mingw64 -defterm -no-start -here -c "pacman -S --needed --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-clang-tools-extra mingw-w64-x86_64-python"
    if ($LASTEXITCODE -ne 0) {
        throw "pacman toolchain install failed."
    }
}

switch ($Action) {
    "paths" { Install-Paths -Root $Root -Check:$Check }
    "find-python" { Find-Python }
    "msys2" { Install-Msys2Toolchain }
}
