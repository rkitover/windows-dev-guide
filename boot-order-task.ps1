$taskname = 'Restore Boot Order'

# At startup rather than at logon, so that the next boot is pointed back at
# GRUB before you reboot again, whether or not you sign in.
$trigger = new-scheduledtasktrigger -atstartup

if (-not (test-path /logs)) { mkdir /logs }

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
	"-command ""& '$(join-path $psscriptroot restore-boot-order.ps1)' " + `
	"*>&1 | out-file -append -encoding utf8 /logs/restore-boot-order.log""")

# bcdedit needs elevation, so this runs as SYSTEM rather than as you.
$principal = new-scheduledtaskprincipal `
    -userid 'SYSTEM' `
    -logontype serviceaccount `
    -runlevel highest

$settings = new-scheduledtasksettingsset `
    -startwhenavailable `
    -executiontimelimit (new-timespan -minutes 5)

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -principal $principal `
    -settings $settings `
    -ea stop | out-null

"Task '$taskname' successfully registered to run at startup."
