# Duel Defense

Tower defense game made in Godot 4.

![image](https://github.com/d10sfan/duel-defense/assets/4337981/5c5bfcb8-26a5-4d83-b5e5-9a6690edbed7)


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

## License Information

License for the game can be seen here - https://github.com/d10sfan/duel-defense/blob/main/LICENSE.md

For any assets used in the project, see the Assets/AssetsLicenses folder.

