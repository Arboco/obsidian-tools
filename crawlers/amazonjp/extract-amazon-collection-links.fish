#! /usr/bin/env fish
cat ~/Downloads/firefox.html | grep -o 'class="a-size-base-plus a-link-normal itemBookTitle a-text-bold".*">' | sed -n 's/.*\(http[s]*:\/\/[^\s]*\).*/\1/p' > url.txt
