#! /usr/bin/env fish

set script_dir (dirname (status --current-filename))
set parent_dir (dirname $script_dir)
set obsidian (ot_config_grab "ObsidianMainFolder")
set filename "$argv[1]"
set note_file (find $obsidian -type f -name "$argv[1].md" -not -path '*/[@.]*')
set folder_title (echo $argv[1] | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set resource_folder (ot_config_grab "ObsidianResourceFolder")
set game_folder (ot_config_grab "GameFolder")
set screenshot_folder $obsidian/$resource_folder/$game_folder/media/$folder_title
set script_dir (realpath (status dirname))
set id "$argv[2]"
set device_name (ot_config_grab "Profile"$id"DeviceName")
set last_recorded_file /tmp/ot_last_recorded_file

set controller_check (ot_config_grab "Profile"$id"ControllerCheck")
if test $controller_check -eq 1
    set input_block (ot_config_grab "Profile"$id"InputBlock")
end
set audio_array (pactl list short sinks | grep -oP '^\d+\s+\K\S+')

set screenshot_button (ot_config_grab "Profile"$id"ScreenshotButton")
set record_button (ot_config_grab "Profile"$id"RecordButton")
set audio_button (ot_config_grab "Profile"$id"AudioButton")
set select_screenshot (ot_config_grab "Profile"$id"SelectScreenshotButton")
set hold_button (ot_config_grab "Profile"$id"HoldButton")
set mindpalace_button (ot_config_grab "Profile"$id"MindPalace")
set mindpalace_number 1
set mind_palace_uuid (uuidgen)

if test -z (ot_config_grab "Profile"$id"ScreenshotButton")
    set screenshot_button screenshot_button
end
if test -z (ot_config_grab "Profile"$id"RecordButton")
    set record_button record_button
end
if test -z (ot_config_grab "Profile"$id"AudioButton")
    set audio_button audio_button
end
if test -z (ot_config_grab "Profile"$id"SelectScreenshotButton")
    set select_screenshot select_screenshot
end
if test -z (ot_config_grab "Profile"$id"HoldButton")
    set select_screenshot hold_screenshot
end
if test -z (ot_config_grab "Profile"$id"MindPalace")
    set select_screenshot mind_palace_button
end

mkdir -p $screenshot_folder

# required since event number can change
yes | evtest >/dev/null 2>/tmp/evtest-info.txt
set devinput (cat /tmp/evtest-info.txt | grep -P "$device_name" | head -n 1 | grep -oP '/dev/input/event[0-9]+')
echo (date +%s) >/tmp/xbox_time.txt

evtest $devinput | while read line

    if test $controller_check -eq 1
        if echo $line | grep -qP "$input_block"; or echo $line | grep -q SYN_REPORT
        else
            echo $line | grep -oP "(?<=Event: time )[^.]*" >>/tmp/xbox_time.txt
        end
    end

    if test $controller_check -eq 1
        if string match -q "*$hold_button), value 1" "$line"
            set hold_trigger 1
        else if string match -q "*$hold_button), value 0" "$line"
            set hold_trigger 0
        end
    else
        set hold_trigger 1
    end

    # for mindpalace
    if string match -q "*$mindpalace_button), value 1" "$line"; and test $hold_trigger -eq 1
        echo \a
        set timestamp (date +%F_%H%M%S)
        set fs_name "$folder_title-$timestamp.jpg"
        scrot -u $screenshot_folder/$fs_name

        if grep "cut:" $note_file
            echo "cut found"
            set numcut (string split ' ' (grep -oP "(?<=cut: ).*" $note_file))
            gm mogrify -quality 50 -shave $numcut[1]x$numcut[2] $screenshot_folder/$fs_name
            sleep 1
        else
            gm mogrify -quality 50 -fuzz 5% -trim $screenshot_folder/$fs_name
        end

        set uuid (uuidgen)
        echo "I: $uuid #$mindpalace_number" >>$note_file
        echo "mpid: $mind_palace_uuid" >>$note_file
        echo ">" >>$note_file
        echo "![[$fs_name]]" >>$note_file
        echo "" >>$note_file

        set mindpalace_number (math $mindpalace_number + 1)
    end

    # for generic screenshots 
    if string match -q "*$screenshot_button), value 1" "$line"; and test $hold_trigger -eq 1
        echo \a
        set timestamp (date +%F_%H%M%S)
        set fs_name "$folder_title-$timestamp.jpg"
        scrot -u $screenshot_folder/$fs_name

        if grep "cut:" $note_file
            echo "cut found"
            set numcut (string split ' ' (grep -oP "(?<=cut: ).*" $note_file))
            gm mogrify -shave $numcut[1]x$numcut[2] $screenshot_folder/$fs_name
            sleep 1
        else
            gm mogrify -fuzz 5% -trim $screenshot_folder/$fs_name
        end

        echo -e "![[$fs_name]]\n" >>"$note_file"
        echo "![[$fs_name]]" >$last_recorded_file
    end

    # for screen capture
    if string match -q "*$record_button), value 1" "$line"; and test $hold_trigger -eq 1
        echo \a
        sleep 0.5
        set timestamp (date +%F_%H%M%S)
        set fv_name "$folder_title-vid-$timestamp.mp4"
        echo -e "![[$fv_name]]\n" >>"$note_file"
        echo "![[$fv_name]]" >$last_recorded_file

        # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
        $script_dir/input-ffmpeg-escaper.fish "$id" &

        # required to grab active window data so that in windowed mode only the game is captured 
        for line in (xdotool getactivewindow getwindowgeometry --shell)
            set -gx (echo $line | cut -d= -f1) (echo $line | cut -d= -f2)
        end

        set crop "iw:ih:0:0"
        if grep -q "crop:" $note_file
            set crop (grep -oP "(?<=crop: ).*" $note_file)
        end

        # first three lines are to be able to use two audio devices (headphones and speakers) and be able to capture audio no matter what, though don't switch audio device mid recording
        ffmpeg \
            -thread_queue_size 1024 -f pulse -i $audio_array[1].monitor \
            -thread_queue_size 1024 -f pulse -i $audio_array[2].monitor \
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
            -f x11grab -draw_mouse 0 \
            -video_size "$WIDTH"x"$HEIGHT" \
            -thread_queue_size 1024 -f x11grab -framerate 60 -i :0.0+$X,$Y \
            -vf "crop=$crop" \
            -c:v libx264 -preset ultrafast -vsync 1 -c:a aac $screenshot_folder/$fv_name
    end

    if string match -q "*$audio_button), value 1" "$line"; and test $hold_trigger -eq 1
        echo \a
        sleep 0.5
        set timestamp (date +%F_%H%M%S)
        set fv_name "$folder_title-vid-$timestamp.mp3"
        echo -e "![[$fv_name]]\n" >>"$note_file"
        echo "![[$fv_name]]" >$last_recorded_file

        # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
        $script_dir/input-ffmpeg-escaper.fish "$id" &

        ffmpeg \
            -thread_queue_size 1024 -f pulse -i $audio_array[1].monitor \
            -thread_queue_size 1024 -f pulse -i $audio_array[2].monitor \
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
            -ac 2 -ar 44100 -b:a 192k $screenshot_folder/$fv_name

        set url "http://127.0.0.1:8081"
        # Use curl with --silent --head to send a HEAD request and check HTTP status
        curl --silent --head --fail $url >/dev/null
        if test $status -eq 0
            source ~/python/jap-trans/bin/activate.fish
            python3 $parent_dir/python/transcribe.py $screenshot_folder/$fv_name | sed 's/\[[^][]*\]//g' >>"$note_file"
            ffplay -nodisp -autoexit $parent_dir/helper/pleased-emote-animal-crossing.mp3 >/dev/null 2>&1
        end

    end

    if test $controller_check -eq 0
        if string match -q "*$select_screenshot), value 1" "$line"
            echo \a
            set timestamp (date +%F_%H%M%S)
            set fs_name "$folder_title-$timestamp.jpg"
            scrot -s $screenshot_folder/$fs_name
            echo -e "![[$fs_name]]\n" >>"$note_file"
            echo "![[$fs_name]]" >$last_recorded_file

            set url "http://127.0.0.1:8081"
            # Use curl with --silent --head to send a HEAD request and check HTTP status
            curl --silent --head --fail $url >/dev/null
            if test $status -eq 0
                echo "Server is ready"
                set response (curl -s "$url/?q=$screenshot_folder/$fs_name")
                echo "$response" >>"$note_file"
            else
                echo "Server not reachable"
            end

        end
    end
end
