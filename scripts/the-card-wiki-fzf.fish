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

    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align=left "$tmpimg"

    sleep 0.3
    rm $tmpimg
end

set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set notes (ot_config_grab "NotesFolder")
set obsidian_resource (ot_config_grab "ObsidianResourceFolder")

set select_key (echo $argv[1] | string trim -r)
set key_md (rg -l $select_key $obsidian_folder/$notes)

awk -v search="$select_key" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $key_md >/tmp/img_treasure
set img_array (cat /tmp/img_treasure | grep -oP "(?<=!\[\[)[^\|?\]]*")
cat /tmp/img_treasure | sed "/!\[\[/d" | sed 's/```shell//g' | sed 's/```//g' | bat --style=plain --color=always --language=fish | glow
for img in $img_array
    set suffix (echo $img | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
    set img_path (find $obsidian_folder/$obsidian_resource -type f -name "$img")
    icat_half $img_path "$suffix"
end

rm /tmp/img_treasure
