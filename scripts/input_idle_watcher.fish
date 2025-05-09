#! /usr/bin/env fish
set window_id_counter 0
set pid_active
set pid_second
set second_difference 0
set id "$argv[1]"
set hook_counter (ot_config_grab "Profile"$id"HookCounter")
set idle_counter (ot_config_grab "Profile"$id"IdleCounter")
set idle_counter_c (math $idle_counter x 1000)

while true
    set window_id (xdotool getwindowfocus)
    if test $window_id -eq (xdotool getwindowfocus)
        set window_id_counter (math $window_id_counter + 1)
        sleep 1
        echo -n -e "\rHooking Process... $window_id_counter/$hook_counter"
    end

    if test $window_id_counter -eq $hook_counter
        set pid_active (xprop -id $window_id _NET_WM_PID | awk '{print $3}')
        set p_name (ps -p $pid_active -o comm=)
        echo " Process $p_name hooked."
        echo -e "\a"
        sleep 5
        set window_id_2 (xdotool getwindowfocus)
        set pid_active_2 (xprop -id $window_id_2 _NET_WM_PID | awk '{print $3}')
        set p_name (ps -p $pid_active_2 -o comm=)
        echo "Second Process $p_name hooked."
        echo -e "\a"
        break
    end
end

if test $argv[2] -eq 1
    set xbox_time 0
    set xbox_time_seconds 0
    while kill -0 $pid_active 2>/dev/null
        if grep '[0-9]' /tmp/xbox_time.txt >/dev/null 2>&1
            set xbox_time (cat /tmp/xbox_time.txt)
            set xbox_time_seconds (math (date +%s) - $xbox_time)
        end
        if test $window_id -eq (xdotool getwindowfocus)
            if test $xbox_time_seconds -ge $idle_counter
                set second_difference (math $second_difference + 1)
                sleep 1
            else
                sleep 1
            end
        else
            set second_difference (math $second_difference + 1)
            sleep 1
        end
        echo -n -e "\rIdle seconds accumulated: $second_difference"
    end
else
    while kill -0 $pid_active 2>/dev/null

        if test $window_id -eq (xdotool getwindowfocus) -o $window_id_2 -eq (xdotool getwindowfocus)
            if test (xprintidle) -ge $idle_counter_c
                set second_difference (math $second_difference + 1)
                sleep 1
            else
                sleep 1
            end
        else
            set second_difference (math $second_difference + 1)
            sleep 1
        end
        echo -n -e "\rIdle seconds accumulated: $second_difference"
    end
end

echo " "
echo ---
echo $second_difference >/tmp/idle_counter.txt
