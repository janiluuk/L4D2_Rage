# Getting Started

## For Players

### Quick Start
1. Join a server running L4D2 Rage Edition
2. Hold **SHIFT** to open the class selection menu (or it will auto-open if you don't have a class)
3. Choose your class - your previous choice is remembered and auto-selected
4. Abilities auto-bind to **mouse3**, **mouse4**, and **mouse5**
5. Hold **SHOVE + USE** for 1 second to open quick action menu
6. Type `!guide` for in-game help

### Basic Controls
- **SHIFT**: Hold to open/close main menu (release to close)
  - **Menu Navigation**: Use **1/2/3/4** keys to navigate menu options
  - **7**: Previous page, **8**: Next page, **9**: Exit menu
  - **Movement is NOT blocked** - you can move while menu is open!
- **CTRL**: Hold to open deployment menu (release to close)
- **SHOVE + USE** (hold for 1 second): Open quick action menu to deploy or use any skill
- **Mouse3/4/5**: Use class abilities directly

## For Server Administrators

### Installation
1. Copy the `sourcemod/` folder to your server directory
2. Ensure SourceMod 1.12+ is installed
3. Ensure the **httpclient** extension is available
4. Restart the server

### Docker Deployment
The easiest way to run a server:

```bash
docker-compose up
```

This automatically sets up everything with no configuration needed.

### Configuration
- **Class Skills**: Edit `sourcemod/configs/rage_class_skills.cfg`
- **Cooldowns**: Edit `cfg/sourcemod/talents.cfg`
- **Music**: See [Music Setup Guide](../features/MUSIC_SETUP_GUIDE.md)

### Requirements
- SourceMod 1.12 or higher
- Left 4 Dead 2 dedicated server
- httpclient extension (included with SM 1.12+)

## Next Steps

- Learn about [Classes & Skills](../classes-skills/)
- Explore [Features](../features/)
- Check [Assets](../assets/) for custom content

