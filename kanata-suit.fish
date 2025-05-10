#! /usr/bin/env fish
set obsidian (ot_config_grab "ObsidianMainFolder")
set game_folder (ot_config_grab "GameFolder")
set fullpath_game (cat /tmp/obsidian-game.txt)
set gamename (basename -s .md $fullpath_game)
set filename "$gamename"
set note_file (find $obsidian -type f -name "$gamename.md" -not -path '*/[@.]*')
set folder_title (echo $gamename | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set screenshot_folder "$obsidian/resources/$game_folder/media/$folder_title"
set script_dir (realpath (status dirname))

if test -d $screenshot_folder
    echo "folder exists"
else
    mkdir $screenshot_folder
end
argparse --name=gn h/help s/screenshot v/video a/audio 'n/name=' -- $argv
or return

if set -q _flag_s
    echo \a
    set timestamp (date +%s)
    set fs_name "$folder_title$timestamp.jpg"
    scrot -u $screenshot_folder/$fs_name

    if grep "cut:" $note_file
        echo "cut found"
        set numcut (string split ' ' (grep -oP "(?<=cut: ).*" $note_file))
        gm mogrify -shave $numcut[1]x$numcut[2] $screenshot_folder/$fs_name
        sleep 1
    else
        echo "cut not found"
    end

    gm mogrify -fuzz 5% -trim $screenshot_folder/$fs_name
    echo -e "![[$fs_name]]\n" >>"$note_file"
    exit
end

if set -q _flag_v
    echo \a
    sleep 0.5
    set timestamp (date +%s)
    set fv_name "$folder_title-vid-$timestamp.mp4"
    echo -e "![[$fv_name]]\n" >>"$note_file"

    # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
    $script_dir/vn-ffmpeg-escaper.fish &

    # required to grab active window data so that in windowed mode only the game is captured 
    for line in (xdotool getactivewindow getwindowgeometry --shell)
        set -gx (echo $line | cut -d= -f1) (echo $line | cut -d= -f2)
    end

    # first three lines are to be able to use two audice devices (headphones and speakers) and be able to capture audio no matter what, though don't switch audio device mid recording
    ffmpeg \
        -thread_queue_size 1024 -f pulse -i alsa_output.usb-FiiO_DigiHug_USB_Audio-01.analog-stereo.monitor \
        -thread_queue_size 1024 -f pulse -i alsa_output.pci-0000_0d_00.4.analog-stereo.monitor \
        -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
        -video_size "$WIDTH"x"$HEIGHT" \
        -thread_queue_size 1024 -f x11grab -framerate 30 -i :0.0+$X,$Y \
        -c:v libx264 -preset ultrafast -vsync 1 -c:a aac $screenshot_folder/$fv_name
    exit
end

if set -q _flag_a
    echo \a
    sleep 0.5
    set timestamp (date +%s)
    set fv_name "$folder_title-vid-$timestamp.mp3"
    echo -e "![[$fv_name]]\n" >>"$note_file"

    # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
    $script_dir/vn-ffmpeg-escaper.fish &

    ffmpeg \
        -thread_queue_size 1024 -f pulse -i alsa_output.usb-FiiO_DigiHug_USB_Audio-01.analog-stereo.monitor \
        -thread_queue_size 1024 -f pulse -i alsa_output.pci-0000_0d_00.4.analog-stereo.monitor \
        -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3" \
        -ac 2 -ar 44100 -b:a 192k $screenshot_folder/$fv_name
    exit
end
