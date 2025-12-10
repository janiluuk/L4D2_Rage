# Classes & Skills

## Overview

L4D2 Rage Edition features 7 unique classes, each with distinct abilities and playstyles. Each class has:
- **Special Skill**: Primary ability (mouse3)
- **Secondary Skill**: Secondary ability (mouse4)
- **Tertiary Skill**: Tertiary ability (mouse5)
- **Deploy Action**: Hold CTRL to deploy items/supplies

## Classes

### 🪖 Soldier
**Role**: Frontline fighter with heavy firepower

**Skills**:
- **Special**: Satellite Strike - Call down an orbital strike from above (outdoor areas only)
- **Secondary**: Chain Lightning - Aim at an enemy and unleash lightning that chains between up to 5 targets, dealing devastating area damage with falloff
- **Tertiary**: Zed Time - Activate slow motion (30% speed) that affects all players for 5 seconds - perfect for clutch moments and tactical advantages
- **Deploy**: Engineer Supply Menu (ammo packs)

**Playstyle**: Aggressive frontline combat with area damage, crowd control, and missile support. Chain Lightning excels at clearing groups, while Zed Time gives you and your team a massive edge in dangerous situations.

---

### 🏃 Athlete
**Role**: Movement expert with enhanced mobility

**Skills**:
- **Special**: Anti-Gravity Grenade - Launch enemies into the air
- **Secondary**: Parachute - Hold Use mid-air to glide down safely from any height
- **Tertiary**: High Jump - Enhanced jump ability for reaching elevated positions
- **Deploy**: Blink - Short-range teleport that lets you instantly reposition or escape danger. Perfect for quick escapes and tactical repositioning.

**Passive Abilities**:
- **Wall Run & Climb** - Automatically stick to walls when jumping near them. Run along walls with W/S, climb upward with JUMP. Reach places other classes can't access!

**Playstyle**: High mobility, vertical movement, and escape capabilities. Wall running and blinking make you nearly impossible to pin down.

---

### 🏥 Medic
**Role**: Team support and healing specialist

**Skills**:
- **Special**: Medic Grenade - Healing area effect
- **Secondary**: Healing Orb - Projectile that heals on contact
- **Tertiary**: UnVomit - Remove vomit effect from survivors
- **Deploy**: Medic Supply Menu (health packs, pain pills)

**Playstyle**: Support teammates, prioritize healing, and keep the team alive.

---

### 🥷 Saboteur
**Role**: Stealth scout with reconnaissance abilities

**Skills**:
- **Special**: Cloak - Temporary invisibility with Dead Ringer (drops fake corpse)
- **Secondary**: Extended Sight - See special infected through walls for 20 seconds (2 minute cooldown). Perfect for scouting and calling out threats
- **Tertiary**: Lethal Weapon - Charged sniper shot with explosion
- **Deploy**: Saboteur Mines Menu (motion-sensitive mines)

**Passive Abilities**:
- **Poison Melee** - Your melee attacks automatically apply toxic damage over time. Enemies glow green and take continuous damage every second. Perfect for hit-and-run tactics - strike, cloak away, and let the poison finish them off.

**Playstyle**: Stealth, reconnaissance, and precision strikes from range. Poison melee makes your hit-and-run tactics incredibly effective against special infected.

---

### 💪 Commando
**Role**: Damage specialist with crowd control

**Skills**:
- **Special**: Berzerk Mode - Enhanced damage and speed
- **Secondary**: Dummy Missile - Decoy missile
- **Tertiary**: Homing Missile - Tracking missile
- **Deploy**: Engineer Supply Menu (ammo packs)

**Playstyle**: High damage output, especially effective against Tanks.

---

### 🔧 Engineer
**Role**: Builder and defensive specialist

**Skills**:
- **Special**: Shield Grenade - Deployable shield
- **Secondary**: Multiturret - Deploy multiple turrets
- **Tertiary**: Airstrike - Call in air support
- **Deploy**: Turret Selection Menu

**Playstyle**: Defensive positioning, area control, and support structures.

---

### 🛡️ Brawler
**Role**: Tank with high survivability

**Skills**:
- **Special**: (Currently none - see [Plugin Integration](../development/plugin-integration.md))
- **Secondary**: (Currently none)
- **Tertiary**: (Currently none)
- **Deploy**: Medic Supply Menu (health packs)

**Playstyle**: High health pool, damage soaking, frontline tanking.

**Note**: Brawler class is currently incomplete. See [Plugin Integration Suggestions](../development/plugin-integration.md) for recommended skills.

---

## Skill Usage

### Activation
- Skills are activated by pressing the bound mouse buttons (mouse3/4/5)
- Most skills have cooldowns
- You'll hear a sound and see a notification when a skill is ready
- **Quick Action Menu**: Hold **SHOVE + USE** for 1 second to open a menu showing all your skills and deployment options. Select with number keys (1-4) to use them instantly

### Cooldowns
- Each skill has a configurable cooldown period
- Cooldown notifications appear in HUD and hint text
- Sound notification plays when cooldown expires

### Deployment Actions
- Hold **CTRL** to open your class's deployment menu
- Release **CTRL** to close the menu
- Must be on solid ground (not in air or saferoom)
- Some deployments have usage limits per round
- **Quick Action Menu**: Also accessible via SHOVE + USE - shows deployment as option 1

## Strategy Tips

- **Soldier**: 
  - Use Chain Lightning on grouped enemies for devastating area damage
  - Activate Zed Time during horde events or when the team is in danger
  - Save Satellite Strike for Tanks or large groups in outdoor areas
- **Athlete**: 
  - Use Wall Run to reach elevated positions and escape tight spots
  - Blink through hordes or away from special infected
  - Use Parachute before jumping from high places
- **Medic**: Save Healing Orb for critical moments
- **Saboteur**: 
  - Use Poison Melee on special infected, then cloak away - let the poison finish them
  - Extended Sight reveals threats before they ambush - call them out for your team
  - Use Cloak to escape or reposition when overwhelmed
- **Commando**: Activate Berzerk before engaging Tanks
- **Engineer**: Set up turrets at chokepoints
- **Brawler**: Focus on drawing enemy attention and protecting teammates

## Related Documentation

- [Deploy Action Guide](../features/DEPLOY_ACTION_GUIDE.md)
- [Plugin Integration](../development/plugin-integration.md) - For adding new skills

