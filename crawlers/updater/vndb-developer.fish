#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_vndb (rg -l "https://vndb.org" $obsidian/$note/*)
set list_vndb (rg -l "  - vn" $list_vndb)
#set list_vndb (rg -l "igdb" $PWD/*.md)
for file in $list_vndb
    echo $file
    set html /tmp/vndb.html
    set url (rg "https://vndb.org.*" $file)
    set url (string split " " $url)[2]

    while test -z $developer
        curl -s -A Mozilla/5.0 "(X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0" "$url" >$html
        set developer (rg -o --multiline --multiline-dotall '<td>Developer</td>.*?</td>' $html | rg -oP '(?<=title=")[^"]*')
        echo $file
        if test -z $developer
            sleep 2
        end
    end

    if rg "developer:" $file
        sed -i '/developer:/d' $file
        sed -i "/^title:/a\\developer:" $file
        for i in $developer
            sed -i "/^developer:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end
    rm $html
    set -e developer
end
