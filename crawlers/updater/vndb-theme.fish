#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_vndb (rg -l "https://vndb.org" $obsidian/$note/*)
set list_vndb (rg -l "  - vn" $list_vndb)
#set list_vndb (rg -l "igdb" $PWD/*.md)
for file in $list_vndb
    echo $file

    if rg "themes:" $file
        if rg "genres:" $file
        else
            sed -i "/^themes:/a\\genres:" $file
        end
    else
        sed -i "/^status:/a\\themes:" $file
        if rg "genres:" $file
        else
            sed -i "/^themes:/a\\genres:" $file
        end
    end
end
