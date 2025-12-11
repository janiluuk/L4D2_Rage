# Assets and Models Reference

This document lists all assets (models, sounds, particles, materials) referenced in the L4D2 Rage Edition codebase and provides optimization recommendations.

## Models

### Survivor Models (Standard L4D2)
These are standard game models and should always be available:
- `models/survivors/survivor_coach.mdl`
- `models/survivors/survivor_producer.mdl`
- `models/survivors/survivor_mechanic.mdl`
- `models/survivors/survivor_gambler.mdl`
- `models/survivors/survivor_namvet.mdl`
- `models/survivors/survivor_teenangst.mdl`
- `models/survivors/survivor_biker.mdl`
- `models/survivors/survivor_manager.mdl`

**Status:** ✅ Standard game assets - no action needed

### Weapon Models
Referenced in `rage_survivor_multiple_equipment.sp`:
- `models/w_models/weapons/w_rifle_m16a2.mdl`
- `models/w_models/weapons/w_rifle_sg552.mdl`
- `models/w_models/weapons/w_desert_rifle.mdl`
- `models/w_models/weapons/w_rifle_ak47.mdl`
- `models/w_models/weapons/w_smg_uzi.mdl`
- And many more weapon models...

**Status:** ✅ Standard game assets - no action needed

### Custom Models
These may need to be provided:
- Various grenade models (referenced in grenades plugin)
- Turret models (referenced in multiturret plugin)
- Custom survivor models in `custom/models/survivors/`

**Status:** ⚠️ Check if custom models exist in `custom/models/` directory

## Materials/Sprites

### Laser Beams
- `materials/sprites/laserbeam.vmt` (L4D2)
- `materials/sprites/laser.vmt` (L4D1)

**Status:** ✅ Standard game assets

### Particle Effects
- Various particle systems referenced via `PrecacheParticleIndex()`
- Most are standard Source engine particles

**Status:** ✅ Standard game assets

## Sounds

### Music Files
- Location: `custom/sound/music/` or `sound/custom/rage/`
- Format: 44.1 kHz WAV or MP4
- Listed in: `sourcemod/data/music_mapstart.txt` and `music_mapstart_newly.txt`

**Status:** ⚠️ Requires server admin to add music files

### Sound Effects
- Healing orb sounds (referenced in `rage_survivor_plugin_healingorb.sp`)
- Model swap sound: `ui/pickup_secret01.wav` (GuessWho gamemode)
- Various weapon sounds (standard game)

**Status:** ✅ Most are standard game assets

## Optimization Recommendations

### 1. Model Precache Optimization
**Current State:** Models are precached in `OnMapStart()` which is correct.

**Recommendation:**
- ✅ Keep precaching in `OnMapStart()` (already optimal)
- Consider lazy-loading for rarely used models if memory is a concern
- Verify all custom models exist before precaching

### 2. Sound Optimization
**Current State:** Music files are added to download table and precached.

**Recommendation:**
- ✅ Only one music track is downloaded per map start (already optimized)
- Consider compressing music files to reduce download size
- Use MP4 format for better compression than WAV
- Ensure `sv_downloadurl` is configured for fast downloads

### 3. Particle Optimization
**Current State:** Particles are precached on map start.

**Recommendation:**
- ✅ Current approach is optimal
- Consider removing unused particle precaches if any exist
- Verify particle paths are correct (some may be L4D2-specific)

### 4. Missing Assets Checklist

**To verify:**
1. Check if `custom/models/survivors/` contains any custom survivor models
2. Verify all music files listed in `music_mapstart.txt` exist
3. Check if any custom weapon models are referenced
4. Verify particle effect paths are correct for L4D2

**Commands to check:**
```bash
# Check for missing music files
cd sourcemod/data
while IFS= read -r line; do
    if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
        # Extract path from line (format: "path TAG- name")
        path=$(echo "$line" | awk '{print $1}')
        if [[ ! -f "../../left4dead2/sound/$path" ]]; then
            echo "MISSING: $path"
        fi
    fi
done < music_mapstart.txt

# Check for custom models
find custom/models -name "*.mdl" -type f
```

## Asset Organization

### Recommended Directory Structure
```
left4dead2/
├── sound/
│   └── custom/
│       └── rage/          # Music files go here
│           └── *.mp3 or *.wav
├── models/
│   └── custom/            # Custom models (if any)
│       └── survivors/
└── materials/
    └── custom/            # Custom materials (if any)
```

### Fast Download Setup
Ensure your server has:
1. `sv_allowdownload 1` in server.cfg
2. `sv_downloadurl "http://your-content-server.com/left4dead2/"` configured
3. Content server serving files from the `left4dead2/` directory structure

## Known Issues

### Potential Missing Assets
1. **Custom Survivor Models:** If any custom survivor models are referenced, they must exist in `custom/models/survivors/`
2. **Music Files:** All music files listed in data files must exist and be accessible
3. **Particle Effects:** Some particle effects may be L4D2-specific and won't work in L4D1

### Optimization Opportunities
1. **Music Compression:** Convert WAV files to MP4 for smaller file sizes
2. **Lazy Loading:** Consider lazy-loading rarely used models
3. **Asset Validation:** Add runtime checks for missing assets with fallbacks

## Testing Checklist

- [ ] All music files in `music_mapstart.txt` exist and are accessible
- [ ] All music files in `music_mapstart_newly.txt` exist (if used)
- [ ] Custom models (if any) are present in correct directories
- [ ] Fast download server is configured and working
- [ ] No console errors about missing models/sounds on map start
- [ ] Music plays correctly for all players
- [ ] Particle effects display correctly

