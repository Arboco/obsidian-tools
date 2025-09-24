#! /usr/bin/env fish

set pdf_md $argv[1]
set obsidian (ot_config_grab "ObsidianMainFolder")
set folder_title (basename -s ".md" $pdf_md | sed 's/ /-/g')
set resource_folder (ot_config_grab "ObsidianResourceFolder")

set screenshot_folder "$obsidian/$resource_folder/book_db/pdf/$folder_title"
set device_name (ot_config_grab "MangaDeviceName")
set screenshot_button (ot_config_grab "MangaScreenshot")

mkdir -p $screenshot_folder

yes | evtest >/dev/null 2>/tmp/evtest-info.txt
set devinput (cat /tmp/evtest-info.txt | grep -P "$device_name" | head -n 1 | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line

    if string match -q "*$screenshot_button), value 1" "$line"
        set timestamp (date +%F_%H%M%S)
        scrot -s $screenshot_folder/$folder_title-$timestamp.jpg
        echo -e "![[$folder_title-$timestamp.jpg]]\n" >>$pdf_md
    end
end
