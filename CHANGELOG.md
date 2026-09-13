# Changelog

## 0.4.9-godot - 2026-09-13

- Reduced oversized vertical cave openings in Worldgen V2.
- Added vertical masks to main tunnels and room carving so caves stay closer to controlled bands instead of becoming extremely tall voids.
- Reduced global cave density from `0.22` to `0.16`.
- Raised cave thresholds so medium and large cave rooms are rarer.
- Increased surface and floor buffers so caves avoid the terrain surface and the bottom layer more strongly.
- Expanded the configured world to 128 chunks per side with `size` set to `2047`.
- Kept `pregenerateFullWorldOnLoad` disabled so the larger world streams progressively instead of freezing at startup.

## 0.4.8-godot - 2026-09-13

- Rebalanced cave room generation so small caves are the most common, medium caves are rarer and large caves are very rare.
- Added editable cave size thresholds to `assets/worldgen.json`: `caveSmallRoomThreshold`, `caveMediumRoomThreshold` and `caveLargeRoomThreshold`.
- Small cave pockets now use tighter noise for smaller underground shapes.
- Medium caves require a rarer room seed and more depth.
- Large caves require deep underground placement, a high threshold and an extra rarity gate.

## 0.4.7-godot - 2026-09-13

- Reworked the Worldgen V2 cave system.
- Added separate cave layers for main tunnels, secondary branches and deeper rooms.
- Added editable cave controls in `assets/worldgen.json`: `caveSurfaceBuffer`, `caveFloorBuffer`, `caveTunnelScale`, `caveBranchScale` and `caveRoomScale`.
- Protected the spawn more strongly from nearby cave cuts.
- Caves now avoid the surface more consistently and reserve larger rooms for deeper underground layers.
- Cave openness now reacts slightly to biomes, with mountain and rocky areas allowing more caves than coast and forest areas.

## 0.4.6-godot - 2026-09-13

- Added a larger smooth-mode optimization pass for the voxel engine.
- World block keys now use `Vector3i` coordinates instead of formatted `x,y,z` strings.
- Chunk rebuilds now reuse native block positions without text parsing.
- Block rendering, collision and targeting now use cached block property dictionaries for solid, transparent, liquid, placeable and material lookups.
- Mesh rebuild neighbor checks now read directly from the world dictionary by coordinate.
- Disabled full block-by-block world pregeneration by default to avoid large startup stalls; `pregenerateFullWorldOnLoad` remains available in `assets/worldgen.json` for manual testing.
- Removed the old text coordinate parser that was no longer needed.

## 0.4.5-godot - 2026-09-13

- Added a world-generation optimization pass focused on full loading pregeneration.
- Generated blocks now write into the active chunk map directly instead of checking and resolving the chunk map for every block.
- Height and biome caches now use `Vector2i` keys instead of formatted text keys.
- Cave checks are skipped before calling noise when a column is inside the protected spawn, too deep for caves, or too close to the surface.
- Water column generation now computes shallow-water state once per column.
- Tree generation avoids rewriting the touched-chunk dictionary back into the active job after each tree.

## 0.4.4-godot - 2026-09-13

- Added full-world pregeneration during the loading screen when creating or joining a world.
- Added `pregenerateFullWorldOnLoad` to `assets/worldgen.json`.
- Loading progress now separates full map generation from spawn display preparation.
- Initial generation is queued from the spawn outward so the start area stays prioritized.
- Distant chunks are generated as world data only; the game still renders only the useful nearby chunks to avoid a massive startup mesh freeze.
- Increased loading generation passes slightly while gameplay is inactive.

## 0.4.3-godot - 2026-09-13

- Added a larger anti-freeze optimization pass for world generation and chunk rebuilds.
- Chunk visible-block caches now store `Vector3i` positions directly instead of reparsing text keys during mesh rebuilds.
- Chunk block maps now also keep block positions, reducing coordinate parsing during visibility refreshes.
- Tree generation is now processed across chunk job steps instead of all trees being placed in one burst at the end of a chunk.
- Rebuilds caused by rapid block breaking/placing are briefly coalesced so the same chunk is not rebuilt too aggressively during click spam.
- Worldgen block selection now receives cached water/min-height values instead of reading generation settings for every generated block.
- Loading can process more generation passes while gameplay is inactive, making the start area prepare faster without giving control too early.

## 0.4.2-godot - 2026-09-13

- Moved Worldgen V2 terrain, biome, ore, cave and tree-density logic into `src/world/worldgen_v2.gd`.
- Kept the active implementation in GDScript because the installed Godot build is not the .NET/C# build.
- Added `docs/WORLDGEN_CSHARP.md` to document the future C# migration path.
- Added essential terrain blocks: deep stone, gravel, rocky dirt, wet sand and shallow water.
- Added copper ore, raw copper, rare ore and forge crystal.
- Generated textures for the new blocks and updated the asset generator.
- Updated terrain generation so deep layers, coasts, dry zones and rocky areas use the new blocks.

## 0.4.1-godot - 2026-09-13

- Added a loading screen for Survival, Creative and New World startup.
- The title menu no longer generates the world before the player chooses a mode.
- The player receives control only after nearby spawn chunks are generated and displayed.
- Added loading progress based on generated and rendered spawn chunks.
- Chunk generation does extra work while the loading screen is visible, keeping gameplay inactive until the start area is ready.
- Cached cave settings inside each chunk generation job to reduce repeated config reads during underground generation.

## 0.4.0-godot - 2026-09-13

- Started Worldgen V2.
- Increased world bounds to 192 blocks wide with deeper underground space and taller terrain.
- Added simple biome selection for meadow, forest, coast, dry, rocky and mountain zones.
- Reworked terrain height into layered continent, hill, detail and ridge noise.
- Added height and biome caches so repeated terrain queries do less work.
- Reworked caves with deeper tunnel and pocket noise while keeping the spawn area protected.
- Tree density now depends on the generated biome.
- Added editable `assets/worldgen.json` controls for biome scale, detail strength, spawn blending and cave thresholds.

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
