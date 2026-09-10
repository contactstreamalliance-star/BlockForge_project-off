# Changelog

## 0.3.11-godot - 2026-09-10

- Reduced freezes caused by the tree-leaf visibility fix.
- Tree generation now keeps bulk updates enabled while logs and leaves are placed.
- Tree-touched chunks now invalidate their visible-block cache instead of rebuilding it immediately.
- Neighbor chunks touched by tree leaves are rebuilt through the normal chunk rebuild queue.

## 0.3.10-godot - 2026-09-10

- Fixed tree leaves that could stay invisible until a nearby block was broken.
- Tree generation now tracks every touched chunk, including neighboring chunks.
- Visible-block caches are refreshed for all chunks modified by a generated tree.
- Already displayed neighboring chunks are queued for rebuild when tree leaves spill across chunk borders.

## 0.3.9-godot - 2026-09-10

- Reworked survival inventory into 36 fixed slots.
- Added 64-unit stacks for blocks and items.
- Added right-click inventory dropping for one item at a time.
- Added Shift + right-click inventory destruction for a full stack.
- Crafting now checks output space before consuming ingredients.
- Dropped items now stay on the ground when the inventory is full.
- Death drops now preserve separate inventory stacks.

## 0.3.8-godot - 2026-09-10

- Added per-frame time budgets for chunk generation and chunk rebuild work.
- Replaced step-based block targeting with direct voxel traversal.
- Reduced block spam cost by rebuilding neighboring chunks only when the edited block touches a chunk border.
- Reduced repeated worldgen config reads during terrain generation.
- Cached face corner data and hotbar styles to cut repeated allocations.
- Reduced dropped item update cost by reusing frame time and squared distance checks.

## 0.3.7-godot - 2026-09-10

- Replaced text-heavy inventory and hotbar slots with texture icons.
- Added an editable hotbar row inside the inventory screen.
- Added click-to-assign behavior: select a hotbar slot, then click an inventory block texture.
- Creative mode inventory now shows placeable blocks so the hotbar can be customized without gathering resources first.

## 0.3.6-godot - 2026-09-10

- Used the added inventory asset as a safe reference instead of importing its broken dependencies into the active Godot project.
- Added visual inventory slots with block icons, item counts and hover feedback.
- Added scrollable inventory and crafting panels so more items and recipes fit cleanly.
- Kept the external asset pack outside the active project to prevent Godot parse errors.

## 0.3.5-godot - 2026-09-10

- Regrouped all optimization notes into one entry.
- Added chunked world rebuilding, chunk rebuild queues, progressive chunk generation and column-by-column terrain generation.
- Added visible-block caching, texture caching, shared materials for single-texture blocks and block action pacing.
- Reduced repeated work in mesh rebuilds, world generation, spawn setup, hotbar refreshes, HUD updates, dropped item checks, collision checks and block targeting.
- Kept already displayed chunks in the scene when the player moves away.
- Removed separate optimization changelog entries to keep the history easier to read.

## 0.3.0-godot - 2026-09-10

- Added Survival and Creative mode selection from the title menu.
- Added a larger procedural world with hills, mountains, deeper terrain and caves.
- Added inventory, craft recipes, health, fall damage, Game Over and respawn flow.
- Added dropped item pickups after death.
- Added granite, clay, coal ore, iron ore, coal, raw iron and workbench data/textures.
- Added `src/systems/player_inventory.gd` and `src/systems/crafting_book.gd`.
- Kept chunked visible-face rendering active; smoke test generated about 162k blocks and 95k visible faces without script errors.

## 0.2.4-godot - 2026-09-07

- Split reusable code out of `src/main.gd` into focused files under `src/ui`, `src/systems`, `src/utils` and `src/world`.
- Added `PatchNotesPanel`, `AudioLibrary`, `TextureCache`, `BlockMaterialFactory` and `SelectionOutline` scripts.
- Removed old unused helper code from `main.gd`.
- Added architecture documentation for future contributors.

## 0.2.3-godot - 2026-09-07

- Added an in-game Patch Notes menu available from the title screen and the Escape pause menu.
- Added editable `assets/patch_notes.json` so update notes can be changed without rebuilding archives.
- Added structured update entries with title, description, additions, modifications and removals.

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
