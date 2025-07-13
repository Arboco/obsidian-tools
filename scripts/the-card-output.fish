#! /usr/bin/env fish

set script_dir (realpath (status dirname))
set parent_dir (dirname (status --current-filename))
set parent_dir (dirname $parent_dir)

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
    set suffix (echo "$image" | rg -oP '\.[^.\\/]+$')
    set temp_image (mktemp --suffix $suffix)

    set term_size (kitty icat --print-window-size | string split "x")
    set img_size (identify -format "%w %h" $image | string split " ")
    set max_wanted_height (math round $term_size[2] / 2)
    if test $img_size[2] -gt $max_wanted_height
        magick "$image" -resize x$max_wanted_height $temp_image
        kitty +kitten icat --transfer-mode=memory --stdin=no --align=left "$temp_image"
    else
        kitty +kitten icat --transfer-mode=memory --stdin=no --align=left "$image"
    end

    rm "$temp_image"
end

function just_thumbnail
    set file $argv[1]
    set temp_thumb (mktemp)
    ffmpeg -y -ss 00:00:01 -i "$file" -frames:v 1 -update 1 -q:v 2 "$temp_thumb.jpg" >/dev/null 2>&1
    icat_half $temp_thumb.jpg
    rm $temp_thumb
end

function property_increase_exists
    set search_key $argv[1]
    set end_md $argv[2]
    set property $argv[3]
    awk -v key="$search_key" -v property="$property" '
        BEGIN {
            RS = ""
            ORS = "\n\n"
        }
        {
            if ($0 ~ key && !updated) {
                # Build dynamic regex to match "property: [0-9]+"
                regex = property ": [0-9]+"
                if (match($0, regex)) {
                    split(substr($0, RSTART, RLENGTH), a, " ")
                    new_val = a[2] + 1
                    sub(regex, property ": " new_val)
                }
                updated = 1
            }
            print
        }
        ' "$end_md" >"$end_md.tmp" && mv "$end_md.tmp" "$end_md"
end

function property_increase_new
    set search_key $argv[1]
    set end_md $argv[2]
    set property $argv[3]
    awk -v key="$search_key" -v property="$property" '
        {
            print
            if ($0 ~ key) {
                print property": 1"
            }
        } ' $end_md >"$end_md.tmp" && mv "$end_md.tmp" "$end_md"
end

function brainstorming
    set trans_input $argv[1]
    set key_title $argv[2]
    echo $trans_input
    while not string match 0 $trans_input
        awk -v search_str="$key_title" -v append="$trans_input" '
            BEGIN { RS=""; ORS="\n\n" }
            {
                if ($0 ~ search_str) {
                    $0 = $0 "\n" append
                }
                print
            } ' "$target_md" >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
        set trans_input (gum input --placeholder "Escape with 0, anything else gets added to the block")
        echo $trans_input
    end
end

set mpv_is_running 0

for i in (cat /tmp/the-card_final_sorted_array)
    set i_trim (string trim -r -- $i)
    set trimmed (string split '`' -- $i_trim)[1]
    set target_md (rg -lF "$trimmed" $obsidian_folder/$notes)

    clear
    set card_type (echo "$i" | grep -o "^.")
    if string match -q Q $card_type
        echo "$i" | perl -pe 's/`[^`]*`//g' | glow
        gum input --placeholder "Press enter to continue..."
    end

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

    if not test -z $mpid
        kill $mpid
        set -e mpid
    end
    clear
    echo ""
    awk -v search="$trimmed" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $target_md >/tmp/file_contents_ready
    set treasure_array (cat /tmp/file_contents_ready | grep -oP "(?<=(!|>)\[\[)[^\|?\]]*")

    if string match -q T $card_type; or string match -q Q $card_type; or string match -q I $card_type
        cat /tmp/file_contents_ready | sed -E '/!|>\[\[/d' \
            | sed 's/^>//g' \
            | sed '/^I:/ s/.*/\x1b[38;2;173;216;230m&\x1b[0m/' \
            | sed '/^T:/ {/second_counter/ s/.*/\x1b[38;2;255;165;0m&\x1b[0m/}' \
            | sed '/^Q:/ s/.*/\x1b[38;2;152;255;152m&\x1b[0m/' \
            | sed '/^agenda:/ s/.*/\x1b[38;2;0;255;255m&\x1b[0m/' \
            | perl -pe 's/`[^`]*`//g' \
            | perl -pe 's/(#\w+)/"\e[38;2;255;255;0m$1\e[0m"/ge' \
            | fold -s -w 90 | bat -p --language=Markdown | sed 's/^/    /'
    else
        cat /tmp/file_contents_ready | sed "/!\[\[/d" | sed 's/```shell//g' | sed 's/```//g' | bat --wrap auto --color=always --language=fish
    end
    for tre in $treasure_array
        set suffix (echo $tre | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
        set file_path (find $obsidian_folder/$obsidian_resource -type f -name "$tre")
        if echo $file_path | rg -q '(mp3|aac|flac|wav|alac|ogg|aiff|dsd)$'
            mpv --no-video $file_path >/dev/null &
            set mpid $last_pid
        else if echo $file_path | rg -q '(mp4|mkv|mov|avi|webm|flv|wmv)$'
            if test $generate_thumbnail -eq 1
                just_thumbnail $file_path
            else
                if test $mpv_is_running -eq 0
                    mpv-small &
                end
                echo '{ "command": ["loadfile", "'"$file_path"'"] }' | socat - /tmp/mpv-socket
            end

        else
            icat_half $file_path
        end
    end

    echo ""
    echo "Source: $(basename $target_md)" | sed 's/^/ /'
    echo ""

    if string match -q T $card_type
        mkdir -p $obsidian_folder/$obsidian_resource/drill_evidence
        set input_user (gum input --placeholder "s - Skip | r - Revise | o - Open File | c - Complete Task")
        if string match -q s $input_user
            if cat /tmp/file_contents_ready | rg -q "^skipped:"
                property_increase_exists $i $target_md skipped
            else
                property_increase_new $i $target_md skipped
            end
        else if string match o $input_user
            clear
            obsidian "obsidian://$target_md" >/dev/null 2>&1 &
        else if string match r $input_user
            clear
            kitty nvim +/"$i" $target_md
        else if echo "$input_user" | rg -q '^.{2,}$'
            brainstorming $input_user $i
        else
            if cat /tmp/file_contents_ready | rg -q "^skipped:"
                property_increase_exists $i $target_md skipped
            else
                property_increase_new $i $target_md skipped
            end
        end

        if cat /tmp/file_contents_ready | rg "^skipped: 9"
            clear
            cat $parent_dir/helper/humiliation
            ffplay -nodisp -autoexit $parent_dir/helper/scary_sound.mp3 >/dev/null 2>&1 &
            echo ""
            gum spin --spinner dot --title "Skipped 10 times? Try to think about why you are avoiding this task..." -- sleep 60
        end

        if string match -q c $input_user
            set input_user (gum input --placeholder "t - Transform | r - Repeat | d - Delete | a - Archive")
            if string match -q t $input_user
                read replacement
                awk -v search="$i" -v replace="$replacement" '{ gsub(search, replace); print }' $target_md >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
            else if string match -q r $input_user
                break
            else if string match -q d $input_user
                awk -v start="$i" '
                  BEGIN { skip = 0 }
                  /^$/ { skip = 0; print; next }
                  skip || $0 ~ start { skip = 1; next }
                  { print }
                  ' $target_md >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
            else if string match -q a $input_user
                mkdir -p $obsidian_folder/$notes/archive
                set archive_file "$obsidian_folder/$notes/archive/Task Archive.md"
                touch $archive_file
                set cur_date (date +"%Y-%m-%dT%H:%M:%S")
                set cur_date (echo "archived: $cur_date")
                awk -v start="$i" -v out="$archive_file" -v date="$cur_date" '
                    BEGIN {
                        copying = 0
                        skipped = 0
                    }
                    {
                        if (!skipped && $0 ~ start) {
                            copying = 1
                            sub(/^T: /, "", $0)    # Remove "T: " from matched line
                            print $0 >> out
                            next
                        }

                        if (copying) {
                            if ($0 == "") {
                                print date >> out   # Add date instead of the empty line
                                copying = 0
                                skipped = 1
                                next
                            }
                            print $0 >> out
                            next
                        }

                        print
                    } ' $target_md >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
                echo "" >>$archive_file
            end
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
        else if string match -q Q $card_type
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
        else if echo "$user_input" | rg -q '^.{2,}$'
            brainstorming $user_input $i
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
        else if echo "$user_input" | rg -q '^.{2,}$'
            brainstorming $user_input $i
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

if string match 1 $the_key_activated
    set key_header (cat $tmp_key_contents | grep -P "^K:" )
    if cat $tmp_key_contents | rg -q "^key_cleared:"
        property_increase_exists $key_header $key_md key_cleared
    else
        property_increase_new $key_header $key_md key_cleared
    end
end
rm /tmp/file_contents_ready
