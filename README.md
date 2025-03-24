# obsidian-game-suit
Scripts to capture video game material seamlessly into obsidian notes.

Obsidian md file requires YAML property "launch" where the command line launch command for the game is inserted.
Games are launched with:
`gameinit "<title of obsidian md file>"`

# obsidian-anime-suit
Scripts to capture anime and manga material and seamlessly integrate it into obsidian note


Dependencies:
- mpv
- mpv-cut plugin
- memento
- graphicsmagick
- scrot

mpv-cut has to be inserted for mpv and memento separately since they don't share plugins/configs


Otherwise only folders have to be changed for this script to work. 

Obsidian md files require YAML property:
- path (absolute path to folder of anime)
- watched (number of episodes watched, used to find next episode and iterate watched count, has to be a number field)


# obsi 
Custom fzf to find and print obsidian md files with glow, replaces cheat
