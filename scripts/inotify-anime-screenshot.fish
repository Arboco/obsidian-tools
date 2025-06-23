#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set title "$argv[2]"
set obsidian (ot_config_grab "ObsidianMainFolder")
set resources_folder (ot_config_grab "ObsidianResourceFolder")
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set anime_folder (ot_config_grab "AnimeFolder")
set screenshot_folder "$obsidian/$resources_folder/$anime_folder/media/screenshots/$folder_title"

mkdir -p $screenshot_folder

set debug_file /tmp/anime-starter-debug
echo "screenshot file" >>$debug_file
echo "obsidian file: $obsidian_md" >>$debug_file
echo "screenshot_folder: $screenshot_folder" >>$debug_file

inotifywait -m -e create --format '%w%f' $screenshot_folder | while read FILE
    set timestamp (date +%s)
    mv $FILE $screenshot_folder/$folder_title$timestamp.jpg
    if rg "cover-img.*thumb" $obsidian_md
        sed -i /cover-img:/d $obsidian_md
        sed -i "/^episode:/a\\cover-img: \"!\[\[$folder_title$timestamp.jpg\]\]\"" $obsidian_md
    end

    if rg "cover-img:" $obsidian_md
    else
        sed -i "/^episode:/a\\cover-img: \"!\[\[$folder_title$timestamp.jpg\]\]\"" $obsidian_md
    end

    echo -e "![[$folder_title$timestamp.jpg]]\n" >>$obsidian_md
    echo "" >>$obsidian_md
end
