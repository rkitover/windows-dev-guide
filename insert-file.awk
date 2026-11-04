BEGIN { begin_include=0; in_include=0 }
# Strip carriage returns, so that both files may have CRLF line endings.
{ sub(/\r$/, "") }
$0 ~ "^\\[\\/\\/\\]: # \"BEGIN INCLUDED " include_file "\"$" {
    begin_include=1
}
begin_include && /^```[[:alnum:]]+$/{
    in_include=1
}
in_include && /^```$/{
    begin_include=0
    in_include=0
}
{
    if (in_include == 2) {
        while (getline line < include_file) {
            sub(/\r$/, "", line)
            print line
        }
    }
    else if (in_include < 2) {
        print
    }

    if (in_include) { in_include++ }
}
