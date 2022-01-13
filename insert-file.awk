BEGIN { begin_include=0; in_include=0 }
$0 ~ "^\\[\\/\\/\\]: # \"BEGIN INCLUDED " include_file "\"$" {
    begin_include=1
}
begin_include && /^```powershell$/{
    in_include=1
}
in_include && /^```$/{
    begin_include=0
    in_include=0
}
{
    if (in_include == 2) {
        while (getline line < include_file) {
            print line
        }
    }
    else if (in_include < 2) {
        print
    }

    if (in_include) { in_include++ }
}
