#! /usr/bin/env fish

set obsidian_folder (ot_config_grab "ObsidianMainFolder")
set notes (ot_config_grab "NotesFolder")
set obsidian_resource (ot_config_grab "ObsidianResourceFolder")

if echo $argv[1] | rg "^\[.\]"
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
    | sed '/^subtags:/ s/.*/\x1b[38;2;173;216;230m&\x1b[0m/' \
    | sed '/^c-tags:/ s/.*/\x1b[38;2;180;160;220m&\x1b[0m/' \
    | sed '/^f-tags:/ s/.*/\x1b[38;2;255;0;0m&\x1b[0m/' \
    | sed '/^f-links:/ s/.*/\x1b[38;2;255;0;0m&\x1b[0m/' \
    | sed '/^f-subtags:/ s/.*/\x1b[38;2;255;0;0m&\x1b[0m/' \
    | sed '/^f-string/ s/.*/\x1b[38;2;255;0;0m&\x1b[0m/' \
    | sed '/^a-subtags:/ s/.*/\x1b[38;2;255;105;180m&\x1b[0m/' \
    | sed '/^origin:/ s/.*/\x1b[38;2;0;255;255m&\x1b[0m/' \
    | sed '/^family:/ s/.*/\x1b[38;2;200;255;200m&\x1b[0m/' \
    | sed '/^string/ s/.*/\x1b[38;2;255;165;0m&\x1b[0m/' \
    | sed '/^links:/ s/.*/\x1b[38;2;50;205;50m&\x1b[0m/' | glow
for img in $img_array
    set suffix (echo $img | rg -o '[^.\\\\/:*?"<>|\\r\\n]+$')
    set img_path (find $obsidian_folder/$obsidian_resource -type f -name "$img")
    #icat_half $img_path "$suffix"
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --align=left $img_path
end

rm /tmp/img_treasure
