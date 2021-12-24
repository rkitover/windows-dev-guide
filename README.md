<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Windows Native Development Environment Setup Guide for Linux Users](#windows-native-development-environment-setup-guide-for-linux-users)
  - [Install Chocolatey and Some Packages](#install-chocolatey-and-some-packages)
  - [Chocolatey Usage Notes](#chocolatey-usage-notes)
  - [Configure the Terminal](#configure-the-terminal)
    - [Terminal Usage](#terminal-usage)
    - [Scrolling and Searching in the Terminal](#scrolling-and-searching-in-the-terminal)
    - [Transparency](#transparency)
  - [Setting up an Editor](#setting-up-an-editor)
    - [Setting up Vim](#setting-up-vim)
    - [Setting up nano](#setting-up-nano)
  - [Set up PowerShell Profile](#set-up-powershell-profile)
  - [Setting up gpg](#setting-up-gpg)
  - [Setting up ssh](#setting-up-ssh)
  - [Setting up git](#setting-up-git)
  - [PowerShell Usage Notes](#powershell-usage-notes)
  - [Elevated Access (sudo)](#elevated-access-sudo)
  - [Using PowerShell Gallery](#using-powershell-gallery)
  - [Available Command-Line Tools and Utilities](#available-command-line-tools-and-utilities)
  - [Creating Scheduled Tasks (cron)](#creating-scheduled-tasks-cron)
  - [Working With virt-manager VMs Using virt-viewer](#working-with-virt-manager-vms-using-virt-viewer)
  - [Using X11 Forwarding Over SSH](#using-x11-forwarding-over-ssh)
  - [Mounting SMB/SSHFS Folders](#mounting-smbsshfs-folders)

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
[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')
choco install -y visualstudio2019community --params '--locale en-US'
choco install -y visualstudio2019-workload-nativedesktop
choco install -y vim --params '/NoDesktopShortcuts'
choco install -y 7zip autohotkey autologon bzip2 dejavufonts diffutils gawk git gpg4win grep gzip hackfont less make microsoft-windows-terminal neovim netcat nodejs notepadplusplus NTop.Portable powershell-core python ripgrep sed sshfs StrawberryPerl unzip zip
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

Sometimes after you install a package, your terminal session will not have it in
`$env:PATH`, you can restart your terminal or run `refreshenv` re-read your
environment settings. This is also in the `$profile` below, so starting a new
tab will also work.

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
    "scrollbarState": "hidden",
    "closeOnExit": "always",
    "bellStyle": "none"
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
{ "command": { "action": "findMatch", "direction": "next" },          "keys": "ctrl+shift+n" },
{ "command": { "action": "findMatch", "direction": "prev" },          "keys": "ctrl+shift+p" },
{ "command": { "action": "scrollUp", "rowsToScroll": 1 },
  "keys": "ctrl+shift+up" },
{ "command": { "action": "scrollDown", "rowsToScroll": 1 },
  "keys": "ctrl+shift+down" }
```
.

And **REMOVE** the `CTRL+V` binding, if you want to use `CTRL+V` in vim (visual
line selection.)

This gives you a sort of "tmux" for PowerShell using tabs, and binds keys to
find next/previous match.

Note that `CTRL+SHIFT+N` is bound by default to opening a new window and
`CTRL+SHIFT+P` is bound by default to opening the command palette, if you need
these, rebind them or the original actions to something else.

Restart the terminal.

#### Terminal Usage

You can toggle full-screen mode with `F11`.

`SHIFT`+`ALT`+`+` will open a split pane vertically, while `SHIFT`+`ALT`+`-`
will open a split pane horizontally. This works in full-screen as well.

You can paste with both `SHIFT+INSERT` and `CTRL+SHIFT+V`. To copy text with my
provided configuration, simply select it.

The documentation for the terminal and a lot of other good information is here:

https://docs.microsoft.com/en-us/windows/terminal/
.

#### Scrolling and Searching in the Terminal

These are the scrolling keybinds available:

| Key                 | Action                 |
|---------------------|------------------------|
| CTRL+SHIFT+PGUP     | Scroll one page up.    |
| CTRL+SHIFT+PGDN     | Scroll one page down.  |
| CTRL+SHIFT+UP       | Scroll X lines up.     |
| CTRL+SHIFT+DOWN     | Scroll X lines down.   |

In my provided configuration, `CTRL+SHIFT+UP/DOWN` will scroll by 1 line, you
can change this to any number of lines by adjusting the `rowsToScroll`
parameter. You can even make additional keybindings for the same action but a
different keybind with a different `rowsToScroll` value.

You can scroll with your mouse scrollwheel, assuming that there is no active
application controlling the mouse.

For searching scrollback with my provided configuration, follow the following process:

1. Press `CTRL+SHIFT+F` and type in your search term in the search box that pops
   up in the upper right, the term is case-insensitive.
2. Press `ESC` to close the search box.
3. Press `CTRL+SHIFT+N` to find the first match going up, the match will be
   highlighted.
4. Press `CTRL+SHIFT+P` to find the first match going down below the current
   match.
5. To change the search term, press `CTRL+SHIFT+F` again, type in the new term,
   and press `ESC`.

You can scroll the terminal while a search is active and your match position
will be preserved.

This system is powerful enough to give you most of the functionality of a pager
without using a pager.

#### Transparency

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

You can install the `autohotkey` package from Chocolatey.

This will toggle transparency in a window when you press `CTRL+WIN+ESC`, you
have to press it twice the first time.

Thanks to @munael for this tip.

Note that this will not work for the Administrator PowerShell window unless you
run AutoHotkey with Administrator privileges, you can do that on startup by
creating a task in the Task Scheduler.

### Setting up an Editor

Here I will describe how to set up a few editors. You can use nano, vim, emacs
or vscode etc..

You can also edit files in the Visual Studio IDE using the `devenv` command.

You can use `notepad` which is in your `$env:PATH` already, and `wordpad`, for
which I added an alias in the `$profile` below.

I use vim, and the examples here are geared towards that.

If you want a very simple terminal editor that doesn't require learning how to
use it, you can use nano, see below for how to install it.

Make sure `$env:EDITOR` is set to the executable or script that launches your
editor with backslashes replaced with forward slashes so that git can use it for commit messages. See the `$profile` example below.

#### Setting up Vim

I recommend using neovim on Windows because it has working mouse support and is
almost 100% compatible with vim anyway, except in an ssh session where neovim
does not currently work for some reason.

If you are using neovim or both, run the following:

```powershell
mkdir ~/.vim -ea ignore
ni -it sym ~/vimfiles -tar $(resolve-path ~/.vim) -ea ignore
cmd /c rmdir /Q /S $(resolve-path ~/AppData/Local/nvim)
ni -it sym ~/AppData/Local/nvim -tar $(resolve-path ~/.vim)
if (-not (test-path ~/.vim/init.vim)) {
    ni ~/.vimrc -ea ignore
    ni -it sym ~/.vim/init.vim  -tar $(resolve-path ~/.vimrc)
} elseif (-not (test-path ~/.vimrc)) {
    ni -it sym ~/.vimrc         -tar $(resolve-path ~/.vim/init.vim)
}
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

$private:vim = resolve-path ~/.local/bin/nvim.bat

set-alias -name vim -val nvim

# Neovim is broken in ssh sessions, use regular vim.
if ($env:SSH_CONNECTION) {
    $vim = resolve-path ~/.local/bin/vim.bat
    ri alias:vim
}

$env:EDITOR = $vim -replace '\\','/'
```
.

In `~/.local/bin/nvim.bat` put the following for neovim:

```dosbatch
@echo off
set TERM=
/tools/neovim/neovim/bin/nvim %*
```
,

and in `~/.local/bin/vim.bat` put the following for regular vim:

```dosbatch
@echo off
set TERM=
for /f "tokens=*" %%f in ('dir /b \tools\vim\vim*') do @call set vimdir=%%f
/tools/vim/%vimdir%/vim %*
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

#### Setting up nano

Run the following:

```powershell
ri -r -fo ~/Downloads/nano-installer -ea ignore
mkdir ~/Downloads/nano-installer | out-null
pushd ~/Downloads/nano-installer
curl -sLO ("https://files.lhmouse.com/nano-win/" + $(curl -sL -o - "https://files.lhmouse.com/nano-win/" | ?{ $_ -match '.*"(nano.*\.7z)".*' } | %{ $matches[1] } | select -last 1))
7z x nano*.7z | out-null
mkdir ~/.local/bin -ea ignore | out-null
cpi -fo pkg_x86_64*/bin/nano.exe ~/.local/bin
mkdir ~/.nano -ea ignore | out-null
git clone https://github.com/scopatz/nanorc *> $null
gci -r nanorc -i *.nanorc | %{ cpi $_ ~/.nano }
popd
write ("include `"" + (($env:USERPROFILE -replace '\\','/') -replace '^[^/]+','').tolower() + "/.nano/*.nanorc`"") >> ~/.nanorc
```
.

Make sure `~/.local/bin` is in your `$env:PATH` and set `$env:EDITOR` in your
`$profile` as follows:

```powershell
$env:EDITOR = (get-command nano).source -replace '\\','/'
```
.

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

# Chocolatey profile
$chocolatey_profile = "$env:chocolateyinstall\helpers\chocolateyprofile.psm1"

if (test-path $chocolatey_profile) {
    import-module $chocolatey_profile
}

# Update environment in case the terminal session environment is not up to date.
update-sessionenvironment

$private:prepend_paths = `
    '~/.local/bin'

foreach ($path in $prepend_paths) {
    $path = resolve-path $path

    if (-not ((($env:PATH -split ';') | ? length | %{ (resolve-path $_ -ea ignore).path }) -contains $path)) {
        $env:PATH = "$path;" + $env:PATH
    }
}
# Remove Strawberry Perl MinGW stuff from PATH.
$env:PATH = ($env:PATH -split ';' | ?{ $_ -notmatch '\\Strawberry\\c\\bin$' }) -join ';'

$terminal_settings = resolve-path ~/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json

if ($env:TERM) { ri env:TERM }

$private:vim = resolve-path ~/.local/bin/nvim.bat

set-alias -name vim -val nvim

# Neovim is broken in ssh sessions, use regular vim.
if ($env:SSH_CONNECTION) {
    $vim = resolve-path ~/.local/bin/vim.bat
    ri alias:vim
}

$env:EDITOR = $vim -replace '\\','/'

# For nano:
#$env:EDITOR = (get-command nano).source -replace '\\','/'

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

# "Windows PowerShell" does not support the `e special character sequence for Escape, so we use a variable $e for this.
$e = [char]27

function format-eventlog {
    $input | %{
        write ("$e[95m[$e[34m" + ('{0:MM-dd} ' -f $_.timecreated) + `
        "$e[36m" + ('{0:HH:mm:ss}' -f $_.timecreated) + `
        "$e[95m]$e[0m " + `
        ($_.message -replace "`n.*",''))
    }
}

function syslog {
    get-winevent -log system -oldest | format-eventlog
}

# You have to enable the tasks log first as admin, see the Scheduled Tasks section below.

function tasklog {
    get-winevent 'Microsoft-Windows-TaskScheduler/Operational' -oldest | format-eventlog
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

function sudo {
    ssh localhost "sl $(pwd); $($args -join " ")"
}

function nproc {
    [environment]::processorcount
}

# Make help nicer.
$PSDefaultParameterValues = @{"help:Full"=$true}
$env:PAGER = 'less'

function which {
    $cmd = try { get-command @args -ea stop }
           catch { write-error $_ -ea stop }

    if ($cmd.commandtype -eq 'Application') {
        $cmd = $cmd.source
    }
    $cmd
}

set-alias -name notepad -val '/program files/notepad++/notepad++'
set-alias -name patch   -val $(resolve-path /prog*s/git/usr/bin/patch.exe)
set-alias -name wordpad -val $(resolve-path /prog*s/win*nt/accessories/wordpad.exe)

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
# vcvars64.bat        for x86_64 native builds.
# vcvars32.bat        for x86_32 native builds.
# vcvarsx86_arm64.bat for ARM64  cross  builds.
    cmd /c 'vcvars64.bat & set' | where { $_ -match '=' } | %{
        $var,$val = $_.split('=')
        set-item -force "env:$var" -value $val
    }
    popd
}

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

### Setting up ssh

To make sure the permissions are correct on the files in your `~/.ssh`
directory, run the following:

```powershell
&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force $(resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
```

### Setting up git

You can copy over your `~/.gitconfig` and/or run the following to set some
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

PowerShell is very different from POSIX shells, in both usage and programming.

This section won't teach you PowerShell, but it will give you enough
information to use it as a shell and a springboard for further exploration.

You can get a list of aliases with `alias` and lookup specific aliases with e.g.
`alias ri`. It allows globs, e.g. to see aliases starting with `s` do `alias
s*`.

You can get help text for any cmdlet via its long name or alias with `help -full
<cmdlet>`. To use `less` instead of the default pager, do e.g.: `help -full gci |
less`.

If you use the settings in my `$profile`, `less` will be the default pager for
`help` via `$env:PAGER`, and `-full` will be enabled by default via
`$PSDefaultParameterValues`.

You can search for documentation using globs, for example to see a list of
articles containing the word "where":

```powershell
help *where*
```
.

The conceptual documentation not related to a specific command or function takes
the form `about_XXXXX` e.g. `about_Operators`, modules you install will often
also have such a document, to see a list:

```powershell
help about_*
```
.

Run `update-help` once in a while to update all your help files.

You can get documentation for external utilities in this way:

```powershell
icacls /? | less
```
.

For documentation for cmd builtins, you can do this:

```powershell
cmd /c help for | less
```
.

For the `git` man pages, do `git help <command>` to open the man page in your
browser, e.g. `git help config`.

I suggest using the short forms of PowerShell aliases instead of the POSIX
aliases, this forces your brain into PowerShell mode so you will mix things up
less often, with the exception of a couple of things like `mkdir` and the
wrapper above for `which`.

Here are a few:

| PowerShell alias                   | Full cmdlet + Params                            | POSIX command          |
|------------------------------------|-------------------------------------------------|------------------------|
| sl                                 | Set-Location                                    | cd                     |
| gci -n                             | Get-ChildItem -Name                             | ls                     |
| gci                                | Get-ChildItem                                   | ls -l                  |
| gi                                 | Get-Item                                        | ls -ld                 |
| cpi                                | Copy-Item                                       | cp -r                  |
| ri                                 | Remove-Item                                     | rm                     |
| ri -fo                             | Remove-Item -Force                              | rm -f                  |
| ri -r -fo                          | Remove-Item -Force -Recurse                     | rm -rf                 |
| gc                                 | Get-Content                                     | cat                    |
| mi                                 | Move-Item                                       | mv                     |
| mkdir                              | New-Item -ItemType Directory                    | mkdir                  |
| which (custom)                     | Get-Command                                     | command -v, which      |
| gci -r                             | Get-ChildItem -Recurse                          | find                   |
| ni                                 | New-Item                                        | touch <new-file>       |
| sort                               | Sort-Object                                     | sort                   |
| sort -u                            | Sort-Object -Unique                             | sort -u                |
| measure -l                         | Measure-Object -Line                            | wc -l                  |
| measure -w                         | Measure-Object -Word                            | wc -w                  |
| measure -c                         | Measure-Object -Character                       | wc -m                  |
| gc file &vert; select -first 10    | Get-Content file &vert; Select-Object -First 10 | head -n 10 file        |
| gc file &vert; select -last  10    | Get-Content file &vert; Select-Object -Last  10 | tail -n 10 file        |
| gc -wait -tail 20 some.log         | Get-Content -Wait -Tail 20 some.log             | tail -f -n 20 some.log |

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

Note that globs in PowerShell are case-insensitive.

Redirection for files and commands works like in POSIX on a basic level, that
is, you can expect `>`, `>>` and `|` to redirect files and commands like you
would expect on a POSIX shell. The `<` operator is not yet available. The file descriptors `0`, `1` and `2` are
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
`lastw<TAB>`.

PowerShell relies very heavily on tab completion, and just about everything can
be tab completed. The style I present here uses short forms and abbreviations
instead, when possible.

Tab completing directories and files with spaces in them can be very annoying,
one simple fix is to use a glob, for example:

```powershell
sl /prog*s/node<TAB>
```

, will complete `'C:\Program Files\nodejs'`.

The cmdlet `Get-Command` (wrapped by `which` in the `$profile` above) will tell
you the type of a command, like `type` on bash. To get the path of an executable
use, e.g.:

```powershell
(get-command git).source
```
.

The `which` wrapper does this automatically.

`Get-Child-Item` (`gci`) and `Get-Item` (`gi`) do not only operate
on filesystem objects, but on many other kinds of objects. For example, you can
operate on registry values like a filesystem, e.g.:

```powershell
gi  HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion
gci HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion | less
```

, here `HKLM` stands for the `HKEY_LOCAL_MACHINE` section of the registry.
`HKCU` stands for `HKEY_CURRENT_USER`.

You can go into these objects and work with them similar to a filesystem, for
example try this:

```powershell
sl HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion
gci | less
sl WindowsUpdate
gci
sl ..
```

, etc..

The properties displayed and their contents will depend on the types of objects
you are working with.

The first column in filesystem directory listings from `gci` or `gi` is the mode
or attributes of the object. The positions of the letters will vary, but here is
their meaning:

| Mode Letter | Attribute Set On Object |
|-------------|-------------------------|
| l           | Link                    |
| d           | Directory               |
| a           | Archive                 |
| r           | Read-Only               |
| h           | Hidden                  |
| s           | System                  |

To see hidden files, pass `-Force` to `gci` or `gi`:

```powershell
gci -fo
gi -fo hidden-file
```
.

The best way to manipulate these attributes is with the `attrib` utility, for
example, to make a file or directory hidden do:

```powershell
attrib +h file
gi -fo file
```
, `-Force` is required for `gci` and `gi` to access hidden filesystem objects.

To make it visible do:

```powershell
attrib -h file
gi file
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
, this sets `ErrorAction` to `Ignore`.

For a `find` replacement, use the `-Recurse` flag to `gci`, e.g.:

```powershell
gci -r *.cpp
```
.

To search under a specific directory, use this syntax:

```powershell
gci -r /windows -i *.dll
```

, for example, to find all DLL files in all levels under `C:\Windows`.

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

, copies the files and directories listed in my file to a directory on a USB
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
write "This file contains $((gc README.md | measure -l).lines) lines."
```
.

There isn't really a parallel to subshells in POSIX shells, because Windows does
not use `fork()`, but immediately executed script blocks can be used for similar
purposes. The syntax is:

```powershell
&{ write "this is running in a script block" }
```
.

In PowerShell, the backtick `` ` `` is the escape character, and you can use it
at the end of a line, escaping the line end as a line continuation character. In
regular expressions, the backslash `\` is the escape character, like everywhere
else.

The backtick is also used to escape nested double quotes, but not single quotes,
for example:

```powershell
write "this `"is`" a test"
```
.

It is also used for special character sequences, here are some useful ones:

| Sequence     | Character                                      |
|--------------|------------------------------------------------|
| `n           | Newline                                        |
| `r           | Carriage Return                                |
| `b           | Backspace                                      |
| `t           | Tab                                            |
| `u{hex code} | Unicode Character by Hex Code Point            |
| `e           | Escape (not supported by "Windows PowerShell") |
| `0           | Null                                           |
| `a           | Alert (bell)                                   |

.


For example, this will print an emoji between two blank lines, indented by a tab:

```powershell
write "`n`t`u{1F47D}`n"
```
.

PowerShell script files are any sequence of commands in a `.ps1` file, and you
can run them directly:

```powershell
./script.ps1
```
.

The equivalent of `set -e` in POSIX shells is:

```powershell
$erroractionpreference = 'stop'
```
.

I highly recommend it adding it to the top of your scripts.

The bash commands `pushd` and `popd` are also available for use in your scripts.

Reading a PowerShell script into your current session works the same way as in
bash, e.g.:

```powershell
. ~/source/PowerShell/some_functions.ps1
```
, this will also work to reload your `$profile` after making changes to it:

```powershell
. $profile
```
.

Another couple of extremely useful cmdlets are `get-clipboard` and
`set-clipboard` to access the clipboard, for example:

```powershell
get-clipboard > clipboard-contents.txt
gc somefile.txt | set-clipboard
```
.

To open the explorer file manager for the current or any folder you can just run
`explorer`, e.g.:

```powershell
explorer .
explorer $(resolve-path /prog*s)
explorer shell:startup
```
.

To open a file in its associated program, similarly to `xdg-open` on Linux, use the `start` command, e.g.:

```powershell
start some_text.txt
start some_code.cpp
```
.

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

### Elevated Access (sudo)

There is currently no sudo-like utility to get elevated access in a terminal
session that is not complete garbage, however a reasonable workaround is connect
to localhost with ssh, as ssh gives you elevated access. This will not allow you
to run GUI apps with elevated access, or preserve your current location, but
most commands should work.

If you use the sudo function defined in the `$profile` I provide, then your
current location will be preserved.

This assumes you installed the ssh server as described in the [Install
Chocolatey and Some Packages](#install-chocolatey-and-some-packages) section.

To set this up:

```powershell
sl ~/.ssh
gc id_rsa.pub >> authorized_keys
```

, then make sure the permissions are correct by running the commands in the
[Setting up ssh](#setting-up-ssh) section.

Test connecting to localhost with `ssh localhost` for the first time, if
everything went well ssh will prompt you to trust the host key, and on
subsequent connections you will connect with no prompts.

You can now run console elevated commands, for example:

```powershell
sudo choco upgrade -y all
```
, the `sudo` function is defined in the sample `$profile` in the [Set up
PowerShell Profile](#set-up-powershell-profile) section.

### Using PowerShell Gallery

To enable PowerShell Gallery to install third-party modules, run this command:

```powershell
set-psrepository psgallery -installationpolicy trusted
```
.

You can then install modules using `install-module`, for example:

```powershell
install-module PSWriteColor
```
.

You can then immediately use the new module, e.g.:

```powershell
write-color -t 'foo' -c 'magenta'
```
.

To update all your modules, you can do this:

```powershell
get-installedmodule | update-module
```
.

### Available Command-Line Tools and Utilities

The commands `grep`, `sed`, `awk`, `rg`, `diff`, `patch`, `less`, `zip`, `gzip`,
`nc`, `unzip`, `bzip2`, `ssh`, `vim`, `nvim` (neovim) are the same as in Linux
and were installed in the list of packages installed from Chocolatey above.

The `patch` command comes with Git for Windows, the `$profile` above adds an
alias to it.

You get `node` and `npm` from the nodejs package. You can install any NodeJS
utilities you need with `npm install -g <utility>`, and it will be available in
your `$env:PATH`.

The `python` and `pip` tools (version 3) come from the Chocolatey python
package. There is nothing special you have to do to install modules with `pip`.

The `perl` command comes from StrawberryPerl from Chocolatey, it is mostly fully
functional and allows you to install many modules from CPAN without issues. See
the `$env:PATH` override for it in the `$profile` above.

The tools `cmake` and `ninja` come with Visual Studio, if you used my sample
`$profile` section to set up the Visual Studio environment. You can get
dependencies from Conan or VCPKG, I recommend Conan because it has binary
packages. More on all that later when I expand this guide. Be sure to pass `-G
Ninja` to `cmake`.

The Visual Studio C and C++ compiler command is `cl`. Here is a simple example:

```powershell
cl hello.c /o hello
```
.

To start the Visual Studio IDE you can use the `devenv` command.

To open a cmake project, go into the directory containing `CMakeLists.txt` and
run:

```powershell
devenv .
```
.

To debug an executable built with `-DCMAKE_BUILD_TYPE=Debug`, you can do this:

```powershell
devenv /debugexe file.exe arg1 arg2 ...
```
.

The tool `make` is a native port of GNU Make from Chocolatey. It will generally
not run regular Linux Makefiles because it expects `cmd.exe` shell commands.
However, it is possible to write Makefiles that work in both environments if the
commands are the same, for example the one in this repository.

For an `ldd` replacement, you can do this:

```powershell
dumpbin /dependents prog.exe
dumpbin /dependents somelib.dll
```
.

The commands `curl` and `tar` are now standard Windows commands. The
implementation of `tar` is not particularly wonderful, it currently does not
handle symbolic links correctly and will not save your ACLs. You can save your
ACLs with `icacls`.

For an `htop` replacement, use `ntop` (installed in the list of Chocolatey
packages above.) with my wrapper function in the sample `$profile`.

You can run any `cmd.exe` commands with `cmd /c <command>`.

Many more things are available from Chocolatey and other sources of course, at
varying degrees of functionality.

### Creating Scheduled Tasks (cron)

You can create and update tasks for the Windows Task Scheduler to run on a
certain schedule or on certain conditions with a small PowerShell script. I will
provide an example here.

First, enable the tasks log by running the following in an admin shell:

```powershell
$logname = 'Microsoft-Windows-TaskScheduler/Operational'
$log = new-object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logname
$log.isenabled=$true
$log.savechanges()
```
.

This is from:

https://stackoverflow.com/questions/23227964/how-can-i-enable-all-tasks-history-in-powershell/23228436#23228436
.

This will allow you to use the `tasklog` function from the sample `$profile`
above to view the Task Scheduler log.

This is a script called `register-task.ps1` that I use for the nightly builds
for a project. The script must be run in an elevated shell.

```powershell
$TASKNAME = 'Nightly Build'
$RUNAT    = '23:00'

$trigger = new-scheduledtasktrigger -at $RUNAT -daily

if (-not (test-path /logs)) { mkdir /logs }

$action  = new-scheduledtaskaction `
    -execute (get-command pwsh).source `
    -argument "-noprofile -executionpolicy remotesigned -command `"& '$(resolve-path $psscriptroot/build-nightly.ps1)' *>> /logs/build-nightly.log`""

$password = (get-credential $env:username).getnetworkcredential().password

register-scheduledtask -force `
    -taskname $TASKNAME `
    -trigger $trigger -action $action `
    -user $env:username `
    -password $password `
    -runlevel highest `
    -ea stop | out-null

write "Task '$TASKNAME' successfully registered to run daily at $RUNAT."

# vim:sw=4 et:
```
.

With the `-force` parameter to `register-scheduledtask`, you can update your
task settings and re-run the script and the task will be updated.

With `-runlevel` set to `highest` the task runs elevated, omit this parameter to
run with standard permissions.

You can also pass a `-settings` parameter to `register-scheduledtask` taking a
task settings object created with `new-scheduledtasksettingsset`, which allows
you to change many options for how the task is run.

You can use:

```powershell
start-scheduledtask 'Task Name'
```

, to test running your task.

To delete a task, run:

```powershell
unregister-scheduledtask -confirm:$false 'Task Name'
```
.

### Working With virt-manager VMs Using virt-viewer

Unfortunately `virt-manager` is unavailable as a native utility, if you like you
can run it using WSL or even Cygwin.

However, `virt-viewer` is available from Chocolatey and with a bit of setup can
allow you to work with your remote `virt-manager` VMs conveniently.

The first step is to edit the XML for your VMs and assign non-conflicting spice
ports bound to localhost for each one.

For example, for my Windows build VM I have:

```xml
<graphics type='spice' port='5901' autoport='no' listen='127.0.0.1'>
  <listen type='address' address='127.0.0.1'/>
</graphics>
```

, while my macOS VM uses port 5900.

Edit your sshd config and make sure the following is enabled:

```
GatewayPorts yes
```
. Restart sshd.

Then, forward the spice ports for the VMs you are interested in working with over ssh. To do that, edit your `~/.ssh/config` and set your server entry to something like the following:

```sshconfig
Host your-server
  LocalForward 5900 localhost:5900
  LocalForward 5901 localhost:5901
  LocalForward 5902 localhost:5902
```
, then if you have a tab open in the terminal with an ssh connection to your server, the ports will be forwarded.

You can also make a separate entry just for forwarding the ports with a different alias, for example:

```sshconfig
Host your-server-ports
  HostName your-server
  LocalForward 5900 localhost:5900
  LocalForward 5901 localhost:5901
  LocalForward 5902 localhost:5902
```
, and then create a continuously running task to keep the ports open, with a command such as:

```powershell
ssh -NT your-server-ports
```
.

See the [Creating Scheduled Tasks (cron)](#creating-scheduled-tasks-cron)
section for information on using tasks.

As an alternative to creating a task, you can make a startup folder shortcut,
first open the folder:

```powershell
explorer shell:startup
```

, and then create a shortcut to `pwsh`, then open the properties for the
shortcut and set the target to something like:

```powershell
"C:\Program Files\PowerShell\7\pwsh.exe" -windowstyle hidden -c "ssh -NT server-ports"
```
.

Make sure `Run:` is changed from `Normal window` to `Minimized`.

Once that is done, the last step is to install `virt-viewer` from Chocolatey and add the functions to your `$profile` for launching it for your VMs. I use these:

```powershell
function winbuilder {
    &(resolve-path 'C:\Program Files\VirtViewer*\bin\remote-viewer.exe') -f spice://localhost:5901 *> $null
}

function macbuilder {
    &(resolve-path 'C:\Program Files\VirtViewer*\bin\remote-viewer.exe') -f spice://localhost:5900 *> $null
}
```
.

Launching the function will open a full screen graphics console to your VM.

Moving your mouse cursor to the top-middle will pop down the control panel with
control and disconnect functions.

### Using X11 Forwarding Over SSH

Install `vcxsrv` from Chocolatey.

It is necessary to disable DPI scaling for this app. First, run this command in
an admin terminal:

```powershell
[environment]::setenvironmentvariable('__COMPAT_LAYER', 'HighDpiAware /M', 'machine')
```
.

Open the app folder:

```powershell
explorer $(resolve-path /progr*s/vcxsrv)
```

and open the properties for `vcxsrv.exe` and go to `Compatibility -> Change High
DPI settings` at the bottom under `High DPI scaling override` check the checkbox
for `Override high DPI scaling behavior` and under `Scaling performed by:`
select `Application`.

Reboot your computer.

Open your startup shortcuts:

```powershell
explorer shell:startup
```
and create a shortcut to `vcxsrv.exe` with the target set to:

```powershell
"C:\Program Files\VcXsrv\vcxsrv.exe" -multiwindow -clipboard -wgl
```
.

Launch the shortcut.

On your remote computer, add this function to your `~/.bashrc`:

```bash
x() {
    (
        scale=1.2
        export GDK_DPI_SCALE=$scale
        export QT_SCALE_FACTOR=$scale
        export QT_FONT_DPI=96
        export ELM_SCALE=$scale
        export XAUTHORITY=$HOME/.Xauthority
        export GTK_THEME=Adwaita:dark
        # Install libqt5-qtstyleplugins and qt5ct and configure your Qt style with the qt5ct GUI.
        export QT_PLATFORM_PLUGIN=qt5ct
        export QT_QPA_PLATFORMTHEME=qt5ct
        ("$@" >/dev/null 2>&1 &) &
    ) >/dev/null 2>&1
}
```
.

Edit your remote computer sshd config and make sure the following is enabled:

```
X11Forwarding yes
```
. Restart sshd.

On the local computer, edit `~/.ssh/config` and set the configuration for your
remote computer as follows:

```sshconfig
Host remote-computer
  ForwardX11 yes
  ForwardX11Trusted yes
```
.

Make sure `$env:DISPLAY` is set in your `$profile` as follows:

```powershell
$env:DISPLAY = '127.0.0.1:0.0'
```
.

Open a new ssh session to the remote computer.

You can now open X11 apps with the `x` function you added to your `~/.bashrc`,
e.g.:

```bash
x gedit ~/.bashrc
```

Set your desired scale in the `~/.bashrc` function and configure the appearance
for your Qt apps with qt5ct.

One huge benefit of this setup is that you can use `xclip` on your remote
computer to put things into your local clipboard.

### Mounting SMB/SSHFS Folders

This is as simple as making a symbolic link to a UNC path.

For example, to mount a share on an SMB file server:

```powershell
sl ~
ni -it sym work-documents -tar //corporate-server/documents
```
.

To mount my NAS over SSHFS I can do this, assuming the Chocolatey `sshfs`
package is installed:

```powershell
sl ~
ni -it sym nas -tar //sshfs.kr/remoteuser@remote.host!2223/mnt/HD/HD_a2/username
```
.

Here `2223` is the port for ssh. Use `sshfs.k` instead of `sshfs.kr` to specify
a path relative to your home directory.
