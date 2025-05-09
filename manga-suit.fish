#! /usr/bin/env fish 

set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set anime_folder (ot_config_grab "AnimeFolder")
set media_folder "/home/anon/ortup/important/notes/ortvault/resources/$anime_folder/media/panels"
set obsidian_md (grep 'status: Tracking' $obsidian_folder -rl)
set manga_name (echo $obsidian_md | grep -oP '[^/]+(?=.{3}$)' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set panel_folder (echo "$media_folder/$manga_name")
set read_volumes (math (grep -oP '(?<=read-volumes: )..?' $obsidian_md) + 1)
set date (date +%d.%m.%y)
set info_bar ">[!info] $date - Volume: $read_volumes"

if grep "$date - Volume: $read_volumes" $obsidian_md
else
    echo -e "\n$info_bar\n" >>$obsidian_md
end

mkdir -p $panel_folder

set timestamp (date +%s)
scrot -s $panel_folder/$manga_name.$timestamp.jpg
echo -e "![[$manga_name.$timestamp.jpg]]\n" >>$obsidian_md
