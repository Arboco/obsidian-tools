#! /usr/bin/env fish

set devinput (cat /tmp/evtest-info.txt | grep 'NuPhy' | head -n 1 | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line
  if string match -q "*KEY_END), value 1" "$line"
    pkill -SIGINT ffmpeg
    sleep 1
    echo \a
    exit
  end
end


