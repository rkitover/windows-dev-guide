ni -it sym ~/.config -tar ($env:USERPROFILE + '\AppData\Local') -ea ignore

if (-not (test-path ~/scoop)) {
    iwr get.scoop.sh | iex
}

# BusyBox must be first in the installation order.
~/scoop/shims/scoop.cmd install busybox bzip2 diffutils dos2unix file gawk grep gzip less make mingw perl ripgrep sed zip unzip
~/scoop/shims/scoop.cmd shim rm bash # Installed by busybox
~/scoop/shims/scoop.cmd bucket add nerd-fonts
~/scoop/shims/scoop.cmd install DejaVuSansMono-NF

&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
