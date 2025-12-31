# Menu Navigation Improvements for Skills, Deployments, and Game Menu

## ✅ Implementation Status: COMPLETE

**Menu navigation improvements have been implemented!**

The menu system now uses number key navigation (1-4 keys) which:
- ✅ Does NOT block player movement (MOVETYPE_WALK maintained)
- ✅ Uses 1/2/3/4 keys instead of WASD
- ✅ Faster and more intuitive navigation
- ✅ Movement keys (WASD) work normally while menu is open

**Current Navigation:**
- **Keys 1-4**: Navigate menu (Left/Right/Up/Down)
- **Keys 7-9**: Previous page/Next page/Exit menu
- **Movement keys (WASD)**: Work normally while menu is open

## Current State

The menu system currently:
- Uses WASD navigation (W/S for up/down, A/D for left/right selection) - **blocks movement**
- Freezes player when menu opens (`MOVETYPE_NONE`) when `MenuNums = false`
- Supports `MenuNums` mode (1-4 keys for navigation) but it's currently disabled (`buttons_nums = false`)
- Skills can be accessed via keybinds (Mouse3/4/5 or combos) OR via menu
- Has a separate `QuickActionMenu` for skills (separate from main menu)
- Menu properly closes now (key binding bug fixed)

## Current Issues

1. **WASD conflicts with movement**: The menu uses W/S/A/D for navigation, which blocks player movement while the menu is open
2. **Skills access inconsistency**: Skills can be accessed via keybinds OR via menu, creating confusion
3. **Menu blocking gameplay**: Opening the menu freezes player movement (MOVETYPE_NONE when MenuNums=false), interrupting combat flow
4. **Multiple access points**: Skills/deployments exist in both the main menu and a separate QuickActionMenu
5. **Complex keybind combinations**: Some actions require multi-key combinations (e.g., "Crouch + Use + Fire")
6. **MenuNums mode unused**: The number key navigation exists but is disabled (`buttons_nums = false` in BuildSingleMenu)

## Proposed Navigation Schemes

### Option 1: Enable MenuNums Mode (Easiest - Recommended First Step)
**Best for: Quick improvement with minimal code changes**

```
Implementation:
- Change `buttons_nums = false` to `buttons_nums = true` in BuildSingleMenu()
- MenuNums mode already exists and uses 1/2/3/4 keys for navigation
- Movement is NOT blocked when MenuNums = true (MOVETYPE_WALK maintained)
- Navigation: 1=Left, 2=Right, 3=Up, 4=Down, 7=Previous, 8=Next, 9=Exit

Current MenuNums Behavior:
- Uses number keys 1-4 for directional navigation
- Does NOT freeze player movement
- Already implemented, just needs to be enabled

Improvements Needed:
- Add direct selection (press number to select item, not just navigate)
- Update menu display text to show number key hints
- Show numbered options in menu display

Benefits:
- No movement blocking (already implemented)
- Fast number key access
- Minimal code changes required
- Already tested and working
```

### Option 2: Radial/Quick Select Menu
**Best for: Fast skill activation without opening full menu**

```
Implementation:
- Hold SHIFT: Opens quick radial menu (4-6 options in a circle)
- Direction keys (WASD) point to different actions
- Release SHIFT on a direction = activates that skill
- No menu display, just visual indicator (crosshair indicator or HUD element)

Quick Radial Layout (4 directions):
- UP (W): Primary Skill (Skill Action 1)
- RIGHT (D): Secondary Skill (Skill Action 2)  
- DOWN (S): Tertiary Skill (Skill Action 3)
- LEFT (A): Deploy Action

Extended Radial (8 directions):
- Add diagonal directions for additional quick actions
- UP-RIGHT: Get Kit
- DOWN-RIGHT: Third Person Toggle
- DOWN-LEFT: View Stats
- UP-LEFT: Open Full Menu

Benefits:
- Extremely fast skill activation
- No screen blocking
- Intuitive directional mapping
- Maintains full movement control
```

### Option 3: Hybrid System (Recommended for Best UX)
**Best for: Balancing speed and functionality**

```
Quick Access (Hold SHIFT):
- While holding SHIFT, press number keys 1-4 for instant skill activation:
  1 = Primary Skill
  2 = Secondary Skill  
  3 = Tertiary Skill
  4 = Deploy Action
- No menu display, just executes action immediately
- Visual feedback: Brief HUD text showing which skill activated

Full Menu (Tap SHIFT or bind separate key):
- Opens full menu with all options
- Uses number keys 1-9 for selection (no WASD needed)
- ENTER confirms, ESC closes
- Does NOT freeze movement (keep MOVETYPE_WALK)

Smart Menu System:
- Skills section shows current class abilities with cooldown timers
- Deploy section shows available deployments with ammo/count indicators
- Context-aware: Shows only relevant options for current class

Benefits:
- Best of both worlds: fast execution + full menu access
- No movement interruption
- Clear visual feedback
- Reduces cognitive load (no remembering key combinations)
```

### Option 4: Mouse Wheel Navigation
**Best for: Players who prefer mouse-based navigation**

```
Navigation:
- Mouse wheel scroll: Navigate up/down menu options
- Mouse1: Select/Activate highlighted option
- Mouse2: Go back/Close menu
- Number keys: Quick select (bypass scrolling)
- Arrow keys: Navigate (doesn't block WASD since arrow keys are separate)

Benefits:
- Intuitive scrolling
- Doesn't conflict with movement keys
- Fast number key shortcuts still available
- Familiar pattern for most players
```

## Recommended Implementation: Progressive Enhancement

### Phase 0: Quick Win - Enable MenuNums Mode
**Effort: Very Low | Impact: High**

Simply enable the existing MenuNums mode:
```sourcepawn
// In rage_survivor_menu.sp, line 1101
bool buttons_nums = true;  // Change from false to true
```

This immediately:
- ✅ Removes movement blocking
- ✅ Allows number key navigation
- ✅ Maintains all existing functionality
- ⚠️ Still requires navigation (1-4 for direction) rather than direct selection

### Phase 1: Enhanced MenuNums with Direct Selection
**Effort: Low | Impact: High**

Modify menu to support direct item selection:
- Show item numbers (1, 2, 3, 4) next to each menu option
- Press number key directly selects that item (no navigation needed)
- Combine with Phase 0 for best experience

### Phase 2: Hybrid System (Option 3)

### Phase 1: Quick Skill Access
```sourcepawn
// In rage_menu_base.sp, modify MenuNums mode
// When MenuNums = true, use number keys for selection
// Add visual feedback for quick actions

// Quick access: Hold SHIFT + press 1-4
- Shows brief overlay: "Skill 1 Activated" / "Deploy Activated"
- Executes immediately without opening full menu
- Cooldown timer shown in HUD
```

### Phase 2: Improved Full Menu
```sourcepawn
// Update DisplayExtraMenu to use number keys
// Change menu type to use number buttons (MenuNums = true)
// Remove MOVETYPE_NONE blocking

// Menu structure:
Page 1 - Quick Actions:
1. Deploy Ability
2. Skills Menu (submenu)
3. Change Class
4. Guide

Page 2 - Team & Voting:
1. Team Selection
2. Set Away
3. Vote Options
4. Initiate Vote

Page 3 - Skills Detail (if selected from main menu):
1. Primary Skill: [Current Name] [Cooldown: Xs]
2. Secondary Skill: [Current Name] [Cooldown: Xs]
3. Tertiary Skill: [Current Name] [Cooldown: Xs]
4. Deploy: [Current Name] [Ammo: X]
5. Back to Main Menu
```

### Phase 3: Enhanced UX Features

1. **Context-Aware Menu**: Show only skills available to current class
2. **Cooldown Indicators**: Display remaining cooldown time next to skills
3. **Ammo/Count Display**: Show deployment limits (turrets, grenades, etc.)
4. **Quick Preview**: Hover over skill shows brief description
5. **Sound Feedback**: Different sounds for skill activation vs. menu navigation

## Migration Path

### Immediate Improvements (Low Effort, High Impact)
1. ✅ **Fix key binding issue** (already done - menu properly closes)
2. ⚡ **Enable MenuNums mode** (change `buttons_nums = false` to `true` in BuildSingleMenu) - **Takes 1 line change**
3. ✅ **Movement already not blocked** when MenuNums = true (already implemented)
4. 🔄 **Add quick skill access** (SHIFT + 1-4 without opening menu) - requires new handler
5. 🔄 **Update menu text** to show number key hints when MenuNums is enabled

### Short-term Improvements (Medium Effort)
1. Add cooldown timers to menu
2. Add skill name display per class
3. Consolidate QuickActionMenu into main menu
4. Add visual feedback for quick actions

### Long-term Improvements (Higher Effort)
1. Implement radial menu option (toggleable)
2. Add customizable keybind presets
3. Add menu themes/customization
4. Implement touch-friendly menu for mobile/tablet controllers

## Code Changes Needed

### rage_menu_base.sp
- Already supports MenuNums mode (number key navigation)
- Need to ensure MenuNums mode doesn't block movement
- Add quick action handler for SHIFT + number keys

### rage_survivor_menu.sp
- Update BuildSingleMenu to use MenuNums = true
- Add quick skill access handler (bypass menu)
- Integrate QuickActionMenu into main menu structure
- Remove MOVETYPE_NONE when using MenuNums

### rage_survivor.sp
- Expose skill names/descriptions to menu system
- Add cooldown query functions for menu display
- Add deployment count/ammo query functions

## User Testing Recommendations

1. Test with players who have no mouse buttons beyond Mouse1/Mouse2
2. Test with players using non-QWERTY keyboards
3. Test during combat situations (stress test)
4. Gather feedback on preferred navigation method
5. A/B test: MenuNums vs traditional WASD navigation

## Accessibility Considerations

- Support alternative input methods (arrow keys, joystick)
- Ensure menu is readable in various lighting conditions
- Provide audio cues for menu navigation
- Allow remapping of all navigation keys
- Support screen reader compatibility (if applicable)

## Performance Considerations

- Quick actions should execute in <50ms
- Menu rendering should not cause FPS drops
- Minimize server-side processing for menu interactions
- Cache menu structures to avoid rebuilds

