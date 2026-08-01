# PERF-RM-04 — Plan d'implémentation collision gameplay en couches

**Scope :** séparer collision statique et occupancy dynamique ; représenter uniquement les pixels de masques par chunks bitset. Aucune règle métier, dépendance Flutter/Flame ou migration JSON.

## Audit initial

- `_buildPixelCollisionCache` alloue `mapWidth * tileWidth * mapHeight * tileHeight` booléens même sans masque.
- La bitmap fusionne collision statique et entités ; `withEntityPosition` et les changements de visibilité la reconstruisent entièrement.
- Les caches cellule tuiles/éléments et la map d'entités bloquantes existent déjà séparément.
- Les tests couvrent masque prioritaire, cellules legacy, rotations, visibilité PNJ, mouvement et reachability.

## Étapes test-first

- [ ] Créer `gameplay_world_state_collision_storage_characterization_test.dart` : grande map 256² sans masque, zéro chunk pixel, token statique partagé après move, collision cellule/dynamique identique, bounds.
- [ ] Étendre `gameplay_world_state_entity_move_test.dart` pour départ/arrivée et partage statique.
- [ ] Exécuter les tests et conserver RED sur les diagnostics/stockage absents.
- [ ] Créer `src/collision/world_collision_storage.dart` : cellules statiques immuables + chunks 32×32 packés alloués uniquement lors d'un bit masque solide.
- [ ] Construire le stockage une fois depuis layers/cellules/masques ; conserver les entités dans `_blockingEntityByPos` et les interroger dynamiquement lors des tests pixel.
- [ ] Faire partager le stockage dans `withPlayer`, visibilité, world rules et `withEntityPosition`; supprimer les rebuilds monde pixel.
- [ ] Préserver rotation/crop/hors-bounds des masques avec `QuarterTurnPixelTransform` et tests existants.
- [ ] Créer `benchmark/world_collision_scaling.dart` avec CLI validée, warmups/samples, tailles, move p50/p95/p99, compteurs chunks et JSON.
- [ ] Mesurer 32/64/128/256 et 512 isolé, puis relancer suite gameplay, runtime bridges, smokes et analyzers.

## Non-objectifs et risques

- Pas de changement de reachability : elle continue de consommer `GameplayWorldState`.
- Pas de compression des caches cellule dans ce lot ; ils sont O(nombre de cellules), pas O(nombre de pixels monde).
- Un masque dense peut allouer tous les chunks qu'il touche, mais jamais une bitmap monde en leur absence.

## Preuves attendues

- Aucun chunk pixel sans masque, stockage statique identique après déplacement.
- Move 256² p95 sous 5 ms AOT sur la machine de preuve ; RSS historique non requalifiée sans mesure fraîche comparable.
- Parité terrain, mask, legacy cells, entités, interaction, warp et reachability.

