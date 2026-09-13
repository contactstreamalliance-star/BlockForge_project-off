# Performance

The pre-alpha now renders grouped visible faces instead of complete cubes for every visible block.

This reduces the number of triangles drawn and avoids many hidden faces. It also keeps texture UVs simple and easier to debug.

Transparent blocks no longer render internal faces against identical neighboring blocks, which reduces visual artifacts and avoids huge stacks of blended surfaces.

## 0.3.8 optimization pass

Chunk generation and chunk mesh rebuilds now use small per-frame time budgets. The game should keep drawing frames while terrain work continues instead of doing too much in one frame.

Breaking or placing a block rebuilds the edited chunk. Neighbor chunks are rebuilt only when the edited block is on a chunk border, because only then can a neighboring chunk face change.

Block targeting now uses direct voxel traversal instead of many tiny ray steps. This keeps looking around and spam clicking lighter.

Terrain generation caches repeated world settings inside each chunk job, and mesh building reuses face corner data instead of recreating it for every face.

Dropped item updates reuse the same frame timestamp and squared distance checks to avoid extra square-root work.

## 0.4.1 loading and generation stability

The title menu no longer builds the world before the player chooses a mode. Starting Survival, Creative or New World now shows a loading screen while the spawn chunks are generated and displayed.

During this loading screen, gameplay stays inactive and the mouse remains free. The player receives control only after the nearby spawn chunks are ready, which avoids starting inside a half-built view.

The loading screen can process extra terrain work because the player is not moving yet. Cave generation settings are copied into each chunk job so deep world generation does fewer repeated config lookups.

## 0.4.3 anti-freeze pass

Visible-block caches now store block positions directly. Mesh rebuilds no longer need to split text keys for every visible block.

Chunk block maps also keep positions. Visibility refreshes can reuse those positions instead of parsing coordinates again.

Tree placement is processed as part of the chunk job over multiple steps. A chunk no longer places every queued tree in one burst after its terrain columns are done.

Repeated block edits briefly coalesce chunk rebuilds. This reduces repeated rebuilds of the same chunk during rapid click spam while still keeping the world updated.

Worldgen block selection receives cached water level and minimum height values instead of reading the settings dictionary for every single generated block.

## 0.4.4 full loading pregeneration

World creation and world joining can now pregenerate every chunk in the configured map while the loading screen is visible.

This is intentionally split from rendering. The distant chunks are generated as terrain data, but the scene only displays the nearby spawn chunks at first. Rendering every generated chunk at startup would create a much larger mesh spike and hurt performance.

The generation queue prioritizes the spawn and then works outward, so the starting area is prepared first even when full-map pregeneration is enabled.

Editable performance knob:

- `assets/worldgen.json` -> `pregenerateFullWorldOnLoad`

When enabled, startup loading takes longer, but exploration should avoid more terrain-generation stalls later.

## 0.4.5 generation pass

Generated blocks now write directly into the active chunk map kept by the chunk job. This avoids checking and resolving the chunk dictionary for every generated block.

Height and biome caches use `Vector2i` keys instead of formatted strings, reducing allocation pressure while the full map is being prepared.

Cave noise is now skipped before calling the cave function when the block is inside the protected spawn, near bedrock, or too close to the surface. Those checks already returned false before; doing them at the column loop avoids many function calls during deep terrain generation.

Water generation now calculates shallow-water state once per column, and tree generation avoids rewriting a shared dictionary after every tree.

## 0.4.6 smooth voxel mode

World blocks now use `Vector3i` dictionary keys instead of formatted coordinate strings. This removes a large amount of string creation during generation and removes text parsing during chunk rebuilds.

Block properties used in hot paths are cached after `assets/blocks.json` is loaded:

- solid blocks
- transparent blocks
- liquid blocks
- placeable blocks
- block materials
- single-material blocks

Chunk mesh rebuilds now read neighbor blocks directly by coordinate, avoiding an extra helper call for every visible face check.

The default `pregenerateFullWorldOnLoad` value is now `false`. The setting still exists for manual testing, but the smoother default avoids forcing the game to generate the entire world block by block before play. This matters even more now that the default world is 128 chunks per side. The spawn area is still prepared before control returns to the player, and nearby chunks continue to stream in progressively.

## 0.2.2 optimization pass

The world mesh is split into 16 x 16 block chunks. Breaking or placing one block no longer rebuilds the whole world mesh.

Texture loading is cached, so repeated faces using the same PNG reuse the same texture resource instead of decoding the file again.

The HUD refreshes at a fixed lightweight interval instead of rebuilding its text every physics frame.

Block shadows are disabled for now. This is intentional for the pre-alpha because the blocky scene already has clear face lighting, and full shadow casting was too expensive for the current renderer.

Editable performance knobs:

- `assets/worldgen.json` -> `size`
- `assets/worldgen.json` -> `maxHeight`
- `F` in game toggles denser or lighter fog

If a machine still struggles, lower `size` first.

Current default world settings are intentionally streaming-first for the desktop pre-alpha:

- `size`: 2047
- `minHeight`: -42
- `maxHeight`: 78
- `waterLevel`: 9
- `waterEnabled`: true
- `treeChance`: 0.014
- `caveChance`: 0.16
- `renderDistanceChunks`: 1
- `pregenerateFullWorldOnLoad`: false

The spawn area is flattened into a wide clean meadow so the player does not appear under terrain, in water, inside leaves, or directly in front of a cliff.
