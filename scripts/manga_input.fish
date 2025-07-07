#! /usr/bin/env fish

set manga_md $argv[1]
set volume_md $argv[2]
set obsidian (ot_config_grab "ObsidianMainFolder")
set folder_title (basename -s ".md" $manga_md | sed 's/ /-/g')
set resource_folder (ot_config_grab "ObsidianResourceFolder")

set mangapath (cat $manga_md | grep 'volumepath:' | grep -oP '(?<=volumepath: ).*$')
set volume_info (basename -s ".html" "$mangapath")
set volume_number (echo $volume_info | grep -oP "[0-9]+" | sed 's/^0*//')

set screenshot_folder "$obsidian/$resource_folder/manga/mangareader/$folder_title/$volume_number"
set device_name (ot_config_grab "MangaDeviceName")
set screenshot_button (ot_config_grab "MangaScreenshot")

mkdir -p $screenshot_folder

yes | evtest >/dev/null 2>/tmp/evtest-info.txt
set devinput (cat /tmp/evtest-info.txt | grep -P "$device_name" | head -n 1 | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line

    if string match -q "*$screenshot_button), value 1" "$line"
        set timestamp (date +%F_%H%M%S)
        if rg "cover-img:" $volume_md
        else
            sed -i "/^origin:/a\\cover-img: \"!\[\[$folder_title-$timestamp.jpg\]\]\"" $volume_md
        end
        scrot -s $screenshot_folder/$folder_title-$timestamp.jpg
        echo -e "![[$folder_title-$timestamp.jpg]]\n" >>$volume_md
    end
end
