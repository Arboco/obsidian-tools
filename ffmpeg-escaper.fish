#! /usr/bin/env fish

set devinput (cat /tmp/evtest-info.txt | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line
  if string match -q "*ABS_HAT0Y), value 1" "$line"
    echo \a
    echo "hello world"
    pkill -SIGINT ffmpeg
    exit
  end
end


