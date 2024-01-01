# Duel Defense

Tower defense game made in Godot 4. https://d10sfan.itch.io/duel-defense

![image](https://github.com/d10sfan/duel-defense/assets/4337981/2c003788-2647-4034-a5b9-a1c13b3ffa77)



## Development Information

CI is setup to build artifacts for Linux, Windows, Web, and Android. The game is built with GDScript and JSON config files. Contributions, including code and assets, are welcome! Please look over the pull request template. As well, feature ideas or bugs found are also welcome to be reported.

### Android

A new debug keystore can be created with a command similar to the following

```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```

The keystore can then be converted to base64 and stored in the github secrets.

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

### Modding

Mods are in the form of .pck files, that can be put into the user data mods folder, ~/.local/share/godot/app_userdata/Duel Defense/mods on Linux for example. Mods can override existing files in the game, or new items can be created, such as new levels.

Mods can be manually installed. As well, mod.io is integrated with the game, so that mods can be downloaded in-game. See https://mod.io/g/duel-defense1 for a list of mods, and to upload a mod.

For more information about how to create mods, go to https://github.com/d10sfan/duel-defense-mod-example. Note that mods will not be loaded while the game is being tested in the editor, due to a Godot bug.

## License Information

License for the game can be seen here - https://github.com/d10sfan/duel-defense/blob/main/LICENSE.md

For any assets used in the project, see the Assets/AssetsLicenses folder.

