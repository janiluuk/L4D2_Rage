# Music files

Place custom round-start or background music files here. The Docker Compose setup mounts this directory into the game server at `left4dead2/sound/custom/rage`, which matches the paths used in `sourcemod/data/music_mapstart*.txt`.

Recommended soundtrack (Zorasoft – Project Doom: https://zorasoft.net/prjdoom.html) is available via the downloader; run `python download_soundtrack.py --out .` to pull the set as MP4s alongside any other album you specify.

Guidelines for adding more tracks:

* Use 44.1 kHz audio to match Source engine expectations.
* Reference tracks in the data files without the leading `sound/` prefix, e.g. `custom/rage/my_track.wav`.
* Keep filenames ASCII-only to avoid download issues.

To pull in the DOOM/DOOM II gamerip straight from downloads.khinsider.com as MP4 audio, run:

```
python download_soundtrack.py --out .
```
