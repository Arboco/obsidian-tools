#! /usr/bin/env fish

set obsidian_main (ot_config_grab "ObsidianMainFolder")
set notes_folder (ot_config_grab "NotesFolder")
set sort_yaml $HOME/.config/ortscripts/sort.yaml
set search_array (grep -oP '^.*?(?=:)' $sort_yaml)

for i in (find $obsidian_main $obsidian_main/$notes_folder -maxdepth 1 -type f)
    for inner in $search_array
        if grep -wq "  - $inner" $i; or grep "tags: .*$inner" $i
            set raw_grep (grep "  - $inner" $i; or  grep -oP "(?<=tags: )$inner" $i >/dev/null 2>&1)
            set refined_grep (echo $raw_grep | grep -o "[a-zA-Z]*")
            set target_folder (grep -oP "(?<=$refined_grep:).*" $sort_yaml)
            set target_folder (string trim "$target_folder")
            mkdir -p "$obsidian_main/$notes_folder/$target_folder"
            mv $i "$obsidian_main/$notes_folder/$target_folder"
            set filename (basename $i)
            echo -e (set_color red)"Moved"(set_color normal) $filename (set_color red)"to"(set_color normal) $obsidian_main/$notes_folder/$target_folder
            break
        end
    end
end
