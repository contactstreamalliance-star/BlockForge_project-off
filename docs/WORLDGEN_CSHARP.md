# Worldgen C# note

The active project currently uses the standard Godot build installed on this machine, not the Godot .NET build.

For that reason, the playable Worldgen V2 stays active in `src/world/worldgen_v2.gd` so the game keeps launching normally.

The new worldgen module is intentionally separated from `main.gd` to make a future C# port easier:

- terrain height calculation
- biome selection
- natural block selection
- ore placement
- cave carving
- tree density per biome

To make C# active later, the project should be opened with Godot .NET, then this module can be ported to a C# class without changing the editable data files in `assets/worldgen.json` and `assets/blocks.json`.
