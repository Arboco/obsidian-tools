#! /usr/bin/env fish

function show_image
    set image $argv[1]

    set cols (tput cols)
    set lines (tput lines)
    set lines (math round $lines / 2)

    kitty +kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align left --scale-up --place {$cols}x{$lines}@0x0 "$image"
end

function just_thumbnail
    set file $argv[1]
    set temp_thumb (mktemp)
    set cleanup_list $cleanup_list $temp_thumb
    ffmpeg -y -ss 00:00:01 -i "$file" -frames:v 1 -update 1 -q:v 2 "$temp_thumb.jpg" >/dev/null 2>&1
    show_image $temp_thumb.jpg
    rm $temp_thumb
end

function true_multiline_block_ripgrep
    set temp_rg (mktemp)
    set card_type $argv[1]
    set key_string $argv[2]
    set only_key_header $argv[3]
    rg -U -oP --no-filename "$card_type:.*(?:\n(?!\s*\n).*)*?$key_string.*\$" $obsidian_folder/$notes >$temp_rg

    cat $temp_rg | while read line
        if echo $line | rg -q "($card_type:|$key_string)"
        else
            sed -i 1d $temp_rg
            continue
        end
        set puzzle_pieces $puzzle_pieces $line
        if not test -z $puzzle_pieces[2]
            if string match -q true $only_key_header
                set completed_puzzle "$puzzle_pieces[1]"
            else
                set completed_puzzle "$puzzle_pieces[2] | $puzzle_pieces[1]"
            end
            set -e puzzle_pieces
            echo $completed_puzzle
        end
    end

    rm $temp_rg
end

set script_dir (dirname (status --current-filename))
set parent_dir (dirname $script_dir)
set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set notes (ot_config_grab "NotesFolder")
set obsidian_resource (ot_config_grab "ObsidianResourceFolder")

if string match -q keyring $argv[2]
    true_multiline_block_ripgrep K "$argv[1]" true | sed 's/.*/\x1b[38;2;186;85;211m&\x1b[0m/'
    exit
end

if echo $argv[1] | rg -q "^\[.\]"; or echo $argv[1] | rg -q "^key"; or echo $argv[1] | rg -q "^cards"
    set select_key (echo $argv[1] | string split "|")[2]
    set select_key (echo $select_key | string trim -lr)
else
    set select_key (echo $argv[1] | string trim -r)
end
set key_md (rg -lF $select_key $obsidian_folder/$notes)
set base "$obsidian_folder/$notes"
set full "$key_md"

set relative (string replace -- "$base" "" -- $full)
if string match -q trophy $argv[2]
    set trophy_line (cat ~/.config/ortscripts/thekey_trophies.txt | rg "$select_key")
    set total_value (echo $trophy_line | rg -o '^[0-9]+')
    set total_value (echo " :$total_value")
    set bronze (echo $trophy_line | rg -oP "(?<=bronze=)[0-9]+")
    set bronze (echo "󱉏 :$bronze" | sed 's/.*/\x1b[38;5;208m&\x1b[0m/')
    set silver (echo $trophy_line | rg -oP "(?<=silver=)[0-9]+")
    set silver (echo "󱉏 :$silver" | sed 's/.*/\x1b[38;5;250m&\x1b[0m/')
    set gold (echo $trophy_line | rg -oP "(?<=gold=)[0-9]+")
    set gold (echo "󱉏 :$gold" | sed 's/.*/\x1b[38;5;220m&\x1b[0m/')
    set platinum (echo $trophy_line | rg -oP "(?<=platinum=)[0-9]+")
    set platinum (echo "󱉏 :$platinum" | sed 's/.*/\x1b[38;5;254m&\x1b[0m/')
    set diamond (echo $trophy_line | rg -oP "(?<=diamond=)[0-9]+")
    set diamond (echo " :$diamond" | sed 's/.*/\x1b[38;5;45m&\x1b[0m/')
    set obsidian (echo $trophy_line | rg -oP "(?<=obsidian=)[0-9]+")
    set obsidian (echo "󰂩 :$obsidian" | sed 's/.*/\x1b[38;5;93m&\x1b[0m/')

    echo "$total_value $bronze $silver $gold $platinum $diamond $obsidian"
end

awk -v search="$select_key" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $key_md >/tmp/img_treasure

echo -e "\e[38;2;120;120;120m$relative\e[0m"
set img_array (cat /tmp/img_treasure | grep -oP '(?<=(!|>)\[\[)[^\|?\]]*')
cat /tmp/img_treasure | awk '!/(!|>)\[\[/' \
    | sed '/^tags/ s/.*/\x1b[38;2;255;255;0m&\x1b[0m/' \
    | sed '/^keyring:/ s/.*/\x1b[38;2;186;85;211m&\x1b[0m/' \
    | sed '/^mp:/ s/.*/\x1b[38;2;186;85;211m&\x1b[0m/' \
    | sed '/^subtags:/ s/.*/\x1b[38;2;173;216;230m&\x1b[0m/' \
    | sed '/^c-tags:/ s/.*/\x1b[38;2;180;160;220m&\x1b[0m/' \
    | sed '/^f-tags:/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^f-links:/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^f-subtags:/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^f-string/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^remove:/ s/.*/\x1b[38;2;220;20;60m&\x1b[0m/' \
    | sed '/^a-subtags:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
    | sed '/^contains:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
    | sed '/^uuid:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
    | sed '/^mpid:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
    | sed '/^agenda:/ s/.*/\x1b[38;2;0;255;255m&\x1b[0m/' \
    | sed '/^family:/ s/.*/\x1b[38;2;200;255;200m&\x1b[0m/' \
    | sed '/^key/ s/.*/\x1b[38;2;152;255;152m&\x1b[0m/' \
    | sed '/^cards_cleared:/ s/.*/\x1b[38;2;152;255;152m&\x1b[0m/' \
    | sed '/^string/ s/.*/\x1b[38;2;255;165;0m&\x1b[0m/' \
    | sed '/^regex/ s/.*/\x1b[38;2;176;196;222m&\x1b[0m/' \
    | sed '/^skip:/ s/.*/\x1b[38;2;173;255;47m&\x1b[0m/' \
    | sed '/^timer:/ s/.*/\x1b[38;2;0;120;255m&\x1b[0m/' \
    | sed '/^cardstring/ s/.*/\x1b[38;2;70;130;180m&\x1b[0m/' \
    | sed '/^links:/ s/.*/\x1b[38;2;50;205;50m&\x1b[0m/' | glow
for img in $img_array
    set suffix (echo $img | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
    set img_path (find $obsidian_folder/$obsidian_resource -type f -name "$img")
    set img_basename (basename $img_path)
    if echo $img_basename | rg -q '(mp4|mkv|mov|avi|webm|flv|wmv)$'
        just_thumbnail $img_path
    else
        show_image $img_path
    end
end

rm /tmp/img_treasure
