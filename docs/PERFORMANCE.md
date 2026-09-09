# Performance

The pre-alpha now renders grouped visible faces instead of complete cubes for every visible block.

This reduces the number of triangles drawn and avoids many hidden faces. It also keeps texture UVs simple and easier to debug.

Transparent blocks no longer render internal faces against identical neighboring blocks, which reduces visual artifacts and avoids huge stacks of blended surfaces.

## 0.2.2 optimization pass

The world mesh is now split into 16 x 16 block chunks. Breaking or placing one block no longer rebuilds the whole world mesh; only the changed chunk and its four direct neighboring chunks are rebuilt.

Texture loading is cached, so repeated faces using the same PNG reuse the same texture resource instead of decoding the file again.

The HUD refreshes at a fixed lightweight interval instead of rebuilding its text every physics frame.

Block shadows are disabled for now. This is intentional for the pre-alpha because the blocky scene already has clear face lighting, and full shadow casting was too expensive for the current renderer.

Editable performance knobs:

- `assets/worldgen.json` -> `size`
- `assets/worldgen.json` -> `maxHeight`
- `F` in game toggles denser or lighter fog

If a machine still struggles, lower `size` first.

Current default world settings are intentionally conservative for the desktop pre-alpha:

- `size`: 44
- `maxHeight`: 18
- `waterLevel`: 6
- `waterEnabled`: false
- `treeChance`: 0.003

The spawn area is flattened into a wide clean meadow so the player does not appear under terrain, in water, inside leaves, or directly in front of a cliff.
