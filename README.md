# InKing

A 2D turn-based ink territory game built in Godot 4.6. Two players compete to cover the most tiles with their ink. Similar to Splatoon but grid-based and turn-based, with deck-building mechanics planned.

## How to Play

- Each turn, click one of your own tiles to select it as a starting point
- Click a direction arrow (▲▼◀▶) to shoot — your ink travels 5 tiles in that direction
- If your ink crosses the opponent's territory, it converts those tiles to yours
- After 60 turns (30 each), whoever has the most tiles wins

## Testing Multiplayer

### Same machine (hot-seat)
Just run the game. Both players share the mouse — take turns clicking.

### Two windows on one machine
1. In Godot editor: **Debug > Customize Run Instances** — set to 2 instances
2. Window 1: click **Host Game**
3. Window 2: leave IP as `127.0.0.1`, click **Join Game**

### Two devices on the same WiFi (or phone hotspot)
1. On the host machine, find your local IP:
   - Windows: open a terminal and run `ipconfig` → look for **IPv4 Address** under your active adapter (e.g. `192.168.1.42`)
   - Mac: **System Settings > Wi-Fi > Details** or run `ipconfig getifaddr en0` in Terminal
2. Host machine: click **Host Game**
3. Other device: type the host's local IP into the Join field, click **Join Game**

> This works on the same WiFi network or if both devices are connected to the same phone hotspot.

### Over the internet (different networks — e.g. Toronto + LA)
1. Both players install **Tailscale**: [tailscale.com/download](https://tailscale.com/download)
2. Sign in (same or linked accounts)
3. Host finds their Tailscale IP in the Tailscale app (looks like `100.x.x.x`)
4. Host clicks **Host Game**, shares their Tailscale IP
5. Other player types that IP into Join field, clicks **Join Game**

## Project Structure

```
scenes/        # Godot scene files
scripts/
  autoloads/   # GameState.gd, Network.gd (singletons)
  Game.gd      # Turn logic, RPCs
  Grid.gd      # Board rendering and input
  Lobby.gd     # Host/Join UI
  UI.gd        # HUD, win screen
```

## Roadmap

- [x] Local hot-seat play
- [x] Networked multiplayer (LAN + Tailscale)
- [ ] Card/deck system
- [ ] Ink strength mechanic
- [ ] Visual polish (sprites, animations)
- [ ] Sound
