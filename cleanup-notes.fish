#! /usr/bin/env fish

set obsidian_main (ot_config_grab "ObsidianMainFolder")
set notes_folder $obsidian_main/(ot_config_grab "NotesFolder")
set resources_folder $obsidian_main/(ot_config_grab "ObsidianResourceFolder")

mkdir -p $obsidian_main/restrash

for i in $(find $resources_folder/* -type f)
    set filename (basename $i)
    if rg -F "[[$filename" $notes_folder/
    else
        mv $i $obsidian_main/restrash
    end
end

for i in $(find $obsidian_main/restrash/* -type f)
    set filename (basename $i)
    if rg "/$filename" $obsidian_main/*
        echo "Moving back canvas media."
        mv $i $resources_folder
    end
end
