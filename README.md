# BlockForge Alpha

BlockForge Alpha est une base Godot pour construire un Minecraft-like open source : exploration locale, blocs, craft, ressources, survie douce et fichiers faciles a modifier.

Ce projet est un jeu local avant tout. Il ne doit pas devenir un jeu avec serveur obligatoire. Le coeur du projet doit rester jouable en local, ouvert aux modifications et simple a publier sur GitHub.

## Direction du projet

- bac a sable voxel local ;
- monde modifiable par blocs ;
- fichiers ouverts pour les textures, donnees, recettes et comportements ;
- modding communautaire sans dependance a des modloaders Minecraft ;
- multijoueur seulement optionnel plus tard, jamais obligatoire ;
- aucune IP personnelle, aucun serveur officiel cache, aucun compte en ligne force.

## Ouvrir le projet

1. Ouvre Godot.
2. Choisis `Importer`.
3. Selectionne ce dossier : `C:\Users\Utilisateur\Documents\Codex\2026-08-10\j\outputs\BlockForge_prject`.
4. Ouvre le fichier `project.godot`.
5. Lance la scene principale.

## Controles actuels

- `Z` ou `W` : avancer
- `Q` ou `A` : gauche
- `S` : reculer
- `D` : droite
- Fleches directionnelles : deplacement alternatif
- Souris : camera
- `Shift` : courir
- `Espace` : sauter
- Clic gauche : action principale temporaire
- Clic droit : action secondaire temporaire
- `F` : action speciale temporaire
- `TAB` : ciblage temporaire de prototype
- `E` : interagir avec ressource ou station proche
- `Echap` : liberer la souris

## Boucle de jeu visee

1. Apparaitre dans une petite zone voxel locale.
2. Recolter des ressources.
3. Casser et poser des blocs.
4. Fabriquer des objets simples.
5. Explorer et agrandir son monde.
6. Modifier les fichiers du jeu pour ajouter blocs, textures, recettes et mods.

## Etat actuel

Cette copie contient encore une scene Godot de test avec des assets temporaires. Elle doit maintenant etre recentree vers BlockForge :

- remplacer progressivement les anciens systemes RPG en ligne par des systemes de blocs ;
- ajouter un vrai monde voxel modifiable ;
- ajouter inventaire, craft, outils et ressources ;
- garder tous les fichiers modifiables directement ;
- documenter chaque mise a jour dans les fichiers du projet.

Les assets importes viennent du Godot Asset Store et ont ete choisis pour leur licence claire. Voir `docs/asset_sources.md`.

## Fichiers importants

- `scenes/main.tscn` : scene principale.
- `scripts/main.gd` : scene de test actuelle et logique temporaire.
- `scripts/player_controller.gd` : controle du joueur.
- `scripts/enemy_basic.gd` : comportements de test a remplacer par des creatures simples.
- `scripts/resource_node.gd` : ressources recoltables.
- `scripts/interactable_station.gd` : stations interactives du hub.
- `data/characters.json` : base des quatre personnages de depart.
- `docs/roadmap_alpha_0_1.md` : roadmap.
- `docs/backlog_alpha_0_1.md` : backlog.
- `docs/godot_architecture.md` : notes techniques.
- `docs/asset_sources.md` : sources et licences des assets temporaires.

## Prochaine vraie etape

La prochaine etape logique est de remplacer la scene de test par une premiere zone voxel jouable :

- blocs de terre, herbe, pierre, bois et feuilles ;
- cassage et pose de blocs ;
- inventaire simple ;
- textures modifiables ;
- sauvegarde locale ;
- documentation claire pour les futurs contributeurs.
