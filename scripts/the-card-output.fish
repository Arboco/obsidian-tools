#! /usr/bin/env fish

set script_dir (realpath (status dirname))
set parent_dir (dirname (status --current-filename))
set parent_dir (dirname $parent_dir)
set cleanup_list

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

function image_in_corner
    set image $argv[1]
    set cols (tput cols)
    set lines (tput lines)

    set img_width 20
    set img_height 10

    set x (math "$cols - $img_width")
    set y (math "floor(($lines - $img_height) / 2)")

    kitty +kitten icat \
        --clear \
        --transfer-mode=memory \
        --unicode-placeholder \
        --stdin=no \
        --place {$img_width}x{$img_height}@{$x}x{$y} \
        "$image"
end

function icat_half
    set image $argv[1]
    set suffix (echo "$image" | rg -oP '\.[^.\\/]+$')
    set temp_image (mktemp --suffix $suffix)
    set cleanup_list $cleanup_list $temp_image

    set term_size (kitty icat --print-window-size | string split "x")
    set img_size (identify -format "%w %h" $image | string split " ")
    set max_wanted_height (math round $term_size[2] / 2)
    if test $img_size[2] -gt $max_wanted_height
        magick "$image" -resize x$max_wanted_height $temp_image
        kitty +kitten icat --transfer-mode=memory --stdin=no --align=left "$temp_image"
    else
        kitty +kitten icat --transfer-mode=memory --stdin=no --align=left "$image"
    end
    rm $temp_image
end

function just_thumbnail
    set file $argv[1]
    set temp_thumb (mktemp)
    set cleanup_list $cleanup_list $temp_thumb
    ffmpeg -y -ss 00:00:01 -i "$file" -frames:v 1 -update 1 -q:v 2 "$temp_thumb.jpg" >/dev/null 2>&1
    icat_half $temp_thumb.jpg
    rm $temp_thumb
end

function property_custom_increment
    set search_key $argv[1]
    set end_md $argv[2]
    set property $argv[3]
    set increment $argv[4]
    awk -v key="$search_key" -v property="$property" -v inc="$increment" '
        BEGIN {
            RS = ""
            ORS = "\n\n"
        }
        {
            if ($0 ~ key && !updated) {
                regex = property ": [0-9]+"
                if (match($0, regex)) {
                    split(substr($0, RSTART, RLENGTH), a, " ")
                    new_val = a[2] + inc
                    sub(regex, property ": " new_val)
                }
                updated = 1
            }
            print
        } ' "$end_md" >"$end_md.tmp" && mv "$end_md.tmp" "$end_md"
end

function property_increase_new
    set search_key $argv[1]
    set end_md $argv[2]
    set property $argv[3]
    set value $argv[4]
    awk -v key="$search_key" -v property="$property" -v val="$value" '
        {
            print
            if ($0 ~ key) {
                print property ": " val
            }
        }' "$end_md" >"$end_md.tmp" && mv "$end_md.tmp" "$end_md"
end

function brainstorming
    set trans_input $argv[1]
    set key_title $argv[2]
    echo $trans_input
    while not string match "" $trans_input
        awk -v search_str="$key_title" -v append="$trans_input" '
            BEGIN { RS=""; ORS="\n\n" }
            {
                if ($0 ~ search_str) {
                    $0 = $0 "\n" append
                }
                print
            } ' "$target_md" >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
        set trans_input (gum input --placeholder "Escape by pressing empty Enter, anything else gets added to the block")
        echo $trans_input
    end
end

set mpv_is_running 0

set cards_done 0

for i in (cat /tmp/the-card_final_sorted_array)
    if string match -q true $want_to_exit
        break
    end
    set i_trim (string trim -r -- $i)
    set trimmed (string split '`' -- $i_trim)[1]
    set target_md (rg -lF "$trimmed" $obsidian_folder/$notes)

    clear
    set card_type (echo "$i" | grep -o "^.")

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

    set permit_obtained false
    set once_is_enough false
    set card_content /tmp/file_contents_ready
    while string match -q false $permit_obtained
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
                                  ' $target_md >$card_content

        # Getting and setting up all data for data and s-value 
        if cat $card_content | rg -q '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'
            set card_date (cat $card_content | rg -o '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
            set card_has_date true
        else
            set card_has_date false
        end

        if cat $card_content | rg -q S-Value
            set s_value (cat $card_content | rg -o 'S-Value.*' | rg -oP '.?[0-9]')
            set card_has_svalue true
        else
            set card_has_svalue false
        end

        set image_list /tmp/image-list-the-card-output
        cat $card_content | grep -oP "(?<=(!|>)\[\[)[^\|?\]]*" >$image_list

        if string match -q true $mindpalace_format
            set first_image (head -n 1 $image_list)
            set file_path (find $obsidian_folder/$obsidian_resource -type f -name "$first_image")
            icat_half $file_path
            echo ""
            sed -i 1d $image_list
            gum input --placeholder "Press enter to continue..."
        end

        if string match -q Q $card_type
            echo "$i" | perl -pe 's/`[^`]*`//g' | sed -E 's/#[0-9]+//g' | glow
            gum input --placeholder "Press enter to continue..."
            clear
            echo ""
        end

        set tags (cat $card_content | rg -o '#[A-Za-z0-9_\\/]+')
        set mpid_image_shown false

        if string match -q T $card_type; or string match -q Q $card_type; or string match -q I $card_type
            cat $card_content | awk '!/(!|>)\[\[|`/' \
                | awk '{ gsub(/#[A-Za-z0-9_\/]+/, ""); print }' \
                | sed 's/^>//g' \
                | sed '/!\[/d' \
                | sed '/^mpid:/d' \
                | sed '/^---/d' \
                | sed '/^I:/ s/.*/\x1b[38;2;173;216;230m&\x1b[0m/' \
                | sed '/^T:/ {/second_counter/ s/.*/\x1b[38;2;255;165;0m&\x1b[0m/}' \
                | sed '/^Q:/ s/.*/\x1b[38;2;152;255;152m&\x1b[0m/' \
                | sed '/^agenda:/ s/.*/\x1b[38;2;0;255;255m&\x1b[0m/' \
                | perl -pe 's/`[^`]*`//g' \
                | perl -pe 's/(#\w+)/"\e[38;2;255;255;0m$1\e[0m"/ge' \
                | fold -s -w 90 | bat -p --language=Markdown | sed 's/^/    /'
        else
            cat $card_content | sed "/!\[\[/d" | sed 's/```shell//g' | sed 's/```//g' | bat --wrap auto --color=always --language=fish
        end
        cat $image_list | while read tre
            set suffix (echo $tre | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
            set file_path (find $obsidian_folder/$obsidian_resource -type f -name "$tre")
            if echo $file_path | rg -q '(mp3|aac|flac|wav|alac|ogg|aiff|dsd)$'
                mpv --no-video $file_path >/dev/null &
                set mpid $last_pid
            else if echo $file_path | rg -q '(mp4|mkv|mov|avi|webm|flv|wmv)$'
                if string match -q true $generate_thumbnail
                    just_thumbnail $file_path
                else
                    if test $mpv_is_running -eq 0
                        mpv-small &
                    end
                    echo '{ "command": ["loadfile", "'"$file_path"'"] }' | socat - /tmp/mpv-socket
                end
            else if cat $card_content | rg -q "^mpid:"; and string match -q false $mpid_image_shown; and string match -q false $mindpalace_format
                image_in_corner $file_path
                set mpid_image_shown true
            else
                icat_half $file_path
            end
        end

        if cat $card_content | rg -q "#bronze"
            set trophy (echo "󱉏 B" | sed 's/.*/\x1b[38;5;208m&\x1b[0m/')
        else if cat $card_content | rg -q "#silver"
            set trophy (echo "󱉏 S" | sed 's/.*/\x1b[38;5;250m&\x1b[0m/')
        else if cat $card_content | rg -q "#gold"
            set trophy (echo "󱉏 G" | sed 's/.*/\x1b[38;5;220m&\x1b[0m/')
        else if cat $card_content | rg -q "#platinum"
            set trophy (echo "󱉏 P" | sed 's/.*/\x1b[38;5;254m&\x1b[0m/')
        else if cat $card_content | rg -q "#diamond"
            set trophy (echo " D" | sed 's/.*/\x1b[38;5;45m&\x1b[0m/')
        else if cat $card_content | rg -q "#obsidian"
            set trophy (echo "󰂩 O" | sed 's/.*/\x1b[38;5;93m&\x1b[0m/')
        end

        if cat $card_content | rg -q "#readmore"
            set readmore "󰑇 "
        end

        set source $(basename $target_md | sed 's/.*/\x1b[38;5;240m&\x1b[0m/')
        echo ""
        echo "$source $trophy $readmore" | sed 's/^/ /'
        echo $tags | sed 's/.*/\x1b[38;5;240m&\x1b[0m/' | sed 's/^/ /'
        echo ""

        set -e trophy
        set -e readmore

        if string match -q T $card_type
            mkdir -p $obsidian_folder/$obsidian_resource/drill_evidence
            set input_user (gum input --placeholder "s - Skip | r - Revise | o - Open File | c - Complete Task | 0 - Exit")
            if string match -q s $input_user
                if cat $card_content | rg -q "^skipped:"
                    property_custom_increment $i $target_md skipped 1
                else
                    property_increase_new $i $target_md skipped 1
                end
                set permit_obtained true
            else if string match o $input_user
                clear
                setsid bash -c 'obsidian "obsidian://'"$target_md"'" >/dev/null 2>&1' </dev/null &>/dev/null &
            else if string match r $input_user
                clear
                kitty nvim +/"$i" $target_md
            else if echo "$input_user" | rg -q '^.{2,}$'
                brainstorming $input_user $i
            else if string match -q 0 $input_user
                if cat $card_content | rg -q "^skipped:"
                    property_increase_exists $i $target_md skipped
                else
                    property_increase_new $i $target_md skipped
                end
                set want_to_exit true
                break
            else
                if cat $card_content | rg -q "^skipped:"
                    property_increase_exists $i $target_md skipped
                else
                    property_increase_new $i $target_md skipped
                end
                set permit_obtained true
            end

            if cat $card_content | rg "^skipped: 9"
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
                    set permit_obtained true
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
                    set permit_obtained true
                end
            end

        end

        if string match -q I $card_type
            if string match -q false $once_is_enough
                gum spin --spinner moon --title "Get inspired..." -- sleep $second_counter
                set once_is_enough true
            end
        end

        echo ""
        if string match -q W $card_type
            set user_input (gum input --placeholder "0 - Exit | r - Revise | o - Open File")
            if string match 1 $user_input; or string match 2 $user_input; or string match d $user_input
                set user_input ""
            end
        else if string match -q I $card_type
            set user_input (gum input --placeholder "d - Date | 0 - Exit | r - Revise | o - Open File")
            if string match 1 $user_input; or string match 2 $user_input
                set user_input ""
            end
        else if string match -q Q $card_type
            set user_input (gum input --placeholder "1 - Correct | 2 - Wrong | 0 - Exit | r - Revise | o - Open File")
            if string match d $user_input
                set user_input ""
            end
        else if string match -q I $card_type
            set user_input (gum input --placeholder "d - Date | 0 - Exit | r - Revise | o - Open File")
            if string match 1 $user_input; or string match 2 $user_input
                set user_input ""
            end
        end

        if string match -q 0 $user_input
            set want_to_exit true
            break
        end

        if string match r $user_input
            clear
            kitty nvim +/"$i" $target_md
        end

        if string match o $user_input
            clear
            setsid bash -c 'obsidian "obsidian://'"$target_md"'" >/dev/null 2>&1' </dev/null &>/dev/null &
        end

        # Removing old date and svalue
        if echo $i | rg "$card_type.*`"
            set cleaned_i (echo $i | awk '{sub(/`.*/, ""); print}')
            awk -v target="$i" '
                {
                    if ($0 == target) {
                        sub(/`.*$/, "", $0)
                    }
                    print
                }' $target_md >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
            set i $cleaned_i
        end

        set new_date (date +"%Y-%m-%d %H:%M:%S")

        if string match 1 $user_input; or string match 2 $user_input
            clear
            if string match 1 $user_input
                set s_value (math $s_value + 1)
            else
                set s_value (math $s_value - 1)
            end
            set meta_append "`$new_date S-Value: $s_value`"
            awk -v target="$i" -v append_str=" $meta_append" '
              {
                  if ($0 == target) {
                      sub(/[[:space:]]+$/, "", $0)     # Trim trailing whitespace
                      $0 = $0 append_str               # Append the string
                  }
                  print
              } ' $target_md >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
            set permit_obtained true
        end

        if string match d $user_input
            clear
            set meta_append "`$new_date`"
            awk -v target="$i" -v append_str=" $meta_append" '
                {
                    if ($0 == target) {
                        sub(/[[:space:]]+$/, "", $0)     # Trim trailing whitespace
                        $0 = $0 append_str               # Append the string
                    }
                    print
                } ' $target_md >"$target_md.tmp" && mv "$target_md.tmp" "$target_md"
            set permit_obtained true
        end

        if echo "$user_input" | rg -q '^.{2,}$'
            brainstorming $user_input $i
        end
    end
    if string match -q true $permit_obtained
        set cards_done (math $cards_done + 1)
    end
    set -e target_md
end
if not test -z $mpid
    kill $mpid
end

if not test -z $mpv_pid
    kill $mpv_pid
end

if string match -q 1 $the_key_activated
    set key_header (cat $tmp_key_contents | grep -P "^K:" )
    if cat $tmp_key_contents | rg -q "^cards_cleared:"
        property_custom_increment $key_header $key_md cards_cleared $cards_done
    else
        property_increase_new $key_header $key_md cards_cleared $cards_done
    end
    set key_date (date +"%Y-%m-%d %H:%M:%S")
    sed -i "s/.*$select_key_trim.*/$select_key_trim `$key_date`/g" $key_md
end

for i in $cleanup_list
    if test -e $i
        rm $i
    end
end

rm $card_content
