#! /usr/bin/env fish

function icat_half
    set image $argv[1]

    if not test -f "$image"
        echo "Error: File not found: $image"
        return 1
    end

    set rows (tput lines)
    set row_height_px 18
    set max_height (math "$rows * $row_height_px / 2")

    set tmpimg (mktemp --suffix=.$argv[2])
    magick "$image" -resize x$max_height\> "$tmpimg"

    kitty +kitten icat "$tmpimg"
    sleep 0.3
    rm $tmpimg
end

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
            set wiki_choice (for w in $question_array; echo $w; end | fzf -0 --preview "rg --no-filename -A 10 {} $obsidian_folder/$notes | glow")
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
    if not test -z $pid
        kill $pid
        set -e pid
    end
    clear
    echo "Source: $target_md"
    awk -v search="$trimmed" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $target_md | tee /tmp/img_treasure | glow
    set img_array (cat /tmp/img_treasure | grep -oP "(?<=!\[\[)[^\]]*")
    for img in $img_array
        set suffix (echo $img | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
        set img_path (find $obsidian_folder/$obsidian_resource -type f -name "$img")
        if echo $img_path | rg mp3
        else
            icat_half $img_path "$suffix"
        end
    end
    if cat /tmp/img_treasure | grep -oP "(?<=!\[\[).*.mp3"
        set mp3 (cat /tmp/img_treasure | grep -oP "(?<=!\[\[).*.mp3" | perl -pe 's/([\[\]])/\\\\$1/g')
        set mp3path (find $obsidian_folder/$obsidian_resource -type f -name "$mp3")
        mpv --no-video "$mp3path" >/dev/null &
        set pid $last_pid
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

if not test -z $pid
    kill $pid
end
rm /tmp/img_treasure
