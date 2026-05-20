# ShadowV2-19 — Projected Building Shadow Runtime Instruction Design Gate

Date: 2026-05-20

Statut: design-only, runtime-instruction-design-only, no-code-change hors ce rapport.

## 1. Résumé exécutif

ShadowV2-19 tranche le pont futur entre `ProjectedBuildingShadowGeometry` et le runtime sans l'implémenter.

Décision principale: ShadowV2-20 doit réutiliser `ShadowRuntimeShapeKind.projectedPolygon` pour le POC adapter. Le renderer sait déjà dessiner ce shape, y compris les bandes d'opacité des quadrilatères. Ajouter un nouveau shape kind forcerait une modification renderer inutile pour V2-20. Ajouter une metadata `sourceKind` serait architecturalement propre à terme, mais modifierait `ShadowRuntimeRenderInstruction` trop tôt alors que l'adapter peut rester explicitement nommé et testé.

Adapter recommandé: créer plus tard `packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart`, avec une fonction pure:

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
)
```

La fonction devra fixer `renderPass: ShadowRenderPass.groundStatic`, convertir les quatre points V2 en `ShadowRuntimePoint`, calculer les bounds `worldLeft/worldTop/width/height`, propager `opacity` et `colorHexRgb`, et ne jamais importer Flame, Canvas, Flutter, `static_shadow_family_projection`, Selbrume, manifest traversal ou diagnostics.

## 2. Objectif du lot

Objectif: décider comment afficher plus tard une `ProjectedBuildingShadowGeometry` dans le runtime sans confondre V2 avec `genericProjection` V1, sans casser le renderer actuel, et sans réintroduire d'automatisme dangereux.

Ce lot conçoit le pont. Il ne le construit pas.

## 3. Rappel ShadowV2-18

ShadowV2-18 a validé une géométrie V2 pure:

- `ProjectedBuildingShadowPoint`
- `ProjectedBuildingShadowGeometry`
- `resolveProjectedBuildingShadowGeometry(...)`

Comportements confirmés:

- `config.enabled == false` retourne `null`.
- `enabled == true` produit exactement 4 points.
- Ordre stable: nearLeft, nearRight, farRight, farLeft.
- Direction normalisée.
- `followsSun` V0 traité comme `fixed`.
- `opacity` et `colorHexRgb` propagés.
- Aucun lookup catalogue, aucun traversal `ProjectManifest`, aucun runtime, aucun editor, aucun JSON.

## 4. État initial du worktree

Commande:

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Résultat:

```text

```

Interprétation: worktree initial propre.

## 5. Décision AGENTS / design gate

Commandes:

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md ../AGENTS.md 2>/dev/null || true
```

Résultat:

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
AGENTS.md:765:Before structural changes, read the nearest:
AGENTS.md:848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
AGENTS.md:1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
AGENTS.md:1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation:

- Ce lot est un design gate.
- Il respecte la règle AGENTS: conception avant implémentation.
- Aucune implémentation runtime, renderer, editor, codec, diagnostic, manifest, Selbrume ou baseline n'est prévue.

## 6. Fichiers audités

Tous les fichiers demandés existent:

```text
present packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
present packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
present packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
present packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
present packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
present packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
present packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
present packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart
present packages/map_runtime/lib/src/shadow/actor_contact_shadow_runtime_resolver.dart
present packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
present packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
present packages/map_runtime/tool/shadow/README.md
present reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
present reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md
present reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md
```

Tests runtime Shadow recensés:

```text
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
packages/map_runtime/test/shadow/actor_contact_shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
packages/map_runtime/test/shadow/runtime_shadow_render_order_contract_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart
packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart
packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
packages/map_runtime/test/shadow/shadow_runtime_render_order_mapping_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_runtime/test/shadow/shadow_runtime_resolver_test.dart
packages/map_runtime/test/shadow/static_placed_element_shadow_runtime_resolver_test.dart
```

## 7. Audit geometry V2

Commande:

```bash
rg -n "ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|resolveProjectedBuildingShadowGeometry|StaticShadowVisualMetrics" packages/map_core/lib/src packages/map_core/test/shadow_v2 reports/shadows/v2
```

Résultat structurant:

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:7:final class ProjectedBuildingShadowPoint
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:28:final class ProjectedBuildingShadowGeometry
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:43:  final List<ProjectedBuildingShadowPoint> points;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:44:  final double opacity;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:45:  final String colorHexRgb;
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:63:ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:66:  required StaticShadowVisualMetrics metrics,
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:8:  group('Projected building shadow geometry', () {
reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md:9:- resolver location : `map_core`, géométrie pure, avec adapters runtime/editor plus tard ;
reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md:15:- render pass futur : `groundStatic`, avant sprites et actors, sans contact ledge automatique.
```

Constats:

- `ProjectedBuildingShadowGeometry` contient seulement points, opacity et color.
- Le constructeur exige exactement 4 points et normalise `colorHexRgb` en uppercase.
- Le resolver retourne `null` si la config est disabled.
- Les tests imposent l'ordre des points, l'immuabilité, la validation et l'indépendance runtime/editor/manifest.
- La géométrie V2 est déjà le bon input d'un adapter runtime.

## 8. Audit runtime instruction actuel

Commande:

```bash
rg -n "class ShadowRuntimeRenderInstruction|enum ShadowRuntimeShapeKind|ShadowRuntimeRenderInstruction\\(|projectedPolygon|ellipse|contact|points|renderPass|colorHexRgb|opacity" packages/map_runtime/lib/src packages/map_runtime/test
```

Résultat structurant:

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:5:enum ShadowRuntimeShapeKind {
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:6:  contactBlob,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:7:  ellipse,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:8:  projectedPolygon,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:40:final class ShadowRuntimeRenderInstruction {
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:42:    required this.shape,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:43:    required this.renderPass,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:44:    required this.worldLeft,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:45:    required this.worldTop,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:46:    required this.width,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:47:    required this.height,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:48:    required this.opacity,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:49:    String colorHexRgb = '000000',
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:51:    Iterable<ShadowRuntimePoint> polygonPoints = const [],
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart:29:    test('creates a valid projected polygon instruction', () {
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart:151:    test('rejects projected polygons with fewer than three points', () {
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart:175:    test('rejects polygon points on oval shapes', () {
```

Constats:

- `projectedPolygon` existe déjà dans le modèle runtime.
- `ShadowRuntimeRenderInstruction` n'a pas de champ source/type metadata.
- L'instruction exige toujours `worldLeft`, `worldTop`, `width`, `height`, même pour les polygones.
- Les `polygonPoints` sont immuables après construction.
- Le modèle valide les couleurs, opacités, dimensions et points.

Implication pour V2-20:

- L'adapter devra calculer les bounds à partir des points V2.
- Aucun changement de `ShadowRuntimeRenderInstruction` n'est nécessaire pour un POC robuste.

## 9. Audit renderer actuel

Commande:

```bash
rg -n "drawPath|drawOval|Path\\(|ShadowRuntimeShapeKind|paint|Canvas|opacity|colorHexRgb|projectedPolygon" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
```

Résultat structurant:

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:16:    switch (instruction.shape) {
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:17:      case ShadowRuntimeShapeKind.contactBlob:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:18:      case ShadowRuntimeShapeKind.ellipse:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:19:        _renderOval(canvas, instruction);
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:20:      case ShadowRuntimeShapeKind.projectedPolygon:
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:21:        _renderProjectedPolygon(canvas, instruction);
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:35:    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:38:  void _renderProjectedPolygon(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:43:    if (points.length != 4) {
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:44:      canvas.drawPath(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:50:    for (final band in createProjectedStaticShadowOpacityBands()) {
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:51:      canvas.drawPath(
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:105:    test('draws projectedPolygon with visible interior and transparent outside',
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:123:    test('keeps projectedPolygon opacity zero transparent inside', () async {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:136:    test('draws projectedPolygon with stronger near alpha than far alpha',
```

Constats:

- Le renderer sait déjà dessiner `projectedPolygon`.
- Les quadrilatères ont un rendu en bandes d'opacité via `createProjectedStaticShadowOpacityBands()`.
- Les polygones non-4-points ont un fallback `drawPath` simple.
- V2 produit exactement 4 points, donc le chemin de rendu principal sera celui des bandes.
- ShadowV2-20 ne doit pas toucher au renderer.

## 10. Audit render pass / ordering

Commande:

```bash
rg -n "groundStatic|actorContact|ShadowRenderPass|renderPass|MapLayersComponent|priority|render|children|add\\(" packages/map_runtime/lib/src packages/map_runtime/test
```

Résultat structurant:

```text
packages/map_core/lib/src/models/shadow.dart:18:enum ShadowRenderPass {
packages/map_core/lib/src/models/shadow.dart:20:  groundStatic,
packages/map_core/lib/src/models/shadow.dart:23:  actorContact,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:18:  RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:19:  RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:20:  RuntimeShadowRenderOrderSlot.placedElementSprites,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:21:  RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:291:    for (var i = visible.length - 1; i >= 0; i--) {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:293:      if (layer is SurfaceLayer) {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:294:        _paintSurfaceLayer(canvas, layer);
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:297:    _paintShadows(canvas);
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:300:        tile: (id, name, tilesetId, v, o, tiles) {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:309:          _paintPlacedElementsForLayer(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:318:    _paintEntities(canvas);
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:335:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:338:      ShadowRenderPass.groundStatic,
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:340:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:343:      ShadowRenderPass.actorContact,
```

Ordre réel du pass background:

```text
terrain / paths
-> surface layers
-> shadow collection: groundStatic puis actorContact
-> tile layers + placed element sprites
-> entities
-> collision/debug overlays si activés
```

Le contrat d'ordre confirme:

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

Décision: V2 building projected shadows doivent être `groundStatic`, donc après surfaces et avant sprites de bâtiments. Elles ne doivent pas apparaître au-dessus des bâtiments.

## 11. Décision instruction shape

### Option A — Réutiliser `ShadowRuntimeShapeKind.projectedPolygon`

Principe:

```text
ProjectedBuildingShadowGeometry -> ShadowRuntimeRenderInstruction(shape: projectedPolygon)
```

Avantages:

- Le shape existe déjà.
- Le renderer le gère déjà.
- Les tests renderer couvrent déjà le rendu visible, l'opacité zéro, les bandes near/far et le filtrage de pass.
- Aucun changement renderer.
- Aucun changement `ShadowRuntimeRenderInstruction`.
- V2-20 peut rester un adapter pur et unitaire.

Risques:

- L'inventaire runtime ne distingue pas intrinsèquement V1 projection et V2 building projection.
- Les captures/baselines verront seulement `shapeKind: projectedPolygon` sauf si le builder futur ajoute une metadata externe.
- Debug moins explicite dans les collections tant que `sourceKind` n'existe pas.

Mitigation:

- Nommer l'adapter `projected_building_shadow_runtime_adapter.dart`.
- Tests explicites sur l'absence d'import `static_shadow_family_projection` et absence de mention `genericProjection`.
- Reporter la metadata source à un lot futur si le builder/visual gate montre un besoin réel.

### Option B — Ajouter `ShadowRuntimeShapeKind.buildingProjectedPolygon`

Avantages:

- Séparation V1/V2 claire dans l'instruction.
- Inventaire/debug plus lisibles.

Risques:

- Modifie `ShadowRuntimeRenderInstruction`.
- Modifie `ShadowRuntimeRenderer` pour ajouter un case.
- Augmente la surface runtime alors que le rendu est identique à `projectedPolygon`.
- Rend ShadowV2-20 plus large et plus risqué.

Décision: rejeté pour V2-20.

### Option C — Ajouter une metadata source

Exemple conceptuel:

```dart
sourceKind: ShadowRuntimeSourceKind.projectedBuildingV2
shape: ShadowRuntimeShapeKind.projectedPolygon
```

Avantages:

- Sépare correctement source et forme.
- Le renderer continue à raisonner en shape.
- Inventaire/debug/baselines plus clairs.

Risques:

- Modifie `ShadowRuntimeRenderInstruction`.
- Nécessite de toucher aux tests de collection, égalité/hash, helpers et potentiellement captures.
- Trop gros pour le POC adapter V0.

Décision: option propre pour plus tard, mais non retenue pour ShadowV2-20.

### Recommandation finale

Retenir Option A pour ShadowV2-20.

Raison: le code réel a déjà `projectedPolygon` dans l'instruction et dans le renderer. Le besoin immédiat est de convertir une géométrie V2 validée en instruction runtime, pas de changer le modèle runtime.

## 12. Décision adapter location

Options comparées:

| Option | Décision | Pourquoi |
|---|---|---|
| `packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart` | Retenue | Fichier dédié, testable, sans pollution renderer/collection. |
| Collection builder | Rejetée pour V2-20 | Mélange manifest traversal, lookup preset, geometry resolver et instruction. Trop tôt. |
| Renderer | Rejetée | Le renderer doit consommer une instruction, pas résoudre une géométrie. |

Décision: ShadowV2-20 crée un adapter dédié dans `map_runtime/lib/src/shadow/`.

## 13. Décision adapter inputs

Signature recommandée:

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
)
```

Décisions:

- `renderPass` est fixe: `ShadowRenderPass.groundStatic`.
- Les points viennent directement de `geometry.points`, dans l'ordre déjà validé.
- `opacity` vient de `geometry.opacity`.
- `colorHexRgb` vient de `geometry.colorHexRgb`.
- `width` / `height` sont requis par `ShadowRuntimeRenderInstruction`; l'adapter devra calculer une bounding box à partir des quatre points.
- `worldLeft` / `worldTop` sont le min X/Y de cette bounding box.
- Pas d'input `ProjectManifest`, pas de preset id, pas de config, pas de placement.
- Pas de gestion `disabled`; si la config est disabled, le resolver V2 a déjà retourné `null`.
- Pas de gestion `missingPreset`; l'adapter reçoit une geometry valide.

Pourquoi pas `required ShadowRenderPass renderPass`:

- Une grande ombre de bâtiment est sémantiquement au sol.
- Ouvrir ce paramètre dès V0 rend possible une mauvaise instruction `actorContact`.
- Si un lot futur veut plus de passes, il doit repasser par un design gate.

## 14. Décision render pass

Décision: `ShadowRenderPass.groundStatic`.

Justification:

- Les ombres projetées de bâtiments sont des ombres au sol.
- Le pass existe déjà.
- Le renderer filtre déjà `groundStatic`.
- `MapLayersComponent` dessine `groundStatic` avant les sprites de placed elements.
- Cela évite que l'ombre V2 apparaisse au-dessus du bâtiment.

Risque:

- V1 static shadows et V2 building projected shadows seront dans le même pass.

Mitigation:

- V2-20 ne crée pas de collection; aucun mélange runtime global.
- Le builder futur devra garder l'inventaire V2 clair dans ses tests et rapports.

## 15. Décision render order

Ordre cible documenté pour V2:

```text
terrain / paths / surfaces
-> groundStatic shadows V1 + V2
-> actorContact shadows selon système existant
-> placed element sprites
-> actors / player / NPC
-> occlusion patches
-> overlays / debug / HUD
```

Nuance importante:

- Le prompt proposait `actors -> actor contact shadows selon système existant`.
- Le code réel montre que le système existant dessine `actorContact` dans `_paintShadows()`, juste après `groundStatic`, donc avant sprites/entities.
- ShadowV2 building projected shadows ne changent pas cette politique.

Règle V2:

```text
Projected building shadows: groundStatic only, before placed element sprites.
```

## 16. Collection future séparée

ShadowV2-20 doit faire uniquement:

```text
ProjectedBuildingShadowGeometry synthétique
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeRenderInstruction
```

ShadowV2-20 ne doit pas faire:

- manifest traversal;
- lookup `projectedBuildingShadowCatalog`;
- lecture `ProjectElementEntry.projectedBuildingShadow`;
- lecture `ProjectManifest`;
- lecture de placements;
- intégration Selbrume;
- screenshot;
- renderer change.

Lot futur après V2-20:

```text
builder manifest/map:
- parcourt les éléments placés;
- récupère ProjectElementEntry.projectedBuildingShadow;
- lookup preset dans ProjectManifest.projectedBuildingShadowCatalog;
- skip disabled;
- skip ou diagnostique missing preset selon politique builder/diagnostics;
- appelle resolveProjectedBuildingShadowGeometry(...);
- appelle createProjectedBuildingShadowRuntimeInstruction(...);
- merge avec ShadowRuntimeInstructionCollection existante.
```

Il ne faut pas mélanger ces étapes.

## 17. Missing preset / diagnostics

Décision:

- L'adapter runtime ne gère jamais `missingPreset`.
- L'adapter ne voit pas `presetId`.
- L'adapter ne connaît pas le catalogue.
- L'adapter ne fait aucun fallback vers `genericProjection`.

Règle:

```text
geometry adapter receives valid geometry only.
missing preset belongs to diagnostics or future builder.
genericProjection is never a fallback for V2 projected building shadows.
```

## 18. Screenshot / visual gate policy

ShadowV2-20:

- Tests unitaires runtime seulement.
- Pas de screenshot.
- Pas de baseline.
- Pas de Selbrume.

À partir du premier lot qui touche renderer, collection builder runtime branchée, `PlayableMapGame`, Selbrume ou captures:

- screenshot harness obligatoire;
- baseline V2 séparée obligatoire;
- before/after obligatoire;
- rapport de comparaison obligatoire.

Evidence actuelle:

- Le README du harness indique qu'il est manuel, hors `test/`, reproductible, et non lancé par défaut.
- Le baseline manifest V1 `selbrume_shadow_v1` compte `staticInstructions: 10`, `contactLedge: 10`, `genericProjection: 0`, `captures: 11`.
- V2 ne doit pas modifier ce baseline.

## 19. Tests à prévoir pour ShadowV2-20

### Test 1 — Converts geometry to runtime instruction

Input:

```text
ProjectedBuildingShadowGeometry:
- 4 points: nearLeft, nearRight, farRight, farLeft
- opacity: 0.18
- colorHexRgb: 000000
```

Expected:

```text
ShadowRuntimeRenderInstruction:
- shape == ShadowRuntimeShapeKind.projectedPolygon
- renderPass == ShadowRenderPass.groundStatic
- polygonPoints preserved in order
- opacity == 0.18
- colorHexRgb == 000000
- worldLeft/worldTop/width/height equal computed bounds
- softnessMode == ShadowSoftnessMode.hardEdge
```

### Test 2 — Computes bounds from points

Input with non-zero and non-sorted coordinates.

Expected:

```text
worldLeft = minX
worldTop = minY
width = maxX - minX
height = maxY - minY
```

### Test 3 — Does not handle disabled

No disabled test in adapter. Disabled remains resolver responsibility.

### Test 4 — No renderer dependency

Static source audit test if local style allows file text checks:

```text
adapter source must not contain:
- dart:ui
- Canvas
- Flame
- flutter
- ShadowRuntimeRenderer
```

### Test 5 — No genericProjection dependency

Static source audit:

```text
adapter source must not contain:
- genericProjection
- static_shadow_family_projection
- resolveProjectedStaticShadowGeometry
- StaticShadowFamily
```

### Test 6 — Degenerate bounds behavior

If geometry points produce zero width or height, adapter should let `ShadowRuntimeRenderInstruction` validation throw `ValidationException`, or throw the same type with a clearer adapter message. Prefer relying on instruction validation unless implementation clarity suffers.

## 20. Fichiers proposés pour ShadowV2-20

Créer:

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

Modifier:

```text
none, sauf export éventuel si le package impose un barrel interne pour les tests.
```

Interdits pour ShadowV2-20:

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_element_entry.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
reports/shadows/baselines/**
```

Si un futur lot choisit Option C metadata:

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
packages/map_runtime/test/shadow/shadow_runtime_instruction_collection_test.dart
```

Mais ce n'est pas ShadowV2-20.

## 21. Roadmap après ShadowV2-19

Roadmap recommandée:

```text
ShadowV2-20 — Runtime Instruction Adapter V0
ShadowV2-21 — Runtime Collection Builder Design Gate
ShadowV2-22 — Runtime Collection Builder V0
ShadowV2-23 — Runtime Provider Integration Design Gate
ShadowV2-24 — One Building Runtime Visual POC
ShadowV2-25 — Screenshot Baseline V2
ShadowV2-26 — Editor Preview Design Gate
ShadowV2-27 — Editor Preview V0
```

Ajustement par rapport au prompt:

- Insérer un provider integration design gate avant le visual POC si le builder doit entrer dans `PlayableMapGame`.
- Garder screenshot/baseline pour le moment où un rendu réel est modifié ou branché.

## 22. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md ../AGENTS.md 2>/dev/null || true
rg -n "ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|resolveProjectedBuildingShadowGeometry|StaticShadowVisualMetrics" packages/map_core/lib/src packages/map_core/test/shadow_v2 reports/shadows/v2
rg -n "class ShadowRuntimeRenderInstruction|enum ShadowRuntimeShapeKind|ShadowRuntimeRenderInstruction\\(|projectedPolygon|ellipse|contact|points|renderPass|colorHexRgb|opacity" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "drawPath|drawOval|Path\\(|ShadowRuntimeShapeKind|paint|Canvas|opacity|colorHexRgb|projectedPolygon" packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow
rg -n "Runtime.*Shadow.*Collection|runtimeStatic|staticPlaced|actorContact|resolve.*Shadow|ShadowRuntimeRenderInstruction" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "groundStatic|actorContact|ShadowRenderPass|renderPass|MapLayersComponent|priority|render|children|add\\(" packages/map_runtime/lib/src packages/map_runtime/test
find packages/map_runtime/test/shadow packages/map_runtime/test/application -type f | sort
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 23. Résultats

Résultats principaux:

- Worktree initial propre.
- Tous les fichiers demandés sont présents.
- `ProjectedBuildingShadowGeometry` est pure et contient les données nécessaires à une instruction runtime.
- `ShadowRuntimeRenderInstruction` supporte déjà `projectedPolygon`.
- `ShadowRuntimeRenderer` dessine déjà `projectedPolygon`.
- `ShadowRuntimeInstructionCollection` trie déjà par `groundStatic` / `actorContact`.
- `MapLayersComponent` dessine les shadows après surfaces et avant sprites/entities.
- Le harness Selbrume est manuel et ne doit pas être lancé pour ShadowV2-20.

## 24. git diff --stat

Commande:

```bash
git diff --stat
```

Résultat après création de ce rapport:

```text
 ...d_building_shadow_runtime_instruction_design.md | 1052 ++++++++++----------
 1 file changed, 504 insertions(+), 548 deletions(-)
```

## 25. git diff --name-status

Commande:

```bash
git diff --name-status
```

Résultat après création de ce rapport:

```text
M	reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
```

## 26. git diff --check

Commande:

```bash
git diff --check
```

Résultat après création de ce rapport:

```text

```

Interprétation: aucun whitespace error détecté.

## 27. git status final

Commande:

```bash
git status --short --untracked-files=all
```

Résultat final:

```text
 M reports/shadows/v2/shadow_v2_19_projected_building_shadow_runtime_instruction_design.md
```

Interprétation: seul le rapport ShadowV2-19 est modifié.

## 28. Risques / réserves

- Option A ne distingue pas V1/V2 dans `ShadowRuntimeRenderInstruction`.
- Les screenshots actuels peuvent seulement montrer `shapeKind: projectedPolygon` tant qu'une metadata source n'existe pas.
- Le renderer applique les bandes d'opacité communes à tous les quadrilatères `projectedPolygon`; si V2 veut un rendu artistique différent, il faudra un nouveau design gate renderer.
- L'adapter devra calculer des bounds valides; les geometries dégénérées devront échouer proprement.
- Le futur builder ne doit pas réutiliser `runtime_static_placed_element_shadow_sources.dart` sans design, car ce fichier est aujourd'hui centré sur V1 `element.shadow` / `placed.shadowOverride`.

## 29. Auto-critique

La recommandation Option A est volontairement minimaliste. Elle optimise ShadowV2-20 pour une conversion pure et testable, mais elle reporte le debug source-level. Si l'équipe veut des captures ou inventaires qui séparent immédiatement `projectedBuildingV2` de V1, Option C devra être planifiée avant le builder ou avant les baselines V2.

Le point le plus important à surveiller est le futur collection builder: c'est là que le risque d'un fallback `genericProjection` peut revenir. Il faudra un design gate dédié avant de parcourir manifest/map.

## 30. Regard critique sur le prompt

Le prompt est très utile parce qu'il interdit explicitement les modifications dangereuses: renderer, runtime, editor, Selbrume, screenshots, generated files et commit.

Deux points à clarifier pour les prochains lots:

1. L'ordre demandé mentionne `actors -> actor contact shadows selon système existant`, mais le code existant dessine `actorContact` avant les actors. Le rapport tranche en faveur du code réel.
2. L'Evidence Pack demande des résultats `rg` très larges. Les commandes sont bonnes pour l'audit, mais les rapports devraient inclure les lignes structurantes plutôt que des milliers de matches non décisionnels. Ce rapport reproduit les résultats pertinents qui justifient les décisions.

## 31. Prompt proposé pour ShadowV2-20

```md
# ShadowV2-20 — Projected Building Shadow Runtime Instruction Adapter V0

Repo:

```text
/Users/karim/Project/pokemonProject
```

## Contrat

Implémenter uniquement l'adapter pur:

```text
ProjectedBuildingShadowGeometry -> ShadowRuntimeRenderInstruction
```

Ne pas modifier:

```text
ShadowRuntimeRenderInstruction
ShadowRuntimeRenderer
MapLayersComponent
PlayableMapGame
runtime_static_placed_element_shadow_collection.dart
runtime_static_placed_element_shadow_sources.dart
ProjectManifest
ProjectElementEntry
codecs
diagnostics
geometry V2
Selbrume
screenshots/baselines
generated files
```

Ne pas lancer `build_runner`.

## Décision ShadowV2-19 à respecter

```text
shape: ShadowRuntimeShapeKind.projectedPolygon
renderPass: ShadowRenderPass.groundStatic
adapter location: packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
input: ProjectedBuildingShadowGeometry only
no manifest traversal
no preset lookup
no genericProjection fallback
no renderer dependency
```

## Fichiers à créer

```text
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

## Adapter attendu

```dart
ShadowRuntimeRenderInstruction createProjectedBuildingShadowRuntimeInstruction(
  ProjectedBuildingShadowGeometry geometry,
)
```

Comportement:

```text
- convertit geometry.points en ShadowRuntimePoint en conservant l'ordre;
- fixe shape projectedPolygon;
- fixe renderPass groundStatic;
- propage opacity;
- propage colorHexRgb;
- calcule worldLeft/worldTop/width/height depuis les bounds des points;
- softnessMode hardEdge par défaut;
- ne connaît pas disabled;
- ne connaît pas missingPreset;
- ne mentionne pas genericProjection.
```

## Tests requis

```text
1. Converts geometry to projectedPolygon groundStatic instruction.
2. Preserves polygon point order.
3. Preserves opacity and colorHexRgb.
4. Computes bounds from unordered coordinate extents.
5. Does not import renderer/Canvas/Flame/Flutter.
6. Does not import or mention genericProjection/static shadow projection.
7. Degenerate bounds fail with ValidationException through runtime instruction validation.
```

## Commandes

```bash
cd /Users/karim/Project/pokemonProject
dart test packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
dart analyze packages/map_runtime
git diff --stat
git diff --name-status
git diff --check
```

## Rapport

Créer:

```text
reports/shadows/v2/shadow_v2_20_projected_building_shadow_runtime_instruction_adapter.md
```

Le rapport doit confirmer:

```text
- aucun renderer modifié;
- aucune collection modifiée;
- aucun Selbrume/screenshot/baseline;
- aucun fallback genericProjection;
- tests passés.
```
```
