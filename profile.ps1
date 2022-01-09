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

if ($iswindows) {
    [Console]::OutputEncoding = [Console]::InputEncoding = `
        $OutputEncoding = [System.Text.Encoding]::UTF8

    set-executionpolicy -scope currentuser remotesigned
    set-culture en-US

    if ($private:chocolatey_profile = resolve-path `
        "$env:chocolateyinstall\helpers\chocolateyprofile.psm1" `
        -ea ignore) {

        import-module $chocolatey_profile
    }

    # Update environment in case the terminal session environment
    # is not up to date.
    update-sessionenvironment
}

# Make help nicer.
$PSDefaultParameterValues["get-help:Full"] = $true
$env:PAGER = 'less'

new-module MyProfile -script {

$path_sep = [system.io.path]::pathseparator

$global:ps_share_dir  = if ($iswindows) {
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

    if (-not $iswindows) { $str }

    $str -replace ('^'+(sysdrive)),''
}

function home_to_tilde($str) {
    if (-not $str) { $str = $input }

    $home_dir = [regex]::escape($home)

    $str -replace ('^'+$home_dir),'~'
}

function backslashes_to_forward($str) {
    if (-not $str) { $str = $input }

    if (-not $iswindows) { return $str }

    $str -replace '\\','/'
}

function pretty_path($str) {
    if (-not $str) { $str = $input }

    $str | home_to_tilde | trim_sysdrive | backslashes_to_forward
}

# Replace OneDrive Documents path in $profile with ~/Documents
# symlink, if you have one.
if ($iswindows -and
    ((gi ~/Documents -ea ignore).target -match 'OneDrive')) {

    $global:profile = $profile -replace 'OneDrive\\',''

    # Remove Strawberry Perl MinGW stuff from PATH.
    $env:PATH = (split_env_path |
        ?{ $_ -notmatch '\bStrawberry\\c\\bin$' }
    ) -join $path_sep
}

$global:profile = $profile | pretty_path

$global:ps_config_dir = split-path $profile -parent

$global:ps_history = "$ps_share_dir/ConsoleHost_history.txt"

if ($iswindows) {
    $global:terminal_settings = resolve-path ~/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json -ea ignore | pretty_path
}

$prepend_paths = `
    '~/.local/bin'

foreach ($path in $prepend_paths) {
    if (-not ($path = resolve-path $path -ea ignore)) {
        continue
    }

    if (-not ((split_env_path) -contains $path)) {
        $env:PATH = ($path,$env:PATH) -join $path_sep
    }
}

if ($iswindows) {
    # This breaks terminal handling in some native Windows apps
    # like vim.
    ri env:TERM -ea ignore
}

if ($iswindows) {
    $vim = ''

    # Neovim is broken in ssh sessions on Windows, use regular vim.
    if (-not $env:SSH_CONNECTION) {
        foreach ($cmd in '~/.local/bin/nvim.bat','nvim') {
            if ($vim = (get-command $cmd -ea ignore).source) {
                break
            }
        }

        if ($vim) {
            set-alias vim -scope global -val $vim
        }
    }

    if (-not $vim) {
        foreach ($cmd in '~/.local/bin/vim.bat','vim') {
            if ($vim = (get-command $cmd -ea ignore).source) {
                break
            }
        }
    }

    if ($vim) {
        $env:EDITOR = $vim -replace '\\','/'
    }
}
else {
    $env:EDITOR = 'vim'
}

$env:VCPKG_ROOT = resolve-path ~/source/repos/vcpkg -ea ignore

if (-not $env:DISPLAY) {
    $env:DISPLAY = '127.0.0.1:0.0'
}

function global:megs {
    gci -r @args | select mode, lastwritetime, @{ name="MegaBytes"; expression={ [math]::round($_.length / 1MB, 2) }}, name
}

function global:cmconf {
    grep -E --color 'CMAKE_BUILD_TYPE|VCPKG_TARGET_TRIPLET|UPSTREAM_RELEASE' CMakeCache.txt
}

# Windows PowerShell does not support the `e special character
# sequence for Escape, so we use a variable $e for this.
$e = [char]27

if ($iswindows) {
    function global:pgrep {
        get-ciminstance win32_process -filter "name like '%$($args[0])%' OR commandline like '%$($args[0])%'" | select processid, name, commandline
    }

    function global:pkill {
        pgrep $args[0] | %{ stop-process $_.processid }
    }

    function format-eventlog {
        $input | %{
            echo ("$e[95m[$e[34m" + ('{0:MM-dd} ' -f $_.timecreated) + `
            "$e[36m" + ('{0:HH:mm:ss}' -f $_.timecreated) + `
            "$e[95m]$e[0m " + `
            ($_.message -replace "`n.*",''))
        }
    }

    function global:syslog {
        get-winevent -log system -oldest | format-eventlog
    }

    # You have to enable the tasks log first as admin, see:
    # https://stackoverflow.com/q/13965997/262458
    function global:tasklog {
        get-winevent 'Microsoft-Windows-TaskScheduler/Operational' -oldest | format-eventlog
    }

    function global:ntop {
        ntop.exe -s 'CPU%' @args
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
        foreach ($arg in ($args | %{ $_ })) {
            if (test-path $arg) {
                (gi $arg).lastwritetime = get-date
            }
            else {
                ni $arg | out-null
            }
        }
    }

    function global:sudo {
        ssh localhost "sl $(get-location); $($args -join " ")"
    }

    function global:nproc {
        [environment]::processorcount
    }
}

# Windows PowerShell does not have Remove-Alias.
function rmalias($alias) {
    # Use a loop to remove aliases from all scopes.
    while (test-path "alias:\$alias") {
        ri -force "alias:\$alias"
    }
}

rmalias pwd

function global:pwd {
    get-location | % path | pretty_path
}

function global:ltr { $input | sort lastwritetime }

function global:count { $input | measure | % count }

# Example utility function to convert CSS hex color codes to rgb(x,x,x) color codes.
function global:hexcolortorgb {
    'rgb(' + ((($args[0] -replace '^(#|0x)','' -split '(..)(..)(..)')[1,2,3] | %{ [uint32]"0x$_" }) -join ',') + ')'
}

function global:which {
    $cmd = try { get-command @args -ea stop }
           catch { write-error $_ -ea stop }

    if ($cmd.commandtype -eq 'Application') {
        $cmd = $cmd.source | pretty_path
    }

    $cmd
}

function map_alias {
    $input | %{ $_.getenumerator() | %{
        $path = $_.value

        # Expand any globs in path.
        if ($dir = resolve-path (
                split-path -parent $path) -ea ignore) {

            $path = "$dir/$(split-path -leaf $path)"
        }

        if ($cmd = get-command $path -ea ignore) {
            rmalias $_.key
            set-alias -scope global $_.key -value $cmd
        }
    }}
}

if ($iswindows) {
    @{
        notepad = '/prog*s/notepad++/notepad++'
        patch   = '/prog*s/git/usr/bin/patch'
        wordpad = '/prog*s/win*nt/accessories/wordpad'
    } | map_alias
}

# For diff on Windows install diffutils from choco.
if (get-command diff -commandtype application -ea ignore) {
    rmalias diff
}

@{
    vcpkg = '~/source/repos/vcpkg/vcpkg'
} | map_alias

if ($iswindows) {
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
        # vcvars64.bat          for x86_64 native builds.
        # vcvars32.bat          for x86_32 native builds.
        # vcvarsamd64_arm64.bat for ARM64  cross  builds.
        cmd /c 'vcvars64.bat & set' | ?{ $_ -match '=' } | %{
            $var,$val = $_.split('=')
            set-item -force "env:$var" -value $val
        }
        popd
    }
}

# Remove duplicates from $env:PATH.
$env:PATH = (split_env_path | select -unique) -join $path_sep

} | import-module

import-module posh-git

new-module MyPrompt -script {
# Windows PowerShell does not support the `e special character
# sequence for Escape, so we use a variable $e for this.
$e = [char]27

function global:prompt_error_indicator() {
    if ($gitpromptvalues.dollarquestion) {
        "$e[38;2;078;154;06m{0}$e[0m" -f 'v'
    }
    else {
        "$e[38;2;220;020;60m{0}$e[0m" -f 'x'
    }
}

$env_indicator = "$e[38;2;173;127;168m{0}{1}{2}$e[38;2;173;127;168m{3}$e[0m" -f `
    'PWSH',
    ("$e[1m$e[38;2;85;87;83m{0}$e[0m" -f '{'),
    $(if (-not $iswindows)
             { "$e[1m$e[38;2;175;095;000m{0}$e[0m" -f 'L' }
        else { "$e[1m$e[38;2;032;178;170m{0}$e[0m" -f 'W' }),
    ("$e[1m$e[38;2;85;87;83m{0}$e[0m" -f '}')

if ($iswindows) {
    $username = $env:USERNAME
    $hostname = $env:COMPUTERNAME.tolower()
}
else {
    $username = $(whoami)
    $hostname = $(hostname) -replace '\..*',''
}

$gitpromptsettings.defaultpromptprefix.text = '{0} {1} ' `
    -f '$(prompt_error_indicator)',$env_indicator

$gitpromptsettings.defaultpromptbeforesuffix.text ="`n$e[0m$e[38;2;140;206;250m{0}$e[1;97m@$e[0m$e[38;2;140;206;250m{1} " `
    -f $username,$hostname

$gitpromptsettings.defaultpromptabbreviatehomedirectory = $true
$gitpromptsettings.defaultpromptwritestatusfirst        = $false
$gitpromptsettings.defaultpromptpath.foregroundcolor    = 0xC4A000
$gitpromptsettings.defaultpromptsuffix.foregroundcolor  = 0xDC143C
$gitpromptsettings.windowtitle = $null

$host.ui.rawui.windowtitle = $hostname
} | import-module

import-module psreadline

set-psreadlineoption     -editmode emacs
set-psreadlineoption     -historysearchcursormovestoend

set-psreadlinekeyhandler -key tab       -function complete
set-psreadlinekeyhandler -key uparrow   -function historysearchbackward
set-psreadlinekeyhandler -key downarrow -function historysearchforward

set-psreadlinekeyhandler -chord 'ctrl+spacebar' -function menucomplete
set-psreadlinekeyhandler -chord 'alt+enter'     -function addline

if ($private:posh_vcpkg = resolve-path `
    ~/source/repos/vcpkg/scripts/posh-vcpkg -ea ignore) {

    import-module $posh_vcpkg
}

if ($private:private_profile = resolve-path `
    $ps_config_dir/private-profile.ps1 -ea ignore) {

    . $private_profile
}
