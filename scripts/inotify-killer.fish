#! /usr/bin/env fish
while kill -0 $argv[1] > /dev/null 2>&1
    echo "Process is running"
    sleep 1  
end
killall inotifywait
