# Source Code Guide

`main.gd` coordinates the playable pre-alpha. Keep it focused on connecting systems together.

- `ui/`: menus and interface panels.
- `ui/patch_notes_controller.gd`: loads and controls the Patch Notes screen.
- `ui/patch_notes_panel.gd`: displays the Patch Notes screen.
- `systems/`: reusable game systems such as audio, settings, saves and future mod support.
- `utils/`: generic helpers that can be reused anywhere.
- `world/`: voxel-specific helpers for block materials, selection, terrain math and future chunk/world code.

When adding a feature, prefer a small new file in the matching folder instead of growing `main.gd`.

Keep the core game local-first. Do not add forced servers, hidden online connections or account requirements to the base project.
