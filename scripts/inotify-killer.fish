#! /usr/bin/env fish
while kill -0 $argv[1] >/dev/null 2>&1
    sleep 1
end
killall inotifywait

echo \a
