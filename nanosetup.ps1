$erroractionpreference = 'stop'

$releases = 'https://files.lhmouse.com/nano-win/'

ri -r -fo ~/Downloads/nano-installer -ea ignore
mkdir ~/Downloads/nano-installer | out-null
pushd ~/Downloads/nano-installer
curl -sLO ($releases + (
    iwr -usebasicparsing $releases | % links |
    ? href -match '\.7z$' | select -last 1 | % href
))
7z x nano*.7z | out-null
mkdir ~/.local/bin -ea ignore | out-null
cpi -fo pkg_x86_64*/bin/nano.exe ~/.local/bin
mkdir ~/.nano -ea ignore | out-null
git clone https://github.com/scopatz/nanorc *> $null
gci -r nanorc -i *.nanorc | cpi -dest ~/.nano
popd
("include `"" + (($env:USERPROFILE -replace '\\','/') `
    -replace '^[^/]+','').tolower() + `
    "/.nano/*.nanorc`"") >> ~/.nanorc

gi ~/.nanorc,~/.nano,~/.local/bin/nano.exe
