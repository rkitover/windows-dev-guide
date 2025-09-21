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
$env:LESS = '-Q$-r$-X$-F$-K'

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

function curdrive {
    if ($iswindows) { $pwd.drive.name + ':' }
}

function trim_curdrive($str) {
    if (-not $str) { $str = $input }

    if (-not $iswindows) { return $str }

    $str -replace ('^'+[regex]::escape((curdrive))),''
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

function global:remove_path_spaces($path) {
    if (-not $path) { $path = $($input) }

    if (-not $iswindows) { return $path }

    if (-not $path) { return $path }

    $parts = while ($path -notmatch '^\w+:[\\/]$') {
        $leaf = split-path -leaf   $path
        $path = split-path -parent $path

        $fs = new-object -comobject scripting.filesystemobject

        if ($leaf -match ' ') {
            $leaf = if ((gi "${path}/$leaf").psiscontainer) {
                split-path -leaf $fs.getfolder("${path}/$leaf").shortname
            }
            else {
                split-path -leaf $fs.getfile("${path}/$leaf").shortname
            }
        }
        
        $leaf.tolower()
    }

    if ($parts) { [array]::reverse($parts) }

    $path = $path -replace '[\\/]+', ''

    $path + '/' + ($parts -join '/')
}

function global:shortpath($str) {
    if (-not $str) { $str = $($input) }

    $str | resolve-path -ea ignore | % path `
        | remove_path_spaces | trim_curdrive | backslashes_to_forward
}

function global:realpath($str) {
    if (-not $str) { $str = $($input) }

    $str | resolve-path -ea ignore | % path `
        | remove_path_spaces | backslashes_to_forward
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

if (-not $env:ENV) {
    $env:ENV = shortpath ~/.shrc
}

if (-not $env:VCPKG_ROOT) {
    $env:VCPKG_ROOT = resolve-path ~/source/repos/vcpkg -ea ignore
}

if ($iswindows) {
    # Load VS env only once.
    :OUTER foreach ($vs_year in '2022','2019','2017') {
        foreach ($vs_type in 'preview','buildtools','community') {
            foreach ($x86 in '',' (x86)') {
                $vs_path="/program files${x86}/microsoft visual studio/${vs_year}/${vs_type}/Common7/Tools"

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
        $default_arch = $env:PROCESSOR_ARCHITECTURE.tolower()

        function global:vsenv($arch) {
            if (-not $arch)      { $arch = $default_arch }
            if ($arch -eq 'x64') { $arch = 'amd64' }

            $saved_vcpkg_root = $env:VCPKG_ROOT

            & $vs_path/Launch-VsDevShell.ps1 -arch $arch -skipautomaticlocation

            if ($saved_vcpkg_root) {
                $env:VCPKG_ROOT = $saved_vcpkg_root
            }
        }

        vsenv $default_arch
    }
}

if ($env:VCPKG_ROOT -and (test-path $env:VCPKG_ROOT)) {
    $global:vcpkg_toolchain = $env:VCPKG_ROOT + '/scripts/buildsystems/vcpkg.cmake'

    if ($iswindows) {
        $arch = if ($env:PROCESSOR_ARCHITECTURE -ieq 'AMD64') { 'x64' }
            else { $env:PROCESSOR_ARCHITECTURE.tolower() }

        $env:VCPKG_DEFAULT_TRIPLET = "${arch}-windows-static"

        $env:LIB     = $env:LIB     + ';' + $env:VCPKG_ROOT + '/installed/' + $env:VCPKG_DEFAULT_TRIPLET + '/lib'
        $env:INCLUDE = $env:INCLUDE + ';' + $env:VCPKG_ROOT + '/installed/' + $env:VCPKG_DEFAULT_TRIPLET + '/include'
    }
}

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
                # WinGet symlinks
            %{ if ($link_target = (gi $_).target) {
                    $link_target | shortpath
                }
                # Scoop shims
                elseif (test-path ($shim = $_ -replace '\.exe$','.shim')) {
                    gc $shim | %{ $_ -replace '^path = "([^"]+)"$','$1' } | shortpath
                }
                # Chocolatey shims
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

    if ((test-path ~/.tmux-pwsh.conf) -and (test-path /msys64/usr/bin/tmux.exe)) {
        function global:tmux {
            /msys64/usr/bin/tmux -f ~/.tmux-pwsh.conf @args
        }
    }
    elseif ((gcm -ea ignore wsl) -and (wsl -- ls '~/.tmux-pwsh.conf' 2>$null)) {
        function global:tmux {
            wsl -- tmux -f '~/.tmux-pwsh.conf' @args
        }
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

# Alias the MSYS2 environments if MSYS2 is installed.
if ($iswindows -and (test-path /msys64)) {
    function global:msys2 {
        $env:MSYSTEM = 'MSYS'
        /msys64/usr/bin/bash -l $(if ($args) { '-c',"$args" })
        ri env:MSYSTEM
    }

    function global:msys {
        $env:MSYSTEM = 'MSYS'
        /msys64/usr/bin/bash -l $(if ($args) { '-c',"$args" })
        ri env:MSYSTEM
    }

    function global:clang64 {
        $env:MSYSTEM = 'CLANG64'
        /msys64/usr/bin/bash -l $(if ($args) { '-c',"$args" })
        ri env:MSYSTEM
    }

    function global:ucrt64 {
        $env:MSYSTEM = 'UCRT64'
        /msys64/usr/bin/bash -l $(if ($args) { '-c',"$args" })
        ri env:MSYSTEM
    }

    function global:mingw64 {
        $env:MSYSTEM = 'MINGW64'
        /msys64/usr/bin/bash -l $(if ($args) { '-c',"$args" })
        ri env:MSYSTEM
    }

    function global:mingw32 {
        $env:MSYSTEM = 'MINGW32'
        /msys64/usr/bin/bash -l $(if ($args) { '-c',"$args" })
        ri env:MSYSTEM
    }
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
