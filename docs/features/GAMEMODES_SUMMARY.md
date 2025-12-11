# Game Modes Organization Summary

## Overview

Game modes have been organized into a separate directory structure for better maintainability and clarity. All gamemode plugins are now located in `sourcemod/scripting/gamemodes/`.

## Directory Structure

```
sourcemod/scripting/
├── gamemodes/
│   ├── rage_gamemode_guesswho.sp    # Hide & Seek game mode
│   ├── rage_gamemode_race.sp         # Race to safe room mode
│   └── rage_tests_gamemodes.sp       # Test suite for gamemodes
└── [other plugins...]
```

## Available Game Modes

### 1. GuessWho (Hide & Seek)
- **File:** `rage_gamemode_guesswho.sp`
- **Description:** One player is the Seeker, others are Hiders who must blend with props
- **Activation:** Select "GuessWho" from the game mode menu
- **Features:**
  - Seeker hunts hiders before time runs out
  - Hiders can use special abilities to escape
  - Props and blockers for strategic hiding
  - Bot management for balanced gameplay

### 2. Race Mod
- **File:** `rage_gamemode_race.sp`
- **Description:** Competitive race to the safe room with point scoring
- **Activation:** Select "Race Mod" from the game mode menu (toggles `rage_racemod_on` CVar)
- **Features:**
  - Points based on finish position (1st=10, 2nd=8, 3rd=6, 4th=4)
  - Bonus points for killing Tanks (+5) and Witches (+3)
  - Bonus points for pouring gascans (+2)
  - Friendly fire disabled (except molotovs)
  - Special infected delay players but won't kill
  - Countdown timer before race starts
  - Commands:
    - `!scores` - Check current standings
    - `!startrace` (admin) - Force start the race

## Integration

### Menu Integration
Game modes are integrated into the main survivor menu:
- Access via: Main Menu → Vote Options → Select Game Mode
- Race Mod toggles via CVar (no mp_gamemode change needed)
- GuessWho uses standard mp_gamemode switching

### Compilation
The `compile_plugins.sh` script has been updated to automatically compile all plugins in the `gamemodes/` subdirectory:

```bash
# Automatically finds and compiles:
# - sourcemod/scripting/rage*.sp
# - sourcemod/scripting/gamemodes/rage*.sp
./compile_plugins.sh
```

## Testing

A dedicated test suite (`rage_tests_gamemodes.sp`) verifies:
- Plugin loading and availability
- CVar functionality
- Menu integration
- Library dependencies

Run tests with: `sm_test_gamemodes` (admin command)

## Documentation

### In-Game Guide
The tutorial system (`rage_survivor_guide.sp`) includes a "Game Modes" section accessible via `!guide`:
- Overview of available modes
- Detailed explanations for each mode
- Activation instructions

### README.md
The main README has been updated with:
- Game modes section in Quality of Life features
- Architecture documentation for developers
- Quick reference for players

## Configuration

### Race Mod
- **CVar:** `rage_racemod_on` (0/1)
- **Config:** `sourcemod/configs/rage_gamemode_race.cfg` (auto-generated)
- **Safe Room Areas:** Hardcoded for all campaign maps (c1m1 through c6m3)

### GuessWho
- Uses standard game mode CVars
- Configuration files in `sourcemod/configs/guesswho/`
- Map-specific configs in `data/guesswho/config.cfg`

## Future Enhancements

Potential improvements:
- More game modes (suggested: King of the Hill, Capture the Flag variants)
- Better integration with VScript mutation system
- Admin controls for mode-specific settings
- Statistics tracking per mode
- Mode-specific achievements

## Notes

- Race Mod works with all standard L4D2 campaign maps
- GuessWho requires specific map setup (blockers, props, portals)
- Both modes reset properly when switching between modes
- All modes are compatible with the class system and other Rage features

