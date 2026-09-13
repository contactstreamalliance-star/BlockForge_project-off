# Worldgen V2

Worldgen V2 is configured from `assets/worldgen.json` and implemented in `src/world/worldgen_v2.gd`.

## Caves

The cave system is split into three layers:

- main tunnels: readable underground paths
- secondary branches: smaller connections around the main tunnels
- deep rooms: larger pockets that appear mostly lower underground

The spawn area is protected so the player should not start above a broken underground void. Caves also use vertical masks so tunnels and rooms do not carve huge open shafts through too many layers at once.

Editable cave settings:

- `caveChance`: general cave density.
- `caveTunnelThreshold`: higher values make main tunnels rarer.
- `cavePocketThreshold`: higher values make deep rooms rarer.
- `caveSurfaceBuffer`: minimum distance below the terrain surface before caves can carve.
- `caveFloorBuffer`: protected layer above the bottom of the world.
- `caveTunnelScale`: scale of main tunnel noise.
- `caveBranchScale`: scale of secondary branch noise.
- `caveRoomScale`: scale of deep room noise.
- `caveSmallRoomThreshold`: higher values make small cave pockets rarer.
- `caveMediumRoomThreshold`: higher values make medium caves rarer.
- `caveLargeRoomThreshold`: higher values make large caves rarer.

Mountains and rocky biomes open caves slightly more. Coast and forest biomes keep caves slightly tighter.

Current cave room rarity is intentionally layered:

- small caves are the most common
- medium caves need more depth and a rarer room seed
- large caves need deep placement, a high threshold, vertical band checks and an extra rarity gate

The default world is configured for 128 chunks per side. `pregenerateFullWorldOnLoad` should stay disabled for this size so the game streams chunks progressively.
