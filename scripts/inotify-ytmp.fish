#! /usr/bin/env fish

set obsidian_md "$argv[1]"
set title "$argv[2]"
set a_path (cat $obsidian_md | grep 'path:')
set a_path (echo $a_path | grep -oP '(?<=path: ).*$')
set folder_title (echo $title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
set screenshot_folder "/home/anon/ortup/important/notes/ortvault/resources/mindpalace/youtube/$folder_title"

if test -d $screenshot_folder
    echo "folder exists"
else
    mkdir $screenshot_folder
end

set counter 0

inotifywait -m -e create --format '%w%f' ~/Downloads/ | while read FILE
    sleep 1
    set timestamp (date +%s)
    if test -e "$FILE"
        if test -z (ls -A $screenshot_folder)
            echo --- >>$obsidian_md
            echo "tags:" >>$obsidian_md
            echo "country:" >>$obsidian_md
            echo "city:" >>$obsidian_md
            mv "$FILE" $screenshot_folder/$folder_title-cover.jpg
            echo -e "cover-img: \"[[$folder_title-cover.jpg]]\"" >>$obsidian_md
            echo "cssclasses:" >>$obsidian_md
            echo "  - img-grid" >>$obsidian_md
            echo "  - img-max" >>$obsidian_md
            echo "obsidianUIMode: preview" >>$obsidian_md
            echo --- >>$obsidian_md
        else
            mv "$FILE" $screenshot_folder/$folder_title$timestamp.jpg
            echo -e "![[$folder_title$timestamp.jpg]]" >>$obsidian_md
            set counter (math $counter + 1)
            if test $counter = 8
                echo -e "" >>$obsidian_md
                set counter 0
            end
        end
    end
end
