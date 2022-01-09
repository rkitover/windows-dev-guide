BEGIN { begin_profile=0; in_profile=0 }
/^\[\/\/\]: # "BEGIN INCLUDED PROFILE\.PS1"$/{
    begin_profile=1
}
begin_profile && /^```powershell$/{
    in_profile=1
}
in_profile && /^```$/{
    begin_profile=0
    in_profile=0
}
{
    if (in_profile >= 2) {
        if (in_profile == 2) {
            while (getline line < "./profile.ps1") {
                print line
            }
        }
    }
    else {
        print
    }

    if (in_profile) { in_profile++ }
}
