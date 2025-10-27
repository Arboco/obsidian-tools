#! /usr/bin/env fish

set html "/tmp/myanime.html"

for file in *.md
    echo "Processing $file"
    if cat $file | grep 'jap_title: ..'
    else
        sed -i '/year:/d' "$file"
        sed -i '/date:/d' "$file"
        sed -i '/jap_title:/d' "$file"
    end
end

echo done

for file in (find . -type f -name "*.md")
    if cat $file | grep 'jap_title: ..'
    else
        echo "Processing $file"
        set url (cat $file | grep -oP '(?<=url: ).*$')
        curl -s -A Mozilla/5.0 "(X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0" "$url" >$html
        set jap_title (cat $html | grep -oP '(?<=Japanese:</span> )[^<]*')
        set date (cat $html | grep -oP '... .?[0-9]+, [0-9]{4}' | head -n 1)
        set date (date -d $date +"%Y-%m-%d")

        sed -i "/^title:/a\\jap_title: $jap_title" "$file"
        sed -i "/^jap_title:/a\\date: $date" "$file"

        rm $html
    end
end
