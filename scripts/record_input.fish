#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set filename "$argv[1]"
set note_file (find $obsidian -type f -name "$argv[1].md" -not -path '*/[@.]*')
set folder_title (echo $argv[1] | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set resource_folder (ot_config_grab "ObsidianResourceFolder")
set game_folder (ot_config_grab "GameFolder")
set screenshot_folder $obsidian/$resource_folder/$game_folder/screenshots/$folder_title
set script_dir (realpath (status dirname))
set id "$argv[2]"
set device_name (ot_config_grab "Profile"$id"DeviceName")
set controller_check (ot_config_grab "Profile"$id"ControllerCheck")
set audio_array (pactl list short sinks | grep -oP '^\d+\s+\K\S+')

set screenshot_button (ot_config_grab "Profile"$id"ScreenshotButton")
set record_button (ot_config_grab "Profile"$id"RecordButton")
set audio_button (ot_config_grab "Profile"$id"AudioButton")

mkdir -p $screenshot_folder

# required since event number can change
yes | evtest >/dev/null 2>/tmp/evtest-info.txt
set devinput (cat /tmp/evtest-info.txt | grep "$device_name" | head -n 1 | grep -oP '/dev/input/event[0-9]+')
echo (date +%s) >/tmp/xbox_time.txt

evtest $devinput | while read line

    if test $controller_check -eq 1
        echo $line | grep -oP "(?<=Event: time )[^.]*" >/tmp/xbox_time.txt
    end

    # for screenshots
    if string match -q "*$screenshot_button), value 1" "$line"
        echo \a
        set timestamp (date +%s)
        set fs_name "$folder_title$timestamp.jpg"
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

    # for screen capture
    if string match -q "*$record_button), value 1" "$line"
        echo \a
        sleep 0.5
        set timestamp (date +%s)
        set fv_name "$folder_title-vid-$timestamp.mp4"
        echo -e "![[$fv_name]]\n" >>"$note_file"

        # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
        $script_dir/input-ffmpeg-escaper.fish "$id" &

        # required to grab active window data so that in windowed mode only the game is captured 
        for line in (xdotool getactivewindow getwindowgeometry --shell)
            set -gx (echo $line | cut -d= -f1) (echo $line | cut -d= -f2)
        end

        # first three lines are to be able to use two audice devices (headphones and speakers) and be able to capture audio no matter what, though don't switch audio device mid recording
        ffmpeg \
            -thread_queue_size 1024 -f pulse -i $audio_array[1].monitor \
            -thread_queue_size 1024 -f pulse -i $audio_array[2].monitor \
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
            -video_size "$WIDTH"x"$HEIGHT" \
            -thread_queue_size 1024 -f x11grab -framerate 30 -i :0.0+$X,$Y \
            -c:v libx264 -preset ultrafast -vsync 1 -c:a aac $screenshot_folder/$fv_name
    end

    if string match -q "*$audio_button), value 1" "$line"
        echo \a
        sleep 0.5
        set timestamp (date +%s)
        set fv_name "$folder_title-vid-$timestamp.mp3"
        echo -e "![[$fv_name]]\n" >>"$note_file"

        # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
        $script_dir/input-ffmpeg-escaper.fish "$id" &

        ffmpeg \
            -thread_queue_size 1024 -f pulse -i $audio_array[1].monitor \
            -thread_queue_size 1024 -f pulse -i $audio_array[2].monitor \
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
            -ac 2 -ar 44100 -b:a 192k $screenshot_folder/$fv_name
    end
end
