# Music files

Place custom round-start or background music files here. The Docker Compose setup mounts this directory into the game server at `left4dead2/sound/custom/rage`, which matches the paths used in `sourcemod/data/music_mapstart*.txt`.

* Use 44.1 kHz audio to match Source engine expectations.
* Reference tracks in the data files without the leading `sound/` prefix, e.g. `custom/rage/my_track.mp3`.
* Keep filenames ASCII-only to avoid download issues.
