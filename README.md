# W Mine and Building Game
An original Mining and Building Sandbox game.

## Screenshots
(Screenshots made in version 0.9b from December 3rd 2025)
<img width="639" height="359" alt="Screenshot1" src="https://github.com/user-attachments/assets/1d6ce4a1-21b4-4658-b446-1877de8d1664" />
<img width="639" height="359" alt="screenshot2" src="https://github.com/user-attachments/assets/4e189f18-fedf-4397-8919-98998f8ccea0" />

## Features
- Singleplayer and Multiplayer
- Level Saving/Loading
- Many different blocks
- bEtTer GraÜPhIcs TheN MiNcErAfT
- Open Source and made in Godot

## Controls
These are the controls for the game. Every Input marked with an * can be changed in settings

```
Forward/Backward    W/S*
Left/Right          A/D*
Jump                Spacebar
Blockmenu           B*
Place Block         Left Click*
Break Block         Right Click*
Sprint              Shift
Quit                Alt+Q (or OS default)
Toggle Flight       Ctrl+Shift+F1 (only in singleplayer)
Fly down            C* (only in singleplayer)
```

## Multiplayer Help

### Setup
To make it easier to copy your IP, open the *Console Version* of the game.

**Note:** You have to enable *UPNP* on your router settings, or else nobody can join your server. Just look for an setting with "UPNP enable" or similar. You don't need to port forward, since we use UPNP.

Then in the game, *choose an Playername and world size*. After that click on *"Multiplayer Host"*. This will *open an server and print the IP in the chat* and the console. If you don't see one, *look for some errors* in the console.

The server closes, when the host leaves.

### Joining
To join your server you need to *enter your IP*, there is no port needed (The game **always** uses port 9555). Then after *choosing an playername*, you can join to the server. *Due to the new join pipeline, the hosting player will experience some lag.*

### Connection to Server Lost
If the GridMap (the blocks of the world) is to big, it takes to long to send the data to the players. You know this happend if you get the error "The mutliplayer instance isn't currently active." after joining. This has improved since 0.9d, but it still isn't perfect.

### Saving and Loading
Only the *host* of the server is *allowed to save* the current level. If you want to *load* an specific level on your server you *have to name it "server"*. The game will look in your levels folder for an level called *"server"* and load it, when starting up. This was done because loading while the server in on had some problems, while testing.

> Made by Marlon49, 2025.
