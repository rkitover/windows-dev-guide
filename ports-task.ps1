$erroractionpreference = 'stop'

$taskname = 'Forward Server Ports'

$trigger = new-scheduledtasktrigger -atlogon

$action  = new-scheduledtaskaction `
    -execute (get-command powershell).source `
    -argument '-noprofile -executionpolicy remotesigned -command "while ($true) { ssh -NT server-ports }"'

$password = (get-credential $env:username).getnetworkcredential().password

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -user $env:username `
    -password $password `
    -ea stop | out-null

"Task '$taskname' successfully registered to run at logon."
