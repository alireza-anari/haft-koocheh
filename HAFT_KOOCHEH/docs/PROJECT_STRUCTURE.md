# Project structure — phase 0.1

Project root: HAFT_KOOCHEH/. Main scene: scenes/app/main.tscn.
Empty modules reserve the approved layout; no gameplay or unused scripts exist.
Git does not track empty directories. The delivery ZIP preserves all directories.

| Directory | Responsibility |
| --- | --- |
| scenes/app | Application entry |
| scenes/gameplay, scripts/gameplay | Gameplay composition |
| scenes/player, scripts/player | Player |
| scenes/obstacles, scripts/obstacles | Obstacles |
| scenes/enemies, scripts/enemies | Enemies |
| scenes/collectibles | Collectible scenes |
| scenes/levels, resources/levels | Level scenes and data |
| scenes/ui, scripts/ui | Interface |
| scripts/core | Shared application code |
| scripts/systems | Independent systems |
| assets/characters | Character art |
| assets/environments | Environment art |
| assets/obstacles | Obstacle art |
| assets/ui | Interface art |
| assets/fonts | Fonts |
| assets/audio/music, assets/audio/sfx | Audio |
| docs | Design, decisions, audit and QA |
| tests | Static validation, not a substitute for Godot |

Restore empty directories after clone (Python 3, from project root):

```sh
python3 - <<'PY'
from pathlib import Path
for directory in ['docs', 'scenes/app', 'scenes/gameplay', 'scenes/player', 'scenes/obstacles', 'scenes/enemies', 'scenes/collectibles', 'scenes/levels', 'scenes/ui', 'scripts/core', 'scripts/player', 'scripts/gameplay', 'scripts/obstacles', 'scripts/enemies', 'scripts/systems', 'scripts/ui', 'resources/levels', 'assets/characters', 'assets/environments', 'assets/obstacles', 'assets/ui', 'assets/fonts', 'assets/audio/music', 'assets/audio/sfx', 'tests']:
    Path(directory).mkdir(parents=True, exist_ok=True)
PY
```
