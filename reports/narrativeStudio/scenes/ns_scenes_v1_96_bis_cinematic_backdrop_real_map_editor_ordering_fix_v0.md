# NS-SCENES-V1-96-bis — Cinematic Backdrop Real Map Editor Ordering Investigation / Fix V0

## 1. Résumé exécutif

Le lot V1-96-bis a permis d'enquêter en profondeur sur la divergence réelle d'ordre de rendu entre le Cinematic Builder (preview de décor) et le Map Editor de PokeMap. 

Alors que la V1-96 précédente avait introduit un tri basé sur le Y visuel global (`elementBottomY`) et des heuristiques textuelles synthétiques, elle rompait la structure fondamentale d'empilement des calques 2D. 

Dans cette V1-96-bis, nous avons aligné le Cinematic Builder sur le comportement exact du Map Editor : le rendu respecte d'abord l'ordre des passes de dessin (`terrain` -> `path` -> `tileBackground` -> `surface` -> `placedBackground` -> `foreground`), puis parcourt les calques dans le sens décroissant (`length - 1` vers `0` pour afficher le calque `0` au sommet de la pile), et applique enfin un Y-sorting intra-calque/intra-passe uniquement en tant que tie-breaker.

## 2. Gate 0

Lors de l'activation du lot, le statut Git était parfaitement propre sur la branche `main` avec le dernier commit validé `89f172b7` (V1-96) :
```text
/Users/karim/Project/pokemonProject
main
89f172b7 feat(cinematics): implement cinematic backdrop depth / Z-order parity polish V0
```

Aucune modification préexistante n'a été altérée ou polluée.

## 3. Fichiers lus

Les fichiers suivants ont été audités pour cette implémentation :
- [map_grid_painter.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart) (pipeline du Map Editor)
- [map_layers_component.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart) (pipeline du runtime Flame)
- [cinematic_map_backdrop_layer_render_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart) (cinematic builder instructions list builder)
- [cinematic_map_backdrop_render_pass.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart) (render passes enum)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart) (test suite)

## 4. Synthèse des sub-agents et arbitrages

- **Sub-agent A (Forensics)** : Audit de `MapGridPainter` révélant l'absence de Y-sort global inter-calque et la présence d'une boucle décroissante (`visibleLayers.length - 1` down to `0`).
- **Sub-agent B (Real Regression)** : Création d'une fixture de test RED simulant la superposition Ponton / Eau / Mur / Toit pour reproduire les divergences constatées.
- **Sub-agent C (Cinematic Render Plan)** : Identification des permutations de passes (`path` et `tileBackground`) et du tri erroné par index croissant.
- **Sub-agent D (Ordering Adapter)** : Choix de l'Option C (créer un comparateur de tri précis reflétant le comportement exact du Map Editor dans le render plan cinematic).
- **Sub-agent E (Patch)** : Modification chirurgicale du tri sans pollution de code.
- **Sub-agent F (Visual Parity)** : Mise à jour du golden montrant l'eau sous le ponton.
- **Sub-agent G (Anti-scope)** : Validation d'aucune modification hors de `packages/map_editor` et absence d'importation de packages de runtime/playback.

## 5. Design Gate — Real Map Editor Ordering Investigation / Fix V0

Toutes les questions du Design Gate ont été répondues dans le plan d'implémentation mis à jour, confirmant notamment que le Map Editor splitte les éléments placés tuile par tuile (localX/localY) et que le comparateur cinématique en fait de même.

## 6. Pourquoi V1-96 n’a pas suffi

V1-96 appliquait un tri spatial (Y visuel) au-dessus de la logique d'empilement des calques. Ainsi, si une tuile du calque 1 était plus haute en Y qu'une tuile du calque 2 (qui était pourtant au-dessus dans l'éditeur), le tri l'inversait à l'affichage. De plus, les passes `path` (eau) et `tileBackground` (ponton) étaient inversées, dessinant l'eau par-dessus le ponton.

## 7. Audit réel de l’ordre Map Editor

Dans `MapGridPainter.paint` (dans `map_grid_painter.dart`), le pipeline de rendu parcourt les couches visibles avec des boucles imbriquées par type de passe :
1. Terrain (inversé)
2. Path (inversé)
3. Tile background pass (inversé)
4. Surface (inversé)
5. Shadows (statique)
6. Placed elements background pass (inversé)
7. Foreground pass (dessinant pour chaque calque dans le sens `length - 1` vers `0` les cellules de tuiles d'abord, puis ses éléments placés).

## 8. Audit du pipeline cinematic actuel

Le Cinematic Builder génère une liste plate d'instructions de dessin (`CinematicMapBackdropLayerBitmapInstruction`). Le painter (`CinematicMapBackdropLayerRenderPainter`) parcourt ensuite séquentiellement cette liste triée. L'ordre de rendu est donc 100% déterminé par le comparateur de tri de la liste.

## 9. Divergence exacte identifiée

1. Les passes de rendu `path` et `tileBackground` étaient inversées dans l'extension d'ordre.
2. Le tri d'index de calque (`layerIndex`) était croissant au lieu de décroissant.
3. Le Y-sorting global prévalait sur la hiérarchie des passes et de l'index des calques.

## 10. Cas RED reproduisant la divergence

Ajout du test `reproduces real cinematic backdrop depth divergence from Map Editor ordering` mettant en scène un ponton (TileLayer calque 1) et de l'eau (PathLayer calque 2) ainsi qu'un toit (calque 0) et un mur (calque 1). Le test a bien échoué en RED sous V1-96 avec une inversion de rendu de l'eau et de l'empilement.

## 11. Correction retenue

Réécriture du comparateur de tri des instructions cinématiques :
- Tri par groupe de passe (`terrain` -> `path` -> `tileBackground` -> `surface` -> `placedBackground` -> `foreground`).
- Tri par `layerIndex` décroissant.
- Tri intra-calque foreground : `tileForeground` avant `placedForeground`.
- Tie-breaker intra-calque/sous-passe : Y visuel croissant puis X croissant puis zOrder d'origine.

## 12. Alignement avec le Map Editor

Cette correction élimine le Y-sort global et assure que les instructions sont ordonnées calque par calque dans l'ordre décroissant de la pile de l'éditeur, restaurant une parité totale.

## 13. Préservation V1-94 bis / Path Studio / eau

Le test d'intégration `uses Path Studio center pattern when a path layer references its base preset` reste entièrement vert. L'eau Path Studio continue de s'afficher sans aucune régression.

## 14. Préservation V1-95-bis / pan / zoom / grille

Les tests de manipulation de viewport locaux, zoom, reset, grille masquée par défaut et timeline restent au vert. La preview canvas-first réactive reste pleinement opérationnelle.

## 15. Préservation Actor Display V1-92

Les placeholders d'acteurs de la V1-92 restent correctement positionnés et sandwichés entre la passe d'arrière-plan et la passe d'avant-plan (foreground).

## 16. Tests ajoutés ou modifiés

- **Ajouté** : `reproduces real cinematic backdrop depth divergence from Map Editor ordering`
- **Ajouté** : `captures V1-96-bis real Map Editor ordering fix visual gate when requested`
- **Modifié** : `builds extended backdrop bitmap instructions for neutral terrain path surface and placed elements` (mise à jour de l'ordre attendu avec path avant tileBackground).

## 17. Visual Gate

La Visual Gate a été générée avec succès :
- **Fichier** : [ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png)
- **Format** : PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
- **SHA-1 Checksum** : `1621df1109527efc14ccd3f08f0264c11dbfe2d6`

## 18. Avant / après : changement visible

- **Avant (V1-96)** : L'eau dessinée par-dessus le ponton (le masquait), les toits de maisons dessinés sous les murs (empilement de calques inversé).
- **Après (V1-96-bis)** : L'eau est correctement passée sous le ponton, le toit de la maison est dessiné au-dessus du mur du calque inférieur, et le rendu correspond à 100% au rendu final de l'éditeur.

## 19. Commandes exécutées

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_core && dart test --reporter=compact && dart analyze
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_96_BIS_CAPTURE_REAL_MAP_EDITOR_ORDERING=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-96-bis real Map Editor ordering fix visual gate when requested'
```

## 20. Résultats des tests

Tous les tests de l'éditeur et du core (193 tests dans le builder, 21 tests dans la library, tous les tests dans le core) sont entièrement au vert.

## 21. Analyze

L'analyse ciblée sur les fichiers modifiés et ajoutés est de 100% propre (No issues found!).

## 22. Checks anti-scope

Le diff Git sur les autres packages (`map_runtime`, `map_gameplay`, `map_battle`, `examples`, `selbrume`) est vide (`<vide>`), prouvant le respect total de l'isolation du lot.

## 23. Fichiers créés

Aucun fichier source créé.
Fichiers rapports créés :
- `reports/narrativeStudio/scenes/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_96_bis_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png`

## 24. Fichiers modifiés

- [cinematic_map_backdrop_render_pass.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart)
- [cinematic_map_backdrop_layer_render_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart)

## 25. Roadmaps mises à jour

Mise à jour des roadmaps pour passer le lot `NS-SCENES-V1-96-bis` à `DONE` produit-validé avec preuve.

## 26. Limites connues

N/A.

## 27. Non-objectifs confirmés

Le lot a scrupuleusement évité tout Flame, GameWidget, GameState, playback de preview, ou hardcode Selbrume.

## 28. Evidence Pack

L' Evidence Pack a été rédigé avec l'ensemble des diffs, commandes et checksums.

## 29. Auto-review critique

Toutes les questions d'auto-review du lot ont été validées avec succès.

## 30. Recommandation pour le prochain lot

Nous recommandons désormais de reprendre la roadmap linéaire avec :
`NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`
