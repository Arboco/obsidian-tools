#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_vndb (rg -l "https://vndb.org" $obsidian/$note/*)
set list_vndb (rg -l "  - vn" $list_vndb)
#set list_vndb (rg -l "igdb" $PWD/*.md)
for file in $list_vndb
    echo $file

    if rg "  - plotge" $file
        sed -i '/  - plotge/d' $file
        sed -i "/^genres:/a\\  - \"\[\[plotge\]\]\"" $file
    else
    end
end
