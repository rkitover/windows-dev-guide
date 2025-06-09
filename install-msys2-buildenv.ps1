$erroractionpreference = 'stop'

$orig_path = $env:PATH
$env:PATH  = "C:\msys64\usr\bin;$env:PATH"

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
	$pkgs = write isl mpc msys2-runtime-devel msys2-w32api-headers msys2-w32api-runtime autoconf automake libtool zlib-devel
    }
    else {
	$pkgs = write crt-git headers-git tools-git libmangle-git
    }

    if ($env -match '64$') {
	$pkgs += 'extra-cmake-modules'
    }

    if ($env -eq 'clang64') {
	$pkgs += write lldb clang
    }
    else {
	$pkgs += write gcc gcc-libs

	if ($env -ne 'msys') {
	    $pkgs += 'gcc-libgfortran'
	}
    }

    $pkgs += write binutils cmake make pkgconf windows-default-manifest ninja gdb ccache

    if ($arch) {
	$pkgs = $pkgs | %{ "${arch}-$_" }
    }

    $pkgs += write git make

    /msys64/usr/bin/pacman -Sy --noconfirm
    /msys64/usr/bin/pacman -S --noconfirm --needed $pkgs
}

$env:PATH = $orig_path
