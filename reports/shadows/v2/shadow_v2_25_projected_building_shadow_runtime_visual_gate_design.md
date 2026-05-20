# ShadowV2-25 — Projected Building Shadow Runtime Visual Gate Design

## 1. Résumé exécutif

ShadowV2-25 est un design gate strictement documentaire. Aucun code runtime, aucun test, aucune fixture, aucun screenshot et aucune baseline n'ont été créés.

Décision recommandée pour ShadowV2-26 : créer une micro preuve visuelle ciblée, en mémoire, sans golden file et sans Selbrume. Le test doit construire une collection V2 via le host/provider déjà raccordé par `PlayableMapGame`, puis rendre cette collection avec `ShadowRuntimeRenderer.renderCollectionPass(...)` sur un `Canvas` contrôlé et vérifier quelques pixels.

Option recommandée : Option C — test renderer + provider combiné sans `GameWidget`.

Pourquoi :
- le renderer couvre déjà `projectedPolygon` au niveau pixel, donc il ne faut pas le modifier ;
- le Lot 24 prouve déjà que V2 atteint le provider du `MapLayersComponent` background, donc le prochain trou à fermer est la preuve pixel de bout en bout minimal ;
- une golden Flame complète serait trop fragile pour une première preuve V2 ;
- Selbrume reste trop massif et trop dépendant de données artistiques réelles pour ce jalon.

## 2. Objectif du lot

Le Lot 24 a branché les instructions ShadowV2 dans le runtime via `PlayableMapGame`. Le Lot 25 devait décider comment prouver visuellement, au lot suivant, qu'une instruction V2 `projectedPolygon` est réellement dessinée.

Le périmètre de ce lot est donc uniquement :
- auditer les tests visuels et screenshot existants ;
- auditer les tests renderer ;
- auditer les tests host/runtime existants ;
- auditer le pipeline `PlayableMapGame` / `MapLayersComponent` / `ShadowRuntimeRenderer` ;
- comparer les options ;
- cadrer précisément ShadowV2-26.

## 3. Rappel ShadowV2-22 à ShadowV2-24

ShadowV2-22 a créé :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

Ce builder produit des instructions `ShadowRuntimeShapeKind.projectedPolygon` dans le pass `ShadowRenderPass.groundStatic`.

ShadowV2-23 a validé le raccord runtime sans toucher au renderer ni à `MapLayersComponent` :
- intégration via `PlayableMapGame` ;
- merge V2 avant V1 static placed ;
- renderer existant réutilisé ;
- screenshot repoussé à un gate visuel dédié.

ShadowV2-24 a branché V2 dans `PlayableMapGame` :
- collection V2 privée par map ;
- refresh au montage / update bundle ;
- cleanup au démontage ;
- merge V2 -> V1 -> actorContact ;
- external `shadowCollectionProvider` prioritaire ;
- `enableStaticPlacedElementShadows=false` désactive V2 en V0 ;
- aucun changement `MapLayersComponent`, `ShadowRuntimeRenderer`, `map_core`, Selbrume ou screenshot.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Interprétation : le worktree initial était propre avant ShadowV2-25.

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision : le lot est design-only. Le design gate est précisément l'objet de ShadowV2-25, donc aucune implémentation n'est autorisée dans ce lot.

Note Flame MCP : `flame_docs` a été interrogé avec :
- `FlameGame GameWidget testing render to image golden screenshot Canvas`
- `GameWidget test widget FlameGame render priority`
- `components render priority`

Résultat : aucune documentation n'a été trouvée pour ces requêtes. La décision s'appuie donc sur les patterns locaux déjà testés dans `map_runtime`.

## 6. Fichiers audités

Fichiers et zones audités :
- `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart`
- `packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart`
- `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart`
- `packages/map_runtime/tool/shadow/README.md`
- `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`
- `packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart`
- `packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart`

Inventaire des fichiers du lot :
- Créé par ShadowV2-25 : `reports/shadows/v2/shadow_v2_25_projected_building_shadow_runtime_visual_gate_design.md`
- Modifié par ShadowV2-25 : Aucun
- Supprimé par ShadowV2-25 : Aucun
- Generated touché : Aucun
- Screenshot / baseline créé : Aucun
- Fichier Selbrume touché : Aucun

Le rapport courant est le contenu complet du seul fichier créé par ce lot.

## 7. Audit des tests visuels / golden / screenshot existants

Commande large obligatoire :

```bash
rg -n "golden|matchesGoldenFile|screenshot|baseline|capture|repaintBoundary|toImage|GameWidget|FlameGame|pumpWidget|render" packages/map_runtime/test packages/map_runtime/tool packages/map_runtime/lib
```

Résultat quantifié :

```text
945
```

Commande complémentaire conservant la liste des fichiers concernés :

```bash
rg -l "golden|matchesGoldenFile|screenshot|baseline|capture|repaintBoundary|toImage|GameWidget|FlameGame|pumpWidget|render" packages/map_runtime/test packages/map_runtime/tool packages/map_runtime/lib
```

Sortie :

```text
packages/map_runtime/tool/render_lot_4e_battle_visuals_test.dart
packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart
packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/tool/phase_a_battle_coverage.dart
packages/map_runtime/lib/src/presentation/flame/battle_fx_sprite_sheet_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
packages/map_runtime/tool/phase_b_scaffold_pack_coverage.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/tool/shadow/README.md
packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart
packages/map_runtime/lib/src/presentation/flame/battle_move_visual_catalog.dart
packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_debug_panel_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_fx_layer_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_resolver.dart
packages/map_runtime/test/battle_move_visual_catalog_test.dart
packages/map_runtime/test/battle_pokemon_sprite_resolver_test.dart
packages/map_runtime/lib/src/presentation/flame/battle_rmxp_animation_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_sdk_particle_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
packages/map_runtime/test/map_layers_component_render_pass_test.dart
packages/map_runtime/test/battle_mobile_command_overlay_test.dart
packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart
packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
packages/map_runtime/lib/src/presentation/flame/battle_fx_sprite_component.dart
packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart
packages/map_runtime/lib/src/presentation/flutter/battle_command_overlay_snapshot.dart
packages/map_runtime/lib/src/presentation/flame/battle_rmxp_hue_filter.dart
packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart
packages/map_runtime/test/battle_bag_menu_model_test.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/test/battle_command_menu_component_test.dart
packages/map_runtime/test/battle_scene_combatant_component_animation_test.dart
packages/map_runtime/test/path_pattern_runtime_render_resolution_test.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
packages/map_runtime/test/battle_overlay_component_test.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/test/battle_scene_layout_test.dart
packages/map_runtime/test/battle_rmxp_animation_component_test.dart
packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
packages/map_runtime/test/runtime_tileset_image_test.dart
packages/map_runtime/test/file_game_save_repository_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_runtime/test/path_pattern_runtime_reload_regression_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_runtime/test/battle_sdk_particle_component_test.dart
packages/map_runtime/test/battle_fx_layer_component_test.dart
packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart
packages/map_runtime/test/map_layers_component_placed_element_render_test.dart
packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart
packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart
packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
packages/map_runtime/test/surface/surface_runtime_test_support.dart
packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
packages/map_runtime/test/surface/surface_runtime_golden_slice_test.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_runtime/test/battle_fx_bundle_cache_test.dart
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
packages/map_runtime/test/surface/surface_runtime_ordering_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
packages/map_runtime/test/shadow/runtime_shadow_render_order_contract_test.dart
packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart
packages/map_runtime/test/battle_fx_sprite_component_test.dart
packages/map_runtime/test/surface/surface_runtime_missing_assets_test.dart
packages/map_runtime/test/surface/surface_runtime_renderer_test.dart
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart
packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart
packages/map_runtime/test/playable_map_game_input_test.dart
```

Commande ciblée sur les fichiers décisionnels :

```bash
rg -n "screenshot|baseline|capture|golden" packages/map_runtime/tool/shadow/README.md packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Extrait utile de la sortie :

```text
packages/map_runtime/tool/shadow/README.md:6:package test suites or CI by accident. It is a reproducible screenshot capture
packages/map_runtime/tool/shadow/README.md:7:tool, not a golden comparison test.
packages/map_runtime/tool/shadow/README.md:9:## Run capture only
packages/map_runtime/tool/shadow/README.md:21:## Run capture + baseline comparison
packages/map_runtime/tool/shadow/README.md:23:Shadow baseline comparison is optional and manually invoked. In V0 it is
packages/map_runtime/tool/shadow/README.md:86:The baseline V1 lives under:
packages/map_runtime/tool/shadow/README.md:89:reports/shadows/baselines/selbrume_shadow_v1/
packages/map_runtime/tool/shadow/README.md:126:V0 deliberately does not implement automatic baseline updates. To update a
packages/map_runtime/tool/shadow/README.md:133:This V0 harness captures the current runtime output and asserts the expected
packages/map_runtime/tool/shadow/README.md:142:It does not compare pixels against a golden baseline, and it should not block
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart:30:  test('selbrume shadow screenshot harness', () async {
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart:184:    expect(captures, hasLength(10));
```

Conclusion :
- il existe un harness screenshot Selbrume, mais il est explicitement manuel et V1-oriented ;
- il existe des tests image/pixel en mémoire dans `map_runtime/test` ;
- aucun signal ne justifie une baseline massive au premier POC visuel V2.

## 8. Audit des tests renderer existants

Commande :

```bash
rg -n "projectedPolygon|drawPath|drawOval|image|pixel|transparent|opacity|renderCollectionPass" packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
```

Sortie :

```text
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:19:      final image = await renderSurfaceTestComponent(component);
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:21:      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:61:      final image = await renderSurfaceTestComponent(component);
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:63:      expect(await pixelAt(image, 16, 16), rgba(0, 255, 0, 255));
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:191:      final image = await renderSurfaceTestComponent(component);
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:193:      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:105:    test('draws projectedPolygon with visible interior and transparent outside',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:119:      expect(await _alphaAt(image, 10, 8), greaterThan(0));
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:120:      expect(await _alphaAt(image, 1, 1), 0);
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:123:    test('keeps projectedPolygon opacity zero transparent inside', () async {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:139:    test('draws projectedPolygon with stronger near alpha than far alpha',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:160:      final nearAlpha = await _alphaAt(image, 18, 12);
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:161:      final farAlpha = await _alphaAt(image, 20, 32);
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:167:    test('projectedPolygon fallback still draws non four point polygons',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:217:    test('draws projectedPolygon and ellipse in input order', () async {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:243:  group('ShadowRuntimeRenderer.renderCollectionPass', () {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:304:    test('filters projectedPolygon instructions by render pass', () async {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:397:  const ShadowRuntimeRenderer().renderCollectionPass(canvas, collection, pass);
```

Constats :
- `ShadowRuntimeRenderer` sait déjà dessiner `projectedPolygon`.
- Le renderer a déjà une preuve pixel :
  - intérieur visible ;
  - extérieur transparent ;
  - opacité zéro transparente ;
  - gradient near/far ;
  - filtrage par render pass ;
  - ordre d'input.
- ShadowV2-26 ne doit pas retester le renderer isolé comme si cette surface n'existait pas. Il doit prouver que la collection V2 produite par le host arrive dans une image en mémoire.

## 9. Audit des tests host runtime existants

Commande :

```bash
rg -n "runtime_projected_building_shadow_host_integration|runtime_static_placed_element_shadow_host_integration|shadowCollectionProvider|MapLayersComponent|PlayableMapGame" packages/map_runtime/test/shadow packages/map_runtime/lib/src/presentation/flame
```

Sortie pertinente :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:19:        'PlayableMapGame provides projected building shadows to the background layer',
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:33:      final collection = background.shadowCollectionProvider!()!;
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:35:      expect(background.shadowCollectionProvider, isNotNull);
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:36:      expect(foreground.shadowCollectionProvider, isNull);
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:79:        'PlayableMapGame merges V2 projected shadows with V1 static placed shadows',
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:99:        'PlayableMapGame merges projected building shadows before V1 static shadows',
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:120:        'PlayableMapGame keeps external shadow provider priority over internal projected shadows',
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:152:        'PlayableMapGame disables projected building ground shadows when static placed shadows are disabled',
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:348:MapLayersComponent _backgroundLayer(PlayableMapGame game) {
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart:44:    test('static shadow is visible in the background render when configured',
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart:59:      final image = await _render(background, width: 160, height: 160);
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart:451:Future<ui.Image> _render(
packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart:48:      final image = await _render(layer);
packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart:156:Future<ui.Image> _render(MapLayersComponent component) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1664:  ShadowRuntimeInstructionCollectionProvider? _shadowCollectionProviderForMap(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6570:    final backgroundLayers = MapLayersComponent(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6575:      shadowCollectionProvider: _shadowCollectionProviderForMap(bundle.map.id),
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:331:    final collection = shadowCollectionProvider?.call();
```

Ce que Lot 24 prouve déjà :
- `PlayableMapGame` produit une collection V2 pour le background layer ;
- aucune config V2 => pas d'instruction V2 ;
- preset manquant => skip silencieux ;
- V1 + V2 coexistent ;
- V2 est avant V1 dans `groundStatic` ;
- external provider reste prioritaire ;
- le flag static désactive V2 en V0 ;
- `RuntimeMapGame` reste passif.

Ce que Lot 24 ne prouve pas :
- un pixel issu d'une ombre V2 dessinée dans une image ;
- l'interaction finale entre une collection V2 produite par le host et le `ShadowRuntimeRenderer`.

Point important : le test V1 host contient déjà un pattern de rendu en mémoire de `MapLayersComponent` via `ui.PictureRecorder`, donc ShadowV2-26 peut réutiliser cette stratégie sans golden file.

## 10. Audit du pipeline visuel PlayableMapGame / MapLayersComponent

Extrait audité de `MapLayersComponent` :

```dart
  void _paintShadows(Canvas canvas) {
    final collection = shadowCollectionProvider?.call();
    if (collection == null || collection.isEmpty) {
      return;
    }
    shadowRenderer.renderCollectionPass(
      canvas,
      collection,
      ShadowRenderPass.groundStatic,
    );
    shadowRenderer.renderCollectionPass(
      canvas,
      collection,
      ShadowRenderPass.actorContact,
    );
  }
```

Extrait audité de `ShadowRuntimeRenderer` :

```dart
  void renderInstruction(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    _validateHardEdge(instruction);
    switch (instruction.shape) {
      case ShadowRuntimeShapeKind.contactBlob:
      case ShadowRuntimeShapeKind.ellipse:
        _renderOval(canvas, instruction);
      case ShadowRuntimeShapeKind.projectedPolygon:
        _renderProjectedPolygon(canvas, instruction);
    }
  }

  void renderCollectionPass(
    ui.Canvas canvas,
    ShadowRuntimeInstructionCollection collection,
    ShadowRenderPass pass,
  ) {
    final instructions = switch (pass) {
      ShadowRenderPass.groundStatic => collection.groundStatic,
      ShadowRenderPass.actorContact => collection.actorContact,
    };
    renderInstructions(canvas, instructions);
  }
```

Extrait audité de `PlayableMapGame` :

```dart
  ShadowRuntimeInstructionCollectionProvider? _shadowCollectionProviderForMap(
    String mapId,
  ) {
    final externalProvider = shadowCollectionProvider;
    if (externalProvider != null) {
      return externalProvider;
    }
    if (!enableActorContactShadows && !enableStaticPlacedElementShadows) {
      return null;
    }
    return () => _provideShadowCollectionForMap(mapId);
  }

  ShadowRuntimeInstructionCollection? _provideShadowCollectionForMap(
    String mapId,
  ) {
    final collections = <ShadowRuntimeInstructionCollection>[];
    if (enableStaticPlacedElementShadows) {
      final projectedBuildingCollection =
          _projectedBuildingShadowCollectionByMapId[mapId];
      if (projectedBuildingCollection != null &&
          projectedBuildingCollection.isNotEmpty) {
        collections.add(projectedBuildingCollection);
      }
      final staticCollection = _staticShadowCollectionByMapId[mapId];
      if (staticCollection != null && staticCollection.isNotEmpty) {
        collections.add(staticCollection);
      }
    }
    if (enableActorContactShadows && mapId == _activeMapId) {
      final actorCollection = _actorShadowCollectionController.provide();
      if (actorCollection != null && actorCollection.isNotEmpty) {
        collections.add(actorCollection);
      }
    }
    if (collections.isEmpty) {
      return null;
    }
    return mergeShadowRuntimeInstructionCollections(collections);
  }
```

Constat :
- la collection finale passe déjà par `MapLayersComponent.shadowCollectionProvider` ;
- `MapLayersComponent` appelle déjà le renderer existant ;
- le renderer supporte déjà `projectedPolygon` ;
- aucun fichier runtime ne doit changer pour le POC visuel V2.

## 11. Options étudiées

### Option A — Golden screenshot Flame complet

Principe : monter un `PlayableMapGame` minimal dans un `GameWidget`, capturer l'image, comparer à une golden.

Avantages :
- preuve réaliste très proche du rendu final ;
- couvre potentiellement `GameWidget`, Flame lifecycle et composition visuelle complète.

Risques :
- fragile en CI et selon plateformes ;
- exige une baseline ;
- risque de mélanger preuve technique V2 et bruit de rendu général ;
- plus lourd que le besoin immédiat.

Décision : rejetée pour ShadowV2-26. Trop large pour la première preuve visuelle V2.

### Option B — Test image/pixel ciblé sans golden file

Principe : rendre un `PlayableMapGame` ou un `MapLayersComponent` minimal en image mémoire, puis vérifier quelques pixels.

Avantages :
- plus robuste qu'une golden ;
- peut prouver un pixel visible sans baseline ;
- pattern déjà présent dans les tests V1 host.

Risques :
- si on rend tout `MapLayersComponent`, on peut retomber sur des détails surfaces/tiles/sprites qui masquent l'ombre ;
- peut dupliquer les tests `MapLayersComponent shadow renderer integration`.

Décision : bonne option de secours, mais moins ciblée que l'option C pour ShadowV2-26.

### Option C — Test renderer + provider combiné sans GameWidget

Principe : construire un `PlayableMapGame` minimal comme dans Lot 24, récupérer la collection finale via le provider du background layer, puis appeler `ShadowRuntimeRenderer.renderCollectionPass(...)` sur un `Canvas` mémoire et vérifier les pixels.

Avantages :
- prouve que le host produit la collection V2 réelle ;
- prouve que la collection V2 réelle est dessinable par le renderer existant ;
- évite `GameWidget`, golden, screenshot, Selbrume et baseline ;
- garde le test dans `packages/map_runtime/test/shadow` ;
- ne modifie aucun runtime.

Risques :
- ne teste pas un `MapLayersComponent.render(...)` complet dans le même test ;
- dépend d'un petit helper image/pixel.

Réponse au risque : `shadow_runtime_renderer_integration_test.dart` couvre déjà le fait que `MapLayersComponent` appelle le provider et `renderCollectionPass`. Le test V2 visuel doit combler le lien manquant : collection V2 host -> renderer -> pixels.

Décision : recommandée pour ShadowV2-26.

### Option D — Micro fixture manuelle documentée uniquement

Principe : créer une micro map et vérifier humainement une capture hors tests.

Avantages :
- utile pour une validation artistique humaine ;
- simple à comprendre.

Risques :
- pas de preuve CI ;
- pas de verrouillage automatisé ;
- trop faible pour un gate technique.

Décision : rejetée pour ShadowV2-26. Peut devenir un complément manuel plus tard, mais pas la preuve principale.

### Option E — Selbrume screenshot

Principe : utiliser le harness Selbrume existant et capturer une vraie scène.

Avantages :
- scène réelle ;
- utile pour validation artistique globale future.

Risques :
- massif ;
- fragile ;
- dépend de données artistiques réelles ;
- mélange authoring Selbrume, baseline V1 et preuve technique V2 ;
- peut entraîner un festival de captures sans isoler le signal V2.

Décision : rejetée pour ShadowV2-26.

## 12. Option recommandée

Option recommandée : Option C — test renderer + provider combiné sans `GameWidget`.

Pourquoi :
- ShadowV2-24 prouve déjà le host/provider mais pas les pixels.
- `ShadowRuntimeRenderer` prouve déjà `projectedPolygon` mais pas avec une collection V2 produite par `PlayableMapGame`.
- L'option C relie ces deux preuves sans modifier le runtime.
- Elle évite Selbrume, les baselines, les screenshots disque et les golden files.
- Elle reste petite, stable, lisible et CI-friendly.

Lot 26 doit faire :
- créer un test V2 visuel ciblé ;
- construire un `PlayableMapGame` minimal avec une ombre V2 authorée ;
- récupérer la collection finale depuis le background provider ;
- rendre `collection.groundStatic` via `ShadowRuntimeRenderer.renderCollectionPass(...)` sur `ui.PictureRecorder` ;
- vérifier un pixel dans le polygone V2 avec alpha > 0 ;
- vérifier un pixel hors polygone avec alpha == 0 ;
- vérifier que la collection source contient bien une instruction `projectedPolygon` `groundStatic` avec les points attendus ;
- vérifier que V2 reste avant V1 dans la collection si coexistence testée ;
- ajouter un audit source anti-dérive dans le test ou dans le rapport.

Lot 26 ne doit pas faire :
- modifier `PlayableMapGame` ;
- modifier `MapLayersComponent` ;
- modifier `ShadowRuntimeRenderer` ;
- créer une baseline ;
- créer un screenshot ;
- toucher Selbrume ;
- modifier `map_core` ;
- créer un nouveau chemin de rendu.

## 13. Ce que le visual gate doit prouver

Obligatoire pour ShadowV2-26 :
- une instruction V2 `projectedPolygon` `groundStatic` est produite par le host runtime ;
- cette instruction vient de données V2 authorées ;
- cette instruction atteint un `Canvas` via le renderer existant ;
- un pixel intérieur au polygone V2 est non transparent ;
- un pixel extérieur est transparent ;
- couleur/opacité/polygonPoints attendus restent cohérents avec le preset ;
- aucun screenshot/baseline/Selbrume ;
- aucun diagnostic runtime ;
- aucun `genericProjection` ou auto-policy.

Peut attendre :
- full `GameWidget` screenshot ;
- comparaison golden ;
- micro fixture visuelle lancée manuellement ;
- baseline V2 ;
- validation artistique Selbrume ;
- cycle jour/nuit ;
- editor preview.

## 14. Plan précis du Lot 26

ShadowV2-26 — Projected Building Shadow Runtime Visual POC V0

Objectif :

```text
Prouver en test automatisé qu'une ombre V2 produite par PlayableMapGame
est dessinée en pixels par ShadowRuntimeRenderer existant,
sans screenshot disque et sans baseline.
```

Fichiers à créer :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
reports/shadows/v2/shadow_v2_26_projected_building_shadow_runtime_visual_poc.md
```

Fichiers à modifier :

```text
Aucun fichier de production.
```

Fichiers interdits :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/tool/**
/Users/karim/Desktop/selbrume/**
```

Test / preuve à ajouter :

```text
runtime_projected_building_shadow_visual_poc_test.dart
```

Assertions obligatoires :
- `PlayableMapGame` minimal charge une map synthétique V2 ;
- background `MapLayersComponent` possède un provider ;
- provider retourne une collection avec une instruction V2 `projectedPolygon`;
- `renderPass == ShadowRenderPass.groundStatic`;
- les points attendus sont ceux du Lot 24 : `(64,128)`, `(64,192)`, `(112,176)`, `(112,144)`;
- rendu mémoire via `ShadowRuntimeRenderer.renderCollectionPass(..., ShadowRenderPass.groundStatic)`;
- pixel intérieur au polygone V2 : alpha > 0 ;
- pixel extérieur à l'ombre : alpha == 0 ;
- en coexistence V1 + V2, collection order V2 avant V1 reste vérifié ;
- aucun diagnostic runtime ;
- aucun auto-shadow / `genericProjection`.

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart test/shadow/shadow_runtime_renderer_integration_test.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart
cd packages/map_runtime && flutter analyze test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
cd /Users/karim/Project/pokemonProject
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy|SHADOW_SCREENSHOT|baseline|matchesGoldenFile" packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :
- un seul test V2 visual POC créé ;
- aucun fichier runtime de production modifié ;
- aucun screenshot/baseline/fixture Selbrume ;
- le test ciblé passe ;
- les tests renderer/host ciblés passent ;
- analyze ciblé passe ;
- audit anti-dérive propre ou hits documentés ;
- final status limité au test V2-26 et au rapport V2-26.

## 15. Tests / assertions recommandés pour le Lot 26

Tests recommandés :

```text
runtime projected building visual POC renders host-provided V2 polygon pixels
```

Assertions :
- charge `PlayableMapGame` avec la micro bundle V2 déjà proche de celle du Lot 24 ;
- récupère le background layer ;
- récupère `background.shadowCollectionProvider!()!`;
- isole l'instruction V2 par `shape == projectedPolygon`, `colorHexRgb == '123ABC'`, `opacity == 0.18`;
- vérifie les quatre points attendus ;
- rend la collection via le renderer existant ;
- lit `ui.ImageByteFormat.rawRgba`;
- vérifie un pixel intérieur, par exemple `(80,150)` ou un point calculé explicitement comme intérieur au polygone ;
- vérifie un pixel extérieur, par exemple `(10,10)`;
- en test séparé ou sous-section, vérifie la coexistence V1+V2 en ordre de collection sans dépendre d'une couleur blendée fragile.

Tests à éviter :
- golden file ;
- `matchesGoldenFile`;
- screenshot disque ;
- Selbrume ;
- test editor ;
- test map_core ;
- test renderer direct sans provider host ;
- test `GameWidget` complet.

## 16. Fichiers explicitement interdits au Lot 26

Lot 26 ne devra pas modifier :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/tool/**
reports/shadows/baselines/**
reports/shadows/screenshots/**
/Users/karim/Desktop/selbrume/**
```

Lot 26 ne devra pas créer :

```text
*.png
*.jpg
*.jpeg
*.webp
*.golden
baseline_manifest.json
fixture Selbrume
nouveau renderer
nouveau provider public
nouveau modèle
nouveau codec
nouveau diagnostic
generated file
```

## 17. Risques / réserves

Risque 1 : l'option C ne rend pas tout `MapLayersComponent`.

Réponse : `shadow_runtime_renderer_integration_test.dart` couvre déjà que `MapLayersComponent` appelle le provider et rend les passes. Lot 26 doit rester une preuve du chaînon V2 host collection -> renderer pixels.

Risque 2 : un pixel intérieur choisi à la main peut devenir fragile si la géométrie change.

Réponse : le test doit vérifier les points attendus puis choisir un pixel clairement intérieur, loin des bords et de l'antialiasing. Le renderer utilise `isAntiAlias = false`, ce qui aide.

Risque 3 : coexistence V1+V2 par pixel peut être ambiguë à cause du blending.

Réponse : l'ordre de coexistence doit rester vérifié par collection order, comme Lot 24. La preuve pixel obligatoire doit rester centrée sur la visibilité V2.

Risque 4 : le nom `enableStaticPlacedElementShadows` pilote encore V2 en V0.

Réponse : ce comportement est déjà validé en Lot 24 et ne doit pas être re-designé dans le visual gate.

## 18. Auto-critique

Le rapport recommande une preuve volontairement intermédiaire : pas une full scene Flame, pas une golden, pas Selbrume. C'est le bon niveau pour réduire le risque technique sans ouvrir un chantier de baselines. La limite est assumée : ShadowV2-26 ne sera pas encore une validation artistique globale, mais une preuve technique que la donnée V2 authorée devient un pixel dessiné par le renderer existant.

J'ai aussi évité de recommander une modification de production pour rendre le test plus commode. Si Lot 26 se retrouve à devoir modifier `PlayableMapGame`, `MapLayersComponent` ou `ShadowRuntimeRenderer`, ce sera un signal que le plan a dépassé son périmètre.

## 19. Regard critique sur le prompt

Le prompt est bien borné : il empêche le saut prématuré vers Selbrume, les screenshots massifs et les baselines. Le point le plus délicat est la formule "visual gate" qui peut inciter à une golden complète ; l'audit montre que le repo a déjà des tests pixel en mémoire, donc la meilleure suite est plus petite qu'une capture réelle.

Le prompt a aussi raison d'exiger une recommandation unique. Sans cela, le prochain lot pourrait hésiter entre `GameWidget`, renderer direct et screenshot harness. La recommandation C donne un axe précis.

## 20. Commandes lancées

Commandes lancées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "golden|matchesGoldenFile|screenshot|baseline|capture|repaintBoundary|toImage|GameWidget|FlameGame|pumpWidget|render" packages/map_runtime/test packages/map_runtime/tool packages/map_runtime/lib
rg -n "projectedPolygon|drawPath|drawOval|image|pixel|transparent|opacity|renderCollectionPass" packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
rg -n "runtime_projected_building_shadow_host_integration|runtime_static_placed_element_shadow_host_integration|shadowCollectionProvider|MapLayersComponent|PlayableMapGame" packages/map_runtime/test/shadow packages/map_runtime/lib/src/presentation/flame
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy" packages/map_runtime/lib packages/map_core/lib
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 21. git diff --stat

Sortie initiale avant création du rapport :

```text
```

Sortie finale après création du rapport :

```text
```

Interprétation : `git diff --stat` ne liste pas les fichiers non suivis. Le seul fichier visible dans le status final est le rapport V2-25 non suivi.

## 22. git diff --name-status

Sortie initiale avant création du rapport :

```text
```

Sortie finale après création du rapport :

```text
```

Interprétation : aucun fichier suivi n'a été modifié.

## 23. git diff --check

Sortie initiale avant création du rapport :

```text
```

Sortie finale après création du rapport :

```text
```

Interprétation : aucun whitespace error détecté par `git diff --check`.

## 24. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/shadows/v2/shadow_v2_25_projected_building_shadow_runtime_visual_gate_design.md
```

Interprétation : le seul changement de ShadowV2-25 est le rapport Markdown demandé.

Vérification anti-formulations interdites du rapport :

```bash
rg -n "<regex anti-formulations interdites>" reports/shadows/v2/shadow_v2_25_projected_building_shadow_runtime_visual_gate_design.md
```

Sortie :

```text
```

Checklist finale :
- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Selbrume non modifié
- [x] Tests visuels/golden existants audités
- [x] Tests renderer existants audités
- [x] Tests host runtime existants audités
- [x] Pipeline PlayableMapGame / MapLayersComponent audité
- [x] Options comparées
- [x] Option recommandée unique
- [x] Plan ShadowV2-26 précis
- [x] Fichiers interdits au Lot 26 listés
- [x] git diff --check propre
- [x] git status final conforme
