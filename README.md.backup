# L4D2: Rage Edition

A celebratory remix of Left 4 Dead 2 DLR Mode that turns every round into a playable action movie. Rage Edition keeps the co-op chaos you love and layers on bold classes, dramatic abilities, and a stack of quality-of-life touches that make the whole server feel alive.

## Core Features
- **Plugin-based architecture** - Sourcemod 1.12 compatible with modular class system
- **Configurable classes** - Six unique classes with customizable skills via `configs/rage_class_skills.cfg`
- **New menu system** - Hold ALT to show menu, navigate with WASD
- **Advanced abilities** - Portable turrets, mines, missiles, satellite strikes, healing orbs, and more
- **Quality of life** - Third-person view toggle, scripted HUD, self-help mechanics, music player

## Quick setup

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
- Moves faster, shrugs off more hits, and slashes like a blender.
- Can order satellite strike on outside areas.
- Fires a homing missile with `SKILL ACTION 2` and a dummy distraction missile with `SKILL ACTION 3`.
- Flips night vision on or off whenever the fight slips into darkness.
- Has increased health

### Ninja
- Built for motion: sprint boosts, double jumps, and mid-air karate kicks.
- Moves fast
- Sprint + **Jump** together to launch a ninja kick into whatever you collide with.
- Hold **Use** mid-air to deploy a parachute and float over chaos or escape a wipe.
- Throws antigravity grenades

### Trooper
- Increased damage per weapon, reloads fast. Can perform tank knockdowns.
- Builds rage meter to unleash a Berserk rush that melts specials. Activate rage with `SKILL ACTION 1`
- Lots of health

### Medic
- Can deploy defibs and medpacks
- Faster healing and revival; movement boost while healing
- Summon healing orbs with `SKILL ACTION 2` that glow and announce to others; cleanses bile with `SKILL ACTION 3` button
- Players notified when healed; healed players gain a special glow; look down + **Shift** to drop medkits/supplies
- Can throw healing grenades by using `SKILL ACTION 1`

### Engineer
- Spawns ready-to-use upgrade packs
- Deploy action opens a turret menu with two turret types and eight ammo options; look down + **Shift** to drop ammo supplies
- Deploys protective shields and barricades doors/windows
- Turrets notify nearby players, can be blown up by infected and are non-blocking
- Can carry turrets around
- Has 20 experimental type grenades like Black Hole vortices, Tesla lightning, Medic healing clouds, or an Airstrike marker. Throw with `SKILL ACTION 1`

### Saboteur
- Faster crouch movement with invisibility
- Dead Ringer decoy: Use `SKILL ACTION 1` to vanish and drop a fake corpse.
- When invisible, reveals special infected for 20 s every 2 min
- Deploy action covers 20 mine types; look down + **Shift** to plant mines that glow and warn nearby players
- Reduced survivor damage, increased infected damage

## Additional Features & Commands
- **Class Skill Actions** – Bind `skill_action_1` through `skill_action_3` and `deployment_action` to trigger your class's abilities. Inputs are fully configurable per class in `configs/rage_class_skills.cfg`.
- Keeps chosen class throughout the campaign unless user changes it.

## Predicaments Plugin
Enhances survivor gameplay with self-help mechanics, struggle system, and crawling:
- **Self-Revival**: Revive yourself from incapacitation by holding CROUCH and consuming pills, adrenaline, or first-aid kits
- **Ledge Rescue**: Pull yourself up from ledges using available medical items
- **Pin Escape**: Break free from Special Infected (Smoker, Hunter, Jockey, Charger) by struggling or using items
- **Teammate Revival**: Incapacitated survivors can revive other incapacitated teammates by pressing RELOAD
- **Struggle System**: Mash CROUCH to build up struggle progress and escape from pins. Infected can counter-struggle by pressing SPRINT
- **Incapped Crawling**: Move while incapacitated using movement keys with configurable speed
- **Item Pickup While Down**: Grab nearby medical supplies while incapacitated
- **Bot Support**: Bots can revive themselves with configurable settings

Configure via `cfg/sourcemod/l4d2_predicaments.cfg` (auto-generated on first load). Key convars:
- `l4d2_predicament_enable` - Master switch (default: 1)
- `l4d2_predicament_use` - Items allowed: 0=none, 1=pills/adrenaline, 2=medkits, 3=both (default: 3)
- `self_help_crawl_enable` - Enable incapped crawling (default: 1)
- `self_help_crawl_speed` - Crawling speed multiplier 0.0-1.0 (default: 0.15)
- `self_help_struggle_mode` - Struggle system: 0=disabled, 1=automatic, 2=manual (default: 0)
- `self_help_struggle_gain` - Progress gained per struggle input (default: 10.0)
- `l4d2_predicament_bot` - Bot revival enabled (default: 1)

For developers: The plugin provides API hooks via `l4d2_predicaments.inc` for controlling healing and struggle mechanics.

## Toys, tricks, and server spice
- **Music player** – Type `!music` to choose the soundtrack, skip songs, or go silent. Preferences stick with you between maps.
- **Away toggle** – Need a breather? Mark yourself AFK directly from the menu and hop back in when ready.
- **Multiple equipment mode** – Pick how forgiving pickups are, from classic single-use kits to double-tap weapon swaps.
- **Voting hub** – Launch game mode and map votes without fumbling chat commands.
- **Custom gamemodes** - Escort mission, Jockey chase, deathmatch 1v1 modes. By choosing gamemode, available maps are updated.
- **Command parity** – Every feature also has an `sm_` console command so you can bind keys or build macros exactly how you like.

## Soundtrack corner
Drop a list of 44.1 kHz audio files (WAV/MP4 are safest) into the supplied music text files, point your fast-download host at them, and the plugin does the rest. First-time players can even hear a special welcome track if you enable the option.

### Music directory
Custom tracks belong in the repo-level `music/` folder. Docker Compose mounts that directory into the server at `left4dead2/sound/custom/rage` so the entries in `sourcemod/data/music_mapstart*.txt` resolve correctly (e.g., `custom/rage/my_track.wav`).

Want music out of the box? Run `python music/download_soundtrack.py --out music` to fetch MP4s for the DOOM/DOOM II gamerip directly from downloads.khinsider.com. The pull includes Zorasoft's licenseless **Project Doom** album (https://zorasoft.net/prjdoom.html) so you still get Intro Stomp, Midnight Assault, and Final Push without storing the WAVs in the repository.

## Admin corner
Need to tidy the battlefield? `!rageadm` opens a dedicated panel with spawn helpers, restart controls, god mode, and slow-motion toggles. Everything is grouped for quick decisions mid-round.

## Ready to tinker?
Rage Edition is built from modular SourceMod plugins, so you can add new talents, swap out effects, or write your own class packs without touching the core. Check the `sourcemod/scripting` folder for clean, well-documented examples.

Grab the files, drop them on your server, tweak `configs/rage_class_skills.cfg` to taste, and let the rage weekend begin.

## Credits

Rage Edition grew out of DLR keeps a mix of community talent and community open-source modules alive.

- Core talents and class system by DLR team, Ken, Neil, Spirit, panxiaohai, and Yani.
- Scripted HUD work by Mart and Yani.
- Extra menu system, airstrike, grenades, and Left 4 DHooks utilities by SilverShot (Silvers).
- Satellite cannon plugin by ztar.
- Music player by Dragokas.
- Tutorial guide and Dead Ringer cloak by Yani and Shadowysn.
- In-progress jump and utility plugins from zonde306 and Yani, alongside shanapu’s shared parachute logic.
- Enhanced graphics and custom Adawong model by LuxLuma
- Ripping custom soundtrack by Zorasoft
- Additional sound effects and event themes by Yaniho
- Predicaments plugin based on Pan Xiaohai's original work, enhanced by cravenge and Yani
- Alliedmodders community
