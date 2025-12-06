# Complete Music Setup Guide

This guide provides step-by-step instructions for adding custom music to your L4D2 Rage Edition server.

## Quick Start

1. **Prepare your music files** (see Format Requirements below)
2. **Place files in the correct directory** (see Directory Structure)
3. **Add entries to the music list** (see Configuration Files)
4. **Configure fast download** (see Fast Download Setup)
5. **Test and enjoy!**

---

## Format Requirements

### Audio Format
- **Sample Rate:** 44.1 kHz (required by Source engine)
- **Formats Supported:** WAV, MP4 (MP3 container)
- **Recommended:** MP4 for better compression

### File Naming
- Use ASCII characters only (no special characters, accents, or emojis)
- Keep filenames short and descriptive
- Use lowercase with underscores: `my_awesome_track.mp4`

### Converting Audio Files

**Using FFmpeg (Recommended):**
```bash
# Convert any audio to 44.1 kHz MP4
ffmpeg -i input.mp3 -ar 44100 -ac 2 output.mp4

# Convert to WAV (larger file size)
ffmpeg -i input.mp3 -ar 44100 -ac 2 output.wav

# Batch convert all MP3s in a directory
for file in *.mp3; do
    ffmpeg -i "$file" -ar 44100 -ac 2 "${file%.mp3}.mp4"
done
```

**Using Online Tools:**
- [MP3 Quality Modifier](https://www.inspire-soft.net/software/mp3-quality-modifier) - Windows tool
- [Audacity](https://www.audacityteam.org/) - Free, cross-platform audio editor

---

## Directory Structure

### Option 1: Using Docker Compose (Recommended)
If using Docker Compose, place music files in:
```
custom/sound/music/
```

The Docker setup automatically mounts this to:
```
left4dead2/sound/custom/rage/
```

### Option 2: Manual Server Setup
Place music files directly in:
```
left4dead2/sound/custom/rage/
```

**Example:**
```
left4dead2/
└── sound/
    └── custom/
        └── rage/
            ├── at_dooms_gate.mp4
            ├── dark_halls.mp4
            ├── victory_music.mp4
            └── ...
```

---

## Configuration Files

### Main Music List
**File:** `sourcemod/data/music_mapstart.txt`

**Format:**
```
TS_SERVER/at_dooms_gate.mp3 TAG- at_dooms_gate.mp3
TS_SERVER/dark_halls.mp3 TAG- dark_halls.mp3
custom/rage/victory_music.mp4 TAG- Victory Music
```

**Path Rules:**
- Paths are relative to `sound/` directory
- Use forward slashes `/` (even on Windows)
- No leading `sound/` prefix
- Format: `path_to_file.ext TAG- Display Name`

**Examples:**
```
# Standard path (from sound/ directory)
custom/rage/my_track.mp4 TAG- My Awesome Track

# Subdirectory
custom/rage/ambient/background.mp4 TAG- Background Music

# Commented out (won't be loaded)
//custom/rage/disabled_track.mp4 TAG- Disabled Track
```

### New Player Music List (Optional)
**File:** `sourcemod/data/music_mapstart_newly.txt`

**Purpose:** Play different music for players joining for the first time

**Format:** Same as main list

**Enable:** Set `l4d_music_mapstart_use_firstconnect_list` to `1`

---

## Fast Download Setup

### Why Fast Download?
Without fast download, players must download music files from your game server, which can be slow and cause connection delays. Fast download uses a web server for faster transfers.

### Step 1: Set Up Web Server
You need a web server (Apache, Nginx, or any static file server) accessible via HTTP.

**Directory Structure on Web Server:**
```
http://your-server.com/left4dead2/
├── sound/
│   └── custom/
│       └── rage/
│           ├── at_dooms_gate.mp4
│           └── ...
└── models/
    └── ...
```

### Step 2: Configure Server CVars
Add to your `server.cfg` or `sourcemod/configs/server.cfg`:

```bash
# Enable downloads
sv_allowdownload 1

# Set your fast download URL (no trailing slash)
sv_downloadurl "http://your-server.com/left4dead2"

# Optional: Set download URL for specific content
sv_downloadurl_allow_dlfile 1
```

### Step 3: Test Download
1. Connect to server as a new player
2. Check console for download messages
3. Verify music plays correctly

---

## Adding Music Files - Step by Step

### Method 1: Manual Addition

1. **Prepare your audio file:**
   ```bash
   # Convert to 44.1 kHz MP4
   ffmpeg -i my_song.mp3 -ar 44100 -ac 2 my_song.mp4
   ```

2. **Place file in directory:**
   ```bash
   # Docker setup
   cp my_song.mp4 custom/sound/music/
   
   # Manual setup
   cp my_song.mp4 left4dead2/sound/custom/rage/
   ```

3. **Add to music list:**
   ```bash
   # Edit sourcemod/data/music_mapstart.txt
   echo "custom/rage/my_song.mp4 TAG- My Song" >> sourcemod/data/music_mapstart.txt
   ```

4. **Upload to fast download server:**
   ```bash
   # Copy to web server directory
   scp my_song.mp4 user@web-server:/var/www/left4dead2/sound/custom/rage/
   ```

5. **Reload music list:**
   - In-game: `sm_music_update` (admin command)
   - Or restart server

### Method 2: Using the Download Script

The repository includes a Python script to download soundtracks:

```bash
cd custom/sound/music
python download_soundtrack.py --out .
```

This downloads the DOOM/DOOM II soundtrack and Zorasoft's Project Doom album.

---

## Admin Menu Music Management

The admin menu now includes music management options (see Admin Menu section below).

**Features:**
- List all available music tracks
- Play specific tracks
- View current track information
- Reload music list

---

## Troubleshooting

### Music Not Playing

**Check:**
1. File exists in correct location
2. File is 44.1 kHz sample rate
3. Entry in `music_mapstart.txt` is correct
4. Fast download URL is configured
5. Player has music enabled in settings

**Debug Commands:**
```bash
# Check if music plugin is loaded
sm plugins list | grep music

# Test play specific track (admin only)
sm_music 0  # Play track index 0

# Reload music list
sm_music_update

# Check current track
sm_music_current
```

### Download Issues

**Symptoms:** Players can't download music, connection is slow

**Solutions:**
1. Verify `sv_downloadurl` is set correctly
2. Check web server is accessible
3. Verify file paths match exactly
4. Check web server allows `.mp4` and `.wav` file types
5. Test download URL in browser: `http://your-server.com/left4dead2/sound/custom/rage/your_track.mp4`

### File Format Issues

**Symptoms:** Music plays but sounds distorted or wrong speed

**Solutions:**
1. Verify sample rate is exactly 44.1 kHz
2. Re-convert file using FFmpeg
3. Check file isn't corrupted

---

## Best Practices

1. **File Size:** Keep individual tracks under 10MB for faster downloads
2. **Compression:** Use MP4 format for better compression than WAV
3. **Organization:** Group tracks by theme (e.g., `ambient/`, `action/`, `victory/`)
4. **Naming:** Use descriptive names that players will recognize
5. **Testing:** Always test tracks before adding to production server
6. **Backup:** Keep original audio files in case you need to re-convert

---

## Example: Adding a Custom Track

```bash
# 1. Convert your audio
ffmpeg -i my_custom_track.mp3 -ar 44100 -ac 2 my_custom_track.mp4

# 2. Copy to server directory
cp my_custom_track.mp4 custom/sound/music/

# 3. Add to music list
echo "custom/rage/my_custom_track.mp4 TAG- My Custom Track" >> sourcemod/data/music_mapstart.txt

# 4. Upload to fast download server
scp my_custom_track.mp4 user@web-server:/var/www/left4dead2/sound/custom/rage/

# 5. In-game, reload music list
sm_music_update

# 6. Test it
sm_music 0  # If it's the first track, or find its index
```

---

## Advanced Configuration

### Separate Lists for New Players
Edit `sourcemod/data/music_mapstart_newly.txt` and set:
```
l4d_music_mapstart_use_firstconnect_list 1
```

### Disable Auto-Play
Set in server config:
```
start_music_enabled 0
```

### Adjust Play Delay
Set delay before music starts (in seconds):
```
l4d_music_mapstart_delay 17
```

### Show Track Name in Chat
```
l4d_music_mapstart_display_in_chat 1
```

---

## Support

If you encounter issues:
1. Check server logs for errors
2. Verify file paths are correct
3. Test with a known-working track first
4. Check fast download server is accessible
5. Verify audio format requirements are met

