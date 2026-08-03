$sshfixperms = resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1 -ea ignore | select -first 1
$sshutils    = resolve-path /prog*s/openssh*/opensshutils.psd1 -ea ignore | select -first 1

if ($sshfixperms -and $sshutils) {
    &$sshfixperms
    import-module -force $sshutils
    repair-authorizedkeypermission -file ~/.ssh/authorized_keys
}
