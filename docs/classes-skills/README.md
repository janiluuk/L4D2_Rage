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
- **Special**: Satellite Strike - Call down an orbital strike
- **Secondary**: Dummy Missile - Decoy missile
- **Tertiary**: Homing Missile - Tracking missile
- **Deploy**: Engineer Supply Menu (ammo packs)

**Playstyle**: Aggressive frontline combat with area damage and missile support.

---

### 🏃 Athlete
**Role**: Movement expert with enhanced mobility

**Skills**:
- **Special**: Anti-Gravity Grenade - Launch enemies into the air
- **Secondary**: Parachute - Safe descent from heights
- **Tertiary**: High Jump - Enhanced jump ability
- **Deploy**: Medic Supply Menu (health packs)

**Playstyle**: High mobility, vertical movement, and escape capabilities.

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
- **Special**: Cloak - Temporary invisibility
- **Secondary**: Extended Sight - See special infected through walls
- **Tertiary**: Lethal Weapon - Charged sniper shot with explosion
- **Deploy**: Saboteur Mines Menu (motion-sensitive mines)

**Playstyle**: Stealth, reconnaissance, and precision strikes from range.

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
- Skills are activated by pressing the bound mouse buttons
- Most skills have cooldowns
- You'll hear a sound and see a notification when a skill is ready

### Cooldowns
- Each skill has a configurable cooldown period
- Cooldown notifications appear in HUD and hint text
- Sound notification plays when cooldown expires

### Deployment Actions
- Hold **CTRL** to open your class's deployment menu
- Release **CTRL** to close the menu
- Must be on solid ground (not in air or saferoom)
- Some deployments have usage limits per round

## Strategy Tips

- **Soldier**: Use Satellite Strike on grouped enemies or Tanks
- **Athlete**: Use Parachute before jumping from high places
- **Medic**: Save Healing Orb for critical moments
- **Saboteur**: Use Cloak to escape or reposition
- **Commando**: Activate Berzerk before engaging Tanks
- **Engineer**: Set up turrets at chokepoints
- **Brawler**: Focus on drawing enemy attention and protecting teammates

## Related Documentation

- [Deploy Action Guide](../features/DEPLOY_ACTION_GUIDE.md)
- [Plugin Integration](../development/plugin-integration.md) - For adding new skills

