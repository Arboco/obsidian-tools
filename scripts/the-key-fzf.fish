#! /usr/bin/env fish

function show_image
    set image $argv[1]

    set cols (tput cols)
    set lines (tput lines)
    set lines (math round $lines / 2)

    kitty +kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align left --scale-up --place {$cols}x{$lines}@0x0 "$image"

end

set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set notes (ot_config_grab "NotesFolder")
set obsidian_resource (ot_config_grab "ObsidianResourceFolder")

if echo $argv[1] | rg "^\[.\]"; or echo $argv[1] | rg "^key"; or echo $argv[1] | rg "^cards"
    set select_key (echo $argv[1] | string split "|")[2]
    set select_key (echo $select_key | string trim -lr)
else
    set select_key (echo $argv[1] | string trim -r)
end
set key_md (rg -l $select_key $obsidian_folder/$notes)

awk -v search="$select_key" '
      index($0, search) {flag=1}
      flag {print}
      /^$/ && flag {flag=0}
                              ' $key_md >/tmp/img_treasure
set img_array (cat /tmp/img_treasure | grep -oP "(?<=(!|>)\[\[)[^\|?\]]*")
cat /tmp/img_treasure | sed -E '/!|>\[\[/d' \
    | sed '/^tags:/ s/.*/\x1b[38;2;255;255;0m&\x1b[0m/' \
    | sed '/^keyring:/ s/.*/\x1b[38;2;186;85;211m&\x1b[0m/' \
    | sed '/^subtags:/ s/.*/\x1b[38;2;173;216;230m&\x1b[0m/' \
    | sed '/^c-tags:/ s/.*/\x1b[38;2;180;160;220m&\x1b[0m/' \
    | sed '/^f-tags:/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^f-links:/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^f-subtags:/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^f-string/ s/.*/\x1b[38;2;255;100;100m&\x1b[0m/' \
    | sed '/^remove:/ s/.*/\x1b[38;2;220;20;60m&\x1b[0m/' \
    | sed '/^a-subtags:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
    | sed '/^contains:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
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
    show_image $img_path
end

rm /tmp/img_treasure
