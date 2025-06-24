#! /usr/bin/env fish 
set script_dir (dirname (status --current-filename))
set parent_dir (dirname $script_dir)
while kill -0 $argv[1] >/dev/null 2>&1
    sleep 1
end
killall inotifywait

ffplay -nodisp -autoexit $parent_dir/helper/amazed-emote-animal-crossing.mp3 >/dev/null 2>&1
