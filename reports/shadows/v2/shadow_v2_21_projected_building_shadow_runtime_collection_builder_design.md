# ShadowV2-21 — Projected Building Shadow Runtime Collection Builder Design Gate

## 1. Résumé exécutif

ShadowV2-21 conçoit le futur builder qui transformera des données authorées :

```text
ProjectManifest + MapData + placements
```

en :

```text
ShadowRuntimeInstructionCollection contenant des instructions ShadowV2
```

Aucun code n’a été modifié. Aucun runtime, renderer, `MapLayersComponent`, modèle persistant, diagnostic, codec, adapter V2-20, fichier Selbrume, screenshot, baseline, generated file ou commit n’a été créé/modifié.

Décisions principales :

```text
builder location : map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
inputs : ProjectManifest + MapData
output : ShadowRuntimeInstructionCollection
traversal : même ordre MapData.placedElements, filtré par TileLayer visible/opacity > 0
missing preset : skip, pas de throw
diagnostics usage : le builder n’appelle pas diagnoseProjectedBuildingShadows
metrics : réutiliser la formule V1 source.width/source.height * cell size
render integration : hors scope V2-22
```

## 2. Objectif du lot

Concevoir précisément le traversal futur :

```text
manifest + mapData
-> placements visibles
-> ProjectElementEntry
-> ProjectElementProjectedBuildingShadowConfig
-> ProjectBuildingShadowPreset
-> StaticShadowVisualMetrics
-> ProjectedBuildingShadowGeometry
-> ShadowRuntimeRenderInstruction
-> ShadowRuntimeInstructionCollection
```

Le lot prépare ShadowV2-22, sans implémenter ce builder.

## 3. Rappel ShadowV2-20

ShadowV2-20 a créé l’adapter borné :

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
)
```

Mapping validé :

```text
shape = ShadowRuntimeShapeKind.projectedPolygon
renderPass = ShadowRenderPass.groundStatic
points préservés
opacity préservée
colorHexRgb préservé
```

V2-21 doit concevoir le builder qui produira les `ProjectedBuildingShadowGeometry`, puis appellera cet adapter.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
Aucune ligne.
```

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

```text
Ce lot est design-only.
Il respecte le design gate.
Aucune implémentation n’est prévue.
```

## 6. Fichiers audités

Briques V2 :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_element.dart
```

Pipeline runtime V1 :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

Map data / rendering context :

```text
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```

Tests existants utiles :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
packages/map_runtime/test/map_layers_component_placed_element_render_test.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Rapports récents :

```text
reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md
reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

## 7. Audit runtime V1 collection builder

Le builder V1 est séparé en deux niveaux :

```text
runtime_static_placed_element_shadow_sources.dart
  RuntimeMapBundle -> RuntimeStaticPlacedElementShadowSource[]

runtime_static_placed_element_shadow_collection.dart
  catalog + sources -> ShadowRuntimeInstructionCollection
```

Preuves ciblées :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:8:List<RuntimeStaticPlacedElementShadowSource>
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:9:    buildRuntimeStaticPlacedElementShadowSources({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:15:  final visibleTileLayerById = <String, TileLayer>{
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:16:    for (final layer in bundle.map.layers.whereType<TileLayer>())
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:17:      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:20:      visibleTileLayerById.isEmpty ||
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:22:    return const <RuntimeStaticPlacedElementShadowSource>[];
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:25:  final sources = <RuntimeStaticPlacedElementShadowSource>[];
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:29:    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:48:      RuntimeStaticPlacedElementShadowSource(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:53:        metrics: StaticPlacedElementShadowRuntimeMetrics(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:62:  return List<RuntimeStaticPlacedElementShadowSource>.unmodifiable(sources);
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:66:    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:69:  return buildRuntimeStaticPlacedElementShadowCollection(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:71:    sources: buildRuntimeStaticPlacedElementShadowSources(bundle: bundle),
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:6:final class RuntimeStaticPlacedElementShadowSource {
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:13:    this.isVisible = true,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:23:  final StaticPlacedElementShadowRuntimeMetrics metrics;
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:24:  final bool isVisible;
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:49:    buildRuntimeStaticPlacedElementShadowCollection({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:51:  required Iterable<RuntimeStaticPlacedElementShadowSource> sources,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:53:  final inputs = <StaticPlacedElementShadowRuntimeInput>[];
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:55:    if (!source.isVisible) {
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:68:      StaticPlacedElementShadowRuntimeInput(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:79:    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
```

Conclusion :

```text
V1 prouve le pattern utile : source extraction séparée du resolver, filtrage par TileLayer visible, collection générique en sortie.
V2 doit s’en inspirer sans importer la logique V1 de projection/family/genericProjection.
```

## 8. Audit RuntimeMapBundle / map data

`RuntimeMapBundle` contient déjà `ProjectManifest` + `MapData`, plus des getters `cellWidth` et `cellHeight`.

Preuves :

```text
packages/map_runtime/lib/src/application/runtime_map_bundle.dart:3:class RuntimeMapBundle {
packages/map_runtime/lib/src/application/runtime_map_bundle.dart:4:  RuntimeMapBundle({
packages/map_runtime/lib/src/application/runtime_map_bundle.dart:11:  final ProjectManifest manifest;
packages/map_runtime/lib/src/application/runtime_map_bundle.dart:12:  final MapData map;
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:31:Future<ProjectManifest> loadProjectManifestFromFile(String manifestPath) async {
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:68:Future<MapData> loadMapDataFromFile(
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:99:Future<RuntimeMapBundle> loadRuntimeMapBundle({
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:124:  return RuntimeMapBundle(
```

`MapData` contient `layers` et `placedElements`.

```text
packages/map_core/lib/src/models/map_data.dart:21:class MapData with _$MapData {
packages/map_core/lib/src/models/map_data.dart:29:    @Default([]) List<MapLayer> layers,
packages/map_core/lib/src/models/map_data.dart:30:    @Default([]) List<MapPlacedElement> placedElements,
packages/map_core/lib/src/models/map_data.dart:99:class MapPlacedElement with _$MapPlacedElement {
packages/map_core/lib/src/models/map_data.dart:101:  const factory MapPlacedElement({
packages/map_core/lib/src/models/map_data.dart:103:    required String layerId,
packages/map_core/lib/src/models/map_data.dart:104:    required String elementId,
packages/map_core/lib/src/models/map_data.dart:105:    required GridPos pos,
packages/map_core/lib/src/models/map_data.dart:107:    @Default(1.0) double opacity,
```

`MapLayer.tile` expose visibilité et opacité.

```text
packages/map_core/lib/src/models/map_layer.dart:20:  const factory MapLayer.tile({
packages/map_core/lib/src/models/map_layer.dart:24:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:25:    @Default(1.0) double opacity,
```

## 9. Audit metrics calculation

V1 calcule les métriques depuis la position du placement, la taille de cellule runtime, et la source de la première frame de l’élément.

Preuves :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:33:    if (element == null || element.frames.isEmpty) {
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:36:    final frame = element.frames.first;
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:37:    final source = frame.source;
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:53:        metrics: StaticPlacedElementShadowRuntimeMetrics(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:54:          worldLeft: placed.pos.x * cellWidth,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:55:          worldTop: placed.pos.y * cellHeight,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:56:          visualWidth: source.width * cellWidth,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:57:          visualHeight: source.height * cellHeight,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:295:StaticShadowVisualMetrics _visualMetricsFromRuntimeMetrics(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:298:  return StaticShadowVisualMetrics(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:299:    left: metrics.worldLeft,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:300:    top: metrics.worldTop,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:301:    visualWidth: metrics.visualWidth,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:302:    visualHeight: metrics.visualHeight,
```

La géométrie V2 attend déjà `StaticShadowVisualMetrics`.

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:63:ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:66:  required StaticShadowVisualMetrics metrics,
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:82:      metrics.visualWidth * config.anchor.xRatio +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:85:      metrics.visualHeight * config.anchor.yRatio +
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:88:  final length = metrics.visualHeight * preset.shape.lengthRatio;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:89:  final nearHalfWidth = metrics.visualWidth * preset.shape.nearWidthRatio / 2;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:90:  final farHalfWidth = metrics.visualWidth * preset.shape.farWidthRatio / 2;
```

Décision :

```text
V2-22 doit réutiliser la même stratégie de métriques que V1 :
left = placed.pos.x * cellWidth
top = placed.pos.y * cellHeight
visualWidth = primaryFrame.source.width * cellWidth
visualHeight = primaryFrame.source.height * cellHeight
```

## 10. Audit ShadowRuntimeInstructionCollection

`ShadowRuntimeInstructionCollection` est générique, immutable, et groupe déjà les instructions par render pass.

Preuves :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:47:final class ShadowRuntimeInstructionCollection {
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:48:  ShadowRuntimeInstructionCollection({
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:49:    Iterable<ShadowRuntimeRenderInstruction> instructions = const [],
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:54:  )   : instructions = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:57:        groundStatic = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:60:                instruction.renderPass == ShadowRenderPass.groundStatic,
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:63:        actorContact = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:66:                instruction.renderPass == ShadowRenderPass.actorContact,
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:70:  final List<ShadowRuntimeRenderInstruction> instructions;
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:71:  final List<ShadowRuntimeRenderInstruction> groundStatic;
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:72:  final List<ShadowRuntimeRenderInstruction> actorContact;
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:110:ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:128:  return ShadowRuntimeInstructionCollection(instructions: retained);
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart:4:ShadowRuntimeInstructionCollection mergeShadowRuntimeInstructionCollections(
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart:7:  final instructions = <ShadowRuntimeRenderInstruction>[];
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart:11:  return ShadowRuntimeInstructionCollection(instructions: instructions);
```

Conclusion :

```text
V2 n’a pas besoin d’un wrapper collection dédié en V0.
```

## 11. Décision builder location

Options comparées :

```text
Option A — builder dédié dans map_runtime/lib/src/shadow
Option B — intégrer à runtime_static_placed_element_shadow_collection.dart
Option C — modifier MapLayersComponent directement
```

Décision :

```text
Option A.
```

Fichier futur :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
```

Justification :

```text
- garde V2 séparée de V1 generic/static/contact ledge ;
- évite de polluer le renderer ;
- testable sans Flame ;
- limite les risques de réintroduire genericProjection ;
- respecte la responsabilité du package map_runtime.
```

Pas de modification de `MapLayersComponent` en V2-22.

## 12. Décision builder inputs

Options comparées :

```text
Option A — RuntimeMapBundle
Option B — ProjectManifest + MapData
Option C — sources préconstruites
```

Décision :

```text
Option B pour V2-22 :
buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

Justification :

```text
- plus pur que RuntimeMapBundle ;
- plus simple à tester ;
- ne dépend pas de projectRootDirectory ni des chemins de tilesets ;
- la taille cellule est dérivable depuis manifest.settings ;
- un wrapper RuntimeMapBundle pourra être ajouté plus tard si nécessaire.
```

Wrapper éventuel futur :

```dart
ShadowRuntimeInstructionCollection
    buildRuntimeProjectedBuildingShadowCollectionForBundle({
  required RuntimeMapBundle bundle,
}) {
  return buildRuntimeProjectedBuildingShadowCollection(
    manifest: bundle.manifest,
    mapData: bundle.map,
  );
}
```

Ce wrapper ne doit pas être obligatoire en V2-22.

## 13. Décision builder output

Options comparées :

```text
Option A — List<ShadowRuntimeRenderInstruction>
Option B — ShadowRuntimeInstructionCollection
Option C — nouveau RuntimeProjectedBuildingShadowCollection
```

Décision :

```text
Option B : ShadowRuntimeInstructionCollection.
```

Justification :

```text
- collection déjà générique ;
- immutable ;
- groupe déjà groundStatic / actorContact ;
- compatible avec le renderer futur ;
- compatible avec mergeShadowRuntimeInstructionCollections ;
- évite un type V2 sans responsabilité nouvelle.
```

## 14. Traversal proposé

Pseudo-code canonique pour ShadowV2-22 :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in mapData.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty ||
      visibleTileLayerById.isEmpty ||
      mapData.placedElements.isEmpty ||
      manifest.projectedBuildingShadowCatalog.isEmpty) {
    return ShadowRuntimeInstructionCollection();
  }

  final cellWidth =
      manifest.settings.tileWidth * manifest.settings.displayScale;
  final cellHeight =
      manifest.settings.tileHeight * manifest.settings.displayScale;
  final instructions = <ShadowRuntimeRenderInstruction>[];

  for (final placed in mapData.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    if (placed.opacity <= 0) {
      continue;
    }

    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }

    final config = element.projectedBuildingShadow;
    if (config == null || !config.enabled) {
      continue;
    }

    final preset =
        manifest.projectedBuildingShadowCatalog.presetById(config.presetId);
    if (preset == null) {
      continue;
    }

    final frame = element.frames.first;
    final source = frame.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }

    final geometry = resolveProjectedBuildingShadowGeometry(
      config: config,
      preset: preset,
      metrics: StaticShadowVisualMetrics(
        left: placed.pos.x * cellWidth,
        top: placed.pos.y * cellHeight,
        visualWidth: source.width * cellWidth,
        visualHeight: source.height * cellHeight,
      ),
    );
    if (geometry == null) {
      continue;
    }

    instructions.add(createProjectedBuildingShadowRuntimeInstruction(geometry));
  }

  return ShadowRuntimeInstructionCollection(instructions: instructions);
}
```

Décisions de traversal :

```text
- parcourir mapData.placedElements dans l’ordre source ;
- considérer uniquement les placements rattachés à un TileLayer visible et opacity > 0 ;
- skip si placed.opacity <= 0 ;
- retrouver l’élément via placed.elementId.trim() ;
- skip si element absent ;
- skip si element.frames est vide ;
- lire element.projectedBuildingShadow ;
- skip si projectedBuildingShadow == null ;
- skip si config.enabled == false ;
- lookup preset via manifest.projectedBuildingShadowCatalog.presetById(config.presetId) ;
- skip si preset absent ;
- utiliser element.frames.first en V0 pour les métriques, comme V1 source builder ;
- skip si source.width/source.height <= 0 ;
- appeler resolveProjectedBuildingShadowGeometry ;
- skip si la géométrie retourne null ;
- appeler createProjectedBuildingShadowRuntimeInstruction ;
- retourner ShadowRuntimeInstructionCollection.
```

Ordre stable :

```text
instructions dans l’ordre de mapData.placedElements après filtrage.
```

## 15. Missing preset behavior

Décision :

```text
Si presetId est manquant :
- le builder skip l’instruction ;
- il ne throw pas ;
- il ne crée aucun fallback ;
- il ne revient jamais vers genericProjection.
```

Justification :

```text
diagnoseProjectedBuildingShadows(manifest) signale déjà missingPreset en error.
Le runtime ne doit pas rendre le chargement fragile pour une dette authoring V2.
```

## 16. Diagnostics usage

Options comparées :

```text
Option A — builder n’appelle pas diagnostics
Option B — builder appelle diagnostics et filtre les errors
```

Décision :

```text
Option A.
```

Le builder V2-22 ne doit pas appeler :

```dart
diagnoseProjectedBuildingShadows(manifest)
```

Justification :

```text
- diagnostics = authoring / QA ;
- builder runtime = conversion sûre de données déjà présentes ;
- évite double travail ;
- évite de coupler le runtime aux messages de diagnostic ;
- missing preset est traité localement par skip.
```

## 17. Metrics strategy

Décision :

```text
Réutiliser la stratégie V1 sans extraire de helper commun en V2-22.
```

Formule :

```text
cellWidth = manifest.settings.tileWidth * manifest.settings.displayScale
cellHeight = manifest.settings.tileHeight * manifest.settings.displayScale

left = placed.pos.x * cellWidth
top = placed.pos.y * cellHeight
visualWidth = element.frames.first.source.width * cellWidth
visualHeight = element.frames.first.source.height * cellHeight
```

Pourquoi pas de helper commun maintenant :

```text
- extraire un helper modifierait V1 ;
- le lot V2-22 doit rester V2-only ;
- le code dupliqué sera petit et mécaniquement identique ;
- un helper partagé pourra venir si V1/V2 collection builders convergent.
```

Note sur `placed.opacity` :

```text
V2-22 doit skipper opacity <= 0.
Il ne doit pas multiplier geometry.opacity par placed.opacity en V0.
```

Raison :

```text
le renderer des placed elements applique l’opacité layer via Paint,
mais le builder d’ombres V1 ne transmet pas layer/placement opacity à l’instruction.
Pour V2-22, le preset reste source unique de l’apparence ShadowV2.
```

## 18. Render pass / ordering

Le builder produit indirectement :

```text
ShadowRenderPass.groundStatic
```

car V2-20 force ce render pass dans l’adapter.

Décision de lot :

```text
V2-22 crée une collection testée mais non branchée à MapLayersComponent.
V2-23 sera le design gate de render integration.
```

Ordre futur visé :

```text
terrain / paths / surfaces
-> groundStatic shadows V1 + V2
-> placed element sprites
-> actors
-> actor contact shadows selon système existant
-> overlays / debug / HUD
```

Le branchement réel et le merge V1/V2 restent hors scope V2-22.

## 19. Relation V1/V2

Décision :

```text
Le builder V2 ne lit pas :
- element.shadow
- MapPlacedElementShadowOverride
- StaticShadowFamily
- ProjectShadowCatalog
- genericProjection
```

V1 + V2 coexistence :

```text
autorisée au runtime builder ;
diagnostiquée côté ShadowV2-16 par v1AndV2Coexistence warning ;
pas bloquante pour produire l’instruction V2 si la config V2 est valide.
```

Anti-régression :

```text
V2-22 doit inclure un audit/test source qui vérifie l’absence de genericProjection et d’accès element.shadow.
```

## 20. Tests à prévoir pour ShadowV2-22

Créer :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Tests exacts :

```text
1. No projected shadows
   Manifest avec catalogue vide, éléments sans config V2.
   Attendu : ShadowRuntimeInstructionCollection vide.

2. Single valid projected shadow
   Manifest avec preset A, élément avec config enabled true preset A,
   placement visible sur TileLayer visible.
   Attendu : 1 instruction, shape projectedPolygon, renderPass groundStatic,
   points attendus via la formule V2.

3. Disabled config skipped
   Config enabled false.
   Attendu : 0 instruction.

4. Missing preset skipped
   Config enabled true preset missing.
   Attendu : 0 instruction, pas de throw.

5. Invisible layer skipped
   TileLayer isVisible false.
   Attendu : 0 instruction.

6. Layer opacity zero skipped
   TileLayer opacity 0.
   Attendu : 0 instruction.

7. Placement opacity zero skipped
   MapPlacedElement opacity 0.
   Attendu : 0 instruction.

8. Placement missing element skipped
   Placement référence elementId absent.
   Attendu : 0 instruction, pas de throw.

9. Empty element frames skipped
   ProjectElementEntry frames vide si constructible dans le test,
   ou documenter si le modèle/validator l’interdit.
   Attendu : 0 instruction, pas de throw.

10. Invalid source dimensions skipped
    Frame source width/height <= 0 si constructible.
    Attendu : 0 instruction, pas de throw.

11. Order stable
    Plusieurs placements valides.
    Attendu : instructions dans l’ordre de mapData.placedElements après filtrage.

12. Metrics parity with V1
    tileWidth 16, tileHeight 16, displayScale 2,
    placement pos (1, 2), source 2x3.
    Attendu : metrics équivalentes à left 32, top 64, width 64, height 96,
    vérifiées via points attendus.

13. No V1 dependency
    Audit source :
    - ne mentionne pas genericProjection ;
    - ne mentionne pas ProjectShadowCatalog ;
    - ne lit pas element.shadow ;
    - ne lit pas placed.shadowOverride ;
    - n’importe pas static_shadow_family_projection.
```

Commandes attendues pour V2-22 :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart test test/shadow_v2
cd packages/map_runtime && flutter analyze lib/src/shadow/runtime_projected_building_shadow_collection.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
```

## 21. Fichiers proposés pour ShadowV2-22

Créer :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
reports/shadows/v2/shadow_v2_22_projected_building_shadow_runtime_collection_builder.md
```

Ne pas créer en V2-22 :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_sources.dart
```

Raison :

```text
Le builder peut rester lisible dans un seul fichier V0.
Séparer sources/collection maintenant ajouterait un type public ou quasi-public sans besoin immédiat.
```

Fichiers interdits au prochain lot :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_core/**
packages/map_editor/**
examples/**
Selbrume project/map files
screenshots/baselines
```

## 22. Roadmap après ShadowV2-21

Suite recommandée :

```text
ShadowV2-22 — Runtime Collection Builder V0
ShadowV2-23 — Runtime Render Integration Design Gate
ShadowV2-24 — Runtime Render Integration V0
ShadowV2-25 — One Building Visual Fixture / Screenshot Gate Design
ShadowV2-26 — One Building Visual POC
ShadowV2-27 — Editor Preview Design Gate
```

## 23. Commandes lancées

Commandes demandées :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "buildRuntimeStaticPlacedElementShadowSources|buildRuntimeStaticPlacedElementShadowCollection|RuntimeStaticPlacedElementShadow|StaticPlacedElementShadow|staticPlaced|shadow source|MapPlacedElement|TileLayer|opacity|visible" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "class RuntimeMapBundle|RuntimeMapBundle\\(|loadRuntimeMapBundle|loadProjectManifestFromFile|loadMapDataFromFile|ProjectManifest|MapData" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "StaticShadowVisualMetrics|visualWidth|visualHeight|worldLeft|worldTop|displayScale|tileWidth|tileHeight|sourceRect|frame" packages/map_runtime/lib/src packages/map_core/lib/src packages/map_runtime/test packages/map_core/test
rg -n "ShadowRuntimeInstructionCollection|ShadowRuntimeRenderInstruction|renderCollectionPass|groundStatic|actorContact|collection" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "ProjectedBuildingShadowGeometry|resolveProjectedBuildingShadowGeometry|createProjectedBuildingShadowRuntimeInstruction|projectedBuildingShadow|projectedBuildingShadowCatalog|diagnoseProjectedBuildingShadows" packages/map_core/lib/src packages/map_runtime/lib/src packages/map_core/test packages/map_runtime/test reports/shadows/v2
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Commandes focalisées utilisées pour reproduire les preuves ci-dessus :

```bash
rg -n "buildRuntimeStaticPlacedElementShadowSources|buildRuntimeStaticPlacedElementShadowCollection|RuntimeStaticPlacedElementShadow|StaticPlacedElementShadow|MapPlacedElement|TileLayer|opacity|visible|isVisible" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
rg -n "class RuntimeMapBundle|RuntimeMapBundle\\(|loadRuntimeMapBundle|loadProjectManifestFromFile|loadMapDataFromFile|ProjectManifest|MapData" packages/map_runtime/lib/src/application/runtime_map_bundle.dart packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
rg -n "StaticShadowVisualMetrics|StaticPlacedElementShadowRuntimeMetrics|visualWidth|visualHeight|worldLeft|worldTop|displayScale|tileWidth|tileHeight|sourceRect|frame" packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
rg -n "ShadowRuntimeInstructionCollection|ShadowRuntimeRenderInstruction|renderCollectionPass|groundStatic|actorContact|collection" packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
rg -n "ProjectedBuildingShadowGeometry|resolveProjectedBuildingShadowGeometry|createProjectedBuildingShadowRuntimeInstruction|projectedBuildingShadow|projectedBuildingShadowCatalog|diagnoseProjectedBuildingShadows" packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

## 24. Résultats

Résultats essentiels :

```text
- V1 source builder filtre TileLayer visible et opacity > 0.
- V1 source builder calcule worldLeft/worldTop/visualWidth/visualHeight depuis placed.pos et source.width/source.height.
- RuntimeMapBundle contient manifest + map mais le builder V2 peut accepter ProjectManifest + MapData.
- ShadowRuntimeInstructionCollection est générique et suffisante pour V2.
- ProjectBuildingShadowPresetCatalog expose presetById exact/case-sensitive.
- V2 geometry et V2 adapter existent déjà et sont appelables depuis map_runtime via map_core.
```

## 25. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
Aucune ligne.
```

## 26. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
Aucune ligne.
```

## 27. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
Aucune ligne.
```

## 28. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/v2/shadow_v2_21_projected_building_shadow_runtime_collection_builder_design.md
```

## 29. Risques / réserves

`MapLayersComponent` rend les placed elements par `TileLayer`, et V1 shadow source builder suit la même convention. V2-22 doit donc reprendre ce comportement pour rester compatible, même si un futur nettoyage pourrait clarifier la relation avec `ObjectLayer`.

La stratégie de métriques utilise `element.frames.first`, comme V1. Cela ignore l’animation au moment runtime. C’est acceptable en V0 car les grandes ombres projetées sont authorées pour bâtiments statiques ; une future preview/editor pourra exposer explicitement le choix de frame si nécessaire.

`placed.opacity` est traité comme skip si `<= 0`, mais ne multiplie pas l’opacité de l’ombre. C’est cohérent avec un preset authoré et évite d’inventer un blending policy en runtime.

## 30. Auto-critique

La décision de ne pas créer `runtime_projected_building_shadow_sources.dart` en V2-22 est volontairement conservatrice. Si le test file devient lourd, un split sources/collection pourra être introduit plus tard avec un design explicite.

Le builder `ProjectManifest + MapData` est plus pur que `RuntimeMapBundle`, mais le runtime host aura probablement besoin d’un wrapper bundle ensuite. Ce wrapper doit rester hors scope V2-22 pour garder le prochain diff petit.

## 31. Regard critique sur le prompt

Le prompt est précis et maintient très bien la séparation entre builder, renderer, MapLayersComponent et screenshots.

Point de vigilance : les commandes `rg` larges incluent des termes comme `opacity`, `frame` et `MapData` sur de très grands fichiers runtime, ce qui produit beaucoup de bruit non décisionnel. Pour les prochains lots, cibler directement `packages/map_runtime/lib/src/shadow`, `packages/map_runtime/lib/src/application`, `packages/map_core/lib/src/models/map_data.dart` et les tests shadow rendrait l’Evidence Pack plus net.

## 32. Prompt proposé pour ShadowV2-22

````md
# ShadowV2-22 — Projected Building Shadow Runtime Collection Builder V0

Tu travailles dans le repo local :

```text
/Users/karim/Project/pokemonProject
```

## Contrat

Implémenter uniquement le builder runtime ShadowV2 :

```text
ProjectManifest + MapData -> ShadowRuntimeInstructionCollection
```

Ne pas modifier le renderer.
Ne pas modifier `MapLayersComponent`.
Ne pas modifier `ShadowRuntimeRenderer`.
Ne pas modifier `ShadowRuntimeRenderInstruction`.
Ne pas modifier `ProjectManifest`, `ProjectElementEntry`, `MapData`, les codecs, les diagnostics, la géométrie V2 ou l’adapter V2-20.
Ne pas modifier Selbrume.
Ne pas modifier screenshots/baselines.
Ne pas lancer build_runner.
Ne pas créer de generated file.
Ne pas faire de commit.

## Fichiers autorisés

Créer :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
reports/shadows/v2/shadow_v2_22_projected_building_shadow_runtime_collection_builder.md
```

Ne pas modifier `map_runtime.dart` sauf convention explicitement nécessaire. Par défaut, ne pas exporter publiquement.

## API attendue

Créer :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

## Comportement attendu

Le builder doit :

- indexer `manifest.elements` par id ;
- indexer les `TileLayer` visibles avec `isVisible == true` et `opacity > 0` ;
- parcourir `mapData.placedElements` dans l’ordre source ;
- ignorer les placements dont `layerId.trim()` ne correspond pas à un TileLayer visible ;
- ignorer les placements avec `opacity <= 0` ;
- ignorer les placements dont `elementId.trim()` ne correspond à aucun élément ;
- ignorer les éléments sans frames ;
- ignorer les éléments sans `projectedBuildingShadow` ;
- ignorer les configs `enabled == false` ;
- lookup le preset via `manifest.projectedBuildingShadowCatalog.presetById(config.presetId)` ;
- ignorer les presets manquants sans throw ;
- ignorer les sources de frame avec width/height <= 0 ;
- calculer `StaticShadowVisualMetrics` avec :
  - `left = placed.pos.x * cellWidth`
  - `top = placed.pos.y * cellHeight`
  - `visualWidth = frame.source.width * cellWidth`
  - `visualHeight = frame.source.height * cellHeight`
  - `cellWidth = manifest.settings.tileWidth * manifest.settings.displayScale`
  - `cellHeight = manifest.settings.tileHeight * manifest.settings.displayScale`
- appeler `resolveProjectedBuildingShadowGeometry`;
- ignorer une geometry null ;
- appeler `createProjectedBuildingShadowRuntimeInstruction`;
- retourner `ShadowRuntimeInstructionCollection`.

Le builder ne doit pas :

- appeler `diagnoseProjectedBuildingShadows`;
- lire `element.shadow`;
- lire `placed.shadowOverride`;
- lire `ProjectShadowCatalog`;
- appeler V1 generic/static projection ;
- utiliser Flame, Flutter, Canvas, Paint ou dart:ui.

## Tests requis

Créer `packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart`.

Tests :

1. no projected shadows -> collection vide ;
2. single valid projected shadow -> 1 instruction projectedPolygon groundStatic points attendus ;
3. disabled config skipped ;
4. missing preset skipped sans throw ;
5. invisible layer skipped ;
6. layer opacity zero skipped ;
7. placement opacity zero skipped ;
8. placement missing element skipped sans throw ;
9. empty frames skipped si constructible ;
10. invalid source dimensions skipped si constructible ;
11. ordre stable selon `mapData.placedElements` ;
12. metrics parity avec formule V1 ;
13. audit source anti-V1 : pas de `genericProjection`, pas de `ProjectShadowCatalog`, pas de `element.shadow`, pas de `shadowOverride`, pas de `static_shadow_family_projection`.

## Commandes à lancer

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "buildRuntimeProjectedBuildingShadowCollection|runtime_projected_building_shadow|ProjectedBuildingShadowGeometry|createProjectedBuildingShadowRuntimeInstruction|resolveProjectedBuildingShadowGeometry" packages/map_runtime/lib/src packages/map_runtime/test packages/map_core/lib/src
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_collection_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart test test/shadow_v2
cd packages/map_runtime && flutter analyze lib/src/shadow/runtime_projected_building_shadow_collection.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## Rapport attendu

Créer :

```text
reports/shadows/v2/shadow_v2_22_projected_building_shadow_runtime_collection_builder.md
```

Inclure :

- résumé exécutif ;
- fichiers créés/modifiés ;
- API créée ;
- traversal implémenté ;
- skip rules ;
- missing preset behavior ;
- diagnostics non appelés ;
- relation V1/V2 ;
- tests ;
- analyze ;
- audit anti-dérive ;
- git diff/status ;
- prochain lot recommandé.
````
