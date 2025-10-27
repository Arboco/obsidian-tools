#! /usr/bin/env fish

set html "/tmp/vndb.html"

for file in *.md
    echo "Processing $file"
    sed -i '/year:/d' "$file"  # Example command
end

echo "done"


for file in (find . -type f -name "*.md")
    echo "Processing $file"
    set url (cat $file | grep -oP '(?<=url: ).*$')
    curl -s -A Mozilla/5.0 "(X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0" "$url" > $html  


    set date (cat $html | grep -oP '(?<="tc1">)[^<]*' | head -n 1)
    set developer (cat $html | grep -oP '(?<=">)[^<]*(?=</a></td>)' | head -n 1)

    sed -i "/^status:/a\\date: $date" "$file"
    sed -i "/^title:/a\\developer: \"$developer\"" "$file"
end



