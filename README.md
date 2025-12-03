# L4D2: Rage Edition 🔥

Transform Left 4 Dead 2 into an action-packed versus and co-op experience! Pick your class, unleash devastating abilities, and survive the chaos with friends. Think of it as your favorite zombie shooter... but turned up to 11.

**Looking for the infected side?** Check out the companion mod [L4D2 Rage: Infected Edition](https://github.com/janiluuk/L4D2_Rage_Infected) for enhanced special infected gameplay!

## What Makes It Special? ✨

**Choose Your Hero** – Six unique classes (Soldier, Ninja, Trooper, Medic, Engineer, Saboteur) each with their own superpowers and playstyle

**Epic Abilities** – Deploy turrets, throw experimental grenades, go invisible, heal teammates, call in airstrikes, and way more

**Survival Tools** – Self-revive when downed, crawl while incapacitated, struggle free from infected pins, and help your teammates even when you're down

**Slick Controls** – Tap X (voice menu) for a quick Rage menu that lets you change classes, toggle settings, and trigger abilities—all with WASD navigation

**Smart Menu Memory** – Your chosen class is saved between rounds, preselected when the menu opens, and announced at round start so you always know what you’re running

**Custom Everything** – Play your own music, customize every ability, adjust difficulty, and tinker with 100+ settings

**Built for Fun** – Less grind, more action. Every round feels like a blockbuster movie scene

## Getting Started (Super Easy!)

**For Players:**
1. Join a server running Rage Edition
2. The menu is automatically bound to the **V** key on first join (or **SHIFT** if configured by server)—just hold to open, release to close
3. Skill actions are automatically bound to mouse buttons: **mouse3** (middle), **mouse4**, and **mouse5**
4. You can also press **X** (voice menu key) for quick access, or type `!rage_bind` to change the key
5. Pick your class and learn your abilities from the menu—the menu remembers your last choice and will highlight it next time
6. Type `!guide` in chat to open the full tutorial anytime

**For Server Owners:**
1. Drop the `sourcemod/` folder into your L4D2 server directory
2. Edit `configs/rage_class_skills.cfg` to customize classes and abilities
3. (Optional) Tweak settings in `cfg/sourcemod/talents.cfg` for cooldowns and limits
4. (Optional) Change the default menu bind key in `cfg/sourcemod/rage_survivor_menu.cfg` - set `rage_menu_default_key` to "v" (default), "shift", or any other key
5. Make sure the SourceMod **httpclient** extension is installed (ships with SM 1.12+); place `httpclient.ext.*` binaries in `addons/sourcemod/extensions/`
6. Restart your server and you're good to go!

**Pro tip:** Use Docker Compose if you want a one-click setup—just run `docker-compose up` and everything works out of the box.

## How to Use Your Abilities

Every class has special powers! Here's how to trigger them:

| What it does | Default controls | Quick tip |
| ------------ | ---------------- | --------- |
| **Skill Action 1** | Middle mouse button (mouse3) - **auto-bound** | Your class's signature move |
| **Skill Action 2** | Mouse4 (side button) - **auto-bound** OR Use + Fire together | Secondary ability |
| **Skill Action 3** | Mouse5 (side button) - **auto-bound** OR Crouch + Use + Fire t   ogether | Tertiary ability |
| **Deploy Action** | Look down + CROUCH + SHOVE (button combo, no key) | Drop turrets, supplies, or mines |

**Automatic Bindings:**
- **Menu**: Automatically bound to **V** key (or **SHIFT** if server configured) on first join
- **Skill Actions**: Automatically bound to **mouse3**, **mouse4**, and **mouse5** when you join or respawn
- You can also press **X** (voice menu key) to access the menu instantly

**Want to change keys?**
- **Menu key**: Type `!rage_bind` in chat for instructions, or add this to your autoexec.cfg:
  ```
  bind <key> +rage_menu  // Hold to open menu, release to close
  ```
- **Skill action keys**: Manually rebind in console or autoexec.cfg:
  ```
  bind mouse3 skill_action_1
  bind mouse4 skill_action_2
  bind mouse5 skill_action_3
  ```
- **Alternative**: Use button combinations (Use+Fire, Crouch+Use+Fire) instead of mouse buttons
- **Configuration**: Edit `configs/rage_skill_actions.cfg` to customize the display labels shown in-game

### Skills & Deployment Quick Reference

Every class has up to 3 skill actions and 1 deployment action. All skill actions can be rebound in `configs/rage_skill_actions.cfg`.

| Class | Skill Action 1 | Skill Action 2 | Skill Action 3 | Deployment Action |
| ----- | -------------- | -------------- | -------------- | ----------------- |
| **Soldier** | Satellite Strike | Homing Missile (Type 1) | Decoy Missile (Type 2) | Engineer Supplies Menu |
| **Athlete** | Anti-gravity Grenades | None | None | Medic Supplies Menu |
| **Medic** | Healing Grenades | Healing Orb | UnVomit (Cleanse Bile) | Medic Supplies Menu |
| **Saboteur** | Dead Ringer Cloak | None | None | Saboteur Mines Menu |
| **Commando** | Berzerk Rage | None | None | Engineer Supplies Menu |
| **Engineer** | Experimental Grenades | Multiturret | None | Engineer Supplies Menu |
| **Brawler** | UnVomit (Cleanse Bile) | None | None | Medic Supplies Menu |

**Default Key Bindings:**
- **Menu**: **V** key (or **SHIFT** if server configured) - automatically bound on first join
- **Skill Action 1**: **mouse3** (middle mouse button) - automatically bound to `skill_action_1` command
- **Skill Action 2**: **mouse4** (mouse side button) - automatically bound to `skill_action_2` command, OR use **Use + Fire** button combo
- **Skill Action 3**: **mouse5** (mouse side button) - automatically bound to `skill_action_3` command, OR use **Crouch + Use + Fire** button combo
- **Deployment Action**: **Look down + CROUCH + SHOVE** (button combination, no automatic key binding)

**Note:** All mouse button bindings are automatically set when you join the server or respawn. You can also manually bind keys in console:
```
bind mouse3 skill_action_1
bind mouse4 skill_action_2  
bind mouse5 skill_action_3
```
Or use the button combinations above if you prefer not to use mouse buttons.

## Meet Your Squad 💪

### 🎖️ Soldier (Soldierboy)
The frontline tank who takes hits and keeps moving. Fast on his feet, tough as nails, and lethal with melee weapons.

**Active Skills:**
- **Satellite Strike** – Call down devastation from orbit on outdoor areas
- **Homing Missile** – Fire a heat-seeking rocket at your target
- **Decoy Missile** – Launch a dummy to distract infected

**Passive Perks:**
- **Increased Health** – 300 HP (2x default)
- **Movement Speed** – 15% faster than normal
- **Faster Melee Attacks** – Swing melee weapons 2x faster
- **Faster Weapon Attacks** – Shoot weapons 50% faster
- **Enhanced Armor** – Armor reduces damage by 25% more effectively
- **Night Vision** – See in the dark like it's daytime

### 🥷 Ninja (Athlete)
Speed demon built for parkour and aerial combat. Double jump, wall run, and float over danger.

**Active Skills:**
- **Ninja Kick** – Sprint + Jump to flying-kick enemies into oblivion
- **Parachute** – Hold Use mid-air to glide down safely
- **Anti-gravity Grenades** – Throw grenades that mess with physics

**Passive Perks:**
- **Movement Speed** – 20% faster than normal (fastest class)
- **High Jump** – Jump much higher than normal
- **Double Jump** – Perform a second jump mid-air for extra mobility
- **Bunnyhop** – Chain jumps together for sustained speed
- **Long Jump** – Extended jump distance

### ⚔️ Trooper (Commando)
Pure damage output. Reloads faster, hits harder, and can take down a Tank hand-to-hand.

**Active Skills:**
- **Berserk Mode** – Build rage and unleash a devastating rampage
- **Tank Knockdown** – Melee a Tank to stagger it

**Passive Perks:**
- **Increased Health** – 300 HP (2x default)
- **Faster Reload** – Reload 50% faster than normal
- **Weapon Damage Bonuses** – Increased damage per weapon type:
  - Pistol: +25 damage
  - Grenade: +20 damage
  - Sniper/Hunting Rifle: +15 damage
  - Rifle: +10 damage
  - SMG: +7 damage
  - Shotgun: +5 damage
  - Default: +5 damage
- **Tank Immunity** – Immune to Tank knockdowns
- **Stomping** – Can stomp downed infected to finish them

### ⚕️ Medic
Your team's lifeline. Heals faster, drops supplies, and keeps everyone alive.

**Active Skills:**
- **Healing Grenades** – Throw a grenade that heals instead of hurts
- **Healing Orb** – Summon glowing orbs that restore health to nearby players
- **Cleanse Bile** – Press Skill Action 3 (shown in-game) or `!unvomit` while covered to clear boomer bile (120s cooldown)

**Passive Perks:**
- **Healing Aura** – Heals nearby survivors for 10 HP every 2 seconds when crouching (256 unit range)
- **Speed Boost** – 70% faster movement while healing (crouching)
- **Faster Revive** – Revive teammates 50% faster
- **Faster Healing** – Heal with medkits 50% faster

### 🔧 Engineer
The builder who fortifies positions and rains experimental hell on zombies.

**Active Skills:**
- **Experimental Grenades** – 20 wild options: Black Hole vortexes, Tesla lightning, Airstrike markers, healing clouds, and more
- **Deploy Turrets** – Place auto-firing turrets with 20+ ammo types (regular bullets, explosive rounds, lasers, you name it)
- **Ammo Supplies** – Drop infinite ammo packs for your squad
- **Barricades** – Block doors and windows

**Passive Perks:**
- **Portable Turrets** – Turrets can be carried around and redeployed
- Standard health (150 HP)

### 🕵️ Saboteur
The stealth specialist who sneaks, scouts, and plants deadly traps.

**Active Skills:**
- **Dead Ringer Cloak** – Go invisible and drop a fake corpse to fool infected
- **Extended Sight** – Reveal special infected positions for 20 seconds (every 2 minutes)
- **Deploy Mines** – Plant 20 different mine types with unique effects

**Passive Perks:**
- **Invisibility** – Become invisible after crouching for 5 seconds
- **Faster Crouch Movement** – Move faster while crouching and cloaked
- **Night Vision** – Optional night vision capability
- **Damage Profile** – Reduced damage to survivors, but increased damage to infected
- Standard health (150 HP)

### 🥊 Brawler *(Experimental)*
Heavy-duty tank class with massive health for soaking damage. Still being tested!

**Active Skills:**
- **UnVomit (Cleanse Bile)** – Cleanse boomer bile from yourself

**Passive Perks:**
- **Massive Health Pool** – 600 HP (4x default health!)
- Designed to soak damage for the team

## Survival Mechanics (Predicaments System)

Never feel helpless again! The Predicaments system gives you ways to save yourself and help teammates even when things go wrong:

**🩹 Self-Revival** – Incapacitated? Use pills, adrenaline, or medkits to revive yourself (hold CROUCH)

**🪢 Ledge Rescue** – Hanging off a ledge? Pull yourself up with medical items

**💪 Pin Escape** – Grabbed by a Smoker, Hunter, or Jockey? Struggle free by mashing CROUCH or consuming items

**🤝 Team Revival** – Down but not out? Revive other incapacitated teammates by pressing RELOAD

**🐛 Crawl When Down** – Move while incapacitated to reach cover or supplies

**📦 Grab Items** – Pick up nearby medical supplies even when incapacitated

**🤖 Smart Bots** – Bots can revive themselves too (configurable)

All settings live in `cfg/sourcemod/rage_survivor_predicament.cfg`. The key ones:
- `rage_survivor_predicament_enable` – Turn it on/off (default: 1)
- `rage_survivor_predicament_use` – Which items work: 0=none, 1=pills/adrenaline, 2=medkits, 3=both (default: 3)
- `rage_survivor_predicament_crawl_speed` – How fast you crawl (0.0-1.0, default: 0.15)

## Fun Extras & Quality of Life

**🎵 Music Player** – Type `!music` to pick your soundtrack, skip tracks, or mute it. Your preferences save between maps.

**🎮 Third-Person Camera** – Toggle between always-on, melee-only, or off. Your choice sticks with you.

**🧠 Class Memory & Alerts** – Your saved class is preselected in the menu every round, and you’ll get a quick reminder of your pick when the round begins.

**🚶 AFK Mode** – Need a break? Mark yourself away from the menu and your team knows you'll be back.

**🎯 Extended HUD** – Optional overlay with class info, cooldown timers, and stats.

**🗳️ Game Mode Voting** – Vote for custom game modes (Escort missions, Jockey chase, 1v1 deathmatch) and maps without typing commands.

**⚙️ Multiple Equipment Mode** – Configure how forgiving item pickups are, from classic single-use to double-tap weapon swaps.

**💬 Tutorial System** – Type `!guide` or `!ragetutorial` for an in-game tutorial covering classes, controls, skills, and tips. Never get lost again!

**🎮 Console Commands** – Every feature has an `sm_` command so you can create custom binds or macros.

## Built-in Tutorials

The in-game guide (`!guide` or `!ragetutorial`) covers everything you need:

1. **Quick Start** – How to open the guide and get playing fast
2. **Survivor Classes** – Deep dives on all six classes (Soldier, Athlete/Ninja, Commando/Trooper, Medic, Engineer, Saboteur)
3. **Controls & Features** – Quick menu, skill buttons, third-person camera, HUD toggles, AFK mode, equipment settings
4. **Skills & Deployables** – How to use class abilities and deploy items
5. **Predicaments** – Survival mechanics explained
6. **Game Modes** – Overview of custom modes
7. **Gameplay Tips** – Pro strategies and tricks

Access any topic from the menu—it's like having a handbook built into the game!

## Music Setup 🎵

Want a custom soundtrack? Easy!

1. Put 44.1 kHz audio files (WAV or MP4) in the `music/` folder
2. List them in `sourcemod/data/music_mapstart*.txt` (use paths like `custom/rage/my_track.wav`)
3. Point your fast-download host at the files
4. Restart the server and players can choose tracks with `!music`

**Instant Soundtrack:** Run `python music/download_soundtrack.py --out music` to grab the DOOM/DOOM II gamerip and Zorasoft's royalty-free Project Doom album. No manual downloads needed!

The Docker Compose setup automatically mounts `music/` to `left4dead2/sound/custom/rage` so everything just works.

## Admin Tools 🛠️

Type `!rageadm` to open the admin panel with quick access to:
- Spawn helpers (items, infected, events)
- Restart controls
- God mode toggles
- Slow-motion effects
- HUD and music controls

Everything grouped for fast decisions mid-round.

## For Developers & Modders

Rage Edition is fully modular! Each class ability lives in its own plugin file, so you can:
- Add new talents without touching the core
- Swap out effects or create custom class packs
- Use the Rage API to hook into class systems

Check `sourcemod/scripting/` for clean, documented examples. The architecture:
- **RageCore** – Class and perk system
- **Skill plugins** – Individual abilities (airstrike, berserk, grenades, turrets, etc.)
- **rage_class_skills.cfg** – Define which skills each class gets
- **Include files** – Shared utilities and APIs in `sourcemod/scripting/include/rage/`

Want to build something? The code is ready for you.

## Troubleshooting missing map entities

If the server log shows messages like `Couldn't find any entities named fire13_timer, which point_template fire13_template is specifying`, the running BSP is missing the child entities that a `point_template` expects to clone. The fix must be applied to the map files, not the gameplay plugins:

- **Verify the BSP and workshop files.** Redownload the affected campaign/workshop map so the original template children (timers, smoke, hurt volumes, decals, sounds) are present in the `left4dead2/maps/*.bsp` bundle.
- **Patch with Stripper if you cannot rebuild the map.** Add the missing entities under `left4dead2/addons/stripper/maps/<mapname>.cfg` (e.g., `fire13_timer`, `fire13_clip`, `fire13_smoke`, `fire13_fog_volume`, or `fire_ballroom_07-sound`). Stripper runs server-side and can recreate those entities at load time.
- **Source for the entities.** Copy the entity definitions from the map author's VMF/decompiled BSP or request the fixed map from the campaign’s workshop page; the names in the error text tell you which blocks to restore.

These errors are map-content issues—once the missing template members exist in the map or Stripper config, the log spam stops and scripted fires/sounds will spawn correctly.

## Credits

Rage Edition is powered by community talent and open-source awesomeness:

- **Core talents and class system** by DLR team, Ken, Neil, Spirit, panxiaohai, and Yani
- **Scripted HUD** by Mart and Yani
- **Menu system, airstrike, grenades, and Left 4 DHooks utilities** by SilverShot (Silvers)
- **Satellite cannon** by ztar
- **Music player** by Dragokas
- **Tutorial guide and Dead Ringer cloak** by Yani and Shadowysn
- **Jump and utility plugins** from zonde306 and Yani, plus shanapu's parachute logic
- **Enhanced graphics and custom Adawong model** by LuxLuma
- **Custom soundtrack ripping** by Zorasoft
- **Sound effects and event themes** by Yaniho
- **Predicaments plugin** based on Pan Xiaohai's work, enhanced by cravenge and Yani
- **Alliedmodders community** for tools and support

Thank you to everyone who made this possible! 🙌
