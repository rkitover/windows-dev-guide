<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Windows Native Development Environment Setup Guide for Linux Users](#windows-native-development-environment-setup-guide-for-linux-users)
  - [Install Chocolatey and Some Packages](#install-chocolatey-and-some-packages)
  - [Chocolatey Usage Notes](#chocolatey-usage-notes)
  - [Configure the Terminal](#configure-the-terminal)
  - [Setting up Vim](#setting-up-vim)
  - [Set up PowerShell Profile](#set-up-powershell-profile)
  - [Setting up gpg](#setting-up-gpg)
  - [Setting up sshd](#setting-up-sshd)
  - [Setting up git](#setting-up-git)
  - [PowerShell Usage Notes](#powershell-usage-notes)
  - [Available Command-Line Tools and Utilities](#available-command-line-tools-and-utilities)
  - [Mounting SMB/SSHFS Folders](#mounting-smbsshfs-folders)
  - [Miscellaneous](#miscellaneous)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Windows Native Development Environment Setup Guide for Linux Users

### Install Chocolatey and Some Packages

Make sure developer mode is turned on in Windows settings, this is necessary for
making unprivileged symlinks.

- Press Win+X and open PowerShell (Administrator).

- Run these commands:

```powershell
Set-ExecutionPolicy -Scope LocalMachine -Force RemoteSigned
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```
.

Close the Administrator PowerShell window and open it again.

Install some chocolatey packages:

```powershell
choco install -y visualstudio2019community --params '--locale en-US'
choco install -y visualstudio2019-workload-nativedesktop
choco install -y 7zip autohotkey autologon bzip2 dejavufonts diffutils gawk git gpg4win grep gzip hackfont less make microsoft-windows-terminal neovim nodejs notepadplusplus NTop.Portable powershell-core python ripgrep sed sshfs unzip vim zip
# Copy your .ssh over to your profile directly first preferrably:
stop-service ssh-agent
sc.exe delete ssh-agent
choco install -y openssh --params '/SSHServerFeature /SSHAgentFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe'
refreshenv
sed -i 's/^[^#].*administrators.*/#&/g' /programdata/ssh/sshd_config
restart-service sshd
```
.

### Chocolatey Usage Notes

Here are some commands for using the Chocolatey package manager.

To search for a package:

```powershell
choco search patch
```
.

To get the description of a package:

```powershell
choco info patch
```
.

To install a package:

```powershell
choco install -y patch
```
.

To uninstall a package:


```powershell
choco uninstall -y patch
```
.

To list installed packages:

```powershell
choco list --local
```
.

To update all installed packages:

```powershell
choco update -y all
```
.

### Configure the Terminal

Launch the terminal and choose Settings from the tab drop-down, this will open
the settings json in visual studio.

In the global settings, above the `"profiles"` section, add:

```json
"copyFormatting": "all",
"focusFollowMouse": true,
// If enabled, selections are automatically copied to your clipboard.
"copyOnSelect": true,
// If enabled, formatted data is also copied to your clipboard
"copyFormatting": true,
"tabSwitcherMode": "disabled",
"tabWidthMode": "equal",
"wordDelimiters": " ",
"largePasteWarning": false,
"multiLinePasteWarning": false,
"windowingBehavior": "useAnyExisting",
```
.

In the `"profiles"` `"defaults"` section add:

```json
"defaults":
{
    // Put settings here that you want to apply to all profiles.
    "adjustIndistinguishableColors": false,
    "font": 
    {
        "face": "Hack",
        "size": 11
    },
    "antialiasingMode": "cleartype",
    "cursorShape": "filledBox",
    "colorScheme": "Tango Dark",
    "intenseTextStyle": "bold",
    "padding": "0",
    "scrollbarState": "hidden"
    "closeOnExit": "always"
},
```
.

I prefer the 'SF Mono' font which you can get here:

https://github.com/supercomputra/SF-Mono-Font
.

Other fonts you might like are `IBM Plex Mono` which you can install from:

https://github.com/IBM/plex
,

and 'DejaVu Sans Mono' which was in the list of Chocolatey packages above.

In the `"actions"` section add these keybindings:

```json
{ "command": { "action": "newTab"  }, "keys": "ctrl+shift+t" },
{ "command": { "action": "nextTab" }, "keys": "ctrl+shift+right" },
{ "command": { "action": "prevTab" }, "keys": "ctrl+shift+left" }
```
.

And **REMOVE** the `ctrl+v` binding, if you want to use `ctrl+v` in vim (visual
line selection.)

This gives you a sort of "tmux" for PowerShell using tabs.

Restart the terminal.

You can toggle full-screen mode with `F11`.

`SHIFT`+`ALT`+`+` will open a split pane vertically, while `SHIFT`+`ALT`+`-`
will open a split pane horizontally. This works in full-screen as well.

### Setting up Vim

I recommend using neovim on Windows because it has working mouse support and is
almost 100% compatible with vim anyway.

If you don't use vim, just add an alias for your favorite editor in your
powershell `$profile`, and set `$env:EDITOR` so that git can open it for commit
messages etc.. I will explain how to do this below.

If you are using neovim, run the following:

```powershell
mkdir ~/.vim,~/AppData/Local/nvim -ea ignore
ni ~/.vimrc -ea ignore
cmd /c rmdir /Q /S $(resolve-path ~/AppData/Local/nvim)
ni -it sym ~/AppData/Local/nvim -tar $(resolve-path ~/.vim)
ri ~/.vim/init.vim -ea ignore
ni -it sym ~/.vim/init.vim      -tar $(resolve-path ~/.vimrc)
ni -it sym ~/vimfiles           -tar $(resolve-path ~/.vim)
```
.

For regular vim run the following:

```powershell
mkdir ~/.vim -ea ignore
ni -it sym ~/vimfiles -tar $(resolve-path ~/.vim)
```

You can edit your powershell profile with `vim $profile`, and reload it with `.
$profile`.

Add the following to your `$profile`:

```powershell
if ($env:TERM) { ri env:TERM }

$vim = resolve-path ~/.local/bin/nvim.bat
set-alias -name vim -val nvim

# Neovim is broken in ssh sessions, use regular vim.
if ($env:SSH_CONNECTION) {
    $vim = resolve-path ~/.local/bin/vim.bat
    ri alias:vim
}

$env:EDITOR = $vim -replace '\\','/'

ri variable:vim
```
.

In `~/.local/bin/nvim.bat` put the following for neovim:

```bat
@echo off
set TERM=
nvim %*
```
,

and in `~/.local/bin/vim.bat` put the following for regular vim:

```bat
@echo off
set TERM=
c:\windows\vim.bat %*
```
.

This is needed for git to work correctly with native vim/neovim.

Some suggestions for your `~/.vimrc`:

```vim
set encoding=utf8
set langmenu=en_US.UTF-8
let g:is_bash=1
set formatlistpat=^\\s*\\%([-*][\ \\t]\\\|\\d+[\\]:.)}\\t\ ]\\)\\s*
set ruler bg=dark nohlsearch bs=2 noea ai fo+=n undofile modeline belloff=all modeline modelines=5
set fileformats=unix,dos

set mouse=a
if !has('nvim')
  set ttymouse=xterm2
endif

" Add vcpkg includes to include search path to get completions for C++.
let g:home = fnamemodify('~', ':p')

if isdirectory(g:home . 'source/repos/vcpkg/installed/x64-windows-static/include')
  let &path .= ',' . g:home . 'source/repos/vcpkg/installed/x64-windows-static/include'
endif

if has('win32')
  if !has('gui_running')
    set termguicolors
  else
    set guifont=Hack:h11:cANSI
    au ColorScheme * hi Normal guibg=#000000
  endif
endif
if (has('win32') || has('gui_win32')) && executable('pwsh')
    set shell=pwsh
    set shellcmdflag=\ -ExecutionPolicy\ RemoteSigned\ -NoProfile\ -Nologo\ -NonInteractive\ -Command
endif

filetype plugin indent on
syntax enable

au BufRead COMMIT_EDITMSG,*.md setlocal spell
au BufRead *.md setlocal tw=80
" Return to last edit position when opening files.
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif
```
.

I use this color scheme, which is a fork of Apprentice for black backgrounds:

https://github.com/rkitover/Apprentice

You can add it with Plug or pathogen or whatever you prefer.

### Set up PowerShell Profile

Now add some useful things to your powershell profile, I will present some of
mine below:

Run:

```powershell
vim $profile
```

or

```powershell
notepad $profile
```
.

If you use my posh-git prompt, you'll need the git version of posh-git:

```powershell
mkdir ~/source/repos -ea ignore
cd ~/source/repos
git clone https://github.com/dahlbyk/posh-git
```
.

Here is a profile to get you started, it has a few examples of functions and
aliases which you will invariably write for yourself:

```powershell
chcp 65001 > $null

set-executionpolicy -scope currentuser remotesigned

set-culture en-US

# Remove Strawberry Perl MinGW stuff from PATH.
$env:PATH = ($env:PATH -split ';' | ?{ $_ -notmatch '\\Strawberry\\c\\bin$' }) -join ';'

$terminal_settings = resolve-path ~/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json

if ($env:TERM) { ri env:TERM }

$vim = resolve-path ~/.local/bin/nvim.bat
set-alias -name vim -val nvim

# Neovim is broken in ssh sessions, use regular vim.
if ($env:SSH_CONNECTION) {
    $vim = resolve-path ~/.local/bin/vim.bat
    ri alias:vim
}

$env:EDITOR = $vim -replace '\\','/'

ri variable:vim

if (test-path ~/source/repos/vcpkg) {
    $env:VCPKG_ROOT = resolve-path ~/source/repos/vcpkg
}

$env:DISPLAY = '127.0.0.1:0.0'

function megs {
    gci -r $args | select mode, lastwritetime, @{name="MegaBytes"; expression = { [math]::round($_.length / 1MB, 2) }}, name
}

function cmconf {
    grep -E --color 'CMAKE_BUILD_TYPE|VCPKG_TARGET_TRIPLET|UPSTREAM_RELEASE' CMakeCache.txt
}

function pgrep {
    get-ciminstance win32_process -filter "name like '%$($args[0])%' OR commandline like '%$($args[0])%'" | select processid, name, commandline
}

function pkill {
    pgrep $args | %{ stop-process $_.processid }
}

# Windows PowerShell does not support the `e special character sequence for Escape, so we use a variable $e for this.
$e = [char]27

function format-eventlog {
    $input | %{
        echo ("$e[95m[$e[34m" + ('{0:MM-dd} ' -f $_.timecreated) + `
        "$e[36m" + ('{0:HH:mm:ss}' -f $_.timecreated) + `
        "$e[95m]$e[0m " + `
        ($_.message -replace "`n.*",''))
    }
}

function syslog {
    get-winevent -log system -oldest | format-eventlog | oh -p -ea ignore
}

# You have to enable the tasks log first as admin, see:
# https://stackoverflow.com/q/13965997/262458

function tasklog {
    get-winevent 'Microsoft-Windows-TaskScheduler/Operational' -oldest | format-eventlog | oh -p -ea ignore
}

function ltr { $input | sort lastwritetime }

function ntop { ntop.exe -s 'CPU%' $args }

function head {
    $lines = if ($args.length -and $args[0] -match '^-(.+)') { $null,$args = $args; $matches[1] } else { 10 }
    
    if (!$args.length) {
        $input | select -first $lines
    }
    else {
        gc $args | select -first $lines
    }
}

# Example utility function to convert CSS hex color codes to rgb(x,x,x) color codes.
function hexcolortorgb {
    'rgb(' + (((($args[0] -replace '^#','') -split '(..)(..)(..)')[1,2,3] | %{ [uint32]"0x$_" }) -join ',') + ')'
}

function less_paged_help {
    get-help @args -detailed | less
}

set-alias -name help    -val less_paged_help

set-alias -name which   -val get-command
set-alias -name notepad -val '/program files/notepad++/notepad++'

# To use neovim instead of vim for mouse support:
set-alias -name vim     -val nvim

if (test-path alias:diff) { ri -fo alias:diff }

# Load VS env only once.
foreach ($vs_type in 'buildtools','community') {
    $vs_path="/program files (x86)/microsoft visual studio/2019/${vs_type}/vc/auxiliary/build"

    if (test-path $vs_path) {
        break
    }
    else {
        $vs_path=$null
    }
}

if ($vs_path -and -not $env:VSCMD_VER) {
    pushd $vs_path
    cmd /c 'vcvars64.bat & set' | where { $_ -match '=' } | %{
        $var,$val = $_.split('=')
        set-item -force "env:$var" -value $val
    }
    popd
}

# Chocolatey profile
$chocolatey_profile = "$env:chocolateyinstall\helpers\chocolateyprofile.psm1"

if (test-path $chocolatey_profile) { import-module $chocolatey_profile }

import-module ~/source/repos/posh-git/src/posh-git.psd1

function global:PromptWriteErrorInfo() {
    if ($global:gitpromptvalues.dollarquestion) {
        "$e[0;32mv$e[0m"
    }
    else {
        "$e[0;31mx$e[0m"
    }
}

$gitpromptsettings.defaultpromptabbreviatehomedirectory      = $true

$gitpromptsettings.defaultpromptprefix.text                  = '$(PromptWriteErrorInfo) '

$username = $env:USERNAME
$hostname = $env:COMPUTERNAME.tolower()

$gitpromptsettings.defaultpromptwritestatusfirst             = $false
$gitpromptsettings.defaultpromptbeforesuffix.text            = "`n$e[0m$e[38;2;140;206;250m$username$e[1;97m@$e[0m$e[38;2;140;206;250m$hostname "
$gitpromptsettings.defaultpromptsuffix.foregroundcolor       = 0xDC143C

$gitpromptsettings.windowtitle = $null
$host.ui.rawui.windowtitle = $hostname

import-module psreadline

set-psreadlineoption     -editmode emacs
set-psreadlinekeyhandler -key tab       -function complete
set-psreadlinekeyhandler -key uparrow   -function historysearchbackward
set-psreadlinekeyhandler -key downarrow -function historysearchforward
```
.

This profile works for "Windows PowerShell" as well. But the profile is in a
different file, so you will need to make a symlink there to your PowerShell
`$profile`.

```powershell
mkdir ~/Documents/WindowsPowerShell
ni -it sym ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1 -tar $profile
```
.

Be aware that if your Documents are in OneDrive, OneDrive will ignore and not
sync symlinks.

### Setting up gpg

Make this symlink:

```powershell
sl ~
mkdir .gnupg -ea ignore
cmd /c rmdir /Q /S $(resolve-path ~/AppData/Roaming/gnupg)
ni -it sym ~/AppData/Roaming/gnupg -tar $(resolve-path ~/.gnupg)
```
.

Then you can copy your `.gnupg` over, without the socket files.

To configure git to use it, do the following:

```powershell
git config --global commit.gpgsign true
git config --global gpg.program 'C:\Program Files (x86)\GnuPG\bin\gpg.exe'
```
.

### Setting up sshd

If you've installed openssh before copying over your `~/.ssh`, you will need to
fix permissions on your `authorized_keys` files, the easiest way to do
that is to re-run the installer with `--force`:

```powershell
choco install -y --force openssh --params '/SSHServerFeature /SSHAgentFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe'
```

If you need to fix permissions on your private key, follow these instructions:

https://superuser.com/a/1329702/226829

### Setting up git

You can copy over your `~/.gitconfig`, and run the following to set some
settings I recommend:

```powershell
# SET YOUR NAME AND EMAIL HERE:
git config --global user.name "John Doe"
git config --global user.email johndoe@example.com

git config --global core.autocrlf  false
git config --global push.default   simple
git config --global pull.rebase    true
git config --global commit.gpgsign true
```
.

### PowerShell Usage Notes

PowerShell is very different from unix shells, in both usage and programming.

This section won't teach you PowerShell, but it will give you enough
information to use it as a shell and a springboard for further exploration.

You can get a list of aliases with `alias` and lookup specific aliases with e.g.
`alias ri`. It allows globs, e.g. to see aliases starting with `s` do `alias
s*`.

You can get help text for any cmdlet via its long name or alias with `help`. To
use `less` instead of the default pager, do e.g.: `help gci | less`.

The profile above overrides `help` to add `-detailed` and pipe to less.

For the `git` man pages, do `git help <command>` to open the man page in your
browser, e.g. `git help config`.

I suggest using the short forms of PowerShell aliases instead of the POSIX
aliases, this forces your brain into PowerShell mode so you will mix things up
less often, with the exception of a couple of things like `mkdir` and the alias
above for `which`.

Here is a few:

| PowerShell alias              | Full cmdlet + Params                       | POSIX command                  |
|-------------------------------|--------------------------------------------|--------------------------------|
| sl                            | Set-Location                               | cd                             |
| gci -n                        | Get-ChildItem -Name                        | ls                             |
| gci                           | Get-ChildItem                              | ls -l                          |
| gi                            | Get-Item                                   | ls -d                          |
| cpi                           | Copy-Item                                  | cp -r                          |
| ri                            | Remove-Item                                | rm                             |
| ri -fo                        | Remove-Item -Force                         | rm -f                          |
| ri -r -fo                     | Remove-Item -Force -Recurse                | rm -rf                         |
| gc                            | Get-Content                                | cat                            |
| mi                            | Move-Item                                  | mv                             |
| mkdir                         | New-Item -ItemType Directory               | mkdir                          |
| which (custom)                | Get-Command                                | command -v, which              |
| gci -r                        | Get-ChildItem -Recurse                     | find                           |
| ni                            | New-Item                                   | touch <new-file>               |
| sort                          | Sort-Object                                | sort                           |
| sort -u                       | Sort-Object -Unique                        | sort -u                        |
| measure -l                    | Measure-Object -Line                       | wc -l                          |
| measure -w                    | Measure-Object -Word                       | wc -w                          |
| measure -c                    | Measure-Object -Character                  | wc -m                          |
| gc file &vert; select -first 10    | Get-Content file &vert; Select-Object -First 10 | head -n 10 file                |
| gc file &vert; select -last  10    | Get-Content file &vert; Select-Object -Last  10 | tail -n 10 file                |
| gc -wait -tail 20 some.log    | Get-Content -Wait -Tail 20 some.log        | tail -f -n 20 some.log         |

.

This will get you around and doing stuff, the usage is slightly different
however.

For one thing commands like `cpi` (`Copy-Item`) take a list of files differently
from POSIX, they must be a PowerShell list, which means separated by commas. For
example, to copy `file1` and `file2` to `dest-dir`, you would do:

```powershell
cpi file1,file2 dest-dir
```
.

To remove `file1` and `file2` you would do:

```powershell
ri file1,file2
```
.

You can list multiple globs in these lists as well as files and directories
etc., for example:

```powershell
ri .*.un~,.*.sw?
```
.

Redirection for files and commands works like in POSIX on a basic level, that
is, you can expect `<`, `>` and `|` to redirect files and commands like you
would expect on a POSIX shell. The file descriptors `0`, `1` and `2` are
`stdin`, `stdout` and `stderr` just like in POSIX.  The equivalent of
`/dev/null` is `$null`, so a command such as:

```bash
cmd >/dev/null 2>&1
```

would be:

```powershell
cmd *> $null
```
.

For `ls -ltr` use:

```powershell
gci | sort lastwritetime
```

Or the alias in my profile:

```powershell
gci | ltr
```
.

Parameters can be completed with `tab`, so in the case above you could write
`lastw<tab>`.

To see hidden files, pass `-Force` to `gci`:

```powershell
gci -fo
```
.

To make a file or directory hidden do:

```powershell
attrib +h file
```

and to make it visible do:

```powershell
attrib -h file
```
.

To make a symbolic link, do:

```powershell
ni -it sym name-of-link -tar path-to-source
```
.

Make sure the `path-to-source` is an absolute path, you can use tab completion
or `$(resolve-path file)` to ensure this.

**WARNING**: Do not use `ri` to delete a symbolic link to a directory, do this
instead:

```powershell
cmd /c rmdir symlink-to-directory
```
.

Errors for most PowerShell commands can be suppressed as follows:

```powershell
mkdir existing-dir -ea ignore
```
,

this sets `ErrorAction` to `Ignore`.

For a `find` replacement, use the `-Recurse` flag to `gci`, e.g.:

```powershell
gci -r *.cpp
```
.

To search under a specific directory, use this syntax:

```powershell
gci -r /windows -i *.dll
```

will find all DLL files in all levels under `C:\Windows`.

PowerShell supports an amazing new system called the "object pipeline", what
this means is that you can pass objects around via pipelines and inspect their
properties, call methods on them, etc..

Here is an example of using the object pipeline to delete all vim undo files:

```powershell
gci -r .*.un~ | ri
```
.

It's that simple, `ri` notices that the input objects are files, and removes
them.

If the cmdlet works on files, they can be strings as well, for example:

```powershell
gc file-list | cpi -r -dest e:/backup
```

copies the files and directories listed in my file to a directory on a USB
stick.

You can access the piped-in input in your own functions as the special `$input`
variable, like in the `head` example in the profile above.

Here is a more typical example:

```powershell
get-process | ?{ $_.name -notmatch 'svchost' } | %{ $_.name } | sort -u
```
.

Here `?{ ... }` is like filter/grep block and `%{ ... }` is like apply/map.

The equivalent of `wc -l file` to count lines is:

```powershell
gc file | measure -l
```
,
while `-w` will count words and `-c` will count characters. You can combine any
of the three in one command, the output is a table.

To get just the number of lines, you can do this:

```powershell
(gc file | measure -l).lines
```
.

Command substitution is pretty much the same as in POSIX shells, using `$( ...
)`. For example:

```powershell
vim $(gci -r *.h)
echo "This file contains $((gc README.md | measure -l).lines) lines."
```
.

In PowerShell, the backtick `` ` `` is the escape character, and you can use it
at the end of a line, escaping the line end as a line continuation character. In
regular expressions, the backslash `\` is the escape character, like everywhere
else.

Here are a couple more example of PowerShell one-liners:

```powershell
# Name and command mapping for aliases starting with 'se'.
alias se* | select name, resolvedcommand

# Create new empty files foo1 .. foo7.
1..7 | %{ ni "foo$_" }

# Find the import libraries in the Windows SDK with symbol names matching
# 'MessageBox'.
gci '/program files (x86)/windows kits/10/lib/10.*/um/x64/*.lib' | `
  %{ $_.name; dumpbin -headers $_ | grep MessageBox }
```
.

### Available Command-Line Tools and Utilities

The commands `grep`, `sed`, `awk`, `rg`, `diff`, `patch`, `less`, `zip`, `gzip`,
`unzip`, `bzip2`, `ssh`, `vim`, `nvim` (neovim) are the same as in Linux and
were installed in the list of packages installed from Chocolatey above.

You get `node` and `npm` from the nodejs package. You can install any NodeJS
utilities you need with `npm install -g <utility>`, and they will be available
in your `$env:PATH`.

The `python` tool (version 3) comes from the Chocolatey python package.

The tools `cmake` and `ninja` come with Visual Studio, if you used my sample
`$profile` section to set up the Visual Studio environment. You can get
dependencies from Conan or VCPKG, I recommend Conan because it has binary
packages. More on all that later when I expand this guide. Be sure to pass `-G
Ninja` to `cmake`.

The tool `make` is a native port of GNU Make from Chocolatey. It will generally
not run regular Linux Makefiles because it expects `cmd.exe` shell commands.
However, it is possible to write Makefiles that work in both environments if the
commands are the same, for example the one in this repository.

The commands `curl` and `tar` are now standard Windows commands. The
implementation of `tar` is not particularly wonderful, it currently does not
handle symbolic links correctly and will not save your ACLs. You can save your
ACLs with `icacls`.

For an `htop` replacement, use `ntop` (installed in the list of Chocolatey
packages above.) with my wrapper function in the sample `$profile`.

You can run any `cmd.exe` commands with `cmd /c <command>`.

Many more things are available from Chocolatey and other sources of course, at
varying degrees of functionality.

### Mounting SMB/SSHFS Folders

This is as simple as making a symbolic link to a UNC path.

For example, to mount a share on an SMB file server:

```powershell
sl ~
ni -it sym work-documents -tar //corporate-server/documents
```
.

To mount my NAS over SSHFS I can do this, assuming the Chocolatey sshfs package
is installed:

```powershell
sl ~
ni -it sym nas -tar //sshfs.kr/remoteuser@remote.host!2223/mnt/HD/HD_a2/rkitover
```
.

Here `2223` is the port for ssh. Use `sshfs.k` instead of `sshfs.kr` to specify
a path relative to your home directory.

### Miscellaneous

To get transparency in Microsoft terminal, use this AutoHotkey script:

```autohotkey
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Toggle window transparency.
#^Esc::
WinGet, TransLevel, Transparent, A
If (TransLevel = 255) {
    WinSet, Transparent, 205, A
} Else {
    WinSet, Transparent, 255, A
}
return
```
.

This will toggle transparency in a window when you press `Ctrl+Win+Esc`, you
have to press it twice the first time.

Thanks to @munael for this tip.

Note that this will not work for the Administrator PowerShell window unless you
run AutoHotkey with Administrator privileges, you can do that on startup by
creating a task.
