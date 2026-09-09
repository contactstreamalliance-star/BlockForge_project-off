# BlockForge Alpha

BlockForge Alpha est une pré-alpha Godot native d'un bac à sable voxel open source. Elle ne tourne pas dans un navigateur, ne dépend pas d'un CDN, et garde tous ses fichiers en clair pour GitHub.

Ce projet est indépendant de Minecraft. Il ne reprend aucun fichier, code, texture, son, nom, logo ou asset Minecraft.

## Lancer avec Godot

Ouvre ce dossier dans Godot :

```text
outputs/BlockForge_prject
```

ou lance directement :

```powershell
& "C:\Users\Utilisateur\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "C:\Users\Utilisateur\Documents\Codex\2026-09-06\serais-tu-capable-de-me-refaire\outputs\BlockForge_prject"
```

## Contrôles

- `Survie` : lance une partie avec vie, inventaire, craft et dégâts de chute.
- `Créatif` : lance une partie avec blocs illimités et sans dégâts de chute.
- `ZQSD` ou `WASD` : marcher.
- Souris : regarder.
- Espace : sauter.
- Clic gauche : casser le bloc visé.
- Clic droit : poser le bloc sélectionné.
- `1` à `9` : choisir un bloc.
- `E` ou `I` : ouvrir l'inventaire et le craft.
- `F` : changer le brouillard rétro.
- `R` : générer un nouveau monde.
- `Échap` : pause.

## Structure

- `scripts/` : code Godot séparé par rôle.
- `assets/` : blocs, textures, sons, langue, recettes, génération.
- `tools/generate_assets.py` : régénère les textures et sons originaux du prototype.
- `mods/` : emplacement prévu pour les futurs mods.
- `docs/` : documentation du projet.
- `.github/` : fichiers recommandés pour contribution GitHub.

## Statut

Pré-alpha jouable. Le moteur est volontairement simple et doit rester centré sur un jeu de survie voxel local, open source et facilement moddable.

La 0.3.0 ajoute une première base de survie avec inventaire, craft, barre de vie, dégâts de chute, écran Game Over, objets récupérables après réapparition et monde procédural plus grand.
