#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set title "$argv[2]"
set a_path (cat $obsidian_md | grep 'path:')
set a_path (echo $a_path | grep -oP '(?<=path: ).*$')
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set resource_folder (ot_config_grab "ObsidianResourceFolder")
set screenshot_folder $obsidian_folder/$resource_folder/(ot_config_grab "MindPalaceFolder")/$folder_title-clips

if test -d $screenshot_folder
    echo "folder exists"
else
    mkdir $screenshot_folder
end

inotifywait -m -e create --format '%w%f' $screenshot_folder | while read FILE
    set timestamp (date +%s)
    mv $FILE $screenshot_folder/$folder_title$timestamp.jpg
    echo -e "![[$folder_title$timestamp.jpg]]\n" >>$obsidian_md
end
