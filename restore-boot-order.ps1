$erroractionpreference = 'stop'

# Windows Boot Manager puts itself back at the front of the firmware boot order
# on every boot, so setting the order alone never survives to the next one and
# the machine boots straight past GRUB into Windows. Firmware updates and in
# place upgrades do the same thing, they are just not the common case.
#
# BootNext is a one shot override that the firmware consumes and clears, and it
# takes precedence over the boot order, so setting it on every boot is what
# actually guarantees the next one reaches GRUB. The order is put back as well,
# so that a boot which does not run this first, e.g. straight after a firmware
# update, still has a chance of landing in the right place.
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

# bcdedit calls BootNext the bootsequence of {fwbootmgr}. This is the part that
# matters, so it is done unconditionally.
"Setting the next boot to $wanted ..."

bcdedit /set '{fwbootmgr}' bootsequence $target

if ($order[0] -eq $target) {
    "$wanted is already first in the firmware boot order."
}
else {
    "Moving $wanted to the front of the firmware boot order ..."
    bcdedit /set '{fwbootmgr}' displayorder $target /addfirst
}
