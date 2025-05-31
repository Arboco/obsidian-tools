#! /usr/bin/env fish

set obsidian_main (ot_config_grab "ObsidianMainFolder")
set notes_folder $obsidian_main/(ot_config_grab "NotesFolder")
set resources_folder $obsidian_main/(ot_config_grab "ObsidianResourceFolder")

mkdir -p $obsidian_main/restrash

for i in $(find $resources_folder/* -type f)
    set filename (basename $i)
    if rg -F "$filename" $obsidian_main
    else
        mv $i $obsidian_main/restrash
    end
end
