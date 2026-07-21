# W Mine and Building Game
An original Mining and Building Sandbox game.

## Screenshots
(Screenshots made in an old version from December 3rd, 2025)
<img width="639" height="359" alt="Screenshot1" src="https://github.com/user-attachments/assets/1d6ce4a1-21b4-4658-b446-1877de8d1664" />
<img width="639" height="359" alt="screenshot2" src="https://github.com/user-attachments/assets/4e189f18-fedf-4397-8919-98998f8ccea0" />

## Features
- Singleplayer and *Multiplayer*
- Level *Saving/Loading*
- Many different blocks
- *Survival mode* (currently in dev)
- bEtTer GraÜPhIcs TheN MiNcErAfT
- *Open Source* and made in Godot

## Controls
These are the controls for the game. *Every Input marked with an * can be changed in settings.*

```
Forward/Backward    W/S*
Left/Right          A/D*
Jump                Spacebar
Blockmenu           B*
Place Block         Left Click*
Break Block         Right Click*
Sprint              Shift*
Quit                Alt+Q (or OS default)
Fly down            V* (only in singleplayer)
Crafting            C*
```

## Commands
These commands can be used in the in-game chat:

```
!fly                Toggles flight (only in singleplayer)
!give [BLOCK/ITEM]  Gives an Item or Block with given ID and Count.
 [ID] [COUNT]
!clearinv           Clears your inventory.
!noclip             Toggles Collision of the player.
!gridmap_cell_data  Prints the data of the hovering block in the gridmap.
```

## Multiplayer Help

### Disclaimer
Multiplayer **does NOT provide any kind of anti-cheat**. Anyone with the technical skills could modify the game code to **enable flying in multiplayer or similar**, since these checks are performed **client-side**. This multiplayer is **not ment for any professional and/or big environment** and should **only be used** with people you know and trust.

### Setup
To make it easier to copy your IP, open the **Console Version** of the game.

**Note:** You need to **port forward** any port of your choosing, if you want to play with people, who aren't in your local network. *The default port* for W Mine and Building Game *is __9555__*

Then in the game, *choose an __Playername__ and __world size__* (I would suggest you go for an *smaller world size for now*) and an **port** (default 9555). The port here *should be the one you port forwarded* (if you did). After that click on **"Multiplayer Host"**. This will *open an server and print the IP in the chat* and the console. If you don't see one, *look for some errors* in the console.

The server closes, when the host leaves or closes the game.

### Joining
To join a server you need to _**enter the IP** of the server_ and also enter the servers **port** into the field on the right. (Default is *9555*). Then after *choosing an playername*, you can join to the server. *Joining might take a long time, but waiting times will be improved in a future update in 0.12*

### Connection to Server Lost
If the *GridMap* (the blocks of the world) *is to big*, it might take too long to send the data to the clients. You know this happend if you get the error **"The multiplayer instance isn't currently active."** after joining. *This has improved since 0.9d*, but it still isn't perfect.

### Saving and Loading
Only the **host** of the server is *allowed to save* the current level. If you want to *load* an specific level on your server you *have to name it "server"*. The game will look in your levels folder for an level called **"server"** and load it, when starting up. This was done because loading while the server in on had some problems, while testing.

> Made by toBlue49, 2026

## Legal Disclaimer
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
