# NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0

## 1. Résumé exécutif
Ce lot réalise la vérification de fidélité visuelle et le polissage du rendu des sprites d'acteurs de cinématiques. Il prouve le rendu des sprites d'acteurs en utilisant une feuille de sprite de pixel-art réelle et non plate (la fixture `actor_sprite_test_sheet.png`, représentant Timi), éliminant tout bloc de couleur unie ou "totem". Il met également en œuvre des vérifications de limites strictes et une gestion des diagnostics avec fallback en cas de découpe hors-limites, en évitant les crashs graphiques et les hardcodes de fichiers externes, tout en préservant le respect total du design system (pas de couleurs codées en dur).

## 2. Gate 0
```text
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/test/fixtures/cinematics/actor_sprite_test_sheet.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png
?? reports/narrativeStudio/scenes/ns_scenes_v1_99_bis_cinematic_actor_sprite_real_asset_fidelity_visual_gate_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_99_bis_evidence_pack.md
```

## 3. Fichiers modifiés / créés
- [cinematic_actor_sprite_preview_renderer.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart)
- [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart)
- [cinematic_builder_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart)
- [cinematic_actor_sprite_preview_renderer_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart)
- [actor_sprite_test_sheet.png](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/fixtures/cinematics/actor_sprite_test_sheet.png)
- [ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png)

## 4. Synthèse des arbitrages et réalisations
1. **Fidélité visuelle prouvée** : Utilisation d'une fixture locale réelle et non plate `actor_sprite_test_sheet.png` (contenant le personnage Timi) pour le test de rendu. Un test de parité extrait les couleurs du canvas pour prouver qu'il s'agit d'un pixel-art réel et non d'un bloc de couleur unie (23 couleurs uniques détectées).
2. **Aucun hardcode de chemin externe** : L'accès aux fichiers se fait localement dans le dossier des tests (`test/fixtures/cinematics/`), éliminant tout chemin absolu externe.
3. **Respect strict du design system** : Aucune couleur unie codée en dur (comme `Colors.red` ou `Color(0xFFFF0000)`) n'a été insérée dans `lib/`. La couleur de fallback pour la découpe hors-limites est injectée via le constructeur en utilisant `context.pokeMapColors.error`.
4. **Vérifications de limites robustes** : Le résolveur d'overlay et le peintre effectuent tous deux des vérifications de limites du rectangle source par rapport à l'image. Si le rectangle de découpe sort de l'atlas, un diagnostic `debugPrint` explicite est produit, et le painter dessine une boîte barrée avec la couleur d'erreur au lieu de crasher.

## 5. Scope réalisé
- Intégration de la fixture réelle Timi dans les tests.
- Remplacement du fallback de crop invalide par une boîte d'erreur croisée.
- Élimination complète de tous les literals de couleur du code de production `lib/`.
- Mise à jour du test de capture de golden file Visual Gate V1-99-bis.

## 6. Prochain lot recommandé
`NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract` pour commencer le cadrage de la persistance temporelle et des contrôles de playback interactifs.
