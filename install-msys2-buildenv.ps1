$erroractionpreference = 'stop'

$env:PATH = "C:\msys64\usr\bin;$env:PATH"

if (-not $args) {
    $args = 'clang64'
}

foreach ($env in $args) {
    $env = $env.tolower()

    if ($env -eq 'msys') {
	$arch = ''
    }
    elseif ($env -eq 'clang64') {
	$arch = 'mingw-w64-clang-x86_64'
    }
    elseif ($env -eq 'clangarm64') {
	$arch = 'mingw-w64-clang-aarch64'
    }
    elseif ($env -eq 'mingw32') {
	$arch = 'mingw-w64-i686'
    }
    elseif ($env -eq 'ucrt64') {
	$arch = 'mingw-w64-ucrt-x86_64'
    }
    elseif ($env -eq 'mingw64') {
	$arch = 'mingw-w64-x86_64'
    }
    else {
	write-error -ea stop "Unknown MSYS2 build environment: $env"
    }

    if ($env -eq 'msys') {
	$pkgs = echo isl mpc msys2-runtime-devel msys2-w32api-headers msys2-w32api-runtime 
    }
    else {
	$pkgs = echo crt-git headers-git tools-git libmangle-git
    }

    if ($env -match '64$') {
	$pkgs += 'extra-cmake-modules'
    }

    if ($env -eq 'clang64') {
	$pkgs += echo lldb clang
    }
    else {
	$pkgs += echo gcc gcc-libs

	if ($env -ne 'msys') {
	    $pkgs += 'gcc-libgfortran'
	}
    }

    $pkgs += echo binutils cmake make pkgconf `
	windows-default-manifest ninja gdb ccache

    if ($arch) {
	$pkgs = $pkgs | %{ "${arch}-$_" }
    }

    $pkgs += echo git make

    /msys64/usr/bin/pacman -Sy --noconfirm
    /msys64/usr/bin/pacman -S --noconfirm --needed $pkgs
}
