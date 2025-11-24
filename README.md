# L4D2: Rage Edition

A celebratory remix of Left 4 Dead 2 DLR Mode that turns every round into a playable action movie. Rage Edition keeps the co-op chaos you love and layers on bold classes, dramatic abilities, and a stack of quality-of-life touches that make the whole server feel alive.

## Core Features
- Sourcemod 1.12 compatible
- Plugin-based architecture: drop in new perks or classes via `RageCore` and optional skill plugins
- Configurable skill bindings per class via `configs/rage_class_skills.cfg` (special, secondary, tertiary, deploy)
- Modular perk system with negative effects and combo chaining; class-based skins and custom class definitions.
- New menu system. Hold ALT to show menu, move and select with WASD keys. Release ALT to exit.
- Additional admin menu aligned with the new menu system
- Toggle between 3rd person view modes. Either always, on melee weapon or off. Setting persists for clients.
- Optional HUD with alerts, class specific info, and stats.
- Expanded help system with class descriptions and tutorials
- Adjustable adrenaline, pills, revive and heal timings
- Integrated functionalities: Versus match countdown, multiple equipment, self healing with configurable bot support.
- Portable turrets with 20 different shooting modes
- Mines with 20 different types
- Ninja kick to the face, parachute glide and other enhancemenets for classes. See class description for more info.
- Missile functionality rewritten with more fun in mind. Shooter will be highlighted for other infected to kill. Missiles can be shot down. 
- Debug modes, logging, streamlined release and development flow. 

## Play your way

- Players have 3 extra skill actions + deploy action. These are configurable.
- Default inputs for the four actions are below; rebind them to your liking in `configs/rage_class_skills.cfg` or via your own keybinds.

| Action               | Default input              | Notes |
| -------------------- | -------------------------- | ----- |
| `skill_action_1`     | Middle button              | Primary class action |
| `skill_action_2`     | Use + Fire                 | Alternate class action |
| `skill_action_3`     | Crouch + Use + Fire        | Extra class action |
| `deployment_action`  | Look down and hold **Shift** | Deploy/place items |

- You can trigger actions from the quick menu as well.
- Update `configs/rage_skill_actions.cfg` if you remap these buttons so the in-game prompts match your binds.
- Multiple equipment mode
- You can configure the skills and add new ones

### Soldierboy
- Moves faster, shrugs off more hits, and slashes like a blender.
- Can order satellite strike on outside areas.
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
- Launches missiles with `SKILL ACTION 2`, homing missiles with `SKILL ACTION 3`
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
- Alliedmodders community
