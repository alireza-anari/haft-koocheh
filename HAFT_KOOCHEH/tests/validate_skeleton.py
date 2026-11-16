"""Static acceptance checks only; does not parse resources using Godot."""
from pathlib import Path
import configparser
import re

root = Path(__file__).resolve().parents[1]
config = configparser.ConfigParser(interpolation=None, delimiters=("=",), comment_prefixes=(";", "#"))
expected = {
    "application": {"config/name": '"HAFT KOOCHEH"', "run/main_scene": '"res://scenes/app/main.tscn"'},
    "display": {"window/size/viewport_width": "1280", "window/size/viewport_height": "720", "window/stretch/mode": '"canvas_items"', "window/stretch/aspect": '"keep"', "window/handheld/orientation": "0"},
    "physics": {"common/physics_ticks_per_second": "60"},
    "rendering": {"renderer/rendering_method": '"gl_compatibility"', "renderer/rendering_method.mobile": '"gl_compatibility"'},
}
# Godot permits the top-level config_version before the first section.
text = (root / "project.godot").read_text()
config.read_string("[format]\n" + text)
assert config["format"]["config_version"] == "5"
for section, values in expected.items():
    for key, value in values.items():
        assert config[section][key] == value, (section, key)
scene = root / config["application"]["run/main_scene"].strip('"').removeprefix("res://")
assert scene.is_file()
scene_text = scene.read_text()
assert '[gd_scene format=3]' in scene_text
assert re.findall(r'type="([^"]+)"', scene_text) == ["Node2D", "CanvasLayer", "Label"]
assert 'text = "HAFT KOOCHEH"' in scene_text
allowed_scripts = {"scripts/player/player_controller.gd", "scripts/gameplay/prototype_run.gd", "tests/test_auto_run.gd", "tests/test_jump.gd", "scripts/gameplay/level_controller.gd", "scripts/obstacles/hazard.gd", "tests/test_failure_restart.gd", "scripts/gameplay/coin.gd", "scripts/gameplay/coin_score_prototype.gd", "scripts/systems/score_manager.gd", "tests/test_coin_score.gd"}
assert {p.relative_to(root).as_posix() for p in root.rglob("*.gd")} == allowed_scripts, "Unexpected gameplay script"
assert {p.relative_to(root).as_posix() for p in root.rglob("*.tscn")} == {"scenes/app/main.tscn", "scenes/player/player.tscn", "scenes/gameplay/prototype_run.tscn", "scenes/gameplay/failure_prototype.tscn", "scenes/gameplay/failure_world.tscn", "scenes/obstacles/hazard.tscn", "scenes/collectibles/coin.tscn", "scenes/gameplay/coin_score_prototype.tscn", "scenes/gameplay/coin_score_world.tscn"}
assert "[autoload]" not in text
player_text = (root / "scenes/player/player.tscn").read_text()
assert 'type="CharacterBody2D"' in player_text and 'type="RectangleShape2D"' in player_text
assert 'type="Polygon2D"' in player_text
assert not any(p.is_file() and p.name != ".gitkeep" for p in (root / "assets").rglob("*"))
for directory in ['docs', 'scenes/app', 'scenes/gameplay', 'scenes/player', 'scenes/obstacles', 'scenes/enemies', 'scenes/collectibles', 'scenes/levels', 'scenes/ui', 'scripts/core', 'scripts/player', 'scripts/gameplay', 'scripts/obstacles', 'scripts/enemies', 'scripts/systems', 'scripts/ui', 'resources/levels', 'assets/characters', 'assets/environments', 'assets/obstacles', 'assets/ui', 'assets/fonts', 'assets/audio/music', 'assets/audio/sfx', 'tests']:
    assert (root / directory).is_dir(), directory
for name in ["README.md", "docs/TECHNICAL_DESIGN.md", "docs/PROJECT_STRUCTURE.md", "docs/DECISIONS.md", "docs/QA_TEST_PLAN.md"]:
    assert (root / name).stat().st_size > 0, name
print("PASS: static configuration, main-scene references, module directories and required docs")
print("LIMIT: this check does not prove Godot parsing, runtime, rendering or Android export")
