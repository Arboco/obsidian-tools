#! /usr/bin/env fish 

set script_dir (realpath (status dirname))
set urls (cat ~/Downloads/firefox.html | grep -o 'class="a-size-base-plus a-link-normal itemBookTitle a-text-bold".*">' | sed -n 's/.*\(http[s]*:\/\/[^\s]*\).*/\1/p')
#set urls (cat $script_dir/url.txt) 
set title "kimino-koto-ga-daidaidaidaidaisuki-na-100-nin-no-kanojo"
set md_name "君のことが大大大大大好きな100人の彼女"
set series_link "[[Kimi no Koto ga Daidaidaidaidaisuki na 100-nin no Kanojo]]"
set crop "true" 

set img_folder "/home/anon/ortup/important/notes/ortvault/resources/anime_db/manga_gallery"
set md_folder "/home/anon/ortup/important/notes/ortvault/notes/anime_db/manga_gallery"


mkdir "$img_folder/$title"
mkdir "$md_folder/$title"

for item in $urls
  set timestamp (date +%s)
  node $script_dir/fetch-page.js "$item" > /tmp/amazonjp.html
  set img_link (cat /tmp/amazonjp.html | grep -o '"landingImageUrl":".*"' | grep -o 'https.*g')
  if cat /tmp/amazonjp.html | grep -oP '(?<=\[{"hiRes":")[^"]*'
    set img_link (cat /tmp/amazonjp.html | grep -oP '(?<=\[{"hiRes":")[^"]*')
  end
  cat /tmp/amazonjp.html | grep -oP '(?<=\[{"hiRes":")[^"]*'
  set num (cat /tmp/amazonjp.html | grep -oP '(?<=name="description" content="Amazon.co.jp: )[^(]*' | sed 's/１/1/g; s/２/2/g; s/３/3/g; s/４/4/g; s/５/5/g; s/６/6/g; s/７/7/g; s/８/8/g; s/９/9/g; s/０/0/g' | grep -o '[0-9]*')
  
  set img_title "$title-mg-$num.jpg"
  
  if test $crop = "true"
    wget -O "/tmp/$img_title" $img_link
    magick "/tmp/$img_title" -gravity East -crop 0x0+120+0 +repage "$img_folder/$title/$img_title"
    rm "/tmp/$img_title"
  else 
    wget -O "$img_folder/$title/$img_title" $img_link
  end
  
  set md "$md_folder/$title/$md_name $num.md"
  echo "---" >> $md
  echo -e "series: \"$series_link\"" >> $md
  echo "order: $num" >> $md
  echo -e "url: \"$item\"" >> $md
  echo "status:" >> $md
  echo -e "cover-img: \"![[$img_title]]\"" >> $md 
  echo "tags: manga gallery japan" >> $md
  echo "---" >> $md
end

