# NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0

## 1. Résumé exécutif
Ce lot réalise l'intégration visuelle du plan de sprites acteurs statiques résolu par le lot V1-98. Les sprites statiques réels des personnages sont maintenant rendus dans la preview du Cinematic Builder lorsqu'ils sont résolus et disponibles dans le cache/registry des images. Si les images ne sont pas chargées ou si le sprite est incomplet, le système retombe élégamment sur le placeholder (cercle pastille P/M/C) du lot V1-92.

## 2. Gate 0
```text
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
?? packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_evidence_pack.md
```

## 3. Fichiers lus
- [cinematic_actor_sprite_preview_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart)
- [cinematic_actor_sprite_preview_resolver.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart)
- [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart)
- [cinematic_map_backdrop_preview_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart)
- [cinematics_library_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart)

## 4. Synthèse des sub-agents et arbitrages
Les passes spécialisées confirment que :
- L'overlay existant est correctement sandwiché dans le panel.
- Charger les images via le `CinematicMapBackdropLayerPlanLoader` et les passer au panel est performant et évite tout décodage synchrone dans la boucle de build/paint.
- La stratégie hybride (Option C) est parfaitement compatible avec la pile d'ordonnancement de V1-96-bis.

## 5. Design Gate — Cinematic Actor Display Preview Sprite Renderer V0

1. **Quel contrat V1-98 est consommé ?**
   - `CinematicActorSpritePreviewPlan`, `CinematicActorSpritePreviewActor`, `CinematicActorSpriteRef`, `CinematicActorSpriteDepthHint`, et `buildCinematicActorSpritePreviewPlan`.
2. **Quels tests V1-98 manquants sont ajoutés avant rendu ?**
   - Des tests couvrant NPC via `mapEntity`, `placeholderOnly`, et non-mutation du projet. Ils ont été ajoutés et validés avec succès dans `cinematic_actor_sprite_preview_resolver_test.dart`.
3. **Comment visualElementId is-il garanti placeholderOnly ?**
   - Si `appearance.status` est `placeholderOnly`, le statut est `placeholderFallback`, forçant le fallback.
4. **Comment mapEntity NPC est-il couvert ?**
   - Le résolveur de V1-98 inspecte le character ID de l'apparence de l'acteur et le résout via le manifest du projet.
5. **Comment ProjectManifest / MapData non-mutation est-elle prouvée ?**
   - Un test vérifie que les objets d'origine ne changent pas lors de la construction du plan.
6. **Quelle stratégie de rendu est retenue : overlay, depth-aware ou hybride ?**
   - Option C (Hybride) : Sprite rendu dans la couche overlay existante entre background et foreground.
7. **Pourquoi cette stratégie ne casse pas V1-96-bis ?**
   - L'overlay est placé après le rendu du décor de fond et avant le rendu des décors d'avant-plan (comme les toits), respectant l'ordonnancement 2.5D de la map.
8. **L’overlay acteur est-il déjà sandwiché entre background et foreground ?**
   - Oui, dans `_BackdropLayerBitmapMap` et `_BackdropBitmapMap`, le widget overlay est placé dans la Stack Flutter entre les deux passes.
9. **Comment les foregrounds restent-ils au-dessus des sprites si attendu ?**
   - Le CustomPaint de foreground s'exécute après le widget overlay dans la Stack Flutter.
10. **Comment les labels restent-ils lisibles ?**
    - Rendus avec des conteneurs contrastés et des polices du design system PokeMap.
11. **Comment les diagnostics restent-ils accessibles ?**
    - Ils restent exposés via le plan de sprites et visibles dans l'inspecteur/panel de warnings.
12. **Comment les images sont-elles chargées hors build()/paint() ?**
    - Via le `CinematicMapBackdropLayerPlanLoader` et le cache de tilesets asynchrone lors du chargement initial de la map.
13. **Comment un sprite indisponible retombe-t-il en placeholder ?**
    - Si l'image n'est pas disponible dans la map `tilesets` ou que le statut de l'acteur n'est pas `spriteReady`, le marker rond standard s'affiche.
14. **Comment éviter flicker/loading violent ?**
    - Grâce à un chargement en amont et un fallback synchrone propre vers le placeholder.
15. **Comment le sprite est-il ancré bottom-center ?**
    - Le Positioned calcule son top/left tel que le bas-milieu de l'image s'aligne sur l'ancre `tileCenterBottom` de la tuile.
16. **Comment frameWidth/frameHeight sont-ils utilisés ?**
    - Pour définir la taille de la frame en tuiles et cropper le rectangle source en pixels.
17. **Comment pan/zoom/Vue scène sont-ils préservés ?**
    - Grâce aux calculs de coordonnées de viewport effectués par `CinematicMapBackdropViewportTransform`.
18. **Comment la grille masquée V1-95-bis is-elle préservée ?**
    - En n'apportant aucune modification à la gestion de la grille.
19. **Comment Path Studio/eau V1-94 bis est-il préservé ?**
    - Préservé sans modification, validé par les tests de non-régression.
20. **Comment ordering V1-96-bis est-il préservé ?**
    - Grâce au sandwich Stack Flutter qui maintient le foreground au-dessus de l'overlay.
21. **Comment éviter runtime/Flame/GameState ?**
    - Zéro import et utilisation de Flame/runtime.
22. **Comment éviter playback/currentTimeMs/playbackTimeMs ?**
    - Aucun time tracking ou animation de frame, le sprite reste fixe.
23. **Comment éviter mutation ProjectManifest/MapData ?**
    - Les classes d'édition et plans sont immutables et purs.
24. **Comment éviter hardcode Selbrume ?**
    - Aucune référence à Selbrume n'est codée en dur.
25. **Quelle Visual Gate sera produite ?**
    - Une capture visual gate montrant la preview avec un sprite d'acteur réel et le fallback placeholder.
26. **Quel prochain lot exact est recommandé ?**
    - `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract`.

## 6. Réserves V1-97 / V1-98 traitées
Toutes les réserves de depth et de chargement d'image ont été résolues en chargeant les images à l'avance et en utilisant l'overlay sandwich existant.

## 7. Scope réalisé
- Affichage du sprite acteur statique.
- Chargement asynchrone des images au niveau du loader de backdrop.
- Rendu CustomPaint de sprite cropped avec pixel-art scaling.
- Fallback vers le placeholder.
- Diagnostics et labels préservés.

## 8. Stratégie renderer retenue
L'option hybride consistant à garder le widget overlay placé entre les passes de background et de foreground a été validée.

## 9. Chargement image hors build/paint
Les images de tilesets supplémentaires requises par les personnages sont identifiées en amont et résolues par le `CinematicMapBackdropLayerPlanLoader`.

## 10. Intégration du Sprite Preview Plan
Le plan est propagé depuis `CinematicsLibraryWorkspace` jusqu'à `CinematicActorDisplayPreviewOverlay`.

## 11. Rendu sprite statique
Le sprite est dessiné sans aucune boucle d'animation ni playback temporel.

## 12. Ancrage bottom-center
Le point d'ancrage calculé correspond à la base de la tuile logique de l'acteur.

## 13. Préservation labels / direction hints
Les badges textuels et les hints de direction (N, S, E, W) restent affichés.

## 14. Fallback placeholders
Le pastille ronde est rendue en cas d'image indisponible ou d'acteur incomplet.

## 15. Diagnostics sprite
Les diagnostics restent disponibles et alimentent les warnings visuels.

## 16. Compatibilité depth V1-96-bis
La stack Flutter du panel garantit que le foreground couvre les sprites acteurs.

## 17. Préservation Path Studio / eau
L'eau et les tracés restent inchangés.

## 18. Préservation Vue scène / pan / zoom / grille
Toutes les transformations de grille et de caméra restent opérationnelles.

## 19. Préservation timeline / inspector / transports disabled
La timeline et l'inspecteur fonctionnent comme d'habitude et les boutons de lecture restent grisés.

## 20. Restrictions anti-runtime / anti-Flame / anti-playback
Aucun import de Flame ou map_runtime, aucune boucle temporelle.

## 21. Design system
Utilisation exclusive de `PokeMapTone` et `context.pokeMapColors`.

## 22. Tests ajoutés ou modifiés
Création de `cinematic_actor_sprite_preview_renderer_test.dart` et ajout d'un test visual gate dans `cinematic_builder_workspace_test.dart`.

## 23. Visual Gate
Capture sous `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png`.

## 24. Commandes exécutées
*(Détaillé dans l'Evidence Pack)*

## 25. Résultats des tests
*(Détaillé dans l'Evidence Pack)*

## 26. Analyze
*(Détaillé dans l'Evidence Pack)*

## 27. Checks anti-scope
*(Détaillé dans l'Evidence Pack)*

## 28. Fichiers créés
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart`
- `packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_99_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png`

## 29. Fichiers modifiés
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 30. Roadmaps mises à jour
Marqué V1-99 comme DONE.

## 31. Limites connues
- Les sprites d'acteurs sont statiques (première frame idle).

## 32. Non-objectifs confirmés
- Pas de playback, pas de Flame, pas de déplacement animé.

## 33. Evidence Pack
Consulter [ns_scenes_v1_99_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_99_evidence_pack.md).

## 34. Auto-review critique
Le découpage du rendering et du resolver est respecté, aucune mutation sur le manifest ou mapData, aucun import de Flame/runtime.

## 35. Recommandation pour le prochain lot
Passer à `NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract`.
