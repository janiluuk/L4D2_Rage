# Getting Started

## For Players

### Quick Start
1. Join a server running L4D2 Rage Edition
2. Hold **SHIFT** (or **V**) to open the class selection menu
3. Choose your class
4. Abilities auto-bind to **mouse3**, **mouse4**, and **mouse5**
5. Press **X** (voice menu) for quick menu access
6. Type `!guide` for in-game help

### Basic Controls
- **SHIFT** or **V**: Open/close main menu
- **CTRL**: Hold to open deployment menu (release to close)
- **Mouse3/4/5**: Use class abilities
- **X**: Quick menu access

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

