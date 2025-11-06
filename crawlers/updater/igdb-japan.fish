#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_igdb (rg -l "https://www.igdb.com" $obsidian/$note/*)
#set list_igdb (rg -l "igdb" $PWD/*.md)
for file in $list_igdb

    set html /tmp/igdb.html
    set url (rg "https://www.igdb.com.*" $file)
    set url (string split " " $url)[2]
    node fetch-page.js "$url" >/tmp/igdb.html

    function string_sanitizer
        string replace -a '&amp;' '&' -- "$argv[1]"
    end

    if rg -oP '(?<=<strong>Japan:</strong> )[^<]*' $html
        if rg j_title $file
        else
            set jap_title (rg -oP '(?<=<strong>Japan:</strong> )[^<]*' $html)
            sed -i "/^title:/a\\j_title: $jap_title" $file
        end
    end
end
