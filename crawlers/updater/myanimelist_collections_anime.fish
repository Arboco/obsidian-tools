#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_rel (rg -l "myanimelist" $obsidian/$note/*)
#set list_rel (rg -l "myanimelist" $PWD/*.md)
for file in $list_rel
    echo $file

    if rg "  - anime" $file
        set html /tmp/myanime.html
        set url (rg "https://myanimelist.net.*" $file)
        set url (string split " " $url)[2]

        set -e genres
        set genres
        set loop_counter 0
        while test -z $genres
            curl $url >$html
            set genres (rg --multiline --multiline-dotall '<span class="dark_text">Genres?:</span>.*?<span itemprop="genre" style="display: none">.*?</div>' $html)
            set genres (echo $genres | rg -oP '(?<=<span itemprop="genre" style="display: none">)[^<]*')
            if test $loop_counter -gt 0
                sleep 5
            end
            set loop_counter (math $loop_counter + 1)
        end

        function string_sanitizer
            string replace -a '&amp;' '&' -- "$argv[1]"
        end

        set premier (rg -oP -m 1 '(?<=<a href="https://myanimelist.net/anime/season/)[^<]*' $html)
        set premier (string split '>' $premier)[2]
        sed -i "/^url:/a\\premiered: \"\[\[$premier\]\]\"" $file

        set studio (rg -oP '(?<=class="information studio author"><a href="/anime/producer/)[^<]*' $html)
        set studio (string split '>' $studio)[2]
        sed -i "/^url:/a\\studio:" $file
        for i in $studio
            sed -i "/^studio:/a\\  - \"\[\[$i\]\]\"" $file
        end

        sed -i "/^url:/a\\genres:" $file
        for i in $genres
            sed -i "/^genres:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set themes (rg --multiline --multiline-dotall '<span class="dark_text">Themes?:</span>.*?<span itemprop="genre" style="display: none">.*?</div>' $html)
        set themes (echo $themes | rg -oP '(?<=<span itemprop="genre" style="display: none">)[^<]*')
        sed -i "/^url:/a\\themes:" $file
        for i in $themes
            sed -i "/^themes:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set demographic (rg --multiline --multiline-dotall '<span class="dark_text">Demographics?:</span>.*?<span itemprop="genre" style="display: none">.*?</div>' $html)
        set demographic (echo $demographic | rg -oP '(?<=<span itemprop="genre" style="display: none">)[^<]*')
        sed -i "/^url:/a\\demographic:" $file
        for i in $demographic
            sed -i "/^demographic:/a\\  - \"\[\[$i\]\]\"" $file
        end

        set source (rg --multiline --multiline-dotall '<span class="dark_text">Sources?:</span>.*?<a href="https://myanimelist.net/anime/.*?</div>' $html)
        set source (echo $source | rg -o 'related_entries">.*</a>' | rg -o ' .* ' | string trim -lr)
        sed -i "/^demographic:/i\\source:" $file
        for i in $source
            sed -i "/^source:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end
end
