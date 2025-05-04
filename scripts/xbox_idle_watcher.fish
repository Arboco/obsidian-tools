#! /usr/bin/env fish
set window_id_counter 0
set pid_active
set second_difference

while true
    set window_id (xdotool getwindowfocus)
    if test $window_id -eq (xdotool getwindowfocus)
        set window_id_counter (math $window_id_counter + 1)
        sleep 1
        echo "Hooking Process... $window_id_counter/10"
    end

    if test $window_id_counter -eq 20
        set pid_active (xprop -id $window_id _NET_WM_PID | awk '{print $3}')
        echo "Process determined."
        echo -e "\a"
        break
    end
end

while kill -0 $pid_active 2>/dev/null
    set xbox_time (cat /tmp/xbox_time.txt)
    set xbox_time_seconds (math (date +%s) - $xbox_time)

    if test $window_id -eq (xdotool getwindowfocus)
        if test $xbox_time_seconds -gt 29
            set second_difference (math $second_difference + 1)
            sleep 1
        else
            sleep 1
        end
    else
        set second_difference (math $second_difference + 1)
        sleep 1
    end
    echo "Seconds accumulated: $second_difference"
end

echo $second_difference >/tmp/idle_counter.txt
