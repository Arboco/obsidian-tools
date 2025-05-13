#! /usr/bin/env fish
set window_id_counter 0
set pid_active
set pid_second
set second_difference 0
set payback 0
set payback_cost 0
set payback_times 0
set id "$argv[1]"
set hook_counter (ot_config_grab "Profile"$id"HookCounter")
if test $argv[3] -gt 0
    set hook_counter $argv[3]
end
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

        if echo $pid_active | grep found >/dev/null 2>&1
            set pid_active (xprop -id $window_id WM_CLASS)
            echo "_NET_WIM_PID on first process not found, using WM_CLASS method."
            set p_name (echo $pid_active | grep -oP '(?<=WM_CLASS\(STRING\) = ")[^"]*')
            set pid_active (pidof $p_name)
        end

        set p_name (ps -p $pid_active -o comm=)
        echo " Process $p_name hooked."
        echo -e "\a"
        sleep 5
        set window_id_2 (xdotool getwindowfocus)
        set pid_active_2 (xprop -id $window_id_2 _NET_WM_PID | awk '{print $3}')

        if echo $pid_active_2 | grep found >/dev/null 2>&1
            set pid_active_2 (xprop -id $window_id_2 WM_CLASS)
            echo "_NET_WIM_PID on second process not found, using WM_CLASS method."
            set p_name (echo $pid_active_2 | grep -oP '(?<=WM_CLASS\(STRING\) = ")[^"]*')
            set pid_active_2 (pidof $p_name)
        end

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
        set xbox_time (tail -n 1 /tmp/xbox_time.txt)
        set xbox_time_seconds (math (date +%s) - $xbox_time)
        if test $window_id -eq (xdotool getwindowfocus)
            if test $xbox_time_seconds -ge $idle_counter
                set second_difference (math $second_difference + 1)
                set payback 1
                sleep 1
            else
                sleep 1
            end
        else
            set second_difference (math $second_difference + 1)
            sleep 1
        end
        if test $payback -eq 1
            if test $xbox_time_seconds -lt 3
                set payback_cost (math $payback_cost + $idle_counter)
                set payback 0
                set payback_times (math $payback_times + 1)
            end
        end
        echo -n -e "\rIdle seconds accumulated: $second_difference"
    end

else
    while kill -0 $pid_active 2>/dev/null
        if test $window_id -eq (xdotool getwindowfocus) -o $window_id_2 -eq (xdotool getwindowfocus)
            if test (xprintidle) -ge $idle_counter_c
                set second_difference (math $second_difference + 1)
                set payback 1
                sleep 1
            else
                sleep 1
            end
        else
            set second_difference (math $second_difference + 1)
            sleep 1
        end
        if test $payback -eq 1
            if test (xprintidle) -lt 3000
                set payback_cost (math $payback_cost + $idle_counter)
                set payback 0
                set payback_times (math $payback_times + 1)
            end
        end
        echo -n -e "\rIdle seconds accumulated: $second_difference"
    end
end

set second_difference (math $second_difference + $payback_cost)
echo " "
echo ---
echo "Payback was given $payback_times times!"
echo $second_difference >/tmp/idle_counter.txt
