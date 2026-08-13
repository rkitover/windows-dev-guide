$erroractionpreference = 'stop'

$taskname = 'Forward Server Ports'

$trigger = new-scheduledtasktrigger -atlogon

# If the $profile maps an alias for ssh, get-command returns that alias, whose
# source is the module it came from and not the path a task action needs.
$ssh = get-command ssh
while ($ssh.commandtype -eq 'Alias') { $ssh = $ssh.resolvedcommand }

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
