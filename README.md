# Duel Defense

Tower defense game made in Godot 4.

## Gameplay Information

### In-Game Console

At any time while the game is running, you can use the ` key to open the console. This has many commands which are helpful for debugging and developing.

To see a list of commands, run `commands_list`. The logs also appear in the console.

Inside the code of the project, `'Console.add_command'` will be seen, which are the command definitions.


### Using autoexec.cfg

The same commands you can use in the in-game console can also be used in an autoexec.cfg file. This file should be put in the config directory for Godot. On Linux, this is at `~/.local/share/godot/app_userdata/Duel Defense/configs/`

The file could look like
	
```
map Map1
set_use_auto_turrets true
toggle_play
```
This will switch to a map called Map1, enable to debug automatic turrets, and start the game.

## License Information

TODO - Add License file for the project

For any assets used in the project, see the Assets/AssetsLicenses folder.

