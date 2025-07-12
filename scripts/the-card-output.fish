#! /usr/bin/env fish

set script_dir (realpath (status dirname))

function mpv-small
    set file $argv[1]
    mpv --input-ipc-server=/tmp/mpv-socket \
        --idle=yes \
        --force-window=yes \
        --geometry=640x360-0-0 \
        --keepaspect >/dev/null &

    set -g mpv_pid $last_pid
    set mpvid $mpv_pid

    set mpv_is_running 1
    sleep 1
    i3-msg '[class="mpv"] floating enable'
end

function icat_half
    set image $argv[1]

    set cols (tput cols)
    set lines (tput lines)

    set cell_width 9
    set cell_height 18

    set width_px (math round $cols x $cell_width / 2)
    set height_px (math round $lines x $cell_height / 2)

    kitty +kitten icat --use-window-size=$cell_width,$cell_height,$width_px,$height_px $argv[1]
end

set mpv_is_running 0

for i in (cat /tmp/the-card_final_sorted_array)
    set card_type (echo "$i" | grep -o "^.")

    if string match -q Q $card_type
        echo "$i" | glow
        gum input --placeholder "Press enter to continue..."
    end

    set i_trim (string trim -r -- $i)
    set trimmed (string split '`' -- $i_trim)[1]
    set target_md (rg -lF "$trimmed" $obsidian_folder/$notes)

    if string match -q Combined $choice
    else
        if string match -q W $card_type
            set wiki_choice (for w in $question_array; echo $w; end | fzf -0 --preview "$script_dir/the-card-wiki-fzf.fish {}")
            set target_md (rg -lF "$wiki_choice" $obsidian_folder/$notes)
            set trimmed (string split '`' -- $wiki_choice)[1]
        end
    end

    if string match -q I $card_type
        if test -z $second_counter
            echo "Minimum amount of time in seconds to observe inspiration:"
            set inspiration_option (gum choose --limit 1 "0" "15" "30" "60" "Custom")
            if string match -q Custom $inspiration_option
                set second_counter (gum input --placeholder "Set seconds")
            else
                set second_counter $inspiration_option
            end
        end
        clear
    end

    if string match -q D $card_type
        while not string match y $user_decision
            mkdir -p $obsidian_folder/$obsidian_resource/drill_evidence
            echo "$i"
            set input_user (gum input --placeholder "Press Enter when you are ready to provide Image Evidence of your drill, insert x if you don't want to provide evidence")
            if string match -q x $input_user
                break
            end
            set image_evidence (gum file $HOME)
            set suffix_evidence (echo $image_evidence | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
            icat_half $image_evidence "$suffix_evidence"
            set user_decision (gum input --placeholder "Are you sure about this evidence? y/n")
            if string match y $user_decision
                cp $target_md /tmp/clone.md
                set uuid (uuidgen)
                cp $image_evidence $obsidian_folder/$obsidian_resource/drill_evidence/$uuid.$suffix_evidence
                set image_final_insert "![[$uuid.$suffix_evidence]]"
                awk -v search="$trimmed" -v newline="$image_final_insert" '
              !in_para && index($0, search) { found = 1 }
              NF > 0 { in_para = 1 }  # paragraph is active (non-empty line)
              NF == 0 && found && !inserted {
                print newline
                inserted = 1
              }
              { print }
              NF == 0 { in_para = 0 }  # reset at blank line
              ' /tmp/clone.md >$target_md
            end
        end
        clear
        rm /tmp/clone.md
    end
    if not test -z $mpid
        kill $mpid
        set -e mpid
    end
    clear
    echo "Source: $target_md"
    awk -v search="$trimmed" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $target_md >/tmp/file_contents_ready
    set treasure_array (cat /tmp/file_contents_ready | grep -oP "(?<=(!|>)\[\[)[^\|?\]]*")
    cat /tmp/file_contents_ready | sed -E '/!|>\[\[/d' | glow
    for tre in $treasure_array
        set suffix (echo $tre | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
        set file_path (find $obsidian_folder/$obsidian_resource -type f -name "$tre")
        if echo $file_path | rg -q '(mp3|aac|flac|wav|alac|ogg|aiff|dsd)$'
            mpv --no-video $file_path >/dev/null &
            set mpid $last_pid
        else if echo $file_path | rg -q '(mp4|mkv|mov|avi|webm|flv|wmv)$'
            echo $file_path
            if test $mpv_is_running -eq 0
                mpv-small &
            end
            echo '{ "command": ["loadfile", "'"$file_path"'"] }' | socat - /tmp/mpv-socket
        else
            icat_half $file_path
        end
    end

    if string match -q I $card_type
        gum spin --spinner moon --title "Get inspired..." -- sleep $second_counter
    end

    echo ""
    if not echo $i | rg -qP '`'
        if string match -q W $card_type
            set user_input (gum input --placeholder "0 - Exit | r - Revise | o - Open File")
            if string match 1 $user_input; or string match 2 $user_input
                set user_input ""
            end
        else if string match -q I $card_type
            set user_input (gum input --placeholder "d - Date | 0 - Exit | r - Revise | o - Open File")
            if string match 1 $user_input; or string match 2 $user_input
                set user_input ""
            end
        else
            set user_input (gum input --placeholder "1 - Correct | 2 - Wrong | 0 - Exit | r - Revise | o - Open File")
        end
        set new_date (date +"%Y-%m-%d %H:%M:%S")

        if string match 0 $user_input
            exit
        else if string match r $user_input
            clear
            kitty nvim +/"$i" $target_md
        else if string match 1 $user_input
            clear
            sed -i "s/$i/$i_trim `$new_date S-Value: 1`/g" $target_md
        else if string match 2 $user_input
            clear
            sed -i "s/$i/$i_trim `$new_date S-Value: -1`/g" $target_md
        else if string match o $user_input
            clear
            obsidian "obsidian://$target_md" >/dev/null 2>&1 &
        else if string match d $user_input
            clear
            sed -i "s/$i/$i_trim `$new_date`/g" $target_md
        end
    else
        if string match -q I $card_type
            set user_input (gum input --placeholder "d - Date | 0 - Exit | r - Revise | o - Open File")
            if string match 1 $user_input; or string match 2 $user_input
                set user_input ""
            end
        else
            set user_input (gum input --placeholder "1 - Correct | 2 - Wrong | 0 - Exit | r - Revise | o - Open File")
            if string match d $user_input
                set user_input ""
            end
        end
        set old_date (echo $i | rg -o "`.*:[0-9]+" | sed 's/`//g')
        set new_date (date +"%Y-%m-%d %H:%M:%S")
        set svalue (echo $i | rg -oP "(?<=S-Value: )[-0-9]*")

        if string match 0 $user_input
            exit
        else if string match r $user_input
            clear
            kitty nvim +/"$i" $target_md
        else if string match 1 $user_input
            clear
            set svalue (math $svalue + 1)
            set new_i (echo $i | string replace -r 'S-Value: -?\d+' "S-Value: $svalue" -- $line)
            sed -i "s/$i/$new_i/g" $target_md
            sed -i "s/$old_date/$new_date/g" $target_md
        else if string match 2 $user_input
            clear
            set svalue (math $svalue - 1)
            set new_i (echo $i | string replace -r 'S-Value: -?\d+' "S-Value: $svalue" -- $line)
            sed -i "s/$i/$new_i/g" $target_md
            sed -i "s/$old_date/$new_date/g" $target_md
        else if string match o $user_input
            clear
            obsidian "obsidian://$target_md" >/dev/null 2>&1 &
        else if string match d $user_input
            clear
            sed -i "s/$old_date/$new_date/g" $target_md
        else if string match 2 $user_input
        end
    end

    set -e target_md
end

if not test -z $mpid
    kill $mpid
end

if not test -z $mpv_pid
    kill $mpv_pid
end

if not test -z the_key_activated
    if test $the_key_activated -eq 1
        echo "The key was found and activated"
    end
end
rm /tmp/file_contents_ready
