# Lethal Weapon Skill - Required Assets

This document lists all assets required for the Lethal Weapon skill plugin.

## Sound Files

All sound files should be placed in `custom/sound/` directory on your server.

### Required Sounds

1. **`ambient/spacial_loops/lights_flicker.wav`**
   - **Purpose**: Plays while charging the weapon
   - **Location**: `custom/sound/ambient/spacial_loops/lights_flicker.wav`
   - **Source**: This is a default L4D2 sound file, should already exist
   - **Note**: If missing, the charging sound will be silent

2. **`level/startwam.wav`**
   - **Purpose**: Plays when weapon is fully charged AND used for global cooldown notifications
   - **Location**: `custom/sound/level/startwam.wav`
   - **Source**: This is a default L4D2 sound file, should already exist
   - **Note**: This is the critical "ready" sound used by the cooldown notification system

3. **`weapons/awp/gunfire/awp1.wav`**
   - **Purpose**: Plays when the charged shot is fired
   - **Location**: `custom/sound/weapons/awp/gunfire/awp1.wav`
   - **Source**: This is a default L4D2 sound file, should already exist
   - **Note**: If missing, the shot sound will be silent

4. **`animation/bombing_run_01.wav`**
   - **Purpose**: Plays when the explosion occurs
   - **Location**: `custom/sound/animation/bombing_run_01.wav`
   - **Source**: This is a default L4D2 sound file, should already exist
   - **Note**: If missing, the explosion sound will be silent

### Sound File Verification

To verify these sounds exist, check:
```
left4dead2/custom/sound/ambient/spacial_loops/lights_flicker.wav
left4dead2/custom/sound/level/startwam.wav
left4dead2/custom/sound/weapons/awp/gunfire/awp1.wav
left4dead2/custom/sound/animation/bombing_run_01.wav
```

**Note**: These are all default L4D2 sounds and should already be present in your game installation. If they are missing, you may need to verify your game files through Steam.

## Particle Effects

The following particle effects are used (these are built into L4D2, no files needed):

1. **`gas_explosion_main`** - Main explosion effect
2. **`electrical_arc_01_cp0`** - Charging particle effect
3. **`electrical_arc_01_system`** - Fully charged particle effect

These are precached automatically by the plugin and require no additional files.

## Model Files

The following model files are used (these are built into L4D2, no files needed):

1. **`models/props_junk/propanecanister001a.mdl`** - Explosion prop
2. **`models/props_junk/gascan001a.mdl`** - Fire prop

These are precached automatically by the plugin and require no additional files.

## Sprite Files

1. **`materials/sprites/laserbeam.vmt`**
   - **Purpose**: Laser beam effect when firing
   - **Location**: Built into L4D2
   - **Note**: No additional files needed

## Asset Summary

✅ **All required assets are built into Left 4 Dead 2**
- No custom sound files need to be downloaded
- No custom models need to be added
- No custom particles need to be created
- No custom sprites need to be added

The plugin will work out of the box with a standard L4D2 installation. All assets are precached automatically when the map loads.

## Troubleshooting

If sounds are not playing:

1. **Check server console** for precache errors
2. **Verify game files** through Steam (Right-click L4D2 → Properties → Local Files → Verify integrity)
3. **Check file permissions** - ensure server can read sound files
4. **Check download URLs** - if using `sv_downloadurl`, ensure sounds are available

If particles are not showing:

1. **Check server console** for particle precache errors
2. **Verify particle system** is working (other plugins using particles should work)
3. **Check ConVar** `l4d2_lw_chargeparticle` is set to 1

## Configuration

All asset-related settings can be controlled via ConVars:

- `l4d2_lw_chargingsound` - Enable/disable charging sound (default: 1)
- `l4d2_lw_chargedsound` - Enable/disable charged ready sound (default: 1)
- `l4d2_lw_chargeparticle` - Enable/disable particle effects (default: 1)
- `l4d2_lw_flash` - Enable/disable screen flash (default: 1)
- `l4d2_lw_shake` - Enable/disable screen shake (default: 1)

See `cfg/sourcemod/l4d2_lethal_weapon.cfg` for all configuration options.

