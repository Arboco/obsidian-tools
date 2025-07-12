#! /usr/bin/env fish

if string match film $argv[1]
    set obsidian_md "$argv[2]"
    set episode_md $obsidian_md
    set title "$argv[3]"
else
    set obsidian_md "$argv[1]"
    set episode_md "$argv[2]"
    set title "$argv[3]"
end
set obsidian (ot_config_grab "ObsidianMainFolder")
set resources_folder (ot_config_grab "ObsidianResourceFolder")
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set anime_folder (ot_config_grab "AnimeFolder")
set last_recorded_file /tmp/ot_last_recorded_file

if string match film $argv[1]
    set screenshot_folder "$obsidian/$resources_folder/film/media/clips/$folder_title"
    set a_path (rg -oP '(?<=filmpath: ).*$' $obsidian_md | rg -o '/.*\/')
else if string match tv $argv[4]
    set screenshot_folder "$obsidian/$resources_folder/tvseries/media/clips/$folder_title"
    set a_path (rg -oP '(?<=seriespath: ).*$' $obsidian_md)
else
    set screenshot_folder "$obsidian/$resources_folder/$anime_folder/media/clips/$folder_title"
    set a_path (rg -oP '(?<=animepath: ).*$' $obsidian_md)
end

mkdir -p $screenshot_folder

inotifywait -m -e create --format '%w%f' "$a_path" | while read FILE
    sleep 3
    set codec (ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 $FILE)
    set file_end (echo "$(basename $FILE)" | grep -o '...$')
    set timestamp (date +%F_%H%M%S)

    # x265 hevc codec doesn't work on my obsidian so I convert it into a friendlier codec 
    #if test $codec = 'hevc' 
    #echo "hevc codec detected, conversion started."
    set lang (echo '{ "command": ["get_property", "track-list"] }' | socat - /tmp/mpvsocket | jq '.data[] | select(.type == "audio" and .selected == true)' | jq '.["id"]')
    ffmpeg -i $FILE -c:v libx264 -crf 25 -preset slow -c:a aac -b:a 320k -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -map 0:v -map 0:$lang[1] $screenshot_folder/$folder_title$timestamp.mp4
    echo -e "![[$folder_title$timestamp.mp4]]\n" >>$episode_md
    echo "" >>$episode_md
    echo "![[$folder_title$timestamp.mp4]]" >$last_recorded_file

    rm $FILE

    #echo "File is compatible, going to move it as is."
    #mv $FILE "$screenshot_folder/$folder_title$timestamp.$file_end"
    #echo -e "![[$folder_title$timestamp.$file_end]]\n" >> $obsidian_md
end
