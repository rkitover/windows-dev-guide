$erroractionpreference = 'stop'

# Anything that writes UEFI NVRAM tends to put Windows Boot Manager back at the
# front of the firmware boot order, and the machine then boots straight past
# GRUB. Firmware updates delivered through Windows Update do it, and so do in
# place upgrades and their failed attempts. The Fedora entry itself survives,
# only its position is lost.
#
# The entry is looked up by description rather than by its identifier, because
# an entry that has been recreated rather than reordered has a new one.

$wanted = 'Fedora'

$lines = bcdedit /enum firmware

# Map each entry identifier to its description.
$descriptions = @{}
$identifier   = $null

foreach ($line in $lines) {
    if ($line -match '^identifier\s+(\{[^}]+\})') {
        $identifier = $matches[1]
    }
    elseif ($identifier -and $line -match '^description\s+(.+?)\s*$') {
        $descriptions[$identifier] = $matches[1]
        $identifier = $null
    }
}

# The first displayorder in the output is the one belonging to {fwbootmgr},
# which is the firmware boot order. {bootmgr} has one of its own further down.
$order   = @()
$inorder = $false

foreach ($line in $lines) {
    if (-not $inorder -and $line -match '^displayorder\s+(\{[^}]+\})') {
        $inorder = $true
        $order  += $matches[1]
    }
    elseif ($inorder) {
        if ($line -match '^\s+(\{[^}]+\})\s*$') { $order += $matches[1] }
        else { break }
    }
}

$target = $descriptions.keys |
    where-object { $descriptions[$_] -eq $wanted } |
    select-object -first 1

if (-not $target) {
    "No firmware boot entry called $wanted, leaving the boot order alone."
    return
}

if ($order[0] -eq $target) {
    "$wanted is already first in the firmware boot order."
    return
}

"Moving $wanted to the front of the firmware boot order ..."

bcdedit /set '{fwbootmgr}' displayorder $target /addfirst
