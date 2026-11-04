$erroractionpreference = 'stop'

$taskname = 'Forward Server Ports'

$trigger = new-scheduledtasktrigger -atlogon

# Ask for the application, the $profile may map an alias or function for ssh,
# whose source is not the path a task action needs.
$ssh = get-command -commandtype application ssh -totalcount 1

$action  = new-scheduledtaskaction `
    -execute $ssh.source `
    -argument '-NT server-ports'

$password = (get-credential $env:username).getnetworkcredential().password

register-scheduledtask -force `
    -taskname $taskname `
    -trigger $trigger -action $action `
    -user $env:username `
    -password $password `
    -ea stop | out-null

"Task '$taskname' successfully registered to run at logon."
