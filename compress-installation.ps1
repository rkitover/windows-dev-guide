$erroractionpreference = 'stop'

# Compress the parts of the installation that are read constantly and written
# rarely, using the Windows Overlay Filter. Reads decompress transparently and
# writing a file drops it back out of compression, so nothing here slows down
# the files you actually change.
#
# Re-running only compresses what has been added since the last run, which is
# what makes this safe to schedule.

# C:\Windows is deliberately absent. Servicing owns those files and CompactOS
# below is the supported way to compress them.
$targets = @(
    $env:programfiles
    ${env:programfiles(x86)}
    $env:programdata
    '/msys64'
)

function get-freebytes {
    (get-ciminstance win32_logicaldisk `
        -filter "deviceid = '$env:systemdrive'").freespace
}

$before = get-freebytes

# Windows opts out of this on devices with a fast disk and plenty of free
# space, and asking for it explicitly overrides that. Once it is on there is
# nothing left to do, and the conversion takes long enough to be worth
# skipping.
if ((compact.exe /compactos:query) -match 'is in the Compact state') {
    "Windows itself is already compacted."
}
else {
    "Compacting Windows itself ..."
    compact.exe /compactos:always
}

foreach ($target in $targets) {
    if (-not (test-path -literalpath $target)) {
        "Skipping $target, it is not installed."
        continue
    }

    "Compressing $target ..."

    # LZX is the strongest algorithm compact.exe offers. Without /f it skips
    # files that are already compressed, so a second run is cheap.
    compact.exe /c /a /i /q /exe:lzx "/s:$target" |
        select-string -pattern 'are stored in|compression ratio' |
        foreach-object { "  $($_.line.trim())" }
}

$after = get-freebytes

"Free space went from {0:N2} GB to {1:N2} GB, a saving of {2:N2} GB." -f `
    ($before / 1gb), ($after / 1gb), (($after - $before) / 1gb)
