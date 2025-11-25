# L4D2: Rage Edition

A celebratory remix of Left 4 Dead 2 DLR Mode that turns every round into a playable action movie. Rage Edition keeps the co-op chaos you love and layers on bold classes, dramatic abilities, and a stack of quality-of-life touches that make the whole server feel alive.

## Core Features
- **Plugin-based architecture** - Sourcemod 1.12 compatible with modular class system
- **Configurable classes** - Six unique classes with customizable skills via `configs/rage_class_skills.cfg`
- **New menu system** - Hold ALT to show menu, navigate with WASD
- **Advanced abilities** - Portable turrets, mines, missiles, satellite strikes, healing orbs, and more
- **Quality of life** - Third-person view toggle, scripted HUD, self-help mechanics, music player

## Quick Setup

1. Copy `sourcemod/` into your server install (or mount it with Docker Compose).
2. Edit `configs/rage_class_skills.cfg` to assign skills, deployables, and per-class descriptions.
3. (Optional) Adjust cvars in `cfg/sourcemod/talents.cfg` for cooldowns, health tweaks, and limits per class.
4. Restart the server or reload the plugins to pick up changes.

## Classes & Skills

Each class has 3 skill actions + 1 deployment action. Default keybinds:
- **Skill 1**: Middle button
- **Skill 2**: Use + Fire
- **Skill 3**: Crouch + Use + Fire  
- **Deploy**: Look down + Shift

Configure in `configs/rage_class_skills.cfg` and `configs/rage_skill_actions.cfg`.

### Soldierboy
High mobility and firepower with satellite strikes, homing missiles, and night vision.

### Ninja
Speed-focused with double jumps, ninja kicks, parachute gliding, and antigravity grenades.

### Trooper
Tank killer with high damage, fast reload, rage meter, and berserk mode.

### Medic
Support class with faster healing/revival, healing orbs, bile cleanse, and healing grenades.

### Engineer
Builder class with turrets (20 ammo types), shields, barricades, and experimental grenades.

### Saboteur
Stealth specialist with invisibility, Dead Ringer decoy, mines (20 types), and increased infected damage.

## Self-Help Mechanics (Predicaments Plugin)
Core survival features include self-revival, ledge rescue, pin escape, teammate revival, struggle system, and incapped crawling. Configure via `cfg/sourcemod/l4d2_predicaments.cfg`.

## Additional Features
- **Music Player** - `!music` command for soundtrack selection
- **Admin Menu** - `!rageadm` for spawn helpers, god mode, slow-motion
- **Custom Gamemodes** - Escort mission, Jockey chase, deathmatch
- **Voting System** - Launch game mode and map votes

## Music Setup
Drop 44.1 kHz audio files (WAV/MP4) into `music/` folder. Docker Compose mounts this at `left4dead2/sound/custom/rage`. Run `python music/download_soundtrack.py --out music` to fetch DOOM/DOOM II tracks from downloads.khinsider.com.

## Development
Rage Edition is built from modular SourceMod plugins. Check `sourcemod/scripting` for clean, well-documented examples. The plugin-based architecture makes it easy to add new talents, swap effects, or write custom class packs without touching the core.

## Credits

Rage Edition grew out of DLR and keeps a mix of community talent and open-source modules alive.

- Core talents and class system by DLR team, Ken, Neil, Spirit, panxiaohai, and Yani.
- Scripted HUD work by Mart and Yani.
- Extra menu system, airstrike, grenades, and Left 4 DHooks utilities by SilverShot (Silvers).
- Satellite cannon plugin by ztar.
- Music player by Dragokas.
- Tutorial guide and Dead Ringer cloak by Yani and Shadowysn.
- In-progress jump and utility plugins from zonde306 and Yani, alongside shanapu's shared parachute logic.
- Enhanced graphics and custom Adawong model by LuxLuma
- Ripping custom soundtrack by Zorasoft
- Additional sound effects and event themes by Yaniho
- Predicaments plugin based on Pan Xiaohai's original work, enhanced by cravenge and Yani
- Alliedmodders community
