# L4D2 Rage Edition - Complete Classes & Skills Guide

This comprehensive guide covers all survivor classes, their abilities, perks, and strategies in L4D2 Rage Edition.

## Table of Contents

- [Overview](#overview)
- [Class System](#class-system)
- [Soldier - Frontline Tank](#soldier---frontline-tank)
- [Athlete - Speed Demon](#athlete---speed-demon)
- [Medic - Team Support](#medic---team-support)
- [Saboteur - Stealth Specialist](#saboteur---stealth-specialist)
- [Commando - Damage Dealer](#commando---damage-dealer)
- [Engineer - Builder](#engineer---builder)
- [Brawler - Heavy Tank (Experimental)](#brawler---heavy-tank-experimental)
- [Skill Actions Reference](#skill-actions-reference)
- [Class Selection Tips](#class-selection-tips)

---

## Overview

L4D2 Rage Edition features 7 distinct survivor classes, each with unique abilities, passive perks, and playstyles. Classes are designed to encourage teamwork and provide diverse tactical options during gameplay.

### Class Selection

- Hold **SHIFT** to open the quick menu
- Navigate with **1/2/3/4** keys (movement NOT blocked)
- Your last selected class is remembered and highlighted
- Use **7/8/9** for menu page navigation

### Ability Controls

| Action | Default Control | Alternative |
|--------|----------------|-------------|
| **Skill Action 1** (Primary) | Mouse3 (middle click) | Auto-bound on join |
| **Skill Action 2** (Secondary) | Mouse4 (side button) | Use + Fire together |
| **Skill Action 3** (Tertiary) | Mouse5 (side button) | Crouch + Use + Fire together |
| **Deploy Action** | Hold CTRL (Left CTRL) | Opens deployment menu |

> **Note:** Controls auto-bind when you join the server. Type `!rage_bind` for manual binding instructions.

---

## Class System

### Configuration

Classes and their skill assignments are configured in:
```
sourcemod/configs/rage_class_skills.cfg
```

Each class can have:
- **Special** (Primary skill) - Main class-defining ability
- **Secondary** - Support or utility skill
- **Tertiary** - Additional skill or cleanse ability  
- **Deploy** - Equipment/supply deployment

### Skill Types

1. **skill:SkillName[:type]** - Triggers a registered Rage skill with optional type parameter
2. **command:Plugin:Type** - Calls useCustomCommand for specific plugin functionality
3. **builtin:action** - Built-in actions (supply menus, turrets, mines)
4. **none** - Disables the binding

---

## Soldier - Frontline Tank

**Role:** Heavy assault, frontline combat, area denial

**Description:** Frontline fighter with faster movement, heavier armor, and brutal melee swings. The Soldier excels at leading charges and controlling large groups of infected.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **Satellite Strike** | Mouse3 | 30s | Calls down orbital strike on targeted area (outdoor only) |
| **Chain Lightning** | Mouse4 | 30s | Unleashes lightning that chains between up to 5 enemies |
| **Zed Time** | Mouse5 | 60s | Activates slow motion (30% speed) for 5 seconds affecting entire server |

### Passive Perks

- **300 HP** - Double the default health pool
- **+15% Movement Speed** - Faster than base survivors
- **2x Melee Attack Speed** - Swing melee weapons twice as fast
- **+50% Weapon Fire Rate** - All guns fire faster
- **Enhanced Armor** - Better damage reduction
- **Night Vision** - Toggle with skill to see in darkness

### Playstyle & Strategy

**Strengths:**
- Excels at holding chokepoints
- Strong in outdoor areas with Satellite Strike
- Effective against hordes with Chain Lightning
- Team-wide utility with Zed Time for clutch moments

**Best For:**
- Players who like being on the front lines
- Leading team pushes through horde concentrations
- Tank control and area denial

**Tips:**
- Save Satellite Strike for Tank encounters or massive hordes
- Chain Lightning works best when enemies are grouped
- Use Zed Time when team needs breathing room (everyone benefits)
- Your high health makes you ideal for drawing aggro

---

## Athlete - Speed Demon

**Role:** Mobility specialist, scout, flanker

**Description:** Movement expert with high jumps, aerial control, and a parachute for safe drops. The Athlete makes parkour look easy with enhanced mobility and physics-defying abilities.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **Anti-Gravity Grenades** | Mouse3 | 15s | Throws grenades that manipulate physics and send infected flying |
| **Blink** | Mouse4 | 8s | Short-range teleport (300-500 units) in aim direction |
| **High Jump** | Mouse5 | 5s | Enhanced jump for reaching elevated positions |

### Passive Abilities

| Ability | Control | Cooldown | Description |
|---------|---------|----------|-------------|
| **Parachute** | Hold USE in air | None | Glide down safely from any height |
| **Wall Run & Climb** | Auto-activates | None | Stick to walls, run along them (W/S), climb with JUMP |
| **Double Jump** | Jump in air | None | Jump twice for extended air time |
| **Ninja Kick** | Sprint + Jump | None | Flying kick that damages and knocks back enemies |

### Passive Perks

- **+20% Movement Speed** - Fastest class in the game
- **Enhanced Jump Height** - Jump significantly higher
- **Double Jump** - Second jump while airborne
- **Bunny Hop Chains** - Sustained speed through consecutive jumps
- **Extended Jump Distance** - Cover more ground per jump

### Playstyle & Strategy

**Strengths:**
- Unmatched mobility and map traversal
- Can reach normally inaccessible areas
- Excellent at kiting and evasion
- Great for scouting ahead or flanking

**Best For:**
- Players who get bored standing still
- Speed runners and parkour enthusiasts
- Tactical flanking and repositioning

**Tips:**
- Wall Run automatically activates near walls - use W/S to move along them
- Hold USE mid-air for parachute - no fall damage ever
- Blink has line-of-sight requirement in default config
- Ninja Kick great for clearing path through common infected
- Use mobility to rescue incapped teammates quickly

---

## Medic - Team Support

**Role:** Healer, support, team sustain

**Description:** Team sustain lead who heals faster, drops supplies, and throws restorative grenades. The Medic keeps everyone alive and in fighting shape.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **Healing Grenades** | Mouse3 | 20s | Throws grenade that heals nearby survivors instead of damaging |
| **Healing Orb** | Mouse4 | 30s | Summons glowing orbs that restore health to nearby players |
| **Cleanse Bile (UnVomit)** | Mouse5 | 120s | Instantly clears boomer bile effect |

### Deploy Actions

| Action | Control | Description |
|--------|---------|-------------|
| **Medical Supplies** | Hold CTRL | Opens menu to drop medkits, pills, adrenaline, defibs |

### Passive Perks

- **Healing Aura** - When crouching, heal nearby survivors for 10 HP every 2 seconds
- **+70% Crouch Movement Speed** - Move fast while healing
- **+50% Revive Speed** - Get teammates up faster
- **+50% Medkit Healing Speed** - Apply medkits in half the time
- **Standard Health** - 150 HP (default)

### Playstyle & Strategy

**Strengths:**
- Keeps team alive through sustained healing
- Excellent in prolonged engagements
- Can clear bile quickly (crucial during Tank fights)
- Supplies team with medical items

**Best For:**
- Players who enjoy support roles
- Team-oriented gameplay
- Being the MVP who keeps everyone alive

**Tips:**
- Position healing grenades to cover multiple teammates
- Crouch near injured teammates to trigger healing aura
- Save UnVomit for critical moments (120s cooldown)
- Drop supplies strategically before major engagements
- Your speed while crouching makes you effective combat medic

---

## Saboteur - Stealth Specialist

**Role:** Stealth, reconnaissance, trap placement

**Description:** Stealthy scout with cloak, fast crouch movement, and a toolkit of motion-sensitive mines. The Saboteur strikes from the shadows and sets deadly traps.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **Dead Ringer Cloak** | Mouse3 | 45s | Go invisible and drop fake corpse to fool infected |
| **Extended Sight** | Mouse4 | 120s | Reveal special infected positions through walls for 20 seconds |
| **Poison Melee** | Mouse5 | Passive | Melee attacks apply toxic damage over time (enemies glow green) |

### Deploy Actions

| Action | Control | Description |
|--------|---------|-------------|
| **Deploy Mines** | Hold CTRL | Opens menu with 20 different mine types and effects |

### Passive Perks

- **Auto-Cloak** - Become invisible after crouching for 5 seconds
- **+Faster Crouch Speed** - Move faster while cloaked
- **Night Vision** - Optional toggle for dark areas
- **Reduced Friendly Fire** - Deal less damage to survivors
- **Increased Infected Damage** - Deal more damage to infected
- **Standard Health** - 150 HP

### Playstyle & Strategy

**Strengths:**
- Can scout ahead safely with cloak
- Extended Sight provides intel to entire team
- Mines provide area control and denial
- Poison melee for hit-and-run tactics

**Best For:**
- Players who love stealth gameplay
- Strategic, tactical thinking
- Surprise attacks and ambushes

**Tips:**
- Dead Ringer drops a fake corpse - infected will attack it
- Use Extended Sight to call out special infected positions
- Place mines at chokepoints before major hordes
- Poison melee applies DoT - hit and cloak away
- Crouch for 5 seconds anywhere to auto-cloak

---

## Commando - Damage Dealer

**Role:** DPS, crowd control, Tank fighter

**Description:** Damage specialist with faster reloads, heavier hits, and crowd control during Tank fights. The Commando is built for maximum kill efficiency.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **Berserk Mode** | Mouse3 | 60s | Build rage and unleash devastating damage |
| **Guided Missiles** | Mouse4/5 | 30s | Launch missile types 1 & 2 for targeted destruction |

### Deploy Actions

| Action | Control | Description |
|--------|---------|-------------|
| **Ammo Supplies** | Hold CTRL | Opens menu to drop ammo packs for squad |

### Passive Perks

- **300 HP** - Tank-level health pool
- **+50% Reload Speed** - Get back in the fight faster
- **Bonus Weapon Damage** - All weapons hit harder (pistols +25, rifles +10)
- **Immune to Tank Knockdowns** - Stand your ground against Tanks
- **Tank Knockdown** - Melee attacks can stagger Tanks
- **Stomp Downed Infected** - Finish incapped infected quickly

### Playstyle & Strategy

**Strengths:**
- Highest raw damage output
- Excellent in Tank fights
- Fast reload keeps pressure constant
- High health allows aggressive play

**Best For:**
- Players who see hordes as target practice
- Maximum DPS focus
- Tank takedown specialists

**Tips:**
- Berserk Mode scales with kills - use during hordes
- Use melee to stagger Tanks during critical moments
- Tank immunity lets you face-tank and deal damage
- Fast reloads mean you can use heavy ammo weapons effectively
- Drop ammo supplies before major engagements

---

## Engineer - Builder

**Role:** Area control, fortification, experimental warfare

**Description:** Builder who deploys turrets, ammo packs, and experimental grenades to lock down chokepoints. The Engineer turns any position into a fortress.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **Experimental Grenades** | Mouse3 | 15s | 20 wild options: Black Holes, Tesla coils, Airstrikes, Healing clouds |
| **Deploy Turret** | Mouse4 | 30s | Place auto-firing turrets with 20+ ammo types (bullets, explosives, lasers) |

### Deploy Actions

| Action | Control | Description |
|--------|---------|-------------|
| **Engineer Supplies** | Hold CTRL | Opens turret selection menu with advanced configurations |

### Passive Perks

- **Portable Turrets** - Can pick up and redeploy turrets
- **Multiple Turret Types** - Regular bullets, explosive rounds, lasers, and more
- **Standard Health** - 150 HP (but you have turrets)

### Playstyle & Strategy

**Strengths:**
- Best area control in the game
- Can fortify any position
- Experimental grenades provide utility for any situation
- Turrets provide constant DPS without ammunition drain

**Best For:**
- Players who love strategy and positioning
- Defensive playstyles
- Creative problem solving with experimental tools

**Tips:**
- Place turrets at chokepoints before hordes
- Experiment with different turret ammo types for situations
- Some experimental grenades heal, others create black holes
- Portable turrets can be relocated as needed
- Combine grenades and turrets for devastating combos

---

## Brawler - Heavy Tank (Experimental)

**Role:** Damage sponge, tank

**Description:** Heavy bruiser with a massive health pool built to soak damage for the squad. Still being tested and balanced.

### Primary Skills

| Skill | Control | Cooldown | Description |
|-------|---------|----------|-------------|
| **UnVomit (Cleanse Bile)** | Mouse3 | 120s | Cleanse boomer bile from yourself |

### Passive Perks

- **600 HP** - 4x default health (highest in game)
- **Damage Sponge** - Designed to absorb hits for team

### Playstyle & Strategy

**Strengths:**
- Can survive situations that would kill other classes
- Natural tank role with massive HP pool
- Draws infected attention away from teammates

**Best For:**
- Players who want to be unkillable
- Testing new tank mechanics
- Extreme survival scenarios

**Tips:**
- Still experimental - balance subject to change
- Use your HP pool to protect squishier classes
- Position yourself between threats and teammates
- Currently limited skills - more may be added

---

## Skill Actions Reference

### Primary (Mouse3 / Skill Action 1)
- **Soldier:** Satellite Strike
- **Athlete:** Anti-Gravity Grenades
- **Medic:** Healing Grenades
- **Saboteur:** Dead Ringer Cloak
- **Commando:** Berserk Mode
- **Engineer:** Experimental Grenades
- **Brawler:** -

### Secondary (Mouse4 / Skill Action 2)
- **Soldier:** Chain Lightning
- **Athlete:** Blink Teleport
- **Medic:** Healing Orb
- **Saboteur:** Extended Sight
- **Commando:** Guided Missile Type 1
- **Engineer:** Deploy Turret
- **Brawler:** -

### Tertiary (Mouse5 / Skill Action 3)
- **Soldier:** Zed Time
- **Athlete:** High Jump
- **Medic:** Cleanse Bile (UnVomit)
- **Saboteur:** Poison Melee (Lethal Weapon)
- **Commando:** Guided Missile Type 2
- **Engineer:** -
- **Brawler:** UnVomit

### Deploy (Hold CTRL)
- **Soldier:** - (none configured)
- **Athlete:** - (none configured)
- **Medic:** Medical Supplies Menu
- **Saboteur:** Deploy Mines Menu
- **Commando:** Ammo Supplies Menu
- **Engineer:** Engineer Supplies Menu (Turrets)
- **Brawler:** - (none configured)

---

## Class Selection Tips

### For Beginners
1. **Medic** - Forgiving with self-heal, helps team
2. **Commando** - High HP, straightforward damage focus
3. **Soldier** - Balanced stats, powerful abilities

### For Advanced Players
1. **Athlete** - High skill ceiling with mobility
2. **Saboteur** - Requires strategic thinking
3. **Engineer** - Positioning and planning crucial

### Team Composition Suggestions

**Balanced Team (4 players):**
- 1 Medic (healing/support)
- 1 Soldier or Commando (DPS/tank)
- 1 Athlete (mobility/scouting)
- 1 Engineer or Saboteur (utility/control)

**Aggressive Team:**
- 2 Commandos (DPS)
- 1 Soldier (tank/DPS)
- 1 Medic (sustain)

**Defensive Team:**
- 2 Engineers (turrets/area control)
- 1 Medic (healing)
- 1 Saboteur (mines/traps)

---

## Configuration Files

- **Class Skills:** `sourcemod/configs/rage_class_skills.cfg`
- **Talents/Cooldowns:** `cfg/sourcemod/talents.cfg`
- **Individual Skill Configs:** `cfg/sourcemod/rage_*.cfg`

---

## Additional Resources

- **[Testing Guide](../testing/)** - Test suite documentation and how to run tests
- **[Main README](../../README.md)** - Project overview and getting started

---

**Note:** This guide reflects the current state of L4D2 Rage Edition. Abilities, cooldowns, and class balance are subject to changes through configuration files without requiring plugin recompilation.
