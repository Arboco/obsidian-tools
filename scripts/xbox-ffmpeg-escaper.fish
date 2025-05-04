#! /usr/bin/env fish

set gamepad_name (config_grab "GamePadName")
set devinput (cat /tmp/evtest-info.txt | grep "$gamepad_name" | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line
    if string match -q "*ABS_HAT0Y), value 1" "$line"
        pkill -SIGINT ffmpeg
        echo "hello world"
        exit
    end
end
