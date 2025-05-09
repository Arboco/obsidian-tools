#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set title "$argv[2]"
set a_path (cat $obsidian_md | grep 'path:')
set a_path (echo $a_path | grep -oP '(?<=path: ).*$')
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set screenshot_folder (ot_config_grab "AnimeFolder")/media/screenshots/$folder_title

mkdir -p $screenshot_folder

inotifywait -m -e create --format '%w%f' $screenshot_folder | while read FILE
    set timestamp (date +%s)
    mv $FILE $screenshot_folder/$folder_title$timestamp.jpg
    echo -e "![[$folder_title$timestamp.jpg]]\n" >>$obsidian_md
end
