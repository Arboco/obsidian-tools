#! /usr/bin/env fish

set html "/tmp/dlsite.html"

for file in *.md
    echo "Processing $file"
    sed -i '/year:/d' "$file" # Example command
end

echo done

for file in (find . -type f -name "*.md")
    if cat $file | grep 'genre:'
    else
        echo "Processing $file"
        set url (cat $file | grep -oP '(?<=url: ).*$')
        curl -s -A Mozilla/5.0 "(X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0" "$url" >$html

        set circle (cat $html | grep "\[.*\] | DLsite" | head -n 1)
        set circle (echo $circle | grep -oP "(?<=\[)[^]]*")
        set work_type (cat $html | grep 'work_type/')
        set work_type (echo $work_type | grep -oP '(?<=title=")[^"]*' | head -n 1)
        set date (cat $html | grep -oP '(?<=\"regist_date\":\")[^"]*')
        set date (echo $date | sed 's;\\\/;-;g')
        set genre_array (cat $html | grep '\.genre')
        set num 1
        for i in $genre_array
            set genre_name_array[$num] (echo $i | grep -oP '(?<=.genre">)[^<]*')
            set num (math $num +1)
        end

        set img_folder /home/anon/ortup/important/notes/ortvault/resources/game/cover/doujin
        set sample_array (cat $html | grep -oP '(?<=<div data-src="//).*img_smp[0-9].jpg')
        wget -P "$img_folder/" $sample_array
        set rj (cat $file | grep -oP '(?<=code: ).*$')

        set num 1
        for i in $sample_array
            set img_name_array[$num] (echo $i | grep -oP '(?<=0/)R.*_img.*')
            set num (math $num +1)
        end

        sed -i "/^title:/a\\circle: $circle" "$file"
        sed -i "/^circle:/a\\type: $work_type" "$file"
        sed -i "/^status:/a\\date: $date" "$file"
        sed -i "/^date:/a\\obsidianUIMode: preview" "$file"
        sed -i "/^code:/a\\genre:" "$file"

        for i in $genre_name_array
            sed -i "/^genre:/a\\  - $i" "$file"
        end

        echo "" >>$file
        echo "# Preview" >>$file
        echo "![[$rj.jpg]]" >>$file
        echo "" >>$file
        for i in $img_name_array
            echo "![[$i]]" >>$file
        end
        echo "# Main" >>$file

        set -e sample_array
        set -e genre_array
        set -e genre_name_array
        set -e img_name_array
        rm $html
    end
end
