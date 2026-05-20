# ShadowV2-29 — Existing V1 Ugly Shadow Source Audit / Suppression Design Gate

## 1. Résumé exécutif

ShadowV2-29 est resté design-only / audit-only.

Conclusion principale :

- les ombres V1 existent encore comme données persistées dans `ProjectElementEntry.shadow` et `MapPlacedElement.shadowOverride` ;
- le runtime V1 consomme `element.shadow` et `placed.shadowOverride` via `buildRuntimeStaticPlacedElementShadowSources(...)`, puis génère des `projectedPolygon` ou des contact ledges ;
- l'éditeur V1 consomme les mêmes données via `buildEditorStaticShadowPreviewInstructions(...)` ;
- ShadowV2 est mergé avant V1 côté runtime et peint avant V1 côté editor, donc V1 peut encore s'afficher quand V2 existe ;
- aucune règle actuelle ne dit "V2 masque V1" ;
- dans Selbrume lu en lecture seule, `projectedBuildingShadow` est absent, `shadowOverride` non-null est absent, `genericProjection` est absent, mais 20 éléments portent encore une config `shadow` V1 et 11 placements référencent des éléments avec V1 active.

Source la plus probable des ombres moches visibles dans le projet réel Selbrume :

```text
ProjectElementEntry.shadow V1 déjà persisté,
résolu par la preview editor V1 et par le runtime static placed V1.
```

Niveau de confiance : fort pour les ombres générées par le moteur ; moyen pour l'image fournie, car une ombre déjà peinte dans le PNG reste possible tant qu'un test comparatif asset/rendu sans shadow n'a pas été fait.

Option recommandée :

```text
V2 active masque la shadow V1 static placed du même élément / placement,
côté runtime et côté editor preview,
sans supprimer les données,
et sans couper les petites ombres V1 des éléments qui n'ont pas de V2.
```

Lot 30 recommandé :

```text
ShadowV2-30 — V2 Suppresses Same-Element Legacy Static Shadow V0
```

## 2. Objectif du lot

Objectif : identifier pourquoi les anciennes ombres V1 restent visibles et proposer une stratégie de neutralisation sans implémenter.

Question concrète :

```text
Quand une ombre ancienne apparaît sous/autour d'un bâtiment,
d'où vient-elle exactement ?
```

Réponse courte :

```text
Elle vient du chemin V1 static placed shadows quand le bâtiment possède
ProjectElementEntry.shadow ou quand un placement possède shadowOverride.
Dans Selbrume, les placements n'ont pas de shadowOverride non-null ;
la source constatée est donc ProjectElementEntry.shadow.
```

## 3. Rappel ShadowV2-24 à ShadowV2-28

ShadowV2-24 a branché le runtime :

```text
ProjectManifest + MapData
-> buildRuntimeProjectedBuildingShadowCollection(...)
-> PlayableMapGame
-> merge V2 + V1 + actorContact
-> MapLayersComponent
-> ShadowRuntimeRenderer
```

ShadowV2-26 a prouvé le rendu pixel runtime :

```text
provider PlayableMapGame
-> collection V2 projectedPolygon groundStatic
-> ShadowRuntimeRenderer.renderCollectionPass(...)
-> pixels alpha > 0
```

ShadowV2-28 a branché la preview editor :

```text
ProjectManifest + MapData + tileWidth/tileHeight
-> buildEditorProjectedBuildingShadowPreviewInstructions(...)
-> EditorStaticShadowPreviewInstruction
-> MapGridPainter
-> Canvas editor
```

Ce qui reste ouvert : V1 existe encore et peut se superposer à V2.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
Aucune ligne.
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Résultat `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Résultat `rg` :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

- ce lot est précisément un design gate ;
- aucune implémentation n'est autorisée ;
- la création du rapport Markdown est conforme au périmètre.

## 6. Fichiers audités

Audités côté `map_core` :

- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/operations/static_shadow_family_projection.dart`
- `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`
- `packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart`
- `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`
- tests Shadow V1 et ShadowV2 diagnostics sous `packages/map_core/test`

Audités côté `map_runtime` :

- `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart`
- `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart`
- `packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- tests shadow runtime sous `packages/map_runtime/test/shadow`

Audités côté `map_editor` :

- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`
- tests shadow editor sous `packages/map_editor/test`

Audités côté données réelles en lecture seule :

- `/Users/karim/Desktop/selbrume/project.json`
- `/Users/karim/Desktop/selbrume/maps/Selbrume.json`

Fichiers créés par ce lot :

```text
reports/shadows/v2/shadow_v2_29_existing_v1_ugly_shadow_source_audit_suppression_design.md
```

Fichiers modifiés par ce lot :

```text
Aucun.
```

Fichiers supprimés par ce lot :

```text
Aucun.
```

## 7. Audit modèles Shadow V1 map_core

Commande :

```bash
rg -n "ProjectShadow|ProjectShadowCatalog|ProjectShadowProfile|ProjectElementShadowConfig|MapPlacedElementShadowOverride|ShadowCasterMode|StaticShadowFamily|genericProjection|contactBlob|ellipse|castsShadow|shadowProfileId|shadowOverride|shadow:" packages/map_core/lib packages/map_core/test
```

Constats précis :

- `ShadowCasterMode` existe dans `packages/map_core/lib/src/models/shadow.dart` avec `none`, `contactBlob`, `ellipse`.
- `StaticShadowFamily` existe avec `genericProjection`, `compactProp`, `tallProp`, `building`, `foliage`.
- `ProjectShadowProfile` définit le profil V1 : `mode`, `renderPass`, `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity`, `colorHexRgb`.
- `ProjectElementShadowConfig` est la config V1 persistée sur `ProjectElementEntry.shadow`.
- `ProjectElementShadowConfig.castsShadow == true` exige `shadowProfileId`.
- `MapPlacedElementShadowOverride` est la config V1 persistée sur `MapPlacedElement.shadowOverride`.
- `ShadowOverrideMode.disabled` existe et permet de couper la shadow V1 d'un placement.
- `ProjectManifest.shadowCatalog` porte le catalogue V1.
- `ProjectElementEntry.shadow` et `ProjectElementEntry.projectedBuildingShadow` peuvent coexister.
- `MapPlacedElement.shadowOverride` est présent dans `MapData`.

Extraits utiles :

```text
packages/map_core/lib/src/models/shadow.dart:6:enum ShadowCasterMode {
packages/map_core/lib/src/models/shadow.dart:11:  contactBlob,
packages/map_core/lib/src/models/shadow.dart:14:  ellipse,
packages/map_core/lib/src/models/shadow.dart:44:enum StaticShadowFamily {
packages/map_core/lib/src/models/shadow.dart:45:  genericProjection,
packages/map_core/lib/src/models/shadow.dart:179:final class ProjectElementShadowConfig {
packages/map_core/lib/src/models/shadow.dart:181:    this.castsShadow = false,
packages/map_core/lib/src/models/shadow.dart:182:    this.shadowProfileId,
packages/map_core/lib/src/models/shadow.dart:257:final class MapPlacedElementShadowOverride {
packages/map_core/lib/src/models/project_manifest.dart:179:    ProjectShadowCatalog shadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:436:    ProjectElementShadowConfig? shadow,
packages/map_core/lib/src/models/map_data.dart:110:    MapPlacedElementShadowOverride? shadowOverride,
```

Valeurs produisant les ombres à risque :

- `StaticShadowFamily.genericProjection` utilise la projection V1 de base ;
- `StaticShadowFamily.compactProp`, `tallProp`, `foliage` utilisent aussi une projection V1, mais calibrée ;
- `StaticShadowFamily.building` évite la projection longue et passe par un contact ledge ;
- `ShadowCasterMode.ellipse` et `contactBlob` sont tous deux acceptés par le resolver static placed V1, puis transformés en polygone statique sauf cas `building`.

Valeurs utiles à conserver :

- `ShadowCasterMode.contactBlob` et certains `ellipse` locaux peuvent rester utiles pour de petits props ;
- `StaticShadowFamily.building` produit des contact ledges courts, mais reste une shadow V1 et peut visuellement entrer en conflit avec ShadowV2.

## 8. Audit auto-policy V1 / genericProjection

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject|ElementAutoShadow|autoShadow|genericProjection|StaticShadowFamily|castsShadow|shadowProfileId" packages/map_core/lib packages/map_core/test reports/shadows
```

Constats :

- `applyElementAutoShadowPolicyToProject(...)` existe dans `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`.
- L'éditeur expose `applyElementAutoShadowSuggestionsToProject(...)` dans `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`.
- `EditorNotifier.applyElementAutoShadowSuggestions()` peut appeler cette policy via un use case editor.
- Le runtime ne l'appelle pas.
- Le test runtime `load_runtime_map_bundle_shadow_policy_test.dart` verrouille que le chargement runtime conserve les shadows existantes comme données authorées, sans les appliquer automatiquement.
- La policy a historiquement pu écrire des `ProjectElementEntry.shadow` persistés.
- La version actuelle ne considère que `buildingLarge` comme artistiquement safe dans `_autoShadowKindIsArtisticallySafe(...)`.
- Les anciennes configs reconnues incluent encore un `_oldAutoDefaultPropShadow()` en `StaticShadowFamily.genericProjection`.

Extraits utiles :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:468:  Future<void> applyElementAutoShadowSuggestions() async {
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart:15:    test('keeps missing shadow configs absent at runtime load', () async {
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart:38:    test('preserves recognized old auto shadows as authored data', () async {
```

Lecture du code :

```text
_autoShadowKindIsArtisticallySafe(buildingLarge) => true
_autoShadowKindIsArtisticallySafe(tallThin/wideLow/smallSquare/defaultProp) => false
```

Conclusion :

- l'auto-policy n'est pas une génération runtime ;
- elle peut être une source historique de données V1 persistées ;
- elle reste un risque si l'utilisateur relance explicitement l'action editor ;
- elle ne doit pas être utilisée pour ShadowV2.

## 9. Audit runtime V1 static placed shadows

Commande :

```bash
rg -n "buildRuntimeStaticPlacedElementShadow|runtime_static_placed_element_shadow|StaticPlacedElementShadow|staticShadow|element.shadow|placed.shadowOverride|ProjectElementShadowConfig|MapPlacedElementShadowOverride|genericProjection|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|ShadowRuntimeRenderer|groundStatic" packages/map_runtime/lib packages/map_runtime/test
```

Constats :

- `buildRuntimeStaticPlacedElementShadowSources(...)` parcourt `bundle.map.placedElements`.
- Il filtre les `TileLayer` invisibles ou transparentes.
- Il lit `element.shadow`.
- Il lit `placed.shadowOverride`.
- Il calcule les metrics depuis `placed.pos`, `bundle.cellWidth`, `bundle.cellHeight` et la source de frame.
- Il transmet `element.shadow?.family` et `placed.shadowOverride?.family`.
- `buildRuntimeStaticPlacedElementShadowCollection(...)` appelle `resolveShadowConfig(...)`, puis construit un `StaticPlacedElementShadowRuntimeInput`.
- `resolveStaticPlacedElementShadowRuntimeInstruction(...)` refuse tout pass différent de `groundStatic`.
- Pour `StaticShadowFamily.building`, il appelle `resolveBuildingStaticShadowContactLedgeGeometry(...)`.
- Sinon il appelle `resolveProjectedStaticShadowGeometry(...)` avec `resolveStaticShadowFamilyProjectionSpec(...)`.
- La shape produite est `ShadowRuntimeShapeKind.projectedPolygon`.

Extraits utiles :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:48:      RuntimeStaticPlacedElementShadowSource(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:51:        elementShadow: element.shadow,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart:52:        placedOverride: placed.shadowOverride,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:43:    final resolution = resolveShadowConfig(
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:45:      elementShadow: source.elementShadow,
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:46:      placedOverride: source.placedOverride,
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:154:  final family = resolveStaticShadowFamily(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:158:  if (family == StaticShadowFamily.building) {
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:164:  final projectedGeometry = resolveProjectedStaticShadowGeometry(
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:167:    projectionSpec: resolveStaticShadowFamilyProjectionSpec(
```

Conclusion :

```text
V1 continue à produire des instructions runtime même si le même élément possède une ShadowV2.
```

## 10. Audit PlayableMapGame merge V1/V2

Commande :

```bash
rg -n "_projectedBuildingShadowCollectionByMapId|_staticShadowCollectionByMapId|_provideShadowCollectionForMap|mergeShadowRuntimeInstructionCollections|enableStaticPlacedElementShadows|enableActorContactShadows" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow
```

Extraits utiles :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:192:      _projectedBuildingShadowCollectionByMapId =
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:195:      _staticShadowCollectionByMapId =
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1677:  ShadowRuntimeInstructionCollection? _provideShadowCollectionForMap(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1683:          _projectedBuildingShadowCollectionByMapId[mapId];
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1688:      final staticCollection = _staticShadowCollectionByMapId[mapId];
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1702:    return mergeShadowRuntimeInstructionCollections(collections);
```

Ordre actuel :

```text
1. V2 projected building shadow collection
2. V1 static placed element shadow collection
3. actor contact shadow collection
```

Effets des flags :

- `enableStaticPlacedElementShadows == false` coupe V2 projected building et V1 static placed ;
- `enableActorContactShadows == false` coupe actor contact ;
- `shadowCollectionProvider` externe reste prioritaire.

Absence actuelle :

```text
Aucune règle ne supprime V1 quand V2 est active sur le même élément.
```

Risque :

```text
Comme V2 est mergé avant V1, V1 peut être rendu après V2 dans le même pass groundStatic,
donc assombrir, doubler ou contredire l'ombre V2.
```

## 11. Audit editor V1 static shadow preview

Commande :

```bash
rg -n "EditorStaticShadowPreview|buildEditorStaticShadowPreviewInstructions|paintEditorStaticShadowPreviewInstructions|editor_static_shadow_preview|shadowOverride|element.shadow|genericProjection|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|contactBlob|ellipse|projectedPolygon" packages/map_editor/lib packages/map_editor/test
```

Constats :

- `EditorStaticShadowPreviewInstruction` supporte `oval` et `projectedPolygon`.
- `buildEditorStaticShadowPreviewInstructions(...)` construit la preview V1 depuis `manifest`, `map`, `tileWidth`, `tileHeight`.
- Il lit `element.shadow` et `placed.shadowOverride`.
- Il appelle `resolveShadowConfig(...)`.
- Il appelle `resolveStaticShadowFamily(...)`.
- Pour `StaticShadowFamily.building`, il appelle `resolveBuildingStaticShadowContactLedgeGeometry(...)`.
- Sinon, il appelle `resolveProjectedStaticShadowGeometry(...)` et `resolveStaticShadowFamilyProjectionSpec(...)`.
- `paintEditorStaticShadowPreviewInstructions(...)` peint `projectedPolygon` avec les bandes d'opacité existantes.

Extraits utiles :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:111:List<EditorStaticShadowPreviewInstruction>
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:156:      elementShadow: element.shadow,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:157:      placedOverride: placed.shadowOverride,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:183:      elementFamily: element.shadow?.family,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:184:      overrideFamily: placed.shadowOverride?.family,
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:191:        : resolveProjectedStaticShadowGeometry(
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart:194:            projectionSpec: resolveStaticShadowFamilyProjectionSpec(
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart:38:      case EditorStaticShadowPreviewShapeKind.projectedPolygon:
```

Conclusion :

```text
La preview editor V1 reste active et peut produire les mêmes ombres que le runtime V1.
```

## 12. Audit canvas editor V1/V2 order

Commande :

```bash
rg -n "projectedBuildingShadowPreviewInstructions|staticShadowPreviewInstructions|paintEditorStaticShadowPreviewInstructions|placed elements|_paintPlacedElement|MapGridPainter|paint\\(" packages/map_editor/lib/src/ui/canvas packages/map_editor/test/map_grid_painter_test.dart
```

Extraits utiles :

```text
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:273:    final projectedBuildingShadowPreviewInstructions = projectContext == null
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:281:    final staticShadowPreviewInstructions = projectContext == null
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:335:    paintEditorStaticShadowPreviewInstructions(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:337:      projectedBuildingShadowPreviewInstructions,
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:340:    paintEditorStaticShadowPreviewInstructions(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:342:      staticShadowPreviewInstructions,
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:348:        _paintPlacedElementsForLayer(
```

Ordre actuel dans le slot shadows statiques :

```text
1. Preview ShadowV2 projected building
2. Preview Shadow V1 static shadow
3. Éléments placés / sprites
```

Conclusion :

```text
L'éditeur peint V2 avant V1.
Si un élément a les deux, l'utilisateur voit encore la V1 après la V2,
sous le sprite, dans le même slot.
```

## 13. Audit données projet / Selbrume lecture seule

Commandes :

```bash
test -f /Users/karim/Desktop/selbrume/project.json && rg -n '"shadow"|"shadowOverride"|"projectedBuildingShadow"|"genericProjection"|"castsShadow"|"shadowProfileId"|projectedBuildingShadowCatalog|shadowCatalog' /Users/karim/Desktop/selbrume/project.json || true

test -d /Users/karim/Desktop/selbrume/maps && rg -n '"shadow"|"shadowOverride"|"projectedBuildingShadow"|"genericProjection"|"castsShadow"|"shadowProfileId"' /Users/karim/Desktop/selbrume/maps || true
```

Résultat synthétique précis sur `/Users/karim/Desktop/selbrume/project.json` :

```text
448:      "shadow": {
449:        "castsShadow": true,
450:        "shadowProfileId": "default-ground-wide-ellipse",
489:      "shadow": {
490:        "castsShadow": true,
491:        "shadowProfileId": "default-ground-wide-ellipse",
530:      "shadow": {
531:        "castsShadow": true,
532:        "shadowProfileId": "default-ground-contact-blob",
...
12219:  "shadowCatalog": {
```

Résumé quantitatif via `jq` :

Commande :

```bash
test -f /Users/karim/Desktop/selbrume/project.json && jq -r '[ (.elements // [] | length), (.elements // [] | map(select(.shadow != null)) | length), (.elements // [] | map(select(.projectedBuildingShadow != null)) | length), (.elements // [] | map(select(.shadow.family == "genericProjection")) | length), (.elements // [] | map(select(.shadow.castsShadow == true)) | length), (.shadowCatalog.profiles // [] | length), (.projectedBuildingShadowCatalog.presets // [] | length) ] | @tsv' /Users/karim/Desktop/selbrume/project.json || true
```

Résultat :

```text
63	20	0	0	20	3	0
```

Interprétation des colonnes :

```text
elements total = 63
elements avec shadow != null = 20
elements avec projectedBuildingShadow != null = 0
elements shadow.family == genericProjection = 0
elements avec shadow.castsShadow == true = 20
shadowCatalog profiles = 3
projectedBuildingShadowCatalog presets = 0
```

Inventaire des 20 éléments avec V1 active :

```text
test_maison_pkm	test maison pkm	6	7	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
test	test	45	33	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
custom_cliff_selbrume	custom cliff  selbrume	3	13	default-ground-contact-blob	tallProp	0.2	0.8	0.55	0.5	1.0	0.28	0.05
selbrum_maison_1	selbrum maison 1	5	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_2	selbrum maison  2	6	7	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_3	selbrum maison 3	8	7	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_4	selbrum maison  4	5	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_7	selbrum maison  7	6	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrum_maison_8	selbrum maison  8	11	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
objectif	objectif	45	33	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrume_centre_pok_mon	selbrume centre pokémon	8	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
selbrume_maison_6	selbrume maison 6	6	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
le_puits	le puits	4	5	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
kiosque_l_gumes	kiosque à légumes	6	6	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
for_t_1	forêt 1	25	11	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
barri_re_pierre	barrière pierre	13	6	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5	0.5	0.98	0.58	0.06
parasol	parasol	4	4	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
rock_cliff_1	rock cliff 1	3	4	default-ground-wide-ellipse	building	0.2	0.72	0.48	0.5	0.98	0.6	0.06
rock_cliff_2	rock cliff  2	7	2	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5	0.5	0.98	0.58	0.06
rock_cliff_3	rock cliff  3	9	3	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5	0.5	0.98	0.58	0.06
```

Catalogue V1 Selbrume :

```text
default-ground-soft-ellipse	Ombre douce au sol	ellipse	groundStatic	0.35	000000	1.0	1.0
default-ground-wide-ellipse	Ombre large au sol	ellipse	groundStatic	0.28	000000	1.35	0.85
default-ground-contact-blob	Ombre compacte au sol	contactBlob	groundStatic	0.35	000000	1.0	1.0
```

Résumé placements Selbrume via `jq` :

```text
{
  "placedTotal": 2105,
  "placedWithNonNullShadowOverride": 0,
  "placedReferencingShadowedElement": 11,
  "placedReferencingProjectedBuildingShadow": 0,
  "shadowedElementPlacementCounts": [
    {"elementId": "kiosque_l_gumes", "count": 1},
    {"elementId": "le_puits", "count": 1},
    {"elementId": "selbrum_maison_1", "count": 1},
    {"elementId": "selbrum_maison_2", "count": 1},
    {"elementId": "selbrum_maison_3", "count": 1},
    {"elementId": "selbrum_maison_4", "count": 2},
    {"elementId": "selbrum_maison_7", "count": 1},
    {"elementId": "selbrum_maison_8", "count": 1},
    {"elementId": "selbrume_centre_pok_mon", "count": 1},
    {"elementId": "test", "count": 1}
  ]
}
```

Conclusion Selbrume :

- aucun `projectedBuildingShadow` authoré actuellement ;
- aucun preset V2 dans `projectedBuildingShadowCatalog` ;
- aucun `shadowOverride` non-null sur les placements ;
- aucun `genericProjection` dans les données actuelles ;
- la source V1 persistée réelle est `ProjectElementEntry.shadow`, surtout `family: building`, plus quelques `compactProp` / `tallProp`.

## 14. Hypothèse asset-shadow peinte dans PNG

L'hypothèse "ombre déjà peinte dans l'asset" reste plausible pour l'image fournie, car elle montre des bâtiments isolés avec des formes grises directement autour du sprite. Si ces pixels gris sont dans le PNG source, aucune suppression runtime/editor ne les retirera.

Méthode de vérification recommandée pour un lot ultérieur :

1. charger le tileset source concerné en lecture seule ;
2. identifier le rectangle source de l'élément ;
3. afficher ce rectangle seul, sans shadow provider et sans preview V1/V2 ;
4. comparer avec le rendu avec shadow collection vide ;
5. si le gris reste dans les deux cas, l'ombre est asset-baked ;
6. si le gris disparaît quand les collections/preview shadow sont vides, l'ombre vient du moteur.

Ne pas implémenter cette méthode dans ShadowV2-29.

## 15. Sources probables des ombres moches

Classement des sources :

1. `ProjectElementEntry.shadow` V1 persisté : confiance forte.
2. Preview editor V1 static shadow : confiance forte pour l'éditeur.
3. Runtime V1 static placed shadow : confiance forte pour le runtime.
4. `MapPlacedElement.shadowOverride` : confiance faible pour Selbrume actuel, car aucun override non-null n'a été trouvé.
5. `genericProjection` : confiance faible pour Selbrume actuel, car `genericProjection` vaut 0 dans les données ; reste un risque de code/fallback si `family` absent.
6. Auto-policy V1 : confiance moyenne comme source historique, faible comme source runtime actuelle.
7. ShadowV2 : confiance nulle pour Selbrume actuel, car aucune donnée V2 authorée.
8. Ombre peinte dans PNG : confiance moyenne pour l'image fournie, à vérifier séparément.

Réponse à la question centrale :

```text
Si une ombre moche est visible autour/sous un bâtiment dans Selbrume aujourd'hui,
la source générée par le moteur la plus probable est ProjectElementEntry.shadow V1.
Si l'ombre est visible dans le sprite brut hors moteur, elle est dans l'asset.
```

## 16. Options étudiées

### Option A — V2 active masque V1 pour le même élément

Principe :

```text
Si ProjectElementEntry.projectedBuildingShadow.enabled == true,
alors ignorer la shadow V1 du même élément / placement
dans le runtime static placed V1 et la preview editor V1.
```

Avantages :

- règle simple et lisible ;
- règle cohérente avec "V2 remplace les grandes ombres projetées de bâtiments" ;
- pas de migration destructrice ;
- pas de suppression de données ;
- règle identique editor/runtime ;
- corrige aussi les V1 `building/contactLedge`, pas seulement `genericProjection`.

Risques :

- si un élément V2 avait aussi une petite V1 utile volontaire, cette V1 disparaîtrait ;
- nécessite des tests explicites sur la coexistence V1 + V2.

Analyse :

Cette option est la plus sûre pour les bâtiments ShadowV2. Elle garde les petites ombres V1 des éléments non V2, donc elle ne coupe pas le système V1 globalement.

### Option B — V2 active masque seulement genericProjection V1

Avantages :

- très fin ;
- conserve les `building/contactLedge`, `compactProp`, `tallProp`, `contactBlob`.

Rejet :

- trop étroit pour les données actuelles ;
- Selbrume a `genericProjection = 0`, mais conserve des shadows V1 visibles ;
- ne traite pas les `building/contactLedge` qui restent la source réelle constatée.

### Option C — Flag global temporaire pour couper V1 static placed shadows

Avantages :

- rapide côté runtime ;
- existe déjà partiellement via `enableStaticPlacedElementShadows` dans `PlayableMapGame`.

Rejet :

- coupe trop large ;
- mélange V1 et V2 ;
- ajoute ou propage une surface publique confuse ;
- ne répond pas proprement au cas "un élément V2 remplace sa V1".

### Option D — Migration / cleanup des données V1 existantes

Avantages :

- nettoie la source persistée ;
- réduit l'ambiguïté future.

Rejet pour le prochain lot :

- destructif ;
- demande validation artistique élément par élément ;
- Selbrume ne doit pas être modifié sans lot dédié ;
- ne règle pas la règle de coexistence V1/V2 dans le code.

### Option E — Ne rien supprimer, seulement afficher un warning editor

Avantages :

- très sûr ;
- cohérent avec le diagnostic V2 `v1AndV2Coexistence`.

Rejet :

- ne règle pas le visuel ;
- l'utilisateur continuerait à voir les vieilles ombres.

### Option F — Couper toute preview editor V1 mais garder runtime V1

Avantages :

- améliore vite la sensation dans l'éditeur.

Rejet :

- crée une divergence editor/runtime ;
- l'utilisateur ne voit plus le vrai rendu ;
- ne corrige pas le jeu.

## 17. Option recommandée

Option recommandée :

```text
Option A — V2 active masque la V1 static placed pour le même élément / placement.
```

Pourquoi :

- l'audit montre que les V1 restantes ne sont pas seulement `genericProjection` ;
- les données réelles Selbrume ont `genericProjection = 0`, donc une suppression generic-only manquerait la source actuelle ;
- V2 est explicitement authorée pour remplacer les grandes ombres projetées de bâtiment ;
- les petites ombres utiles restent intactes sur les éléments qui n'ont pas de V2 ;
- aucune donnée n'est supprimée ;
- la règle est symétrique runtime/editor ;
- la règle peut être testée sans screenshot ni Selbrume.

Pourquoi les autres options sont rejetées :

- Option B : trop étroite pour les V1 `building/contactLedge` actuelles.
- Option C : trop globale et confuse.
- Option D : destructive et prématurée.
- Option E : informative mais ne corrige pas l'image.
- Option F : divergence editor/runtime.

Décision de coexistence recommandée :

```text
Si un élément a element.shadow V1 + projectedBuildingShadow V2 enabled,
le builder V2 produit sa preview/instruction,
et le builder V1 static placed ignore cette source V1 pour ce placement.
```

Cas particuliers recommandés :

- `projectedBuildingShadow == null` : V1 inchangée.
- `projectedBuildingShadow.enabled == false` : V1 inchangée.
- preset V2 manquant : V2 ne produit rien ; V1 inchangée en V0 pour éviter qu'une config cassée supprime une shadow existante.
- `shadowOverride.mode == disabled` : V1 déjà désactivée.
- `shadowOverride.mode == custom` sur un élément V2 : ignorer la V1 custom aussi, car la décision "V2 remplace V1" doit rester visible et non ambiguë.

## 18. Plan précis du Lot 30

```text
ShadowV2-30 — V2 Suppresses Same-Element Legacy Static Shadow V0
```

Objectif :

```text
Quand un ProjectElementEntry possède projectedBuildingShadow.enabled == true
et que le preset V2 est résoluble,
ne plus produire la shadow V1 static placed correspondante
côté runtime et côté editor preview.
```

Fichiers à modifier :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

Fichiers à créer :

```text
reports/shadows/v2/shadow_v2_30_v2_suppresses_same_element_legacy_static_shadow.md
```

Fichiers interdits :

```text
packages/map_core/**
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Tests à ajouter/modifier :

```text
runtime V1 source builder:
- skips V1 static shadow when same element has valid enabled V2 projectedBuildingShadow
- keeps V1 static shadow when element has no V2
- keeps V1 static shadow when V2 is disabled
- keeps V1 static shadow when V2 preset is missing, si le runtime V1 source a accès au catalogue V2

runtime host:
- V1 + V2 same element produces only V2 groundStatic for static placed slot
- a non-V2 contactBlob/ellipse element still produces V1

editor V1 preview:
- skips V1 preview when same element has valid enabled V2 projectedBuildingShadow
- keeps V1 preview for non-V2 element
- keeps V1 preview when V2 disabled or unresolved

source anti-dérive:
- no genericProjection fallback added for V2
- no diagnostics call
- no auto-policy call
```

Assertions obligatoires :

- V2 instruction/preview reste produite ;
- V1 instruction/preview du même élément n'est plus produite ;
- V1 d'un autre élément sans V2 reste produite ;
- ordre V2 avant autres shadows reste inchangé ;
- `shadowOverride` custom ne force pas V1 si V2 valide existe ;
- aucun fichier Selbrume modifié.

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all

cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart

cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart test/map_grid_painter_test.dart

cd packages/map_runtime && flutter analyze lib/src/shadow/runtime_static_placed_element_shadow_sources.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart

cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_static_shadow_preview.dart test/application/shadow/editor_static_shadow_preview_test.dart test/map_grid_painter_test.dart

cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :

- V2 valide masque V1 same-element runtime ;
- V2 valide masque V1 same-element editor preview ;
- V1 non-V2 reste fonctionnelle ;
- pas de data cleanup ;
- pas de migration ;
- pas de screenshot ;
- pas de Selbrume ;
- tests ciblés passent ;
- analyze ciblé passe ;
- `git diff --check` propre.

## 19. Tests recommandés pour le Lot 30

Tests runtime :

- `buildRuntimeStaticPlacedElementShadowSources skips same-element V1 when projected building shadow is enabled`
- `PlayableMapGame does not merge legacy V1 static shadow for an element with valid V2`
- `PlayableMapGame keeps legacy V1 static shadows for elements without V2`
- `PlayableMapGame keeps V1 when projected building shadow is disabled`
- `PlayableMapGame keeps V1 when projected preset is missing`

Tests editor :

- `buildEditorStaticShadowPreviewInstructions skips same-element V1 when projected building shadow is enabled`
- `buildEditorStaticShadowPreviewInstructions keeps V1 for non-V2 elements`
- `MapGridPainter paints V2 without same-element V1 overpaint`

Tests anti-dérive :

- absence de `diagnoseProjectedBuildingShadows` dans les chemins runtime/editor V1 modifiés ;
- absence de `applyElementAutoShadowPolicyToProject` ;
- absence de nouveau fallback `genericProjection` pour V2 ;
- absence d'import `map_runtime` dans `map_editor`.

## 20. Fichiers explicitement interdits au Lot 30

```text
packages/map_core/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/models/**
packages/map_editor/lib/src/data/**
packages/map_editor/test/fixtures/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

## 21. Risques / réserves

- Si une ombre est directement peinte dans le PNG, aucune règle V1/V2 ne la retirera.
- La règle "V2 masque V1" doit être conditionnée à une V2 réellement résoluble, sinon un preset manquant pourrait cacher une V1 existante sans afficher de V2.
- Couper toute V1 same-element peut masquer une petite ombre utile volontaire si un élément V2 en avait une ; ce risque est acceptable en V0 pour les bâtiments, mais il doit être testé et documenté.
- Selbrume n'a pas encore de V2 authorée dans les données lues ; le prochain lot peut prouver la règle en micro-fixture, pas en données réelles.
- Le nom `enableStaticPlacedElementShadows` reste ambigu car il contrôle déjà V2 en runtime V0.

## 22. Auto-critique

- Le lot est bien design-only : aucun code de production ni test n'a été modifié.
- La source probable est identifiée avec preuves : dans Selbrume, V1 persistée est présente, V2 absente, overrides non-null absents.
- La stratégie recommandée est ciblée : elle ne coupe pas V1 globalement, seulement V1 same-element quand V2 valide existe.
- La stratégie évite une migration destructive.
- La stratégie évite de casser les petites ombres utiles des éléments non V2.
- Le plan Lot 30 est borné, mais il touche à la fois runtime V1 source et editor V1 preview ; c'est nécessaire pour éviter une divergence editor/runtime.
- Les fichiers interdits sont explicites.
- La seule incertitude restante est l'hypothèse asset-baked, qui nécessite une preuve visuelle ou image read-only distincte.

## 23. Regard critique sur le prompt

Le prompt est bien cadré : il force à ouvrir le système V1 au lieu de blâmer ShadowV2. La meilleure contrainte est l'audit Selbrume en lecture seule, car elle évite une décision abstraite : la donnée réelle actuelle ne contient pas de V2 et ne contient pas de `genericProjection`, donc le problème restant ne peut pas être réglé par une suppression generic-only.

Point à améliorer pour un futur prompt : distinguer explicitement deux cas visuels :

```text
1. ombre générée par moteur ;
2. ombre déjà peinte dans l'asset.
```

Ces deux cas appellent des lots différents.

## 24. Commandes lancées

Commandes minimales exécutées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "ProjectShadow|ProjectShadowCatalog|ProjectShadowProfile|ProjectElementShadowConfig|MapPlacedElementShadowOverride|ShadowCasterMode|StaticShadowFamily|genericProjection|contactBlob|ellipse|castsShadow|shadowProfileId|shadowOverride|shadow:" packages/map_core/lib packages/map_core/test
rg -n "applyElementAutoShadowPolicyToProject|ElementAutoShadow|autoShadow|genericProjection|StaticShadowFamily|castsShadow|shadowProfileId" packages/map_core/lib packages/map_core/test reports/shadows
rg -n "buildRuntimeStaticPlacedElementShadow|runtime_static_placed_element_shadow|StaticPlacedElementShadow|staticShadow|element.shadow|placed.shadowOverride|ProjectElementShadowConfig|MapPlacedElementShadowOverride|genericProjection|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|ShadowRuntimeRenderer|groundStatic" packages/map_runtime/lib packages/map_runtime/test
rg -n "_projectedBuildingShadowCollectionByMapId|_staticShadowCollectionByMapId|_provideShadowCollectionForMap|mergeShadowRuntimeInstructionCollections|enableStaticPlacedElementShadows|enableActorContactShadows" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow
rg -n "EditorStaticShadowPreview|buildEditorStaticShadowPreviewInstructions|paintEditorStaticShadowPreviewInstructions|editor_static_shadow_preview|shadowOverride|element.shadow|genericProjection|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|contactBlob|ellipse|projectedPolygon" packages/map_editor/lib packages/map_editor/test
rg -n "projectedBuildingShadowPreviewInstructions|staticShadowPreviewInstructions|paintEditorStaticShadowPreviewInstructions|placed elements|_paintPlacedElement|MapGridPainter|paint\\(" packages/map_editor/lib/src/ui/canvas packages/map_editor/test/map_grid_painter_test.dart
test -f /Users/karim/Desktop/selbrume/project.json && rg -n '"shadow"|"shadowOverride"|"projectedBuildingShadow"|"genericProjection"|"castsShadow"|"shadowProfileId"|projectedBuildingShadowCatalog|shadowCatalog' /Users/karim/Desktop/selbrume/project.json || true
test -d /Users/karim/Desktop/selbrume/maps && rg -n '"shadow"|"shadowOverride"|"projectedBuildingShadow"|"genericProjection"|"castsShadow"|"shadowProfileId"' /Users/karim/Desktop/selbrume/maps || true
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Commandes complémentaires read-only exécutées :

```bash
sed -n '1,340p' packages/map_core/lib/src/models/shadow.dart
sed -n '1,260p' packages/map_core/lib/src/operations/static_shadow_family_projection.dart
sed -n '1,260p' packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
sed -n '1,260p' packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
sed -n '1,260p' packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
sed -n '1660,1755p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,260p' packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
sed -n '1,140p' packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
jq -r '[ (.elements // [] | length), (.elements // [] | map(select(.shadow != null)) | length), (.elements // [] | map(select(.projectedBuildingShadow != null)) | length), (.elements // [] | map(select(.shadow.family == "genericProjection")) | length), (.elements // [] | map(select(.shadow.castsShadow == true)) | length), (.shadowCatalog.profiles // [] | length), (.projectedBuildingShadowCatalog.presets // [] | length) ] | @tsv' /Users/karim/Desktop/selbrume/project.json
```

Tests lancés :

```text
Aucun. Lot design-only, aucune modification de code.
```

## 25. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat final :

```text
Aucune ligne.
```

## 26. git diff --name-status

Commande :

```bash
git diff --name-status
```

Résultat final :

```text
Aucune ligne.
```

## 27. git diff --check

Commande :

```bash
git diff --check
```

Résultat final :

```text
Aucune ligne.
```

## 28. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
?? reports/shadows/v2/shadow_v2_29_existing_v1_ugly_shadow_source_audit_suppression_design.md
```

Confirmation :

```text
Un seul rapport Markdown a été créé par ShadowV2-29.
Aucun fichier Dart n'a été modifié.
Aucun fichier Selbrume n'a été modifié.
Aucun screenshot ni baseline n'a été créé.
```

Checklist finale :

- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_editor modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Modèles Shadow V1 audités
- [x] Auto-policy V1 auditée
- [x] Runtime V1 audité
- [x] Preview editor V1 auditée
- [x] Merge runtime V1/V2 audité
- [x] Canvas editor V1/V2 audité
- [x] Données projet/Selbrume lues en lecture seule ou inaccessibilité documentée
- [x] Hypothèse asset-shadow documentée
- [x] Options comparées
- [x] Option recommandée unique
- [x] Plan ShadowV2-30 précis
- [x] Fichiers interdits au Lot 30 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme
