# GuessWho Gamemode Integration Summary

## Overview
The GuessWho (Hide & Seek) gamemode has been integrated into the Rage system and added to the gamemode list. The plugin properly resets to a ready-to-start state when gamemodes are changed.

## Integration Points

### 1. Gamemode List
- **File:** `sourcemod/scripting/rage_survivor_menu.sp`
- **Status:** Already present in the gamemode list
- **Entry:** "GuessWho" at index 11
- **Cvar:** `rage_gamemode_guesswho` (default: "guesswho")

### 2. Plugin File
- **File:** `sourcemod/scripting/rage_gamemode_guesswho.sp`
- **Status:** Created and integrated
- **Dependencies:**
  - `<gamemodes/base>` - Base gamemode functionality
  - `<guesswho/gwcore>` - Core GuessWho functionality
  - `<guesswho/gwpoints>` - Movement point system
  - `<guesswho/gwgame>` - Game state management
  - `<guesswho/gwcmds>` - Command handlers
  - `<guesswho/gwents>` - Entity management
  - `<guesswho/gwtimers>` - Timer functions

### 3. Gamemode Change Handling

#### Reset Functionality
The `ResetGamemode()` function ensures a clean state when:
- Gamemode is changed away from GuessWho
- Round ends
- Map ends
- Plugin is unloaded

**Reset actions:**
- Clears all timers (spawning, hider check, door toggle, record, times up, wait, acquire locations, bot movement)
- Resets game state variables (currentSeeker, isStarting, etc.)
- Clears player-specific data (hasBeenSeeker, hiderSwapCount, etc.)
- Resets location tracking arrays

#### Event_GamemodeChange Hook
- **When enabled:** Hooks events, sets CVars, initializes gamemode
- **When disabled:** Unhooks events, restores CVars, cleans up game state
- **Reset call:** Always calls `ResetGamemode()` before enabling to ensure clean start

### 4. State Management

#### Game States
- `State_Unknown` - Initial/ready state
- `State_Starting` - Seeker blind period
- `State_Active` - Game in progress
- `State_HidersWin` - Hiders won
- `State_SeekerWon` - Seeker won

#### State Transitions
1. **Unknown → Starting:** When safe area is left
2. **Starting → Active:** After seed time expires
3. **Active → HidersWin:** Seeker dies or time runs out
4. **Active → SeekerWon:** All hiders die
5. **Any → Unknown:** On reset/gamemode change

### 5. CVar Management

#### Stored CVars
The plugin stores and restores the following CVars:
- `survivor_limit`
- `sb_separation_danger_min_range`
- `sb_separation_danger_max_range`
- `abm_autohard`
- `sb_fix_enabled`
- `sb_pushscale`
- `sb_battlestation_give_up_range_from_human`
- `sb_max_battlestation_range_from_human`
- `enforce_proximity_range`
- `sv_spectatoridle_time`

#### Restoration
CVars are restored when:
- Gamemode is changed away from GuessWho
- Plugin is unloaded
- Map ends

## Key Features

### 1. Seeker Selection
- Random selection from players who haven't been seeker
- Tracks `hasBeenSeeker[]` array
- Resets when all players have been seeker

### 2. Bot Movement System
- Uses `MovePoints` to track valid movement locations
- Bots move randomly to avoid seeker
- Records player positions during seed time
- Saves/loads movement data per map

### 3. Hider Model Swapping
- Players can swap models by looking at another player and pressing RELOAD
- Limited swaps per round (HIDER_SWAP_LIMIT = 3)
- Cooldown between swaps (HIDER_SWAP_COOLDOWN = 30.0 seconds)

### 4. Damage System
- Seeker takes damage when attacking bots
- Hiders take 100 damage when attacked by seeker
- Other damage is blocked

## TODOs for Full Implementation

### Critical
- [ ] Verify all includes compile correctly
- [ ] Test gamemode switching and reset functionality
- [ ] Test bot movement system
- [ ] Test hider model swapping
- [ ] Test seeker selection and rotation

### Optional Enhancements
- [ ] Add configuration for bot behavior
- [ ] Add admin commands for manual seeker selection
- [ ] Add statistics tracking
- [ ] Add map-specific configurations
- [ ] Optimize bot movement pathfinding

## Testing Checklist

### Gamemode Switching
- [ ] Switch from another gamemode to GuessWho
- [ ] Verify clean state on switch
- [ ] Switch from GuessWho to another gamemode
- [ ] Verify CVars are restored
- [ ] Verify timers are cleaned up

### Game Flow
- [ ] Seeker is selected correctly
- [ ] Seed time works (seeker blind)
- [ ] Game starts after seed time
- [ ] Bots move correctly
- [ ] Hiders can swap models
- [ ] Seeker can kill hiders
- [ ] Seeker takes damage from bots
- [ ] Game ends correctly (time/win conditions)

### Reset Functionality
- [ ] All timers are killed on reset
- [ ] Game state is cleared
- [ ] Player data is reset
- [ ] CVars are restored
- [ ] Ready for next round

## Notes

- The gamemode uses `mp_gamemode` ConVar to detect activation
- When `mp_gamemode` is set to "guesswho", the plugin activates
- The plugin automatically resets when switching away from GuessWho
- All game state is cleared to ensure a clean start on next activation

