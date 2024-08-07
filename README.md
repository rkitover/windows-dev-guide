
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Windows Native Development Environment Setup Guide for Linux Users](#windows-native-development-environment-setup-guide-for-linux-users)
  - [Introduction](#introduction)
  - [Installing Visual Studio, Some Packages and Scoop](#installing-visual-studio-some-packages-and-scoop)
  - [winget and scoop notes](#winget-and-scoop-notes)
  - [Configure the Terminal](#configure-the-terminal)
    - [Terminal Usage](#terminal-usage)
    - [Scrolling and Searching in the Terminal](#scrolling-and-searching-in-the-terminal)
    - [Transparency (Old Method)](#transparency-old-method)
  - [Setting up an Editor](#setting-up-an-editor)
    - [Setting up Vim](#setting-up-vim)
    - [Setting up nano](#setting-up-nano)
  - [Setting up PowerShell](#setting-up-powershell)
  - [Setting up ssh](#setting-up-ssh)
  - [Setting up and Using Git](#setting-up-and-using-git)
    - [Git Setup](#git-setup)
    - [Using Git](#using-git)
    - [Dealing with Line Endings](#dealing-with-line-endings)
  - [Setting up gpg](#setting-up-gpg)
  - [Profile (Home) Directory Structure](#profile-home-directory-structure)
  - [PowerShell Usage Notes](#powershell-usage-notes)
    - [Introduction](#introduction-1)
    - [Finding Documentation](#finding-documentation)
    - [Commands, Parameters and Environment](#commands-parameters-and-environment)
    - [Values, Arrays and Hashes](#values-arrays-and-hashes)
    - [Redirection, Streams, $input and Exit Codes](#redirection-streams-input-and-exit-codes)
    - [Command/Expression Sequencing Operators](#commandexpression-sequencing-operators)
    - [Commands and Operations on Filesystems and Filesystem-Like Objects](#commands-and-operations-on-filesystems-and-filesystem-like-objects)
    - [Pipelines](#pipelines)
    - [The Measure-Object Cmdlet](#the-measure-object-cmdlet)
    - [Sub-Expressions and Strings](#sub-expressions-and-strings)
    - [Script Blocks and Scopes](#script-blocks-and-scopes)
    - [Using and Writing Scripts](#using-and-writing-scripts)
    - [Writing Simple Modules](#writing-simple-modules)
    - [Miscellaneous Usage Tips](#miscellaneous-usage-tips)
  - [Elevated Access (sudo)](#elevated-access-sudo)
  - [Using PowerShell Gallery](#using-powershell-gallery)
  - [Available Command-Line Tools and Utilities](#available-command-line-tools-and-utilities)
  - [Using tmux/screen with PowerShell](#using-tmuxscreen-with-powershell)
  - [Creating Scheduled Tasks (cron)](#creating-scheduled-tasks-cron)
  - [Working With virt-manager VMs Using virt-viewer](#working-with-virt-manager-vms-using-virt-viewer)
  - [Using X11 Forwarding Over SSH](#using-x11-forwarding-over-ssh)
  - [Mounting SMB/SSHFS Folders](#mounting-smbsshfs-folders)
  - [Appendix A: Chocolatey Usage Notes](#appendix-a-chocolatey-usage-notes)
    - [Chocolatey Filesystem Structure](#chocolatey-filesystem-structure)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Windows Native Development Environment Setup Guide for Linux Users

### Introduction

This guide is intended for experienced developers familiar with
Linux or other UNIX-like operating systems who want to set up a
native Windows terminal development environment. I will walk you
through setting up and using the package manager, terminal, vim,
gpg, git, ssh, Visual Studio build tools, and PowerShell. I will
explain basic PowerShell usage which will allow you to use it as a
shell and write simple scripts.

This is a work in progress and there are sometimes typos and
grammatical or ordering mistakes as I keep editing it, or bugs in
the [`$profile`](#setting-up-powershell) or setup code, so make any
necessary adjustments.

I am planning to make many more expansions covering for example
things like using `cmake` with `vcpkg` or `Conan` etc..

Your feedback via issues or pull requests on Github is appreciated.

### Installing Visual Studio, Some Packages and Scoop

Make sure developer mode is turned on in Windows settings, this is necessary for
making unprivileged symlinks. Also in developer settings, change powershell
execution policy to RemoteSigned.

- Press Win+X and open PowerShell (Administrator).

Run this script, which is in the repo, like so:

```powershell
./install.ps1
```
, it installs some winget packages, the Visual Studio C++ workload, sets up the
OpenSSH server and sets some QOL improvement settings.

If you want to use the Chocolatey package manager instead of winget and scoop,
see [Appendix A: Chocolatey Usage Notes](#appendix-a-chocolatey-usage-notes).

[//]: # "BEGIN INCLUDED install.ps1"

```powershell
[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')

set-service beep -startuptype disabled

'Microsoft.VisualStudio.2022.Community','7zip.7zip','gsass1.NTop','Git.Git',`
'GnuPG.GnuPG','SourceFoundry.HackFonts','Neovim.Neovim','OpenJS.NodeJS',`
'Notepad++.Notepad++','Microsoft.Powershell','Python.Python.3.13',`
'SSHFS-Win.SSHFS-Win','Microsoft.OpenSSH.Beta','Microsoft.WindowsTerminal' | %{
	winget install $_
}

iwr https://aka.ms/vs/17/release/vs_community.exe -outfile vs_community.exe

./vs_community.exe --passive --add 'Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended;includeOptional'

start-process powershell '-noprofile', '-windowstyle', 'hidden', `
    '-command', "while (test-path $pwd/vs_community.exe) { sleep 5; ri -fo $pwd/vs_community.exe }"

new-itemproperty -path "HKLM:\SOFTWARE\OpenSSH" -name DefaultShell -value '/Program Files/PowerShell/7/pwsh.exe' -propertytype string -force > $null

(gc /programdata/ssh/sshd_config) | %{ $_ -replace '^([^#].*administrators.*)','#$1' } | set-content /programdata/ssh/sshd_config

set-service sshd -startuptype automatic
set-service ssh-agent -startuptype automatic

restart-service sshd
restart-service ssh-agent
```
. If `winget` exits abnormally, update this app from the Windows
Store:

https://apps.microsoft.com/detail/9nblggh4nns1

. If something fails in the script, run it again until everything
succeeds.

- Press Win+X and open PowerShell (**NOT** Administrator)

Now run the user-mode install script:
```powershell
./install-user.ps1
```
, which installs scoop and some scoop packages of UNIX ports, and fixes your
`~/.ssh` files permissions, copy it over first, but you can do this
[later](#setting-up-ssh) as well.

[//]: # "BEGIN INCLUDED install-user.ps1"

```powershell
ni -it sym ~/.config -tar ($env:USERPROFILE + '\AppData\Local') -ea ignore

if (-not (test-path ~/scoop)) {
    iwr get.scoop.sh | iex
}

~/scoop/shims/scoop.cmd install bzip2 diffutils dos2unix file gawk grep gzip less make ripgrep sed zip unzip
~/scoop/shims/scoop.cmd bucket add nerd-fonts
~/scoop/shims/scoop.cmd install DejaVuSansMono-NF

&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
```
.

### winget and scoop notes

To update your winget packages, run this in either a user or admin PowerShell:

```powershell
winget upgrade --all
```
, to update your scoop packages, run this in a normal user
PowerShell:

```powershell
scoop update *
```
. Never run scoop in an elevated shell, only as the user.

Use `winget search` and `scoop search` to look for packages, and `install` to
install them, and `list` to see locally installed packages.

### Configure the Terminal

Launch the Windows Terminal and choose Settings from the tab
drop-down, this will open the settings json in visual studio.

In the global settings, above the `"profiles"` section, add:

```jsonc
// If enabled, formatted data is also copied to your clipboard
"copyFormatting": "all",
"focusFollowMouse": true,
// If enabled, selections are automatically copied to your clipboard.
"copyOnSelect": true,
"tabSwitcherMode": "disabled",
"tabWidthMode": "equal",
"wordDelimiters": " ",
"largePasteWarning": false,
"multiLinePasteWarning": false,
"windowingBehavior": "useAnyExisting",
```
. In the `"profiles"` `"defaults"` section add:

```jsonc
"defaults":
{
    // Put settings here that you want to apply to all profiles.
    "adjustIndistinguishableColors": false,
    "font": 
    {
        "face": "Hack",
        "weight": "light",
        "size": 11
    },
    "antialiasingMode": "cleartype",
    "cursorShape": "filledBox",
    "colorScheme": "Tango Dark",
    "intenseTextStyle": "bold",
    "padding": "0",
    "scrollbarState": "hidden",
    "closeOnExit": "always",
    "bellStyle": "none",
    "intenseTextStyle": "bold",
    "useAcrylic": false,
    "opacity": 77
},
```
. The settings `useAcrylic` and `opacity` make the terminal
transparent, leave those out or set `opacity` to 100 to turn this
off.

I prefer the 'SF Mono' font which you can get here:

https://github.com/supercomputra/SF-Mono-Font

. Other fonts you might like are `IBM Plex Mono` which you can
install from:

https://github.com/IBM/plex

, and 'DejaVu Sans Mono' which was in the [list of
packages](#installing-visual-studio-some-packages-and-scoop).

The Terminal also comes with a nice new Microsoft font called
"Cascadia Code", if you leave out the `"face": "<name>",` line, it
will use it instead.

You can get the newest version of Cascadia Code and the version with
Powerline glyphs called "Cascadia Code PL" from here:

https://github.com/microsoft/cascadia-code/releases?WT.mc_id=-blog-scottha

, you will need it if you decide to use the `oh-my-posh` prompt
described [here](#setting-up-powershell).

In the profile list section, in the entry that lists:

```jsonc
"source": "Windows.Terminal.PowershellCore"
```
, add this:

```jsonc
"commandline": "pwsh -nologp"
```
. You can do the same for the "Windows PowerShell" profile if you
like.

In the `"actions"` section add these keybindings:

```jsonc
{ "command": null, "keys": "alt+enter" },
{ "command": { "action": "newTab"  }, "keys": "ctrl+shift+t" },
{ "command": { "action": "nextTab" }, "keys": "ctrl+shift+right" },
{ "command": { "action": "prevTab" }, "keys": "ctrl+shift+left" },
{ "command": { "action": "findMatch", "direction": "next" },          "keys": "ctrl+shift+n" },
{ "command": { "action": "findMatch", "direction": "prev" },          "keys": "ctrl+shift+p" },
{ "command": { "action": "scrollUp", "rowsToScroll": 1 },
  "keys": "ctrl+shift+up" },
{ "command": { "action": "scrollDown", "rowsToScroll": 1 },
  "keys": "ctrl+shift+down" }
```
. And **REMOVE** the `CTRL+V` binding, if you want to use `CTRL+V`
in vim (visual line selection.)

This gives you a sort of "tmux" for PowerShell using tabs, and binds
keys to find next/previous match.

Note that `CTRL+SHIFT+N` is bound by default to opening a new window
and `CTRL+SHIFT+P` is bound by default to opening the command
palette, if you need these, rebind them or the original actions to
something else.

Restart the terminal.

#### Terminal Usage

You can toggle full-screen mode with `F11`.

`SHIFT`+`ALT`+`+` will open a split pane vertically, while
`SHIFT`+`ALT`+`-` will open a split pane horizontally. This works in
full-screen as well.

You can paste with the right mouse button, `SHIFT+INSERT` and
`CTRL+SHIFT+V`. To copy text with `"copyOnSelect"` enabled, simply
select it, or press `CTRL`+`SHIFT`+`C` otherwise.

The documentation for the terminal and a lot of other good information is here:

https://docs.microsoft.com/en-us/windows/terminal/
.

#### Scrolling and Searching in the Terminal

These are the scrolling keybinds available with this configuration:

| Key                 | Action                 |
|---------------------|------------------------|
| CTRL+SHIFT+PGUP     | Scroll one page up.    |
| CTRL+SHIFT+PGDN     | Scroll one page down.  |
| CTRL+SHIFT+UP       | Scroll X lines up.     |
| CTRL+SHIFT+DOWN     | Scroll X lines down.   |

`CTRL+SHIFT+UP/DOWN` will scroll by 1 line, you can change this to
any number of lines by adjusting the `rowsToScroll` parameter. You
can even make additional keybindings for the same action but a
different keybind with a different `rowsToScroll` value.

You can scroll with your mouse scrollwheel, assuming that there is
no active application controlling the mouse.

For searching scrollback with this configuration, follow the
following process:

1. Press `CTRL+SHIFT+F` and type in your search term in the search
   box that pops up in the upper right, the term is
   case-insensitive.
2. Press `ESC` to close the search box.
3. Press `CTRL+SHIFT+N` to find the first match going up, the match
   will be highlighted.
4. Press `CTRL+SHIFT+P` to find the first match going down below the
   current match.
5. To change the search term, press `CTRL+SHIFT+F` again, type in
   the new term, and press `ESC`.

You can scroll the terminal while a search is active and your match
position will be preserved.

#### Transparency (Old Method)

The transparency configuration in the terminal described
[above](#configure-the-terminal) works correctly with neovim but not
regular vim. For older versions of Terminal or to get transparency
in regular vim, use the autohotkey method described here. You can
install autohotkey from winget using the id `AutoHotkey.AutoHotkey`.

This is the autohotkey script:

```autohotkey
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Toggle window transparency.
#^Esc::
WinGet, TransLevel, Transparent, A
If (TransLevel = 255) {
    WinSet, Transparent, 180, A
} Else {
    WinSet, Transparent, 255, A
}
return
```
. This will toggle transparency in a window when you press
`CTRL+WIN+ESC`, you have to press it twice the first time.

Thanks to @munael for this tip.

Note that this will not work for the Administrator PowerShell window
unless you run AutoHotkey with Administrator privileges, you can do
that on logon by creating a task in the Task Scheduler.

### Setting up an Editor

In this section I will describe how to set up a couple of editors.

You can also edit files in the Visual Studio IDE using the `devenv` command.

You can use `notepad` which is in your `$env:PATH` already or
`notepad++`.

If you want a very simple terminal editor that is easy to use, you
can use [nano](#setting-up-nano), it has nice syntax highlighting
too.

Make sure `$env:EDITOR` is set to the executable or `.bat` file that
launches your editor with backslashes replaced with forward slashes
and make sure that it does not contain any spaces. Set it in your
[`$profile`](#setting-up-powershell) so that git can use it for
commit messages. For example:

```powershell
$private:nano = resolve-path ~/.local/bin/nano.exe
$env:EDITOR = $nano -replace '\\','/'
```
. This will also work well with things you use from UNIX-compatible
environments like Cygwin, MSYS2, etc. if you end up doing that.

Another option is to set it in Git config, which will override the
environment variables, for example:

```powershell
get config --global core.editor (get-command notepad++).source
```
.

#### Setting up Vim

I recommend using Neovim on Windows because it has working mouse
support and is almost 100% compatible with vim. It also works
correctly with transparency in Windows Terminal with a black
background unlike the port of regular vim.

If you want to use the regular vim, the winget id is `vim.vim`.

If you are using neovim only, you can copy your `~/.config/nvim`
over directly, to `~/AppData/Local/nvim`. 

You can edit your powershell profile with `vim $profile`, and reload
it with `.  $profile`.

Look at the included [`$profile`](#setting-up-powershell) for how to
set up a vim alias and set `$env:EDITOR` so that it will work with
Git.

Some suggestions for your `~/.vimrc`, all of this works in both
vims:

[//]: # "BEGIN INCLUDED .vimrc"

```vim
set encoding=utf8
set langmenu=en_US.UTF-8
let g:is_bash=1
set formatlistpat=^\\s*\\%([-*][\ \\t]\\\|\\d+[\\]:.)}\\t\ ]\\)\\s*
set ruler bg=dark nohlsearch bs=2 noea ai fo+=n undofile modeline belloff=all modeline modelines=5
set fileformats=unix,dos

set mouse=a

" Add vcpkg includes to include search path to get completions for C++.
let g:home = fnamemodify('~', ':p')

if isdirectory(g:home . 'source/repos/vcpkg/installed/x64-windows/include')
  let &path .= ',' . g:home . 'source/repos/vcpkg/installed/x64-windows/include'
endif

if isdirectory(g:home . 'source/repos/vcpkg/installed/x64-windows-static/include')
  let &path .= ',' . g:home . 'source/repos/vcpkg/installed/x64-windows-static/include'
endif

if !has('gui_running') && match($TERM, "screen") == -1
  set termguicolors
  au ColorScheme * hi Normal ctermbg=0
endif

if has('gui_running')
  au ColorScheme * hi Normal guibg=#000000

  if has('win32')
    set guifont=Hack:h11:cANSI
  endif
endif

if has('win32') || has('gui_win32')
  if executable('pwsh')
    set shell=pwsh
  else
    set shell=powershell
  endif

  set shellquote= shellpipe=\| shellredir=> shellxquote=
  set shellcmdflag=-nologo\ -noprofile\ -executionpolicy\ remotesigned\ -noninteractive\ -command
endif

filetype plugin indent on
syntax enable

au BufRead COMMIT_EDITMSG,*.md setlocal spell
au BufRead COMMIT_EDITMSG so $VIMRUNTIME/syntax/gitcommit.vim | set tw=72
au BufRead *.md  setlocal tw=80
au FileType json setlocal ft=jsonc sw=4 et

" Return to last edit position when opening files.
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Fix syntax highlighting on CTRL+L.
noremap  <C-L> <Esc>:syntax sync fromstart<CR>:redraw<CR>
inoremap <C-L> <C-o>:syntax sync fromstart<CR><C-o>:redraw<CR>

" Markdown
let g:markdown_fenced_languages = ['css', 'javascript', 'js=javascript', 'json=javascript', 'jsonc=javascript', 'xml', 'ps1', 'powershell=ps1', 'sh', 'bash=sh', 'autohotkey', 'vim', 'sshconfig', 'dosbatch', 'gitconfig']
```
. You can use Plug or pathogen or whatever you prefer to install
plugins.

I highly recommend subscribing to GitHub Copilot and using the vim
plugin which you can get here:

https://github.com/github/copilot.vim

. I use this color scheme, which is a fork of Apprentice for black
backgrounds:

https://github.com/rkitover/Apprentice

You'll probably want the PowerShell support for vim including syntax
highlighting which is here:

https://github.com/PProvost/vim-ps1

. I also use vim-sleuth to detect indent settings and vim-markdown
for better markdown support including syntax highlighting in code
blocks.

#### Setting up nano

Run this script, from this repo using:

```powershell
./nanosetup.ps1
```
, this is the script:

[//]: # "BEGIN INCLUDED nanosetup.ps1"

```powershell
$erroractionpreference = 'stop'

$releases = 'https://files.lhmouse.com/nano-win/'

ri -r -fo ~/nano-installer -ea ignore
mkdir ~/nano-installer | out-null
pushd ~/nano-installer
curl -sLO ($releases + (
    iwr -usebasicparsing $releases | % links |
    ? href -match '\.7z$' | select -last 1 | % href
))
7z x nano*.7z | out-null
mkdir ~/.local/bin -ea ignore | out-null
cpi -fo pkg_x86_64*/bin/nano.exe ~/.local/bin
mkdir ~/.nano -ea ignore | out-null
git clone https://github.com/scopatz/nanorc *> $null
gci -r nanorc -i *.nanorc | cpi -dest ~/.nano
popd
("include `"" + (($env:USERPROFILE -replace '\\','/') `
    -replace '^[^/]+','').tolower() + `
    "/.nano/*.nanorc`"") >> ~/.nanorc

ri -r -fo ~/nano-installer

gi ~/.nanorc,~/.nano,~/.local/bin/nano.exe
```

. Make sure `~/.local/bin` is in your `$env:PATH` and set
`$env:EDITOR` in your [`$profile`](#setting-up-powershell) as follows:

```powershell
$env:EDITOR = (get-command nano).source -replace '\\','/'
```

, or configure Git like so:

```powershell
git config --global core.editor (get-command nano).source
```
.

### Setting up PowerShell

To install the pretty oh-my-posh prompt, run this:

```powershell
winget install jandedobbeleer.ohmyposh
```
, the profile below will set it up for you. You will need a font
with Powerline glyphs, like "Cascadia Code PL", see [setting up the
terminal](#configure-the-terminal).

If you want to use my
[posh-git](https://github.com/dahlbyk/posh-git) theme, install the
module
[posh-git-theme-bluelotus](https://github.com/rkitover/posh-git-theme-bluelotus)
from [PSGallery](#using-powershell-gallery).

You can also install [posh-git](https://github.com/dahlbyk/posh-git)
and make your own
[customizations](https://github.com/dahlbyk/posh-git/wiki/Customizing-Your-PowerShell-Prompt).

Here is a profile to get you started, it has a few examples of
functions and aliases which you will invariably write for yourself.

To edit your `$profile`, you can do:

```powershell
vim $profile
```
, or

```powershell
notepad $profile
```
. If you cloned this repo, you can dot-source mine in yours by
adding this:

```powershell
. ~/source/repos/windows-dev-guide/profile.ps1
```
, you can also link or copy this profile to yours and add your own
things in `~/Documents/PowerShell/private-profile.ps1`, which will
be automatically read with the path set in `$profile_private`.

Or just copy the parts you are interested in to yours.

[//]: # "BEGIN INCLUDED profile.ps1"

```powershell
# Windows PowerShell does not have OS automatic variables.
if (-not (test-path variable:global:iswindows)) {
    $global:IsWindows = $false
    $global:IsLinux   = $false
    $global:IsMacOS   = $false

    if (get-command get-cimsession -ea ignore) {
        $global:IsWindows = $true
    }
    elseif (test-path /System/Library/Extensions) {
        $global:IsMacOS   = $true
    }
    else {
        $global:IsLinux   = $true
    }
}

import-module packagemanagement,powershellget

if ($iswindows) {
    [Console]::OutputEncoding = [Console]::InputEncoding `
        = $OutputEncoding = new-object System.Text.UTF8Encoding

    set-executionpolicy -scope currentuser remotesigned

    [System.Globalization.CultureInfo]::CurrentCulture = 'en-US'

    if ($private:chocolatey_profile = resolve-path (
            "$env:chocolateyinstall\helpers\chocolateyprofile.psm1"`
        ) -ea ignore) {

        import-module $chocolatey_profile
    }

    # Update environment in case the terminal session environment
    # is not up to date, but first clear VS env so it does not
    # accumulate duplicates.
    gci env: | % name `
        | ?{ $_ -match '^(__VSCMD|INCLUDE$|LIB$|LIBPATH$)' } `
        | %{ ri env:\$_ }

    if (get-command -ea ignore update-sessionenvironment) {
        update-sessionenvironment
    }

    # Tell Chocolatey to not add code to $profile.
    $env:ChocolateyNoProfile = 'yes'
}
elseif (-not $env:LANG) {
    $env:LANG = 'en_US.UTF-8'
}

# Make help nicer.
$psdefaultparametervalues["get-help:full"] = $true
$env:PAGER = 'less'

# Turn on these options for less:
#    -Q,--QUIET             # No bells.
#    -r,--raw-control-chars # Show ANSI colors.
#    -X,--no-init           # No term init, does not use alt screen.
#    -F,--quit-if-one-screen
#    -K,--quit-on-intr      # Quit on CTRL-C immediately.
#    --mouse                # Scroll with mouse wheel.
$env:LESS = '-Q$-r$-X$-F$-K$--mouse'

new-module MyProfile -script {

$path_sep = [system.io.path]::pathseparator
$dir_sep  = [system.io.path]::directoryseparatorchar

$global:ps_share_dir = if ($iswindows) {
    '~/AppData/Roaming/Microsoft/Windows/PowerShell'
}
else {
    '~/.local/share/powershell'
}

function split_env_path {
    $env:PATH -split $path_sep | ? length | %{
        resolve-path $_ -ea ignore | % path
    } | ? length
}

function sysdrive {
    if ($iswindows) { $env:SystemDrive }
}

function trim_sysdrive($str) {
    if (-not $str) { $str = $input }

    if (-not $iswindows) { return $str }

    $str -replace ('^'+[regex]::escape((sysdrive))),''
}

function home_to_tilde($str) {
    if (-not $str) { $str = $input }

    $home_dir_re = [regex]::escape($home)
    $dir_sep_re  = [regex]::escape($dir_sep)

    $str -replace ('^'+$home_dir_re+"($dir_sep_re"+'|$)'),'~$1'
}

function backslashes_to_forward($str) {
    if (-not $str) { $str = $input }

    if (-not $iswindows) { return $str }

    $str -replace '\\','/'
}

function global:shortpath($str) {
    if (-not $str) { $str = $($input) }

    $str | resolve-path -ea ignore | % path `
        | trim_sysdrive | backslashes_to_forward
}

function global:realpath($str) {
    if (-not $str) { $str = $($input) }

    $str | resolve-path -ea ignore | % path | backslashes_to_forward
}

function global:syspath($str) {
    if (-not $str) { $str = $($input) }

    $str | resolve-path -ea ignore | % path
}

if ($iswindows) {
    # Replace OneDrive Documents path in $profile with ~/Documents
    # symlink, if you have one.
    if ((gi ~/Documents -ea ignore).target -match 'OneDrive') {
        $global:profile = $profile -replace 'OneDrive\\',''
    }

    # Remove Strawberry Perl MinGW stuff from PATH.
    $env:PATH = (split_env_path |
        ?{ $_ -notmatch '\bStrawberry\\c\\bin$' }
    ) -join $path_sep

    # Add npm module bin wrappers to PATH.
    if (resolve-path ~/AppData/Roaming/npm -ea ignore) {
        $env:PATH += ';' + (gi ~/AppData/Roaming/npm)
    }
}

$global:profile = $profile | shortpath

$global:ps_config_dir = split-path $profile -parent

$global:ps_history = "$ps_share_dir/PSReadLine/ConsoleHost_history.txt"

if ($iswindows) {
    $global:terminal_settings = resolve-path ~/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json -ea ignore | shortpath
    $global:terminal_settings_preview = resolve-path ~/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_*/LocalState/settings.json -ea ignore | shortpath

    if (-not $global:terminal_settings -and $global:terminal_settings_preview) {
        $global:terminal_settings = $global:terminal_settings_preview
    }
}

$extra_paths = @{
    prepend = '~/.local/bin'
    append  = '~/AppData/Roaming/Python/Python*/Scripts',
              '/program files/VcXsrv'
}

foreach ($section in $extra_paths.keys) {
    foreach ($path in $extra_paths[$section]) {
        if (-not ($path = resolve-path $path -ea ignore)) {
            continue
        }

        if (-not ((split_env_path) -contains $path)) {
            $env:PATH = $(if ($section -eq 'prepend') {
                $path,$env:PATH
            }
            else {
                $env:PATH,$path
            }) -join $path_sep
        }
    }
}

if (-not $env:TERM) {
    $env:TERM = 'xterm-256color'
}
elseif ($env:TERM -match '^(xterm|screen|tmux)$') {
    $env:TERM = $matches[0] + '-256color'
}

if (-not $env:COLORTERM) {
    $env:COLORTERM = 'truecolor'
}

if (-not $env:VCPKG_ROOT) {
    $env:VCPKG_ROOT = resolve-path ~/source/repos/vcpkg -ea ignore
}

$global:vcpkg_toolchain = $env:VCPKG_ROOT + '/scripts/buildsystems/vcpkg.cmake'

if (-not $env:DISPLAY) {
    $env:DISPLAY = '127.0.0.1:0.0'
}

if (-not $env:XAUTHORITY) {
    $env:XAUTHORITY = join-path $home .Xauthority

    if (-not (test-path $env:XAUTHORITY) `
        -and (
          ($xauth = (get-command -commandtype application xauth -ea ignore).source) `
          -or ($xauth = (gi '/program files/VcXsrv/xauth.exe' -ea ignore).fullname) `
        )) {

        $cookie = (1..4 | %{ "{0:x8}" -f (get-random) }) -join ''

        xauth add ':0' . $cookie | out-null
    }
}

function global:megs {
    if (-not $args) { $args = $input }

    gci @args | select mode, lastwritetime, @{ name="MegaBytes"; expression={ [math]::round($_.length / 1MB, 2) }}, name
}

function global:cmconf {
    sls 'CMAKE_BUILD_TYPE|VCPKG_TARGET_TRIPLET|UPSTREAM_RELEASE' CMakeCache.txt
}

function global:cmclean {
    ri -r CMakeCache.txt,CMakeFiles -ea ignore
}

# Windows PowerShell does not have Remove-Alias.
function global:rmalias($alias) {
    # Use a loop to remove aliases from all scopes.
    while (test-path "alias:\$alias") {
        ri -force "alias:\$alias"
    }
}

function is_ext_cmd($cmd) {
    (get-command $cmd -ea ignore).commandtype `
        -cmatch '^(Application|ExternalScript)$'
}

# Check if invocation of external command works correctly.
function ext_cmd_works($exe) {
    $works = $false

    if (-not (is_ext_cmd $exe)) {
        write-error 'not an external command' -ea stop
    }

    $($input | &$exe @args | out-null; $works = $?) 2>&1 `
        | sv err_out

    $works -and -not $err_out
}

function global:%? { $input | %{ $_ } | ?{ $_ } }

function global:which {
    $cmd = try { get-command @args -ea stop | select -first 1 }
           catch { write-error $_ -ea stop }

    if (is_ext_cmd $cmd) {
        $cmd = $cmd.source | shortpath
    }
    elseif ($cmd.commandtype -eq 'Alias' `
            -and (is_ext_cmd $cmd.Definition)) {

        $cmd = $cmd.definition | shortpath
    }

    $cmd
}

rmalias type

function global:type {
    try { which @args } catch { write-error $_ -ea stop }
}

function global:command {
    # Remove -v etc. for now.
    if ($args[0] -match '^-') { $null,$args = $args }

    try {
        which @args -commandtype application,externalscript
    } catch { write-error $_ -ea stop }
}

function ver_windows {
    $osver = [environment]::osversion.version
    $major = $osver.major
    $build = $osver.build

    if ($major -eq 10 -and $build -gt 22000) {
        $major = 11
    }

    try {
        $arch = [System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture
    } catch {}

    'Windows {0} build {1}{2}' `
        -f $major,
           $build,
           $(if ($arch) { " $arch" })
}

function global:ver {
    if ($iswindows) {
        ver_windows
    }
    else {
        $uname_parts = $(if     ($islinux) { 'sri' }
                         elseif ($ismacos) { 'srm' }
                       ).getenumerator() | %{ uname "-$_" }

        # Remove -xxx-xxx suffixes from kernel versions.
        if ($islinux) {
            $uname_parts[1] = $uname_parts[1] -replace '-.*',''
        }

        "{0} kernel {1} {2}" -f $uname_parts
    }
}

function global:mklink {
    $usage = 'args: [link] target'

    $args = $args | %{ $_ } | ? length

    if (-not $args) { $args = @($input) }

    while ($args.count -gt 2 -and $args[0] -match '^/[A-Z]$') {
        $null,$args = $args
    }

    if (-not $args -or $args.count -gt 2) {
        write-error $usage -ea stop
    }

    $link,$target = $args

    if (-not $target) {
        $target = $link

        if (-not (split-path -parent $target)) {
            write-error ($usage + "`n" + 'cannot make link with the same name as target') -ea stop
        }

        $link = split-path -leaf $target
    }

    if (-not ($link_parent = split-path -parent $link)) {
        $link_parent = get-location | % path
    }
    if (-not ($target_parent = split-path -parent $target)) {
        $target_parent = get-location | % path
    }

    $link_parent = try {
        $link_parent | resolve-path -ea stop | % path
    }
    catch { write-error $_ -ea stop }

    if (-not (resolve-path $target -ea ignore)) {
        write-warning "target '${target}' does not yet exist"
    }

    $absolute = @{
        link   = join-path $link_parent   (split-path -leaf $link)
        target = join-path $target_parent (split-path -leaf $target)
    }

    $home_dir_re = [regex]::escape($home)
    $dir_sep_re  = [regex]::escape($dir_sep)

    $in_home = @{}

    $absolute.getenumerator() | %{
      if ($_.value -match ('^'+$home_dir_re+"($dir_sep_re"+'|$)')) {
        $in_home[$_.key] = $true
      }
    }

    # If target is in home, make sure ~ is resolved.
    #
    # Make sure relative links are relative to link parent
    # (::ispathrooted() does not understand ~ paths and considers
    # them relative.)
    #
    # And if both link and target are in home dir, force relative
    # link, this is to make backups/copies/moves and SMB shares of
    # the home/profile dir easier and less error-prone.
    $target = if (-not (
                      $in_home.target `
                      -or [system.io.path]::ispathrooted($target)
                  ) -or $in_home.count -eq 2) {

        pushd $link_parent
        resolve-path -relative $absolute.target
        popd
    }
    else {
        $absolute.target
    }

    if (-not $iswindows -or $psversiontable.psversion.major -ge 6) {
        # PSCore.
        try {
            new-item -itemtype symboliclink $absolute.link `
                -target $target -ea stop
        }
        catch { write-error $_ -ea stop }
    }
    else {
        # WinPS or older.
        $params = @(
            if (test-path -pathtype container $target) { '/D' }
        )
        cmd /c mklink @params $absolute.link $target
        if (-not $?) { write-error "exited: $lastexitcode" -ea stop }
    }
}

function global:rmlink {
    $args = @($input),$args | %{ $_ } | ? length

    if (-not $args) {
        write-error 'args: link1 [link2 ...]' -ea stop
    }

    $args | %{
        try { $_ = gi $_ -ea stop }
        catch { write-error $_ -ea stop }

        if (-not $_.target) {
            write-error "$_ is not a symbolic link" -ea stop
        }

        if ((test-path -pathtype container $_) `
            -and $iswindows `
            -and $psversiontable.psversion.major -lt 7) {

            # In WinPS remove-item does not work for dir links.
            cmd /c rmdir $_
            if (-not $?) { write-error "exited: $lastexitcode" -ea stop }
        }
        else {
            try { ri $_ }
            catch { write-error $_ -ea stop }
        }
    }
}

# Find neovim or vim and set $env:EDITOR, prefer neovim.
if ($iswindows) {
    $vim = ''

    $locs =
        { (get-command nvim.exe @args).source },
        { resolve-path /tools/neovim/nvim*/bin/nvim.exe @args },
        { (get-command vim.exe @args).source },
        { (get-command vim.bat @args).source },
        { resolve-path /tools/vim/vim*/vim.exe @args }

    foreach ($loc in $locs) {
        if ($vim = &$loc -ea ignore) { break }
    }

    if ($vim) {
        set-alias vim -value $vim -scope global

        if ($vim -match 'nvim') {
            set-alias nvim -value $vim -scope global
        }

        # Remove spaces from path if possible, because this breaks UNIX ports.
        $env:EDITOR = realpath $vim `
            | %{ $_ -replace '/Program Files/','/progra~1/' } `
            | %{ $_ -replace '/Program Files (x86)/','/progra~2/' } `
    }
}
else {
    $env:EDITOR = 'vim'
}

# Windows PowerShell does not support the `e special character
# sequence for Escape, so we use a variable $e for this.
$e = [char]27

if ($iswindows) {
    function global:pgrep($pat) {
        if (-not $pat) { $pat = $($input) }

        get-ciminstance win32_process -filter "name like '%${pat}%' OR commandline like '%${pat}%'" | select ProcessId,Name,CommandLine
    }

    function global:pkill($proc) {
        if (-not $proc) { $proc = $($input) }

        if ($pid = $proc.ProcessId) {
            stop-process $pid
        }
        else {
            pgrep $proc | %{ stop-process $_.ProcessId }
        }
    }

    function format-eventlog {
        $input | %{
            ("$e[95m[$e[34m" + ('{0:MM-dd} ' -f $_.timecreated) `
            + "$e[36m" + ('{0:HH:mm:ss}' -f $_.timecreated) `
            + "$e[95m]$e[0m " `
            + $_.message) | out-string
        }
    }

    function global:syslog {
        get-winevent -log system -oldest | format-eventlog | less
    }

    # You have to enable the tasks log first as admin, see:
    # https://stackoverflow.com/q/13965997/262458
    function global:tasklog {
        get-winevent 'Microsoft-Windows-TaskScheduler/Operational' `
            -oldest | format-eventlog | less
    }

    function global:ntop {
        ntop.exe -s 'CPU%' @args
        if (-not $?) { write-error "exited: $lastexitcode" -ea stop }
    }

    function head_tail([scriptblock]$cmd, $arglist) {
        $lines =
            if ($arglist.length -and $arglist[0] -match '^-(.+)') {
                $null,$arglist = $arglist
                $matches[1]
            }
            else { 10 }

        if (!$arglist.length) {
            $input | &$cmd $lines
        }
        else {
            gc $arglist | &$cmd $lines
        }
    }

    function global:head {
        $input | head_tail { $input | select -first @args } $args
    }

    function global:tail {
        $input | head_tail { $input | select -last @args  } $args
    }

    function global:touch {
        if (-not $args) { $args = $input }

        $args | %{ $_ } | %{
            if (test-path $_) {
                (gi $_).lastwritetime = get-date
            }
            else {
                ni $_ | out-null
            }
        }
    }

    function global:sudo {
        $cmd = [management.automation.invocationinfo].getproperty('ScriptPosition',
            [reflection.bindingflags] 'instance, nonpublic').getvalue($myinvocation).text -replace '^\s*sudo\s*',''

        ssh localhost -- "sl '$(get-location)'; $cmd"
    }

    function global:nproc {
        [environment]::processorcount
    }

    # To see what a choco shim is pointing to.
    function global:readshim {
        if (-not $args) { $args = $input }

        $args | %{ $_ } |
            %{ get-command $_ -commandtype application `
                -ea ignore } | %{ $_.source } | `
                # winget symlinks
            %{ if ($link_target = (gi $_).target) {
                    $link_target | shortpath
                }
                # scoop shims
                elseif (test-path ($shim = $_ -replace '\.exe$','.shim')) {
                    gc $shim | %{ $_ -replace '^path = "([^"]+)"$','$1' } | shortpath
                }
                # chocolatey shims
                elseif (&$_ --shimgen-help) {
                    $_ | ?{ $_ -match "^ Target: '(.*)'$" } `
                       | %{ $matches[1] } | shortpath
                }
            }
    }

    function global:env {
        gci env: | sort name | %{
            "`${{env:{0}}}='{1}'" -f $_.name,$_.value
        }
    }

    # Tries to reset the terminal to a sane state, similar to the Linux reset
    # binary from ncurses-utils.
    function global:reset {
        [char]27 + "[!p"
        clear-host
    }

    function global:tmux {
        wsl tmux -f '~/.tmux-pwsh.conf' @args
    }
}
elseif ($ismacos) {
    function global:ls {
        if (-not $args) { $args = $input }
        &(command ls) -Gh @args
        if (-not $?) { write-error "exited: $lastexitcode" -ea stop }
    }
}
elseif ($islinux) {
    function global:ls {
        if (-not $args) { $args = $input }
        &(command ls) --color=auto -h @args
        if (-not $?) { write-error "exited: $lastexitcode" -ea stop }
    }
}

if (-not (test-path function:global:grep) `
    -and (get-command -commandtype application grep -ea ignore) `
    -and ('foo' | ext_cmd_works (command grep) --color foo)) {

    function global:grep {
        $input | &(command grep) --color @args
        if (-not $?) { write-error "exited: $lastexitcode" -ea stop }
    }
}

rmalias gl
rmalias pwd

function global:gl  { get-location | % path | shortpath }
function global:pwd { get-location | % path | shortpath }

function global:ltr { $input | sort lastwritetime }

function global:count { $input | measure | % count }

# Example utility function to convert CSS hex color codes to rgb(x,x,x) color codes.
function global:hexcolortorgb {
    if (-not ($color = $args[0])) { $color = $($input) }

    'rgb(' + ((($args[0] -replace '^(#|0x)','' -split '(..)(..)(..)')[1,2,3] | %{ [uint32]"0x$_" }) -join ',') + ')'
}

function map_alias {
    $input | %{ $_.getenumerator() | %{
        $path = $_.value

        # Expand any globs in path.
        if ($parent = split-path -parent $path) {
            if ($parent = resolve-path $parent -ea ignore) {
                $path = join-path $parent (split-path -leaf $path)
            }
            else {
                return
            }
        }

        if ($cmd = get-command $path -ea ignore) {
            rmalias $_.key

            $type = $cmd.commandtype

            $cmd = if ($type `
                    -cmatch '^(Application|ExternalScript)$') {

                $cmd.source
            }
            elseif ($type -cmatch '^(Cmdlet|Function)$') {
                $cmd.name
            }
            else {
                throw "Cannot alias command of type '$type'."
            }

            set-alias $_.key -value $cmd -scope global
        }
    }}
}

if ($iswindows) {
    @{
        patch   = '/prog*s/git/usr/bin/patch'
        wordpad = '/prog*s/win*nt/accessories/wordpad'
        ssh     = '/prog*s/OpenSSH-*/ssh.exe'
        '7zfm'  = '/prog*s/7-zip/7zfm.exe'
    } | map_alias
}

$cmds = @{}

foreach ($cmd in 'perl','diff','colordiff','tac') {
    $cmds[$cmd] = try {
        get-command -commandtype application,externalscript $cmd `
            -ea ignore | select -first 1 | % source
    }
    catch { $null }
}

# For diff on Windows install diffutils from choco.
#
# Clone git@github.com:daveewart/colordiff to ~/source/repos
# for colors.
if ($cmds.diff) {
    rmalias diff
    rmalias colordiff

    $cmd = $clone = $null
    $prepend_args = @()

    function global:diff {
        $args = $prepend_args,$args

        $rc = 2

        @( $input | &$cmd @args; $rc = $lastexitcode ) | less -Q -r -X -F -K --mouse

        if ($rc -ge 2) {
            write-error "exited: $rc" -ea stop
        }
    }

    $cmd = if ($cmds.colordiff) {
        $cmds.colordiff
    }
    elseif ($cmds.perl -and ($clone = resolve-path `
                ~/source/repos/colordiff/colordiff.pl `
                -ea ignore)) {
        $prepend_args = @($clone)
        $cmds.perl
    }
    else {
        $cmds.diff
    }

    if ($cmds.colordiff -or $clone) {
        set-alias -scope global colordiff -value diff
    }
}

@{
    vcpkg = '~/source/repos/vcpkg/vcpkg'
} | map_alias

if (-not $cmds.tac) {
    function global:tac {
        $file = if ($args) { gc $args } else { @($input) }

        $file[($file.count - 1) .. 0]
    }
}

# Aliases to pwsh Cmdlets/functions.
set-alias s -value select-object -scope global

if ($iswindows) {
    # Load VS env only once.
    :OUTER foreach ($vs_year in '2022','2019','2017') {
        foreach ($vs_type in 'preview','buildtools','community') {
            foreach ($x86 in '',' (x86)') {
                $vs_path="/program files${x86}/microsoft visual studio/${vs_year}/${vs_type}/vc/auxiliary/build"

                if (test-path $vs_path) {
                    break OUTER
                }
                else {
                    $vs_path=$null
                }
            }
        }
    }

    if ($vs_path) {
        $saved_vcpkg_root = $env:VCPKG_ROOT

        pushd $vs_path
        cmd /c 'vcvars64.bat & set' | ?{ $_ -match '=' } | %{
#        cmd /c 'vcvars32.bat & set' | ?{ $_ -match '=' } | %{
#        cmd /c 'vcvarsamd64_arm64.bat & set' | ?{ $_ -match '=' } | %{
            $var,$val = $_.split('=')
            set-item -force "env:\$var" -val $val
        }
        popd

        if ($saved_vcpkg_root) {
            $env:VCPKG_ROOT = $saved_vcpkg_root
        }
    }
}

# Remove duplicates from $env:PATH.
$env:PATH = (split_env_path | select -unique) -join $path_sep

} | import-module

# This is my posh-git prompt theme:
if (get-module -listavailable posh-git-theme-bluelotus) {
    import-module posh-git-theme-bluelotus

# If you want the posh-git window title, uncomment this:
#
#    $gitpromptsettings.windowtitle =
#        $gitprompt_theme_bluelotus.originalwindowtitle;
}
elseif (get-command oh-my-posh -ea ignore) {
    oh-my-posh --init --shell pwsh `
        --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/paradox.omp.json' | iex
}

if (-not (get-module posh-git) `
    -and (get-module -listavailable posh-git)) {

    import-module posh-git
}

if (-not (get-module psreadline)) {
    import-module psreadline
}

set-psreadlineoption -editmode emacs
set-psreadlineoption -historysearchcursormovestoend
set-psreadlineoption -bellstyle none

set-psreadlinekeyhandler -key tab       -function complete
set-psreadlinekeyhandler -key uparrow   -function historysearchbackward
set-psreadlinekeyhandler -key downarrow -function historysearchforward

set-psreadlinekeyhandler -chord 'ctrl+spacebar' -function menucomplete
set-psreadlinekeyhandler -chord 'alt+enter'     -function addline

if ($private:posh_vcpkg = `
    resolve-path ~/source/repos/vcpkg/scripts/posh-vcpkg `
        -ea ignore) {

    import-module $posh_vcpkg
}

if ($private:src = `
    resolve-path $ps_config_dir/private-profile.ps1 `
        -ea ignore) {

    $global:profile_private = $src | shortpath

    . $profile_private
}

# vim:set sw=4 et:
```
. This profile works for "Windows PowerShell" as well. But the profile
is in a different file, so you will need to make a symlink there to
your PowerShell `$profile`.

```powershell
mkdir ~/Documents/WindowsPowerShell
ni -it sym ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1 -tar $profile
```
. Be aware that if your Documents are in OneDrive, OneDrive will
ignore and not sync symlinks.

This `$profile` also works for PowerShell for Linux and macOS.

The utility functions it defines are described [here](#available-command-line-tools-and-utilities).

### Setting up ssh

To make sure the permissions are correct on the files in your
`~/.ssh` directory, run the following:

```powershell
&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
```
.

### Setting up and Using Git

#### Git Setup

You can copy over your `~/.gitconfig` and/or run the following to
set some settings I recommend:

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

#### Using Git

Git usage from PowerShell is pretty much the same as on Linux, with
a couple of caveats.

Arguments containing special characters like `:` or `.` must be
quoted, for example:

```powershell
git tag -s 'v5.41' -m'v5.41'
git push origin ':refs/heads/some-branch'
```
. The `.git` directory is hidden, to see it use:

```powershell
gci -fo
# or
gi -fo .git
```
. **NEVER** run the command:

```powershell
ri -r -fo *
```
. On Linux, the `*` glob does match dot files like `.git`, but on
Windows it matches everything.

The command:

```powershell
ri -r *
```
, is safe because hidden files like `.git` are not affected without `-Force`.

Because `.git` is a hidden directory, this also means that to delete a cloned repository, you must pass `-Force` to `Remove-Item`, e.g.:

```powershell
ri -r -fo somerepo
```
.

#### Dealing with Line Endings

With `core.autocrlf` set to `false`, the files in your checkouts
will have UNIX line endings, but occasionally you need a project to
have DOS line endings, for example if you use PowerShell scripts to
edit the files in the project. In this case, it's best to make a
`.gitattributes` file in the root of your project and commit it,
containing for example:

```console
* text=auto
*.exe binary
```
. Make sure to add exclusions for all binary file types you need.

This way, anyone cloning the repo will have the correct line
endings.

### Setting up gpg

Make this symlink:

```powershell
sl ~
mkdir .gnupg -ea ignore
cmd /c rmdir (resolve-path ~/AppData/Roaming/gnupg)
ni -it sym ~/AppData/Roaming/gnupg -tar (resolve-path ~/.gnupg)
```
. Then you can copy your `.gnupg` over, without the socket files.

To configure git to use it, do the following:

```powershell
git config --global commit.gpgsign true
git config --global gpg.program 'C:\Program Files (x86)\GnuPG\bin\gpg.exe'
```
.

### Profile (Home) Directory Structure

Your Windows profile directory, analogous to a UNIX home directory,
will usually be something like `C:\Users\username`, it may be on a
server share if you are using a domain in an organization.

The automatic PowerShell variable `$home` will contain the path to
your profile directory as well as the environment variable
`$env:USERPROFILE`. You can use the environment variable in things
such as Explorer using the cmd syntax, e.g. try entering
`%USERPFOFILE%` in the Explorer address bar.

The `~/AppData` directory is analogous to the Linux `~/.config`
directory, except it has two parts, `Local` and `Roaming`. The
`Roaming` directory may be synced by various things across your
computers, and the `Local` directory is generally intended for your
specific computer configurations.

It is up to any particular application whether it uses the `Local`
or `Roaming` directory, or both, and for what. When backing up any
particular application configuration, check if it uses one or the
other or both.

The [install
script](#installing-visual-studio-some-packages-and-scoop) makes a
`~/.config` symlink pointing to `~/AppData/Local`. This is adequate
for some Linux ports such as Neovim.

There is one other important difference you must be aware of. When
you uninstall an application on Windows, it will often **DELETE**
its configuration directory or directories under `~/AppData`. This
is one reason why in this guide I give instructions for making a
directory under your `$home` and symlinking the `AppData` directory
to it. Make sure you backup your terminal `settings.json` for this
reason as well.

### PowerShell Usage Notes

#### Introduction

PowerShell is very different from POSIX shells, in both usage and
programming.

This section won't teach you PowerShell, but it will give you enough
information to use it as a shell, write basic scripts and be a
springboard for further exploration.

You must be aware that when PowerShell is discussed, there are two
versions that are commonly used, Windows PowerShell or WinPS for
short, and PowerShell Core or PSCore for short.

Windows PowerShell is the standard `powershell` command in Windows,
and you can rely on it being installed on any Windows system. It is
currently version `5.1` of PowerShell with some extra patches and
backported security fixes by Microsoft.

PowerShell Core is the latest release from the open source
PowerShell project. Currently this is `7.2.1` but will almost
certainly be higher when you are reading this. If installed, it will
be available in `$env:PATH` as the `pwsh` command.

You can see your PowerShell version with:

```powershell
$PSVersionTable
```
. Everything in this guide is compatible with both versions, except
when I explicitly state that it isn't.

WinPS is not as nice for interactive use as PSCore, but for writing
scripts and modules you have just about all the facilities of the
language available, except for a few new features like ternaries
which I won't cover here. I recommend targeting WinPS for any
scripts or modules that you will write.

#### Finding Documentation

You can get a list of aliases with `alias` and lookup specific
aliases with e.g. `alias ri`. It allows globs, e.g. to see aliases
starting with `s` do `alias s*`.

You can get help text for any Cmdlet via its long name or alias with
`help -full <Cmdlet>`. To use `less` instead of the default pager,
do e.g.: `help -full gci | less`.

In the [`$profile`](#setting-up-powershell), `less` is set to the
default pager for `help` via `$env:PAGER`, and `-full` is enabled by
default via `$PSDefaultParameterValues`.

You can use tab completion to find help topics and search for
documentation using globs, for example to see a list of articles
containing the word "where":

```powershell
help *where*
```
. The conceptual documentation not related to a specific command or
function takes the form `about_XXXXX` e.g. `about_Operators`,
modules you install will often also have such a document, to see a
list do:

```powershell
help about_*
```
. Run `update-help` once in a while to update all your help files.

You can get documentation for external utilities in this way:

```powershell
icacls /? | less
```
. For documentation for cmd builtins, you can do this:

```powershell
cmd /c help for | less
```
. For the `git` man pages, use `git help <command>` to open the man
page in your browser, e.g.:

```powershell
git help config
```
.

#### Commands, Parameters and Environment

I suggest using the short forms of PowerShell aliases instead of the
POSIX aliases, this forces your brain into PowerShell mode so you
will mix things up less often, with the exception of a couple of
things that are easier to type like `mkdir`, `ps` or `kill` or some
of the wrappers in the [`$profile`](#setting-up-powershell).

Here are a few:

| PowerShell alias                   | Full Cmdlet + Params                                  | POSIX command          |
|------------------------------------|-------------------------------------------------------|------------------------|
| sl                                 | Set-Location                                          | cd                     |
| gl                                 | Get-Location                                          | pwd                    |
| gci -n                             | Get-ChildItem -Name                                   | ls                     |
| gci                                | Get-ChildItem                                         | ls -l                  |
| gi                                 | Get-Item                                              | ls -ld                 |
| cpi                                | Copy-Item                                             | cp -r                  |
| ri                                 | Remove-Item                                           | rm                     |
| ri -fo                             | Remove-Item -Force                                    | rm -f                  |
| ri -r -fo                          | Remove-Item -Force -Recurse                           | rm -rf                 |
| gc                                 | Get-Content                                           | cat                    |
| mi                                 | Move-Item                                             | mv                     |
| mkdir                              | New-Item -ItemType Directory                          | mkdir                  |
| which (custom)                     | Get-Command                                           | command -v, which      |
| gci -r                             | Get-ChildItem -Recurse                                | find                   |
| ni                                 | New-Item                                              | touch <new-file>       |
| sls -ca                            | Select-String -CaseSensitive                          | grep                   |
| sls                                | Select-String                                         | grep -i                |
| gci -r | sls -ca                   | Get-ChildItem -Recurse | Select-String -CaseSensitive | grep -r                |
| sort                               | Sort-Object                                           | sort                   |
| sort -u                            | Sort-Object -Unique                                   | sort -u                |
| measure -l                         | Measure-Object -Line                                  | wc -l                  |
| measure -w                         | Measure-Object -Word                                  | wc -w                  |
| measure -c                         | Measure-Object -Character                             | wc -m                  |
| gc file &vert; select -first 10    | Get-Content file &vert; Select-Object -First 10       | head -n 10 file        |
| gc file &vert; select -last  10    | Get-Content file &vert; Select-Object -Last  10       | tail -n 10 file        |
| gc -wait -tail 20 some.log         | Get-Content -Wait -Tail 20 some.log                   | tail -f -n 20 some.log |
| iex                                | Invoke-Expression                                     | eval                   |

. This will get you around and doing stuff, the usage is slightly
different however.

For one thing commands like `cpi` (`Copy-Item`) take a list of files
differently from POSIX, they must be a PowerShell list, which means
separated by commas. For example, to copy `file1` and `file2` to
`dest-dir`, you would do:

```powershell
cpi file1,file2 dest-dir
```
. To remove `file1` and `file2` you would do:

```powershell
ri file1,file2
```
. You can list multiple globs in these lists as well as files and
directories etc., for example:

```powershell
ri .*.un~,.*.sw?
```
. Note that globs in PowerShell are case-insensitive.

Also, unlike Linux, the `*` glob will match all files including
`.dotfiles`. Windows uses a different mechanism for hidden files,
see below.

PowerShell relies very heavily on tab completion, and just about
everything can be tab completed. The style I present here uses short
forms and abbreviations instead, when possible.

Tab completing directories and files with spaces in them can be
annoying, for example:

```powershell
sl /prog<TAB>
```
, will show the completion `C:\Program`. If you want to complete
`C:\Program Files` type `` `<SPACE> `` and it will be completed with
a starting quote. More on the `` ` `` escape character later.

For completing `/Program Files` it's easier to use DOS short alias
`/progra~1` and for `/Program Files (x86)` the `/progra~2` alias.
The [`$profile`](#setting-up-powershell) defines the variable
`$ps_history` for the command history file location which is
analogous to `~/.bash_history` on Linux, you can view it with e.g.:

```powershell
less $ps_history
```
. Command-line editing and history search works about the same way
as in bash. I have also defined the `PSReadLine` options to make up
arrow not only cycle through previous commands, but will also allow
you to type the beginning of a previous command and cycle through
matches.

For examining variables and objects, unlike in POSIX shells, a value
will be formatted for output implicitly and you do not have to
`echo` it, to write a message you can just use a string, to examine
a variable you can just input it directly, for example:

```powershell
'Operation was successful!'
"The date today is: {0}" -f (get-date)
$profile
$env:PAGER
```
. As you can see here, there is a difference between normal
variables and environment variables, which are prefixed with `env:`,
which is a `PSDrive`, more on that later.

Many commands you will use in PowerShell will, in fact, yield
objects that will use the format defined for them to present
themselves on the terminal. For example `gci` or `gi`. You can
change these formats too.

The Cmdlet `Get-Command` will tell you the type of a command, like
`type` on bash. To get the path of an executable use, e.g.:

```powershell
(get-command git).source
```
. The [`$profile`](#setting-up-powershell) `which`,`type` and
`command` wrappers do this automatically.

#### Values, Arrays and Hashes

One very nice feature of PowerShell is that it very often allows you
to use single values and arrays interchangeably. Arrays are created
by using the `,` comma operator to list multiple values, or
assigning the result of a command that returns multiple values.

```powershell
$val = 'a string'
$val.count # 1
$arr = 'foo',,'bar','baz'
$arr.count # 3

$val | %{ $_.toupper() } # A STRING
($arr | %{ $_.toupper() }) -join ',' # FOO,BAR,BAZ

$repos = gci ~/source/repos
$repos.count # 29
```
. You usually do not have to do anything to work with an array value
as opposed to a single value, but sometimes it is very useful to
enclose values or commands in `@(...)` to coerce the result to an
array. This will also exhaust any iterator-like objects such as
`$input` into an immediate array value. `$(...)` will have the same
effect, but it will not coerce single values to an array.

Occasionally you may want to write a long pipeline directly to a
variable, you can use `set-variable` which has the standard alias
`sv` to do this, for example:

```powershell
gci /windows/system32/*.dll | % fullname | sv dlls
$dlls.count # 3652
```
. Hashes can be defined and used like so:

```powershell
$hash = @{
    foo = 'bar'
    bar = 'baz'
}
$hash.foo # bar
$hash.bar # baz
$hash['foo'] # bar

$hash.keys -join ',' # foo,bar
$hash.values -join ',' # bar,baz

$hash.getenumerator() | %{ "{0} = '{1}'" -f $_.key,$_.value }
# foo = 'bar'
# bar = 'baz'
```

. To make an ordered hash do:

```powershell
$ordered_hash = [ordered]@{
    some  = 'val'
    other = 'val2'
}
```
.

#### Redirection, Streams, $input and Exit Codes

Redirection for files and commands works like in POSIX shells on a
basic level, that is, you can expect `>`, `>>` and `|` to redirect
files and commands like you would expect, for **TEXT** data. `LF`
line ends will also generally get rewritten to `CRLF`, and sometimes
an extra `CRLF` will be added to the end of the file/stream. See
[here](#dealing-with-line-endings) for some ways to deal with this
in git repos. You can also adjust line endings with the `dos2unix`
and `unix2dos` commands.

The `>` redirection operator is a shorthand for the `Out-File`
command.

**DO NOT** redirect binary data, instead have the utility you are
using write the file directly.

The `<` operator is not yet available.

The streams `1` and `2` are `SUCCESS` and `ERROR`, they are
analogous to the `STDOUT` and `STDERR` file descriptors, and
generally work similarly and support the same redirection syntax.

PowerShell has many other streams, see:

```powershell
help about_output_streams
```
. There is no analogue to the `STDIN` stream. This gets quite
complex because the pipeline paradigm is central in PowerShell.

For example, text data is generally broken up into string objects
for each line. If you pipe to `out-string` they will be combined
into one string object. Here is an illustration:

```powershell
get-content try.ps1 | invoke-expression
# Throws various syntax errors.
get-content try.ps1 | out-string | invoke-expression
# Works correctly.
```
, there are many ways to handle pipeline input, the simplest and
least reliable is the automatic variable `$input`, I have used it in
the [`$profile`](#setting-up-powershell) for many things. Here is a
stupid example:

```powershell
function capitalize_foo {
    $input | %{ $_ -replace 'foo','FOO' }
}
```
. If you want to test for the presence of pipeline input, you can
use `$myinvocation.expectinginput`, for example:

```powershell
function got_pipeline {
    if ($myinvocation.expectinginput} { 'pipe' } else { 'no pipe' }
}
```
. The equivalent of `/dev/null` is `$null`, so a command such as:

```bash
cmd 2>/dev/null
```
, would be:

```powershell
cmd 2>$null
```
. While a command such as:

```bash
cmd >/dev/null 2>&1
# Or, using a non-POSIX bash feature:
cmd &>/dev/null
```
, would generally be written as:

```powershell
cmd *> $null
```
, to silence all streams, including extra streams PowerShell has
such as Verbose. If you just want to suppress the output
(`SUCCESS`) stream, you would generally use:

```powershell
cmd | out-null
```
. The `ERROR` stream also behaves quite differently from POSIX
shells.

Both external commands and PowerShell functions and cmdlets indicate
success or failure via `$?`, which is `$true` or `$false`. For
external commands the actual exit code is available via
`$LastExitCode`.

However, PowerShell commands use a different mechanism to indicate
an error status. They throw an exception or write an error to the
`ERROR` stream, which is essentially the same thing, just resulting
in different types of objects being written to the `ERROR` stream.

You can examine the error/exception objects in the `$error` array,
for example:

```powershell
write-error 'Something bad happened.'
$error[0]
```
```console
Write-Error: Something bad happened.
```
```powershell
$error[0] | select *
```
```console
PSMessageDetails      :
Exception             : Microsoft.PowerShell.Commands.WriteErrorException: Something bad happened.
...
```
. As a consequence of both external commands and PowerShell
functions/cmdlets setting `$?`, when you wrap an external command
with a function, `$?` from the command execution will be reset by
the function return. The best workaround I found for this so far, is
to throw a short error like this:

```powershell
function cmd_wrapper {
    cmd @args
    if (-not $?) { write-error "exited: $LastExitCode" -ea stop }
}
```
. Now I must admit to lying to you previously, that is:

```powershell
pwsh-cmd 2> $null
```
, is not the same thing as suppressing `STDERR` in sh, for example:

```powershell
write-error '' *> $null
```
, will still set error status, even though you see no output, and
`$error[0]` will contain an empty error.

Even worse, this means that if you have:

```powershell
$erroractionpreference  = 'stop'
```
, your script will terminate.

For native commands, it does in effect suppress `STDERR`, because
they do not use this mechanism.

For PowerShell commands what you want to do instead is this:

```powershell
mkdir existing-dir -ea ignore
```
, this sets `ErrorAction` to `Ignore`, and does not trigger an error
condition, and does not write an error object to `ERROR`.

#### Command/Expression Sequencing Operators

The operators `;`, `&&` and `||` will generally work how you expect
in sh, but there are some differences you should be aware of.

The `;` operator can not only separate commands, but can also be
very useful to output multiple values (commands are also values.)

Both the ';' and the ',' operator will yield values, but sometimes
using the ',' operator will limit the syntax you can use inside an
expression.

The ';' operator will not work in a parenthesized expression, but
will work in value and array expressions `$(...)` and `@(...)`. For
example:

```powershell
# This will not work:
(cmd; 'foo', 'bar')
# This will work:
$(cmd1; 'foo'; cmd2)
```
. The `&&` and `||` operators are only available in PSCore, and their
semantics are different from what you would expect in sh and other
languages.

The do not work on `$true`/`$false` values, but on the `$?` variable
I described [previously](#redirection-streams-input-and-exit-codes).
This variable is `$true` or `$false` based on whether the exit code
of an external command is zero or if a PowerShell function or cmdlet
executed successfully.

That is, this will not work:

```powershell
$false || some-cmd
```
, but things like this will work fine:

```powershell
cmake && ninja || write-error 'build failed'
```
. As I mentioned previously, since this is a PSCore feature, I do
not recommend using it in scripts or modules intended to be
distributed by themselves.

#### Commands and Operations on Filesystems and Filesystem-Like Objects

The `gci` aka `Get-ChildItem` command is analogous to `ls -l`.

For `ls -ltr` use:

```powershell
gci | sort lastwritetime
# Or my alias:
gci | ltr
```
. The command analogous to `ls -1` would be:

```powershell
gci -n
```
, aka `-Name`, it will list only file/directory/object names as
strings, which can be useful for long names or to pipe name strings
only to another command.


`Get-Child-Item` (`gci`) and `Get-Item` (`gi`) do not only operate
on filesystem objects, but on many other kinds of objects. For
example, you can operate on registry values like a filesystem, e.g.:

```powershell
gi  HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion
gci HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion | less
```
, here `HKLM` stands for the `HKEY_LOCAL_MACHINE` section of the
registry. `HKCU` stands for `HKEY_CURRENT_USER`.

You can go into these objects using `sl` (`Set-Location`) and work
with them similar to a filesystem. The properties displayed and
their contents will depend on the types of objects you are working
with.

You can get a list of "drive" type devices including actual drive
letters with:

```powershell
get-psdrive
```
. These also include variables, environment variables, functions and
aliases, and you can operate on them with `Remove-Item`, `Set-Item`,
etc..

For actual Windows filesystems, the first column in directory
listings from `gci` or `gi` is the mode or attributes of the object.
The positions of the letters will vary, but here is their meaning:

| Mode Letter | Attribute Set On Object |
|-------------|-------------------------|
| l           | Link                    |
| d           | Directory               |
| a           | Archive                 |
| r           | Read-Only               |
| h           | Hidden                  |
| s           | System                  |

. To see hidden files, pass `-Force` to `gci` or `gi`:

```powershell
gci -fo
gi -fo hidden-file
```
. The best way to manipulate these attributes is with the `attrib`
utility, for example, to make a file or directory hidden do:

```powershell
attrib +h file
gi -fo file
```
, `-Force` is required for `gci` and `gi` to access hidden
filesystem objects.

To make this file visible again, do:

```powershell
attrib -h file
gi file
```
. To make a symbolic link, do:

```powershell
ni -it sym name-of-link -tar (resolve-path path-to-source)
```
. The alias `ni` is for `New-Item`. Make sure the `path-to-source`
is a valid absolute or relative path, you can use tab completion or
`(resolve-path file)` to ensure this. The source paths **CAN NOT**
contain the `~` `$env:USERPROFILE` shortcut because this is specific
to PowerShell and not to the Windows operating system.

You must turn on Developer Mode to be able to make symbolic links
without elevation in PowerShell Core.

In Windows PowerShell, you must be elevated to make symbolic links
whether Developer Mode is enabled or not. But you can use:

```powershell
cmd /c mklink <link> <targeT>
```
, without elevation if Developer Mode is enabled.

**WARNING**: Do not use `ri` to delete a symbolic link to a
directory in Windows PowerShell, do this instead:

```powershell
cmd /c rmdir symlink-to-directory
```
, `ri dirlink` works fine in PowerShell Core.

My [`$profile`](#setting-up-powershell) functions `mklink` and
`rmlink` handle all of these details for you and work in both
versions of PowerShell and other OSes. The syntax for `mklink` is
the same as the `cmd` command, but you do not need to pass `/D` for
directory links and the link is optional, the leaf of the target
will be used as the link name as a default.

For a `find` replacement, use the `-Recurse` flag to `gci`, e.g.:

```powershell
gci -r *.cpp
```
.

To search under a specific directory, specify the glob with
`-Include`, e.g.:

```powershell
gci -r /windows -i *.dll
```
, for example, to find all DLL files in all levels under
`C:\Windows`.

Another useful parameter for the file operation commands is
`-Exclude`, which also takes globs, e.g.:

```powershell
gci ~/source/repos -exclude vcpkg
gci -r /some/dir -exclude .*
```
.

#### Pipelines

PowerShell supports an amazing new system called the "object
pipeline", what this means is that you can pass objects around via
pipelines and inspect their properties, call methods on them, etc..
You've already seen some examples of this, and this is the central
paradigm in PowerShell for everything.

When you run a command in PowerShell from the terminal, there is an
implicit pipeline from the command to your terminal device, when the
objects from the command reach your terminal, the format objects for
terminal view are applied to them and they are printed.

Here is an example of using the object pipeline to recursively
delete all vim undo files:

```powershell
gci -r .*.un~ | ri
```
. Here `remove-item` receives file objects from `get-childitem` and
deletes them.

To do the equivalent of a recursive `grep` you could do something
like:

```powershell
sls -r *.[ch] | sls -ca void
```
. I prefer using ripgrep (`rg` command) for this purpose. To turn
off the highlighting in `Select-String`, use the
`-noe`(`-NoEmphasis`) flag. Be aware that `Select-String` will apply
an output format to its results and there will be extra blank lines
at the top and bottom among other things, so if you are going to use
them as text in a pipeline or redirect use the `-raw` flag.

If the Cmdlet works on files, they can be strings as well, for
example:

```powershell
gc file-list | cpi -r -dest e:/backup
```
, copies the files and directories listed in file-list to a
directory on a USB stick.

Most commands can accept pipeline input, even ones you wouldn't
expect to, for example:

```powershell
split-path -parent $profile | sl
```
, will enter your Documents PowerShell directory.

The help documentation for commands will generally state if they
accept pipeline input or not.

You can access the piped-in input in your own functions as the
special `$input` variable, like in some of the functions in the
[`$profile`](#setting-up-powershell). This is the worst way to do
this, it's better to make an advanced function with a process block,
which I won't cover here yet, but it is the most simple.

Here is a more typical example of a pipeline:

```powershell
get-process | ?{ $_.name -notmatch 'svchost' } | %{ $_.name } | sort -u
```
. Here `?{ ... }` is like filter/grep block while `%{ ... }` is like
an apply/map block.

In PowerShell pipelines you will generally be working with object
streams and their properties rather than lines of text. And, as I
mentioned, lines of text are actually string objects anyway. I will
describe a few tricks for doing this here.

You can use the `% property` shorthand to select a single property
from an object stream, for example:

```powershell
gci | % name
```
, will do the same thing as `gci -n`. The input does not have to be
a stream of multiple objects, using this on a single object will
work just fine.

This will get the full paths of the files in a directory:

```powershell
gci ~/source/pwsh/*.ps1 | % fullname
```
. This also works with `?` aka `Where-Object`, which has parameters
mimicking PowerShell operators, allowing you to do things like this:

```powershell
gci | ? length -lt 1000
```
, which will show all filesystem objects less than `1000` bytes.

Or, for example:

```powershell
get-process | ? name -match 'win'
```
. There are many useful parameters to the `select` aka
`Select-Object` command for manipulating object streams, including
`-first` and `-last` as you saw for the `head`/`tail` equivalents,
as well as `-skip`, `-skiplast`, `-unique`, `-index`, `-skipindex`
and `-expand`. The last one, `-expand`, will select a property from
the objects selected and further expand it for objects and arrays.

For a contrived example:

```powershell
gci ~/Downloads/*.zip | sort length | select -skiplast 1 `
    | select -last 1 | % fullname
```
, will give me the name of the second biggest `.zip` file in my
`~/Downloads` folder.

I have aliased `Select-Object` to `s` in the
[`$profile`](#setting-up-powershell) as many people do to save you
some typing.

If you want to inspect the properties available on an object and
their current values, you can use `select *` e.g.:

```powershell
gi .gitconfig | s *
```
.

#### The Measure-Object Cmdlet

The equivalent of `wc -l file` to count lines is:

```powershell
gc file | measure -l
```
, while `-w` will count words and `-c` will count characters. You
can combine any of the three in one command, the output is a table.

To get just the number of lines, you can do this:

```powershell
gc file | measure -l | % lines
```
. Note that if you are working with objects and not lines of text,
`meaure -l` will still do what you expect, but it's better to do
something like:

```powershell
gci | measure | % count
# Or with my $profile function:
gci | count
```
. This is essentially the same thing, because lines of text in
PowerShell pipelines are actually string objects, as I already
mentioned at least 3 times.

#### Sub-Expressions and Strings

The POSIX command substitution syntax allows inserting the result of
an expression in a string or in some other contexts, for example:

```powershell
"This file contains $(gc README.md | measure -l | % lines) lines."
```
. Executing an external command is also an expression, that returns
string objects for the lines outputted, which gives you essentially
the same thing as POSIX command substitution.

The `@( ... )` syntax works identically to the `$( ... )` syntax to
evaluate expressions, however, it cannot be used in a string by
itself and will always result in an array even for one value.

When not inside a string, you can simply use parenthesis, and when
assigning to variables you need nothing at all, for example:

```powershell
$date = get-date
vim (gci -r *.ps1)
```
. For string values, it can be nicer to use formats, e.g.:

```powershell
"This shade of {0} is the hex code #{1:X6}." -f 'Blue',13883343
"Today is: {0}." -f (get-date)
```
. See
[here](https://social.technet.microsoft.com/wiki/contents/articles/7855.powershell-using-the-f-format-operator.aspx)
for more about the `-f` format operator.

. Variables can also be interpolated in strings just like in POSIX
shells, for example:

```powershell
$greeting = 'Hello'
$name     = 'Fred'
"${greeting}, $name"
```
. In PowerShell, the backtick `` ` `` is the escape character, and you
can use it at the end of a line, escaping the line end as a line
continuation character. In regular expressions, the backslash `\` is
the escape character, like everywhere else.

The backtick can also be used to escape nested double quotes, but
not single quotes, for example:

```powershell
"this `"is`" a test"
```

, PowerShell also allows escaping double and single quotes by using
two consecutive quote characters, for example:

```powershell
"this ""is"" a test"
'this ''is'' a test'
```
. The backtick is also used for special character sequences, here are
some useful ones:

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

For example, this will print an emoji between two blank lines,
indented by a tab:

```powershell
"`n`t`u{1F47D}`n"
```
.

#### Script Blocks and Scopes

A section of PowerShell code is usually represented by a Script
Block, a function is a Script Block, or any code between `{ ... }`
braces, such as for `%{ ... }` aka `ForEach-Object` or `?{ ... }`
aka `Where-Object`. Script Blocks have their own dynamic child
scope, that is new variables defined in them are not visible to the
parent scope, and are freed if and when the Script Block is
released.

Script Blocks can be assigned to variables and passed to functions,
like lambdas or function pointers in other languages. Unlike
lambdas, PowerShell does not have lexical closure semantics, it uses
dynamic scope. You can, however, use a module to get an effect
similar to closure semantics, I use this in the
[`$profile`](#setting-up-powershell). For example:

```powershell
new-module SomeName -script {
  ...
  code here
  ...
} | import-module
```
, the way this works is that the module scope is its own independent
script scope, and any exported or global functions can access
variables and non-exported functions in that scope without them
being visible to anything else. When you see the `GetNewClosure()`
method being used, this is essentially what it does.

You can use the call operator `&` to immediately execute a defined
Script Block or one in a variable:

```powershell
&{ "this is running in a Script Block" }
$script = { "this is another Script Block" }
&$script
```
, this can be useful for defining a new scope, somewhat but not
really analogous to a `( ...)` subshell in POSIX shells.

#### Using and Writing Scripts

PowerShell script files are any sequence of commands in a `.ps1`
file, and you can run them directly:

```powershell
./script.ps1
```
. The equivalent of `set -e` in POSIX shells is:

```powershell
$erroractionpreference = 'stop'
```
. I highly recommend it adding it to the top of your scripts.

The bash commands `pushd` and `popd` are also available for use in
your scripts.

Although this guide does not yet discuss programming much, I wanted
to mention one thing that you must be aware of when writing
PowerShell scripts and functions.

PowerShell does not return values the same way as most other
languages. A section of PowerShell code can return values from
anywhere and they will passed down the pipeline or collected into an
array. The command `echo` does nothing for example, a string value
with no command will do the same thing. The `return` statement will
yield a value and return control to the caller, but any value will
be yielded implicitly.

In essence, everything in PowerShell runs in a pipeline, a section
of code runs in a pipeline and yields values to it, and if you are
running it from your terminal, the terminal takes the output objects
from the pipeline and formats them using the formatters assigned to
them.

Here is an illustration:

```powershell
function foo {
    "val1"
    "val: {0}" -f 42
    50
    return 90
    # This won't get returned.
    66
}

$array = foo
$array -join ','
# or
(foo) -join ','
# will yield:
# val1,val: 42,50,90
```
. Since arrays are in PowerShell are fixed size, it is more
computationally expensive to manipulate them via adding and removing
elements. To build an array it is better to assign the result of a
pipeline or a loop, for example:

```powershell
$arr1 = gci /windows

$arr2 = foreach ($file in gci /windows) { $file }
```
, and to remove elements of an array it's better to assign the
source elements you want to a new array by filtering or index, for
example:

```powershell
$arr1 = gci /windows

$arr2 = $arr1 | ?{ (split-path -extension $_) -ne '.exe' }

$arr3 = $arr2[20..29]
```
. Reading a PowerShell script into your current session and scope
works the same way as "dot-source" in POSIX shells, e.g.:

```powershell
. ~/source/PowerShell/some_functions.ps1
```
, this will also work to reload your
[`$profile`](#setting-up-powershell) after making changes to it:

```powershell
. $profile
```
. Function parameter specifications get extremely complex in
PowerShell, but for simple functions this is all you need to know:

```powershell
function foo($arg1) {
    # $arg1 will be first arg, $args will be the rest
}
function bar([array]$arg1, [string]$arg2) {
    # $arg1 must be an array, $arg2 must be a string, $args is the
    # rest.
}
# For more complex param definitions:
function baz {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
        [validatescript({
            if (-not (test-path -pathtype leaf $_)) {
                throw "Certificate file '$_' does not exist."
            }
            $true
        })]
        [system.io.fileinfo]$CertificateFile
    )
}
```
.

#### Writing Simple Modules

As I explained [here](#script-blocks-and-scopes) a module has its
own script scope. It can export functions, variables and aliases
into the importing scope.

A very basic module is a file that ends in the `.psm1` extension and
looks something like this:

```powershell
# open-thingy.psm1

function helper { ... }

function OpenMyThingy {
    ... stuff that uses (helper)
    ... which is not visible anywhere else
}

set-alias thingy -value OpenMyThingy

# Here you specify what is actually visible.
export-modulemember -function OpenMyThingy -alias thingy
```
. You can then load the module with:

```powershell
import-module ~/source/pwsh/modules/open-thingy.psm1
```
, it will tell you if the verbs you are using as the first word of
your exported functions are not up to standard, which is why my
example function has such a stupid name.

You unload it with:

```powershell
remove-module open-thingy
```
, and while you are debugging the module you will need to load it
many, many, many times, which you can do with:

```powershell
import-module -force ~/source/pwsh/modules/open-thingy.psm1
```
. Sometimes this will not be sufficient, and you will need to unload
it, or even start a new PowerShell session.

For more about modules, see the [Using PowerShell Gallery
section](#using-powershell-gallery).

If you want to publish a module to the PowerShell Gallery, you can
follow this [excellent
guide](https://jeffbrown.tech/how-to-publish-your-first-powershell-gallery-package/).
Just be aware that the `publish-module` cmdlet is called
`publish-psresource -repo psgallery` in newer versions of
PackageManagement/PowerShellGet. Also look at the sources of other
people's Gallery modules for ideas on how to do things.

#### Miscellaneous Usage Tips

Another couple of extremely useful Cmdlets are `get-clipboard` and
`set-clipboard` to access the clipboard, they are alias to `gcb` and
`scb` respectively, for example:

```powershell
gcb > clipboard-contents.txt
gc somefile.txt | scb
gc $profile | scb
```
. To open the explorer file manager for the current or any folder
you can just run `explorer`, e.g.:

```powershell
explorer .
explorer (resolve-path /prog*s)
explorer shell:startup
```
. To open a file in its associated program, similarly to `xdg-open`
on Linux, you can use the `start` command or invoke the file like a
script, e.g.:

```powershell
start some_text.txt
./some_file.txt
start some_code.cpp
./some_code.cpp
```
.

### Elevated Access (sudo)

Windows now includes a `sudo` command which can be enabled in
Settings under `System` -> `Developer Settings`. However, the method
I describe here is better. In the usual case, the built-in `sudo`
command has a UAC prompt and only allows running commands in a new
window.

By connecting to localhost with ssh, you gain elevated access (if
you are an admin user, which is the normal case.) This will not
allow you to run GUI apps with elevated access, but most PowerShell
and console commands should work.

If you use the sudo function defined in the
[`$profile`](#setting-up-powershell), then your current location
will be preserved.

All of this assumes you installed the ssh server as described
[here](#installing-visual-studio-some-packages-and-scoop).

To set this up:

```powershell
sl ~/.ssh
gc id_rsa.pub >> authorized_keys
```
, then make sure the permissions are correct by running the commands
[here](#setting-up-ssh).

Test connecting to localhost with `ssh localhost` for the first
time, if everything went well, ssh will prompt you to trust the host
key, and on subsequent connections you will connect with no prompts.

You can now run PowerShell and console elevated commands using the
`sudo` function.

### Using PowerShell Gallery

To enable PowerShell Gallery to install third-party modules, run this command:

```powershell
set-psrepository psgallery -installationpolicy trusted
```
, for new versions of PowerShellGet/PackageManagement, do this
instead:

```powershell
set-psresourcerepository psgallery -trusted
```
, this is not necessary on Windows PowerShell.

You can then install modules using `install-module`, for example:

```powershell
install-module PSWriteColor
```
. On newer versions the command is:

```powershell
install-psresource PSWriteColor
```
. You can immediately use the new module, e.g.:

```powershell
write-color -t 'foo' -c 'magenta'
```
. To update all your modules, you can do this:

```powershell
get-installedmodule | update-module
```
. On newer versions the command is:

```powershell
get-psresource | update-psresource
```
. The `uninstall-module` cmdlet can uninstall modules, usually, the
new cmdlet is `uninstall-psresource`.

. You may need to unload the module in all your sessions for the
package commands to be able to uninstall or update it, and sometimes
you will need to manually delete module directories, preferably in
an admin cmd prompt not running PowerShell, core or Windows.

In PowerShell Core, your modules are written to the
`~/Documents/PowerShell/Modules` directory, with each module written
to a `<Module>/<Version>` tree. You can delete them if they are not
in use. The system-wide directory is
`$env:programfiles/PowerShell/7/Modules`.

For Windows PowerShell the location of modules is
`$env:programfiles/WindowsPowerShell/Modules`.

To see where an imported module is installed, you can do, e.g.:

```powershell
get-module posh-git | select path
```
. You can use `import-module` to load your installed modules by name
into your current session and `remove-module` to remove them.

If you get yourself into some trouble with module installations,
remember that `.nupkg` files are zip files, and you can extract them
to the appropriate `<Module>/<Version>` directory and this will
generally work.

### Available Command-Line Tools and Utilities

The commands installed in the list of packages [installed from
scoop](#installing-visual-studio-some-packages-and-scoop) are
pretty much the same as in Linux.

There are a few very simplistic wrappers for similar functions as
the namesake Linux commands in the
[`$profile`](#setting-up-powershell), including: `pwd`, `which`,
`type`, `command`, `pgrep`, `pkill`, `head`, `tail`, `tac`, `touch`,
`sudo`, `env`, and `nproc`.

See [here](#elevated-access-sudo) about the `sudo` wrapper.

The `ver` function will give you some OS details.

The `mklink <link> <target>` function will make symlinks. With one
parameter, `mklink` will assume it is the target and make a link
with the name of the leaf in the current directory.

The `rmlink` function will delete symlinks, it is primarily intended
for compatibility with WinPS which does not support deleting
directory links with `remove-item`.

The `rmalias` function will delete aliases from all scopes in a way
that is compatible with WinPS.

I made these because the normal PowerShell approach for these is too
cumbersome, I generally recommend using and getting used to the
native idiom for whatever you are doing.

You will very likely write many of your own functions and aliases to
improve your workflow.

For example, I also define `ltr` to add `sort lastwritetime` and
`count` to add `measure | % count` to the end of a pipeline, and
alias `select-object` to `s`.

The `readshim` function will give you the installed target of winget symlinks,
scoop shims and Chocolatey shims for executables you have installed.

The `shortpath` function will convert a raw path to a nicer form
with the sysdrive removed, it can take args or pipeline input. The
`realpath` function will give the canonical path with sysdrive using
forward slashes, while `sysppath` will give you the standard Windows
path with backslashes for e.g. passing to `cmd /c` commands.

The `megs` function will show you the size of a file in mebibytes,
this is not really the right way to do this, the right way would be
to override the `FileInfo` and `DirectoryInfo` formats, I'm still
researching a nice way to do this.

The `syslog` function will show you a simple view of the System
event log, while the `tasklog` function will show you a simple view
of the Tasks event log, which you must first enable as described
[here](#creating-scheduled-tasks-cron).

The `patch` command comes with Git for Windows, the
[`$profile`](#setting-up-powershell) adds an alias to it.

The [install script](#installing-visual-studio-some-packages-and-scoop) in this
guide installs ripgrep, which is a very powerful and fast recursive text search
tool and is extremely useful for exploring codebases you are not familiar with.
The command for it is `rg`.

You get `node` and `npm` from the nodejs package. You can install
any NodeJS utilities you need with `npm install -g <utility>`, and
it will be available in your `$env:PATH`. For example, I use
`doctoc` and `markdown-link-check` to maintain this and other
markdown documents.

The `python` and `pip` tools (version 3) come from the winget
`python` package. To install utilities from `pip` use the `--user`
flag, e.g.:

```powershell
pip install --user conan
```
, you will also need to add the user directory in your `$env:PATH`,
this is done for you in the [`$profile`](#setting-up-powershell).
The path depends on the Python version and looks something like
this:

```console
~/AppData/Roaming/Python/Python310/Scripts
```
, `pip` will give you a warning with the path if it's not in your
`$env:PATH`.

The `perl` command comes from `StrawberryPerl.StrawberryPerl` from
winget, it is mostly fully functional and allows you to install many
modules from CPAN without issues. See the `$env:PATH` override for
it in the [`$profile`](#setting-up-powershell) to remove the MinGW
stuff it comes with. I would recommend removing it from your system
PATH entirely and only adding it when you need to install CPAN
modules that need a compiler.

The tools `cmake` and `ninja` come with Visual Studio, the
[`$profile`](#setting-up-powershell) sets up the Visual Studio
environment. You can get dependencies from Conan or VCPKG, I
recommend Conan because it has binary packages. More on all that
later when I expand this guide. Be sure to pass `-G Ninja` to
`cmake`.

The Visual Studio C and C++ compiler command is `cl`. Here is a
simple example:

```powershell
cl hello.c /o hello
```

. To start the Visual Studio IDE you can use the `devenv` command.

To open a cmake project, go into the directory containing
`CMakeLists.txt` and run:

```powershell
devenv .
```

. To debug an executable built with `-DCMAKE_BUILD_TYPE=Debug`, you
can do this:

```powershell
devenv /debugexe file.exe arg1 arg2 ...
```
. The tool `make` is a native port of GNU Make from scoop. It
will generally not run regular Linux Makefiles because it expects
`cmd.exe` shell commands. However, it is possible to write Makefiles
that work in both environments if the commands are the same, for
example the one in this repository.

For an `ldd` replacement, you can do this:

```powershell
dumpbin /dependents prog.exe
dumpbin /dependents somelib.dll
```

. To see the functions a `.dll` exports, you can do:

```powershell
dumpbin /exports some.dll
```
, and to see the symbols in a static `.lib` library, you can do:

```powershell
dumpbin /symbols foo.lib
```

. The commands `curl` and `tar` are now standard Windows commands.
The implementation of `tar` is not particularly wonderful, it
currently does not handle symbolic links correctly and will not save
your ACLs. You can save your ACLs with `icacls`.

For an `htop` replacement, use `ntop`, installed
[here](#installing-visual-studio-some-packages-and-scoop), with the
wrapper function in the [`$profile`](#setting-up-powershell).

You can run any `cmd.exe` commands with `cmd /c <command>`.

Many more things are available from winget, scoop and Chcolatey and other
sources of course, at varying degrees of functionality.

### Using tmux/screen with PowerShell

It is possible to use tmux from WSL with PowerShell.

First set up WSL with your distribution of choice, I won't cover this here as
there are many excellent guides available.

Then create a `~/.tmux-pwsh.conf` in your WSL home with your tmux
configuration of choice including this statement:

```tmux
set -g default-command "cd \$(wslpath \$(/mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')); '/mnt/c/Program Files/PowerShell/7/pwsh.exe' -nologo"
```
. If you want to use a configuration that behaves like screen I have one
[here](https://github.com/rkitover/tmux-screen-compat). You can load a
configuration file before the preceding statement with the `source` statement in
the tmux config.

To run tmux, run:

```powershell
wsl tmux -f '~/.tmux-pwsh.conf'
```
. The included [profile](#setting-up-powershell) function `tmux` will do this.

### Creating Scheduled Tasks (cron)

You can create and update tasks for the Windows Task Scheduler to
run on a certain schedule or on certain conditions with a small
PowerShell script. I will provide an example here.

First, enable the tasks log by running the following in an admin
shell:

```powershell
$logname = 'Microsoft-Windows-TaskScheduler/Operational'
$log = new-object System.Diagnostics.Eventing.Reader.EventLogConfiguration $logname
$log.isenabled=$true
$log.savechanges()
```
. This is from:

https://stackoverflow.com/questions/23227964/how-can-i-enable-all-tasks-history-in-powershell/23228436#23228436

. This will allow you to use the `tasklog` function from the
[`$profile`](#setting-up-powershell) to view the Task Scheduler log.

This is a script that I use for the nightly builds for a project.
The script must be run in an elevated shell, as this is required to
register a task:

[//]: # "BEGIN INCLUDED build-task.ps1"

```powershell
$taskname = 'Nightly Build'
$runat    = '23:00'

$trigger = new-scheduledtasktrigger -at $runat -daily

if (-not (test-path /logs)) { mkdir /logs }

$action  = new-scheduledtaskaction `
    -execute 'pwsh' `
    -argument ("-noprofile -executionpolicy remotesigned " + `
	"-command ""& '$(join-path $psscriptroot build-nightly.ps1)'""" + `
	" *>> /logs/build-nightly.log")

$password = (get-credential $env:username).getnetworkcredential().password

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -user $env:username `
    -password $password `
    -ea stop | out-null

"Task '$taskname' successfully registered to run daily at $runat."
```
. With the `-force` parameter to `register-scheduledtask`, you can
update your task settings and re-run the script and the task will be
updated.

With `-runlevel` set to `highest` the task runs elevated, omit this
parameter to run with standard permissions.

You can also pass a `-settings` parameter to
`register-scheduledtask` taking a task settings object created with
`new-scheduledtasksettingsset`, which allows you to change many
options for how the task is run, see the `help` documentation for
it.

You can use:

```powershell
start-scheduledtask 'Task Name'
```
, to test running your task.

To delete a task, run:

```powershell
unregister-scheduledtask -confirm:$false 'Task Name'
```
. See also the [virt-viewer
section](#working-with-virt-manager-vms-using-virt-viewer) for an
example of a task that runs at logon.

### Working With virt-manager VMs Using virt-viewer

Unfortunately `virt-manager` is unavailable as a native utility, if
you like you can run it using WSL or even Cygwin.

However, `virt-viewer` is available from winget using the id `RedHat.VirtViewer`
and with a bit of setup can allow you to work with your remote `virt-manager`
VMs conveniently.

The first step is to edit the XML for your VMs and assign
non-conflicting spice ports bound to localhost for each one.

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
. Then restart sshd.

Forward the spice ports for the VMs you are interested in working
with over ssh. To do that, edit your `~/.ssh/config` and set your
server entry to something like the following:

```sshconfig
Host your-server
  LocalForward 5900 localhost:5900
  LocalForward 5901 localhost:5901
  LocalForward 5902 localhost:5902
```
, then if you have a tab open in the terminal with an ssh connection
to your server, the ports will be forwarded.

You can also make a separate entry just for forwarding the ports
with a different alias, for example:

```sshconfig
Host your-server-ports
  HostName your-server
  LocalForward 5900 localhost:5900
  LocalForward 5901 localhost:5901
  LocalForward 5902 localhost:5902
```
, and then create a continuously running
[task](#creating-scheduled-tasks-cron) that starts at logon to keep
the ports open, with a command such as:

```powershell
ssh -NT your-server-ports
```
. Here is a script to create this task:

[//]: # "BEGIN INCLUDED ports-task.ps1"

```powershell
$erroractionpreference = 'stop'

$taskname = 'Forward Server Ports'

$trigger = new-scheduledtasktrigger -atlogon

$action  = new-scheduledtaskaction `
    -execute 'ssh' `
    -argument '-NT server-ports'

$settings = new-scheduledtasksettingsset -restartcount:1000 -restartinterval (new-timespan -minutes 1)

$password = (get-credential $env:username).getnetworkcredential().password

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -settings $settings `
    -user $env:username `
    -password $password `
    -ea stop | out-null

"Task '$taskname' successfully registered to run at logon."
```
. As an alternative to creating a task, you can make a startup
folder shortcut, first open the folder:

```powershell
explorer shell:startup
```
, create a shortcut to `pwsh`, then open the properties for
the shortcut and set the target to something like:

```powershell
"C:\Program Files\PowerShell\7\pwsh.exe" -windowstyle hidden -c "ssh -NT server-ports"
```
. Make sure `Run:` is changed from `Normal window` to `Minimized`.

Once that is done, the last step is to install `virt-viewer` from winget using
the id `RedHat.VirtViewer` and add the functions to your
[`$profile`](#setting-up-powershell) for launching it for your VMs.

I use these:

```powershell
function winbuilder {
    &(resolve-path 'C:\Program Files\VirtViewer*\bin\remote-viewer.exe') -f spice://localhost:5901 *> $null
}

function macbuilder {
    &(resolve-path 'C:\Program Files\VirtViewer*\bin\remote-viewer.exe') -f spice://localhost:5900 `
        --hotkeys=release-cursor=ctrl+alt *> $null
}
```
. Launching the function will open a full screen graphics console to
your VM.

Moving your mouse cursor when it's not grabbed to the top-middle
will pop down the control panel with control and disconnect
functions.

If your VM requires grabbing and ungrabbing input, use the
`--hotkeys` parameter as in the example above to define a hotkey to
release input.

### Using X11 Forwarding Over SSH

Install `vcxsrv` from winget using the id `marha.VcXsrv`.

It is necessary to disable DPI scaling for this app. First, run this
command in an admin terminal:

```powershell
[environment]::setenvironmentvariable('__COMPAT_LAYER', 'HighDpiAware /M', 'machine')
```
. Open the app folder:

```powershell
explorer (resolve-path /progr*s/vcxsrv)
```
, open the properties for `vcxsrv.exe` and go to `Compatibility ->
Change High DPI settings`, at the bottom under `High DPI scaling
override` check the checkbox for `Override high DPI scaling
behavior` and under `Scaling performed by:` select `Application`.

Reboot your computer, which by the way, you can do with
`restart-computer`.

Open your startup shortcuts:

```powershell
explorer shell:startup
```
, and create a shortcut to `vcxsrv.exe` with the target set to:

```powershell
"C:\Program Files\VcXsrv\vcxsrv.exe" -multiwindow -clipboard -wgl
```
. Launch the shortcut.

Make sure that `C:\Program Files\VcXsrv` is in your `$env:PATH` and
that you generate an `~/.Xauthority` file, the sample [`$profile`](#setting-up-powershell) does this for you. To generate an `~/.Xauthority` file do the following:

```powershell
xauth add ':0' . ((1..4 | %{ "{0:x8}" -f (get-random) }) -join '') | out-null
```
. On your remote computer, add this function to your `~/.bashrc`:

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
. Edit your remote computer sshd config and make sure the following
is enabled:

```
X11Forwarding yes
```
, then restart sshd.

On the local computer, edit `~/.ssh/config` and set the
configuration for your remote computer as follows:

```sshconfig
Host remote-computer
  ForwardX11 yes
  ForwardX11Trusted yes
```
. Make sure `$env:DISPLAY` is set in your
[`$profile`](#setting-up-powershell) as follows:

```powershell
if (-not $env:DISPLAY) {
    $env:DISPLAY = '127.0.0.1:0.0'
}
```
. Open a new ssh session to the remote computer.

You can now open X11 apps with the `x` function you added to your
`~/.bashrc`, e.g.:

```bash
x gedit ~/.bashrc
```
. Set your desired scale in the `~/.bashrc` function and configure
the appearance for your Qt apps with qt5ct.

One huge benefit of this setup is that you can use `xclip` on your
remote computer to put things into your local clipboard.

### Mounting SMB/SSHFS Folders

This is as simple as making a symbolic link to a UNC path.

For example, to mount a share on an SMB file server:

```powershell
sl ~
ni -it sym work-documents -tar //corporate-server/documents
```
. To mount my NAS over SSHFS I can do this, assuming the winget
`sshfs` package (id `SSHFS-Win.SSHFS-Win`) is installed:

```powershell
sl ~
ni -it sym nas -tar //sshfs.kr/remoteuser@remote.host!2223/mnt/HD/HD_a2/username
```
. Here `2223` is the port for ssh. Use `sshfs.k` instead of
`sshfs.kr` to specify a path relative to your home directory.

### Appendix A: Chocolatey Usage Notes

I have switched this guide to winget and scoop because that's what people want
to use these days, however Chocolatey is still a very useful source of software
that you may want to use, I will describe it here.

To install the Chocolatey package manager, run this from an admin PowerShell:

```powershell
iwr 'https://chocolatey.org/install.ps1' | % content | iex
```
, then relaunch your terminal session.

This is the old install script for this guide using Chocolatey if
you would prefer to use it instead of winget and scoop:

[//]: # "BEGIN INCLUDED choco-install.ps1"

```powershell
[environment]::setenvironmentvariable('POWERSHELL_UPDATECHECK', 'off', 'machine')
set-service beep -startuptype disabled
choco feature enable --name 'useRememberedArgumentsForUpgrades'
choco install -y visualstudio2022community --params '--locale en-US'
choco install -y visualstudio2022-workload-nativedesktop
choco install -y vim --params '/NoDesktopShortcuts'
choco install -y 7zip NTop.Portable StrawberryPerl bzip2 dejavufonts diffutils dos2unix file gawk git gpg4win grep gzip hackfont less make neovim netcat nodejs notepadplusplus powershell-core python ripgrep sed sshfs unzip xxd zip
## Only run this on Windows 10 or older, this package is managed by Windows 11.
#choco install -y microsoft-windows-terminal
## If you had previously installed it and are now using Windows 11, run:
#choco uninstall microsoft-windows-terminal -n --skipautouninstaller
choco install -y openssh --prerelease --force --params '/SSHServerFeature /PathSpecsToProbeForShellEXEString:$env:programfiles\PowerShell\*\pwsh.exe'
refreshenv
sed -i 's/^[^#].*administrators.*/#&/g' /programdata/ssh/sshd_config
restart-service sshd
&(resolve-path /prog*s/openssh*/fixuserfilepermissions.ps1)
import-module -force (resolve-path /prog*s/openssh*/opensshutils.psd1)
repair-authorizedkeypermission -file ~/.ssh/authorized_keys
ni -it sym ~/.config -tar (resolve-path ~/AppData/Local)
```
, run it in an admin PowerShell terminal.

Here are some commands for using the Chocolatey package manager.

To search for a package:

```powershell
choco search vim
```
. To install a package:

```powershell
choco install -y vim
```
. To get the description of a package:

```powershell
choco info vim
```
, this will also include possible installation parameters that you
can pass as a single string on install, e.g.:

```powershell
choco install -y package --params '/NoDesktopShortcuts
/SomeOtherParam'
```
, if you use install params make sure you enabled the
`useRememberedArgumentsForUpgrades` choco feature, otherwise your
params will not be applied on upgrades and your package may break,
to do this run:

```powershell
choco feature enable --name 'useRememberedArgumentsForUpgrades'
```
. To uninstall a package:

```powershell
choco uninstall -y vim
```
, you might run into packages that can't uninstall, this can happen
when a package was installed with an installer and there is no
specification for how to uninstall, in which case you would have to
clean it up manually.

If you need to uninstall packages that depend on each other, you
must pass the list in the correct order, or choco will throw a
dependency error. For example, this would be the correct order in
one particular case:

```powershell
choco uninstall -y transifex-client python python3
```
, any other order would not work. You can also use the `-x` option
to remove packages and all of their dependencies, or run the command
repeatedly until all packages are uninstalled.

To list installed packages:

```powershell
choco list --local
```
. To update all installed packages:

```powershell
choco upgrade -y all
```
. Sometimes after you install a package, your terminal session will
not have it in `$env:PATH`, you can restart your terminal or run
`refreshenv` to re-read your environment settings. This is also in
the [`$profile`](#setting-up-powershell), so starting a new tab will
also work.

#### Chocolatey Filesystem Structure

The main default directory for choco and packages is
`/ProgramData/chocolatey`.

You can change this directory **BEFORE** you install choco itself like so:

```powershell
[environment]::setenvironmentvariable('ChocolateyInstall', 'C:\Some\Path', 'machine')
```
. This can only be changed before you install choco and any
packages, it **CANNOT** be changed after it is already installed and
any packages are installed.

The directory `/ProgramData/chocolatey/bin` contains the `.exe`
"shims", which are kind of like symbolic links, that point to the
actual program executables. You can run e.g.:

```powershell
grep --shimgen-help
```
, to see the target path and more information about shims. The
[`$profile`](#setting-up-powershell) has a `shimread` function to
get the target of shims.

The directory `/ProgramData/chocolatey/lib` contains the package
install directories with various package metadata and sometimes the
executables as well.

The directory `/tools` is sometimes used by packages as the
installation target as well.

You can change this directory like so:

```powershell
[environment]::setenvironmentvariable('ChocolateyToolsLocation', 'C:\Some\Path', 'machine')
```
, this can be changed after installation, in which case make sure to
move any files there to the new location.

Many packages simply run an installer and do not install to any
specific location, however various package metadata will still be
available under `/ProgramData/chocolatey/lib/<package>`.

<!--- vim:set et sw=4 tw=80: --->
