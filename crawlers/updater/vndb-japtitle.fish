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

    set retry_counter 0
    while test -z $jap_title
        curl -s -A Mozilla/5.0 "(X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0" "$url" >$html
        set jap_title (rg -o --multiline --multiline-dotall '<tr class="title"><td>.*?</span>' $html | rg -oP '(?<=<span lang="ja">)[^<]*')
        echo $file
        if test -z $jap_title
            sleep 2
            set retry_counter (math $retry_counter + 1)
        end
        if test $retry_counter -gt 3
            break
        end
    end

    if test -z $jap_title
    else
        sed -i "/^title:/a\\j_title: \"$jap_title\"" $file
    end
    rm $html
    set -e jap_title
end
