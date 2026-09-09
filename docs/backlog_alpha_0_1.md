# BlockForge Alpha - Backlog

## Priorites

- P0 : indispensable pour retrouver le projet Minecraft-like.
- P1 : important pour rendre la pre-alpha agreable.
- P2 : utile pour les futures versions.

## P0 - Coeur Minecraft-like

| ID | Tache | Resultat attendu | Profil |
| --- | --- | --- | --- |
| P0-01 | Nettoyage direction | Plus de vision RPG en ligne dans la base officielle | Design |
| P0-02 | Projet Godot propre | Dossier ouvrable dans Godot avec scene principale | Dev |
| P0-03 | Monde voxel | Terrain simple compose de blocs | Dev gameplay |
| P0-04 | Casser un bloc | Le joueur peut retirer un bloc vise | Dev gameplay |
| P0-05 | Poser un bloc | Le joueur peut placer un bloc depuis la barre rapide | Dev gameplay |
| P0-06 | Collisions blocs | Le joueur marche correctement sur le terrain | Dev gameplay |
| P0-07 | Textures modifiables | Les blocs utilisent des fichiers faciles a remplacer | Art/dev |
| P0-08 | Sauvegarde locale | Le monde peut etre garde sur le PC | Dev systeme |

## P1 - Boucle de jeu

| ID | Tache | Resultat attendu | Profil |
| --- | --- | --- | --- |
| P1-01 | Barre rapide | Choix rapide des blocs et outils | UI/gameplay |
| P1-02 | Inventaire simple | Ressources visibles et utilisables | UI/gameplay |
| P1-03 | Recettes JSON | Craft modifiable sans recompilation | Dev systeme |
| P1-04 | Table de craft | Premiere interface de fabrication | UI |
| P1-05 | Outils basiques | Pioche, hache, pelle prototypes | Gameplay |
| P1-06 | Sons 8-bit | Pas, casse, pose, menu, ambiance | Audio |
| P1-07 | Menu principal | Jouer, options, patch notes, quitter | UI |
| P1-08 | Patch notes | Historique des mises a jour en jeu | UI/docs |

## P2 - Modding et qualite

| ID | Tache | Resultat attendu | Profil |
| --- | --- | --- | --- |
| P2-01 | Dossier mods | Emplacement clair pour extensions | Dev |
| P2-02 | Exemple de bloc modde | Exemple simple pour contributeurs | Dev/docs |
| P2-03 | Documentation structure | Ou modifier quoi | Docs |
| P2-04 | Options graphiques | Distance, brouillard, volume | UI |
| P2-05 | Optimisation chunks | Meilleures performances | Dev moteur |
| P2-06 | Creatures simples | Animaux ou ennemis locaux | Gameplay |

## Hors scope actuel

- jeu en ligne massif ;
- serveur officiel ;
- comptes en ligne ;
- economie en ligne ;
- hotel des ventes ;
- systeme de tirage payant ou aleatoire ;
- IP personnelle cachee dans le code ;
- multijoueur obligatoire.

## Ordre de travail recommande

1. Supprimer ou remplacer les derniers textes herites de l'ancien prototype.
2. Construire la base voxel locale.
3. Ajouter casse/pose de blocs.
4. Ajouter inventaire et barre rapide.
5. Ajouter craft et recettes modifiables.
6. Ajouter sons et menu propre.
7. Documenter le modding.
