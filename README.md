# L4D2: Rage Edition 🔥

Transform Left 4 Dead 2 into an action-packed versus and co-op experience! Pick your class, unleash devastating abilities, and survive the chaos with friends. Think of it as your favorite zombie shooter... but turned up to 11.

**Looking for the infected side?** Check out the companion mod [L4D2 Rage: Infected Edition](https://github.com/janiluuk/L4D2_Rage_Infected) for enhanced special infected gameplay!

## What Makes It Special? ✨

**Choose Your Hero** – Six unique classes (Soldier, Ninja, Trooper, Medic, Engineer, Saboteur) each with their own superpowers and playstyle

**Epic Abilities** – Deploy turrets, throw experimental grenades, go invisible, heal teammates, call in airstrikes, and way more

**Survival Tools** – Self-revive when downed, crawl while incapacitated, struggle free from infected pins, and help your teammates even when you're down

**Slick Controls** – Hold V (voice key) for a radial menu that lets you change classes, toggle settings, and trigger abilities—all with WASD navigation

**Custom Everything** – Play your own music, customize every ability, adjust difficulty, and tinker with 100+ settings

**Built for Fun** – Less grind, more action. Every round feels like a blockbuster movie scene

## Getting Started (Super Easy!)

**For Players:**
1. Join a server running Rage Edition
2. Press V (default voice key) to open the quick menu
3. Pick your class and learn your abilities from the menu
4. Type `!guide` in chat to open the full tutorial anytime

**For Server Owners:**
1. Drop the `sourcemod/` folder into your L4D2 server directory
2. Edit `configs/rage_class_skills.cfg` to customize classes and abilities
3. (Optional) Tweak settings in `cfg/sourcemod/talents.cfg` for cooldowns and limits
4. Restart your server and you're good to go!

**Pro tip:** Use Docker Compose if you want a one-click setup—just run `docker-compose up` and everything works out of the box.

## How to Use Your Abilities

Every class has special powers! Here's how to trigger them:

| What it does | Default controls | Quick tip |
| ------------ | ---------------- | --------- |
| **Main ability** | Middle mouse button | Your class's signature move |
| **Second ability** | Use + Fire together | Combo power |
| **Third ability** | Crouch + Use + Fire | Extra trick up your sleeve |
| **Deploy stuff** | Look down + Hold Shift | Drop turrets, supplies, or mines |

**Too complicated?** Just press V and select abilities from the quick menu instead!

You can also rebind these in `configs/rage_skill_actions.cfg` or use console commands like `skill_action_1`, `skill_action_2`, etc.

## Meet Your Squad 💪

### 🎖️ Soldier (Soldierboy)
The frontline tank who takes hits and keeps moving. Fast on his feet, tough as nails, and lethal with melee weapons.
- **Satellite Strike** – Call down devastation from orbit on outdoor areas
- **Homing Missile** – Fire a heat-seeking rocket at your target
- **Decoy Missile** – Launch a dummy to distract infected
- **Night Vision** – See in the dark like it's daytime
- **Bonus:** Extra health and armor to survive the chaos

### 🥷 Ninja (Athlete)
Speed demon built for parkour and aerial combat. Double jump, wall run, and float over danger.
- **Ninja Kick** – Sprint + Jump to flying-kick enemies into oblivion
- **Parachute** – Hold Use mid-air to glide down safely
- **Anti-gravity Grenades** – Throw grenades that mess with physics
- **Bonus:** Lightning-fast movement and supreme agility

### ⚔️ Trooper (Commando)
Pure damage output. Reloads faster, hits harder, and can take down a Tank hand-to-hand.
- **Berserk Mode** – Build rage and unleash a devastating rampage
- **Satellite Cannon** – Another orbital option for crowd control
- **Tank Knockdown** – Melee a Tank to stagger it
- **Bonus:** Massive health pool for sustained combat

### ⚕️ Medic
Your team's lifeline. Heals faster, drops supplies, and keeps everyone alive.
- **Healing Grenades** – Throw a grenade that heals instead of hurts
- **Healing Orb** – Summon glowing orbs that restore health to nearby players
- **Cleanse Bile** – Remove boomer bile from teammates
- **Deploy Supplies** – Drop medkits and defibs for your team
- **Bonus:** Speed boost while healing, better revival times

### 🔧 Engineer
The builder who fortifies positions and rains experimental hell on zombies.
- **Deploy Turrets** – Place auto-firing turrets with 20+ ammo types (regular bullets, explosive rounds, lasers, you name it)
- **Experimental Grenades** – 20 wild options: Black Hole vortexes, Tesla lightning, Airstrike markers, healing clouds, and more
- **Ammo Supplies** – Drop infinite ammo packs for your squad
- **Barricades** – Block doors and windows
- **Bonus:** Turrets can be carried around and redeployed

### 🕵️ Saboteur
The stealth specialist who sneaks, scouts, and plants deadly traps.
- **Dead Ringer Cloak** – Go invisible and drop a fake corpse to fool infected
- **Extended Sight** – Reveal special infected positions for 20 seconds (every 2 minutes)
- **Deploy Mines** – Plant 20 different mine types with unique effects
- **Bonus:** Faster crouch movement with invisibility, reduced survivor damage but increased infected damage

### 🥊 Brawler *(Experimental)*
Heavy-duty tank class with massive health for soaking damage. Still being tested!
- **Bonus:** Huge health pool to take punishment for your team

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
