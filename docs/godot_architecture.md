# BlockForge Alpha - Architecture Godot locale-first

## Positionnement

BlockForge Alpha est un Minecraft-like open source construit avec Godot. Le projet doit rester local-first : le joueur doit pouvoir lancer, modifier et tester le jeu sans serveur, sans compte et sans connexion obligatoire.

## Regles de direction

- Ne pas transformer le projet en jeu en ligne massif.
- Ne pas ajouter de serveur officiel obligatoire.
- Ne pas cacher d'adresse IP ou de cible reseau dans le code.
- Ne pas ajouter de compte en ligne force.
- Preferer des fichiers clairs et modifiables aux systemes fermes.
- Garder le multijoueur comme sujet optionnel pour plus tard.

## Architecture cible

```text
res://
  scenes/
    main.tscn
    player/
    blocks/
    ui/
  scripts/
    player/
    world/
    blocks/
    inventory/
    crafting/
    mods/
    ui/
  data/
    blocks.json
    recipes.json
    worldgen.json
    items.json
  assets/
    textures/
    audio/
    models/
    ui/
```

## Priorites techniques

1. Monde voxel local.
2. Pose et cassage de blocs.
3. Inventaire simple.
4. Crafting de base.
5. Sauvegarde locale.
6. Chargement de blocs, recettes et textures depuis des fichiers modifiables.
7. Outils de modding simples et documentes.

## Ce qui doit remplacer l'ancienne direction

- Le hub en ligne devient une zone de depart locale.
- Les systemes de tirage deviennent des prototypes de recettes, plans ou recompenses locales.
- Les personnages multiples deviennent des profils ou skins optionnels.
- L'economie en ligne devient une progression locale.
- Le backend serveur sort du scope de base.

## Structure actuelle

La scene actuelle reste une base temporaire. Elle sert a tester Godot, la camera, les interactions et quelques assets. Les prochaines passes doivent extraire ou remplacer ce qui ne sert pas le sandbox voxel.

## Style de contribution

Chaque ajout doit etre petit, lisible et facile a modifier. Quand c'est possible, ajouter ou modifier des donnees dans `data/` avant de coder en dur dans les scripts.
