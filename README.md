# BlockForge Alpha

BlockForge Alpha est une pré-alpha Godot native d'un bac à sable voxel open source. Elle ne tourne pas dans un navigateur, ne dépend pas d'un CDN, et garde tous ses fichiers en clair pour GitHub.

Ce projet est indépendant de Minecraft. Il ne reprend aucun fichier, code, texture, son, nom, logo ou asset Minecraft.

## Contrôles

- `Survie` : lance une partie avec vie, inventaire, craft et dégâts de chute.
- `Créatif` : lance une partie avec blocs illimités et sans dégâts de chute.
- `ZQSD` ou `WASD` : marcher.
- Souris : regarder.
- Espace : sauter.
- Clic gauche : casser le bloc visé.
- Clic droit : poser le bloc sélectionné.
- `1` à `9` : choisir une case de barre rapide.
- `E` ou `I` : ouvrir l'inventaire, le craft et la personnalisation de la barre rapide.
- Dans l'inventaire : clique une case de barre rapide, puis clique une texture de bloc pour la remplacer.
- Dans l'inventaire : clic droit sur une case pour jeter 1 objet, `Maj` + clic droit pour détruire la pile.
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

La 0.3.6 améliore l'inventaire avec une grille visuelle, des icônes de blocs, des quantités lisibles et des panneaux défilables. Le pack externe ajouté sert de référence, mais reste hors du projet actif pour éviter ses erreurs de dépendances.

La 0.3.7 remplace les noms visibles par des textures dans l'inventaire et la barre rapide, puis ajoute la modification de la barre rapide depuis l'inventaire.

La 0.3.8 ajoute une passe anti-freeze: génération et reconstruction de chunks avec budget par frame, ciblage de bloc plus rapide et reconstructions limitées aux chunks réellement touchés.

La 0.3.9 retravaille l'inventaire de survie avec 36 cases limitées, des piles de 64, la possibilité de jeter ou détruire des objets, et une protection contre la perte d'objets quand l'inventaire est plein.

La 0.3.10 corrige les feuilles d'arbres qui pouvaient rester invisibles quand un arbre débordait dans un chunk voisin déjà affiché.

La 0.3.11 allège ce correctif: les arbres marquent les chunks à rafraîchir sans recalcul brutal immédiat, pour réduire les freezes pendant la génération.
