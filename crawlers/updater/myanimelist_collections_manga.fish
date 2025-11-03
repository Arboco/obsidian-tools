#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_rel (rg -l "myanimelist" $obsidian/$note/*)
#set list_rel (rg -l "myanimelist" $PWD/*.md)
for file in $list_rel
    echo $file

    if rg "  - manga" $file
        set html /tmp/myanime.html
        set url (rg "https://myanimelist.net.*" $file)
        set url (string split " " $url)[2]

        set -e authors
        set authors
        set loop_counter 0
        while test -z $authors
            curl $url >$html
            set authors (rg -oP '(?<=<a href="/people/)[^<]*' $html | sort -u)
            echo $authors
            if test $loop_counter -gt 0
                sleep 5
            end
            set loop_counter (math $loop_counter + 1)
        end

        function string_sanitizer
            string replace -a '&amp;' '&' -- "$argv[1]"
        end

        set genres (rg --multiline --multiline-dotall '<span class="dark_text">Genres?:</span>.*?</div>' $html)
        set genres (echo $genres | rg -oP '(?<=title=")[^"]*')
        sed -i "/^url:/a\\genres:" $file
        for i in $genres
            sed -i "/^genres:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set themes (rg --multiline --multiline-dotall '<span class="dark_text">Themes?:</span>.*?</div>' $html)
        set themes (echo $themes | rg -oP '(?<=title=")[^"]*')
        sed -i "/^url:/a\\themes:" $file
        for i in $themes
            sed -i "/^themes:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set demographic (rg --multiline --multiline-dotall '<span class="dark_text">Demographic?:</span>.*?</div>' $html)
        set demographic (echo $demographic | rg -oP '(?<=title=")[^"]*')
        sed -i "/^url:/a\\demographic:" $file
        for i in $demographic
            sed -i "/^demographic:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set serialization (rg --multiline --multiline-dotall '<span class="dark_text">Serialization?:</span>.*?</div>' $html)
        set serialization (echo $serialization | rg -oP '(?<=title=")[^"]*')
        sed -i "/^demographic:/i\\serialization:" $file
        for i in $serialization
            sed -i "/^serialization:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set authors (rg -oP '(?<=<a href="/people/)[^<]*' $html | sort -u)
        set trim_list
        for i in $authors
            set trim (string split '>' $i)[2]
            set trim (string replace ',' '' $trim)
            set trim_list $trim_list $trim
        end
        set authors $trim_list
        sed -i "/^url:/a\\authors:" $file
        for i in $authors
            sed -i "/authors:/a\\  - \"\[\[$i\]\]\"" $file
        end

        rm $html
    end
end
