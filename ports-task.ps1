$erroractionpreference = 'stop'

$taskname = 'Forward Server Ports'

$trigger = new-scheduledtasktrigger -atlogon

$action  = new-scheduledtaskaction `
    -execute 'ssh' `
    -argument '-NT server-ports'

$settings = new-scheduledtasksettingsset -restartcount:1000 -restartinterval (new-timespan -minutes 1)

$password = (get-credential $env:username).getnetworkcredential().password

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -settings $settings `
    -user $env:username `
    -password $password `
    -ea stop | out-null

"Task '$taskname' successfully registered to run at logon."
