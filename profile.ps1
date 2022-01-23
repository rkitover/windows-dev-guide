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
        $OutputEncoding = new-object System.Text.UTF8Encoding

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
elseif (-not $env:LANG) {
    $env:LANG = 'en_US.UTF-8'
}

# Make help nicer.
$PSDefaultParameterValues["get-help:Full"] = $true
$env:PAGER = 'less'

new-module MyProfile -script {

$path_sep = [system.io.path]::pathseparator

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

    $home_dir = [regex]::escape($home)

    $str -replace ('^'+$home_dir),'~'
}

function backslashes_to_forward($str) {
    if (-not $str) { $str = $input }

    if (-not $iswindows) { return $str }

    $str -replace '\\','/'
}

function global:shortpath($str) {
    if (-not $str) { $str = $input }

    $str | resolve-path -ea ignore | % path | home_to_tilde | `
        trim_sysdrive | backslashes_to_forward
}

function global:realpath($str) {
    if (-not $str) { $str = $input }

    $str | resolve-path -ea ignore | % path | backslashes_to_forward
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
}

$global:profile = $profile | shortpath

$global:ps_config_dir = split-path $profile -parent

$global:ps_history = "$ps_share_dir/ConsoleHost_history.txt"

if ($iswindows) {
    $global:terminal_settings = resolve-path ~/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json -ea ignore | shortpath
}

$extra_paths = @{
    prepend = '~/.local/bin'
    append  = '~/AppData/Roaming/Python/Python*/Scripts'
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

if (-not $env:DISPLAY) {
    $env:DISPLAY = '127.0.0.1:0.0'
}

if (-not $iswindows -and -not $env:XAUTHORITY) {
    $env:XAUTHORITY = join-path $home .Xauthority
}

function global:megs {
    gci @args | select mode, lastwritetime, @{ name="MegaBytes"; expression={ [math]::round($_.length / 1MB, 2) }}, name
}

function global:cmconf {
    sls 'CMAKE_BUILD_TYPE|VCPKG_TARGET_TRIPLET|UPSTREAM_RELEASE' CMakeCache.txt
}

# Windows PowerShell does not have Remove-Alias.
function rmalias($alias) {
    # Use a loop to remove aliases from all scopes.
    while (test-path "alias:\$alias") {
        ri -force "alias:\$alias"
    }
}

# Check if invocation of external command works correctly.
function ext_cmd_works($exe) {
    $works = $false

    if ((get-command $exe).commandtype -ne 'Application') {
        write-error 'not an external command' -ea stop
    }

    $($input | &$exe @args | out-null; $works = $?) 2>&1 | sv err_out

    $works -and -not $err_out
}

function global:which {
    $cmd = try { get-command @args -ea stop | select -first 1 }
           catch { write-error $_ -ea stop }

    if ($cmd.commandtype -match '^(Application|ExternalScript)$') {
        $cmd = $cmd.source | shortpath
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

# Find vim and set $env:EDITOR.
if ($iswindows) {
    $vim = ''

    if ($vim = (get-command nvim -ea ignore).source) {
        set-alias vim -value $vim -scope global
    }
    else {
        $locs =
            { (get-command vim.exe @args).source },
            { resolve-path /tools/vim/vim*/vim.exe @args }

        foreach ($loc in $locs) {
            if ($vim = &$loc -ea ignore) { break }
        }
    }

    if ($vim) {
        $env:EDITOR = realpath $vim
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
        get-ciminstance win32_process -filter "name like '%${pat}%' OR commandline like '%${pat}%'" | select ProcessId,Name,CommandLine
    }

    function global:pkill($pat) {
        pgrep $pat | %{ stop-process $_.ProcessId }
    }

    function format-eventlog {
        $input | %{
            ("$e[95m[$e[34m" + ('{0:MM-dd} ' -f $_.timecreated) + `
            "$e[36m" + ('{0:HH:mm:ss}' -f $_.timecreated) + `
            "$e[95m]$e[0m " + `
            ($_.message -replace "`n.*",''))
        }
    }

    function global:syslog {
        get-winevent -log system -oldest | format-eventlog | less -r
    }

    # You have to enable the tasks log first as admin, see:
    # https://stackoverflow.com/q/13965997/262458
    function global:tasklog {
        get-winevent 'Microsoft-Windows-TaskScheduler/Operational' `
            -oldest | format-eventlog | less -r
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
        if (-not $args) { $args = $input }

        ssh localhost -- "sl $(get-location); $($args -join " ")"
    }

    function global:nproc {
        [environment]::processorcount
    }

    # To see what a choco shim is pointing to.
    function global:readshim {
        if (-not $args) { $args = $input }

        $args | %{ get-command $_ -commandtype application `
                       -ea ignore } | `
            %{ &$_ --shimgen-help } | `
            ?{ $_ -match "^ Target: '(.*)'$" } | `
            %{ $matches[1] } | shortpath
    }

    function global:env {
        gci env: | sort name | %{
            "`${{env:{0}}}='{1}'" -f $_.name,$_.value
        }
    }
}
elseif ($ismacos) {
    function global:ls {
        &(command ls) -Gh $args
        if (-not $?) { write-error "exited: $LastExitCode" -ea stop }
    }
}
else { # linux
    function global:ls {
        &(command ls) --color=auto -h $args
        if (-not $?) { write-error "exited: $LastExitCode" -ea stop }
    }
}

if ((get-command -commandtype application grep -ea ignore) -and `
    ('foo' | ext_cmd_works (command grep) --color foo)) {

    function global:grep {
        $input | &(command grep) --color $args
        if (-not $?) { write-error "exited: $LastExitCode" -ea stop }
    }
}

rmalias pwd

function global:pwd {
    get-location | % path | shortpath
}

function global:ltr { $input | sort lastwritetime }

function global:count { $input | measure | % count }

# Example utility function to convert CSS hex color codes to rgb(x,x,x) color codes.
function global:hexcolortorgb {
    'rgb(' + ((($args[0] -replace '^(#|0x)','' -split '(..)(..)(..)')[1,2,3] | %{ [uint32]"0x$_" }) -join ',') + ')'
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
            set-alias $_.key -value $cmd -scope global
        }
    }}
}

if ($iswindows) {
    @{
        patch   = '/prog*s/git/usr/bin/patch'
        wordpad = '/prog*s/win*nt/accessories/wordpad'
    } | map_alias
}

# For diff on Windows install diffutils from choco.
if (command diff) { rmalias diff }

@{
    vcpkg = '~/source/repos/vcpkg/vcpkg'
} | map_alias

# Aliases to pwsh Cmdlets/functions.
set-alias s -value select-object -scope global

if ($iswindows) {
    # Load VS env only once.
    foreach ($vs_type in 'buildtools','community') {
        $vs_path="/program files/microsoft visual studio/2022/${vs_type}/vc/auxiliary/build"

        if (test-path $vs_path) {
            break
        }
        else {
            $vs_path=$null
        }
    }

    if ($vs_path -and -not $env:VSCMD_VER) {
        pushd $vs_path
        cmd /c 'vcvars64.bat & set' | ?{ $_ -match '=' } | %{
#        cmd /c 'vcvars32.bat & set' | ?{ $_ -match '=' } | %{
#        cmd /c 'vcvarsamd64_arm64.bat & set' | ?{ $_ -match '=' } | %{
            $var,$val = $_.split('=')
            set-item -force "env:\$var" -val $val
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
    $(if ($islinux)
          { "$e[1m$e[38;2;175;095;000m{0}$e[0m" -f 'L' }
      elseif ($ismacos)
          { "$e[1m$e[38;2;175;095;000m{0}$e[0m" -f 'M' }
      else # windows
          { "$e[1m$e[38;2;032;178;170m{0}$e[0m" -f 'W' }),
    ("$e[1m$e[38;2;85;87;83m{0}$e[0m" -f '}')

if ($iswindows) {
    $username = $env:USERNAME
    $hostname = $env:COMPUTERNAME.tolower()
}
else {
    $username = whoami
    $hostname = (hostname) -replace '\..*',''
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

if ($private:src = resolve-path `
    $ps_config_dir/private-profile.ps1 -ea ignore) {

    $global:private_profile = $src | shortpath

    . $private_profile
}
