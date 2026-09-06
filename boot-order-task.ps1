$taskname = 'Restore Boot Order'

# At startup rather than at logon, so that a boot order reset by a firmware
# update or an upgrade is put back before you next reboot, whether or not you
# sign in.
$trigger = new-scheduledtasktrigger -atstartup

if (-not (test-path /logs)) { mkdir /logs }

# Windows PowerShell rather than pwsh, because it is always present at a fixed
# path that is on the machine PATH, which a task running as SYSTEM can resolve.
# pwsh is installed per user, under a versioned WindowsApps path that SYSTEM
# cannot find by name and that changes whenever PowerShell updates.

$action  = new-scheduledtaskaction `
    -execute 'powershell' `
    -argument ("-noprofile -executionpolicy remotesigned " + `
	"-command ""& '$(join-path $psscriptroot restore-boot-order.ps1)'""" + `
	" *>> /logs/restore-boot-order.log")

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
