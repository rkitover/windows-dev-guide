[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')
set-service beep -startuptype disabled
winget install --force Microsoft.VisualStudio.2022.Community vim.vim 7zip.7zip gsass1.NTop StrawberryPerl.StrawberryPerl Git.Git GnuPG.GnuPG SourceFoundry.HackFonts Neovim.Neovim OpenJS.NodeJS Notepad++.Notepad++ Microsoft.Powershell Python.Python.3.13 SSHFS-Win.SSHFS-Win Microsoft.OpenSSH.Beta
$env:path = [system.environment]::getenvironmentvariable("path", "machine") + ';' + [system.environment]::getenvironmentvariable("path", "user")
iwr https://aka.ms/vs/17/release/vs_community.exe -outfile vs_community.exe
./vs_community.exe --passive --add 'Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended;includeOptional'
$pwsh = [system.diagnostics.process]::getcurrentprocess().mainmodule.filename
start-process $pwsh '-noprofile', '-executionpolicy', 'bypass', '-windowstyle', 'hidden', `
    '-command', "while (test-path $pwd/vs_community.exe) { sleep 5; ri -fo $pwd/vs_community.exe }"
ni -it sym ~/.config -tar ($env:USERPROFILE + '\AppData\Local') -ea ignore
if (-not (test-path ~/scoop)) {
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
}
scoop install bzip2 diffutils dos2unix file gawk grep gzip less make netcat ripgrep sed zip unzip
$env:path = [system.environment]::getenvironmentvariable("path", "machine") + ';' + [system.environment]::getenvironmentvariable("path", "user")
scoop bucket add nerd-fonts
scoop install DejaVuSansMono-NF
## Only run this on Windows 10 or older, this package is managed by Windows 11.
#winget install Microsoft.WindowsTerminal
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
sed -i 's/^[^#].*administrators.*/#&/g' /programdata/ssh/sshd_config
set-service sshd -startuptype automatic
set-service ssh-agent -startuptype automatic
start-service sshd
start-service ssh-agent
&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
