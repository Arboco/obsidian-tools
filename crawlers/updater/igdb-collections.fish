#! /usr/bin/env fish

set obsidian (ot_config_grab "ObsidianMainFolder")
set note (ot_config_grab "NotesFolder")
set list_igdb (rg -l "igdb" $obsidian/$note/*)
#set list_igdb (rg -l "igdb" $PWD/*)
for file in $list_igdb
    echo $file

    set html /tmp/igdb.html
    set url (rg "https://www.igdb.com.*" $file)
    set url (string split " " $url)[2]
    node fetch-page.js "$url" >/tmp/igdb.html

    function string_sanitizer
        string replace -a '&amp;' '&' -- "$argv[1]"
    end

    if not rg "engine:" $file
        sed -i "/^url:/i\\engine:" $file
        set engines (rg -oP '(?<=href="/game_engines/)[^<]*' $html | sort -u)
        set clean_engines
        for i in $engines
            set temp_engines (echo $i | string split '>')[2]
            set temp_engines (string_sanitizer $temp_engines)
            if echo $temp_engines | rg "target=\"_blank"
            else
                set clean_engines $clean_engines $temp_engines
            end
        end
        for i in $clean_engines
            sed -i "/^engine:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

    if not rg "genres:" $file
        sed -i "/^title:/a\\genres:" $file
        set genres (rg -oP '(?<=href="/genres/)[^<]*' $html | sort -u)
        set clean_genre
        for i in $genres
            set temp_genre (echo $i | string split '>')[2]
            set temp_genre (string_sanitizer $temp_genre)
            if echo $temp_genre | rg "target=\"_blank"
            else
                set clean_genre $clean_genre $temp_genre
            end
        end
        for i in $clean_genre
            sed -i "/^genres:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

    if not rg "themes:" $file
        sed -i "/^title:/a\\themes:" $file
        set themes (rg -oP '(?<=href="/themes/)[^<]*' $html | sort -u)
        set clean_themes
        for i in $themes
            set temp_themes (echo $i | string split '>')[2]
            set temp_themes (string_sanitizer $temp_themes)
            if echo $temp_themes | rg "target=\"_blank"
            else
                set clean_themes $clean_themes $temp_themes
            end
        end
        for i in $clean_themes
            sed -i "/^themes:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

    if not rg "publisher:" $file
        sed -i "/^title:/a\\publisher:" $file
        set publisher (rg -oP '(?<=Publishers</h6><a class=)[^<]*' $html | sort -u)
        set clean_publisher
        for i in $publisher
            if echo $i | rg 'target="_blank'
            else
                set temp_publisher (echo $i | string split '>')[2]
                set temp_publisher (string_sanitizer $temp_publisher)
                set clean_publisher $clean_publisher $temp_publisher
            end
        end
        for i in $clean_publisher
            sed -i "/^publisher:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

    if not rg "developer:" $file
        sed -i "/^title:/a\\developer:" $file
        set developers (rg -oP '(?<=Main Developers</h6><a class=)[^<]*' $html | sort -u)
        set clean_developers
        for i in $developers
            if echo $i | rg 'target="_blank'
            else
                set temp_developer (echo $i | string split '>')[2]
                set temp_developer (string_sanitizer $temp_developer)
                set clean_developers $clean_developers $temp_developer
            end
        end
        for i in $clean_developers
            sed -i "/^developer:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

    if not rg "series:" $file
        sed -i "/^title:/a\\series:" $file
        set franchises (rg -oP '(?<=href="/franchises/)[^<]*' $html | sort -u)
        set clean_franchises
        for i in $franchises
            set temp_franchises (echo $i | string split '>')[2]
            set temp_franchises (string_sanitizer $temp_franchises)
            if echo $temp_franchises | rg "target=\"_blank"
            else
                set clean_franchises $clean_franchises $temp_franchises
            end
        end
        for i in $clean_franchises
            sed -i "/^series:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

    if not rg "collections:" $file
        sed -i "/^series:/i\\collections:" $file
        set collections (rg -oP '(?<=href="/collections/)[^<]*' $html | sort -u)
        set clean_collections
        for i in $collections
            set temp_collections (echo $i | string split '>')[2]
            set temp_collections (string_sanitizer $temp_collections)
            if echo $temp_collections | rg "target=\"_blank"
            else
                set clean_collections $clean_collections $temp_collections
            end
        end
        for i in $clean_collections
            sed -i "/^collections:/a\\  - \"\[\[$i\]\]\"" $file
        end
    end

end
