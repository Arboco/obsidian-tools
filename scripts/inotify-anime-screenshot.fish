#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set title "$argv[2]"
set obsidian (ot_config_grab "ObsidianMainFolder")
set resources_folder (ot_config_grab "ObsidianResourceFolder")
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set anime_folder (ot_config_grab "AnimeFolder")
set last_recorded_file /tmp/ot_last_recorded_file
if string match film $argv[3]
    set screenshot_folder "$obsidian/$resources_folder/film/media/screenshots/$folder_title"
else if string match tv $argv[3]
    set screenshot_folder "$obsidian/$resources_folder/tvseries/media/screenshots/$folder_title"
else
    set screenshot_folder "$obsidian/$resources_folder/$anime_folder/media/screenshots/$folder_title"
end

mkdir -p $screenshot_folder

inotifywait -m -e create --format '%w%f' $screenshot_folder | while read FILE
    set timestamp (date +%F_%H%M%S)
    mv $FILE $screenshot_folder/$folder_title$timestamp.jpg
    if string match film $argv[3]
    else
        if rg "cover-img.*thumb" $obsidian_md
            sed -i /cover-img:/d $obsidian_md
            sed -i "/^episode:/a\\cover-img: \"!\[\[$folder_title$timestamp.jpg\]\]\"" $obsidian_md
        end
        if rg "cover-img:" $obsidian_md
        else
            sed -i "/^episode:/a\\cover-img: \"!\[\[$folder_title$timestamp.jpg\]\]\"" $obsidian_md
        end
    end

    echo -e "![[$folder_title$timestamp.jpg]]\n" >>$obsidian_md
    echo "" >>$obsidian_md
    echo "![[$folder_title$timestamp.jpg]]" >$last_recorded_file
end
