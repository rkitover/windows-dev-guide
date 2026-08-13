[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')

set-service beep -startuptype disabled

write Microsoft.VisualStudio.Community 7zip.7zip gsass1.NTop Git.Git `
    GnuPG.GnuPG SourceFoundry.HackFonts Neovim.Neovim OpenJS.NodeJS NASM.NASM `
    Notepad++.Notepad++ Microsoft.Powershell Python.Python.3.14 Ccache.Ccache `
    KitWare.CMake Ninja-build.Ninja `
    SSHFS-Win.SSHFS-Win Microsoft.OpenSSH.Preview Microsoft.WindowsTerminal | %{
	winget install $_ --source winget
}

iwr -usebasicparsing https://aka.ms/vs/stable/vs_community.exe -outfile vs_community.exe

./vs_community.exe --passive --add 'Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended;includeOptional'

start-process powershell '-noprofile', '-windowstyle', 'hidden', `
    '-command', "while (test-path $pwd/vs_community.exe) { sleep 5; ri -fo $pwd/vs_community.exe }"

# The shell for incoming ssh connections. This is the app execution alias, which
# Windows keeps pointed at the pwsh you have installed, written out in full
# because sshd needs a literal path and does not expand anything.
new-itemproperty -path "HKLM:\SOFTWARE\OpenSSH" -name DefaultShell `
    -value "$env:localappdata\Microsoft\WindowsApps\pwsh.exe" `
    -propertytype string -force > $null

# Open ssh on all networks, the rule the OpenSSH package adds only covers
# private ones. Remove first so that re-running this does not fail.
remove-netfirewallrule -name sshd -ea ignore
new-netfirewallrule -name sshd -displayname 'OpenSSH Server (sshd)' `
    -direction inbound -action allow -protocol tcp -localport 22 -profile any `
    > $null

$sshd_conf = '/programdata/ssh/sshd_config'
$conf = gc $sshd_conf | %{ $_ -replace '^([^#].*administrators.*)','#$1' }
$conf | set-content $sshd_conf

set-service sshd -startuptype automatic
set-service ssh-agent -startuptype automatic

restart-service -force sshd
restart-service -force ssh-agent
