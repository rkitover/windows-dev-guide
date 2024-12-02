$erroractionpreference = 'stop'

if (-not (test-path /msys64)) {
    winget install --force msys2.msys2
}

$nsswitch_conf = '/msys64/etc/nsswitch.conf'
$conf = gc $nsswitch_conf | %{ $_ -replace '^db_home:.*','db_home: windows' }
$conf | set-content $nsswitch_conf

$env:MSYSTEM = 'MSYS'

1..5 | %{ /msys64/usr/bin/bash -l -c 'pacman -Syu --noconfirm' }

/msys64/usr/bin/bash -l -c 'pacman -S --noconfirm --needed man-db vim git openssh tmux tree mingw-w64-clang-x86_64-ripgrep'

if (-not (test-path ~/.bash_profile)) {
    "source ~/.bashrc`n" | set-content ~/.bash_profile
}

if (-not (test-path ~/.bashrc)) {
    # SET BACK TO MASTER ON FINAL COMMIT
    iwr 'https://raw.githubusercontent.com/rkitover/windows-dev-guide/refs/heads/master/.bashrc' -out ~/.bashrc
}
