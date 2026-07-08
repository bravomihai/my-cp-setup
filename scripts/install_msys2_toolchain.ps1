$ErrorActionPreference = "Stop"

function Find-Msys2Shell {
    $candidates = @(
        "C:\msys64\msys2_shell.cmd",
        "D:\software\programming\msys2\msys2_shell.cmd"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $fromPath = Get-Command msys2_shell.cmd -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    return $null
}

$shell = Find-Msys2Shell
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
