# capture games 
Scripts to capture video game material seamlessly into obsidian notes.

Obsidian md file requires YAML property "launch" where the command line launch command for the game is inserted.
Games are launched with:
`gameinit "<title of obsidian md file>"`

# capture anime
Scripts to capture anime and manga material and seamlessly integrate it into obsidian note


Dependencies:
- mpv
- mpv-cut plugin
- graphicsmagick
- scrot
- xprintidle
- inotify-tools

# Special yaml properties:
## cut: x y 
Takes two numbers that represent pixels that get cut off the side. First number is horizontal pixels, second number is vertical. Both numbers have to be filled, use 0 when you don't want to cut anything for a side. 
## hook-values: x y 
Takes two numbers. First replaces the hook counter, the seconds it takes to hook the first process. Second replaces the start up compensator. Both have to be filled. Use 0 when you want to keep using the default value. 


mpv-cut has to be inserted for mpv and memento separately since they don't share plugins/configs


Otherwise only folders have to be changed for this script to work. 

Obsidian md files require YAML property:
- path (absolute path to folder of anime)
- watched (number of episodes watched, used to find next episode and iterate watched count, has to be a number field)


# obsi 
Custom fzf to find and print obsidian md files with glow, replaces cheat
