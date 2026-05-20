# ShadowV2-17 — Projected Building Shadow Resolver / Runtime Preview Design Gate

## 1. Résumé exécutif

ShadowV2-17 est un design gate. Aucun code, runtime, editor, renderer, codec, diagnostic, modèle persistant, fichier Selbrume, generated file ou baseline screenshot n'a été modifié.

Décisions principales :

- resolver location : `map_core`, géométrie pure, avec adapters runtime/editor plus tard ;
- inputs V0 : `ProjectElementProjectedBuildingShadowConfig + ProjectBuildingShadowPreset + StaticShadowVisualMetrics` ;
- metrics : réutiliser `StaticShadowVisualMetrics` en V0 ;
- output : créer une géométrie pure V2 dédiée plutôt qu'une instruction runtime directe ;
- disabled behavior : resolver bas niveau retourne `null` si `config.enabled == false` ;
- followsSun V0 : accepté et traité comme `fixed`, avec diagnostic `followsSunWithoutTimeOfDay` déjà disponible ;
- render pass futur : `groundStatic`, avant sprites et actors, sans contact ledge automatique.

Le prochain lot recommandé est `ShadowV2-18 — Projected Building Shadow Core Geometry Resolver V0`.

## 2. Objectif du lot

Concevoir comment les données ShadowV2 persistées pourront devenir plus tard :

```text
données authorées
→ config résolue
→ géométrie projetée
→ instruction de rendu
→ preview editor / runtime
```

Ce lot ne crée pas cette chaîne. Il la spécifie pour éviter de réintroduire une projection automatique générique ou un couplage prématuré au runtime.

## 3. Rappel ShadowV2-16

ShadowV2-16 a créé une opération pure :

```dart
List<ProjectedBuildingShadowDiagnostic>
    diagnoseProjectedBuildingShadows(ProjectManifest manifest)
```

Diagnostics disponibles :

- `missingPreset` -> `error`
- `missingPresetForDisabledConfig` -> `warning`
- `unusedPreset` -> `warning`
- `v1AndV2Coexistence` -> `warning`
- `followsSunWithoutTimeOfDay` -> `info`

Ces diagnostics signalent les incohérences authoring. Ils ne corrigent rien, ne rendent rien et ne modifient pas les validators.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

L'état Git initial était propre.

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

Interprétation :

- ce lot est explicitement design-only ;
- aucune implémentation n'est prévue ;
- la conception est autorisée et attendue ;
- les compétences `using-superpowers`, `writing-plans`, `karpathy-guidelines` et `verification-before-completion` ont été consultées pour garder le lot borné et vérifiable.

## 6. Fichiers audités

ShadowV2 modèles / persistence / diagnostics :

- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart`

ShadowV2 codecs :

- `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart`

Shadow V1 core geometry / resolver :

- `packages/map_core/lib/src/operations/shadow_config_resolver.dart`
- `packages/map_core/lib/src/operations/static_shadow_geometry.dart`
- `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`
- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`

Runtime V1 :

- `packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart`

Editor preview V1 :

- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`

Harness screenshots :

- `packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart`
- `packages/map_runtime/tool/shadow/README.md`
- `reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json`

Rapports récents :

- `reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md`
- `reports/shadows/v2/shadow_v2_15_projected_building_shadow_semantic_diagnostics_design.md`
- `reports/shadows/v2/shadow_v2_16_projected_building_shadow_semantic_diagnostics.md`

Documentation Flame :

- recherche `flame_docs` sur `Flame render order component priority Canvas render method PositionComponent priority`
- recherche `flame_docs` sur `priority render order`
- recherche `flame_docs` sur `render method canvas`

Résultat Flame docs :

```text
No results found
```

Conséquence : les décisions runtime s'appuient sur les patterns locaux déjà testés dans `map_runtime`.

## 7. Audit V2 persistence / diagnostics

Commande :

```bash
rg -n "projectedBuildingShadowCatalog|projectedBuildingShadow|ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|diagnoseProjectedBuildingShadows" packages/map_core/lib/src packages/map_core/test reports/shadows/v2
```

Résultats pertinents :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:211:final class ProjectBuildingShadowPreset {
packages/map_core/lib/src/models/projected_building_shadow.dart:291:final class ProjectBuildingShadowPresetCatalog {
packages/map_core/lib/src/models/projected_building_shadow.dart:310:  ProjectBuildingShadowPreset? presetById(String id) {
packages/map_core/lib/src/models/projected_building_shadow.dart:374:final class ProjectElementProjectedBuildingShadowConfig {
packages/map_core/lib/src/models/project_manifest.dart:54:ProjectBuildingShadowPresetCatalog _projectedBuildingShadowCatalogFromJson(
packages/map_core/lib/src/models/project_manifest.dart:76:ProjectElementProjectedBuildingShadowConfig?
packages/map_core/lib/src/models/project_manifest.dart:182:    @Default(ProjectBuildingShadowPresetCatalog.empty())
packages/map_core/lib/src/models/project_manifest.dart:189:    ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:443:    ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:52:List<ProjectedBuildingShadowDiagnostic> diagnoseProjectedBuildingShadows(
```

Constats :

- les données V2 sont persistées dans `ProjectManifest` et `ProjectElementEntry` ;
- le catalogue a un lookup exact `presetById` ;
- les diagnostics traitent déjà les presets manquants et `followsSun` ;
- les modèles V2 restent purs et sans runtime.

## 8. Audit V1 resolver / geometry

Commande :

```bash
rg -n "StaticShadowVisualMetrics|resolveStaticShadowGeometry|resolveProjectedStaticShadowGeometry|ProjectedStaticShadow|StaticShadowProjectionSpec|ShadowRuntimeRenderInstruction|projectedPolygon|contactLedge" packages/map_core/lib/src packages/map_runtime/lib/src packages/map_core/test packages/map_runtime/test
```

Résultats pertinents :

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart:10:final class StaticShadowVisualMetrics {
packages/map_core/lib/src/operations/static_shadow_geometry.dart:207:ResolvedStaticShadowGeometry resolveStaticShadowGeometry({
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:84:final class StaticShadowProjectionSpec {
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:154:final class ProjectedStaticShadowGeometry {
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:194:ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart:14:ProjectedStaticShadowGeometry resolveBuildingStaticShadowContactLedgeGeometry({
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:132:ShadowRuntimeRenderInstruction?
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:164:  final projectedGeometry = resolveProjectedStaticShadowGeometry(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:174:  return ShadowRuntimeRenderInstruction(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:175:    shape: ShadowRuntimeShapeKind.projectedPolygon,
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart:8:  projectedPolygon,
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:38:  void _renderProjectedPolygon(
```

Constats :

- `StaticShadowVisualMetrics` est déjà une métrique pure `left/top/visualWidth/visualHeight` ;
- V1 a une géométrie projetée générique, mais elle dépend d'une base ellipse V1 ;
- V1 utilise `ProjectedStaticShadowGeometry` avec 4 points ;
- V1 building utilise une contact ledge dédiée, pas une grande ombre de bâtiment ;
- le runtime sait déjà dessiner `projectedPolygon`.

## 9. Audit runtime render path

Commande :

```bash
rg -n "groundStatic|actorContact|renderCollectionPass|ShadowRenderPass|drawPath|drawOval|MapLayersComponent|priority|render" packages/map_runtime/lib/src packages/map_runtime/test
```

Résultats pertinents :

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:335:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:338:      ShadowRenderPass.groundStatic,
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:340:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:343:      ShadowRenderPass.actorContact,
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:57:        groundStatic = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart:63:        actorContact = List<ShadowRuntimeRenderInstruction>.unmodifiable(
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:35:    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:44:            canvas.drawPath(path, paint);
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:4:  futureStaticPlacedElementShadows,
packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:5:  futureDynamicActorContactShadows,
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6553:    backgroundLayers.priority = 0;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6567:    foregroundLayers.priority = 100000;
```

Constats :

- les ombres runtime passent par `ShadowRuntimeInstructionCollection` ;
- le renderer rend `groundStatic` puis `actorContact` ;
- le rendu des ombres est dans le background `MapLayersComponent` ;
- le foreground layer a une priority plus haute et n'a pas le provider shadow ;
- les ombres sont actuellement avant sprites/actors dans l'ordre documenté.

## 10. Décision resolver location

Options comparées :

| Option | Décision | Raisons |
| --- | --- | --- |
| A. `map_core` pure geometry resolver | Retenue pour le resolver V0 | Pure Dart, testable, réutilisable editor/runtime, alignée avec `static_shadow_geometry.dart` |
| B. `map_runtime` resolver only | Rejetée pour V0 | Couplerait trop tôt la résolution au rendu Flame |
| C. split core geometry + runtime adapter | Retenue comme architecture complète | Core géométrie en V2-18, adapter runtime plus tard, preview editor plus tard |

Décision :

```text
ShadowV2-18 doit créer uniquement une géométrie pure dans map_core.
Le runtime et l'editor consommeront cette géométrie via des adapters ultérieurs.
```

Fichier probable :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
```

## 11. Décision inputs

Options comparées :

| Option | Décision | Raisons |
| --- | --- | --- |
| A. bas niveau `config + preset + metrics` | Retenue | Simple, pure, testable, aucune lookup dans la géométrie |
| B. haut niveau `manifest + element + placement` | Rejetée pour V0 | Mélange lookup, diagnostics, placement et géométrie |

Signature recommandée pour V2-18 :

```dart
ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
})
```

Le lookup `presetId -> preset` reste hors de cette fonction.

## 12. Décision metrics

Options comparées :

| Option | Décision | Raisons |
| --- | --- | --- |
| Réutiliser `StaticShadowVisualMetrics` | Retenue | Déjà pure, validée, exactement `left/top/visualWidth/visualHeight` |
| Créer `ProjectedBuildingShadowVisualMetrics` | Non retenue en V0 | Duplication de structure sans valeur immédiate |

Décision :

```text
V2-18 réutilise StaticShadowVisualMetrics.
```

Justification :

- les métriques sont déjà génériques malgré leur nom ;
- elles ne dépendent pas de V1 shadow config ;
- elles sont utilisables côté editor et runtime ;
- elles évitent un nouveau modèle miroir.

## 13. Décision output geometry

Options comparées :

| Option | Décision | Raisons |
| --- | --- | --- |
| Nouveau `ProjectedBuildingShadowGeometry` | Retenue | Nom métier clair, porte appearance, évite confusion V1 |
| Réutiliser `ProjectedStaticShadowGeometry` directement | Non retenue comme output public V2 | Utile comme inspiration, mais le nom V1/static est ambigu |
| Retourner `ShadowRuntimeRenderInstruction` | Rejetée | Couplerait `map_core` au runtime |

Types recommandés pour V2-18 :

```dart
final class ProjectedBuildingShadowPoint {
  final double x;
  final double y;
}

final class ProjectedBuildingShadowGeometry {
  final ProjectedBuildingShadowPoint nearLeft;
  final ProjectedBuildingShadowPoint nearRight;
  final ProjectedBuildingShadowPoint farRight;
  final ProjectedBuildingShadowPoint farLeft;
  final double opacity;
  final String colorHexRgb;

  List<ProjectedBuildingShadowPoint> get points;
}
```

La géométrie doit être pure, validée, à égalité de valeur, et sans JSON.

## 14. Géométrie paramétrique proposée

Inputs :

```text
config.anchor
config.localOffset
preset.direction.normalized
preset.shape
preset.appearance
metrics.left
metrics.top
metrics.visualWidth
metrics.visualHeight
```

Formule V0 recommandée :

```text
dir = preset.direction.normalized
perp = (-dir.y, dir.x)

anchorWorldX = metrics.left
             + metrics.visualWidth * config.anchor.xRatio
             + config.localOffset.x

anchorWorldY = metrics.top
             + metrics.visualHeight * config.anchor.yRatio
             + config.localOffset.y

length = metrics.visualHeight * preset.shape.lengthRatio
nearWidth = metrics.visualWidth * preset.shape.nearWidthRatio
farWidth = metrics.visualWidth * preset.shape.farWidthRatio

farCenterX = anchorWorldX + dir.x * length
farCenterY = anchorWorldY + dir.y * length

nearLeft = anchor - perp * nearWidth / 2
nearRight = anchor + perp * nearWidth / 2
farRight = farCenter + perp * farWidth / 2
farLeft = farCenter - perp * farWidth / 2
```

Décisions associées :

- `length` basé sur `visualHeight`, car la hauteur du bâtiment exprime mieux la longueur projetée ;
- `nearWidth` et `farWidth` basées sur `visualWidth`, car l'ombre au sol doit lire la largeur du bâtiment ;
- `localOffset` exprimé en unités monde, comme les offsets V1 déjà utilisés par les shadows ;
- direction toujours normalisée au moment de calculer la projection ;
- l'ancrage recommandé authoring reste proche du pied du bâtiment, souvent `xRatio: 0.5`, `yRatio: 0.98` ou `1.0`.

Exemple numérique recommandé pour test V2-18 :

```text
metrics: left=10, top=20, visualWidth=100, visualHeight=80
anchor: xRatio=0.5, yRatio=1.0
offset: x=0, y=0
direction: x=1, y=0
lengthRatio=0.5
nearWidthRatio=1.0
farWidthRatio=0.5

anchor = (60, 100)
length = 40
nearWidth = 100
farWidth = 50
perp = (0, 1)

nearLeft = (60, 50)
nearRight = (60, 150)
farRight = (100, 125)
farLeft = (100, 75)
```

Cette orientation produit une polygon area positive avec l'ordre `nearLeft, nearRight, farRight, farLeft`.

## 15. Time-of-day V0 behavior

Décision :

```text
V0 accepte followsSun mais le traite comme fixed.
```

Raisons :

- `ProjectedShadowTimeOfDayMode.followsSun` existe déjà comme intention authoring ;
- aucun système jour/nuit actif n'existe encore pour piloter une direction runtime ;
- refuser `followsSun` bloquerait les projets qui préparent déjà ce mode ;
- le diagnostic `followsSunWithoutTimeOfDay` signale déjà que le comportement est provisoire.

Comportement V0 :

```text
fixed -> utiliser preset.direction
followsSun -> utiliser preset.direction aussi
```

## 16. Missing preset behavior

Décision :

```text
Le resolver bas niveau ne traite pas missing preset.
```

Raisons :

- il reçoit déjà un `ProjectBuildingShadowPreset` non-null ;
- la recherche dans le catalogue est une responsabilité du caller ou d'un futur collection builder ;
- les diagnostics détectent déjà les références manquantes.

Comportement futur du builder haut niveau :

```text
si preset absent -> skip instruction + diagnostic existant
aucun fallback vers genericProjection
aucune création de preset par défaut
```

## 17. Disabled config behavior

Décision :

```text
resolver retourne null si config.enabled == false.
```

Raisons :

- sécurité locale ;
- évite de dépendre uniquement de la discipline du caller ;
- rend le comportement testable ;
- respecte l'intention authoring disabled.

Le caller peut aussi éviter d'appeler le resolver, mais le resolver doit rester défensif.

## 18. V1 coexistence behavior

Décision :

```text
Le resolver V2 ne connaît pas Shadow V1.
```

Il ne doit pas inspecter :

- `element.shadow`
- `ProjectElementShadowConfig`
- `StaticShadowFamily`
- `resolveShadowConfig`

La coexistence V1/V2 est un sujet de diagnostics authoring, pas de géométrie V2.

## 19. Runtime instruction future

Options comparées :

| Option | Décision | Raisons |
| --- | --- | --- |
| Réutiliser `ShadowRuntimeShapeKind.projectedPolygon` | Probable pour premier POC runtime | Le renderer sait déjà dessiner un polygon 4 points avec bandes d'opacité |
| Nouveau shape `buildingProjectedPolygon` | À réserver si le debug/source tracking l'exige | Séparation claire, mais plus de renderer/test churn |
| Instruction runtime directe depuis `map_core` | Rejetée | Brise les frontières de package |

Décision ShadowV2-17 :

```text
Ne pas décider définitivement le shape runtime dans V2-18.
Le core V2 retourne une géométrie pure.
Le futur design gate runtime devra choisir entre projectedPolygon réutilisé et shape spécifique.
```

Recommandation provisoire :

```text
Réutiliser projectedPolygon pour le premier POC runtime,
mais ajouter une source/debug metadata seulement si un futur lot en a besoin.
```

## 20. Render pass / ordering future

Décision recommandée :

```text
Les ombres projetées de bâtiments V2 appartiennent au pass groundStatic.
```

Raisons :

- elles sont au sol ;
- elles doivent apparaître après terrain/path/surface ;
- elles doivent être avant sprites, actors et occlusion patches ;
- elles ne sont pas des actor contact shadows ;
- elles ne doivent pas créer de pass runtime tant qu'un pass existant suffit.

Interaction contact ledge :

- V2 building projected shadow ne doit pas créer automatiquement de contact ledge ;
- contact ledge V1 reste distinct ;
- si V1+V2 coexistent, le diagnostic `v1AndV2Coexistence` signale le risque de double ombre ;
- le futur runtime builder ne doit pas résoudre V1 dans le resolver V2.

## 21. Editor preview future

Décisions :

- l'editor preview doit utiliser la même géométrie core que le runtime ;
- aucune duplication de formule côté editor ;
- la preview doit être disponible avant sauvegarde dans un futur lot editor ;
- le painter peut réutiliser le pattern V1 `projectedPolygon` + opacity bands ;
- la conversion geometry -> preview instruction doit vivre côté editor, pas dans `map_core`.

Lots futurs possibles :

```text
ShadowV2-21 — Editor Preview Design Gate
ShadowV2-22 — Editor Preview POC One Building
```

## 22. Tests à prévoir pour ShadowV2-18

Tests exacts recommandés :

1. Disabled config

```text
enabled false -> null geometry
```

2. Basic geometry

```text
metrics 100x80
anchor 0.5/1.0
offset 0/0
direction 1/0
lengthRatio 0.5
nearWidthRatio 1.0
farWidthRatio 0.5
-> nearLeft (60,50), nearRight (60,150), farRight (100,125), farLeft (100,75)
```

3. Direction normalization

```text
direction 2/0 produit les mêmes points que direction 1/0
```

4. Offset

```text
localOffset x/y décale l'anchor et tous les points
```

5. Width / length ratios

```text
nearWidthRatio, farWidthRatio et lengthRatio changent les points attendus
```

6. Appearance propagation

```text
opacity et colorHexRgb sont transmis dans la geometry
```

7. followsSun V0

```text
timeOfDayMode followsSun utilise preset.direction comme fixed
```

8. No V1 dependency

```text
fichier projeté n'importe pas shadow.dart, shadow_config_resolver.dart, map_runtime ou map_editor
```

9. Geometry validation

```text
points finite
polygon non dégénéré
points list unmodifiable
égalité de valeur
```

## 23. Fichiers proposés pour ShadowV2-18

Créer :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md
```

Modifier éventuellement :

```text
packages/map_core/lib/map_core.dart
```

si les opérations pure geometry sont exportées publiquement, comme les opérations shadow V1.

Fichiers interdits pour ShadowV2-18 :

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/project_json_migrations.dart
packages/map_core/lib/src/operations/*json_codec*.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

## 24. Roadmap après ShadowV2-17

Roadmap recommandée :

```text
ShadowV2-18 — Projected Building Shadow Core Geometry Resolver V0
ShadowV2-19 — Runtime Instruction Design Gate
ShadowV2-20 — Runtime Instruction POC One Building
ShadowV2-21 — Editor Preview Design Gate
ShadowV2-22 — Editor Preview POC One Building
ShadowV2-23 — Selbrume One Building Authoring Fixture / Visual Gate
```

Pourquoi cet ordre :

- la géométrie pure doit être testée avant runtime ;
- le runtime doit être design-gaté avant de toucher au renderer ;
- l'editor preview doit partager la géométrie core ;
- Selbrume ne doit être modifié qu'après une visual gate explicite.

## 25. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "projectedBuildingShadowCatalog|projectedBuildingShadow|ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|diagnoseProjectedBuildingShadows" packages/map_core/lib/src packages/map_core/test reports/shadows/v2
rg -n "StaticShadowVisualMetrics|resolveStaticShadowGeometry|resolveProjectedStaticShadowGeometry|ProjectedStaticShadow|StaticShadowProjectionSpec|ShadowRuntimeRenderInstruction|projectedPolygon|contactLedge" packages/map_core/lib/src packages/map_runtime/lib/src packages/map_core/test packages/map_runtime/test
rg -n "groundStatic|actorContact|renderCollectionPass|ShadowRenderPass|drawPath|drawOval|MapLayersComponent|priority|render" packages/map_runtime/lib/src packages/map_runtime/test
rg -n "EditorStaticShadowPreview|paintEditorStaticShadowPreview|ShadowPreview|projectedPolygon|drawPath|drawOval" packages/map_editor/lib/src packages/map_editor/test
ls packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart packages/map_runtime/tool/shadow/README.md reports/shadows/baselines/selbrume_shadow_v1/baseline_manifest.json
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Documentation Flame :

```text
flame_docs search: Flame render order component priority Canvas render method PositionComponent priority
flame_docs search: priority render order
flame_docs search: render method canvas
```

## 26. Résultats

Synthèse des résultats :

- V2 persistence et diagnostics existent dans `map_core`.
- V1 core dispose déjà de métriques visuelles, geometry projetée et tests.
- Runtime dispose déjà de `ShadowRuntimeShapeKind.projectedPolygon`.
- Runtime groupe les instructions par `groundStatic` et `actorContact`.
- `MapLayersComponent` rend les ombres dans le background pass.
- Editor preview V1 a déjà un modèle/painter `projectedPolygon`.
- Harness Selbrume existe et doit rester manuel pour les lots visuels.
- `flame_docs` n'a pas fourni de résultat utile sur les recherches demandées ; les décisions runtime restent basées sur les patterns locaux.

## 27. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text
```

Après création du rapport, `git diff --stat` reste vide car le rapport est un fichier non suivi.

## 28. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie avant création du rapport :

```text
```

Après création du rapport, `git diff --name-status` reste vide car le rapport est un fichier non suivi.

## 29. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 30. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md
```

## 31. Risques / réserves

- Réutiliser `StaticShadowVisualMetrics` garde un nom V1, mais évite une duplication immédiate. Si le nom devient confus dans l'API publique, un alias ou modèle V2 pourra être introduit plus tard.
- Créer une géométrie V2 dédiée duplique partiellement `ProjectedStaticShadowGeometry`, mais clarifie le contrat métier et permet de porter `opacity/colorHexRgb`.
- `followsSun` traité comme fixed en V0 peut surprendre si utilisé sans lire les diagnostics ; c'est acceptable tant que le diagnostic info reste visible côté authoring.
- Le choix runtime final entre `projectedPolygon` réutilisé et shape spécifique doit rester ouvert jusqu'au design gate runtime.

## 32. Auto-critique

Le design privilégie une séparation nette :

- core geometry pure maintenant ;
- runtime adapter plus tard ;
- editor preview plus tard.

C'est plus lent qu'un POC direct dans le renderer, mais c'est cohérent avec la règle du lot : pas de rendu, pas de devinette, pas de retour de genericProjection.

## 33. Regard critique sur le prompt

Le prompt borne correctement le danger principal : ne pas écrire un `drawPath` opportuniste. Il force aussi à regarder V1, ce qui évite de réinventer la géométrie et le render pass.

Le seul point à surveiller est le mot "preview" dans le titre : ici il signifie design de preview future, pas implémentation editor.

## 34. Prompt proposé pour ShadowV2-18

````md
# ShadowV2-18 — Projected Building Shadow Core Geometry Resolver V0

Tu travailles dans `/Users/karim/Project/pokemonProject`.

Contrat :
- créer uniquement une géométrie pure ShadowV2 dans `map_core` ;
- ne pas modifier ProjectManifest ;
- ne pas modifier ProjectElementEntry ;
- ne pas modifier les codecs JSON ;
- ne pas modifier les diagnostics ;
- ne pas modifier le runtime ;
- ne pas modifier l'éditeur ;
- ne pas modifier Selbrume ;
- ne pas lancer build_runner ;
- ne pas créer de generated files ;
- ne pas faire de commit.

Créer :
- `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart`
- `reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md`

Modifier éventuellement :
- `packages/map_core/lib/map_core.dart` si les opérations geometry sont exportées publiquement selon les conventions.

API recommandée :

```dart
ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
})
```

Types recommandés :

```dart
final class ProjectedBuildingShadowPoint {
  final double x;
  final double y;
}

final class ProjectedBuildingShadowGeometry {
  final ProjectedBuildingShadowPoint nearLeft;
  final ProjectedBuildingShadowPoint nearRight;
  final ProjectedBuildingShadowPoint farRight;
  final ProjectedBuildingShadowPoint farLeft;
  final double opacity;
  final String colorHexRgb;
  List<ProjectedBuildingShadowPoint> get points;
}
```

Formule :

```text
dir = preset.direction.normalized
perp = (-dir.y, dir.x)
anchorWorldX = metrics.left + metrics.visualWidth * config.anchor.xRatio + config.localOffset.x
anchorWorldY = metrics.top + metrics.visualHeight * config.anchor.yRatio + config.localOffset.y
length = metrics.visualHeight * preset.shape.lengthRatio
nearWidth = metrics.visualWidth * preset.shape.nearWidthRatio
farWidth = metrics.visualWidth * preset.shape.farWidthRatio
farCenter = anchor + dir * length
nearLeft = anchor - perp * nearWidth / 2
nearRight = anchor + perp * nearWidth / 2
farRight = farCenter + perp * farWidth / 2
farLeft = farCenter - perp * farWidth / 2
```

Comportements :
- `enabled false -> null`
- `followsSun -> utiliser direction du preset comme fixed en V0`
- missing preset hors scope car le resolver reçoit déjà un preset non-null
- aucune dépendance Shadow V1 dans le resolver V2
- aucune instruction runtime

Tests obligatoires :
- disabled config returns null
- geometry basic deterministic case
- direction normalization
- localOffset shifts all points
- ratios alter length/width
- appearance propagation
- followsSun behaves as fixed
- geometry value equality/hashCode
- points unmodifiable
- no runtime/editor imports

Commandes :
- `git status --short --untracked-files=all`
- `dart test test/shadow_v2/projected_building_shadow_geometry_test.dart`
- `dart test test/shadow_v2`
- `dart analyze lib/src/operations/projected_building_shadow_geometry.dart test/shadow_v2/projected_building_shadow_geometry_test.dart`
- `git diff --stat`
- `git diff --name-status`
- `git diff --check`
- `git status --short --untracked-files=all`
````

## Inventaire fichiers

Créés par ShadowV2-17 :

- `reports/shadows/v2/shadow_v2_17_projected_building_shadow_resolver_runtime_preview_design.md`

Modifiés par ShadowV2-17 :

- Aucun fichier de code.

Supprimés par ShadowV2-17 :

- Aucun.

Generated files :

- Aucun.

Fichiers Selbrume :

- Aucun fichier Selbrume modifié.
