#! /usr/bin/env fish

set id "$argv[1]"
set device_name (ot_config_grab "PoolDeviceName")
set escape_button (ot_config_grab "PoolEscapeButton")
set devinput (cat /tmp/evtest-info.txt | grep "$device_name" | head -n 1 | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line
    if string match -q "*$escape_button), value 1" "$line"
        pkill -SIGINT ffmpeg
        sleep 1
        echo \a
        exit
    end
end
