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

cat /tmp/yaml-block | sed -e /url/d -e /cover-img/d -e /score/d -e /---/d |
    awk ' /cssclasses/ { deleting=1; next } deleting && /^[A]/ { deleting=0 } !deleting ' |
    awk ' /tags/ { deleting=1; next } deleting && /^[A]/ { deleting=0 } !deleting ' | bat --language=Markdown
echo ""
set img_filename (cat /tmp/yaml-block | grep "cover-img" | grep -o "\[\[.*\]\]" | sed 's/\[//g' | sed 's/\]//g')
set img_path (find $obsidian_folder/$obsidian_resource -type f -name "$img_filename")
show_image $img_path

rm /tmp/yaml-block
