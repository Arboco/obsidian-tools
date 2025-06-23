# capture games 
Scripts to capture video game material seamlessly into obsidian notes.

Obsidian md file requires YAML property "launch" where the command line launch command for the game is inserted.
Games are launched with:
`gameinit "<title of obsidian md file>"`

# anime-starter 
Dependencies: 
  - socat 
  - mpv-cut plugin
  - inotify-tools 

## Usage 
Put "animepath" property inside your yaml with the absolute path of the anime inside it. That's it. 

## Features 
- fzf search for all animepath anime 
- -i flag for history feature 
- give number as argument to launch the episode directly 
- automatically tracks your completion status 
- only increases episode count if episode is actually completed (85% completion)
- tracks when an episode was not completed and opens it again at the exact time it was closed
- automatically tracks rewatches 
- automatic dataview creation with individual files for each episode 
- automatic thumbnail generation 
- replace thumbnail any time with your own screenshot 
- delete cover-img property to insert a new thumbnail for your next screenshot 
- screenshot support and auto insertion with s key 
- video clip support and insertion with c c (mpv-cut plugin)

Dependencies:
- mpv
- graphicsmagick
- scrot
- xprintidle

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
