
K: 🧩 Model Template Example for the-key #1 🧩
cards_cleared: 2 
key_favorite: 40
keyring: #Keyring
mp: [[Resident Evil 3 Nemesis]]
agenda: S 2025-09-22
skip: Task
timer: 3
links: [[Link1]] [[Link2]]
tags: #tag1 #tag2 
string1: string 1
string2: string 2
regex1: "regex"
cardstring1: string 1
subtags: #subtag1 #subtag2 
contains: string 
uuid: d3ec90bf-9bde-4b5b-978b-c1b79951331d
a-subtag: #subtag 
family: parent children siblings 
f-tags: #tag1 
f-links: [[Link]]
f-string1: string 1
remove: string 
Description 
>[[omnipoten-wizard-of-love.gif]]

# Explanation 
## Option 
- keyring: Corresponds to -k flag, bundles the key in a group with other keys 
- mp: Same as keyring just especially for mind palaces 
- agenda: Corresponds to -a flag, sorts keys after priority and date similiar to the agenda in  emacs. The agenda key consists of priority and date (optional). Date format is `yyyy-mm-dd`
- cards_cleared: How many cards you have cleared of this key. Can be sorted with with -c flag.
- key_favorite: Give the key a personal rating. Can be sorted by the value with the -f flag. 
- skip: Put in either Question, Inspiration, Task, Wiki or Combined to skip directly to the pool you know you want instead of going trough the select menu 
- timer: set the seconds for inspiration so you are not prompted any longer 
## Card Pool increasers 
- links: use obsidian link to include those notes in the pool 
- tags: use tags to include those notes in the pool 
- string: includes all notes that have that particular string in a line. The most powerful application of this is being able to use pretty much any yaml property now to add files. Add each string in a separate line with the property name incrementing like seen in the example
- regex: like string but uses ripgrep -P sensitive regex
- cardstring: adds cards based on string contained within cards 
- family: the-pool related option, include the parent, children or siblings of the note where the key resides in
- subtags: include the cards given that subtag, a subtag is a tag found anywhere in the card contents 

## Filters 
- a-subtag: filter the entire card pool to only include cards with that subtag
- contains: filter based on a line inside the card 
- uuid: filter based on uuid 
- f-tags: removes notes with that tag
- f-links: removes the linked notes
- f-string: removes notes with that string
- remove: remove based on a line inside the card, multiple instances of this can be done by using the same property line by line

Keys work the same as any other card type and can be given a description and images to display as long there are no empty lines. 

## On Combinability 
All properties should work with multiple arguments and being combined with as many properties as one lines. If this is not the case this is a bug. 
