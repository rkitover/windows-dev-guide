#requires -Modules Pester

<#
.SYNOPSIS
    Pester tests for profile.ps1 functions, organized by platform.
#>

beforeall {
    # ── snapshot environment so tests cannot pollute each other ──────
    $script:env_snap = @{}
    gci env: | %{ $script:env_snap[$_.name] = $_.value }

    $script:profile_path = "$PSScriptRoot/profile.ps1"

    # ── temp directory for mock vcvarsall and test files ─────────────
    $script:temp_dir = join-path ([system.io.path]::gettemppath()) "profile-tests-$PID"
    ni -itemtype directory $script:temp_dir -force | out-null

    # ── mock vcvarsall.bat ──────────────────────────────────────────
    # Calls a generated response.bat that sets env vars and echoes
    # banner lines, so the subsequent `&& set` (from vsenv) outputs
    # the correct merged environment.
    $script:mock_vcvarsall   = join-path $script:temp_dir 'vcvarsall.bat'
    $script:mock_response    = join-path $script:temp_dir 'vcvarsall_response.bat'
    $script:mock_exitcode    = join-path $script:temp_dir 'vcvarsall_exitcode.txt'
    $script:mock_args_log    = join-path $script:temp_dir 'vcvarsall_args.txt'

    @"
@echo off
echo %* > "$($script:mock_args_log)"
if not exist "$($script:mock_exitcode)" goto :RUN
set /p EXITCODE=<"$($script:mock_exitcode)"
if not "%EXITCODE%"=="0" exit /b %EXITCODE%
:RUN
if exist "$($script:mock_response)" call "$($script:mock_response)"
"@ | set-content $script:mock_vcvarsall -encoding ascii

    function script:set_mock_output {
        param([string[]]$lines = @(), [int]$exit_code = 0)

        if ($lines) {
            # Convert response lines into a bat file: VAR=value lines
            # become `set` commands, non-VAR lines become `echo` commands.
            $bat = @('@echo off') + @($lines | %{
                if ($_ -match '^[A-Za-z_][A-Za-z_0-9]*=') { "set `"$_`"" }
                else { "echo $_" }
            })
            $bat | set-content $script:mock_response -encoding ascii
        }
        elseif (test-path $script:mock_response) {
            ri $script:mock_response
        }
        "$exit_code" | set-content $script:mock_exitcode -encoding ascii
    }

    function script:get_mock_args {
        if (test-path $script:mock_args_log) {
            (gc $script:mock_args_log -raw).trim()
        }
    }

    # ── build a standard mock vcvarsall response for a given arch ───
    function script:new_vcvarsall_response {
        param(
            [string]$arch          = 'x64',
            [string]$vs_root       = 'C:\Program Files\Microsoft Visual Studio\18\Community',
            [string]$sdk_bin       = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0',
            [string]$tools_version = '14.50.35717'
        )

        $host_arch = 'x64'

        $target_arch = if ($arch -iin 'x64','amd64') { 'x64' }
                       elseif ($arch -ieq 'x86')     { 'x86' }
                       elseif ($arch -ieq 'arm64')    { 'arm64' }
                       else { $arch }

        $msvc_bin = "$vs_root\VC\Tools\MSVC\$tools_version\bin\Host${host_arch}\${target_arch}"

        $vs_path_entries = @(
            $msvc_bin
            "$vs_root\Common7\IDE\VC\VCPackages"
            "$vs_root\Common7\IDE\CommonExtensions\Microsoft\TestWindow"
            "$vs_root\MSBuild\Current\bin\Roslyn"
            'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64'
            'C:\Program Files (x86)\HTML Help Workshop'
            "$sdk_bin\${target_arch}"
            'C:\Program Files (x86)\Windows Kits\10\bin\x64'
            "$vs_root\MSBuild\Current\Bin\amd64"
            'C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319'
            "$vs_root\Common7\IDE"
            "$vs_root\Common7\Tools"
            "$vs_root\VC\vcpkg"
        )

        # Use %Path% so cmd.exe expands the actual inherited PATH at
        # runtime — this respects any stripping vsenv does before launch.
        $vs_path_joined = $vs_path_entries -join ';'

        @(
            "[vcvarsall.bat] Environment initialized for: '${target_arch}'"
            "Path=%Path%;$vs_path_joined"
            "INCLUDE=$vs_root\VC\Tools\MSVC\$tools_version\include;$sdk_bin\..\..\..\include\10.0.26100.0\ucrt;$sdk_bin\..\..\..\include\10.0.26100.0\shared;$sdk_bin\..\..\..\include\10.0.26100.0\um"
            "LIB=$vs_root\VC\Tools\MSVC\$tools_version\lib\${target_arch};$sdk_bin\..\..\..\lib\10.0.26100.0\ucrt\${target_arch};$sdk_bin\..\..\..\lib\10.0.26100.0\um\${target_arch}"
            "LIBPATH=$vs_root\VC\Tools\MSVC\$tools_version\lib\${target_arch}"
            "EXTERNAL_INCLUDE=$vs_root\VC\Tools\MSVC\$tools_version\include"
            "VSINSTALLDIR=$vs_root\"
            "VCToolsVersion=$tools_version"
            "VSCMD_ARG_HOST_ARCH=$host_arch"
            "VSCMD_ARG_TGT_ARCH=$target_arch"
            "__VSCMD_PREINIT_PATH=$env:Path"
        )
    }

    # ── load the profile ────────────────────────────────────────────
    $script:path_sep = [system.io.path]::pathseparator

    . $script:profile_path

    # ── inject mock vcvarsall into the module ───────────────────────
    if ($iswindows -and (get-module MyProfile)) {
        & (get-module MyProfile) {
            if (get-variable vcvarsall -scope script -ea ignore) {
                $script:vcvarsall = resolve-path $args[0]
            }
        } $script:mock_vcvarsall
    }
}

afterall {
    ri env:* -force -ea ignore
    $script:env_snap.getenumerator() | %{
        si -literalpath "env:$($_.key)" $_.value
    }

    if ($script:temp_dir -and (test-path $script:temp_dir)) {
        ri $script:temp_dir -recurse -force -ea ignore
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Module Loading
# ════════════════════════════════════════════════════════════════════════
describe 'Module Loading' {
    it 'creates the MyProfile module' {
        get-module MyProfile | should -not -benullorempty
    }

    it 'sets $global:ps_share_dir' {
        $global:ps_share_dir | should -not -benullorempty
    }

    it 'sets $global:ps_config_dir' {
        $global:ps_config_dir | should -not -benullorempty
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Environment Setup
# ════════════════════════════════════════════════════════════════════════
describe 'Environment Setup' {
    it 'sets $env:PAGER to less' {
        $env:PAGER | should -be 'less'
    }

    it 'sets $env:LESS with expected flags' {
        $env:LESS | should -not -benullorempty
        $env:LESS | should -match '-Q'
        $env:LESS | should -match '-r'
    }

    it 'sets TERM to include 256color' {
        $env:TERM | should -match '256color'
    }

    it 'sets COLORTERM to truecolor' {
        $env:COLORTERM | should -be 'truecolor'
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Path Utility Functions
# ════════════════════════════════════════════════════════════════════════
describe 'Path Utility Functions' {

    describe 'syspath' {
        it 'resolves an existing path to its native form' {
            $r = syspath $home
            $r | should -not -benullorempty
            if ($iswindows) { $r | should -match '\\' }
        }

        it 'accepts pipeline input' {
            $r = $home | syspath
            $r | should -not -benullorempty
        }

        it 'returns nothing for nonexistent paths' {
            $r = syspath '/nonexistent/path/xyz'
            $r | should -benullorempty
        }
    }

    describe 'shortpath' -tag 'Windows' -skip:(-not $iswindows) {
        it 'returns a forward-slash path without the current drive prefix' {
            $r = shortpath $home
            $r | should -not -benullorempty
            $r | should -match '/'
            $r | should -not -match '^[A-Z]:'
        }

        it 'accepts pipeline input' {
            $r = $home | shortpath
            $r | should -not -benullorempty
        }
    }

    describe 'realpath' -tag 'Windows' -skip:(-not $iswindows) {
        it 'returns a forward-slash absolute path with the drive prefix' {
            $r = realpath $home
            $r | should -not -benullorempty
            $r | should -match '/'
            $r | should -match '^[A-Z]:/'
        }
    }

    describe 'split_env_path (module-private)' {
        it 'splits and resolves $env:Path entries' {
            $r = & (get-module MyProfile) { split_env_path }
            $r | should -not -benullorempty
            $r.count | should -begreaterthan 0
        }

        it 'discards nonexistent entries' {
            $old = $env:Path
            try {
                $env:Path = "/nonexistent/test/dir$($script:path_sep)$env:Path"
                $r = & (get-module MyProfile) { split_env_path }
                $r | should -not -contain '/nonexistent/test/dir'
            }
            finally { $env:Path = $old }
        }
    }
}

# ════════════════════════════════════════════════════════════════════════
#  hexcolortorgb
# ════════════════════════════════════════════════════════════════════════
describe 'hexcolortorgb' {
    it 'converts #FF8800' {
        hexcolortorgb '#FF8800' | should -be 'rgb(255,136,0)'
    }

    it 'converts 0xFF8800' {
        hexcolortorgb '0xFF8800' | should -be 'rgb(255,136,0)'
    }

    it 'converts bare hex' {
        hexcolortorgb 'FF8800' | should -be 'rgb(255,136,0)'
    }

    it 'handles lowercase' {
        hexcolortorgb '#ff8800' | should -be 'rgb(255,136,0)'
    }

    it 'converts black' {
        hexcolortorgb '#000000' | should -be 'rgb(0,0,0)'
    }

    it 'converts white' {
        hexcolortorgb '#FFFFFF' | should -be 'rgb(255,255,255)'
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Command Resolution
# ════════════════════════════════════════════════════════════════════════
describe 'Command Resolution' {

    describe 'which' {
        it 'finds a built-in cmdlet' {
            $r = which get-childitem
            $r | should -not -benullorempty
        }

        it 'errors on nonexistent command' {
            { which 'nonexistent-cmd-xyz-12345' } | should -throw
        }
    }

    describe 'type' {
        it 'delegates to which' {
            $r = type get-childitem
            $r | should -not -benullorempty
        }
    }

    describe 'command' -skip:(-not $iswindows) {
        it 'finds external applications' `
            -skip:(-not (get-command cmd.exe -ea ignore)) {
            $r = command cmd.exe
            $r | should -not -benullorempty
        }

        it 'errors on nonexistent command' {
            { command 'nonexistent-cmd-xyz-12345' } | should -throw
        }
    }
}

# ════════════════════════════════════════════════════════════════════════
#  rmalias
# ════════════════════════════════════════════════════════════════════════
describe 'rmalias' {
    it 'removes an alias that exists' {
        set-alias -name 'test-rmalias-xyz' -value get-childitem -scope global
        get-alias 'test-rmalias-xyz' -ea ignore | should -not -benullorempty
        rmalias 'test-rmalias-xyz'
        get-alias 'test-rmalias-xyz' -ea ignore | should -benullorempty
    }

    it 'does not error when alias does not exist' {
        { rmalias 'nonexistent-alias-xyz-12345' } | should -not -throw
    }
}

# ════════════════════════════════════════════════════════════════════════
#  ver
# ════════════════════════════════════════════════════════════════════════
describe 'ver' {
    it 'returns a non-empty version string' {
        ver | should -not -benullorempty
    }

    it 'contains Windows info on Windows' -skip:(-not $iswindows) {
        ver | should -match 'Windows \d+ build \d+'
    }

    it 'contains kernel info on Linux' -skip:(-not $islinux) {
        ver | should -match 'kernel'
    }

    it 'contains kernel info on macOS' -skip:(-not $ismacos) {
        ver | should -match 'kernel'
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Pipeline Utilities
# ════════════════════════════════════════════════════════════════════════
describe 'Pipeline Utilities' {
    describe 'count' {
        it 'counts pipeline items' {
            $r = 1,2,3 | count
            $r | should -be 3
        }

        it 'returns 0 for empty input' {
            $r = @() | count
            $r | should -be 0
        }
    }

    describe 'ltr' {
        it 'sorts by LastWriteTime' -skip:(-not $iswindows) {
            $dir = join-path $script:temp_dir 'ltr-test'
            ni -itemtype directory $dir -force | out-null
            'a' | set-content "$dir/file1.txt"
            start-sleep -milliseconds 100
            'b' | set-content "$dir/file2.txt"
            $r = gci $dir | ltr
            $r[0].name | should -be 'file1.txt'
            $r[1].name | should -be 'file2.txt'
        }
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Symlink Functions
# ════════════════════════════════════════════════════════════════════════
describe 'Symlink Functions' -skip:(-not $iswindows) {
    beforeall {
        $script:link_dir = join-path $script:temp_dir 'symlink-tests'
        ni -itemtype directory $script:link_dir -force | out-null
        'target content' | set-content (join-path $script:link_dir 'target.txt')
        ni -itemtype directory (join-path $script:link_dir 'targetdir') -force | out-null
    }

    describe 'mklink' {
        it 'creates a symbolic link with explicit link and target' {
            $link   = join-path $script:link_dir 'link1.txt'
            $target = join-path $script:link_dir 'target.txt'
            mklink $link $target
            (gi $link).target | should -not -benullorempty
        }

        it 'errors when link parent does not exist' {
            { mklink '/nonexistent/dir/link.txt' (join-path $script:link_dir 'target.txt') } | should -throw
        }
    }

    describe 'rmlink' {
        it 'removes a symbolic link' {
            $link   = join-path $script:link_dir 'link-to-remove.txt'
            $target = join-path $script:link_dir 'target.txt'
            mklink $link $target
            test-path $link | should -betrue
            rmlink $link
            test-path $link | should -befalse
        }

        it 'errors on non-symlink' {
            { rmlink (join-path $script:link_dir 'target.txt') } | should -throw
        }

        it 'errors with no arguments' {
            { rmlink } | should -throw
        }
    }
}

# ════════════════════════════════════════════════════════════════════════
#  Windows-Only Functions
# ════════════════════════════════════════════════════════════════════════
describe 'Windows-Only Functions' -tag 'Windows' -skip:(-not $iswindows) {

    describe 'head' {
        it 'returns first 10 lines by default' {
            $r = 1..20 | head
            $r.count | should -be 10
            $r[0] | should -be 1
        }

        it 'accepts -N for custom count' {
            $r = 1..20 | head -5
            $r.count | should -be 5
        }
    }

    describe 'tail' {
        it 'returns last 10 lines by default' {
            $r = 1..20 | tail
            $r.count | should -be 10
            $r[-1] | should -be 20
        }

        it 'accepts -N for custom count' {
            $r = 1..20 | tail -3
            $r.count | should -be 3
            $r[-1] | should -be 20
        }
    }

    describe 'touch' {
        it 'creates a new file when it does not exist' {
            $f = join-path $script:temp_dir 'touch-new.txt'
            test-path $f | should -befalse
            touch $f
            test-path $f | should -betrue
        }

        it 'updates timestamp on an existing file' {
            $f = join-path $script:temp_dir 'touch-existing.txt'
            'content' | set-content $f
            $before = (gi $f).lastwritetime
            start-sleep -milliseconds 100
            touch $f
            (gi $f).lastwritetime | should -begreaterthan $before
        }
    }

    describe 'nproc' {
        it 'returns a positive integer' {
            nproc | should -begreaterthan 0
        }
    }

    describe 'env' {
        it 'returns formatted environment variable strings' {
            $r = env
            $r | should -not -benullorempty
            $r[0] | should -match '^\$\{env:[^}]+\}='
        }
    }

    describe 'reset' {
        it 'outputs the ANSI reset escape sequence' {
            $r = reset 6>&1 *>&1 | select -first 1
            $r | should -match ([regex]::escape([char]27))
        }
    }

    describe 'megs' {
        it 'shows file size in megabytes' {
            $f = join-path $script:temp_dir 'megs-test.txt'
            'x' * 1000 | set-content $f
            $r = megs $f
            $r | should -not -benullorempty
            $r.megabytes | should -beoftype [double]
        }
    }
}

# ════════════════════════════════════════════════════════════════════════
#  tac
# ════════════════════════════════════════════════════════════════════════
describe 'tac' -skip:(-not (get-command tac -ea ignore)) {
    it 'reverses lines from pipeline input' {
        $r = 'a','b','c' | tac
        $r[0] | should -be 'c'
        $r[1] | should -be 'b'
        $r[2] | should -be 'a'
    }
}

# ════════════════════════════════════════════════════════════════════════
#  vsenv — Extensive Tests
# ════════════════════════════════════════════════════════════════════════
describe 'vsenv' -tag 'Windows' -skip:(-not $iswindows) {

    beforeall {
        $script:vs_root       = 'C:\Program Files\Microsoft Visual Studio\18\Community'
        $script:tools_version = '14.50.35717'
        $script:sdk_bin       = 'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0'

        $script:vsenv_env_snap = @{}
        gci env: | %{ $script:vsenv_env_snap[$_.name] = $_.value }

        function script:get_vsenv_state {
            & (get-module MyProfile) { $script:vsenv_state }
        }

        function script:get_vsenv_vcpkg_in_path {
            & (get-module MyProfile) { $script:vsenv_vcpkg_in_path }
        }

        function script:reset_vsenv {
            try { vsenv -unload } catch {}
            & (get-module MyProfile) {
                $script:vsenv_state = $null
                $script:vsenv_vcpkg_in_path = $null
            }
        }

        function script:invoke_vsenv {
            param([string]$arch = 'x64', [string]$toolkit, [string[]]$extra_lines = @())

            $response = new_vcvarsall_response -arch $arch -vs_root $script:vs_root `
                -sdk_bin $script:sdk_bin -tools_version $script:tools_version
            if ($extra_lines) { $response = $response + $extra_lines }
            set_mock_output -lines $response
            if ($toolkit) { vsenv $arch $toolkit }
            else          { vsenv $arch }
        }
    }

    beforeeach {
        ri env:* -force -ea ignore
        $script:vsenv_env_snap.getenumerator() | %{
            si -literalpath "env:$($_.key)" $_.value
        }
        reset_vsenv
    }

    # ── Initial Load ────────────────────────────────────────────────
    describe 'Initial Load' {

        it 'adds VS tool paths to $env:Path' {
            invoke_vsenv -arch x64
            $env:Path | should -match 'Microsoft Visual Studio'
            $env:Path | should -match 'MSVC'
        }

        it 'sets INCLUDE from vcvarsall output' {
            invoke_vsenv -arch x64
            $env:INCLUDE | should -not -benullorempty
            $env:INCLUDE | should -match 'MSVC'
        }

        it 'sets LIB from vcvarsall output' {
            invoke_vsenv -arch x64
            $env:LIB | should -not -benullorempty
            $env:LIB | should -match 'MSVC'
        }

        it 'sets LIBPATH from vcvarsall output' {
            invoke_vsenv -arch x64
            $env:LIBPATH | should -not -benullorempty
        }

        it 'sets EXTERNAL_INCLUDE from vcvarsall output' {
            invoke_vsenv -arch x64
            $env:EXTERNAL_INCLUDE | should -not -benullorempty
        }

        it 'sets scalar env vars like VSINSTALLDIR' {
            invoke_vsenv -arch x64
            $env:VSINSTALLDIR | should -not -benullorempty
            $env:VSINSTALLDIR | should -match 'Microsoft Visual Studio'
        }

        it 'records vsenv_state' {
            invoke_vsenv -arch x64
            $state = get_vsenv_state
            $state | should -not -benullorempty
            $state.saved_lists | should -not -benullorempty
            $state.vars | should -not -benullorempty
        }

        it 'appends VS entries AFTER baseline PATH entries' {
            $first_baseline = ($env:Path -split ';')[0]
            invoke_vsenv -arch x64
            $entries = $env:Path -split ';'
            $base_idx = [array]::indexof($entries, $first_baseline)
            $vs_idx = 0
            for ($i = 0; $i -lt $entries.count; $i++) {
                if ($entries[$i] -match 'Microsoft Visual Studio') { $vs_idx = $i; break }
            }
            $vs_idx | should -begreaterthan $base_idx
        }

        it 'uses default arch when none specified' {
            set_mock_output -lines (new_vcvarsall_response -arch x64)
            vsenv
            get_mock_args | should -not -benullorempty
        }
    }

    # ── Unload ──────────────────────────────────────────────────────
    describe 'Unload' {

        it 'restores PATH to pre-vsenv baseline' {
            $baseline = $env:Path
            invoke_vsenv -arch x64
            $env:Path | should -not -be $baseline
            vsenv -unload
            $env:Path | should -not -match '\\Microsoft Visual Studio\\'
        }

        it 'restores INCLUDE to pre-vsenv value' {
            $before = $env:INCLUDE
            invoke_vsenv -arch x64
            vsenv -unload
            $env:INCLUDE | should -be $before
        }

        it 'restores LIB to pre-vsenv value' {
            $before = $env:LIB
            invoke_vsenv -arch x64
            vsenv -unload
            $env:LIB | should -be $before
        }

        it 'removes env vars that did not exist before vsenv' {
            ri env:VSINSTALLDIR -ea ignore
            invoke_vsenv -arch x64
            $env:VSINSTALLDIR | should -not -benullorempty
            vsenv -unload
            $env:VSINSTALLDIR | should -benullorempty
        }

        it 'clears vsenv_state to null' {
            invoke_vsenv -arch x64
            get_vsenv_state | should -not -benullorempty
            vsenv -unload
            get_vsenv_state | should -benullorempty
        }

        it 'is idempotent' {
            invoke_vsenv -arch x64
            vsenv -unload
            { vsenv -unload } | should -not -throw
        }
    }

    # ── Architecture Switching ──────────────────────────────────────
    describe 'Architecture Switching' {

        it 'switches from x64 to arm64 with cross-compile syntax' {
            invoke_vsenv -arch x64
            invoke_vsenv -arch arm64
            get_mock_args | should -match 'arm64'
            $env:Path | should -match 'arm64'
        }

        it 'switches from x64 to x86' {
            invoke_vsenv -arch x64
            invoke_vsenv -arch x86
            $env:Path | should -match 'x86'
        }

        it 'preserves user INCLUDE additions across arch switch' {
            invoke_vsenv -arch x64
            $env:INCLUDE += ';C:\Users\custom\include'
            invoke_vsenv -arch arm64
            $env:INCLUDE | should -match 'custom\\include'
        }

        it 'does not accumulate stale entries across rapid switches' {
            invoke_vsenv -arch x64
            invoke_vsenv -arch arm64
            invoke_vsenv -arch x86
            invoke_vsenv -arch x64

            $entries = $env:Path -split ';'
            ($entries | ? { $_ -match 'HostX64\\arm64' }) | should -benullorempty
            ($entries | ? { $_ -match 'HostX64\\x86' })   | should -benullorempty
        }

        it 'treats x64 and amd64 as synonyms' {
            invoke_vsenv -arch x64
            $env:Path | should -match 'HostX64\\x64'

            reset_vsenv
            ri env:* -force -ea ignore
            $script:vsenv_env_snap.getenumerator() | %{
                si -literalpath "env:$($_.key)" $_.value
            }

            invoke_vsenv -arch amd64
            $env:Path | should -match 'HostX64\\x64'
        }
    }

    # ── Unload then Reload ──────────────────────────────────────────
    describe 'Unload then Reload' {

        it 'produces identical VS entries to a fresh load' {
            invoke_vsenv -arch x64
            $first_vs = ($env:Path -split ';') | ? { $_ -match 'Microsoft Visual Studio' }

            vsenv -unload
            invoke_vsenv -arch x64
            $reload_vs = ($env:Path -split ';') | ? { $_ -match 'Microsoft Visual Studio' }

            ($reload_vs -join ';') | should -be ($first_vs -join ';')
        }

        it 'does not accumulate entries' {
            invoke_vsenv -arch x64
            $first_count = ($env:Path -split ';').count

            vsenv -unload
            invoke_vsenv -arch x64
            ($env:Path -split ';').count | should -be $first_count
        }
    }

    # ── VCPKG_ROOT Handling ─────────────────────────────────────────
    describe 'VCPKG_ROOT Handling' {

        beforeeach {
            $script:mock_vcpkg_root = join-path $script:temp_dir 'vcpkg'
            ni -itemtype directory $script:mock_vcpkg_root -force | out-null
            $env:VCPKG_ROOT = $script:mock_vcpkg_root
        }

        it 'preserves VCPKG_ROOT value across vsenv load' {
            $before = $env:VCPKG_ROOT
            invoke_vsenv -arch x64
            $env:VCPKG_ROOT | should -be $before
        }

        it 'includes VCPKG_ROOT in PATH after load' {
            invoke_vsenv -arch x64
            $entries = $env:Path -split ';' | %{ $_.trimend('/\') }
            $entries | should -contain $script:mock_vcpkg_root.trimend('/\')
        }

        it 'keeps VCPKG_ROOT in PATH after unload' {
            invoke_vsenv -arch x64
            vsenv -unload
            $entries = $env:Path -split ';' | %{ $_.trimend('/\') }
            $entries | should -contain $script:mock_vcpkg_root.trimend('/\')
        }

        it 'replaces VS-bundled VC\vcpkg with VCPKG_ROOT' {
            invoke_vsenv -arch x64
            $vc_vcpkg = ($env:Path -split ';') | ? { $_ -match '[/\\]VC[/\\]vcpkg$' }
            $vc_vcpkg | should -benullorempty
        }

        context 'VCPKG_ROOT changes between calls' {

            it 'strips old VCPKG_ROOT and adds new one' {
                invoke_vsenv -arch x64
                vsenv -unload

                $new_root = join-path $script:temp_dir 'vcpkg-v143'
                ni -itemtype directory $new_root -force | out-null
                $env:VCPKG_ROOT = $new_root

                invoke_vsenv -arch x64

                $entries = $env:Path -split ';' | %{ $_.trimend('/\') }
                $entries | should -contain $new_root.trimend('/\')
                $entries | should -not -contain $script:mock_vcpkg_root.trimend('/\')
            }

            it 'updates vsenv_vcpkg_in_path tracking variable' {
                invoke_vsenv -arch x64
                get_vsenv_vcpkg_in_path | should -be $script:mock_vcpkg_root.trimend('/\')

                vsenv -unload
                $new_root = join-path $script:temp_dir 'vcpkg-new'
                ni -itemtype directory $new_root -force | out-null
                $env:VCPKG_ROOT = $new_root

                invoke_vsenv -arch x64
                get_vsenv_vcpkg_in_path | should -be $new_root.trimend('/\')
            }

            it 'handles change without intermediate unload' {
                invoke_vsenv -arch x64

                $new_root = join-path $script:temp_dir 'vcpkg-direct'
                ni -itemtype directory $new_root -force | out-null
                $env:VCPKG_ROOT = $new_root

                invoke_vsenv -arch x64

                $entries = $env:Path -split ';' | %{ $_.trimend('/\') }
                $entries | should -contain $new_root.trimend('/\')
                ($entries | ? { $_ -ieq $script:mock_vcpkg_root.trimend('/\') }) | should -benullorempty
            }
        }

        context 'VCPKG_ROOT is unset' {
            it 'does not error when VCPKG_ROOT is null' {
                ri env:VCPKG_ROOT -ea ignore
                { invoke_vsenv -arch x64 } | should -not -throw
            }
        }

        context 'vcpkg LIB/INCLUDE arch rewriting' {
            it 'rewrites vcpkg triplet paths on arch switch' {
                $env:LIB     = "$($script:mock_vcpkg_root)/installed/x64-windows-static/lib"
                $env:INCLUDE = "$($script:mock_vcpkg_root)/installed/x64-windows-static/include"

                invoke_vsenv -arch x64
                invoke_vsenv -arch arm64

                $env:LIB     | should -match 'arm64-windows-static'
                $env:INCLUDE | should -match 'arm64-windows-static'
            }
        }
    }

    # ── PATH Deduplication ──────────────────────────────────────────
    describe 'PATH Deduplication' {

        it 'deduplicates entries differing only by trailing backslash' {
            $d = join-path $script:temp_dir 'dedup-test'
            ni -itemtype directory $d -force | out-null
            $env:Path = "${d}\;${d};$env:Path"

            invoke_vsenv -arch x64

            $matches = ($env:Path -split ';') | ? { $_.trimend('/\') -ieq $d.trimend('/\') }
            $matches.count | should -be 1
        }

        it 'deduplicates case-insensitively' {
            $d = join-path $script:temp_dir 'CaseTest'
            ni -itemtype directory $d -force | out-null
            $env:Path = "$($d.tolower());$($d.toupper());$env:Path"

            invoke_vsenv -arch x64

            $matches = ($env:Path -split ';') | ? { $_.trimend('/\') -ieq $d.trimend('/\') }
            $matches.count | should -be 1
        }

        it 'normalizes double backslashes from vcvarsall output' {
            $response = new_vcvarsall_response -arch x64
            $response = $response | %{
                if ($_ -match '^Path=') { $_ -replace 'Common7\\IDE', 'Common7\\\\IDE' }
                else { $_ }
            }
            set_mock_output -lines $response
            vsenv x64

            ($env:Path -split ';') | ? { $_ -match '\\\\' } | should -benullorempty
        }

        it 'keeps first occurrence for duplicates' {
            $first_baseline = ($env:Path -split ';' | ? { $_ })[0]
            invoke_vsenv -arch x64
            ($env:Path -split ';')[0] | should -be $first_baseline
        }
    }

    # ── List Var Management ─────────────────────────────────────────
    describe 'List Var Management' {

        it 'prepends vcvarsall entries BEFORE user entries for INCLUDE/LIB' {
            $env:INCLUDE = 'C:\Users\custom\include'
            invoke_vsenv -arch x64

            $entries = $env:INCLUDE -split ';'
            $custom_idx = [array]::indexof($entries, 'C:\Users\custom\include')
            $msvc_idx = 0
            for ($i = 0; $i -lt $entries.count; $i++) {
                if ($entries[$i] -match 'MSVC') { $msvc_idx = $i; break }
            }
            $msvc_idx | should -belessthan $custom_idx
        }

        it 'records vcvarsall_additions for non-PATH list vars' {
            invoke_vsenv -arch x64
            $state = get_vsenv_state
            $state.vcvarsall_additions | should -not -benullorempty
            $state.vcvarsall_additions['INCLUDE'] | should -not -benullorempty
            $state.vcvarsall_additions['LIB'] | should -not -benullorempty
        }

        it 'subtracts previous vcvarsall additions on arch switch' {
            invoke_vsenv -arch x64
            $env:INCLUDE += ';C:\Users\custom\include'
            invoke_vsenv -arch arm64

            # user addition survives the arch switch
            $env:INCLUDE | should -match 'custom\\include'
            # LIB has arch-specific paths (lib\arm64 vs lib\x64)
            $env:LIB | should -match 'arm64'
        }
    }

    # ── vs_strip_re Pattern ─────────────────────────────────────────
    describe 'vs_strip_re Pattern' {

        beforeall {
            $script:vs_strip_re = '[/\\]Microsoft Visual Studio[/\\]|[/\\]Microsoft SDKs[/\\]|[/\\]Windows Kits[/\\](?:[^/\\]+[/\\](?:bin|lib|include|UnionMetadata|References)[/\\]|NETFXSDK[/\\])|[/\\]Microsoft\.NET[/\\]|[/\\]HTML Help Workshop'
        }

        it 'strips \Microsoft Visual Studio\ paths' {
            'C:\Program Files\Microsoft Visual Studio\2022\Community\VC' |
                should -match $script:vs_strip_re
        }

        it 'strips \Microsoft SDKs\ paths' {
            'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A' |
                should -match $script:vs_strip_re
        }

        it 'strips Windows Kits SDK bin paths' {
            'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64' |
                should -match $script:vs_strip_re
        }

        it 'does NOT strip Windows Performance Toolkit' {
            'C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit' |
                should -not -match $script:vs_strip_re
        }

        it 'strips NETFXSDK under Windows Kits' {
            'C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8' |
                should -match $script:vs_strip_re
        }

        it 'strips \Microsoft.NET\ paths' {
            'C:\WINDOWS\Microsoft.NET\Framework64\v4.0.30319' |
                should -match $script:vs_strip_re
        }

        it 'strips HTML Help Workshop' {
            'C:\Program Files (x86)\HTML Help Workshop' |
                should -match $script:vs_strip_re
        }

        it 'does NOT match PowerShell paths' {
            'C:\Program Files\PowerShell\7' | should -not -match $script:vs_strip_re
        }

        it 'does NOT match Git paths' {
            'C:\Program Files\Git\cmd' | should -not -match $script:vs_strip_re
        }

        it 'handles forward slash separators' {
            'C:/Program Files/Microsoft Visual Studio/2022/Community' |
                should -match $script:vs_strip_re
        }
    }

    # ── __VSCMD_PREINIT_* Handling ──────────────────────────────────
    describe '__VSCMD_PREINIT_* Handling' {

        it 'discards __VSCMD_PREINIT_* from vcvarsall output' {
            invoke_vsenv -arch x64
            $env:__VSCMD_PREINIT_PATH | should -benullorempty
        }

        it 'removes pre-existing __VSCMD_PREINIT_* vars' {
            $env:__VSCMD_PREINIT_PATH = 'C:\old\path'
            invoke_vsenv -arch x64
            $env:__VSCMD_PREINIT_PATH | should -benullorempty
        }
    }

    # ── VCPKG_ROOT exclusion from state.vars ────────────────────────
    describe 'VCPKG_ROOT state management' {

        it 'does not store VCPKG_ROOT in state.vars' {
            $env:VCPKG_ROOT = join-path $script:temp_dir 'vcpkg'
            ni -itemtype directory $env:VCPKG_ROOT -force | out-null
            invoke_vsenv -arch x64

            $state = get_vsenv_state
            $state.vars.containskey('VCPKG_ROOT') | should -befalse
        }

        it 'preserves VCPKG_ROOT after vcvarsall might overwrite it' {
            $original = join-path $script:temp_dir 'my-vcpkg'
            ni -itemtype directory $original -force | out-null
            $env:VCPKG_ROOT = $original

            $response = new_vcvarsall_response -arch x64
            $response += 'VCPKG_ROOT=C:\Different\vcpkg'
            set_mock_output -lines $response
            vsenv x64

            $env:VCPKG_ROOT | should -be $original
        }
    }

    # ── Error Handling ──────────────────────────────────────────────
    describe 'Error Handling' {
        it 'throws when vcvarsall exits nonzero' {
            set_mock_output -lines @() -exit_code 1
            { vsenv x64 } | should -throw '*vcvarsall*'
        }
    }

    # ── Verbose Output ──────────────────────────────────────────────
    describe 'Verbose Output' {

        it 'emits the vcvarsall command line via write-verbose' {
            set_mock_output -lines (new_vcvarsall_response -arch x64)
            $verbose = & (get-module MyProfile) {
                $VerbosePreference = 'Continue'; vsenv x64
            } 4>&1
            $verbose | ? { $_ -match '^vsenv:' } | should -not -benullorempty
        }

        it 'emits vcvarsall banner lines as verbose' {
            set_mock_output -lines (new_vcvarsall_response -arch x64)
            $verbose = & (get-module MyProfile) {
                $VerbosePreference = 'Continue'; vsenv x64
            } 4>&1
            $verbose | ? { $_ -match 'vcvarsall:' } | should -not -benullorempty
        }
    }

    # ── Toolkit Selection ───────────────────────────────────────────
    describe 'Toolkit Selection' {

        beforeall {
            $script:mock_msvc_base = join-path $script:temp_dir 'MockVS\VC\Tools\MSVC'
            ni -itemtype directory $script:mock_msvc_base -force | out-null
            '14.30.30705','14.40.33807','14.42.34433','14.50.35717' | %{
                ni -itemtype directory (join-path $script:mock_msvc_base $_) -force | out-null
            }

            $script:mock_vcvarsall_dir = join-path $script:temp_dir 'MockVS\VC\Auxiliary\Build'
            ni -itemtype directory $script:mock_vcvarsall_dir -force | out-null
            copy-item $script:mock_vcvarsall (join-path $script:mock_vcvarsall_dir 'vcvarsall.bat')

            & (get-module MyProfile) {
                $script:vcvarsall = resolve-path $args[0]
            } (join-path $script:mock_vcvarsall_dir 'vcvarsall.bat')
        }

        afterall {
            & (get-module MyProfile) {
                $script:vcvarsall = resolve-path $args[0]
            } $script:mock_vcvarsall
        }

        it 'selects latest version in range for v143 (14.3x-14.4x)' {
            $response = new_vcvarsall_response -arch x64 -tools_version '14.42.34433'
            $response += 'VCToolsVersion=14.42.34433'
            set_mock_output -lines $response

            vsenv x64 v143

            get_mock_args | should -match '14\.42\.34433'
        }

        it 'selects 14.50 for v145' {
            $response = new_vcvarsall_response -arch x64 -tools_version '14.50.35717'
            $response += 'VCToolsVersion=14.50.35717'
            set_mock_output -lines $response

            vsenv x64 v145

            get_mock_args | should -match '14\.50\.35717'
        }

        it 'passes exact version string without scanning' {
            $response = new_vcvarsall_response -arch x64 -tools_version '14.30.30705'
            $response += 'VCToolsVersion=14.30.30705'
            set_mock_output -lines $response

            vsenv x64 '14.30.30705'

            get_mock_args | should -match '14\.30\.30705'
        }

        it 'emits warning when toolkit produces no VCToolsVersion' {
            $response = @(
                '[vcvarsall.bat] Environment initialized'
                'Path=%Path%'
                'INCLUDE=C:\dummy\include'
                'LIB=C:\dummy\lib'
                'LIBPATH=C:\dummy\libpath'
                'EXTERNAL_INCLUDE=C:\dummy\include'
            )
            set_mock_output -lines $response

            # clear VCToolsVersion so the warning triggers
            ri env:VCToolsVersion -ea ignore

            $output = vsenv x64 v143 3>&1
            $warnings = @($output | ?{ $_ -is [System.Management.Automation.WarningRecord] })

            $warnings | should -not -benullorempty
        }
    }

    # ── Full Lifecycle Integration ──────────────────────────────────
    describe 'Full Lifecycle Integration' {

        it 'load -> switch arch -> unload -> reload: clean state' {
            $env:VCPKG_ROOT = join-path $script:temp_dir 'vcpkg-lifecycle'
            ni -itemtype directory $env:VCPKG_ROOT -force | out-null

            invoke_vsenv -arch x64
            invoke_vsenv -arch arm64
            $env:Path | should -match 'arm64'

            vsenv -unload
            $env:Path | should -not -match '\\Microsoft Visual Studio\\'
            ($env:Path -split ';' | %{ $_.trimend('/\') }) |
                should -contain $env:VCPKG_ROOT.trimend('/\')

            invoke_vsenv -arch x64
            $env:Path | should -match 'HostX64\\x64'
            $env:Path | should -not -match 'arm64'
        }

        it 'load -> change VCPKG_ROOT -> reload: only new vcpkg' {
            $root1 = join-path $script:temp_dir 'vcpkg-lc1'
            $root2 = join-path $script:temp_dir 'vcpkg-lc2'
            ni -itemtype directory $root1,$root2 -force | out-null

            $env:VCPKG_ROOT = $root1
            invoke_vsenv -arch x64

            $env:VCPKG_ROOT = $root2
            invoke_vsenv -arch x64

            $entries = $env:Path -split ';' | %{ $_.trimend('/\') }
            $entries | should -contain $root2.trimend('/\')
            ($entries | ? { $_ -ieq $root1.trimend('/\') }) | should -benullorempty
        }

        it 'load -> unload -> change VCPKG_ROOT -> reload: only new vcpkg' {
            $root1 = join-path $script:temp_dir 'vcpkg-lcu1'
            $root2 = join-path $script:temp_dir 'vcpkg-lcu2'
            ni -itemtype directory $root1,$root2 -force | out-null

            $env:VCPKG_ROOT = $root1
            invoke_vsenv -arch x64
            vsenv -unload

            $env:VCPKG_ROOT = $root2
            invoke_vsenv -arch x64

            $entries = $env:Path -split ';' | %{ $_.trimend('/\') }
            $entries | should -contain $root2.trimend('/\')
            ($entries | ? { $_ -ieq $root1.trimend('/\') }) | should -benullorempty
        }

        it 'three arch switches then unload restores clean baseline' {
            invoke_vsenv -arch x64
            invoke_vsenv -arch arm64
            invoke_vsenv -arch x86
            vsenv -unload

            $env:Path | should -not -match '\\Microsoft Visual Studio\\'
            $env:Path | should -not -match '\\Microsoft SDKs\\'
            $env:Path | should -not -match '\\Microsoft\.NET\\'
        }
    }
}

# vim:set sw=4 et: