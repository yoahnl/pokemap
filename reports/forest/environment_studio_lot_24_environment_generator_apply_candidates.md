# Environment Studio Lot 24 — Environment Generator Apply Candidates to Map V0

## 1. Résumé exécutif

Livrable : `ApplyEnvironmentGeneratedPlacementsUseCase` et DTOs associés dans `environment_generator_apply_use_cases.dart`, plus tests `environment_generator_apply_candidates_test.dart`. Le use case applique des `EnvironmentGeneratedPlacementCandidate` (Lot 23) en `MapPlacedElement`, met à jour `EnvironmentArea.generatedPlacementIds`, refuse si cette liste est déjà non vide, valide avec `MapValidator.validate(..., projectDialogueContext: manifest)`, et reste transactionnel (aucune mutation sur erreur). Aucune UI, notifier, canvas, `map_core`, I/O disque.

## 2. Périmètre du lot

**Inclus** : modèles de résultat, issues typées, use case pur, création `MapPlacedElement`, append `placedElements`, mise à jour zone, tests.

**Exclus** : bouton Generate, Clear/Regenerate, appel auto au générateur, `EditorNotifier`, inspecteur, canvas, patch `TileLayer.tiles`, mutation `ProjectManifest`, `map_runtime`, `build_runner`.

## 3. Audit initial MapPlacedElement / candidates / generatedPlacementIds

- `MapPlacedElement` (`map_core` `map_data.dart`) : `id`, `layerId`, `elementId`, `pos`, `applyCollision` (défaut `true`), champs optionnels animation/behaviors/properties.
- **Minimal valide** : `MapPlacedElement(id:, layerId:, elementId:, pos:, applyCollision: …)`.
- **Collision** : `EnvironmentCollisionMode` → `applyCollision` : `forceEnabled`→`true`, `forceDisabled`→`false`, `useElementDefault`→`true` (défaut modèle ; profil collision élément hors scope Lot 24).
- **Tags** : non copiés dans `properties` (pas d’extension `map_core`).
- **Ajout placements** : `copyWith(placedElements: [...existants, ...nouveaux])` après `setEnvironmentLayerContent`.
- **`generatedPlacementIds`** : reconstruction `EnvironmentArea` avec liste ordonnée des ids placés.
- **Pourquoi pas de changement UI / map_core** : contrat du lot — logique applicative `map_editor` uniquement.

## 4. Décisions d’architecture

- Fichier dédié `environment_generator_apply_use_cases.dart` (séparation Lot 23).
- **Id placé** : `placedElementId = candidate.id`.
- **Refus si déjà généré** : `areaAlreadyHasGeneratedPlacements` — pas de remplacement silencieux.
- **Footprint** : alignement `MapValidator` via `_footprintInBounds` (taille frame primaire).
- **Validation finale** : try/catch autour de `setEnvironmentLayerContent` + `MapValidator.validate` → `mapValidationFailed`.

## 5. Modèles de résultat d’application

`EnvironmentAppliedGeneratedPlacement`, `EnvironmentApplyIssueSeverity` (error seul), `EnvironmentApplyIssueKind`, `EnvironmentApplyIssue`, `EnvironmentApplyResult` (listes unmodifiable, `issuesForKind`, `hasErrors`, `errorCount`, `appliedPlacementCount`, égalité structurée).

## 6. Validation des entrées

Résolution couche environnement / `TileLayer` cible / `EnvironmentArea` ; garde-fous liste vide, ids déjà générés, cohérence candidat (layer, area, preset, target), élément dans `manifest.elements`, bounds + footprint, unicité `candidate.id`, conflit `placedElements`, doublon position `(target|x|y)`.

## 7. Création des MapPlacedElement

`MapPlacedElement(id: c.id, layerId: target, elementId:, pos:, applyCollision: …)` ; ordre d’ajout = ordre des candidats après placements existants.

## 8. Mise à jour EnvironmentArea.generatedPlacementIds

`EnvironmentArea` reconstruit avec mêmes champs + `generatedPlacementIds` ordonnés comme les candidats ; autres areas et `targetTileLayerId` inchangés.

## 9. Transactionnalité / absence de mutation en erreur

Sur toute erreur : `_failure(map, …)` avec `map` d’entrée ; tests `identical(r.map, before)` ; aucune application partielle.

## 10. Intégration pure avec le générateur Lot 23

Test `GenerateEnvironmentAreaPlacementsUseCase` → `ApplyEnvironmentGeneratedPlacementsUseCase` : même cardinalité, `generatedPlacementIds` alignés sur les ids candidats.

## 11. Non-mutation UI / EditorNotifier / Canvas

Aucun fichier `editor_notifier.dart`, `environment_layer_inspector_panel.dart`, `map_canvas.dart` modifié pour ce lot.

## 12. Non-persistance disque garantie

Sortie grep (vide = aucune occurrence) :

```text
(aucune ligne)
```

## 13. Pourquoi aucun bouton Generate / Clear / Regenerate dans ce lot

Le cahier des charges exclut explicitement le branchement UI et les politiques de ré-application ; lots ultérieurs (ex. Environment-25).

## 14. Fichiers modifiés

- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart` (nouveau)
- `packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart` (nouveau)
- `reports/forest/environment_studio_lot_24_environment_generator_apply_candidates.md` (nouveau, ce fichier)

## 15. Tests ajoutés ou modifiés

`environment_generator_apply_candidates_test.dart` : modèles/immuabilité, happy path, ordre A/B/C, collision, tags, erreurs layer/candidats, transaction, manifest/tiles, intégration Lot23, `mapValidationFailed`.

## 16. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/application/use_cases/environment_generator_apply_use_cases.dart \
  test/environment_studio/environment_generator_apply_candidates_test.dart
dart analyze lib/src/application/use_cases/environment_generator_apply_use_cases.dart \
  test/environment_studio/environment_generator_apply_candidates_test.dart
flutter analyze lib/src/application/use_cases/environment_generator_apply_use_cases.dart \
  test/environment_studio/environment_generator_apply_candidates_test.dart
grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n \
  lib/src/application/use_cases/environment_generator_apply_use_cases.dart \
  test/environment_studio/environment_generator_apply_candidates_test.dart || true
( greps d’audit §3 du cahier des charges )
flutter test test/environment_studio/environment_generator_apply_candidates_test.dart --reporter expanded
flutter test test/environment_studio/environment_generator_deterministic_core_test.dart \
  test/environment_studio/environment_layer_mask_brush_tool_test.dart \
  test/environment_studio/environment_layer_area_model_editing_test.dart \
  test/environment_studio/environment_layer_target_tile_layer_test.dart \
  test/environment_studio/environment_layer_creation_test.dart \
  test/environment_studio/environment_generator_apply_candidates_test.dart --reporter expanded
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test
```

## 17. Résultats des commandes

### 17.1 Greps d’audit (sortie intégrale)

```text
../map_core/lib/src/models/map_data.dart:96:class MapPlacedElement with _$MapPlacedElement {
../map_core/lib/src/models/map_data.dart:140:class MapPlacedElementBehavior with _$MapPlacedElementBehavior {
../map_core/lib/src/models/map_data.dart:169:class MapPlacedElementEffect with _$MapPlacedElementEffect {
../map_core/lib/src/models/map_data.dart:183:class MapPlacedElementAnimation with _$MapPlacedElementAnimation {
---
../map_core/lib/src/models/map_data.freezed.dart:1330:    return 'MapPlacedElement(id: $id, layerId: $layerId, elementId: $elementId, pos: $pos, applyCollision: $applyCollision, animation: $animation, behaviors: $behaviors, properties: $properties)';
../map_core/lib/src/models/map_data.freezed.dart:1384:  const factory _MapPlacedElement(
../map_core/lib/src/models/map_data.dart:98:  const factory MapPlacedElement({
../map_core/lib/src/operations/map_placed_elements.dart:24:MapData upsertMapPlacedElement(
../map_core/lib/src/operations/map_placed_elements.dart:40:MapData removeMapPlacedElement(
lib/src/application/use_cases/environment_generator_apply_use_cases.dart:538:      final placed = MapPlacedElement(
lib/src/application/services/placed_element_instance_indexer.dart:185:            MapPlacedElement(
test/map_grid_painter_test.dart:32:          MapPlacedElement(
---
../map_core/lib/src/operations/map_placed_elements.dart:77:MapData setMapPlacedElementCollisionApplied(
../map_core/lib/src/operations/map_placed_elements.dart:98:MapData setMapPlacedElementAnimation(
../map_core/lib/src/operations/map_placed_elements.dart:119:MapData resetMapPlacedElementAnimation(
../map_core/lib/src/operations/map_placed_elements.dart:123:  return setMapPlacedElementAnimation(
../map_core/lib/src/operations/map_placed_elements.dart:130:MapData setMapPlacedElementAnimationEnabled(
---
../map_core/lib/src/models/map_data.freezed.dart:29:  List<MapPlacedElement> get placedElements =>
../map_core/lib/src/models/map_data.freezed.dart:64:      List<MapPlacedElement> placedElements,
../map_core/lib/src/models/map_data.freezed.dart:99:    Object? placedElements = null,
../map_core/lib/src/models/map_data.freezed.dart:134:      placedElements: null == placedElements
../map_core/lib/src/models/map_data.freezed.dart:135:          ? _value.placedElements
../map_core/lib/src/models/map_data.freezed.dart:136:          : placedElements // ignore: cast_nullable_to_non_nullable
../map_core/lib/src/models/map_data.freezed.dart:208:      List<MapPlacedElement> placedElements,
../map_core/lib/src/models/map_data.freezed.dart:243:    Object? placedElements = null,
../map_core/lib/src/models/map_data.freezed.dart:278:      placedElements: null == placedElements
../map_core/lib/src/models/map_data.freezed.dart:279:          ? _value._placedElements
../map_core/lib/src/models/map_data.freezed.dart:280:          : placedElements // ignore: cast_nullable_to_non_nullable
../map_core/lib/src/models/map_data.freezed.dart:329:      final List<MapPlacedElement> placedElements = const [],
../map_core/lib/src/models/map_data.freezed.dart:339:        _placedElements = placedElements,
../map_core/lib/src/models/map_data.freezed.dart:372:  final List<MapPlacedElement> _placedElements;
../map_core/lib/src/models/map_data.freezed.dart:375:  List<MapPlacedElement> get placedElements {
../map_core/lib/src/models/map_data.freezed.dart:376:    if (_placedElements is EqualUnmodifiableListView) return _placedElements;
../map_core/lib/src/models/map_data.freezed.dart:378:    return EqualUnmodifiableListView(_placedElements);
../map_core/lib/src/models/map_data.freezed.dart:454:    return 'MapData(id: $id, name: $name, size: $size, version: $version, tilesetId: $tilesetId, layers: $layers, placedElements: $placedElements, entities: $entities, connections: $connections, warps: $warps, triggers: $triggers, gameplayZones: $gameplayZones, mapMetadata: $mapMetadata, properties: $properties, events: $events)';
../map_core/lib/src/models/map_data.freezed.dart:470:                .equals(other._placedElements, _placedElements) &&
../map_core/lib/src/models/map_data.freezed.dart:495:      const DeepCollectionEquality().hash(_placedElements),
../map_core/lib/src/models/map_data.freezed.dart:529:      final List<MapPlacedElement> placedElements,
../map_core/lib/src/models/map_data.freezed.dart:554:  List<MapPlacedElement> get placedElements;
../map_core/lib/src/models/map_data.g.dart:21:      placedElements: (json['placedElements'] as List<dynamic>?)
../map_core/lib/src/models/map_data.g.dart:64:      'placedElements': instance.placedElements.map((e) => e.toJson()).toList(),
../map_core/lib/src/models/map_data.dart:27:    @Default([]) List<MapPlacedElement> placedElements,
../map_core/lib/src/operations/map_resize.dart:98:  final newPlacedElements = map.placedElements
../map_core/lib/src/operations/map_resize.dart:111:    placedElements: newPlacedElements,
../map_core/lib/src/operations/map_placed_elements.dart:30:      map.placedElements.indexWhere((entry) => entry.id == normalized.id);
../map_core/lib/src/operations/map_placed_elements.dart:31:  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
../map_core/lib/src/operations/map_placed_elements.dart:37:  return map.copyWith(placedElements: next);
../map_core/lib/src/operations/map_placed_elements.dart:49:  final next = map.placedElements
../map_core/lib/src/operations/map_placed_elements.dart:52:  if (next.length == map.placedElements.length) {
../map_core/lib/src/operations/map_placed_elements.dart:56:  return map.copyWith(placedElements: next);
../map_core/lib/src/operations/map_placed_elements.dart:71:    ...map.placedElements.where((entry) => entry.layerId != normalizedLayerId),
../map_core/lib/src/operations/map_placed_elements.dart:74:  return map.copyWith(placedElements: next);
../map_core/lib/src/operations/map_placed_elements.dart:87:  final index = map.placedElements
../map_core/lib/src/operations/map_placed_elements.dart:93:  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
../map_core/lib/src/operations/map_placed_elements.dart:95:  return map.copyWith(placedElements: next);
../map_core/lib/src/operations/map_placed_elements.dart:109:      map.placedElements.indexWhere((entry) => entry.id == normalizedId);
../map_core/lib/src/operations/map_placed_elements.dart:114:  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
---
../map_core/lib/src/models/map_data.freezed.dart:1073:  bool get applyCollision => throw _privateConstructorUsedError;
../map_core/lib/src/models/map_data.freezed.dart:1101:      bool applyCollision,
../map_core/lib/src/models/map_data.freezed.dart:1129:    Object? applyCollision = null,
../map_core/lib/src/models/map_data.freezed.dart:1151:      applyCollision: null == applyCollision
../map_core/lib/src/models/map_data.freezed.dart:1152:          ? _value.applyCollision
../map_core/lib/src/models/map_data.freezed.dart:1153:          : applyCollision // ignore: cast_nullable_to_non_nullable
../map_core/lib/src/models/map_data.freezed.dart:1208:      bool applyCollision,
../map_core/lib/src/models/map_data.freezed.dart:1236:    Object? applyCollision = null,
../map_core/lib/src/models/map_data.freezed.dart:1258:      applyCollision: null == applyCollision
../map_core/lib/src/models/map_data.freezed.dart:1259:          ? _value.applyCollision
../map_core/lib/src/models/map_data.freezed.dart:1260:          : applyCollision // ignore: cast_nullable_to_non_nullable
../map_core/lib/src/models/map_data.freezed.dart:1287:      this.applyCollision = true,
../map_core/lib/src/models/map_data.freezed.dart:1307:  final bool applyCollision;
../map_core/lib/src/models/map_data.freezed.dart:1330:    return 'MapPlacedElement(id: $id, layerId: $layerId, elementId: $elementId, pos: $pos, applyCollision: $applyCollision, animation: $animation, behaviors: $behaviors, properties: $properties)';
../map_core/lib/src/models/map_data.freezed.dart:1343:            (identical(other.applyCollision, applyCollision) ||
---
lib/src/application/use_cases/environment_generator_use_cases.dart:8:final class EnvironmentGeneratedPlacementCandidate {
lib/src/application/use_cases/environment_generator_use_cases.dart:9:  EnvironmentGeneratedPlacementCandidate({
lib/src/application/use_cases/environment_generator_use_cases.dart:34:    return other is EnvironmentGeneratedPlacementCandidate &&
lib/src/application/use_cases/environment_generator_use_cases.dart:145:    required List<EnvironmentGeneratedPlacementCandidate> placements,
lib/src/application/use_cases/environment_generator_use_cases.dart:149:      placements: List<EnvironmentGeneratedPlacementCandidate>.unmodifiable(
lib/src/application/use_cases/environment_generator_use_cases.dart:150:        List<EnvironmentGeneratedPlacementCandidate>.from(placements),
lib/src/application/use_cases/environment_generator_use_cases.dart:163:  final List<EnvironmentGeneratedPlacementCandidate> placements;
lib/src/application/use_cases/environment_generator_use_cases.dart:208:  List<EnvironmentGeneratedPlacementCandidate> a,
lib/src/application/use_cases/environment_generator_use_cases.dart:209:  List<EnvironmentGeneratedPlacementCandidate> b,
lib/src/application/use_cases/environment_generator_use_cases.dart:625:    final placements = <EnvironmentGeneratedPlacementCandidate>[];
lib/src/application/use_cases/environment_generator_use_cases.dart:695:          EnvironmentGeneratedPlacementCandidate(
lib/src/application/use_cases/environment_generator_apply_use_cases.dart:244:/// Applique des [EnvironmentGeneratedPlacementCandidate] sur une [MapData] en mémoire.
lib/src/application/use_cases/environment_generator_apply_use_cases.dart:253:    required List<EnvironmentGeneratedPlacementCandidate> candidates,
test/environment_studio/environment_generator_deterministic_core_test.dart:8:        'EnvironmentGeneratedPlacementCandidate copie les tags et expose un Set immuable',
test/environment_studio/environment_generator_deterministic_core_test.dart:11:      final c = EnvironmentGeneratedPlacementCandidate(
---
../map_core/lib/src/models/environment.dart:8:enum EnvironmentCollisionMode {
../map_core/lib/src/models/environment.dart:26:    EnvironmentCollisionMode collisionMode =
../map_core/lib/src/models/environment.dart:27:        EnvironmentCollisionMode.useElementDefault,
../map_core/lib/src/models/environment.dart:75:  final EnvironmentCollisionMode collisionMode;
../map_core/lib/src/operations/environment_preset_json_codec.dart:194:  final EnvironmentCollisionMode collisionMode;
../map_core/lib/src/operations/environment_preset_json_codec.dart:196:    collisionMode = EnvironmentCollisionMode.useElementDefault;
../map_core/lib/src/operations/environment_preset_json_codec.dart:248:EnvironmentCollisionMode _decodeCollisionMode(String value) {
../map_core/lib/src/operations/environment_preset_json_codec.dart:251:      return EnvironmentCollisionMode.useElementDefault;
../map_core/lib/src/operations/environment_preset_json_codec.dart:253:      return EnvironmentCollisionMode.forceEnabled;
../map_core/lib/src/operations/environment_preset_json_codec.dart:255:      return EnvironmentCollisionMode.forceDisabled;
---
../map_core/lib/src/models/environment.dart:260:    List<String>? generatedPlacementIds,
../map_core/lib/src/models/environment.dart:283:    final rawIds = generatedPlacementIds ?? const <String>[];
../map_core/lib/src/models/environment.dart:291:          'generatedPlacementIds',
../map_core/lib/src/models/environment.dart:292:          'EnvironmentArea generatedPlacementIds cannot contain empty strings.',
../map_core/lib/src/models/environment.dart:298:          'generatedPlacementIds',
../map_core/lib/src/models/environment.dart:299:          'EnvironmentArea generatedPlacementIds cannot contain duplicates.',
../map_core/lib/src/models/environment.dart:312:      generatedPlacementIds: List<String>.unmodifiable(ordered),
../map_core/lib/src/models/environment.dart:323:    required this.generatedPlacementIds,
../map_core/lib/src/models/environment.dart:332:  final List<String> generatedPlacementIds;
../map_core/lib/src/models/environment.dart:334:  bool get hasGeneratedPlacements => generatedPlacementIds.isNotEmpty;
../map_core/lib/src/models/environment.dart:346:            _listEquals(generatedPlacementIds, other.generatedPlacementIds);
../map_core/lib/src/models/environment.dart:357:        Object.hashAll(generatedPlacementIds),
../map_core/lib/src/models/environment.dart:545:  /// Zones d’environnement ; ordre significatif pour [generatedPlacementIds].
../map_core/lib/src/models/environment.dart:555:  List<String> get generatedPlacementIds {
../map_core/lib/src/models/environment.dart:558:      out.addAll(area.generatedPlacementIds);
---
lib/src/application/use_cases/gameplay_zone_use_cases.dart:6:    MapValidator.validate(updated);
lib/src/application/use_cases/gameplay_zone_use_cases.dart:42:    MapValidator.validate(updated);
lib/src/application/use_cases/gameplay_zone_use_cases.dart:50:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:39:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:65:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:142:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:153:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:161:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:177:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:193:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:209:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:225:    MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:269:        MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:313:      MapValidator.validate(updated);
lib/src/application/use_cases/layer_use_cases.dart:441:      MapValidator.validate(updated);
```

### 17.2 `dart analyze` (ciblé)

```text
Analyzing environment_generator_apply_use_cases.dart, environment_generator_apply_candidates_test.dart...

   info - test/environment_studio/environment_generator_apply_candidates_test.dart:246:23 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/environment_studio/environment_generator_apply_candidates_test.dart:252:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/environment_studio/environment_generator_apply_candidates_test.dart:454:22 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/environment_studio/environment_generator_apply_candidates_test.dart:603:11 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/environment_studio/environment_generator_apply_candidates_test.dart:771:10 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/environment_studio/environment_generator_apply_candidates_test.dart:776:7 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors
   info - test/environment_studio/environment_generator_apply_candidates_test.dart:808:7 - Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation. - prefer_const_constructors

7 issues found.
```

### 17.3 Tentative `flutter analyze` (ciblé)

```text
Analyzing 2 items...                                            

   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:246:23 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:252:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:454:22 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:603:11 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:771:10 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:776:7 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/environment_studio/environment_generator_apply_candidates_test.dart:808:7 • prefer_const_constructors

7 issues found. (ran in 0.8s)
```

### 17.4 `flutter test` apply (expanded, intégral)

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart
00:00 +0: EnvironmentApplyResult / modèles EnvironmentApplyResult copie défensivement et expose des listes immuables
00:00 +1: EnvironmentApplyResult / modèles EnvironmentAppliedGeneratedPlacement et EnvironmentApplyIssue égalité
00:00 +2: ApplyEnvironmentGeneratedPlacementsUseCase chemin heureux : placements, generatedPlacementIds, layers préservés
00:00 +3: ApplyEnvironmentGeneratedPlacementsUseCase ordre des candidats = ordre placedElements et generatedPlacementIds
00:00 +4: ApplyEnvironmentGeneratedPlacementsUseCase collisionMode forceEnabled / forceDisabled / useElementDefault
00:00 +5: ApplyEnvironmentGeneratedPlacementsUseCase tags candidat ne sont pas copiés vers MapPlacedElement.properties
00:00 +6: ApplyEnvironmentGeneratedPlacementsUseCase erreurs layer / target / area
00:00 +7: ApplyEnvironmentGeneratedPlacementsUseCase emptyCandidates et areaAlreadyHasGeneratedPlacements
00:00 +8: ApplyEnvironmentGeneratedPlacementsUseCase erreurs candidates : wrong layer, area, preset, target, element, bounds
00:00 +9: ApplyEnvironmentGeneratedPlacementsUseCase candidateDuplicateId, placedElementIdConflict, candidatePositionDuplicate
00:00 +10: ApplyEnvironmentGeneratedPlacementsUseCase transactionnalité : deuxième candidate invalide → aucune mutation
00:00 +11: ApplyEnvironmentGeneratedPlacementsUseCase ProjectManifest et TileLayer.tiles inchangés après succès
00:00 +12: ApplyEnvironmentGeneratedPlacementsUseCase intégration Lot 23 → Lot 24
00:00 +13: ApplyEnvironmentGeneratedPlacementsUseCase mapValidationFailed : tileset layer vs element incompatible
00:00 +14: All tests passed!
```

### 17.5 Régressions Lots 19–23 + apply (commande groupée)

Ligne finale :

```text
00:12 +78: All tests passed!
```

### 17.6 `flutter test test/environment_studio`

Ligne finale :

```text
00:12 +184: All tests passed!
```

### 17.7 `flutter test` `editor_workspace_controller` + `top_toolbar`

Ligne finale :

```text
00:09 +14: All tests passed!
```

### 17.8 `flutter test` package `map_editor` complet

Ligne finale :

```text
00:57 +1017 -34: Some tests failed.
```

Dette préexistante (ex. sync catalog Pokémon), hors périmètre Lot 24.

## 18. Git status initial et final

### 18.1 Initial (référence conversation)

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/operations/terrain_preset_subtile_for_map_cell.dart
?? packages/map_core/lib/src/operations/terrain_preset_variant_pick.dart
 M packages/map_core/test/terrain_preset_subtile_for_map_cell_test.dart
?? packages/map_core/test/terrain_preset_variant_pick_test.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/panels/terrain_editor/dialogs/terrain_preset_dialogs.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```
(état fourni au début de la conversation utilisateur ; non recapturé par `git status` dans cette session.)

### 18.2 Final

```text
?? packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart
?? packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart
?? reports/forest/environment_studio_lot_24_environment_generator_apply_candidates.md
```

## Evidence Pack — confirmations explicites

- Aucun `EditorNotifier` modifié : §14 — chemins hors `editor_notifier.dart`.
- Aucune UI / canvas modifiée pour ce lot : §14.
- Aucun `map_core` modifié par ce lot : les fichiers créés sont sous `packages/map_editor/...` et `reports/...` ; d’éventuels `M map_core` dans le dépôt relèvent d’autres lots non livrés ici.
- `generatedPlacementIds` modifiés uniquement sur `MapData` retournée en succès : logique + tests `identical` en erreur.
- Aucun `TileLayer.tiles` patché : test `tilesSnapshot` / comparaison liste.
- Aucune génération auto dans le use case apply : pas d’appel à `GenerateEnvironmentAreaPlacementsUseCase` dans `environment_generator_apply_use_cases.dart`.
- Aucune sauvegarde disque : §12 grep vide.
- Aucun `SurfaceLayer` legacy utilisé dans le use case.
- Aucun `build_runner` lancé pour ce lot.
- Aucun fichier généré (`*.g.dart` / `*.freezed.dart`) modifié par ce lot.
- Aucun commit / `git add` / `git push` : politique dépôt + instructions utilisateur.

## 19. Contenu complet des fichiers créés ou modifiés

### 19.1 `environment_generator_apply_use_cases.dart`

```dart
import 'package:map_core/map_core.dart';

import 'environment_generator_use_cases.dart';

// ---------------------------------------------------------------------------
// Lot Environment-24 — application des candidats Lot 23 → MapPlacedElement.
// Aucune UI, aucun I/O, pas de mutation si erreur.
// ---------------------------------------------------------------------------

/// Lien entre un candidat Lot 23 et l’instance [MapPlacedElement] créée.
final class EnvironmentAppliedGeneratedPlacement {
  const EnvironmentAppliedGeneratedPlacement({
    required this.candidateId,
    required this.placedElementId,
    required this.elementId,
    required this.layerId,
    required this.pos,
  });

  final String candidateId;
  final String placedElementId;
  final String elementId;
  final String layerId;
  final GridPos pos;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAppliedGeneratedPlacement &&
            candidateId == other.candidateId &&
            placedElementId == other.placedElementId &&
            elementId == other.elementId &&
            layerId == other.layerId &&
            pos == other.pos;
  }

  @override
  int get hashCode =>
      Object.hash(candidateId, placedElementId, elementId, layerId, pos);
}

enum EnvironmentApplyIssueSeverity {
  error,
}

enum EnvironmentApplyIssueKind {
  environmentLayerNotFound,
  layerIsNotEnvironmentLayer,
  targetTileLayerMissing,
  targetTileLayerInvalid,
  areaNotFound,
  areaAlreadyHasGeneratedPlacements,
  emptyCandidates,
  candidateWrongEnvironmentLayer,
  candidateWrongArea,
  candidateWrongPreset,
  candidateWrongTargetLayer,
  candidateElementMissing,
  candidateOutOfBounds,
  candidateDuplicateId,
  placedElementIdConflict,
  candidatePositionDuplicate,
  mapValidationFailed,
}

final class EnvironmentApplyIssue {
  const EnvironmentApplyIssue({
    required this.severity,
    required this.kind,
    required this.message,
    this.environmentLayerId,
    this.areaId,
    this.candidateId,
    this.targetLayerId,
    this.elementId,
    this.placedElementId,
  });

  final EnvironmentApplyIssueSeverity severity;
  final EnvironmentApplyIssueKind kind;
  final String message;
  final String? environmentLayerId;
  final String? areaId;
  final String? candidateId;
  final String? targetLayerId;
  final String? elementId;
  final String? placedElementId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentApplyIssue &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            environmentLayerId == other.environmentLayerId &&
            areaId == other.areaId &&
            candidateId == other.candidateId &&
            targetLayerId == other.targetLayerId &&
            elementId == other.elementId &&
            placedElementId == other.placedElementId;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        environmentLayerId,
        areaId,
        candidateId,
        targetLayerId,
        elementId,
        placedElementId,
      );
}

final class EnvironmentApplyResult {
  factory EnvironmentApplyResult({
    required MapData map,
    required List<EnvironmentAppliedGeneratedPlacement> appliedPlacements,
    required List<EnvironmentApplyIssue> issues,
  }) {
    return EnvironmentApplyResult._(
      map: map,
      appliedPlacements:
          List<EnvironmentAppliedGeneratedPlacement>.unmodifiable(
        List<EnvironmentAppliedGeneratedPlacement>.from(appliedPlacements),
      ),
      issues: List<EnvironmentApplyIssue>.unmodifiable(
        List<EnvironmentApplyIssue>.from(issues),
      ),
    );
  }

  const EnvironmentApplyResult._({
    required this.map,
    required this.appliedPlacements,
    required this.issues,
  });

  final MapData map;
  final List<EnvironmentAppliedGeneratedPlacement> appliedPlacements;
  final List<EnvironmentApplyIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == EnvironmentApplyIssueSeverity.error);

  int get errorCount => issues
      .where((i) => i.severity == EnvironmentApplyIssueSeverity.error)
      .length;

  int get appliedPlacementCount => appliedPlacements.length;

  List<EnvironmentApplyIssue> issuesForKind(EnvironmentApplyIssueKind kind) {
    return List<EnvironmentApplyIssue>.unmodifiable(
      issues.where((i) => i.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentApplyResult &&
        map == other.map &&
        appliedPlacementCount == other.appliedPlacementCount &&
        _listEqualsApplied(appliedPlacements, other.appliedPlacements) &&
        _listEqualsApplyIssues(issues, other.issues);
  }

  @override
  int get hashCode => Object.hash(
        map,
        appliedPlacementCount,
        Object.hashAll(appliedPlacements),
        Object.hashAll(issues),
      );
}

bool _listEqualsApplied(
  List<EnvironmentAppliedGeneratedPlacement> a,
  List<EnvironmentAppliedGeneratedPlacement> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsApplyIssues(
  List<EnvironmentApplyIssue> a,
  List<EnvironmentApplyIssue> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _originInBounds(GridPos pos, GridSize size) {
  return pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;
}

/// Footprint [MapValidator] quand [projectDialogueContext] est fourni (élément connu).
bool _footprintInBounds({
  required GridPos pos,
  required GridSize mapSize,
  required ProjectElementEntry element,
}) {
  final source = element.frames.primarySource;
  final width = source.width <= 0 ? 1 : source.width;
  final height = source.height <= 0 ? 1 : source.height;
  final right = pos.x + width;
  final bottom = pos.y + height;
  return right <= mapSize.width && bottom <= mapSize.height;
}

bool _applyCollisionFromCandidate(EnvironmentCollisionMode mode) {
  switch (mode) {
    case EnvironmentCollisionMode.forceEnabled:
      return true;
    case EnvironmentCollisionMode.forceDisabled:
      return false;
    case EnvironmentCollisionMode.useElementDefault:
      // [MapPlacedElement] défaut = true ; aligné sur l’indexeur d’instances tuiles.
      // Le profil [ElementCollisionProfile] pilote la géométrie, pas ce booléen.
      return true;
  }
}

EnvironmentApplyResult _failure(
  MapData original, {
  required List<EnvironmentApplyIssue> issues,
}) {
  return EnvironmentApplyResult(
    map: original,
    appliedPlacements: const [],
    issues: issues,
  );
}

/// Applique des [EnvironmentGeneratedPlacementCandidate] sur une [MapData] en mémoire.
///
/// Transactionnel : la moindre erreur → [map] d’entrée inchangée, aucun placement créé.
class ApplyEnvironmentGeneratedPlacementsUseCase {
  EnvironmentApplyResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String environmentLayerId,
    required String areaId,
    required List<EnvironmentGeneratedPlacementCandidate> candidates,
  }) {
    final issues = <EnvironmentApplyIssue>[];
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();

    EnvironmentLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        if (layer is EnvironmentLayer) {
          envLayer = layer;
        } else {
          issues.add(
            EnvironmentApplyIssue(
              severity: EnvironmentApplyIssueSeverity.error,
              kind: EnvironmentApplyIssueKind.layerIsNotEnvironmentLayer,
              message: 'Layer is not an environment layer: $envId',
              environmentLayerId: envId,
            ),
          );
          return _failure(map, issues: issues);
        }
        break;
      }
    }
    if (envLayer == null) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.environmentLayerNotFound,
          message: 'Environment layer not found: $envId',
          environmentLayerId: envId,
        ),
      );
      return _failure(map, issues: issues);
    }

    final targetId = envLayer.content.targetTileLayerId?.trim();
    if (targetId == null || targetId.isEmpty) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.targetTileLayerMissing,
          message: 'Environment layer has no target tile layer id',
          environmentLayerId: envId,
        ),
      );
      return _failure(map, issues: issues);
    }

    var targetTileLayerFound = false;
    for (final layer in map.layers) {
      if (layer.id == targetId) {
        if (layer is! TileLayer) {
          issues.add(
            EnvironmentApplyIssue(
              severity: EnvironmentApplyIssueSeverity.error,
              kind: EnvironmentApplyIssueKind.targetTileLayerInvalid,
              message:
                  'Target tile layer id does not reference a TileLayer: $targetId',
              environmentLayerId: envId,
              targetLayerId: targetId,
            ),
          );
          return _failure(map, issues: issues);
        }
        targetTileLayerFound = true;
        break;
      }
    }
    if (!targetTileLayerFound) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.targetTileLayerInvalid,
          message: 'Target tile layer not found: $targetId',
          environmentLayerId: envId,
          targetLayerId: targetId,
        ),
      );
      return _failure(map, issues: issues);
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.areaNotFound,
          message: 'Environment area not found: $aid',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    if (area.generatedPlacementIds.isNotEmpty) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.areaAlreadyHasGeneratedPlacements,
          message:
              'Environment area already has generated placements (${area.generatedPlacementIds.length})',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    if (candidates.isEmpty) {
      issues.add(
        const EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.emptyCandidates,
          message: 'No placement candidates to apply',
        ),
      );
      return _failure(map, issues: issues);
    }

    final elementById = <String, ProjectElementEntry>{
      for (final e in manifest.elements) e.id: e,
    };

    final seenCandidateIds = <String>{};
    final seenPositions = <String>{};
    final existingPlacedIds = <String>{
      for (final p in map.placedElements) p.id,
    };
    final stagedPlacedIds = <String>{};

    for (final c in candidates) {
      if (!seenCandidateIds.add(c.id)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateDuplicateId,
            message: 'Duplicate candidate id: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }

      if (c.environmentLayerId.trim() != envId) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongEnvironmentLayer,
            message: 'Candidate environmentLayerId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }
      if (c.areaId.trim() != aid) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongArea,
            message: 'Candidate areaId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }
      if (c.presetId.trim() != area.presetId.trim()) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongPreset,
            message: 'Candidate presetId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }
      if (c.targetLayerId.trim() != targetId) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongTargetLayer,
            message: 'Candidate targetLayerId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            targetLayerId: c.targetLayerId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final entry = elementById[c.elementId.trim()];
      if (entry == null) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateElementMissing,
            message: 'Candidate references unknown element: ${c.elementId}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            elementId: c.elementId,
          ),
        );
        return _failure(map, issues: issues);
      }

      if (!_originInBounds(c.pos, map.size) ||
          !_footprintInBounds(pos: c.pos, mapSize: map.size, element: entry)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateOutOfBounds,
            message:
                'Candidate position or footprint out of map bounds: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            elementId: c.elementId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final placedId = c.id;
      if (existingPlacedIds.contains(placedId) ||
          stagedPlacedIds.contains(placedId)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.placedElementIdConflict,
            message: 'Placed element id already exists: $placedId',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            placedElementId: placedId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final posKey = '${c.targetLayerId.trim()}|${c.pos.x}|${c.pos.y}';
      if (!seenPositions.add(posKey)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidatePositionDuplicate,
            message: 'Duplicate candidate position on layer: $posKey',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            targetLayerId: c.targetLayerId,
          ),
        );
        return _failure(map, issues: issues);
      }

      stagedPlacedIds.add(placedId);
    }

    final newPlaced = <MapPlacedElement>[
      ...map.placedElements,
    ];
    final applied = <EnvironmentAppliedGeneratedPlacement>[];
    final newPlacementIds = <String>[];

    for (final c in candidates) {
      final applyCollision = _applyCollisionFromCandidate(c.collisionMode);
      final placed = MapPlacedElement(
        id: c.id,
        layerId: c.targetLayerId.trim(),
        elementId: c.elementId.trim(),
        pos: c.pos,
        applyCollision: applyCollision,
      );
      newPlaced.add(placed);
      newPlacementIds.add(c.id);
      applied.add(
        EnvironmentAppliedGeneratedPlacement(
          candidateId: c.id,
          placedElementId: c.id,
          elementId: c.elementId.trim(),
          layerId: c.targetLayerId.trim(),
          pos: c.pos,
        ),
      );
    }

    final newAreas = <EnvironmentArea>[
      for (final a in envLayer.content.areas)
        if (a.id == aid)
          EnvironmentArea(
            id: a.id,
            name: a.name,
            presetId: a.presetId,
            mask: a.mask,
            seed: a.seed,
            paramsOverride: a.paramsOverride,
            generatedPlacementIds: newPlacementIds,
          )
        else
          a,
    ];

    final newContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: newAreas,
    );

    MapData updated;
    try {
      updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: newContent,
      ).copyWith(placedElements: newPlaced);
      MapValidator.validate(updated, projectDialogueContext: manifest);
    } catch (e) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.mapValidationFailed,
          message: 'MapValidator.validate failed: $e',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    return EnvironmentApplyResult(
      map: updated,
      appliedPlacements: applied,
      issues: const [],
    );
  }
}
```

### 19.2 `environment_generator_apply_candidates_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_apply_use_cases.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_use_cases.dart';

void main() {
  group('EnvironmentApplyResult / modèles', () {
    test(
        'EnvironmentApplyResult copie défensivement et expose des listes immuables',
        () {
      final m = _minimalMap();
      final rawApplied = <EnvironmentAppliedGeneratedPlacement>[
        const EnvironmentAppliedGeneratedPlacement(
          candidateId: 'c1',
          placedElementId: 'c1',
          elementId: 'e1',
          layerId: 'tiles',
          pos: GridPos(x: 0, y: 0),
        ),
      ];
      final rawIssues = <EnvironmentApplyIssue>[
        const EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.emptyCandidates,
          message: 'x',
        ),
      ];
      final r = EnvironmentApplyResult(
        map: m,
        appliedPlacements: rawApplied,
        issues: rawIssues,
      );
      rawApplied.clear();
      rawIssues.clear();
      expect(r.appliedPlacementCount, 1);
      expect(r.errorCount, 1);
      expect(() => r.appliedPlacements.clear(), throwsUnsupportedError);
      expect(() => r.issues.clear(), throwsUnsupportedError);
      expect(
          r.issuesForKind(EnvironmentApplyIssueKind.emptyCandidates).length, 1);
    });

    test(
        'EnvironmentAppliedGeneratedPlacement et EnvironmentApplyIssue égalité',
        () {
      const a = EnvironmentAppliedGeneratedPlacement(
        candidateId: 'c',
        placedElementId: 'p',
        elementId: 'e',
        layerId: 'l',
        pos: GridPos(x: 1, y: 2),
      );
      const b = EnvironmentAppliedGeneratedPlacement(
        candidateId: 'c',
        placedElementId: 'p',
        elementId: 'e',
        layerId: 'l',
        pos: GridPos(x: 1, y: 2),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      const i1 = EnvironmentApplyIssue(
        severity: EnvironmentApplyIssueSeverity.error,
        kind: EnvironmentApplyIssueKind.areaNotFound,
        message: 'm',
        candidateId: 'c',
      );
      const i2 = EnvironmentApplyIssue(
        severity: EnvironmentApplyIssueSeverity.error,
        kind: EnvironmentApplyIssueKind.areaNotFound,
        message: 'm',
        candidateId: 'c',
      );
      expect(i1, i2);
    });
  });

  group('ApplyEnvironmentGeneratedPlacementsUseCase', () {
    test('chemin heureux : placements, generatedPlacementIds, layers préservés',
        () {
      final ctx = _happyContext();
      final c1 = _cand(
        id: 'env_gen_area1_0_0_e1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final c2 = _cand(
        id: 'env_gen_area1_1_0_e1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 1,
        y: 0,
      );
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [c1, c2],
      );
      expect(r.hasErrors, isFalse);
      expect(r.appliedPlacementCount, 2);
      final env = r.map.layers.first as EnvironmentLayer;
      expect(env.content.targetTileLayerId, 'tiles');
      expect(env.content.areas.single.generatedPlacementIds,
          ['env_gen_area1_0_0_e1', 'env_gen_area1_1_0_e1']);
      final tile = r.map.layers[1] as TileLayer;
      expect(tile.tiles, ctx.tilesSnapshot);
      expect(r.map.placedElements.length, 2);
      expect(r.map.placedElements.map((e) => e.id).toList(),
          ['env_gen_area1_0_0_e1', 'env_gen_area1_1_0_e1']);
    });

    test('ordre des candidats = ordre placedElements et generatedPlacementIds',
        () {
      final ctx = _happyContext(mapW: 3, mapH: 1);
      final a = _cand(
        id: 'A',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final b = _cand(
        id: 'B',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 1,
        y: 0,
      );
      final c = _cand(
        id: 'C',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 2,
        y: 0,
      );
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [a, b, c],
      );
      expect(r.map.placedElements.map((e) => e.id).toList(), ['A', 'B', 'C']);
      final area =
          (r.map.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.generatedPlacementIds, ['A', 'B', 'C']);
    });

    test('collisionMode forceEnabled / forceDisabled / useElementDefault', () {
      final modes = [
        EnvironmentCollisionMode.forceEnabled,
        EnvironmentCollisionMode.forceDisabled,
        EnvironmentCollisionMode.useElementDefault,
      ];
      final expected = [true, false, true];
      for (var i = 0; i < modes.length; i++) {
        final ctxI = _happyContext(mapW: 3, mapH: 1, areaIdSuffix: '_$i');
        final cand = _cand(
          id: 'id_$i',
          env: 'env',
          area: 'area1_$i',
          preset: 'preset1',
          target: 'tiles',
          el: 'e1',
          x: i,
          y: 0,
          mode: modes[i],
        );
        final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
        final r = uc.execute(
          ctxI.map,
          manifest: ctxI.manifest,
          environmentLayerId: 'env',
          areaId: 'area1_$i',
          candidates: [cand],
        );
        expect(r.hasErrors, isFalse, reason: 'mode $i');
        expect(r.map.placedElements.single.applyCollision, expected[i]);
      }
    });

    test('tags candidat ne sont pas copiés vers MapPlacedElement.properties',
        () {
      final ctx = _happyContext();
      final cand = EnvironmentGeneratedPlacementCandidate(
        id: 't1',
        environmentLayerId: 'env',
        areaId: 'area1',
        presetId: 'preset1',
        targetLayerId: 'tiles',
        elementId: 'e1',
        pos: const GridPos(x: 0, y: 0),
        collisionMode: EnvironmentCollisionMode.useElementDefault,
        tags: {'canopy'},
      );
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(r.map.placedElements.single.properties, isEmpty);
    });

    test('erreurs layer / target / area', () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final cand = _singleCandidate(ctx);
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'missing',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r1.issuesForKind(EnvironmentApplyIssueKind.environmentLayerNotFound),
        isNotEmpty,
      );
      expect(identical(r1.map, ctx.map), isTrue);

      final tileMap = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 1),
        layers: [
          const MapLayer.tile(id: 'env', name: 'E', tiles: [0, 0]),
          TileLayer(id: 'tiles', name: 'T', tiles: const [0, 0]),
        ],
      );
      final r2 = uc.execute(
        tileMap,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r2.issuesForKind(EnvironmentApplyIssueKind.layerIsNotEnvironmentLayer),
        isNotEmpty,
      );

      final noTarget = _mapMissingTarget();
      final r3 = uc.execute(
        noTarget.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r3.issuesForKind(EnvironmentApplyIssueKind.targetTileLayerMissing),
        isNotEmpty,
      );

      final badTarget = _mapTargetObjectLayer();
      final r4 = uc.execute(
        badTarget.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(
        r4.issuesForKind(EnvironmentApplyIssueKind.targetTileLayerInvalid),
        isNotEmpty,
      );

      final r5 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'ghost',
        candidates: [cand],
      );
      expect(
          r5.issuesForKind(EnvironmentApplyIssueKind.areaNotFound), isNotEmpty);
    });

    test('emptyCandidates et areaAlreadyHasGeneratedPlacements', () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r1 = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: const [],
      );
      expect(r1.issuesForKind(EnvironmentApplyIssueKind.emptyCandidates),
          isNotEmpty);

      final withIds = _happyContext(
        preGeneratedIds: const ['old'],
      );
      final r2 = uc.execute(
        withIds.map,
        manifest: withIds.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [_singleCandidate(withIds)],
      );
      expect(
        r2.issuesForKind(
            EnvironmentApplyIssueKind.areaAlreadyHasGeneratedPlacements),
        isNotEmpty,
      );
    });

    test(
        'erreurs candidates : wrong layer, area, preset, target, element, bounds',
        () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final base = _singleCandidate(ctx);

      EnvironmentGeneratedPlacementCandidate copy({
        String? env,
        String? area,
        String? preset,
        String? target,
        String? el,
        int? x,
        int? y,
      }) {
        return EnvironmentGeneratedPlacementCandidate(
          id: base.id,
          environmentLayerId: env ?? base.environmentLayerId,
          areaId: area ?? base.areaId,
          presetId: preset ?? base.presetId,
          targetLayerId: target ?? base.targetLayerId,
          elementId: el ?? base.elementId,
          pos: GridPos(x: x ?? base.pos.x, y: y ?? base.pos.y),
          collisionMode: base.collisionMode,
          tags: base.tags,
        );
      }

      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(env: 'other')],
        ).issuesForKind(
            EnvironmentApplyIssueKind.candidateWrongEnvironmentLayer),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(area: 'other')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongArea),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(preset: 'wrong')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongPreset),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(target: 'wrong')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongTargetLayer),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(el: 'missing')],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateElementMissing),
        isNotEmpty,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [copy(x: 99)],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateOutOfBounds),
        isNotEmpty,
      );
    });

    test(
        'candidateDuplicateId, placedElementIdConflict, candidatePositionDuplicate',
        () {
      final ctx = _happyContext();
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final a = _singleCandidate(ctx);
      final b = EnvironmentGeneratedPlacementCandidate(
        id: a.id,
        environmentLayerId: a.environmentLayerId,
        areaId: a.areaId,
        presetId: a.presetId,
        targetLayerId: a.targetLayerId,
        elementId: a.elementId,
        pos: const GridPos(x: 1, y: 0),
        collisionMode: a.collisionMode,
        tags: a.tags,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [a, b],
        ).issuesForKind(EnvironmentApplyIssueKind.candidateDuplicateId),
        isNotEmpty,
      );

      final placed = MapPlacedElement(
        id: 'env_gen_area1_0_0_e1',
        layerId: 'tiles',
        elementId: 'e1',
        pos: const GridPos(x: 0, y: 0),
      );
      final mapWith = ctx.map.copyWith(placedElements: [placed]);
      expect(
        uc.execute(
          mapWith,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [_singleCandidate(ctx)],
        ).issuesForKind(EnvironmentApplyIssueKind.placedElementIdConflict),
        isNotEmpty,
      );

      final c1 = _cand(
        id: 'p1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final c2 = _cand(
        id: 'p2',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      expect(
        uc.execute(
          ctx.map,
          manifest: ctx.manifest,
          environmentLayerId: 'env',
          areaId: 'area1',
          candidates: [c1, c2],
        ).issuesForKind(EnvironmentApplyIssueKind.candidatePositionDuplicate),
        isNotEmpty,
      );
    });

    test('transactionnalité : deuxième candidate invalide → aucune mutation',
        () {
      final ctx = _happyContext(mapW: 3, mapH: 1);
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final good = _cand(
        id: 'g1',
        env: 'env',
        area: 'area1',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 0,
        y: 0,
      );
      final bad = _cand(
        id: 'g2',
        env: 'env',
        area: 'wrong_area',
        preset: 'preset1',
        target: 'tiles',
        el: 'e1',
        x: 1,
        y: 0,
      );
      final before = ctx.map;
      final r = uc.execute(
        before,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [good, bad],
      );
      expect(r.hasErrors, isTrue);
      expect(identical(r.map, before), isTrue);
      expect(r.map.placedElements, isEmpty);
      final area =
          (r.map.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.generatedPlacementIds, isEmpty);
    });

    test('ProjectManifest et TileLayer.tiles inchangés après succès', () {
      final ctx = _happyContext();
      final manifestBefore = ctx.manifest;
      final tilesBefore = (ctx.map.layers[1] as TileLayer).tiles;
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [_singleCandidate(ctx)],
      );
      expect(r.hasErrors, isFalse);
      expect(identical(r.map, ctx.map), isFalse);
      expect(
          manifestBefore.environmentPresets, ctx.manifest.environmentPresets);
      final tilesAfter = (r.map.layers[1] as TileLayer).tiles;
      expect(tilesAfter, tilesBefore);
    });

    test('intégration Lot 23 → Lot 24', () {
      final ctx = _happyContext(mapW: 2, mapH: 2);
      final gen = GenerateEnvironmentAreaPlacementsUseCase();
      final genResult = gen.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      expect(genResult.hasErrors, isFalse);
      expect(genResult.placementCount, greaterThan(0));
      final apply = ApplyEnvironmentGeneratedPlacementsUseCase();
      final applyResult = apply.execute(
        ctx.map,
        manifest: ctx.manifest,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: genResult.placements,
      );
      expect(applyResult.hasErrors, isFalse);
      expect(
        applyResult.appliedPlacementCount,
        genResult.placementCount,
      );
      final ids = genResult.placements.map((c) => c.id).toList();
      final area = (applyResult.map.layers.first as EnvironmentLayer)
          .content
          .areas
          .single;
      expect(area.generatedPlacementIds, ids);
    });

    test('mapValidationFailed : tileset layer vs element incompatible', () {
      final ctx = _happyContext(layerTilesetId: 'tsA');
      final manifestBad = ProjectManifest(
        name: 'p',
        maps: const [],
        tilesets: const [],
        elements: [
          ProjectElementEntry(
            id: 'e1',
            name: 'E',
            tilesetId: 'tsB',
            categoryId: 'c',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
        environmentPresets: [
          EnvironmentPreset(
            id: 'preset1',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(elementId: 'e1', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
      );
      final cand = _singleCandidate(ctx);
      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        ctx.map,
        manifest: manifestBad,
        environmentLayerId: 'env',
        areaId: 'area1',
        candidates: [cand],
      );
      expect(r.issuesForKind(EnvironmentApplyIssueKind.mapValidationFailed),
          isNotEmpty);
      expect(identical(r.map, ctx.map), isTrue);
    });
  });
}

EnvironmentGeneratedPlacementCandidate _singleCandidate(_HappyContext ctx) {
  return _cand(
    id: 'env_gen_area1_0_0_e1',
    env: 'env',
    area: 'area1',
    preset: 'preset1',
    target: 'tiles',
    el: 'e1',
    x: 0,
    y: 0,
  );
}

EnvironmentGeneratedPlacementCandidate _cand({
  required String id,
  required String env,
  required String area,
  required String preset,
  required String target,
  required String el,
  required int x,
  required int y,
  EnvironmentCollisionMode mode = EnvironmentCollisionMode.useElementDefault,
}) {
  return EnvironmentGeneratedPlacementCandidate(
    id: id,
    environmentLayerId: env,
    areaId: area,
    presetId: preset,
    targetLayerId: target,
    elementId: el,
    pos: GridPos(x: x, y: y),
    collisionMode: mode,
    tags: const {},
  );
}

class _HappyContext {
  _HappyContext({
    required this.map,
    required this.manifest,
    required this.tilesSnapshot,
  });

  final MapData map;
  final ProjectManifest manifest;
  final List<int> tilesSnapshot;
}

_HappyContext _happyContext({
  int mapW = 2,
  int mapH = 2,
  List<String>? preGeneratedIds,
  String areaIdSuffix = '',
  String? layerTilesetId,
}) {
  final n = mapW * mapH;
  final cells = List<bool>.filled(n, true);
  final mask = EnvironmentAreaMask(width: mapW, height: mapH, cells: cells);
  final areaId = 'area1$areaIdSuffix';
  final area = EnvironmentArea(
    id: areaId,
    name: 'Z',
    presetId: 'preset1',
    mask: mask,
    seed: 1,
    generatedPlacementIds: preGeneratedIds,
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'tiles',
      areas: [area],
    ),
  );
  final tiles = List<int>.filled(n, 7);
  final tile = MapLayer.tile(
    id: 'tiles',
    name: 'T',
    tilesetId: layerTilesetId,
    tiles: tiles,
  );
  final map = MapData(
    id: 'map1',
    name: 'Map',
    size: GridSize(width: mapW, height: mapH),
    tilesetId: layerTilesetId ?? 'tsA',
    layers: [env, tile],
  );
  final manifest = ProjectManifest(
    name: 'proj',
    maps: const [],
    tilesets: const [],
    elements: [
      ProjectElementEntry(
        id: 'e1',
        name: 'El',
        tilesetId: layerTilesetId ?? 'tsA',
        categoryId: 'cat',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'preset1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          edgeDensity: 1,
          variation: 0,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
  return _HappyContext(map: map, manifest: manifest, tilesSnapshot: tiles);
}

MapData _minimalMap() {
  return MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 1, height: 1),
    layers: [
      TileLayer(id: 't', name: 'T', tiles: const [0]),
    ],
  );
}

({MapData map}) _mapMissingTarget() {
  final mask = EnvironmentAreaMask(
    width: 2,
    height: 1,
    cells: const [true, true],
  );
  final area = EnvironmentArea(
    id: 'area1',
    name: 'Z',
    presetId: 'preset1',
    mask: mask,
    seed: 0,
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: null,
      areas: [area],
    ),
  );
  final map = MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 2, height: 1),
    layers: [
      env,
      TileLayer(id: 'tiles', name: 'T', tiles: const [0, 0]),
    ],
  );
  return (map: map);
}

({MapData map}) _mapTargetObjectLayer() {
  final mask = EnvironmentAreaMask(
    width: 2,
    height: 1,
    cells: const [true, true],
  );
  final area = EnvironmentArea(
    id: 'area1',
    name: 'Z',
    presetId: 'preset1',
    mask: mask,
    seed: 0,
  );
  final env = MapLayer.environment(
    id: 'env',
    name: 'E',
    content: EnvironmentLayerContent(
      targetTileLayerId: 'obj',
      areas: [area],
    ),
  );
  final map = MapData(
    id: 'm',
    name: 'M',
    size: const GridSize(width: 2, height: 1),
    layers: [
      env,
      const MapLayer.object(id: 'obj', name: 'O'),
    ],
  );
  return (map: map);
}
```

## 20. Diff complet

### 20.1 `git diff --no-index /dev/null` — apply use cases

```diff
diff --git a/packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart
new file mode 100644
index 00000000..b94845bc
--- /dev/null
+++ b/packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart
@@ -0,0 +1,606 @@
+import 'package:map_core/map_core.dart';
+
+import 'environment_generator_use_cases.dart';
+
+// ---------------------------------------------------------------------------
+// Lot Environment-24 — application des candidats Lot 23 → MapPlacedElement.
+// Aucune UI, aucun I/O, pas de mutation si erreur.
+// ---------------------------------------------------------------------------
+
+/// Lien entre un candidat Lot 23 et l’instance [MapPlacedElement] créée.
+final class EnvironmentAppliedGeneratedPlacement {
+  const EnvironmentAppliedGeneratedPlacement({
+    required this.candidateId,
+    required this.placedElementId,
+    required this.elementId,
+    required this.layerId,
+    required this.pos,
+  });
+
+  final String candidateId;
+  final String placedElementId;
+  final String elementId;
+  final String layerId;
+  final GridPos pos;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentAppliedGeneratedPlacement &&
+            candidateId == other.candidateId &&
+            placedElementId == other.placedElementId &&
+            elementId == other.elementId &&
+            layerId == other.layerId &&
+            pos == other.pos;
+  }
+
+  @override
+  int get hashCode =>
+      Object.hash(candidateId, placedElementId, elementId, layerId, pos);
+}
+
+enum EnvironmentApplyIssueSeverity {
+  error,
+}
+
+enum EnvironmentApplyIssueKind {
+  environmentLayerNotFound,
+  layerIsNotEnvironmentLayer,
+  targetTileLayerMissing,
+  targetTileLayerInvalid,
+  areaNotFound,
+  areaAlreadyHasGeneratedPlacements,
+  emptyCandidates,
+  candidateWrongEnvironmentLayer,
+  candidateWrongArea,
+  candidateWrongPreset,
+  candidateWrongTargetLayer,
+  candidateElementMissing,
+  candidateOutOfBounds,
+  candidateDuplicateId,
+  placedElementIdConflict,
+  candidatePositionDuplicate,
+  mapValidationFailed,
+}
+
+final class EnvironmentApplyIssue {
+  const EnvironmentApplyIssue({
+    required this.severity,
+    required this.kind,
+    required this.message,
+    this.environmentLayerId,
+    this.areaId,
+    this.candidateId,
+    this.targetLayerId,
+    this.elementId,
+    this.placedElementId,
+  });
+
+  final EnvironmentApplyIssueSeverity severity;
+  final EnvironmentApplyIssueKind kind;
+  final String message;
+  final String? environmentLayerId;
+  final String? areaId;
+  final String? candidateId;
+  final String? targetLayerId;
+  final String? elementId;
+  final String? placedElementId;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentApplyIssue &&
+            severity == other.severity &&
+            kind == other.kind &&
+            message == other.message &&
+            environmentLayerId == other.environmentLayerId &&
+            areaId == other.areaId &&
+            candidateId == other.candidateId &&
+            targetLayerId == other.targetLayerId &&
+            elementId == other.elementId &&
+            placedElementId == other.placedElementId;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        severity,
+        kind,
+        message,
+        environmentLayerId,
+        areaId,
+        candidateId,
+        targetLayerId,
+        elementId,
+        placedElementId,
+      );
+}
+
+final class EnvironmentApplyResult {
+  factory EnvironmentApplyResult({
+    required MapData map,
+    required List<EnvironmentAppliedGeneratedPlacement> appliedPlacements,
+    required List<EnvironmentApplyIssue> issues,
+  }) {
+    return EnvironmentApplyResult._(
+      map: map,
+      appliedPlacements:
+          List<EnvironmentAppliedGeneratedPlacement>.unmodifiable(
+        List<EnvironmentAppliedGeneratedPlacement>.from(appliedPlacements),
+      ),
+      issues: List<EnvironmentApplyIssue>.unmodifiable(
+        List<EnvironmentApplyIssue>.from(issues),
+      ),
+    );
+  }
+
+  const EnvironmentApplyResult._({
+    required this.map,
+    required this.appliedPlacements,
+    required this.issues,
+  });
+
+  final MapData map;
+  final List<EnvironmentAppliedGeneratedPlacement> appliedPlacements;
+  final List<EnvironmentApplyIssue> issues;
+
+  bool get hasErrors =>
+      issues.any((i) => i.severity == EnvironmentApplyIssueSeverity.error);
+
+  int get errorCount => issues
+      .where((i) => i.severity == EnvironmentApplyIssueSeverity.error)
+      .length;
+
+  int get appliedPlacementCount => appliedPlacements.length;
+
+  List<EnvironmentApplyIssue> issuesForKind(EnvironmentApplyIssueKind kind) {
+    return List<EnvironmentApplyIssue>.unmodifiable(
+      issues.where((i) => i.kind == kind).toList(growable: false),
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    if (identical(this, other)) return true;
+    return other is EnvironmentApplyResult &&
+        map == other.map &&
+        appliedPlacementCount == other.appliedPlacementCount &&
+        _listEqualsApplied(appliedPlacements, other.appliedPlacements) &&
+        _listEqualsApplyIssues(issues, other.issues);
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        map,
+        appliedPlacementCount,
+        Object.hashAll(appliedPlacements),
+        Object.hashAll(issues),
+      );
+}
+
+bool _listEqualsApplied(
+  List<EnvironmentAppliedGeneratedPlacement> a,
+  List<EnvironmentAppliedGeneratedPlacement> b,
+) {
+  if (a.length != b.length) return false;
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) return false;
+  }
+  return true;
+}
+
+bool _listEqualsApplyIssues(
+  List<EnvironmentApplyIssue> a,
+  List<EnvironmentApplyIssue> b,
+) {
+  if (a.length != b.length) return false;
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) return false;
+  }
+  return true;
+}
+
+bool _originInBounds(GridPos pos, GridSize size) {
+  return pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;
+}
+
+/// Footprint [MapValidator] quand [projectDialogueContext] est fourni (élément connu).
+bool _footprintInBounds({
+  required GridPos pos,
+  required GridSize mapSize,
+  required ProjectElementEntry element,
+}) {
+  final source = element.frames.primarySource;
+  final width = source.width <= 0 ? 1 : source.width;
+  final height = source.height <= 0 ? 1 : source.height;
+  final right = pos.x + width;
+  final bottom = pos.y + height;
+  return right <= mapSize.width && bottom <= mapSize.height;
+}
+
+bool _applyCollisionFromCandidate(EnvironmentCollisionMode mode) {
+  switch (mode) {
+    case EnvironmentCollisionMode.forceEnabled:
+      return true;
+    case EnvironmentCollisionMode.forceDisabled:
+      return false;
+    case EnvironmentCollisionMode.useElementDefault:
+      // [MapPlacedElement] défaut = true ; aligné sur l’indexeur d’instances tuiles.
+      // Le profil [ElementCollisionProfile] pilote la géométrie, pas ce booléen.
+      return true;
+  }
+}
+
+EnvironmentApplyResult _failure(
+  MapData original, {
+  required List<EnvironmentApplyIssue> issues,
+}) {
+  return EnvironmentApplyResult(
+    map: original,
+    appliedPlacements: const [],
+    issues: issues,
+  );
+}
+
+/// Applique des [EnvironmentGeneratedPlacementCandidate] sur une [MapData] en mémoire.
+///
+/// Transactionnel : la moindre erreur → [map] d’entrée inchangée, aucun placement créé.
+class ApplyEnvironmentGeneratedPlacementsUseCase {
+  EnvironmentApplyResult execute(
+    MapData map, {
+    required ProjectManifest manifest,
+    required String environmentLayerId,
+    required String areaId,
+    required List<EnvironmentGeneratedPlacementCandidate> candidates,
+  }) {
+    final issues = <EnvironmentApplyIssue>[];
+    final envId = environmentLayerId.trim();
+    final aid = areaId.trim();
+
+    EnvironmentLayer? envLayer;
+    for (final layer in map.layers) {
+      if (layer.id == envId) {
+        if (layer is EnvironmentLayer) {
+          envLayer = layer;
+        } else {
+          issues.add(
+            EnvironmentApplyIssue(
+              severity: EnvironmentApplyIssueSeverity.error,
+              kind: EnvironmentApplyIssueKind.layerIsNotEnvironmentLayer,
+              message: 'Layer is not an environment layer: $envId',
+              environmentLayerId: envId,
+            ),
+          );
+          return _failure(map, issues: issues);
+        }
+        break;
+      }
+    }
+    if (envLayer == null) {
+      issues.add(
+        EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.environmentLayerNotFound,
+          message: 'Environment layer not found: $envId',
+          environmentLayerId: envId,
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    final targetId = envLayer.content.targetTileLayerId?.trim();
+    if (targetId == null || targetId.isEmpty) {
+      issues.add(
+        EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.targetTileLayerMissing,
+          message: 'Environment layer has no target tile layer id',
+          environmentLayerId: envId,
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    var targetTileLayerFound = false;
+    for (final layer in map.layers) {
+      if (layer.id == targetId) {
+        if (layer is! TileLayer) {
+          issues.add(
+            EnvironmentApplyIssue(
+              severity: EnvironmentApplyIssueSeverity.error,
+              kind: EnvironmentApplyIssueKind.targetTileLayerInvalid,
+              message:
+                  'Target tile layer id does not reference a TileLayer: $targetId',
+              environmentLayerId: envId,
+              targetLayerId: targetId,
+            ),
+          );
+          return _failure(map, issues: issues);
+        }
+        targetTileLayerFound = true;
+        break;
+      }
+    }
+    if (!targetTileLayerFound) {
+      issues.add(
+        EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.targetTileLayerInvalid,
+          message: 'Target tile layer not found: $targetId',
+          environmentLayerId: envId,
+          targetLayerId: targetId,
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    EnvironmentArea? area;
+    for (final a in envLayer.content.areas) {
+      if (a.id == aid) {
+        area = a;
+        break;
+      }
+    }
+    if (area == null) {
+      issues.add(
+        EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.areaNotFound,
+          message: 'Environment area not found: $aid',
+          environmentLayerId: envId,
+          areaId: aid,
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    if (area.generatedPlacementIds.isNotEmpty) {
+      issues.add(
+        EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.areaAlreadyHasGeneratedPlacements,
+          message:
+              'Environment area already has generated placements (${area.generatedPlacementIds.length})',
+          environmentLayerId: envId,
+          areaId: aid,
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    if (candidates.isEmpty) {
+      issues.add(
+        const EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.emptyCandidates,
+          message: 'No placement candidates to apply',
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    final elementById = <String, ProjectElementEntry>{
+      for (final e in manifest.elements) e.id: e,
+    };
+
+    final seenCandidateIds = <String>{};
+    final seenPositions = <String>{};
+    final existingPlacedIds = <String>{
+      for (final p in map.placedElements) p.id,
+    };
+    final stagedPlacedIds = <String>{};
+
+    for (final c in candidates) {
+      if (!seenCandidateIds.add(c.id)) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateDuplicateId,
+            message: 'Duplicate candidate id: ${c.id}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+
+      if (c.environmentLayerId.trim() != envId) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateWrongEnvironmentLayer,
+            message: 'Candidate environmentLayerId mismatch: ${c.id}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+      if (c.areaId.trim() != aid) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateWrongArea,
+            message: 'Candidate areaId mismatch: ${c.id}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+      if (c.presetId.trim() != area.presetId.trim()) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateWrongPreset,
+            message: 'Candidate presetId mismatch: ${c.id}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+      if (c.targetLayerId.trim() != targetId) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateWrongTargetLayer,
+            message: 'Candidate targetLayerId mismatch: ${c.id}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+            targetLayerId: c.targetLayerId,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+
+      final entry = elementById[c.elementId.trim()];
+      if (entry == null) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateElementMissing,
+            message: 'Candidate references unknown element: ${c.elementId}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+            elementId: c.elementId,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+
+      if (!_originInBounds(c.pos, map.size) ||
+          !_footprintInBounds(pos: c.pos, mapSize: map.size, element: entry)) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidateOutOfBounds,
+            message:
+                'Candidate position or footprint out of map bounds: ${c.id}',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+            elementId: c.elementId,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+
+      final placedId = c.id;
+      if (existingPlacedIds.contains(placedId) ||
+          stagedPlacedIds.contains(placedId)) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.placedElementIdConflict,
+            message: 'Placed element id already exists: $placedId',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+            placedElementId: placedId,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+
+      final posKey = '${c.targetLayerId.trim()}|${c.pos.x}|${c.pos.y}';
+      if (!seenPositions.add(posKey)) {
+        issues.add(
+          EnvironmentApplyIssue(
+            severity: EnvironmentApplyIssueSeverity.error,
+            kind: EnvironmentApplyIssueKind.candidatePositionDuplicate,
+            message: 'Duplicate candidate position on layer: $posKey',
+            environmentLayerId: envId,
+            areaId: aid,
+            candidateId: c.id,
+            targetLayerId: c.targetLayerId,
+          ),
+        );
+        return _failure(map, issues: issues);
+      }
+
+      stagedPlacedIds.add(placedId);
+    }
+
+    final newPlaced = <MapPlacedElement>[
+      ...map.placedElements,
+    ];
+    final applied = <EnvironmentAppliedGeneratedPlacement>[];
+    final newPlacementIds = <String>[];
+
+    for (final c in candidates) {
+      final applyCollision = _applyCollisionFromCandidate(c.collisionMode);
+      final placed = MapPlacedElement(
+        id: c.id,
+        layerId: c.targetLayerId.trim(),
+        elementId: c.elementId.trim(),
+        pos: c.pos,
+        applyCollision: applyCollision,
+      );
+      newPlaced.add(placed);
+      newPlacementIds.add(c.id);
+      applied.add(
+        EnvironmentAppliedGeneratedPlacement(
+          candidateId: c.id,
+          placedElementId: c.id,
+          elementId: c.elementId.trim(),
+          layerId: c.targetLayerId.trim(),
+          pos: c.pos,
+        ),
+      );
+    }
+
+    final newAreas = <EnvironmentArea>[
+      for (final a in envLayer.content.areas)
+        if (a.id == aid)
+          EnvironmentArea(
+            id: a.id,
+            name: a.name,
+            presetId: a.presetId,
+            mask: a.mask,
+            seed: a.seed,
+            paramsOverride: a.paramsOverride,
+            generatedPlacementIds: newPlacementIds,
+          )
+        else
+          a,
+    ];
+
+    final newContent = EnvironmentLayerContent(
+      targetTileLayerId: envLayer.content.targetTileLayerId,
+      areas: newAreas,
+    );
+
+    MapData updated;
+    try {
+      updated = setEnvironmentLayerContent(
+        map,
+        layerId: envId,
+        content: newContent,
+      ).copyWith(placedElements: newPlaced);
+      MapValidator.validate(updated, projectDialogueContext: manifest);
+    } catch (e) {
+      issues.add(
+        EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.mapValidationFailed,
+          message: 'MapValidator.validate failed: $e',
+          environmentLayerId: envId,
+          areaId: aid,
+        ),
+      );
+      return _failure(map, issues: issues);
+    }
+
+    return EnvironmentApplyResult(
+      map: updated,
+      appliedPlacements: applied,
+      issues: const [],
+    );
+  }
+}
```

### 20.2 `git diff --no-index /dev/null` — tests

```diff
diff --git a/packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart b/packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart
new file mode 100644
index 00000000..a668989c
--- /dev/null
+++ b/packages/map_editor/test/environment_studio/environment_generator_apply_candidates_test.dart
@@ -0,0 +1,845 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/application/use_cases/environment_generator_apply_use_cases.dart';
+import 'package:map_editor/src/application/use_cases/environment_generator_use_cases.dart';
+
+void main() {
+  group('EnvironmentApplyResult / modèles', () {
+    test(
+        'EnvironmentApplyResult copie défensivement et expose des listes immuables',
+        () {
+      final m = _minimalMap();
+      final rawApplied = <EnvironmentAppliedGeneratedPlacement>[
+        const EnvironmentAppliedGeneratedPlacement(
+          candidateId: 'c1',
+          placedElementId: 'c1',
+          elementId: 'e1',
+          layerId: 'tiles',
+          pos: GridPos(x: 0, y: 0),
+        ),
+      ];
+      final rawIssues = <EnvironmentApplyIssue>[
+        const EnvironmentApplyIssue(
+          severity: EnvironmentApplyIssueSeverity.error,
+          kind: EnvironmentApplyIssueKind.emptyCandidates,
+          message: 'x',
+        ),
+      ];
+      final r = EnvironmentApplyResult(
+        map: m,
+        appliedPlacements: rawApplied,
+        issues: rawIssues,
+      );
+      rawApplied.clear();
+      rawIssues.clear();
+      expect(r.appliedPlacementCount, 1);
+      expect(r.errorCount, 1);
+      expect(() => r.appliedPlacements.clear(), throwsUnsupportedError);
+      expect(() => r.issues.clear(), throwsUnsupportedError);
+      expect(
+          r.issuesForKind(EnvironmentApplyIssueKind.emptyCandidates).length, 1);
+    });
+
+    test(
+        'EnvironmentAppliedGeneratedPlacement et EnvironmentApplyIssue égalité',
+        () {
+      const a = EnvironmentAppliedGeneratedPlacement(
+        candidateId: 'c',
+        placedElementId: 'p',
+        elementId: 'e',
+        layerId: 'l',
+        pos: GridPos(x: 1, y: 2),
+      );
+      const b = EnvironmentAppliedGeneratedPlacement(
+        candidateId: 'c',
+        placedElementId: 'p',
+        elementId: 'e',
+        layerId: 'l',
+        pos: GridPos(x: 1, y: 2),
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+
+      const i1 = EnvironmentApplyIssue(
+        severity: EnvironmentApplyIssueSeverity.error,
+        kind: EnvironmentApplyIssueKind.areaNotFound,
+        message: 'm',
+        candidateId: 'c',
+      );
+      const i2 = EnvironmentApplyIssue(
+        severity: EnvironmentApplyIssueSeverity.error,
+        kind: EnvironmentApplyIssueKind.areaNotFound,
+        message: 'm',
+        candidateId: 'c',
+      );
+      expect(i1, i2);
+    });
+  });
+
+  group('ApplyEnvironmentGeneratedPlacementsUseCase', () {
+    test('chemin heureux : placements, generatedPlacementIds, layers préservés',
+        () {
+      final ctx = _happyContext();
+      final c1 = _cand(
+        id: 'env_gen_area1_0_0_e1',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 0,
+        y: 0,
+      );
+      final c2 = _cand(
+        id: 'env_gen_area1_1_0_e1',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 1,
+        y: 0,
+      );
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [c1, c2],
+      );
+      expect(r.hasErrors, isFalse);
+      expect(r.appliedPlacementCount, 2);
+      final env = r.map.layers.first as EnvironmentLayer;
+      expect(env.content.targetTileLayerId, 'tiles');
+      expect(env.content.areas.single.generatedPlacementIds,
+          ['env_gen_area1_0_0_e1', 'env_gen_area1_1_0_e1']);
+      final tile = r.map.layers[1] as TileLayer;
+      expect(tile.tiles, ctx.tilesSnapshot);
+      expect(r.map.placedElements.length, 2);
+      expect(r.map.placedElements.map((e) => e.id).toList(),
+          ['env_gen_area1_0_0_e1', 'env_gen_area1_1_0_e1']);
+    });
+
+    test('ordre des candidats = ordre placedElements et generatedPlacementIds',
+        () {
+      final ctx = _happyContext(mapW: 3, mapH: 1);
+      final a = _cand(
+        id: 'A',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 0,
+        y: 0,
+      );
+      final b = _cand(
+        id: 'B',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 1,
+        y: 0,
+      );
+      final c = _cand(
+        id: 'C',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 2,
+        y: 0,
+      );
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [a, b, c],
+      );
+      expect(r.map.placedElements.map((e) => e.id).toList(), ['A', 'B', 'C']);
+      final area =
+          (r.map.layers.first as EnvironmentLayer).content.areas.single;
+      expect(area.generatedPlacementIds, ['A', 'B', 'C']);
+    });
+
+    test('collisionMode forceEnabled / forceDisabled / useElementDefault', () {
+      final modes = [
+        EnvironmentCollisionMode.forceEnabled,
+        EnvironmentCollisionMode.forceDisabled,
+        EnvironmentCollisionMode.useElementDefault,
+      ];
+      final expected = [true, false, true];
+      for (var i = 0; i < modes.length; i++) {
+        final ctxI = _happyContext(mapW: 3, mapH: 1, areaIdSuffix: '_$i');
+        final cand = _cand(
+          id: 'id_$i',
+          env: 'env',
+          area: 'area1_$i',
+          preset: 'preset1',
+          target: 'tiles',
+          el: 'e1',
+          x: i,
+          y: 0,
+          mode: modes[i],
+        );
+        final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+        final r = uc.execute(
+          ctxI.map,
+          manifest: ctxI.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1_$i',
+          candidates: [cand],
+        );
+        expect(r.hasErrors, isFalse, reason: 'mode $i');
+        expect(r.map.placedElements.single.applyCollision, expected[i]);
+      }
+    });
+
+    test('tags candidat ne sont pas copiés vers MapPlacedElement.properties',
+        () {
+      final ctx = _happyContext();
+      final cand = EnvironmentGeneratedPlacementCandidate(
+        id: 't1',
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        presetId: 'preset1',
+        targetLayerId: 'tiles',
+        elementId: 'e1',
+        pos: const GridPos(x: 0, y: 0),
+        collisionMode: EnvironmentCollisionMode.useElementDefault,
+        tags: {'canopy'},
+      );
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [cand],
+      );
+      expect(r.map.placedElements.single.properties, isEmpty);
+    });
+
+    test('erreurs layer / target / area', () {
+      final ctx = _happyContext();
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final cand = _singleCandidate(ctx);
+      final r1 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'missing',
+        areaId: 'area1',
+        candidates: [cand],
+      );
+      expect(
+        r1.issuesForKind(EnvironmentApplyIssueKind.environmentLayerNotFound),
+        isNotEmpty,
+      );
+      expect(identical(r1.map, ctx.map), isTrue);
+
+      final tileMap = MapData(
+        id: 'm',
+        name: 'M',
+        size: const GridSize(width: 2, height: 1),
+        layers: [
+          const MapLayer.tile(id: 'env', name: 'E', tiles: [0, 0]),
+          TileLayer(id: 'tiles', name: 'T', tiles: const [0, 0]),
+        ],
+      );
+      final r2 = uc.execute(
+        tileMap,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [cand],
+      );
+      expect(
+        r2.issuesForKind(EnvironmentApplyIssueKind.layerIsNotEnvironmentLayer),
+        isNotEmpty,
+      );
+
+      final noTarget = _mapMissingTarget();
+      final r3 = uc.execute(
+        noTarget.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [cand],
+      );
+      expect(
+        r3.issuesForKind(EnvironmentApplyIssueKind.targetTileLayerMissing),
+        isNotEmpty,
+      );
+
+      final badTarget = _mapTargetObjectLayer();
+      final r4 = uc.execute(
+        badTarget.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [cand],
+      );
+      expect(
+        r4.issuesForKind(EnvironmentApplyIssueKind.targetTileLayerInvalid),
+        isNotEmpty,
+      );
+
+      final r5 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'ghost',
+        candidates: [cand],
+      );
+      expect(
+          r5.issuesForKind(EnvironmentApplyIssueKind.areaNotFound), isNotEmpty);
+    });
+
+    test('emptyCandidates et areaAlreadyHasGeneratedPlacements', () {
+      final ctx = _happyContext();
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final r1 = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: const [],
+      );
+      expect(r1.issuesForKind(EnvironmentApplyIssueKind.emptyCandidates),
+          isNotEmpty);
+
+      final withIds = _happyContext(
+        preGeneratedIds: const ['old'],
+      );
+      final r2 = uc.execute(
+        withIds.map,
+        manifest: withIds.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [_singleCandidate(withIds)],
+      );
+      expect(
+        r2.issuesForKind(
+            EnvironmentApplyIssueKind.areaAlreadyHasGeneratedPlacements),
+        isNotEmpty,
+      );
+    });
+
+    test(
+        'erreurs candidates : wrong layer, area, preset, target, element, bounds',
+        () {
+      final ctx = _happyContext();
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final base = _singleCandidate(ctx);
+
+      EnvironmentGeneratedPlacementCandidate copy({
+        String? env,
+        String? area,
+        String? preset,
+        String? target,
+        String? el,
+        int? x,
+        int? y,
+      }) {
+        return EnvironmentGeneratedPlacementCandidate(
+          id: base.id,
+          environmentLayerId: env ?? base.environmentLayerId,
+          areaId: area ?? base.areaId,
+          presetId: preset ?? base.presetId,
+          targetLayerId: target ?? base.targetLayerId,
+          elementId: el ?? base.elementId,
+          pos: GridPos(x: x ?? base.pos.x, y: y ?? base.pos.y),
+          collisionMode: base.collisionMode,
+          tags: base.tags,
+        );
+      }
+
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [copy(env: 'other')],
+        ).issuesForKind(
+            EnvironmentApplyIssueKind.candidateWrongEnvironmentLayer),
+        isNotEmpty,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [copy(area: 'other')],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongArea),
+        isNotEmpty,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [copy(preset: 'wrong')],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongPreset),
+        isNotEmpty,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [copy(target: 'wrong')],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidateWrongTargetLayer),
+        isNotEmpty,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [copy(el: 'missing')],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidateElementMissing),
+        isNotEmpty,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [copy(x: 99)],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidateOutOfBounds),
+        isNotEmpty,
+      );
+    });
+
+    test(
+        'candidateDuplicateId, placedElementIdConflict, candidatePositionDuplicate',
+        () {
+      final ctx = _happyContext();
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final a = _singleCandidate(ctx);
+      final b = EnvironmentGeneratedPlacementCandidate(
+        id: a.id,
+        environmentLayerId: a.environmentLayerId,
+        areaId: a.areaId,
+        presetId: a.presetId,
+        targetLayerId: a.targetLayerId,
+        elementId: a.elementId,
+        pos: const GridPos(x: 1, y: 0),
+        collisionMode: a.collisionMode,
+        tags: a.tags,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [a, b],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidateDuplicateId),
+        isNotEmpty,
+      );
+
+      final placed = MapPlacedElement(
+        id: 'env_gen_area1_0_0_e1',
+        layerId: 'tiles',
+        elementId: 'e1',
+        pos: const GridPos(x: 0, y: 0),
+      );
+      final mapWith = ctx.map.copyWith(placedElements: [placed]);
+      expect(
+        uc.execute(
+          mapWith,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [_singleCandidate(ctx)],
+        ).issuesForKind(EnvironmentApplyIssueKind.placedElementIdConflict),
+        isNotEmpty,
+      );
+
+      final c1 = _cand(
+        id: 'p1',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 0,
+        y: 0,
+      );
+      final c2 = _cand(
+        id: 'p2',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 0,
+        y: 0,
+      );
+      expect(
+        uc.execute(
+          ctx.map,
+          manifest: ctx.manifest,
+          environmentLayerId: 'env',
+          areaId: 'area1',
+          candidates: [c1, c2],
+        ).issuesForKind(EnvironmentApplyIssueKind.candidatePositionDuplicate),
+        isNotEmpty,
+      );
+    });
+
+    test('transactionnalité : deuxième candidate invalide → aucune mutation',
+        () {
+      final ctx = _happyContext(mapW: 3, mapH: 1);
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final good = _cand(
+        id: 'g1',
+        env: 'env',
+        area: 'area1',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 0,
+        y: 0,
+      );
+      final bad = _cand(
+        id: 'g2',
+        env: 'env',
+        area: 'wrong_area',
+        preset: 'preset1',
+        target: 'tiles',
+        el: 'e1',
+        x: 1,
+        y: 0,
+      );
+      final before = ctx.map;
+      final r = uc.execute(
+        before,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [good, bad],
+      );
+      expect(r.hasErrors, isTrue);
+      expect(identical(r.map, before), isTrue);
+      expect(r.map.placedElements, isEmpty);
+      final area =
+          (r.map.layers.first as EnvironmentLayer).content.areas.single;
+      expect(area.generatedPlacementIds, isEmpty);
+    });
+
+    test('ProjectManifest et TileLayer.tiles inchangés après succès', () {
+      final ctx = _happyContext();
+      final manifestBefore = ctx.manifest;
+      final tilesBefore = (ctx.map.layers[1] as TileLayer).tiles;
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [_singleCandidate(ctx)],
+      );
+      expect(r.hasErrors, isFalse);
+      expect(identical(r.map, ctx.map), isFalse);
+      expect(
+          manifestBefore.environmentPresets, ctx.manifest.environmentPresets);
+      final tilesAfter = (r.map.layers[1] as TileLayer).tiles;
+      expect(tilesAfter, tilesBefore);
+    });
+
+    test('intégration Lot 23 → Lot 24', () {
+      final ctx = _happyContext(mapW: 2, mapH: 2);
+      final gen = GenerateEnvironmentAreaPlacementsUseCase();
+      final genResult = gen.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+      );
+      expect(genResult.hasErrors, isFalse);
+      expect(genResult.placementCount, greaterThan(0));
+      final apply = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final applyResult = apply.execute(
+        ctx.map,
+        manifest: ctx.manifest,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: genResult.placements,
+      );
+      expect(applyResult.hasErrors, isFalse);
+      expect(
+        applyResult.appliedPlacementCount,
+        genResult.placementCount,
+      );
+      final ids = genResult.placements.map((c) => c.id).toList();
+      final area = (applyResult.map.layers.first as EnvironmentLayer)
+          .content
+          .areas
+          .single;
+      expect(area.generatedPlacementIds, ids);
+    });
+
+    test('mapValidationFailed : tileset layer vs element incompatible', () {
+      final ctx = _happyContext(layerTilesetId: 'tsA');
+      final manifestBad = ProjectManifest(
+        name: 'p',
+        maps: const [],
+        tilesets: const [],
+        elements: [
+          ProjectElementEntry(
+            id: 'e1',
+            name: 'E',
+            tilesetId: 'tsB',
+            categoryId: 'c',
+            frames: const [
+              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
+            ],
+          ),
+        ],
+        surfaceCatalog: ProjectSurfaceCatalog(),
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'preset1',
+            name: 'P',
+            templateId: 't',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+      );
+      final cand = _singleCandidate(ctx);
+      final uc = ApplyEnvironmentGeneratedPlacementsUseCase();
+      final r = uc.execute(
+        ctx.map,
+        manifest: manifestBad,
+        environmentLayerId: 'env',
+        areaId: 'area1',
+        candidates: [cand],
+      );
+      expect(r.issuesForKind(EnvironmentApplyIssueKind.mapValidationFailed),
+          isNotEmpty);
+      expect(identical(r.map, ctx.map), isTrue);
+    });
+  });
+}
+
+EnvironmentGeneratedPlacementCandidate _singleCandidate(_HappyContext ctx) {
+  return _cand(
+    id: 'env_gen_area1_0_0_e1',
+    env: 'env',
+    area: 'area1',
+    preset: 'preset1',
+    target: 'tiles',
+    el: 'e1',
+    x: 0,
+    y: 0,
+  );
+}
+
+EnvironmentGeneratedPlacementCandidate _cand({
+  required String id,
+  required String env,
+  required String area,
+  required String preset,
+  required String target,
+  required String el,
+  required int x,
+  required int y,
+  EnvironmentCollisionMode mode = EnvironmentCollisionMode.useElementDefault,
+}) {
+  return EnvironmentGeneratedPlacementCandidate(
+    id: id,
+    environmentLayerId: env,
+    areaId: area,
+    presetId: preset,
+    targetLayerId: target,
+    elementId: el,
+    pos: GridPos(x: x, y: y),
+    collisionMode: mode,
+    tags: const {},
+  );
+}
+
+class _HappyContext {
+  _HappyContext({
+    required this.map,
+    required this.manifest,
+    required this.tilesSnapshot,
+  });
+
+  final MapData map;
+  final ProjectManifest manifest;
+  final List<int> tilesSnapshot;
+}
+
+_HappyContext _happyContext({
+  int mapW = 2,
+  int mapH = 2,
+  List<String>? preGeneratedIds,
+  String areaIdSuffix = '',
+  String? layerTilesetId,
+}) {
+  final n = mapW * mapH;
+  final cells = List<bool>.filled(n, true);
+  final mask = EnvironmentAreaMask(width: mapW, height: mapH, cells: cells);
+  final areaId = 'area1$areaIdSuffix';
+  final area = EnvironmentArea(
+    id: areaId,
+    name: 'Z',
+    presetId: 'preset1',
+    mask: mask,
+    seed: 1,
+    generatedPlacementIds: preGeneratedIds,
+  );
+  final env = MapLayer.environment(
+    id: 'env',
+    name: 'E',
+    content: EnvironmentLayerContent(
+      targetTileLayerId: 'tiles',
+      areas: [area],
+    ),
+  );
+  final tiles = List<int>.filled(n, 7);
+  final tile = MapLayer.tile(
+    id: 'tiles',
+    name: 'T',
+    tilesetId: layerTilesetId,
+    tiles: tiles,
+  );
+  final map = MapData(
+    id: 'map1',
+    name: 'Map',
+    size: GridSize(width: mapW, height: mapH),
+    tilesetId: layerTilesetId ?? 'tsA',
+    layers: [env, tile],
+  );
+  final manifest = ProjectManifest(
+    name: 'proj',
+    maps: const [],
+    tilesets: const [],
+    elements: [
+      ProjectElementEntry(
+        id: 'e1',
+        name: 'El',
+        tilesetId: layerTilesetId ?? 'tsA',
+        categoryId: 'cat',
+        frames: const [
+          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
+        ],
+      ),
+    ],
+    surfaceCatalog: ProjectSurfaceCatalog(),
+    environmentPresets: [
+      EnvironmentPreset(
+        id: 'preset1',
+        name: 'P',
+        templateId: 't',
+        palette: [
+          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
+        ],
+        defaultParams: EnvironmentGenerationParams(
+          density: 1,
+          edgeDensity: 1,
+          variation: 0,
+          minSpacingCells: 0,
+        ),
+        sortOrder: 0,
+      ),
+    ],
+  );
+  return _HappyContext(map: map, manifest: manifest, tilesSnapshot: tiles);
+}
+
+MapData _minimalMap() {
+  return MapData(
+    id: 'm',
+    name: 'M',
+    size: const GridSize(width: 1, height: 1),
+    layers: [
+      TileLayer(id: 't', name: 'T', tiles: const [0]),
+    ],
+  );
+}
+
+({MapData map}) _mapMissingTarget() {
+  final mask = EnvironmentAreaMask(
+    width: 2,
+    height: 1,
+    cells: const [true, true],
+  );
+  final area = EnvironmentArea(
+    id: 'area1',
+    name: 'Z',
+    presetId: 'preset1',
+    mask: mask,
+    seed: 0,
+  );
+  final env = MapLayer.environment(
+    id: 'env',
+    name: 'E',
+    content: EnvironmentLayerContent(
+      targetTileLayerId: null,
+      areas: [area],
+    ),
+  );
+  final map = MapData(
+    id: 'm',
+    name: 'M',
+    size: const GridSize(width: 2, height: 1),
+    layers: [
+      env,
+      TileLayer(id: 'tiles', name: 'T', tiles: const [0, 0]),
+    ],
+  );
+  return (map: map);
+}
+
+({MapData map}) _mapTargetObjectLayer() {
+  final mask = EnvironmentAreaMask(
+    width: 2,
+    height: 1,
+    cells: const [true, true],
+  );
+  final area = EnvironmentArea(
+    id: 'area1',
+    name: 'Z',
+    presetId: 'preset1',
+    mask: mask,
+    seed: 0,
+  );
+  final env = MapLayer.environment(
+    id: 'env',
+    name: 'E',
+    content: EnvironmentLayerContent(
+      targetTileLayerId: 'obj',
+      areas: [area],
+    ),
+  );
+  final map = MapData(
+    id: 'm',
+    name: 'M',
+    size: const GridSize(width: 2, height: 1),
+    layers: [
+      env,
+      const MapLayer.object(id: 'obj', name: 'O'),
+    ],
+  );
+  return (map: map);
+}
```

## 21. Auto-review

**Points solides** : transaction stricte ; validation `MapValidator` finale ; couverture tests large ; `placedElementId = candidate.id` traçable avec Lot 23.

**Points discutables** : `useElementDefault` → `applyCollision: true` uniformément (approximation vs profil collision élément) ; message `mapValidationFailed` inclut `$e` (verbeux).

**Corrections après auto-review** : suppression variable locale `entry` inutilisée dans la boucle de construction (warning `dart analyze`).

**Risques restants** : incohérence manifeste / carte (tileset) déclenche `mapValidationFailed` — attendu.

**Regard critique sur le prompt** :

- Refuser `generatedPlacementIds` non vides : **oui**, évite doublons et suppressions implicites.
- Consommer les candidates plutôt que régénérer : **oui**, use case pur sans effet de bord manifest.
- `placedElementId = candidate.id` : **cohérent** avec Lot 23 ; conflit explicite si id déjà pris.
- Persister collision/tags : **collision via `applyCollision`** ; **tags non** sans étendre `map_core`.
- Transactionnalité : **suffisante** V0 (validation avant construction + validate final).
- Hors UI / notifier / canvas / bouton Generate : **respecté**.

## 22. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
Use case apply + 14 tests verts ; environment_studio +184 ; bundle régression +78 ; dart analyze 0 erreur (infos const tests). flutter test map_editor +1017 -34 hors périmètre (dette préexistante).
```

Prochain lot recommandé :

```text
Environment-25 — Environment Generate Button Wiring in Inspector V0
```
