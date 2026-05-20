# ShadowV2-23 — Projected Building Shadow Runtime Render Integration Design Gate

## 1. Résumé exécutif

ShadowV2-23 est un design gate uniquement. Aucun code runtime, renderer, test, fixture, screenshot ou fichier generated n'a été modifié.

Décision unique : le Lot 24 doit intégrer les ombres projetées V2 dans le pipeline runtime en amont du rendu, dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`, en construisant une collection V2 par map avec `buildRuntimeProjectedBuildingShadowCollection(...)`, puis en la fusionnant avec les collections shadow internes existantes via `mergeShadowRuntimeInstructionCollections(...)`.

Le renderer ne doit pas changer : `ShadowRuntimeRenderer` sait déjà rendre `ShadowRuntimeShapeKind.projectedPolygon` et sait déjà filtrer une `ShadowRuntimeInstructionCollection` par `ShadowRenderPass.groundStatic` ou `ShadowRenderPass.actorContact`. `MapLayersComponent` ne doit pas changer au Lot 24 : il reçoit déjà un `ShadowRuntimeInstructionCollectionProvider`, appelle ce provider une fois par render, puis rend les passes shadow dans l'ordre existant.

Option recommandée : **merge V2 + V1 avant rendu dans le provider interne de `PlayableMapGame`**, avec V2 dans le même pass `groundStatic`, avant les ombres statiques V1 dans la liste fusionnée pour que la grande projection authorée reste sous les ombres V1 plus locales lorsque les deux coexistent.

## 2. Objectif du lot

Le lot devait décider comment raccorder plus tard la collection produite par :

```dart
ShadowRuntimeInstructionCollection buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

au pipeline de rendu existant, sans implémenter ce raccord.

Question centrale traitée :

```text
Comment faire atteindre les instructions ShadowV2 au render path runtime
sans modifier le renderer,
sans modifier MapLayersComponent en V0,
sans diagnostics runtime,
sans genericProjection,
et sans automatisme artistique ?
```

## 3. Rappel ShadowV2-20 à ShadowV2-22

ShadowV2-20 a créé l'adapter :

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
)
```

avec :

```text
shape = ShadowRuntimeShapeKind.projectedPolygon
renderPass = ShadowRenderPass.groundStatic
points préservés
opacity préservée
colorHexRgb préservé
```

ShadowV2-21 a validé le builder runtime V2 :

```text
ProjectManifest + MapData -> ShadowRuntimeInstructionCollection
```

ShadowV2-22 a implémenté :

```dart
ShadowRuntimeInstructionCollection
    buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

Le builder V2 parcourt `mapData.placedElements`, skippe les cas invalides ou absents, résout la géométrie pure, puis appelle l'adapter V2-20. Il ne branche pas le rendu.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Interprétation : le worktree était propre au début du lot 23.

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

Décision : ce lot est lui-même le design gate demandé. Le design gate est satisfait par la production du présent rapport uniquement. Aucune compétence d'implémentation n'a été invoquée pour écrire du code, aucun fichier Dart n'a été créé ou modifié.

Note Flame : les recherches `flame_docs` suivantes ont été tentées pour vérifier les sujets d'ordre de rendu Flame :

```text
Flame render order component priority render method -> No results found
Component priority render order -> No results found
```

Les décisions s'appuient donc sur l'architecture locale déjà testée (`MapLayersComponent`, `PlayableMapGame`, contrats de render order), sans inventer d'API Flame nouvelle.

## 6. Fichiers audités

Fichiers runtime shadow :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
```

Fichiers Flame / host :

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart
```

Tests audités :

```text
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart
```

Inventaire du lot 23 :

```text
Créé :
- reports/shadows/v2/shadow_v2_23_projected_building_shadow_runtime_render_integration_design.md

Modifié :
- Aucun

Supprimé :
- Aucun

Generated :
- Aucun

Tests créés/modifiés :
- Aucun

Screenshots/baselines/Selbrume :
- Aucun
```

## 7. Audit du renderer shadow runtime

Commande obligatoire :

```bash
rg -n "class ShadowRuntimeRenderer|ShadowRuntimeRenderer|renderCollectionPass|projectedPolygon|drawPath|drawOval|ShadowRuntimeShapeKind|ShadowRenderPass|groundStatic|actorContact" packages/map_runtime/lib/src packages/map_runtime/test
```

Lignes utiles relevées :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:8:final class ShadowRuntimeRenderer {
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:17:      case ShadowRuntimeShapeKind.contactBlob:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:18:      case ShadowRuntimeShapeKind.ellipse:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:20:      case ShadowRuntimeShapeKind.projectedPolygon:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:35:    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:44:      canvas.drawPath(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:51:      canvas.drawPath(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:69:  void renderCollectionPass(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:75:      ShadowRenderPass.groundStatic => collection.groundStatic,
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:76:      ShadowRenderPass.actorContact => collection.actorContact,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:5:enum ShadowRuntimeShapeKind {
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:8:  projectedPolygon,
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:105:    test('draws projectedPolygon with visible interior and transparent outside',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:304:    test('filters projectedPolygon instructions by render pass', () async {
```

Constats :

- `ShadowRuntimeRenderer` sait déjà rendre `ShadowRuntimeShapeKind.projectedPolygon`.
- `projectedPolygon` est rendu par `drawPath`.
- Les polygones à 4 points utilisent déjà les bandes d'opacité de `createProjectedStaticShadowOpacityBands()`.
- `renderCollectionPass(...)` reçoit une `ShadowRuntimeInstructionCollection` complète, choisit `collection.groundStatic` ou `collection.actorContact`, puis appelle `renderInstructions(...)`.
- Le renderer ne trie pas les instructions : l'ordre reçu dans les listes de collection est l'ordre de dessin.
- Le renderer dépend de `dart:ui`, comme attendu pour le rendu, mais le builder V2 et l'adapter V2 n'en dépendent pas.

Décision renderer : **ne pas modifier `ShadowRuntimeRenderer` au Lot 24**.

## 8. Audit du pipeline MapLayersComponent / Flame

Commande obligatoire :

```bash
rg -n "class MapLayersComponent|MapLayersComponent|render\\(|ShadowRuntimeRenderer|renderCollectionPass|groundStatic|actorContact|surfaces|placedElements|actors|debug|occlusion" packages/map_runtime/lib/src/presentation packages/map_runtime/lib/src
```

Lignes utiles relevées :

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:35:class MapLayersComponent extends PositionComponent {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:43:    this.shadowRenderer = const ShadowRuntimeRenderer(),
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:75:  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:76:  final ShadowRuntimeRenderer shadowRenderer;
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:251:  void render(Canvas canvas) {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:335:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:338:      ShadowRenderPass.groundStatic,
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:340:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:343:      ShadowRenderPass.actorContact,
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:572:  ShadowRuntimeInstructionCollectionProvider?
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1660:  ShadowRuntimeInstructionCollectionProvider? _shadowCollectionProviderForMap(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1673:  ShadowRuntimeInstructionCollection? _provideShadowCollectionForMap(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1692:    return mergeShadowRuntimeInstructionCollections(collections);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6542:    final backgroundLayers = MapLayersComponent(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6547:      shadowCollectionProvider: _shadowCollectionProviderForMap(bundle.map.id),
```

Constats sur `MapLayersComponent.render(...)` :

```text
background pass:
terrain
paths
surfaces
_paintShadows(canvas)
tile layers + placed elements
project element entities
collision/debug overlay if enabled

foreground pass:
tile layers + placed elements
project element entities
return
```

`_paintShadows(...)` :

```text
- appelle shadowCollectionProvider une seule fois ;
- no-op si null ou collection vide ;
- rend ShadowRenderPass.groundStatic ;
- rend ShadowRenderPass.actorContact ;
- ne connaît pas V1/V2 ;
- ne trie pas ;
- ne construit pas les collections.
```

Constats sur `PlayableMapGame` :

```text
- le background MapLayersComponent reçoit _shadowCollectionProviderForMap(bundle.map.id) ;
- le foreground MapLayersComponent ne reçoit pas de shadow provider ;
- _provideShadowCollectionForMap(...) fusionne déjà les collections internes ;
- _refreshStaticPlacedElementShadowCollection(...) construit déjà la collection V1 par RuntimeMapBundle ;
- _refreshActorContactShadowCollection(...) construit la collection actorContact active ;
- RuntimeMapGame reste passif et ne construit pas de collection interne.
```

Contrat local d'ordre de rendu :

```text
RuntimeShadowRenderOrderSlot.baseTerrain
RuntimeShadowRenderOrderSlot.groundPaths
RuntimeShadowRenderOrderSlot.surfaceLayers
RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows
RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows
RuntimeShadowRenderOrderSlot.placedElementSprites
RuntimeShadowRenderOrderSlot.actorsPlayerNpc
RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches
RuntimeShadowRenderOrderSlot.debugOverlays
RuntimeShadowRenderOrderSlot.hudUi
```

Décision MapLayersComponent : **ne pas modifier `MapLayersComponent` au Lot 24**. Le composant fait déjà ce qu'il faut si son provider reçoit une collection fusionnée contenant V1 + V2.

## 9. Audit des builders V1

Commande obligatoire :

```bash
rg -n "runtime_static_placed_element_shadow|buildRuntimeStatic|StaticPlacedElementShadow|ShadowRuntimeInstructionCollection|MapPlacedElement|ProjectElementShadowConfig|element.shadow|shadowOverride" packages/map_runtime/lib/src packages/map_runtime/test
```

Lignes utiles relevées :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:8:List<RuntimeStaticPlacedElementShadowSource>
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:9:    buildRuntimeStaticPlacedElementShadowSources({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:51:        elementShadow: element.shadow,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:52:        placedOverride: placed.shadowOverride,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:65:ShadowRuntimeInstructionCollection
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:66:    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:48:ShadowRuntimeInstructionCollection
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:49:    buildRuntimeStaticPlacedElementShadowCollection({
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:78:  return ShadowRuntimeInstructionCollection(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1714:    final collection = buildRuntimeStaticPlacedElementShadowCollectionForBundle(
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart:8:  group('mergeShadowRuntimeInstructionCollections', () {
```

Constats :

- V1 construit des sources depuis `RuntimeMapBundle`, puis une `ShadowRuntimeInstructionCollection`.
- V1 lit `element.shadow` et `placed.shadowOverride`. V2 ne doit pas réutiliser ces champs.
- V1 est déjà raccordé à `PlayableMapGame` via `_refreshStaticPlacedElementShadowCollection(...)`.
- Le point de merge naturel existe déjà : `_provideShadowCollectionForMap(...)`.
- Le helper `mergeShadowRuntimeInstructionCollections(...)` existe déjà et préserve l'ordre des collections puis l'ordre des instructions.

Décision V1/V2 : **V2 doit rester dans son builder séparé et rejoindre V1 uniquement au niveau collection/provider**.

## 10. Audit du builder V2 Lot 22

Commande obligatoire :

```bash
rg -n "buildRuntimeProjectedBuildingShadowCollection|ProjectedBuildingShadow|projectedBuildingShadow|projectedBuildingShadowCatalog|createProjectedBuildingShadowRuntimeInstruction|resolveProjectedBuildingShadowGeometry" packages/map_runtime/lib/src packages/map_runtime/test packages/map_core/lib/src packages/map_core/test
```

Lignes utiles relevées :

```text
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:7:ShadowRuntimeInstructionCollection
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:8:    buildRuntimeProjectedBuildingShadowCollection({
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:42:    final config = element.projectedBuildingShadow;
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:47:    final preset = manifest.projectedBuildingShadowCatalog.presetById(
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:59:    final geometry = resolveProjectedBuildingShadowGeometry(
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart:74:      createProjectedBuildingShadowRuntimeInstruction(geometry),
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart:5:ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart:10:  group('buildRuntimeProjectedBuildingShadowCollection', () {
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart:9:  group('createProjectedBuildingShadowRuntimeInstruction', () {
```

Constats sur `runtime_projected_building_shadow_collection.dart` :

```text
- imports : package:map_core/map_core.dart + adapter/collection/instruction runtime ;
- aucune dépendance Flutter ;
- aucune dépendance Flame ;
- aucune dépendance Canvas ;
- aucun dart:ui ;
- aucun appel diagnoseProjectedBuildingShadows(...) ;
- aucun genericProjection ;
- output = ShadowRuntimeInstructionCollection ;
- toutes les instructions produites par l'adapter sont déjà projectedPolygon + groundStatic.
```

Compatibilité renderer : oui. Le builder V2 produit déjà le même type de collection que V1 et le renderer sait déjà peindre `projectedPolygon`.

## 11. Audit anti-dérive genericProjection / diagnostics

Commande obligatoire :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy" packages/map_runtime/lib packages/map_core/lib
```

Sortie :

```text
packages/map_core/lib/map_core.dart:74:export 'src/operations/static_shadow_family_projection.dart';
packages/map_core/lib/map_core.dart:78:export 'src/operations/element_auto_shadow_policy.dart';
packages/map_core/lib/src/validation/validators.dart:14:class ProjectValidator {
packages/map_core/lib/src/validation/validators.dart:1276:class MapValidator {
packages/map_core/lib/src/validation/validators.dart:1697:        ProjectValidator._validateRelativePath(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:425:        family: StaticShadowFamily.genericProjection,
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:540:    family: StaticShadowFamily.genericProjection,
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:194:ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:66:List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
packages/map_core/lib/src/operations/static_shadow_family_projection.dart:26:      StaticShadowFamily.genericProjection;
packages/map_core/lib/src/operations/static_shadow_family_projection.dart:29:StaticShadowProjectionSpec resolveStaticShadowFamilyProjectionSpec({
packages/map_core/lib/src/operations/static_shadow_family_projection.dart:35:    case StaticShadowFamily.genericProjection:
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:164:  final projectedGeometry = resolveProjectedStaticShadowGeometry(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:167:    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
packages/map_core/lib/src/operations/map_map_metadata.dart:34:  MapValidator.validate(
packages/map_core/lib/src/operations/map_entities.dart:316:/// Règles métier sur les champs typés (également utilisées par [MapValidator]).
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:42:    ProjectValidator.validate(manifest);
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:80:    MapValidator.validate(
packages/map_core/lib/src/models/shadow.dart:45:  genericProjection,
```

Interprétation :

- Les hits `genericProjection`, `static_shadow_family_projection`, `resolveProjectedStaticShadowGeometry` appartiennent au système Shadow V1 existant.
- Les hits `ProjectValidator` / `MapValidator` appartiennent au chargement/validation existant.
- Le diagnostic V2 existe dans `map_core`, mais il n'est pas appelé par le builder V2 runtime.
- Aucun hit ne justifie de faire dépendre l'intégration V2 du resolver V1, de l'auto-policy V1 ou des diagnostics authoring.

Règle pour Lot 24 : **ne pas importer ou appeler `diagnoseProjectedBuildingShadows`, `element_auto_shadow_policy`, `static_shadow_family_projection`, `resolveProjectedStaticShadowGeometry`, `ProjectValidator` ou `MapValidator` dans le raccord V2**.

## 12. Options étudiées

### Option A — Merge V1 + V2 avant rendu

Principe :

```text
collection V2 groundStatic
+ collection V1 groundStatic
+ collection actorContact
= collection finale fournie à MapLayersComponent
```

Avantages :

```text
- réutilise ShadowRuntimeInstructionCollection ;
- réutilise mergeShadowRuntimeInstructionCollections(...) ;
- réutilise ShadowRuntimeRenderer tel quel ;
- réutilise MapLayersComponent tel quel ;
- garde un seul provider par background layer ;
- rend V2 dans groundStatic comme décidé en V2-20 ;
- testable via PlayableMapGame host integration sans screenshot.
```

Risques :

```text
- il faut choisir explicitement l'ordre V2/V1 dans le merge ;
- si V1 + V2 coexistent, les deux seront visibles, conformément à la règle runtime tolérante ;
- le flag existant enableStaticPlacedElementShadows devient le master switch logique des shadows ground static authorées en V0.
```

Décision sur l'ordre dans Option A :

```text
collections = [
  projectedBuildingV2Collection,
  staticPlacedV1Collection,
  actorContactCollection,
]
```

Justification : les grandes projections V2 sont larges et authorées ; lorsqu'un élément a aussi une shadow V1, le diagnostic authoring signale le risque, mais le runtime ne bloque pas. Dessiner V2 avant V1 garde les ombres V1 locales au-dessus des grandes projections, sans changer l'ordre interne de V1 ni l'ordre source V2.

### Option B — Rendu V2 séparé avec le même renderer

Principe :

```text
renderer.renderCollectionPass(v1Collection, groundStatic)
renderer.renderCollectionPass(v2Collection, groundStatic)
```

Avantages :

```text
- séparation visuelle du code V1/V2 au point de render ;
- pas besoin de merge.
```

Risques :

```text
- impose de modifier MapLayersComponent ou son API ;
- duplique les appels renderer ;
- crée deux chemins pour un même pass groundStatic ;
- rend l'ordre V1/V2 dépendant du composant de rendu au lieu du provider ;
- augmente le blast radius du Lot 24.
```

Décision : rejetée pour V0.

### Option C — Modifier ShadowRuntimeInstructionCollection

Principe :

```text
ajouter une API merge/concat dédiée dans ShadowRuntimeInstructionCollection
```

Avantages :

```text
- pourrait rendre le merge plus découvrable.
```

Risques :

```text
- inutile : runtime_shadow_collection_merge.dart existe déjà ;
- modifie un contrat central sans nécessité ;
- augmente les tests de contrat ;
- n'améliore pas le raccord V2.
```

Décision : rejetée pour V0.

### Option D — Modifier ShadowRuntimeRenderer

Principe :

```text
le renderer devient responsable de plusieurs collections
```

Avantages :

```text
- aucun avantage nécessaire pour V2-24.
```

Risques :

```text
- mélange orchestration et rendu ;
- rend le renderer responsable d'une décision de source V1/V2 ;
- risque de casser les tests renderer existants ;
- plus large que le besoin.
```

Décision : rejetée.

### Option E — Utiliser le seam provider/merge existant dans PlayableMapGame

Principe :

```text
buildRuntimeProjectedBuildingShadowCollection(manifest: bundle.manifest, mapData: bundle.map)
-> stockage privé par map dans PlayableMapGame
-> mergeShadowRuntimeInstructionCollections([...])
-> MapLayersComponent reçoit la collection finale inchangée
```

Avantages :

```text
- plus petit point d'intégration réel ;
- respecte la séparation builder / provider / renderer ;
- évite de toucher MapLayersComponent ;
- évite de toucher ShadowRuntimeRenderer ;
- compatible maps connectées déjà chargées par PlayableMapGame ;
- testable avec les patterns existants de runtime_static_placed_element_shadow_host_integration_test.dart.
```

Risques :

```text
- ajoute un troisième type de collection interne dans PlayableMapGame ;
- nécessite de clarifier que enableStaticPlacedElementShadows contrôle aussi les ground static V2 en V0 ;
- nécessite des tests host précis pour éviter un raccord invisible.
```

Décision : retenue, comme réalisation concrète de l'Option A dans le code réel.

## 13. Option recommandée

Option recommandée : **Option E / Option A concrète : intégrer V2 dans `PlayableMapGame` via le provider/merge existant, sans toucher au renderer ni à `MapLayersComponent`.**

Point d'intégration exact :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Zone logique :

```text
_shadowCollectionProviderForMap(...)
_provideShadowCollectionForMap(...)
_refreshStaticPlacedElementShadowCollection(...)
_mountLoadedMap(...)
_loadedMapsById / _staticShadowCollectionByMapId voisinage
```

Lot 24 doit faire :

```text
1. Importer runtime_projected_building_shadow_collection.dart dans PlayableMapGame.
2. Ajouter un stockage privé par map pour la collection V2, par exemple :
   _projectedBuildingShadowCollectionByMapId.
3. Ajouter une méthode privée :
   _refreshProjectedBuildingShadowCollection(RuntimeMapBundle bundle).
4. Appeler cette méthode au montage d'une map, au même niveau que
   _refreshStaticPlacedElementShadowCollection(bundle).
5. Inclure la collection V2 dans _provideShadowCollectionForMap(mapId).
6. Fusionner les collections dans l'ordre :
   V2 projected building, V1 static placed, actorContact.
7. Garder l'external shadowCollectionProvider prioritaire.
8. Garder enableStaticPlacedElementShadows comme master switch V0 des shadows groundStatic authorées.
```

Lot 24 ne doit pas faire :

```text
- modifier ShadowRuntimeRenderer ;
- modifier ShadowRuntimeRenderInstruction ;
- modifier ShadowRuntimeInstructionCollection ;
- modifier MapLayersComponent ;
- créer un nouveau renderer ;
- créer un nouveau provider public ;
- appeler diagnoseProjectedBuildingShadows ;
- appeler genericProjection ou l'auto-policy V1 ;
- modifier map_core ;
- modifier Selbrume ;
- créer des screenshots ou baselines.
```

Pourquoi :

```text
- Le renderer supporte déjà la shape.
- MapLayersComponent supporte déjà la collection.
- PlayableMapGame possède déjà le provider interne et le merge.
- Le builder V2 retourne déjà le bon type.
- Le changement du Lot 24 peut rester limité à un fichier runtime host + un test host.
```

## 14. Ordre de rendu recommandé

Ordre réel observé dans `MapLayersComponent` background pass :

```text
terrain
paths
surface layers
shadow collection groundStatic
shadow collection actorContact
tile layers
placed elements
project element entities
collision/debug overlay if enabled
```

Ordre recommandé pour V2 :

```text
terrain/base layers
paths/surfaces
groundStatic shadows V2 puis V1
actorContact shadows selon pipeline actuel
placed sprites/elements
actors / project element entities
occlusion patches via composants séparés
debug overlays
HUD
```

Raison :

```text
- Les ombres projetées de bâtiments sont au sol.
- Elles doivent rester sous les sprites de bâtiments et sous les acteurs.
- Le pass groundStatic existe déjà pour ce rôle.
- Les actorContact shadows restent dans leur pass existant.
```

Point à ne pas changer au Lot 24 : l'ordre `groundStatic` puis `actorContact` dans `_paintShadows(...)`. Même si le nom `actorContact` semble dynamique, les tests locaux verrouillent déjà ce contrat sous les sprites/actors.

## 15. Comportement V1 + V2 recommandé

Règle confirmée :

```text
Si un élément a shadow V1 + projectedBuildingShadow V2 :
- le runtime ne bloque pas ;
- les deux peuvent produire des instructions ;
- le diagnostic authoring v1AndV2Coexistence signale le risque ;
- aucune correction automatique ;
- aucun fallback ;
- aucun genericProjection V2.
```

Comportement de rendu recommandé :

```text
- V2 produit une ou plusieurs instructions projectedPolygon groundStatic ;
- V1 produit ses instructions existantes ;
- le merge conserve l'ordre interne de chaque collection ;
- V2 est inséré avant V1 dans la collection fusionnée ;
- MapLayersComponent rend ensuite groundStatic en une passe.
```

Cela préserve :

```text
- l'ordre source V2 dans mapData.placedElements ;
- l'ordre V1 existant à l'intérieur de la collection V1 ;
- le pass groundStatic ;
- la tolérance runtime aux dettes authoring ;
- l'absence de diagnostic bloquant au runtime.
```

## 16. Visual gate recommandé

Décision :

```text
Lot 24 : pas de screenshot, pas de Selbrume, pas de baseline.
Lot 25 : micro fixture / visual gate design ciblé.
Lot 26 : screenshot POC ciblé si le rendu est réellement branché et visible.
```

Justification :

```text
- Lot 24 ne doit pas changer le renderer.
- Lot 24 ne doit pas changer MapLayersComponent.
- Le comportement visible repose sur un renderer déjà testé pour projectedPolygon.
- La nouveauté du Lot 24 est le provider/merge, testable par host integration.
```

Déclencheur de visual gate immédiat si le scope change :

```text
Si le Lot 24 touche ShadowRuntimeRenderer, MapLayersComponent, un script screenshot,
Selbrume, ou une baseline, alors le visual gate doit être ramené dans le même lot
ou le lot doit être stoppé pour un design gate complémentaire.
```

## 17. Plan précis du Lot 24

```text
ShadowV2-24 — Projected Building Shadow Runtime Render Integration V0
```

Objectif :

```text
Raccorder la collection runtime ShadowV2 déjà construite au provider interne
de PlayableMapGame afin que MapLayersComponent la rende via le renderer existant.
```

Fichiers à modifier :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Fichiers à créer :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
reports/shadows/v2/shadow_v2_24_projected_building_shadow_runtime_render_integration.md
```

Fichiers à modifier seulement si un ajustement de test existant est strictement nécessaire :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Fichiers interdits :

```text
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
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Implémentation attendue :

```text
1. Ajouter l'import du builder V2 dans PlayableMapGame.
2. Ajouter une map privée :
   Map<String, ShadowRuntimeInstructionCollection> _projectedBuildingShadowCollectionByMapId.
3. Ajouter _refreshProjectedBuildingShadowCollection(RuntimeMapBundle bundle).
4. Dans cette méthode :
   - si shadowCollectionProvider != null ou !enableStaticPlacedElementShadows :
     retirer la collection V2 pour bundle.map.id ;
   - sinon appeler buildRuntimeProjectedBuildingShadowCollection(
       manifest: bundle.manifest,
       mapData: bundle.map,
     ) ;
   - stocker seulement si non vide.
5. Appeler _refreshProjectedBuildingShadowCollection(bundle) dans _mountLoadedMap,
   au même niveau que _refreshStaticPlacedElementShadowCollection(bundle).
6. Dans _provideShadowCollectionForMap(mapId), ajouter la collection V2
   avant la collection V1 static si elle existe.
7. Ne pas changer l'external provider : s'il est fourni, il reste prioritaire.
8. Ne pas appeler diagnostics.
```

Tests à ajouter :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Assertions obligatoires :

```text
- PlayableMapGame expose via son background MapLayersComponent une collection contenant l'instruction V2.
- L'instruction V2 est projectedPolygon.
- L'instruction V2 est groundStatic.
- Les points attendus de la géométrie V2 atteignent la collection provider.
- Absence de config V2 => pas d'instruction V2.
- Preset manquant => skip silencieux, pas de throw.
- V1 + V2 coexistent dans la collection fusionnée.
- Ordre fusionné recommandé : V2 groundStatic avant V1 groundStatic, actorContact ensuite dans instructions.
- External shadowCollectionProvider reste prioritaire.
- enableStaticPlacedElementShadows=false désactive V1 et V2 groundStatic en V0.
- RuntimeMapGame reste passif.
- Aucun appel diagnoseProjectedBuildingShadows.
- Aucun genericProjection dans le raccord V2.
```

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "buildRuntimeProjectedBuildingShadowCollection|mergeShadowRuntimeInstructionCollections|_provideShadowCollectionForMap|_refreshStaticPlacedElementShadowCollection|enableStaticPlacedElementShadows" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|Canvas|Path|Paint|dart:ui|package:flutter|package:flame" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart test test/shadow_v2
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/playable_map_game.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart
cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :

```text
- V2 collection branchée au provider interne PlayableMapGame.
- V2 visible dans la ShadowRuntimeInstructionCollection fournie au background MapLayersComponent.
- Aucun changement renderer.
- Aucun changement MapLayersComponent.
- Aucun changement map_core.
- Aucun diagnostic runtime.
- Aucun genericProjection ajouté.
- Aucune fixture Selbrume.
- Aucun screenshot/baseline.
- Tests ciblés et régression shadow passent.
```

## 18. Tests recommandés pour le Lot 24

Tests concrets proposés :

```text
runtime_projected_building_shadow_host_integration_test.dart
```

Cas 1 :

```text
PlayableMapGame builds projected building shadows for authored V2 placed elements
```

Assertions :

```text
- background.shadowCollectionProvider != null ;
- foreground.shadowCollectionProvider == null ;
- collection.groundStatic contient une instruction V2 ;
- instruction.shape == ShadowRuntimeShapeKind.projectedPolygon ;
- instruction.renderPass == ShadowRenderPass.groundStatic ;
- polygonPoints attendus présents dans l'ordre.
```

Cas 2 :

```text
V1 and V2 groundStatic collections are merged without blocking coexistence
```

Assertions :

```text
- élément avec shadow V1 + projectedBuildingShadow V2 ;
- collection.groundStatic contient 2 instructions ;
- V2 projectedPolygon attendu ;
- V1 instruction attendue ;
- aucun throw ;
- actorContact inchangé si activé.
```

Cas 3 :

```text
projected building shadows are merged before V1 static shadows
```

Assertions :

```text
- collection.instructions conserve l'ordre V2 puis V1 puis actorContact ;
- collection.groundStatic conserve l'ordre V2 puis V1.
```

Cas 4 :

```text
missing projected preset is skipped silently while V1 continues to work
```

Assertions :

```text
- V2 preset manquant ;
- V1 shadow valide ;
- collection.groundStatic contient seulement V1 ;
- pas de throw.
```

Cas 5 :

```text
absence of projected config does not create V2 instructions
```

Assertions :

```text
- manifest sans projectedBuildingShadow ;
- aucun projectedPolygon V2 issu du builder V2 ;
- comportement V1 existant inchangé.
```

Cas 6 :

```text
external shadow provider remains priority over internal V2 builder
```

Assertions :

```text
- PlayableMapGame reçoit shadowCollectionProvider externe ;
- provider du background est le même objet/fonction ;
- V2 interne non observable.
```

Cas 7 :

```text
enableStaticPlacedElementShadows false disables V1 and V2 ground static shadows
```

Assertions :

```text
- enableStaticPlacedElementShadows: false ;
- enableActorContactShadows: true ;
- V2 authored présent ;
- groundStatic vide ;
- actorContact fonctionne si prêt.
```

Cas 8 :

```text
RuntimeMapGame remains passive for projected building shadows
```

Assertions :

```text
- RuntimeMapGame sans provider explicite ;
- layer.shadowCollectionProvider == null ;
- pas de builder interne V2.
```

Cas 9 :

```text
render integration source does not call diagnostics or auto projection
```

Assertions possibles par audit test :

```text
- playable_map_game.dart ne contient pas diagnoseProjectedBuildingShadows ;
- playable_map_game.dart ne contient pas applyElementAutoShadowPolicyToProject ;
- playable_map_game.dart ne contient pas genericProjection ;
- le test V2 host ne masque pas ces termes par concaténation sauf si nécessaire.
```

Test non recommandé au Lot 24 :

```text
- screenshot Selbrume ;
- baseline visuelle ;
- test direct du renderer ;
- test direct de MapLayersComponent si son code n'est pas modifié.
```

## 19. Fichiers explicitement interdits au Lot 24

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/tool/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Exception à ne pas utiliser sans nouveau design gate : modifier `MapLayersComponent` ou `ShadowRuntimeRenderer`. L'audit montre que ce n'est pas nécessaire pour V2-24.

## 20. Risques / réserves

Risque 1 : `enableStaticPlacedElementShadows` devient en V0 le master switch des shadows ground static, incluant V1 et V2. C'est le plus petit choix, mais le nom est historiquement V1. Si un besoin produit exige un toggle séparé, il faudra un lot dédié.

Risque 2 : V1 + V2 coexistence peut créer un rendu visuellement trop sombre. Le runtime ne doit pas corriger automatiquement. Le diagnostic authoring `v1AndV2Coexistence` reste le bon garde-fou.

Risque 3 : le renderer applique aux `projectedPolygon` V2 les bandes d'opacité existantes conçues pour V1 projectedPolygon. C'était accepté implicitement par le choix V2-20 de réutiliser `ShadowRuntimeShapeKind.projectedPolygon`. Si l'art direction veut une distribution d'opacité V2 spécifique, ce sera un lot renderer/design séparé.

Risque 4 : les maps connectées nécessitent que le refresh V2 soit appelé pour chaque `RuntimeMapBundle` monté, pas seulement pour la map active. Le Lot 24 doit tester ce point si le temps le permet.

Risque 5 : un test qui observe uniquement `collection.groundStatic.length` peut confondre V1 et V2, car les deux utilisent `projectedPolygon`. Les tests Lot 24 doivent distinguer les instructions par points attendus, couleur/opacité de preset V2, ou par ordre fusionné.

## 21. Auto-critique

Le design le plus tentant serait de modifier `MapLayersComponent` pour lui donner deux providers, un V1 et un V2. L'audit montre que ce serait une dérive : le composant de rendu n'a pas besoin de connaître les sources. Garder la décision au niveau `PlayableMapGame` respecte mieux la séparation.

Le choix de dessiner V2 avant V1 dans `groundStatic` est une décision artistique/technique V0. Elle protège mieux les ombres V1 existantes et réduit le risque qu'une grande projection V2 écrase visuellement une petite shadow V1. Cette décision doit être testée explicitement au Lot 24 pour éviter une inversion silencieuse.

Le rapport ne propose pas de visual gate immédiat. C'est volontaire parce que le renderer n'est pas modifié. La limite est claire : dès qu'un lot touche le rendu effectif, une micro fixture visuelle devient nécessaire.

## 22. Regard critique sur le prompt

Le prompt est bien borné : il interdit le code et force l'audit du vrai pipeline avant de décider. Le point le plus sensible est la question "faut-il merger les instructions V1 et V2 avant rendu ?" ; dans ce repo, l'existence de `mergeShadowRuntimeInstructionCollections(...)` transforme cette option en meilleur chemin évident.

Le prompt demande aussi d'auditer `MapLayersComponent`. C'est important, car sans cet audit on pourrait croire que le lot 24 doit toucher le composant. Le code montre l'inverse : `MapLayersComponent` est déjà générique côté collection.

Une précision utile pour le prompt V2-24 : nommer explicitement `PlayableMapGame` comme seul fichier de production autorisé, et dire que `enableStaticPlacedElementShadows` contrôle V2 en V0, éviterait une hésitation sur l'ajout d'un nouveau flag public.

## 23. Commandes lancées

Commandes AGENTS / git :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Commandes d'audit obligatoires :

```bash
rg -n "class ShadowRuntimeRenderer|ShadowRuntimeRenderer|renderCollectionPass|projectedPolygon|drawPath|drawOval|ShadowRuntimeShapeKind|ShadowRenderPass|groundStatic|actorContact" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "class MapLayersComponent|MapLayersComponent|render\\(|ShadowRuntimeRenderer|renderCollectionPass|groundStatic|actorContact|surfaces|placedElements|actors|debug|occlusion" packages/map_runtime/lib/src/presentation packages/map_runtime/lib/src
rg -n "runtime_static_placed_element_shadow|buildRuntimeStatic|StaticPlacedElementShadow|ShadowRuntimeInstructionCollection|MapPlacedElement|ProjectElementShadowConfig|element.shadow|shadowOverride" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "buildRuntimeProjectedBuildingShadowCollection|ProjectedBuildingShadow|projectedBuildingShadow|projectedBuildingShadowCatalog|createProjectedBuildingShadowRuntimeInstruction|resolveProjectedBuildingShadowGeometry" packages/map_runtime/lib/src packages/map_runtime/test packages/map_core/lib/src packages/map_core/test
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy" packages/map_runtime/lib packages/map_core/lib
```

Commandes de lecture ciblée :

```bash
sed -n '1,140p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,130p' packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
sed -n '1,120p' packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
sed -n '240,360p' packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
sed -n '1650,1735p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '6535,6572p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,130p' packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
```

Commandes finales prévues pour ce rapport :

```bash
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 24. git diff --stat

Commande avant création du rapport :

```bash
git diff --stat
```

Sortie :

```text
```

Commande après création du rapport :

```bash
git diff --stat
```

Sortie constatée :

```text
```

Interprétation : `git diff --stat` ne liste pas le rapport tant qu'il reste untracked. Le statut final ci-dessous liste le fichier créé.

## 25. git diff --name-status

Commande avant création du rapport :

```bash
git diff --name-status
```

Sortie :

```text
```

Commande après création du rapport :

```bash
git diff --name-status
```

Sortie constatée :

```text
```

Interprétation : aucun fichier suivi n'a été modifié.

## 26. git diff --check

Commande avant création du rapport :

```bash
git diff --check
```

Sortie :

```text
```

Commande après création du rapport :

```bash
git diff --check
```

Sortie constatée :

```text
```

## 27. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie constatée :

```text
?? reports/shadows/v2/shadow_v2_23_projected_building_shadow_runtime_render_integration_design.md
```

Interprétation : seul le rapport ShadowV2-23 est créé.

## Checklist finale :

- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test modifié
- [x] Aucun generated modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun screenshot/baseline créé
- [x] Pipeline renderer audité
- [x] MapLayersComponent / pipeline Flame audité
- [x] Builder V2 Lot 22 audité
- [x] Options d’intégration comparées
- [x] Option recommandée unique
- [x] Plan ShadowV2-24 précis
- [x] Tests ShadowV2-24 proposés
- [x] git diff --check propre
- [x] git status final conforme
