#! /usr/bin/env fish

function show_image
    set image $argv[1]

    set cols (tput cols)
    set lines (tput lines)
    set lines (math round $lines / 2)

    kitty +kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align left --scale-up --place {$cols}x{$lines}@0x0 "$image"
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

set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set notes (ot_config_grab "NotesFolder")
set obsidian_resource (ot_config_grab "ObsidianResourceFolder")

if echo $argv[1] | rg -q ".md"
    set md_title (echo $argv[1] | string split "|")[1]
    set md_title (basename $md_title)
    set md_title (echo $md_title | string trim -lr)
else if string match -q mp $argv[2]
    set md_title "$argv[1].md"
else
    set md_title (echo $argv[1] | string split '"')[2]
    set md_title "$md_title.md"
end

set key_md (find $obsidian_folder/$notes -type f -name "$md_title")

awk -v search="---" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $key_md >/tmp/yaml-block

set img_filename (cat /tmp/yaml-block | grep "cover-img" | grep -o "\[\[.*\]\]" | sed 's/\[//g' | sed 's/\]//g')
set img_path (find $obsidian_folder/$obsidian_resource -type f -name "$img_filename")
show_image $img_path
echo ""
echo ""

if not string match -q mp $argv[2]
    cat /tmp/yaml-block | sed -e /url/d -e /cover-img/d -e /score/d -e /---/d |
        awk '/^cssclasses:/ {d=1; next} d && /^[A-Za-z]/ {d=0} !d' |
        awk '/^tags:/ {d=1; next} d && /^[A-Za-z]/ {d=0} !d' | bat --language=Markdown
end

if string match -q mp $argv[2]
    true_multiline_block_ripgrep K "$argv[1]" true | sed 's/.*/\x1b[38;2;135;206;250m&\x1b[0m/'
end

rm /tmp/yaml-block
