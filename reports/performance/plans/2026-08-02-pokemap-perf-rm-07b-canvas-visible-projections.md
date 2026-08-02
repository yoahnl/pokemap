# PERF-RM-07B — Plan d’implémentation des projections canvas visibles

## Objectif

Rendre le coût du canvas éditeur dépendant du viewport et non de la taille totale de la map, sans modifier le rendu, l’ordre des couches ni les données sérialisées.

## Périmètre

- transmettre les bornes cellulaires visibles déjà calculées par `MapGridPainter` au resolver smart-tile ;
- filtrer les instructions d’ombres statiques et projetées par intersection avec leurs bounds géométriques exactes ;
- conserver le painter standard comme contrôle ;
- couvrir les viewports invalides/hors map, les bords, l’animation, l’ordre des couches et les éléments tournés ;
- documenter le profil 128²→1 024² et la décision Go/No-Go dans l’Evidence Pack du lot.

## Plan TDD

1. Ajouter des tests qui exigent un viewport explicite pour les builders d’ombres et prouvent qu’une ombre intersectante reste visible même si son ancre est hors viewport, tandis qu’une ombre sans intersection est exclue.
2. Ajouter une observation déterministe au snapshot de culling du painter et un test qui compare 128² à 1 024² à viewport constant pour les smart tiles et les ombres.
3. Exécuter les tests ciblés et conserver la preuve rouge avant toute modification de production.
4. Introduire un type de bounds pixel pur Dart partagé par les deux builders d’ombres, puis filtrer après calcul de la géométrie exacte.
5. Passer les bornes visibles aux deux passes smart-tile et les bounds pixel aux deux builders d’ombres.
6. Rerun les tests ciblés, le profil reproductible, les tests de non-régression demandés et `flutter analyze`.
7. Produire `reports/performance/perf_rm_07b_canvas_visible_projections.md`, auditer le diff, puis créer un commit dédié au lot.

## Parité et non-objectifs

- PokeMap MCP : N/A attendu, car le lot ne change aucune sémantique auteur, commande, donnée projet, validation, import/export ou résultat visuel ; il réduit uniquement le travail hors viewport.
- Aucun changement de schéma, JSON, design system, `RepaintBoundary` généralisé ou halo arbitraire.
- `map_core` reste inchangé sauf si les tests révèlent un défaut du resolver borné existant.

## Validation prévue

```bash
cd packages/map_core && dart test test/smart_tiles/smart_tile_layer_visual_resolver_test.dart && dart analyze
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart test/application/shadow/editor_projected_building_shadow_preview_test.dart test/map_grid_painter_test.dart test/ui/world_map/world_map_large_map_performance_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/editor_shell_page_smoke_test.dart test/ui/world_map/world_map_rebuild_isolation_test.dart test/map_grid_painter_test.dart test/ui/world_map/world_map_large_map_performance_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test && flutter analyze
```
