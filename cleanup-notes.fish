#! /usr/bin/env fish

set obsidian_main (ot_config_grab "ObsidianMainFolder")
set notes_folder $obsidian_main/(ot_config_grab "NotesFolder")
set resources_folder $obsidian_main/(ot_config_grab "ObsidianResourceFolder")

if test -e $obsidian_main/restrash
else
    mkdir $obsidian_main/restrash
end

for i in $(find $resources_folder/* -type f)
    set filename (basename $i)
    if grep -r "\[\[$filename.*\]\]" $notes_folder/; or grep -rF "[[$filename]]" $notes_folder/
    else
        mv $i $obsidian_main/restrash
    end
end

for i in $(find $obsidian_main/restrash/* -type f)
    set filename (basename $i)
    if find $obsidian_main -iname "*.canvas" -exec grep "/$filename" {} +
        mv $i $resources_folder
    end
end
