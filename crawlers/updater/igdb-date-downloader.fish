#! /usr/bin/env fish
#for file in *.md
#    echo "Processing $file"
#    sed -i '/year:/d' "$file"  # Example command
#end
#
#echo "done"


for file in (find . -type f -name "*.md")
    echo "Processing $file"
    set url (cat $file | grep -oP '(?<=url: ).*$')
    node fetch-page.js "$url" > /tmp/date-replenisher.html
    set raw_date (cat /tmp/date-replenisher.html | grep -oP '(?<=MuiTypography-h6">)[^ ]*' | head -n 1)
    set month (echo $raw_date | grep -oP '^\d+')
    set day (echo $raw_date | grep -oP '(?<=\/)\d+(?=\/)')
    set year (echo $raw_date | grep -oP '(?<=\/)\d{4}$')

    if test (string length $month) -eq 1
      set month "0$month"
    end

    if test (string length $day) -eq 1
      set day "0$day"
    end

    sed -i "/^status:/a\\date: $year-$month-$day" "$file"
end
