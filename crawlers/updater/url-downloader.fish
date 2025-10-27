#! /usr/bin/env fish

curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0"   \
     -e "https://example.com" \
     -H "Accept-Language: en-US,en;q=0.9" \
     -H "Connection: keep-alive" \
     -H "Upgrade-Insecure-Requests: 1" \
     -c cookies.txt -b cookies.txt -L https://www.igdb.com/


curl -b cookies.txt -s -A "Mozilla/5.0 (X11; Linux x86_64; rv:134.0) Gecko/20100101 Firefox/134.0" "https://www.igdb.com/games/mega-man-zx" > output.html
