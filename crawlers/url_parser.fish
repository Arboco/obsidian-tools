#!/usr/bin/env fish

# Loop through all text files in the current directory
for file in *.md
    # Extract the URL from the bottom of the file
    set url (awk -F'[()]' '/^\[iqdb\]/{print $2}' $file)

    # Check if the URL was successfully extracted
    if test -n "$url"
        # Remove the URL line from the file
        sed -i '/^\[iqdb\]/d' $file

        # Insert the URL into the YAML front matter
        sed -i "/^title:/a url: $url" $file
    else
        echo "No URL found in $file"
    end
end
