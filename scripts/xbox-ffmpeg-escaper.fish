#! /usr/bin/env fish

set gamepad_name (ot_config_grab "GamePadName")
set escape_button (ot_config_grab "Profile2EscapeButton")
set devinput (cat /tmp/evtest-info.txt | grep "$gamepad_name" | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line
    if string match -q "*$escape_button), value 1" "$line"
        pkill -SIGINT ffmpeg
        echo "hello world"
        exit
    end
end
