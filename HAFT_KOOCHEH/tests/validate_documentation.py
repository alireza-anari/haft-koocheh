"""Validate phase 1.3 documents and scope; no gameplay or visual validation."""
import argparse
import re
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
CORE_DOCS = ["GDD.md", "GAMEPLAY_ARCHITECTURE.md", "PLAYER_MOVEMENT_SPEC.md", "ASSET_GUIDE.md", "LEVEL_DESIGN_SPEC.md"]
ALLOWED_MODIFIED = {"README.md", "docs/DECISIONS.md", "docs/QA_TEST_PLAN.md", "docs/PROJECT_STATE.md", "docs/git_validation_results.json", "tests/validate_skeleton.py", "tests/validate_documentation.py", "scripts/player/player_controller.gd", "docs/GAMEPLAY_ARCHITECTURE.md"}
EMPTY_DIR_PLACEHOLDERS = {
    "assets/audio/music/.gitkeep", "assets/audio/sfx/.gitkeep",
    "assets/characters/.gitkeep", "assets/environments/.gitkeep", "assets/fonts/.gitkeep",
    "assets/obstacles/.gitkeep", "assets/ui/.gitkeep", "resources/levels/.gitkeep",
    "scenes/enemies/.gitkeep", "scenes/levels/.gitkeep", "scenes/ui/.gitkeep",
    "scripts/core/.gitkeep", "scripts/enemies/.gitkeep", "scripts/ui/.gitkeep",
    "scenes/collectibles/.gitkeep", "scripts/systems/.gitkeep",
}



def source_paths():
    return {p.relative_to(ROOT).as_posix() for p in ROOT.rglob("*") if p.is_file() and not {".git", ".godot", "__pycache__"}.intersection(p.relative_to(ROOT).parts)}


def without_fences(text):
    return re.sub(r"^```[^\n]*\n.*?^```\s*$", "", text, flags=re.M | re.S)


def validate():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, help="Optional R1 ZIP for byte and allowed-change validation")
    args = parser.parse_args()
    docs = {n: (ROOT / "docs" / n).read_text(encoding="utf-8") for n in CORE_DOCS}
    assert all(len(t.splitlines()) >= 70 for t in docs.values()), "Incomplete core document"
    local_links = 0
    external_links = 0
    for md in [ROOT / "README.md", *sorted((ROOT / "docs").glob("*.md"))]:
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", without_fences(md.read_text(encoding="utf-8"))):
            if re.match(r"https?://", target):
                external_links += 1
                continue
            path, _, anchor = target.partition("#")
            resolved = (md.parent / path).resolve() if path else md
            assert resolved.is_relative_to(ROOT), (md.name, target, "outside project")
            assert resolved.is_file(), (md.name, target, "missing link")
            assert not anchor, "Anchor validation not supported; use file links in this stage"
            local_links += 1
    print(f"PASS: {len(CORE_DOCS)} core docs; {local_links} local Markdown links resolve")
    print(f"LIMIT: {external_links} external Markdown links not HTTP-tested by this validator")

    def level_rows(text):
        rows = re.findall(r"^\| (bazaar_\d{2}) \| ([^|]+) \|", text, re.M)
        return [(i, name.strip()) for i, name in rows]
    gdd_rows = level_rows(docs["GDD.md"])
    level_design_rows = level_rows(docs["LEVEL_DESIGN_SPEC.md"])
    assert [i for i, _ in gdd_rows] == [f"bazaar_{n:02d}" for n in range(1, 11)]
    assert gdd_rows == level_design_rows, "GDD/level IDs or names disagree"
    expected = {"run_speed": "280", "gravity": "1200", "jump_velocity": "-480", "coyote_time": "0.08", "jump_buffer": "0.10"}
    rows = dict(re.findall(r"^\| (run_speed|gravity|jump_velocity|coyote_time|jump_buffer) \| ([^|]+?) \|", docs["PLAYER_MOVEMENT_SPEC.md"], re.M))
    assert {k: v.strip() for k, v in rows.items()} == expected
    decisions = (ROOT / "docs/DECISIONS.md").read_text()
    for key, value in expected.items():
        assert f"{key}={value}" in decisions, (key, "decision parameter mismatch")
    formula = "score = 10 * coins_collected"
    for name in ["GDD.md", "GAMEPLAY_ARCHITECTURE.md", "LEVEL_DESIGN_SPEC.md"]:
        assert formula in docs[name], (name, "score contract mismatch")
    assert formula in decisions
    ids = re.findall(r"^\| (DEC-\d+) \|", decisions, re.M)
    assert ids == [f"DEC-{n:03d}" for n in range(13, 40)], "Missing, duplicate or reordered decision ID"
    qa = (ROOT / "docs/QA_TEST_PLAN.md").read_text()
    assert re.search(r"\| QA-001 \| باز", qa) and re.search(r"\| QA-002 \| باز", qa)
    planned = re.findall(r"^\| (P1-\d+) \|.*\| PLANNED / NOT RUN \|$", qa, re.M)
    assert len(planned) == 22 and len(set(planned)) == 22
    for state in ["READY", "RUNNING", "PAUSED", "FAILED", "COMPLETED"]:
        assert state in docs["GAMEPLAY_ARCHITECTURE.md"]
    print("PASS: 10 shared level IDs/names; 5 movement values; scoring formula; decision IDs; 22 historical planned cases retained; QA-001B and QA-002 remain open")

    sources = source_paths()
    runtime_scripts = {"scripts/player/player_controller.gd", "scripts/gameplay/prototype_run.gd", "tests/test_auto_run.gd", "tests/test_jump.gd", "scripts/gameplay/level_controller.gd", "scripts/obstacles/hazard.gd", "tests/test_failure_restart.gd"}
    runtime_scenes = {"scenes/app/main.tscn", "scenes/player/player.tscn", "scenes/gameplay/prototype_run.tscn", "scenes/gameplay/failure_prototype.tscn", "scenes/gameplay/failure_world.tscn", "scenes/obstacles/hazard.tscn"}
    assert {x for x in sources if x.endswith(".tscn")} == runtime_scenes
    assert {x for x in sources if x.endswith(".gd")} == runtime_scripts
    assert not any(x.endswith((".tres", ".cs", ".csproj")) for x in sources)
    assert not any(x.startswith(("assets/", "resources/")) and not x.endswith("/.gitkeep") for x in sources)
    assert not (ROOT / "export_presets.cfg").exists()
    print("PASS: only approved movement/failure scripts/scenes; no external asset, system manager or export preset")

    if args.baseline:
        with ZipFile(args.baseline) as baseline:
            assert baseline.testzip() is None
            old_files = {n.removeprefix("HAFT_KOOCHEH/"): baseline.read(n) for n in baseline.namelist() if not n.endswith("/")}
            assert len(old_files) == 140
            assert set(old_files).issubset(sources), "Deleted baseline file"
            changed = {name for name, data in old_files.items() if (ROOT / name).read_bytes() != data}
            assert changed.issubset(ALLOWED_MODIFIED), sorted(changed - ALLOWED_MODIFIED)
            new = sources - set(old_files)
            allowed_runtime = runtime_scripts | runtime_scenes | {n + ".uid" for n in runtime_scripts}
            assert all(n in allowed_runtime or n in {"docs/PHASE_1_3_REPORT.md", "docs/phase_1_3_test_results.json", "docs/phase_1_3_manifest.json"} or n.startswith("docs/phase_1_3_evidence/") or n in EMPTY_DIR_PLACEHOLDERS for n in new), sorted(new)
            for name in ["project.godot", "scenes/app/main.tscn", ".gitignore", "docs/GDD.md", "docs/LEVEL_DESIGN_SPEC.md", "docs/PLAYER_MOVEMENT_SPEC.md", "scenes/player/player.tscn", "scenes/gameplay/prototype_run.tscn", "scripts/gameplay/prototype_run.gd", "tests/test_auto_run.gd", "tests/test_jump.gd"]:
                assert (ROOT / name).read_bytes() == old_files[name], name
            for name in ["docs/TECHNICAL_DESIGN.md", "docs/DECISIONS.md", "docs/QA_TEST_PLAN.md"]:
                assert (ROOT / name).read_bytes().startswith(old_files[name]), "Historical text not preserved: " + name
            for n in baseline.namelist():
                if n.endswith("/"):
                    assert (ROOT / n.removeprefix("HAFT_KOOCHEH/")).is_dir(), n
        print("PASS: 140-file baseline preserved; only permitted failure/docs/report/test changes; original decisions and historical QA retained")
    else:
        print("NOT RUN: baseline byte comparison (supply --baseline with the R1 ZIP)")
    print("LIMIT: this is mechanical document/scope validation; semantic review, graphics, gameplay and Android are separate")


if __name__ == "__main__":
    validate()
