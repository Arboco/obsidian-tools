#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set title "$argv[2]"
set a_path (cat $obsidian_md | grep 'path:')
set a_path (echo $a_path | grep -oP '(?<=path: ).*$')
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set resource_folder (ot_config_grab "ObsidianResourceFolder")
set screenshot_folder $obsidian_folder/$resource_folder/(ot_config_grab "MindPalaceFolder")/$folder_title-clips

mkdir -p $screenshot_folder

inotifywait -m -e create --format '%w%f' $a_path | while read FILE
    newline_preppert $obsidian_md
    sleep 3
    set codec (ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 $FILE)
    set file_end (echo "$(basename $FILE)" | grep -o '...$')
    set timestamp (date +%s)

    # x265 hevc codec doesn't work on my obsidian so I convert it into a friendlier codec 
    #if test $codec = 'hevc' 
    #echo "hevc codec detected, conversion started."
    ffmpeg -i $FILE -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 320k $screenshot_folder/$folder_title$timestamp.mp4
    echo "![[$folder_title$timestamp.mp4]]" >>$obsidian_md
    rm $FILE

    #echo "File is compatible, going to move it as is."
    #mv $FILE "$screenshot_folder/$folder_title$timestamp.$file_end"
    #echo -e "![[$folder_title$timestamp.$file_end]]\n" >> $obsidian_md
end
