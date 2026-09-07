$taskname = 'Restore Compression'
$runat    = '03:00'

# Nightly. Compression decays because Windows Update, application installers
# and pacman all write their new files uncompressed, and a pass that finds
# nothing new to do costs very little, so there is no reason to wait.
$trigger = new-scheduledtasktrigger -at $runat -daily

if (-not (test-path /logs)) { mkdir /logs *> $null }

# Windows PowerShell rather than pwsh, because it is always present at a fixed
# path that is on the machine PATH, which a task running as SYSTEM can resolve.
# pwsh is installed per user, under a versioned WindowsApps path that SYSTEM
# cannot find by name and that changes whenever PowerShell updates.
#
# It also writes *>> redirection as UTF-16, which MSYS2 tools will not read, so
# the streams are merged and piped through out-file with an explicit encoding
# instead. That gives UTF-8 with a BOM, as 5.1 has no utf8NoBOM.

$action  = new-scheduledtaskaction `
    -execute 'powershell' `
    -argument ("-noprofile -executionpolicy remotesigned " + `
	"-command ""& '$(join-path $psscriptroot compress-installation.ps1)' " + `
	"*>&1 | out-file -append -encoding utf8 /logs/compress-installation.log""")

# Compressing Program Files needs elevation, so unlike the other tasks here
# this one runs as SYSTEM rather than as you.
$principal = new-scheduledtaskprincipal `
    -userid 'SYSTEM' `
    -logontype serviceaccount `
    -runlevel highest

# The defaults already keep a task from starting on battery, which is what you
# want for something that will use every core for a while.
$settings = new-scheduledtasksettingsset `
    -startwhenavailable `
    -executiontimelimit (new-timespan -hours 4)

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -principal $principal `
    -settings $settings `
    -ea stop | out-null

"Task '$taskname' successfully registered to run nightly at $runat."
