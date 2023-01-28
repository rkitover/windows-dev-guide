[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')
set-service beep -startuptype disabled
choco feature enable --name 'useRememberedArgumentsForUpgrades'
choco install -y visualstudio2022community --params '--locale en-US'
choco install -y visualstudio2022-workload-nativedesktop
choco install -y vim --params '/NoDesktopShortcuts'
choco install -y 7zip NTop.Portable StrawberryPerl bzip2 cmake.portable dejavufonts diffutils dos2unix file gawk git gpg4win grep gzip hackfont less make neovim netcat nodejs notepadplusplus powershell-core python ripgrep sed sshfs unzip xxd zip
## Only run this on Windows 10 or older, this package is managed by Windows 11.
#choco install -y microsoft-windows-terminal
## If you had previously installed it and are now using Windows 11, run:
#choco uninstall microsoft-windows-terminal -n --skipautouninstaller
stop-service ssh-agent
sc.exe delete ssh-agent
choco install -y openssh --prerelease --force --params '/SSHServerFeature /SSHAgentFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe'
refreshenv
sed -i 's/^[^#].*administrators.*/#&/g' /programdata/ssh/sshd_config
restart-service sshd
&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
ni -it sym ~/.config -tar (resolve-path ~/AppData/Local)
