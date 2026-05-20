# ShadowV2-19 — Projected Building Shadow Runtime Instruction Design Gate

## 1. Résumé exécutif

ShadowV2-19 est un design gate pur. Aucun code runtime, core, editor, renderer, diagnostic, codec, modèle persistant, fixture Selbrume, screenshot ou fichier generated n'a été modifié par ce lot.

Décision principale :

- V2-20 doit créer un adapter runtime dédié `ProjectedBuildingShadowGeometry -> ShadowRuntimeRenderInstruction`.
- L'adapter doit réutiliser `ShadowRuntimeShapeKind.projectedPolygon`.
- L'adapter doit fixer `renderPass` à `ShadowRenderPass.groundStatic`.
- L'adapter doit rester séparé des futurs builders manifest/map.
- Aucun `drawPath`, renderer, collection builder, manifest traversal ou lookup catalogue ne doit être ajouté en V2-20.

Le runtime actuel possède déjà une primitive `projectedPolygon`, un renderer `drawPath`, un filtrage par `ShadowRenderPass`, et une peinture des ombres avant les sprites d'éléments dans `MapLayersComponent`. Le pont V2 peut donc commencer par une conversion de données, sans toucher au rendu.

## 2. Objectif du lot

Objectif : décider comment convertir plus tard :

```text
ProjectedBuildingShadowGeometry
```

en :

```text
ShadowRuntimeRenderInstruction
```

sans implémenter cette conversion dans ce lot.

La décision doit éviter :

- confusion avec `genericProjection` V1 ;
- création automatique d'ombres V2 ;
- modification du renderer ;
- modification de l'éditeur ;
- mutation du `project.json` ;
- visual baseline prématurée.

## 3. Rappel ShadowV2-18

ShadowV2-18 a créé :

- `ProjectedBuildingShadowPoint`
- `ProjectedBuildingShadowGeometry`
- `resolveProjectedBuildingShadowGeometry(...)`

Comportements validés :

- `config.enabled == false -> null`
- enabled true -> 4 points
- ordre stable : `nearLeft`, `nearRight`, `farRight`, `farLeft`
- direction normalisée
- `followsSun` V0 -> fixed
- `opacity` / `colorHexRgb` propagés
- aucun lookup catalogue
- aucun traversal `ProjectManifest`
- aucun runtime
- aucun editor
- aucun JSON

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
?? reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md
```

Interprétation :

- ces changements préexistaient au démarrage de ShadowV2-19 ;
- ils correspondent au lot ShadowV2-18 non encore commité ;
- ShadowV2-19 ne les modifie pas.

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

- ce lot est lui-même un design gate ;
- aucune implémentation n'est prévue ;
- le design gate est respecté.

Note Flame :

- `flame_docs` a été interrogé sur le rendu / priority / render order ;
- les requêtes n'ont pas retourné de résultat exploitable ;
- les décisions runtime ci-dessous s'appuient donc sur le code local existant.

## 6. Fichiers audités

Géométrie V2 :

- `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart`
- `reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md`
- `reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md`

Runtime Shadow :

- `packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart`
- `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`
- `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart`
- `packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart`

Render order :

- `packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Tests runtime Shadow :

- `packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`
- `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart`
- `packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart`
- `packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart`

## 7. Audit geometry V2

Commande :

```bash
rg -n "ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|resolveProjectedBuildingShadowGeometry|StaticShadowVisualMetrics" packages/map_core/lib/src packages/map_core/test/shadow_v2 reports/shadows/v2
```

Résultats pertinents :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:7:final class ProjectedBuildingShadowPoint {
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:28:final class ProjectedBuildingShadowGeometry {
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:63:ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:66:  required StaticShadowVisualMetrics metrics,
packages/map_core/lib/src/operations/static_shadow_geometry.dart:10:final class StaticShadowVisualMetrics {
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:9:      final geometry = resolveProjectedBuildingShadowGeometry(
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:151:      final geometry = ProjectedBuildingShadowGeometry(
reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md:10:- inputs V0 : `ProjectElementProjectedBuildingShadowConfig + ProjectBuildingShadowPreset + StaticShadowVisualMetrics` ;
reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md:451:Objectif recommandé : décider comment adapter `ProjectedBuildingShadowGeometry` vers une instruction runtime future, sans encore modifier le renderer.
```

Constats :

- la géométrie V2 est dans `map_core`, pure Dart ;
- elle expose 4 points ordonnés ;
- elle porte déjà `opacity` et `colorHexRgb` ;
- elle ne connaît ni runtime, ni renderer, ni manifest, ni catalogue ;
- les points V2 sont en coordonnées monde de la même forme conceptuelle que les points runtime.

## 8. Audit runtime instruction actuel

Commande :

```bash
rg -n "class ShadowRuntimeRenderInstruction|enum ShadowRuntimeShapeKind|ShadowRuntimeRenderInstruction\\(|projectedPolygon|ellipse|contact|points|renderPass|colorHexRgb|opacity" packages/map_runtime/lib/src packages/map_runtime/test
```

Résultats pertinents :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:5:enum ShadowRuntimeShapeKind {
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:8:  projectedPolygon,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:31:final class ShadowRuntimeRenderInstruction {
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:63:  final ShadowRuntimeShapeKind shape;
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:64:  final ShadowRenderPass renderPass;
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:69:  final double opacity;
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:70:  final String colorHexRgb;
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:72:  final List<ShadowRuntimePoint> polygonPoints;
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:187:    case ShadowRuntimeShapeKind.projectedPolygon:
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart:27:    test('creates a valid projected polygon instruction', () {
```

Lecture ciblée de `shadow_runtime_render_instruction.dart` :

- `ShadowRuntimeShapeKind` contient déjà `contactBlob`, `ellipse`, `projectedPolygon` ;
- `ShadowRuntimeRenderInstruction` porte `shape`, `renderPass`, `worldLeft`, `worldTop`, `width`, `height`, `opacity`, `colorHexRgb`, `softnessMode`, `polygonPoints` ;
- `colorHexRgb` est normalisé uppercase ;
- `projectedPolygon` exige au moins 3 points et rejette les polygones dégénérés ;
- `polygonPoints` est immutable après construction.

Conséquence :

- la forme runtime nécessaire existe déjà ;
- V2-20 n'a pas besoin de modifier `ShadowRuntimeRenderInstruction` pour un premier adapter.

## 9. Audit renderer actuel

Commande :

```bash
rg -n "drawPath|drawOval|Path\\(|ShadowRuntimeShapeKind|paint|Canvas|opacity|colorHexRgb|projectedPolygon" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
```

Résultats pertinents :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:11:  void renderInstruction(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:17:      case ShadowRuntimeShapeKind.contactBlob:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:18:      case ShadowRuntimeShapeKind.ellipse:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:20:      case ShadowRuntimeShapeKind.projectedPolygon:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:35:    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:44:      canvas.drawPath(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:51:      canvas.drawPath(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:85:  final rgb = int.parse(instruction.colorHexRgb, radix: 16);
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:86:  final alpha = (instruction.opacity * 255).round().clamp(0, 255).toInt();
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:105:    test('draws projectedPolygon with visible interior and transparent outside',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:139:    test('draws projectedPolygon with stronger near alpha than far alpha',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:304:    test('filters projectedPolygon instructions by render pass', () async {
```

Lecture ciblée de `shadow_runtime_renderer.dart` :

- `projectedPolygon` est déjà rendu par `drawPath` ;
- un polygone à 4 points reçoit des bandes d'opacité via `createProjectedStaticShadowOpacityBands()` ;
- les autres polygones utilisent un fallback path plein ;
- `renderCollectionPass(...)` filtre par `ShadowRenderPass.groundStatic` ou `ShadowRenderPass.actorContact`.

Conséquence :

- V2-20 ne doit pas toucher le renderer ;
- le rendu V2 réel pourra apparaître plus tard dès qu'une collection injecte des instructions `projectedPolygon`, mais V2-20 doit rester seulement adapter + tests unitaires.

## 10. Audit render pass / ordering

Commande :

```bash
rg -n "groundStatic|actorContact|ShadowRenderPass|renderPass|MapLayersComponent|priority|render|children|add\\(" packages/map_runtime/lib/src packages/map_runtime/test
```

Commande de suivi ciblée utilisée pour éviter les résultats hors Shadow très larges :

```bash
rg -n "groundStatic|actorContact|ShadowRenderPass|renderPass|MapLayersComponent|priority|render|children|add\\(" packages/map_runtime/lib/src packages/map_runtime/test --glob '!packages/map_runtime/lib/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart'
```

Résultats pertinents :

```text
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:1:enum RuntimeShadowRenderOrderSlot {
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:5:  futureStaticPlacedElementShadows,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:6:  futureDynamicActorContactShadows,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:17:  RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:18:  RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:251:  void render(Canvas canvas) {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:335:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:338:      ShadowRenderPass.groundStatic,
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:340:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:343:      ShadowRenderPass.actorContact,
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:57:        groundStatic = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:63:        actorContact = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:117:  ShadowRuntimeRenderPass pass,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:140:  if (resolved.renderPass != ShadowRenderPass.groundStatic) {
```

Lecture ciblée de `map_layers_component.dart` :

```text
background pass:
terrain
paths
surface layers
_paintShadows(canvas)
tile layers + placed elements
entities
collision overlay when enabled
```

Lecture ciblée de `_paintShadows(...)` :

```text
renderCollectionPass(..., ShadowRenderPass.groundStatic)
renderCollectionPass(..., ShadowRenderPass.actorContact)
```

Lecture ciblée de `shadow_runtime_render_order_contract.dart` :

```text
baseTerrain
groundPaths
surfaceLayers
futureStaticPlacedElementShadows
futureDynamicActorContactShadows
placedElementSprites
actorsPlayerNpc
placedElementOcclusionPatches
debugOverlays
hudUi
```

Conséquence :

- le code réel peint déjà les ombres avant les sprites d'éléments et les actors ;
- une ombre V2 `groundStatic` ne sera pas au-dessus du bâtiment ;
- V2-20 ne doit pas changer cet ordre.

## 11. Décision instruction shape

Options comparées :

| Option | Décision | Pourquoi |
|---|---|---|
| A — réutiliser `ShadowRuntimeShapeKind.projectedPolygon` | Retenue pour V2-20 | La primitive existe, le renderer sait déjà la dessiner, aucun changement renderer/instruction requis. |
| B — ajouter `buildingProjectedPolygon` | Rejetée pour V2-20 | Nécessite de modifier `ShadowRuntimeRenderInstruction` et `ShadowRuntimeRenderer` alors que le dessin est identique. |
| C — ajouter une metadata source/type | Différée | Plus propre pour debug à long terme, mais modifie le modèle runtime et les collections pour un gain non nécessaire au premier adapter. |

Décision canonique V2-20 :

```text
ProjectedBuildingShadowGeometry
-> ShadowRuntimeRenderInstruction(shape: ShadowRuntimeShapeKind.projectedPolygon)
```

Justification :

- `projectedPolygon` est une forme de dessin, pas une preuve que la source est V1 ;
- le nom de l'adapter et les tests V2 garantissent la source V2 ;
- aucune dépendance à `genericProjection` ne doit être importée ou mentionnée dans l'adapter ;
- si le debug/source tracking devient nécessaire, une metadata pourra être conçue plus tard sans bloquer le POC.

## 12. Décision adapter location

Options comparées :

| Option | Décision | Pourquoi |
|---|---|---|
| A — `packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart` | Retenue | Responsabilité claire : geometry -> instruction. Testable sans renderer. |
| B — dans une collection builder | Rejetée pour V2-20 | Mélange traversal manifest/map, lookup preset, geometry et instruction. Trop large. |
| C — dans le renderer | Rejetée | Le renderer ne doit pas résoudre ou adapter de données domaine. |

Décision :

```text
V2-20 crée un fichier adapter dédié dans map_runtime/lib/src/shadow/.
```

## 13. Décision adapter inputs

Signature recommandée :

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction({
  required ProjectedBuildingShadowGeometry geometry,
})
```

Décisions :

- pas de `config` ;
- pas de `preset` ;
- pas de `ProjectManifest` ;
- pas de `ProjectElementEntry` ;
- pas de `MapPlacedElement` ;
- pas de catalogue ;
- pas de paramètre `renderPass` en V0.

Mapping :

```text
shape       = ShadowRuntimeShapeKind.projectedPolygon
renderPass  = ShadowRenderPass.groundStatic
points      = geometry.points -> ShadowRuntimePoint(worldX: x, worldY: y)
opacity     = geometry.opacity
colorHexRgb = geometry.colorHexRgb
softness    = ShadowSoftnessMode.hardEdge
worldLeft   = min(points.worldX)
worldTop    = min(points.worldY)
width       = maxX - minX
height      = maxY - minY
```

Les bounds sont nécessaires parce que `ShadowRuntimeRenderInstruction` les utilise déjà pour validation et culling.

Comportement invalid/degenerate :

- l'adapter ne corrige pas ;
- l'adapter ne clamp pas ;
- l'adapter laisse `ShadowRuntimeRenderInstruction` rejeter un polygone dégénéré ;
- le futur builder pourra décider de filtrer ou propager cette erreur, après diagnostics.

## 14. Décision render pass

Décision :

```text
ShadowRenderPass.groundStatic
```

Justification :

- les ombres projetées de bâtiments sont au sol ;
- elles doivent être peintes avant les sprites d'éléments ;
- le pass existe déjà ;
- `MapLayersComponent` peint déjà `groundStatic` avant les placed element sprites ;
- aucun nouveau pass n'est requis pour V2-20.

Risque :

- V1 et V2 cohabiteront dans `groundStatic`.

Mitigation V0 :

- le fichier adapter et les tests portent le nom `projected_building_shadow` ;
- l'adapter ne dépend pas de `static_shadow_family_projection` ;
- un futur builder V2 séparera clairement la provenance des instructions.

## 15. Décision render order

Ordre réel constaté dans le background pass :

```text
terrain
-> paths
-> surfaces
-> shadows groundStatic
-> shadows actorContact
-> tile layers / placed elements
-> entities
-> collision overlay
```

Ordre cible pour V2 building projected shadows :

```text
terrain / paths / surfaces
-> groundStatic shadows V1 + V2
-> placed element sprites
-> actors / project-element entities
-> occlusion patches / overlays / HUD selon système existant
```

Décision :

- V2 building projected shadows doivent rester dans `groundStatic`.
- V2-20 ne modifie pas `MapLayersComponent`.
- V2-20 ne modifie pas le render order.

Note :

- le code actuel peint aussi `actorContact` dans `_paintShadows` avant les sprites/actors ;
- cette décision n'est pas changée par ShadowV2-19.

## 16. Collection future séparée

ShadowV2-20 doit faire uniquement :

```text
ProjectedBuildingShadowGeometry -> ShadowRuntimeRenderInstruction
```

ShadowV2-20 ne doit pas faire :

- traversal `ProjectManifest` ;
- traversal `MapData` ;
- lookup `ProjectBuildingShadowPresetCatalog` ;
- extraction `ProjectElementEntry.projectedBuildingShadow` ;
- extraction `MapPlacedElement` ;
- conversion metrics depuis placements ;
- merge avec collections V1 ;
- injection dans `PlayableMapGame`.

Lot futur après V2-20 :

```text
builder manifest/map :
- parcourt les éléments placés ;
- récupère ProjectElementEntry.projectedBuildingShadow ;
- lookup preset dans ProjectManifest.projectedBuildingShadowCatalog ;
- skip si disabled ;
- skip ou diagnostic si preset absent ;
- appelle resolveProjectedBuildingShadowGeometry(...) ;
- appelle createProjectedBuildingShadowRuntimeInstruction(...) ;
- produit une ShadowRuntimeInstructionCollection V2.
```

## 17. Missing preset / diagnostics

Décision :

- l'adapter runtime ne traite pas `missingPreset` ;
- l'adapter reçoit une géométrie valide, pas un `presetId` ;
- le diagnostic `missingPreset` reste la source de vérité authoring ;
- le futur builder haut niveau ne doit jamais fallback vers `genericProjection`.

Règle :

```text
missing preset -> diagnostic / skip futur builder
jamais genericProjection
```

## 18. Screenshot / visual gate policy

ShadowV2-20 :

- pas de screenshot ;
- pas de baseline ;
- tests unitaires runtime seulement ;
- pas de renderer ;
- pas de `MapLayersComponent` ;
- pas de Selbrume.

Dès qu'un lot touche :

- renderer ;
- collection branchée au host ;
- `PlayableMapGame` ;
- `MapLayersComponent` ;
- Selbrume ;
- baselines ;

alors visual gate obligatoire :

- harness screenshot ;
- baseline V2 séparée ;
- before/after ;
- rapport visuel explicite.

## 19. Tests à prévoir pour ShadowV2-20

Test 1 — converts geometry to runtime instruction :

```text
input:
- ProjectedBuildingShadowGeometry avec 4 points
- opacity 0.18
- colorHexRgb 000000

expected:
- shape == ShadowRuntimeShapeKind.projectedPolygon
- renderPass == ShadowRenderPass.groundStatic
- polygonPoints préservés dans l'ordre
- opacity préservée
- colorHexRgb préservé
```

Test 2 — computes bounds from polygon points :

```text
points non triés spatialement mais ordonnés géométriquement
expected:
- worldLeft == minX
- worldTop == minY
- width == maxX - minX
- height == maxY - minY
```

Test 3 — normalizes color through runtime instruction :

```text
geometry colorHexRgb '0A0B0C' ou uppercase déjà validé
expected:
- runtime instruction colorHexRgb uppercase
```

Test 4 — preserves zero opacity :

```text
geometry opacity 0
expected:
- runtime instruction opacity 0
```

Test 5 — degenerate geometry is not silently fixed :

```text
collinear / zero-area geometry
expected:
- adapter throws ValidationException through ShadowRuntimeRenderInstruction
```

Test 6 — no renderer dependency :

```text
adapter source does not import:
- dart:ui
- flutter
- flame
- shadow_runtime_renderer.dart
```

Test 7 — no genericProjection dependency :

```text
adapter source does not import:
- static_shadow_family_projection.dart
- static_shadow_projection_geometry.dart
adapter source does not contain:
- genericProjection
```

No disabled test :

- disabled was handled in ShadowV2-18 by the geometry resolver ;
- adapter receives non-null geometry only.

## 20. Fichiers proposés pour ShadowV2-20

Fichiers autorisés recommandés :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

Fichiers à ne pas modifier en V2-20 :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_core/**
packages/map_editor/**
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Export public :

- `map_runtime.dart` ne semble pas exporter les helpers shadow internes ;
- V2-20 ne devrait pas ajouter d'export public sauf convention contraire découverte dans le lot.

## 21. Roadmap après ShadowV2-19

Roadmap recommandée :

```text
ShadowV2-20 — Projected Building Shadow Runtime Instruction Adapter V0
ShadowV2-21 — Projected Building Shadow Runtime Collection Builder Design Gate
ShadowV2-22 — Projected Building Shadow Runtime Collection Builder V0
ShadowV2-23 — Projected Building Shadow Renderer / Visual POC Design Gate
ShadowV2-24 — One Building Runtime Visual POC
ShadowV2-25 — Screenshot Baseline V2
ShadowV2-26 — Editor Preview Design Gate
```

## 22. Commandes lancées

Commandes :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|resolveProjectedBuildingShadowGeometry|StaticShadowVisualMetrics" packages/map_core/lib/src packages/map_core/test/shadow_v2 reports/shadows/v2
rg -n "class ShadowRuntimeRenderInstruction|enum ShadowRuntimeShapeKind|ShadowRuntimeRenderInstruction\\(|projectedPolygon|ellipse|contact|points|renderPass|colorHexRgb|opacity" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "drawPath|drawOval|Path\\(|ShadowRuntimeShapeKind|paint|Canvas|opacity|colorHexRgb|projectedPolygon" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "groundStatic|actorContact|ShadowRenderPass|renderPass|MapLayersComponent|priority|render|children|add\\(" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "groundStatic|actorContact|ShadowRenderPass|renderPass|MapLayersComponent|priority|render|children|add\\(" packages/map_runtime/lib/src packages/map_runtime/test --glob '!packages/map_runtime/lib/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart'
rg -n "Runtime.*Shadow.*Collection|runtimeStatic|staticPlaced|actorContact|resolve.*Shadow|ShadowRuntimeRenderInstruction" packages/map_runtime/lib/src packages/map_runtime/test --glob '!packages/map_runtime/lib/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart'
sed -n '1,240p' packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
sed -n '1,280p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
sed -n '1,560p' packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart
sed -n '1,120p' packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
sed -n '1,180p' packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart
sed -n '1,260p' packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart
sed -n '1,700p' packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
sed -n '1660,1735p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,420p' packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 23. Résultats

Synthèse des résultats :

- V2 geometry existe uniquement en `map_core`.
- Runtime instruction contient déjà `projectedPolygon`.
- Runtime renderer dessine déjà `projectedPolygon`.
- Runtime collection sépare `groundStatic` et `actorContact`.
- `MapLayersComponent` peint les shadows entre surfaces et placed element sprites.
- `PlayableMapGame` merge déjà collections static + actor contact via provider, mais V2 ne doit pas s'y brancher en V2-20.
- Aucun blocage AGENTS pour ce lot design-only.

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Interprétation :

- ce diff tracked préexistait au lot ShadowV2-19 ;
- le rapport V2-19 est un fichier non suivi et apparaît dans `git status`.

## 25. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

## 26. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
(aucune sortie)
```

## 27. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
?? reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md
?? reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
```

## 28. Risques / réserves

- Réutiliser `projectedPolygon` mélange la même shape runtime pour V1 et V2. Le risque est acceptable en V0 parce que la provenance est portée par l'adapter et les futurs builders, pas par la primitive de dessin.
- Ajouter une metadata source serait plus clair pour les inventaires debug, mais ce serait un changement de modèle runtime prématuré pour un adapter qui peut rester strictement mécanique.
- `ProjectedShadowShapeTuning.lengthRatio` peut être `0`, ce qui peut produire une géométrie V2 valide côté core mais dégénérée côté runtime instruction. V2-20 doit tester que l'adapter ne corrige pas silencieusement ce cas.
- Le code actuel peint `actorContact` avant les sprites/actors. ShadowV2-19 ne change pas cette architecture ; V2 building shadows doivent rester `groundStatic`.

## 29. Auto-critique

La décision Option A est volontairement conservatrice. Elle maximise la réutilisation du renderer existant et minimise les risques de dérive dans un lot qui ne doit pas rendre. Le coût est une séparation source/shape moins expressive à court terme.

L'audit `rg` runtime global remonte beaucoup de résultats hors Shadow à cause du code Flame et battle. Les décisions reposent donc sur des lectures ciblées des fichiers Shadow/runtime pertinents, listées dans le rapport.

## 30. Regard critique sur le prompt

Le prompt demande de comparer `shape kind` et metadata source. C'est utile, car le code existant rend `projectedPolygon` déjà suffisamment générique pour V2, mais le besoin de debug source est réel à moyen terme.

La limite "ne pas coder" est particulièrement importante ici : le renderer sait déjà dessiner la shape, donc le piège naturel aurait été de brancher une collection trop tôt. Le découpage adapter puis builder puis visual gate reste plus sûr.

## 31. Prompt proposé pour ShadowV2-20

`````md
# ShadowV2-20 — Projected Building Shadow Runtime Instruction Adapter V0

Tu travailles dans le repo local :

```text
/Users/karim/Project/pokemonProject
```

## CONTRAT DE LIVRAISON

Créer uniquement l'adapter runtime pur :

```text
ProjectedBuildingShadowGeometry -> ShadowRuntimeRenderInstruction
```

Tu ne dois PAS modifier :

```text
ShadowRuntimeRenderInstruction
ShadowRuntimeRenderer
MapLayersComponent
PlayableMapGame
ProjectManifest
ProjectElementEntry
codecs JSON
diagnostics
géométrie V2
runtime collection builder existant
editor
Selbrume
screenshots/baselines
generated files
```

Tu ne dois PAS faire de commit.

## Fichiers autorisés

Créer :

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

Ne pas exporter publiquement depuis `map_runtime.dart` sauf convention locale clairement auditée.

## API attendue

Créer :

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction({
  required ProjectedBuildingShadowGeometry geometry,
})
```

Mapping attendu :

```text
shape       = ShadowRuntimeShapeKind.projectedPolygon
renderPass  = ShadowRenderPass.groundStatic
points      = geometry.points -> ShadowRuntimePoint(worldX: x, worldY: y)
opacity     = geometry.opacity
colorHexRgb = geometry.colorHexRgb
softness    = ShadowSoftnessMode.hardEdge
worldLeft   = minX
worldTop    = minY
width       = maxX - minX
height      = maxY - minY
```

L'adapter ne doit pas :

```text
chercher un preset
lire ProjectManifest
lire ProjectElementEntry
lire MapPlacedElement
appeler resolveProjectedBuildingShadowGeometry
modifier le renderer
importer Flutter / Flame / dart:ui
importer static_shadow_family_projection
mentionner genericProjection
```

## Tests attendus

Créer :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Tester :

```text
- converts geometry to projectedPolygon runtime instruction ;
- renderPass groundStatic ;
- polygon points preserved in order ;
- bounds computed from min/max points ;
- opacity/color propagated ;
- zero opacity preserved ;
- degenerate geometry is rejected through runtime instruction validation ;
- adapter source has no Flutter/Flame/dart:ui/renderer import ;
- adapter source has no genericProjection/static_shadow_family_projection dependency.
```

## Commandes à lancer

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "projectedPolygon|ShadowRuntimeRenderInstruction|ShadowRuntimePoint|ShadowRenderPass|ProjectedBuildingShadowGeometry" packages/map_runtime/lib/src packages/map_runtime/test packages/map_core/lib/src
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow/projected_building_shadow_runtime_adapter.dart test/shadow/projected_building_shadow_runtime_adapter_test.dart
cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## Rapport

Créer :

```text
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

Le rapport doit inclure :

```text
- git status initial/final ;
- fichiers créés/modifiés ;
- contenu complet de l'adapter ;
- contenu complet du test ;
- sorties complètes du test ciblé, regression shadow runtime et analyze ;
- git diff --stat ;
- git diff --name-status ;
- git diff --check ;
- confirmation aucun renderer/runtime host/editor/Selbrume/screenshot modifié.
```
`````
