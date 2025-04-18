ni -it sym ~/.config -tar ($env:USERPROFILE + '\AppData\Local') -ea ignore

if (-not (test-path ~/scoop)) {
    iwr get.scoop.sh | iex
}

function scoop { & ~/scoop/apps/scoop/current/bin/scoop.ps1 @args }

# BusyBox must be first in the installation order.
scoop install busybox-lean base64 bc bind bzip2 dd diffutils dos2unix file gawk gettext grep gzip ipcalc less make openssl perl ripgrep sed tar zip unzip wget

'arch ash basename cal cksum clear comm cp cpio cut date df dirname dpkg dpkg-deb du echo ed env expand expr factor false find fold fsync ftpget ftpput getopt hd head hexdump httpd ln logname lzcat lzma lzop lzopcat md5sum mktemp mv nc nl od paste pgrep pidof pipe_progress printenv printf ps pwd readlink realpath reset rev rm rmdir rpm rpm2cpio seq sh sha1sum sha256sum sha3sum sha512sum shred shuf sleep sort split ssl_client stat sum tac tail tee test time timeout touch tr true truncate ts ttysize uname uncompress unexpand uniq unlink unlzma unlzop unxz usleep uudecode uuencode vi watch wc which xargs xxd xz xzcat yes zcat'.split(' ') | %{
    scoop shim add $_ busybox $_
}

scoop bucket add extras
scoop install mpv

scoop bucket add nerd-fonts
scoop install DejaVuSansMono-NF

&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
