#! /usr/bin/env fish

for i in $(find /home/anon/ortup/important/notes/ortvault/resources/* -type f)
    set filename (basename $i)
    if grep -r "\[\[$filename.*\]\]" /home/anon/ortup/important/notes/ortvault/notes/
    else
        mv $i /home/anon/ortup/important/notes/ortvault/restrash
    end
end

for i in $(find /home/anon/ortup/important/notes/ortvault/restrash/* -type f)
    set filename (basename $i)
    if grep -r "/$filename" /home/anon/ortup/important/notes/ortvault/notes/canvas/
        mv $i /home/anon/ortup/important/notes/ortvault/resources/canvas/
    end
end
