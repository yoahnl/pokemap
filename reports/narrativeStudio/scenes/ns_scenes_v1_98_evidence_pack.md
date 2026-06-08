# Evidence Pack — NS-SCENES-V1-98

Lot : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`  
Date : 2026-06-08  
Demandeur : Karim  
Objectif : Implémenter le résolveur de sprites acteurs statiques purement symbolique et synchrone pour le Cinematic Builder avec ses tests unitaires.

## Gate 0 complet

Statut Git initial :
```text
On branch main
nothing to commit, working tree clean
```

---

## Liste des fichiers créés et modifiés

Les fichiers suivants ont été ajoutés ou modifiés pour l'implémentation de ce lot :
- [cinematic_actor_sprite_preview_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart) (Création du modèle logique de plan)
- [cinematic_actor_sprite_preview_resolver.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart) (Création du résolveur logique et symbolique)
- [cinematic_actor_sprite_preview_resolver_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart) (Création de la suite de tests unitaires)
- [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md) (Mise à jour du statut V1-98 et recommandation V1-99)
- [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md) (Mise à jour de la feuille de route du Builder et détails V1-98/V1-99)

---

## Commandes exécutées et résultats

### 1. Exécution des tests unitaires du résolveur
```bash
cd packages/map_editor
flutter test test/cinematic_actor_sprite_preview_resolver_test.dart
```

**Résultat :**
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
00:00 +0: Cinematic Actor Sprite Preview Resolver resolves cinematic only actor sprite preview plan from character idle frame
00:00 +1: Cinematic Actor Sprite Preview Resolver resolves player actor using settings default character ID
00:00 +2: Cinematic Actor Sprite Preview Resolver resolves direction fallback warning when requested direction idle is missing
00:00 +3: Cinematic Actor Sprite Preview Resolver returns missingDirectionFrame when idle animation for requested direction has no frames
00:00 +4: Cinematic Actor Sprite Preview Resolver returns missingIdleAnimation when character has no idle animations at all
00:00 +5: Cinematic Actor Sprite Preview Resolver returns missingCharacter when character is not found in manifest
00:00 +6: Cinematic Actor Sprite Preview Resolver returns missingTileset when character tileset is not found in manifest
00:00 +7: Cinematic Actor Sprite Preview Resolver returns invalidSourceRect when frame source coordinates are negative
00:00 +8: Cinematic Actor Sprite Preview Resolver resolves hidden actors without generating errors
00:00 +9: All tests passed!
```

### 2. Analyse statique ciblée sur les nouveaux fichiers
```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart test/cinematic_actor_sprite_preview_resolver_test.dart
```

**Résultat :**
```text
Analyzing 3 items...                                            
No issues found! (ran in 0.7s)
```

### 3. Exécution des tests de régression ciblés
```bash
cd packages/map_editor
flutter test test/cinematic_builder_workspace_test.dart --plain-name 'uses Path Studio center pattern when a path layer references its base preset'
flutter test test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-96-bis real Map Editor ordering fix visual gate when requested'
flutter test test/cinematics_library_workspace_test.dart
```

**Résultat :**
- Path Studio regression: **All tests passed!**
- Ordering V1-96-bis visual gate: **All tests passed!**
- Cinematics Library workspace: **All tests passed!** (22/22)

### 4. Validation du package Core
```bash
cd packages/map_core
dart test --reporter=compact && dart analyze
```

**Résultat :**
- Test suite: **All tests passed!**
- Analyze: **No issues found!**

---

## Statut Git final (Visualisation des modifications)

```bash
git status --short --untracked-files=all
```

**Résultat :**
```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
?? packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_evidence_pack.md
```

Aucun fichier source de production hors des nouveaux fichiers prévus n'a été altéré.

---

## Auto-review critique de conformité

1. **Le résolveur est-il purement synchrone et symbolique ?** Oui. Zéro appel à `readAsBytes`, décodage image, ou instance de `dart:ui`.
2. **Les dimensions viennent-elles bien du personnage ?** Oui. Elles sont extraites de `frameWidth` et `frameHeight` de la fiche personnage, et non de `TilesetSourceRect`.
3. **Le diagnostic de fallback directionnel est-il implémenté ?** Oui (`actorDisplayDirectionFallback`).
4. **La gestion de missingIdleAnimation et missingDirectionFrame est-elle conforme ?** Oui, validée par tests unitaires.
5. **Le read model V1-91 est-il consommé directement ?** Oui, par le biais des propriétés pré-résolues.
6. **Aucune UI Flame/Widget n'a été touchée ?** Oui, 100% de logique pure dans map_editor.
7. **Le plan contient-il les depthHints requis pour V1-99 ?** Oui (`visualBottom`, `anchorTileX`, etc.).
8. **Aucun import runtime Flame/GameState ?** Oui, étanchéité validée par analyse statique.
9. **Le statut Git respecte-t-il les interdictions de commit ?** Oui. Aucun Git write exécuté.
