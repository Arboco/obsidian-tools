#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set filename "$argv[1]"
set note_file (cat /tmp/the-pool.txt)
set folder_title (echo $argv[1] | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set resource_folder (ot_config_grab "ObsidianResourceFolder")
set pool_folder (ot_config_grab "ThePoolFolder")
set screenshot_folder $obsidian/$resource_folder/$pool_folder/$folder_title
set script_dir (realpath (status dirname))
set id "$argv[2]"
set device_name (ot_config_grab "PoolDeviceName")

set audio_array (pactl list short sinks | grep -oP '^\d+\s+\K\S+')

set screenshot_button (ot_config_grab "PoolScreenshotButton")
set record_button (ot_config_grab "PoolRecordButton")
set audio_button (ot_config_grab "PoolAudioButton")
set select_screenshot (ot_config_grab "PoolSelectScreenshotButton")

mkdir -p $screenshot_folder

# required since event number can change
yes | evtest >/dev/null 2>/tmp/evtest-info.txt
set devinput (cat /tmp/evtest-info.txt | grep "$device_name" | head -n 1 | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line

    # for screenshots
    if string match -q "*$screenshot_button), value 1" "$line"
        echo \a
        set timestamp (date +%F_%H%M%S)
        set fs_name "$folder_title-$timestamp.jpg"
        scrot -u $screenshot_folder/$fs_name

        if grep "cut:" $note_file
            echo "cut found"
            set numcut (string split ' ' (grep -oP "(?<=cut: ).*" $note_file))
            gm mogrify -shave $numcut[1]x$numcut[2] $screenshot_folder/$fs_name
            sleep 1
        end

        gm mogrify -fuzz 5% -trim $screenshot_folder/$fs_name
        echo -e "![[$fs_name]]\n" >>"$note_file"
    end

    # for screenshots where you can select area
    if string match -q "*$select_screenshot), value 1" "$line"
        echo \a
        set timestamp (date +%F_%H%M%S)
        set fs_name "$folder_title-$timestamp.jpg"
        scrot -s $screenshot_folder/$fs_name

        if grep -q "cover-img:" $note_file
            echo -e "![[$fs_name]]\n" >>"$note_file"
        else
            sed -i "/^tags:/i\\cover-img: \"![[$fs_name]]\"" "$note_file"
        end

    end

    # for screen capture
    if string match -q "*$record_button), value 1" "$line"
        echo \a
        sleep 0.5
        set timestamp (date +%F_%H%M%S)
        set fv_name "$folder_title-vid-$timestamp.mp4"
        echo -e "![[$fv_name]]\n" >>"$note_file"

        # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
        $script_dir/pool-escaper.fish 1 &

        # required to grab active window data so that in windowed mode only the game is captured 
        for line in (xdotool getactivewindow getwindowgeometry --shell)
            set -gx (echo $line | cut -d= -f1) (echo $line | cut -d= -f2)
        end

        # first three lines are to be able to use two audio devices (headphones and speakers) and be able to capture audio no matter what, though don't switch audio device mid recording
        ffmpeg \
            -thread_queue_size 1024 -f pulse -i $audio_array[1].monitor \
            -thread_queue_size 1024 -f pulse -i $audio_array[2].monitor \
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
            -f x11grab -draw_mouse 0 \
            -video_size "$WIDTH"x"$HEIGHT" \
            -thread_queue_size 1024 -f x11grab -framerate 30 -i :0.0+$X,$Y \
            -c:v libx264 -preset slow -vsync 1 -c:a aac $screenshot_folder/$fv_name >/dev/null 2>&1
    end

    if string match -q "*$audio_button), value 1" "$line"
        echo \a
        sleep 0.5
        set timestamp (date +%F_%H%M%S)
        set fv_name "$folder_title-vid-$timestamp.mp3"
        echo -e "![[$fv_name]]\n" >>"$note_file"

        # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
        $script_dir/pool-escaper.fish 1 &

        ffmpeg \
            -thread_queue_size 1024 -f pulse -i $audio_array[1].monitor \
            -thread_queue_size 1024 -f pulse -i $audio_array[2].monitor \
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
            -ac 2 -ar 44100 -b:a 192k $screenshot_folder/$fv_name >/dev/null 2>&1
    end
end
