#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set episode_md "$argv[2]"
set title "$argv[3]"
set obsidian (ot_config_grab "ObsidianMainFolder")
set resources_folder (ot_config_grab "ObsidianResourceFolder")
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set anime_folder (ot_config_grab "AnimeFolder")
set screenshot_folder "$obsidian/$resources_folder/$anime_folder/media/clips/$folder_title"
set a_path (rg -oP '(?<=animepath: ).*$' $obsidian_md)

mkdir -p $screenshot_folder

inotifywait -m -e create --format '%w%f' "$a_path" | while read FILE
    sleep 3
    set codec (ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 $FILE)
    set file_end (echo "$(basename $FILE)" | grep -o '...$')
    set timestamp (date +%s)

    # x265 hevc codec doesn't work on my obsidian so I convert it into a friendlier codec 
    #if test $codec = 'hevc' 
    #echo "hevc codec detected, conversion started."
    ffmpeg -i $FILE -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 320k $screenshot_folder/$folder_title$timestamp.mp4
    echo -e "![[$folder_title$timestamp.mp4]]\n" >>$episode_md
    rm $FILE

    #echo "File is compatible, going to move it as is."
    #mv $FILE "$screenshot_folder/$folder_title$timestamp.$file_end"
    #echo -e "![[$folder_title$timestamp.$file_end]]\n" >> $obsidian_md
end
