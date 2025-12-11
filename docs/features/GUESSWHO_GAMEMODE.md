# GuessWho Gamemode Documentation

## Overview

**GuessWho** is a hide-and-seek style gamemode for Left 4 Dead 2. One player is designated as the **Seeker** (armed with a fireaxe), while all other players are **Hiders** (armed with gnomes). The goal is for hiders to avoid being found by the seeker within a time limit.

## How It Works

### Core Mechanics

1. **Seeker**: 
   - One player is randomly selected as the seeker
   - Armed with a fireaxe (melee weapon)
   - Has a glowing effect to distinguish them
   - Must find and eliminate all hiders before time runs out

2. **Hiders**:
   - All other players are hiders
   - Armed with gnomes (weapon_gnome)
   - Must hide and avoid the seeker
   - Win if time runs out without being found

3. **Game State**:
   - Managed via VScript integration
   - Tracks game state (waiting, active, ended)
   - Timer system for round duration
   - Automatic seeker rotation for balance

### Features

- **Custom Map Configuration**: Each map can have custom spawnpoints, entities, and movement points
- **Point Recording System**: Records movement locations for bot AI navigation
- **Custom Entities**: Supports blockers, props, portals, and environmental effects
- **Multiple Sets**: Maps can have different "sets" with different configurations
- **Peek Camera**: Seeker can use a camera system to peek at hiders
- **Auto Vocalizations**: Hiders automatically make sounds when far from seeker

## File Structure

The GuessWho gamemode consists of include files in `sourcemod/scripting/include/guesswho/`:

- **gwcore.inc**: Core functionality - loads configs, manages map database
- **gwgame.inc**: Game logic - seeker/hider mechanics, game state management
- **gwcmds.inc**: Commands - admin and user commands (`/guesswho`, `/join`)
- **gwpoints.inc**: Points system - records and loads movement locations
- **gwents.inc**: Entity spawning - custom props, blockers, portals
- **gwtimers.inc**: Timer callbacks - game timers and periodic checks

## Configuration

### Map Configuration

Maps are configured via `sourcemod/data/guesswho/config.cfg`:

```kv
"mapname"
{
    "defaultset"    "set1"          // Default set to use
    "maptime"       "300"            // Round time in seconds
    "spawnpoint"    "x y z"          // Custom spawn location
    
    "ents"
    {
        "entity1"
        {
            "origin"        "x y z"
            "rotation"      "pitch yaw roll"
            "type"          "env_physics_blocker"
            "model"         "models/path/to/model.mdl"
            "scale"         "5.0 5.0 5.0"
            "offset"        "0 0 0"
            "set"           "default"
        }
    }
    
    "sets"
    {
        "set1"
        {
            "spawnpoint"    "x y z"
            "maptime"       "300"
            "inputs"
            {
                "targetname"   "input value"
            }
        }
    }
}
```

### Movement Points

Movement points are stored in `sourcemod/data/guesswho/<mapname>/<setname>.txt`:
- Format: `px py pz ax ay az` (position and angles)
- Used for bot AI navigation
- Can be recorded in-game with `/guesswho points record`

## Commands

### User Commands

- `/guesswho` - Show help and game information
- `/join` - Join the game as a hider
- `/stuck` - Teleport to spawn if stuck

### Admin Commands

- `/guesswho points record [interval]` - Record movement points
- `/guesswho points save [set]` - Save recorded points
- `/guesswho points load` - Load movement points for current map/set
- `/guesswho points clear` - Clear recorded points
- `/guesswho set [setname]` - Change the active set
- `/guesswho r[eload] [force]` - Reload map configuration
- `/guesswho toggle <blockers/props/all>` - Toggle entity visibility
- `/guesswho clear <props/blockers/all>` - Remove entities
- `/guesswho settime [seconds]` - Set round time
- `/guesswho seeker [player]` - Get or set the current seeker
- `/guesswho debug` - Show debug information

## Integration with Rage Menu

GuessWho has been added to the Rage gamemode selection menu. Players can vote for it like any other gamemode:

1. Open the Rage menu (hold SHIFT)
2. Navigate to "Vote for gamemode"
3. Select "GuessWho"
4. The server will change `mp_gamemode` to `guesswho`

## Requirements

- **VScript Support**: Requires Left 4 DHooks Direct for VScript integration
- **Map Configuration**: Maps need to be configured in `data/guesswho/config.cfg`
- **Movement Points** (optional): For bot AI, movement points should be recorded

## Notes

- The gamemode includes are ready to use, but a plugin file may be needed to fully initialize the gamemode
- The gamemode uses a mutation-style system that integrates with L4D2's VScript
- Custom entities (blockers, props, portals) are spawned based on map configuration
- The seeker is automatically balanced (players who haven't been seeker are prioritized)

## Status

✅ **Menu Integration**: Added to gamemode selection menu  
⚠️ **Plugin Status**: Includes are complete, but a plugin file may be needed for full activation  
📝 **Documentation**: This file provides overview and usage instructions


