# NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0 — Evidence Pack

## 1. Gate 0 Complet
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

## 2. Liste des Fichiers Modifiés / Créés
- [cinematic_actor_sprite_preview_renderer.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart)
- [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart)
- [cinematic_builder_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart)
- [cinematic_actor_sprite_preview_renderer_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart)
- [actor_sprite_test_sheet.png](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/fixtures/cinematics/actor_sprite_test_sheet.png)
- [ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png)

## 3. GREEN Test Output (Unitaire / Widget)
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
00:00 +0: Cinematic Actor Display Preview Renderer Tests does not import runtime or Flame
00:00 +1: Cinematic Actor Display Preview Renderer Tests does not add playback
00:00 +2: Cinematic Actor Display Preview Renderer Tests renders resolved actor sprite in cinematic preview when image is available
00:00 +3: Cinematic Actor Display Preview Renderer Tests keeps placeholder fallback when actor image is unavailable
00:00 +4: Cinematic Actor Display Preview Renderer Tests keeps placeholder fallback for missing character
00:00 +5: Cinematic Actor Display Preview Renderer Tests anchors actor sprite bottom center on actor tile
00:00 +6: Cinematic Actor Display Preview Renderer Tests keeps actor sprite aligned after scene pan and zoom
00:00 +7: Cinematic Actor Display Preview Renderer Tests renders recognizable non flat actor sprite from character sprite sheet fixture
00:00 +8: Cinematic Actor Display Preview Renderer Tests crops actor sprite from non zero source rect
00:00 +9: Cinematic Actor Display Preview Renderer Tests falls back to placeholder when source rect is outside atlas
WARNING: Actor "Professor" (id: actor_prof) has a sprite source rect out of bounds. Source rect: x=1600, y=1600, width=16, height=16. Tileset image size: 256x256.
00:00 +10: Cinematic Actor Display Preview Renderer Tests falls back to placeholder when tileset image is unavailable
00:00 +11: Cinematic Actor Display Preview Renderer Tests does not render a flat debug rectangle for sprite ready actor
00:00 +12: Cinematic Actor Display Preview Renderer Tests keeps actor label visible with real sprite
00:00 +13: Cinematic Actor Display Preview Renderer Tests keeps direction hint visible with real sprite
00:00 +14: Cinematic Actor Display Preview Renderer Tests anchors real sprite bottom center
00:00 +15: Cinematic Actor Display Preview Renderer Tests keeps real sprite aligned after pan and zoom
00:00 +16: Cinematic Actor Display Preview Renderer Tests keeps foreground above real sprite in hybrid composition
00:00 +17: Cinematic Actor Display Preview Renderer Tests keeps Path Studio water visible with real sprite actor
00:00 +18: Cinematic Actor Display Preview Renderer Tests does not read or decode image in build or paint
00:00 +19: Cinematic Actor Display Preview Renderer Tests does not import runtime or Flame
00:00 +20: Cinematic Actor Display Preview Renderer Tests does not add playback
00:00 +21: All tests passed!
```

## 4. Analyse et Guardrails
L'exécution de `flutter test test/design_system_guardrail_test.dart` a confirmé qu'aucun literal de couleur unie n'a été introduit dans les fichiers de production `lib/`.
La couleur d'erreur d'out-of-bounds est correctement propagée du context via `context.pokeMapColors.error`.

## 5. Visual Gate V1-99-bis
La capture d'écran montrant le rendu correct de Timi dimensionné en 32x32px et exempt de distorsions de "totem" ou "bloc unitaire" a été actualisée sous :
[ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_bis_cinematic_actor_display_sprite_renderer_v1.png).
