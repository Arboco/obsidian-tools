#! /usr/bin/env fish

function icat_half
    set image $argv[1]

    set cols (tput cols)
    set lines (tput lines)
    set lines (math round $lines / 2)

    kitty +kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align left --scale-up --place {$cols}x{$lines}@0x0 "$image"
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
    icat_half $img_path
end

rm /tmp/img_treasure
