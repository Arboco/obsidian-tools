#! /usr/bin/env fish

set script_dir (realpath (status dirname))
echo "test $script_dir"
set obsidian (ot_config_grab "ObsidianMainFolder")
set anime_folder (ot_config_grab "AnimeFolder")
set resources_folder (ot_config_grab "ObsidianResourceFolder")
set start (date +%s)
set obsidian_md (find $obsidian -type f -name "$argv[1].md" | grep 'anime/')

$script_dir/scripts/inotify-anime-clip.fish "$obsidian_md" "$argv[1]" &
$script_dir/scripts/inotify-anime-screenshot.fish "$obsidian_md" "$argv[1]" &
set a_path (cat $obsidian_md | grep 'path:')
set a_path (echo $a_path | grep -oP '(?<=path: ).*$')
set folder_title (echo $argv[1] | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set current_episode (cat $obsidian_md | grep -oP '(?<=watched: )[0-9][0-9]?[0-9]?')
set current_episode (math $current_episode + 1)
set screenshot_folder $resources_folder/$anime_folder/media/screenshots/$folder_title

mkdir -p $screenshot_folder

cp $obsidian_md /tmp/clone.md
echo $current_episode
awk '/watched/ { 
    for (i = 1; i <= NF; i++) { 
        if ($i ~ /^[0-9]+$/) $i = $i + 1; 
    } 
} { print }' /tmp/clone.md >$obsidian_md
rm /tmp/clone.md
set cur_date (date +%d.%m.%y)
set cur_hour (date +%H:%M)
set my_array (find $a_path/ -maxdepth 1 -iname "*.mkv" | sort)
echo -e "\n# Episode $current_episode" >>$obsidian_md
echo -e "$cur_hour - $cur_date\n" >>$obsidian_md
mpv --screenshot-directory="$screenshot_folder" $my_array[$current_episode] &

# inotify is very persistent so it needs to be explicitly killed
# this is a watcher that continously looks up if video player still runs and it not it kills the innotify watchers 
$script_dir/scripts/inotify-killer.fish $last_pid &
