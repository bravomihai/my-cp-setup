param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [switch]$Check
)

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
    exit 0
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
