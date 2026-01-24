[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')

set-service beep -startuptype disabled

write Microsoft.VisualStudio.Community 7zip.7zip gsass1.NTop Git.Git `
    GnuPG.GnuPG SourceFoundry.HackFonts Neovim.Neovim OpenJS.NodeJS NASM.NASM `
    Notepad++.Notepad++ Microsoft.Powershell Python.Python.3.14 Ccache.Ccache `
    SSHFS-Win.SSHFS-Win Microsoft.OpenSSH.Preview Microsoft.WindowsTerminal | %{
	winget install $_ --source winget
}

iwr https://aka.ms/vs/stable/vs_community.exe -outfile vs_community.exe

./vs_community.exe --passive --add 'Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended;includeOptional'

start-process powershell '-noprofile', '-windowstyle', 'hidden', `
    '-command', "while (test-path $pwd/vs_community.exe) { sleep 5; ri -fo $pwd/vs_community.exe }"

new-itemproperty -path "HKLM:\SOFTWARE\OpenSSH" -name DefaultShell -value '/Program Files/PowerShell/7/pwsh.exe' -propertytype string -force > $null

$sshd_conf = '/programdata/ssh/sshd_config'
$conf = gc $sshd_conf | %{ $_ -replace '^([^#].*administrators.*)','#$1' }
$conf | set-content $sshd_conf

set-service sshd -startuptype automatic
set-service ssh-agent -startuptype automatic

restart-service -force sshd
restart-service -force ssh-agent
