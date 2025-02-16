#! /usr/bin/env fish
set obsidian "/home/anon/ortup/important/notes/ortvault"
set filename "$argv[1]"
set note_file (find $obsidian -type f -name "$argv[1].md" -not -path '*/[@.]*' -type f -mtime -2)
set folder_title (echo $argv[1] | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set screenshot_folder "$obsidian/resources/game/screenshots/$folder_title"
set script_dir (realpath (status dirname))

if test -d $screenshot_folder
  echo "folder exists"
else
  mkdir $screenshot_folder
end

# required since event number can change
yes | evtest 2> /tmp/evtest-info.txt
set devinput (cat /tmp/evtest-info.txt | grep -oP '/dev/input/event[0-9]+')

evtest $devinput | while read line

  # for screenshots 
  if string match -q "*KEY_RECORD), value 1" "$line"
    echo \a
    set timestamp (date +%s)
    set fs_name "$folder_title$timestamp.jpg"
    scrot -u $screenshot_folder/$fs_name
    gm mogrify -trim $screenshot_folder/$fs_name
    echo -e "![[$fs_name]]\n" >> "$note_file"
  end

  # for screen capture
  if string match -q "*BTN_MODE), value 1" "$line"
    echo \a
    set timestamp (date +%s)
    set fv_name "$folder_title-vid-$timestamp.mp4"
    echo -e "![[$fv_name]]\n" >> "$note_file"

    # required because ffmpeg is buggy as a background process so this serves as a watcher to escape screen capture on demand 
    $script_dir/ffmpeg-escaper.fish &

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
    -thread_queue_size 1024 -f x11grab -framerate 30 -i :0.0+$X,$Y  \
    -c:v libx264 -preset ultrafast -vsync 1 -c:a aac $screenshot_folder/$fv_name
  end
end


