# Agent Guidelines for L4D2_Rage

This repository contains SourceMod plugins for the L4D2 Rage project. Use these rules while editing any file in this repo:

## Coding
- Use SourcePawn newdecls syntax (`#pragma newdecls required`) and keep function signatures explicit.
- Keep non-menu behavior in focused include files (e.g., HUD, keybinds, third-person, kit logic). Favor reusing the existing helper includes under `sourcemod/scripting/include/` instead of placing those responsibilities back into menu plugins.
- Prefer descriptive names for menu actions and helper functions. Align enum/constant ordering with menu rows to keep option handling direct.
- Follow existing brace/indent style in the touched file. Avoid try/catch constructs around imports or includes.

## File organization
- Place shared helpers in `sourcemod/scripting/include/` and keep plugin entry points in `sourcemod/scripting/*.sp`. When adding a new helper, add it to the include directory and keep menu plugins slim by invoking those helpers.
- If you add new assets (music, configs), store them under the matching top-level folder already used in the project.

## Testing
- For SourcePawn changes, compile with `./spcomp64 <plugin>.sp` from `sourcemod/scripting/` when SourceMod includes are available. Note any missing dependencies in the testing section if compilation cannot be run in the current environment.

## Documentation
- Update related README or plugin headers only when behavior changes warrant it. Keep change notes concise.

## PR / Summary notes
- Summaries should focus on player-facing behavior (menu changes, gameplay helpers) and mention key internal refactors if they impact usage.

