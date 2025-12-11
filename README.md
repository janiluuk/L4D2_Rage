# L4D2: Rage Edition 🔥

**Ever wish Left 4 Dead 2 had more chaos, more power, and more ways to absolutely wreck zombies?** Well, you're in the right place.

This is what happens when players get tired of vanilla and decide to turn everything up to 11. We're talking classes with superpowers, abilities that make you feel like a badass, and enough customization to make every round feel fresh. Think of it as your favorite zombie shooter... but someone gave it steroids and a personality.

**Playing on a server?** Just join and start wrecking. Everything auto-binds, the menu remembers your choices, and you'll figure it out in like 30 seconds. Promise.

**Running a server?** Drop it in, tweak a few configs if you want, and watch your players have the time of their lives.

**Looking for the infected side?** Check out our companion mod [L4D2 Rage: Infected Edition](https://github.com/janiluuk/L4D2_Rage_Infected) for when you want to be the one causing chaos instead of surviving it!

---

## 📖 Documentation

**Need more details?** Check out our comprehensive [Documentation Manual](docs/README.md) covering:
- [Getting Started](docs/getting-started/) - Quick start guides for players and admins
- [Classes & Skills](docs/classes-skills/) - Complete class and ability reference
- [Features](docs/features/) - All gameplay features explained
- [Assets](docs/assets/) - Custom content and asset requirements
- [Testing](docs/testing/) - Test suite documentation
- [Development](docs/development/) - Developer guidelines and plugin integration

---

---

## Why You'll Love This 💪

**Pick Your Playstyle** – Six classes that actually feel different. Want to be a tank? Soldier's got you. Want to zoom around like a ninja? Athlete's your jam. Want to heal everyone and be the team MVP? Medic's waiting. Each class changes how you play, not just what color your name is.

**Abilities That Matter** – These aren't just "press button, do thing." These are "press button, call down orbital strikes" or "press button, go invisible and drop a fake corpse." Every ability feels impactful and changes the flow of combat.

**You're Never Helpless** – Downed? Revive yourself. Grabbed? Struggle free. Hanging off a ledge? Pull yourself up. This mod believes in second chances and giving you tools to save yourself when things go sideways.

**Controls That Make Sense** – Hold SHIFT to open the menu. Mouse buttons for abilities. WASD to navigate. It's intuitive, it auto-binds, and it just works. No memorizing 50 keybinds.

**It Remembers You** – Your class choice? Saved. Your music preference? Saved. Your camera mode? Saved. We remember what you like so you don't have to set it up every round.

**Customize Everything** – Want harder difficulty? Done. Want different cooldowns? Done. Want your own music? Done. Want to tweak every single ability? You guessed it—done. This is your server, make it yours.

---

## Quick Start (No Reading Required)

**Just Playing?** Here's all you need:
1. Join a server running Rage Edition
2. Hold **SHIFT** to open the menu
3. Pick a class—the menu will highlight your last choice
4. Your abilities auto-bind to **mouse3**, **mouse4**, and **mouse5**
5. Type `!guide` if you get confused (but you probably won't)

That's it. Seriously. Everything else you'll figure out by playing.

---

## ⚡ New Abilities (Because More Power = More Fun)

We just added some seriously cool abilities that make each class even more unique:

**⚡ Chain Lightning (Soldier)** – Aim at an enemy and watch lightning jump between up to 5 targets, dealing devastating damage. Perfect for clearing groups of infected in style. Each chain jumps to the nearest enemy, so position yourself well and watch the show.

**⏱️ Zed Time (Soldier)** – Activate slow motion that affects everyone on the server. Time slows to 30% speed for 5 seconds, giving you and your team a massive tactical advantage. Perfect for clutch escapes, precise shots, or just looking cool while you wreck everything.

**💨 Blink (Athlete)** – Short-range teleport that lets you instantly reposition or escape danger. Aim where you want to go and blink forward - perfect for quick escapes, repositioning during fights, or just looking like a ninja.

**🧗 Wall Run & Climb (Athlete)** – Automatically stick to walls when you jump near them. Run along walls with W/S, climb upward with JUMP. It's parkour at its finest - reach places other classes can't, traverse obstacles in style, and make mobility your weapon.

**☠️ Poison Melee (Saboteur)** – Your melee attacks automatically apply toxic damage over time. Enemies glow green and take continuous damage every second. Hit-and-run tactics just got a whole lot deadlier - strike, cloak away, and let the poison finish them off.

**👁️ Extended Sight (Saboteur)** – Already had this, but it's worth mentioning: see special infected through walls for 20 seconds. Call out targets, scout ahead, and be the team's eyes.

---

**Running a Server?** Here's the setup:
1. Drop the `sourcemod/` folder into your server directory
2. (Optional) Edit `configs/rage_class_skills.cfg` to customize classes
3. (Optional) Tweak `cfg/sourcemod/talents.cfg` for cooldowns and limits
4. Make sure you have the SourceMod **httpclient** extension (comes with SM 1.12+)
5. Restart and watch the magic happen

**Want it even easier?** Use Docker Compose—just run `docker-compose up` and everything works. No configuration, no headaches, just fun.

**Building from Source?** See the [Building & Testing](#building--testing) section below for complete instructions.

**Building from Source?** See the [For Developers & Modders](#for-developers--modders-build-your-own) section below for build instructions.

---

## How Abilities Work (The Simple Version)

Every class has special powers. Here's how you use them:

| What it does | Default controls | What it's for |
| ------------ | ---------------- | ------------ |
| **Skill Action 1** | Middle mouse button (mouse3) - **auto-bound** | Your class's main ability |
| **Skill Action 2** | Mouse4 (side button) - **auto-bound** OR Use + Fire together | Your secondary ability |
| **Skill Action 3** | Mouse5 (side button) - **auto-bound** OR Crouch + Use + Fire together | Your tertiary ability |
| **Deploy Action** | Hold **CTRL** (Left CTRL) | Drop turrets, supplies, or mines (menu opens) |

**The buttons auto-bind when you join.** No setup needed. But if you want to change them, type `!rage_bind` for instructions or add this to your autoexec.cfg:
```
bind mouse3 skill_action_1
bind mouse4 skill_action_2
bind mouse5 skill_action_3
```

**Don't have extra mouse buttons?** No problem—use the button combos instead. They work just as well.

---

## Meet Your Classes (The Real Talk Version)

### 🎖️ Soldier – The Tank
**The vibe:** You're the one who runs in first, takes the hits, and keeps going. Fast, tough, and hits like a truck.

**What you do:**
- **Satellite Strike** – Call down death from above (outdoor areas only, but it's worth it)
- **Chain Lightning** – Aim at an enemy and unleash lightning that jumps between up to 5 targets, dealing devastating area damage
- **Zed Time** – Activate slow motion that affects everyone, giving you and your team a tactical advantage in clutch moments

**What you get:**
- 300 HP (double the normal amount)
- 15% faster movement
- Melee weapons swing 2x faster
- Weapons fire 50% faster
- Better armor protection
- Night vision (because why not)

**Best for:** Players who like being in the thick of it and not dying.

---

### 🥷 Athlete (Ninja) – The Speed Demon
**The vibe:** You're fast, you're mobile, and you make parkour look easy. Double jump, wall run, and basically fly around the map.

**What you do:**
- **Ninja Kick** – Sprint + Jump to flying-kick enemies into oblivion
- **Blink** – Short-range teleport that lets you instantly reposition or escape danger (mouse4)
- **Anti-gravity Grenades** – Throw grenades that mess with physics (because normal grenades are boring)
- **High Jump** – Enhanced jump ability for reaching elevated positions (mouse5)

**Passive Features:**
- **Parachute** – Hold Use mid-air to glide down safely (always available, no cooldown)
- **Wall Run** – Automatically stick to walls and run along them (or climb upward) - parkour at its finest

**What you get:**
- 20% faster movement (fastest class)
- Jump way higher than normal
- Double jump (because one jump isn't enough)
- Bunnyhop chains for sustained speed
- Extended jump distance

**Best for:** Players who get bored standing still and love mobility.

---

### 💪 Commando – The Damage Dealer
**The vibe:** You're here to kill things. Fast. Reload faster, hit harder, and take down Tanks with your bare hands (okay, with melee, but still).

**What you do:**
- **Berserk Mode** – Build rage and unleash absolute chaos
- **Tank Knockdown** – Melee a Tank to stagger it (yes, really)

**What you get:**
- 300 HP (tank-level health)
- Reload 50% faster
- Bonus damage on every weapon type (pistols get +25, rifles get +10, etc.)
- Immune to Tank knockdowns
- Can stomp downed infected to finish them

**Best for:** Players who see a horde and think "target practice."

---

### ⚕️ Medic – The Team Player
**The vibe:** You're the reason everyone stays alive. Heal faster, drop supplies, and keep the team in fighting shape.

**What you do:**
- **Healing Grenades** – Throw a grenade that heals instead of hurts (game changer)
- **Healing Orb** – Summon glowing orbs that restore health to nearby players
- **Cleanse Bile** – Press Skill Action 3 or type `!unvomit` to clear boomer bile (120s cooldown)

**What you get:**
- Healing aura when crouching (heals nearby survivors for 10 HP every 2 seconds)
- 70% faster movement while healing (crouching)
- Revive teammates 50% faster
- Heal with medkits 50% faster

**Best for:** Players who get satisfaction from keeping everyone alive and being the team MVP.

---

### 🔧 Engineer – The Builder
**The vibe:** You fortify positions, deploy turrets, and rain experimental hell on zombies. You're the one who turns a bad spot into a fortress.

**What you do:**
- **Experimental Grenades** – 20 wild options: Black Hole vortexes, Tesla lightning, Airstrike markers, healing clouds, and more
- **Deploy Turrets** – Place auto-firing turrets with 20+ ammo types (regular bullets, explosive rounds, lasers, you name it)
- **Ammo Supplies** – Drop infinite ammo packs for your squad
- **Barricades** – Block doors and windows

**What you get:**
- Portable turrets (carry them around and redeploy)
- Standard health (150 HP, but you have turrets, so it's fine)

**Best for:** Players who love strategy, positioning, and having an answer for everything.

---

### 🕵️ Saboteur – The Stealth Specialist
**The vibe:** You sneak, you scout, and you plant deadly traps. You're the one who disappears when things get hairy and reappears when it's time to strike.

**What you do:**
- **Dead Ringer Cloak** – Go invisible and drop a fake corpse to fool infected (it's as cool as it sounds)
- **Extended Sight** – Reveal special infected positions for 20 seconds (every 2 minutes) - see through walls!
- **Poison Melee** – Your melee attacks automatically apply toxic damage over time - enemies glow green and take continuous damage
- **Deploy Mines** – Plant 20 different mine types with unique effects

**What you get:**
- Invisibility after crouching for 5 seconds
- Faster crouch movement while cloaked
- Optional night vision
- Reduced damage to survivors, but increased damage to infected
- Standard health (150 HP, but you're invisible, so it's fine)

**Best for:** Players who love stealth, strategy, and being sneaky.

---

### 🥊 Brawler – The Absolute Unit *(Experimental)*
**The vibe:** You're a walking tank. Massive health, soak damage, and keep going when everyone else would be dead.

**What you do:**
- **UnVomit (Cleanse Bile)** – Cleanse boomer bile from yourself

**What you get:**
- 600 HP (4x default health—yes, really)
- Designed to soak damage for the team

**Best for:** Players who want to be unkillable (still being tested, but it's fun).

---

## Survival Mechanics (Because We're Not Monsters)

**Never feel helpless again.** The Predicaments system gives you ways to save yourself and help teammates even when things go wrong:

**🩹 Self-Revival** – Incapacitated? Use pills, adrenaline, or medkits to revive yourself (hold CROUCH). No more waiting for someone to save you.

**🪢 Ledge Rescue** – Hanging off a ledge? Pull yourself up with medical items. Because falling to your death is lame.

**💪 Pin Escape** – Grabbed by a Smoker, Hunter, or Jockey? Struggle free by mashing CROUCH or consuming items. You're not helpless.

**🤝 Team Revival** – Down but not out? Revive other incapacitated teammates by pressing RELOAD. Be the hero.

**🐛 Crawl When Down** – Move while incapacitated to reach cover or supplies. Because lying there doing nothing is boring.

**📦 Grab Items** – Pick up nearby medical supplies even when incapacitated. Help yourself.

**🤖 Smart Bots** – Bots can revive themselves too (configurable). Even the AI gets second chances.

All settings live in `cfg/sourcemod/rage_survivor_predicament.cfg`. The important ones:
- `rage_survivor_predicament_enable` – Turn it on/off (default: 1)
- `rage_survivor_predicament_use` – Which items work: 0=none, 1=pills/adrenaline, 2=medkits, 3=both (default: 3)
- `rage_survivor_predicament_crawl_speed` – How fast you crawl (0.0-1.0, default: 0.15)

---

## Quality of Life Stuff (Because We Care)

**🎵 Music Player** – Type `!music` to pick your soundtrack, skip tracks, or mute it. Your preferences save between maps. Want DOOM music? We got you. Want silence? Also fine.

**🎮 Third-Person Camera** – Toggle between always-on, melee-only, or off. Your choice sticks with you. Some people love it, some hate it—you do you.

**🧠 Class Memory & Alerts** – Your saved class is preselected in the menu every round, and you'll get a quick reminder of your pick when the round begins. No more "wait, what class am I?"

**🚶 AFK Mode** – Need a break? Mark yourself away from the menu and your team knows you'll be back. It's the polite thing to do.

**🎯 Extended HUD** – Optional overlay with class info, cooldown timers, and stats. Turn it on if you like info, turn it off if you like clean screens.

**🗳️ Game Mode Voting** – Vote for custom game modes (Escort missions, Jockey chase, 1v1 deathmatch) and maps without typing commands. Democracy in action.

**🎮 Custom Game Modes** – Multiple game modes available:
- **GuessWho (Hide & Seek)** – One seeker hunts hiders who blend with props
- **Race Mod** – Race to the safe room, compete for points based on finish position
- More modes coming soon!

**⚙️ Multiple Equipment Mode** – Configure how forgiving item pickups are. Off = normal, Single Tap = one tap to switch, Double Tap = two taps to switch. Your choice, your preference.

**💬 Tutorial System** – Type `!guide` or `!ragetutorial` for an in-game tutorial covering classes, controls, skills, and tips. Never get lost again.

**🎮 Console Commands** – Every feature has an `sm_` command so you can create custom binds or macros. Power users, this one's for you.

---

## The In-Game Guide (Your New Best Friend)

Type `!guide` or `!ragetutorial` to open the full tutorial. It covers:
1. **Quick Start** – How to open the guide and get playing fast
2. **Survivor Classes** – Deep dives on all six classes
3. **Controls & Features** – Quick menu, skill buttons, third-person camera, HUD toggles, AFK mode, equipment settings
4. **Skills & Deployables** – How to use class abilities and deploy items
5. **Predicaments** – Survival mechanics explained
6. **Game Modes** – Overview of custom modes (GuessWho, Race Mod, and more)
7. **Gameplay Tips** – Pro strategies and tricks

Access any topic from the menu—it's like having a handbook built into the game. No alt-tabbing to a wiki, no searching forums. Just press a button and learn.

---

## Music Setup (Make It Yours) 🎵

Want a custom soundtrack? See **[MUSIC_SETUP_GUIDE.md](MUSIC_SETUP_GUIDE.md)** for complete step-by-step instructions.

**Quick Start:**
1. **Prepare audio files:** Convert to 44.1 kHz MP4 or WAV format
   ```bash
   ffmpeg -i your_track.mp3 -ar 44100 -ac 2 your_track.mp4
   ```

2. **Place files:** 
   - Docker: `custom/sound/music/your_track.mp4`
   - Manual: `left4dead2/sound/custom/rage/your_track.mp4`

3. **Add to list:** Edit `sourcemod/data/music_mapstart.txt`:
   ```
   custom/rage/your_track.mp4 TAG- Your Track Name
   ```

4. **Configure fast download:** Set in `server.cfg`:
   ```bash
   sv_allowdownload 1
   sv_downloadurl "http://your-content-server.com/left4dead2"
   ```

5. **Upload to web server:** Copy files to your fast download server

6. **Reload:** Use `sm_music_update` in-game or restart server

**Admin Menu:** Access music management via `!rageadm` → Music section:
- List all available tracks
- View current playing track
- Reload music list
- Play/Pause/Next track
- Select specific track to play

**Want it even easier?** Run `python custom/sound/music/download_soundtrack.py --out .` to grab the DOOM/DOOM II gamerip and Zorasoft's royalty-free Project Doom album.

The Docker Compose setup automatically mounts `custom/sound/music/` to `left4dead2/sound/custom/rage` so everything just works.

---

## Admin Tools (For Server Owners) 🛠️

Type `!rageadm` to open the admin panel with quick access to:
- Spawn helpers (items, infected, events)
- Restart controls
- God mode toggles
- Slow-motion effects
- HUD and music controls

Everything grouped for fast decisions mid-round. Because admins have better things to do than type commands.

---

## For Developers & Modders (Build Your Own)

Rage Edition is fully modular! Each class ability lives in its own plugin file, so you can:
- Add new talents without touching the core
- Swap out effects or create custom class packs
- Use the Rage API to hook into class systems

### Building & Testing

**Quick Build** – Run everything in one command:
```bash
./build.sh
```

This will:
1. ✅ Compile all plugins (`scripts/compile_plugins.sh`)
2. ✅ Run all tests (`tests/run_tests.sh`)
3. ✅ Optionally deploy to server (`scripts/deploy_plugins.sh` with `--deploy` flag)

**Build Options:**
```bash
# Standard build (compile + tests)
./build.sh

# Build without tests (faster compilation)
./build.sh --no-tests

# Build and deploy to server
./build.sh --deploy

# Show all options
./build.sh --help
```

**Individual Scripts:**
- `./scripts/compile_plugins.sh` – Compile plugins only
- `./tests/run_tests.sh` – Run all test suites
- `./tests/test_integration_detailed.sh` – Detailed integration tests
- `./tests/test_performance.sh` – Performance analysis
- `./tests/test_bugs.sh` – Bug detection
- `./tests/test_coverage.sh` – Coverage analysis
- `./scripts/deploy_plugins.sh` – Deploy to server (requires `.env`)

**Environment Setup for Deployment:**
1. Copy `.env.example` to `.env`
2. Fill in your RCON credentials:
   ```bash
   RCON_HOST=your.server.com
   RCON_PORT=27022
   RCON_PASSWORD=your_password
   ```
3. Run `./build.sh --deploy` to compile, test, and deploy

**Test Coverage:**
- ✅ 30+ basic tests (compilation, configuration, code quality)
- ✅ 40+ integration tests (classes, skills, menus, equipment)
- ✅ Performance tests (timer leaks, entity leaks, memory usage)
- ✅ Bug detection (common SourceMod issues)
- ✅ Coverage analysis (identifies untested areas)

All tests run automatically during build unless disabled with `--no-tests`.

### Code Architecture

The codebase is organized for modularity and maintainability:

**Core System:**
- **RageCore** (`include/RageCore.inc`) – Class and perk system foundation
- **rage_survivor.sp** – Main plugin that manages classes and skill registration
- **rage_class_skills.cfg** – Configuration file defining which skills each class gets

**Skill Plugins** (`rage_survivor_plugin_*.sp`):
- Individual abilities as separate plugins (airstrike, berserk, grenades, turrets, etc.)
- Each plugin registers with the Rage system via `RegisterRageSkill`
- Plugins can be enabled/disabled independently

**Shared Utilities** (`include/rage/`):
- `rage/effects.inc` – Particle effects, explosions, visual effects
- `rage/validation.inc` – Client and entity validation functions
- `rage/debug.inc` – Unified debug system (replaces per-plugin debug flags)
- `rage/timers.inc` – Timer callbacks and management
- `rage/skills.inc` – Skill registration API and callbacks
- `rage/menus.inc` – Menu system integration
- `rage/const.inc` – Shared constants and enums

**Plugin Naming:** All plugins use the `[RAGE]` prefix for consistency and easy identification.

**Game Modes** (`sourcemod/scripting/gamemodes/`):
- `rage_gamemode_guesswho.sp` – Hide & Seek game mode
- `rage_gamemode_race.sp` – Race to safe room competition mode
- `rage_tests_gamemodes.sp` – Test suite for gamemode functionality

**Testing:** The comprehensive test suite ensures code quality, catches bugs early, and verifies integration between systems. Run `./tests/run_tests.sh` anytime to verify everything works.

Want to build something? The code is ready for you. We believe in open source and community contributions.

---

## Troubleshooting (When Things Go Wrong)

**Missing map entities?** If the server log shows messages like `Couldn't find any entities named fire13_timer`, the map is missing some entities. The fix:
- **Verify the BSP and workshop files.** Redownload the affected campaign/workshop map
- **Patch with Stripper** if you can't rebuild the map. Add the missing entities under `left4dead2/addons/stripper/maps/<mapname>.cfg`
- **Source for the entities.** Copy the entity definitions from the map author's VMF/decompiled BSP or request the fixed map from the campaign's workshop page

These errors are map-content issues—once the missing template members exist in the map or Stripper config, the log spam stops and scripted fires/sounds will spawn correctly.

---

## Credits (The People Who Made This Possible)

Rage Edition is powered by community talent and open-source awesomeness. Big thanks to:

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

**This is a community project, built by players, for players. Enjoy the chaos!**
