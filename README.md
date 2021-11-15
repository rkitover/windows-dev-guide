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
  - [Miscellaneous](#miscellaneous)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Windows Native Development Environment Setup Guide for Linux Users

### Install Chocolatey and Some Packages

Make sure developer mode is turned on in Windows settings, this is necessary for
making unprivileged symlinks.

- Press Win+X and open Windows PowerShell (administrator).

- Run these commands:

```powershell
Set-ExecutionPolicy -Scope LocalMachine -Force RemoteSigned
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

Close the administrator PowerShell window and open it again.

Install some chocolatey packages:

```powershell
choco install -y visualstudio2019community --params '--locale en-US'
choco install -y visualstudio2019-workload-nativedesktop
choco install -y hackfont dejavufonts ripgrep git gpg4win microsoft-windows-terminal powershell-core vim neovim zip unzip notepadplusplus diffutils patch ntop.portable grep gawk sed less gzip
# Copy your .ssh over to your profile directly first preferrably:
stop-service ssh-agent
sc.exe delete ssh-agent
choco install -y openssh --params '/SSHServerFeature /SSHAgentFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe'
```

### Chocolatey Usage Notes

Here are some commands for using the Chocolatey package manager.

To search for a package:

```powershell
choco search patch
```

To get the description of a package:

```powershell
choco info patch
```

To install a package:

```powershell
choco install -y patch
```

To uninstall a package:


```powershell
choco uninstall -y patch
```

To list installed packages:

```powershell
choco list --local
```

To update all installed packages:

```powershell
choco update -y all
```

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

I prefer the 'SF Mono' font which you can get here:

https://github.com/supercomputra/SF-Mono-Font

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

And **REMOVE** the `ctrl+v` binding, if you want to use `ctrl+v` in vim (visual
line selection.)

This gives you a sort of "tmux" for powershell using tabs.

Restart the terminal.

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
ni -itemtype symboliclink ~/AppData/Local/nvim -target $(resolve-path ~/.vim)
ri ~/.vim/init.vim -ea ignore
ni -itemtype symboliclink ~/.vim/init.vim      -target $(resolve-path ~/.vimrc)
```

You can edit your powershell profile with `vim $profile`, and reload it with `.
$profile`.

Add the following to your `$profile`:

```powershell
if ($env:TERM) { ri env:TERM }
$env:EDITOR = resolve-path ~/.local/bin/vim.bat
```

In `~/.local/bin/vim.bat` put the following for neovim:

```bat
@echo off
set TERM=
nvim %*
```

or the following for regular vim:

```bat
@echo off
set TERM=
c:\windows\vim.bat %*
```

This is needed for git to work correctly with native vim.

Some suggestions for your `~/.vimrc`:

```vim
set encoding=utf8
set langmenu=en_US.UTF-8
let g:is_bash=1
set formatlistpat=^\\s*\\%([-*][\ \\t]\\\|\\d+[\\]:.)}\\t\ ]\\)\\s*
set ruler bg=dark nohlsearch bs=2 noea ai fo+=n undofile modeline belloff=all
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

If you use my posh-git prompt, you'll need the git version of posh-git:

```powershell
mkdir ~/source/repos -ea ignore
cd ~/source/repos
git clone https://github.com/dahlbyk/posh-git
```

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
$env:EDITOR = (resolve-path ~/.local/bin/vim.bat).path -replace '\\','/'

if (test-path ~/source/repos/vcpkg) {
    $env:VCPKG_ROOT = resolve-path ~/source/repos/vcpkg
}

function megs {
    gci -rec $args | select mode, lastwritetime, @{name="MegaBytes"; expression = { [math]::round($_.length / 1MB, 2) }}, name
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

function syslog {
    get-winevent -log system | less
}

function taskslog {
    get-winevent 'Microsoft-Windows-TaskScheduler/Operational' 
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

set-alias -name which   -val get-command
set-alias -name notepad -val '/program files/notepad++/notepad++'

# To use neovim instead of vim for mouse support:
set-alias -name vim     -val nvim

if (test-path alias:diff) { remove-item -force alias:diff }

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
        ([char]27) + '[0;32mv' + ([char]27) + '[0m'
    }
    else {
        ([char]27) + '[0;31mx' + ([char]27) + '[0m'
    }
}

$gitpromptsettings.defaultpromptabbreviatehomedirectory      = $true

$gitpromptsettings.defaultpromptprefix.text                  = '$(PromptWriteErrorInfo) '

$username = $env:USERNAME
$hostname = $env:COMPUTERNAME.ToLower()

$gitpromptsettings.defaultpromptwritestatusfirst             = $false
$gitpromptsettings.defaultpromptbeforesuffix.text            = "`n$username@$hostname "
$gitpromptsettings.defaultpromptbeforesuffix.foregroundcolor = 0x87CEFA
$gitpromptsettings.defaultpromptsuffix.foregroundcolor       = 0xDC143C

$gitpromptsettings.windowtitle = $null
$host.ui.rawui.windowtitle = $hostname

import-module psreadline

set-psreadlineoption     -editmode emacs
set-psreadlinekeyhandler -key tab       -function complete
set-psreadlinekeyhandler -key uparrow   -function historysearchbackward
set-psreadlinekeyhandler -key downarrow -function historysearchforward
```

This profile works for "Windows PowerShell", the powershell you launch from the
`Win+X` menu as well. But the profile is in a different file, so you will need
to copy it there too:

```powershell
mkdir ~/Documents/WindowsPowerShell
cpi ~/Documents/PowerShell/Microsoft.Powershell_profile.ps1 ~/Documents/WindowsPowerShell
```

### Setting up gpg

Make this symlink:

```powershell
sl ~
mkdir .gnupg -ea ignore
cmd /c rmdir /Q /S $(resolve-path ~/AppData/Roaming/gnupg)
ni -itemtype symboliclink ~/AppData/Roaming/gnupg -target $(resolve-path ~/.gnupg)
```

Then you can copy your `.gnupg` over, without the socket files.

To configure git to use it, do the following:

```powershell
git config --global commit.gpgsign true
git config --global gpg.program 'C:\Program Files (x86)\GnuPG\bin\gpg.exe'
```

### Setting up sshd

Edit `\ProgramData\ssh\sshd_config` and remove or comment out this section:

```
Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

Then run:

```powershell
restart-service sshd
```

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

### PowerShell Usage Notes

PowerShell is very different from unix shells, in both usage and programming.

This section won't teach you PowerShell, but it will give you enough
information to use it as a shell and a springboard for further exploration.

You can get a list of aliases with `alias` and lookup specific aliases with e.g.
`alias ri`. It allows globs, e.g. to see aliases starting with `s` do `alias
s*`.

You can get help text for any cmdlet via its long name or alias with `help`. To
use `less` instead of the default pager, do e.g.: `help gci | less`.

For the `git` man pages, do `git help <command>` to open the man page in your
browser, e.g. `git help config`.

I suggest using the short forms of PowerShell aliases instead of the POSIX
aliases, this forces your brain into PowerShell mode so you will mix things up
less often, with the exception of a couple of things like `mkdir` and the alias
above for `which`.

Here is a few:

| PowerShell alias | Full cmdlet + Params          | POSIX command     |
|------------------|-------------------------------|-------------------|
| sl               | Set-Location                  | cd                |
| gci              | Get-ChildItem                 | ls                |
| gi               | Get-Item                      | ls -d             |
| cpi              | Copy-Item                     | cp -r             |
| ri               | Remove-Item                   | rm                |
| ri -for          | Remove-Item -Force            | rm -f             |
| ri -rec -for     | Remove-Item -Force -Recurse   | rm -rf            |
| gc               | Get-Content                   | cat               |
| mi               | Move-Item                     | mv                |
| mkdir            | New-Item -ItemType Directory  | mkdir             |
| which (custom)   | Get-Command                   | command -v, which |
| gci -rec         | Get-ChildItem -Recurse        | find              |
| ni               | New-Item                      | touch <new-file>  |
| sort             | Sort-Object                   | sort              |
| sort -u          | Sort-Object -Unique           | sort -u           |

This will get you around and doing stuff, the usage is slightly different
however.

For one thing commands like `cpi` (`Copy-Item`) take a list of files differently
from POSIX, they must be a PowerShell list, which means separated by commas. For
example, to copy `file1` and `file2` to `dest-dir`, you would do:

```powershell
cpi file1,file2 dest-dir
```

To remove `file1` and `file2` you would do:

```powershell
ri file1,file2
```

You can list multiple globs in these lists as well as files and directories
etc., for example:

```powershell
ri .*.un~,.*.sw?
```

The commands `grep`, `sed`, `awk`, `rg`, `diff`, `patch`, `less`, `zip`, `gzip`, `unzip`, `ssh`, `vim`, `nvim` (neovim) are the same as in Linux and were
installed in the list of packages installed from Chocolatey above.

The commands `curl` and `tar` are now standard Windows commands.

For an `htop` replacement, use `ntop` (installed in the list of Chocolatey
packages above.) with my wrapper function in the sample `$profile`.

Redirection for files and commands works like in POSIX on a basic level, that
is, you can expect `<`, `>` and `|` to redirect files and commands like you
would expect on a POSIX shell. `/dev/null` is `$null`, so the equivalent of

```bash
cmd >/dev/null 2>&1
```

would be:

```powershell
cmd *> $null
```

For `ls -ltr` use:

```powershell
gci | sort lastwritetime
```

Or the alias in my profile:

```powershell
gci | ltr
```

Parameters can be completed with `tab`, so in the case above you could write
`lastw<tab>`.

To make a symbolic link, do:

```powershell
ni -itemtype symboliclink name-of-link -target path-to-source
```

again the parameters `-ItemType` and `SymbolicLink` can be `tab` completed.

Errors for most PowerShell commands can be suppressed as follows:

```powershell
mkdir existing-dir -ea ignore
```

this sets `ErrorAction` to `Ignore`.

For a `find` replacement, use the `-Recurse` flag to `gci`, e.g.:

```powershell
gci -rec *.cpp
```
.

To search under a specific directory, prepend it to the glob, for example:

```powershell
gci -rec /windows/*.dll
```

would find all DLL files in all levels under `C:\Windows`.


PowerShell supports an amazing new system called the "object pipeline", what
this means is that you can pass objects around via pipelines and inspect their
properties, call methods on them, etc..

Here is an example of using the object pipeline to delete all vim undo files:

```powershell
gci -rec .*.un~ | ri
```

it's that simple, `ri` notices that the input objects are files, and removes
them.

You can access the piped-in input in your own functions as the special `$input`
variable, like in the `head` example in the profile above.

Here is a more typical example:

```powershell
get-process | ?{ $_.name -notmatch 'svchost' } | %{ $_.name } | sort -uniq
```

here `?{ ... }` is like filter/grep block and `%{ ... }` is like apply/map.

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

This will toggle transparency in a window when you press `Ctrl+Win+Esc`, you
have to press it twice the first time.

Thanks to @munael for this tip.
