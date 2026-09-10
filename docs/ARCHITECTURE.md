# Architecture

BlockForge Alpha is kept intentionally simple for early contributors. Most gameplay data lives in editable JSON and PNG/WAV files, while the Godot scripts are grouped by responsibility.

## Main Flow

`src/main.gd` is the coordinator. It starts Godot nodes, loads data, creates the world, handles player input, updates the HUD, and asks smaller modules to do focused jobs.

Avoid putting every new feature in `main.gd`. If a feature can live on its own, create or extend a file in one of the folders below.

## Folders

- `src/ui/`: menu screens, HUD panels, patch notes, future inventory/crafting screens.
- `src/systems/`: reusable systems that are not tied to one block or one UI screen, such as audio, saving, local settings and future mod support.
- `src/utils/`: small helpers, caches, file loaders and generic utilities.
- `src/world/`: voxel rendering, block materials, world generation helpers, chunk helpers and selection visuals.

## Editable Data

- `assets/blocks.json`: add or edit blocks, names, solidity and texture paths.
- `assets/worldgen.json`: tune world size, seed, terrain mode and spawn settings.
- `assets/patch_notes.json`: add public update notes shown in game.
- `assets/textures/blocks/`: replace PNG textures.
- `assets/audio/`: replace WAV sounds and music.

## Current Scripts

- `src/main.gd`: game coordinator, player movement, world dictionary, chunk rebuild calls.
- `src/systems/player_inventory.gd`: stores and spends collected items.
- `src/systems/crafting_book.gd`: loads `assets/recipes.json` and applies craft results.
- `src/ui/patch_notes_controller.gd`: loads Patch Notes data and controls opening/closing.
- `src/ui/patch_notes_panel.gd`: builds and displays the Patch Notes screen.
- `src/systems/audio_library.gd`: loads and plays WAV sounds/music.
- `src/utils/texture_cache.gd`: loads PNG textures once and reuses them.
- `src/world/block_material_factory.gd`: creates Godot materials for block definitions.
- `src/world/selection_outline.gd`: creates the wireframe outline for the targeted block.

## Recommended Contribution Style

Keep changes small and easy to review. Prefer adding data to JSON files before changing code. When a new feature needs code, put it in the folder that matches its role and keep `main.gd` focused on connecting systems together.

## Project Direction

BlockForge Alpha should grow as a local-first open-source voxel survival game with editable data files, moddable systems and optional community extensions.
