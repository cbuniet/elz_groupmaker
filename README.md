# Groupmaker
Adds a temporary group system for players - Adds leader/member blips

## Dependencies
- Vorp Core


## Installation
- `ensure elz_groupmaker` in your resources.cfg
- edit the config file 
- start your server 

## Features
- Create a temporary group with no person limit
- Differentiation between leader and member blips (Sprite and color can be modified in Config.lua)
- Blips attached to player entities = no jerks on minimap
- Comment to help you to use it for your own scripts

## Utilisation
- Enter the command `/inviteGroup [CHAR_ID and NOT YOU]` to invite a player. You become the group leader.
- As group leader, you can use `/removeGroup [CHAR_ID and NOT YOU]` to remove a player from your group and `/deleteGroup` to delete the group.
- If a player disconnects from the server or crashes, the 'vorp:playerDropped' event handler removes the player from the group. If the player is the group leader, or the group contains only one member, the group is deleted.
  
# Todo List 
- Add an invitation confirmation system with notifications.
- Create an optional menu (enabled in config) with the list of connected players to replace current commands.
- Add a configurable limit to group size
