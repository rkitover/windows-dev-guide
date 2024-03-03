[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')

set-service beep -startuptype disabled

'Microsoft.VisualStudio.2022.Community','vim.vim','7zip.7zip','gsass1.NTop','StrawberryPerl.StrawberryPerl',`
'Git.Git','GnuPG.GnuPG','SourceFoundry.HackFonts','Neovim.Neovim','OpenJS.NodeJS','Notepad++.Notepad++',`
'Microsoft.Powershell','Python.Python.3.13','SSHFS-Win.SSHFS-Win','Microsoft.OpenSSH.Beta','Microsoft.WindowsTerminal' | %{
	winget install $_
}

iwr https://aka.ms/vs/17/release/vs_community.exe -outfile vs_community.exe

./vs_community.exe --passive --add 'Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended;includeOptional'

start-process pwsh '-noprofile', '-windowstyle', 'hidden', `
    '-command', "while (test-path $pwd/vs_community.exe) { sleep 5; ri -fo $pwd/vs_community.exe }"

new-itemproperty -path "HKLM:\SOFTWARE\OpenSSH" -name DefaultShell -value (get-command pwsh).source -propertytype string -force > $null

(gc /programdata/ssh/sshd_config) | %{ $_ -replace '^([^#].*administrators.*)','#$1' } | set-content /programdata/ssh/sshd_config

set-service sshd -startuptype automatic
set-service ssh-agent -startuptype automatic

start-service sshd
start-service ssh-agent