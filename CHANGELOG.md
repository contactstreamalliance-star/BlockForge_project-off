# Changelog

## 0.3.0-godot - 2026-09-10

- Added Survival and Creative mode selection from the title menu.
- Added a larger procedural world with hills, mountains, deeper terrain and caves.
- Added inventory, craft recipes, health, fall damage, Game Over and respawn flow.
- Added dropped item pickups after death.
- Added granite, clay, coal ore, iron ore, coal, raw iron and workbench data/textures.
- Added `scripts/systems/player_inventory.gd` and `scripts/systems/crafting_book.gd`.
- Kept chunked visible-face rendering active; smoke test generated about 162k blocks and 95k visible faces without script errors.

## 0.2.4-godot - 2026-09-07

- Split reusable code out of `scripts/main.gd` into focused files under `scripts/ui`, `scripts/systems`, `scripts/utils` and `scripts/world`.
- Added `PatchNotesPanel`, `AudioLibrary`, `TextureCache`, `BlockMaterialFactory` and `SelectionOutline` scripts.
- Removed old unused helper code from `main.gd`.
- Added architecture documentation for future contributors.

## 0.2.3-godot - 2026-09-07

- Added an in-game Patch Notes menu available from the title screen and the Escape pause menu.
- Added editable `assets/patch_notes.json` so update notes can be changed without rebuilding archives.
- Added structured update entries with title, description, additions, modifications and removals.

## 0.2.2-godot - 2026-09-07

- Added 16 x 16 chunked mesh rebuilding so block edits no longer rebuild the entire world.
- Added PNG texture caching during material setup.
- Reduced HUD update work by refreshing debug text on a short timer instead of every physics frame.
- Kept shadows disabled and documented the choice as a pre-alpha performance setting.

## 0.2.1-godot - 2026-09-07

- Disabled back-face culling on block materials so grass/ground faces no longer disappear from the player view.
- Disabled the temporary strip clouds because they made the sky look broken.
- Made the default seed deterministic for easier debugging and a consistent clean spawn.
- Flattened the playable start area further and softened terrain changes around it.
- Added `JOUER.bat` so the corrected desktop build can be launched directly from the project folder.

## 0.2.0-godot - 2026-09-07

- Added native Godot desktop pre-alpha.
- Added procedural voxel world, block breaking and placement.
- Added editable PNG textures and WAV chiptune assets.
- Added GitHub-ready community files.
- Replaced full-cube rendering with visible-face voxel meshes for smoother performance.
- Fixed selection outline rendering as a filled dark cube.
- Reduced transparent/internal faces and improved spawn placement to avoid starting inside foliage.
- Simplified noisy textures, reduced water rendering to surface faces and opened a clear spawn area.
- Added a hard stability patch: water is disabled by default, spawn is flattened, shadows are disabled, fog is lighter, and the HUD now adapts to smaller windows.
- Reworked the default world again into a clean demo meadow: no fog at launch, no trees at spawn, gentler terrain, and a wider playable start area.
- Retuned block lighting and regenerated several textures to remove the neon grass and over-dark blue wall effect.
