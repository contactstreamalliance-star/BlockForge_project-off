# Project Structure

This is a Godot desktop project with plain editable files.

- `project.godot` stores Godot project settings.
- `scenes/main.tscn` starts the game.
- `src/main.gd` coordinates the current pre-alpha.
- `src/ui/` contains interface panels.
- `src/systems/` contains shared game systems like audio.
- `src/utils/` contains small reusable helpers.
- `src/world/` contains voxel-world rendering and generation helpers.
- `src/world/worldgen_v2.gd` contains the active Worldgen V2 logic.
- `assets/blocks.json` defines blocks and textures.
- `assets/worldgen.json` controls terrain generation.
- `assets/patch_notes.json` controls in-game update notes.
- `assets/textures/blocks/` stores block textures.
- `assets/audio/` stores chiptune WAV files.
- `docs/WORLDGEN_CSHARP.md` explains the future C# migration path for the world generator.
- `tools/generate_assets.py` regenerates original editable prototype assets.
- `mods/` is reserved for future mod files.
