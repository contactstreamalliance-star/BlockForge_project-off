# BlockForge Alpha - Roadmap

## Objectif

Construire une premiere alpha jouable de Minecraft-like open source sous Godot.

Le joueur doit pouvoir :

- lancer le jeu en local ;
- explorer une petite zone ;
- casser et poser des blocs ;
- recolter des ressources ;
- fabriquer des objets simples ;
- modifier les fichiers du jeu ;
- partager le projet sur GitHub.

## Phase 0 - Nettoyage de direction

But : retirer l'ancienne orientation RPG en ligne et poser clairement la direction BlockForge.

Livrables :

- README recentre sur BlockForge ;
- architecture locale-first ;
- backlog Minecraft-like ;
- aucune mention de serveur obligatoire ;
- aucune logique d'IP cachee ou de connexion imposee ;
- anciens systemes de tirage remplaces par des prototypes de craft ou recompenses locales.

## Phase 1 - Base voxel

But : obtenir le vrai coeur du jeu.

Livrables :

- blocs de base ;
- generation simple d'un terrain ;
- pose de blocs ;
- cassage de blocs ;
- collisions propres ;
- sauvegarde locale.

## Phase 2 - Inventaire et craft

But : donner une vraie boucle de jeu.

Livrables :

- barre rapide ;
- inventaire simple ;
- ressources collectables ;
- recettes dans `data/recipes.json` ;
- table de craft ou menu de craft ;
- outils basiques.

## Phase 3 - Monde plus vivant

But : rendre l'exploration plus agreable.

Livrables :

- arbres ;
- pierres ;
- eau simple ;
- sons ;
- musique 8-bit ;
- menu principal propre ;
- options graphiques simples.

## Phase 4 - Modding

But : permettre aux contributeurs de modifier le jeu facilement.

Livrables :

- blocs ajoutes par fichiers ;
- textures remplacables ;
- recettes modifiables ;
- documentation modding ;
- exemples de mods ;
- separation claire du code.

## Phase 5 - Multijoueur optionnel, plus tard

Le multijoueur n'est pas prioritaire. Il ne doit pas bloquer le solo et ne doit jamais devenir obligatoire.

Regles :

- pas de serveur officiel integre ;
- pas d'IP personnelle dans le code ;
- pas de compte en ligne force ;
- pas de jeu en ligne massif ;
- seulement une option communautaire si le jeu local est deja solide.
