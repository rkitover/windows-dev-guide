[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')
set-service beep -startuptype disabled
choco feature enable --name 'useRememberedArgumentsForUpgrades'
choco install -y visualstudio2019community --params '--locale en-US'
choco install -y visualstudio2019-workload-nativedesktop
choco install -y vim --params '/NoDesktopShortcuts'
choco install -y 7zip NTop.Portable StrawberryPerl bzip2 dejavufonts diffutils dos2unix file gawk git gpg4win grep gzip hackfont less make microsoft-windows-terminal neovim netcat nodejs notepadplusplus powershell-core python ripgrep sed sshfs unzip xxd zip
stop-service ssh-agent
sc.exe delete ssh-agent
choco install -y openssh --params '/SSHServerFeature /SSHAgentFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe'
refreshenv
sed -i 's/^[^#].*administrators.*/#&/g' /programdata/ssh/sshd_config
restart-service sshd
&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
ni -it sym ~/.config -tar (resolve-path ~/AppData/Local)
