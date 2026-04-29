# Surface Engine Lot 116 — MovementEffectZonePayload Model V0

Date: 2026-04-29
Repo: `/Users/karim/Project/pokemonProject`

## 1. Résumé exécutif honnête

Lot 116 ajoute la source persistante typée attendue côté `map_core` pour les futurs effets de mouvement Surface : `GameplayZoneKind.movementEffect`, `MovementEffectZoneKind`, `MovementEffectZonePayload`, et le champ optionnel `MapGameplayZone.movementEffect`. Le modèle JSON/Freezed a été régénéré, les validations core acceptent une zone `movementEffect` valide et rejettent les cas sans payload ou `movementCost <= 0`.

Aucune glissade, aucun ralentissement runtime et aucune production de `Moved.movementEffect` n’ont été codés. `map_gameplay` production et `map_runtime` production ne sont pas modifiés. `map_editor` production a reçu uniquement la plomberie minimale nécessaire pour compiler proprement le nouveau kind enum et préserver l’édition générique d’une zone `movementEffect`; aucune action Ice, aucun dialog Ice et aucune UX Surface Ice n’ont été ajoutés.

## 2. Périmètre

Inclus dans le Lot 116 :

- Ajout du kind persistant `GameplayZoneKind.movementEffect` dans `map_core`.
- Ajout de `MovementEffectZoneKind.slide` et `MovementEffectZoneKind.movementCost` dans `map_core`.
- Ajout de `MovementEffectZonePayload(effectKind, movementCost)`.
- Ajout du champ `MapGameplayZone.movementEffect`.
- Mise à jour Freezed/JSON générée dans `packages/map_core` uniquement.
- Validation `movementEffect` côté opérations core et `MapValidator`.
- Tests modèle/JSON/validation core.
- Adaptation minimale `map_editor` pour le nouveau enum et la propagation du payload générique.

Exclus : runtime ice, glissade, mouvement forcé, movement cost appliqué, production de `Moved.movementEffect`, modification de `stepGameplayWorld`, action/dialog Ice, Surface Painter Ice, migration legacy, filtre `surfacePresetId`.

## 3. Gate 0 — status initial

Commande initiale exécutée avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 12
find . -name AGENTS.md -print
```

Sortie initiale complète observée :

```text
/Users/karim/Project/pokemonProject
main
?? reports/surface/surface_engine_lot_115_ice_sliding_runtime_source_contract_prep.md
3aae74a6 lot 114: Surface Movement Effect Runtime Prep
830b8b5b lot 113
011b4bc1 fix bridge
09a9b0df lot 112: Ice Mud Movement Semantics Decision
f57ade04 Merge PSDK battle parity work
993b0033 Complete PSDK battle parity batch
a294999b lot 110: Lava Hazard Runtime E2E Closure
af24a783 lot 109: Editor Generate Lava Hazard Zone from Surface
3ef5fc92 lot 108: Hazard Runtime Consumption Prep
e8bfc68e lot 107: Lava Hazard from Surface Workflow Decision
4851b53f lot 106: Surface Behavior Action Menu
2305f276 lot 104: Surface Gameplay Bridge Runtime E2E Closure
./AGENTS.md
```

`git diff --stat` initial n’a produit aucune ligne. Changement préexistant identifié : `reports/surface/surface_engine_lot_115_ice_sliding_runtime_source_contract_prep.md` était déjà non suivi avant le Lot 116 et n’a pas été modifié par ce lot.

## 4. Context Mode usage

Context Mode était demandé et a été tenté, mais indisponible dans cette session :

```text
Tool mcp__context_mode__ctx_batch_execute is not currently available.
```

Le workflow a donc continué avec des commandes shell ciblées, en limitant les sorties conversationnelles aux constats utiles. La commande finale demandée a aussi été exécutée :

```bash
ctx stats
```

Résultat :

```text
zsh:1: command not found: ctx
```

Résumé compact des économies Context Mode : 0 commande indexée, 0 token économisé par Context Mode, car l’outil `ctx` n’était pas disponible.

## 5. Audit Lots 114 / 115

Commande :

```bash
rg -n "Lot 114|Lot 115|GameplayMovementEffect|GameplayMovementEffectKind|Moved.movementEffect|MovementEffectZonePayload|GameplayZoneKind.movementEffect|movementEffect|SpecialZonePayload|MovementZonePayload" reports/surface packages/map_core/lib packages/map_gameplay/lib packages/map_gameplay/test
```

Findings :

- Lot 114 a livré le contrat runtime porteur côté `map_gameplay` : `GameplayMovementEffect`, `GameplayMovementEffectKind.slide`, `GameplayMovementEffectKind.movementCost`, et `Moved.movementEffect`.
- Les tests Lot 114 confirment que `stepGameplayWorld` ne produit pas encore de `movementEffect`, que `movementEffect` est `null` par défaut et que `hazardEffect` reste séparé.
- Lot 115 décide que la source persistante produit doit être typée : `GameplayZoneKind.movementEffect` + un payload explicite. SurfaceLayer direct, `MovementZonePayload` étendu, `SpecialZonePayload(scriptKey)` et `custom` sont rejetés pour le produit.
- Conclusion : `map_core` devait évoluer maintenant; `map_gameplay` ne devait pas évoluer dans ce lot, car le mapping runtime viendra plus tard.

## 6. Audit MapGameplayZone / payloads existants

Commande :

```bash
rg -n "enum GameplayZoneKind|class MapGameplayZone|freezed class MapGameplayZone|MovementZonePayload|HazardZonePayload|EncounterZonePayload|SpecialZonePayload|custom|movement:|hazard:|special:|encounter:" packages/map_core/lib packages/map_core/test
```

Findings :

- `GameplayZoneKind` vivait dans `packages/map_core/lib/src/models/enums.dart` avec `encounter`, `movement`, `hazard`, `special`, `custom`.
- `MapGameplayZone` vivait dans `packages/map_core/lib/src/models/map_data.dart` et portait les payloads `encounter`, `movement`, `hazard`, `special`.
- Les payloads typés vivaient dans `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`.
- `MovementZonePayload` représentait un gate de déplacement (`requiredMode`, `allowedModes`), pas un effet Surface comme la glissade ou un coût.
- `SpecialZonePayload` représentait `scriptKey` + propriétés libres, trop string-based pour être la source produit du movement effect.
- `custom` est documenté comme fallback non typé et ne doit pas être utilisé par du nouveau code.

## 7. Audit Freezed / JSON / generated

Commande :

```bash
rg -n "part .*freezed|part .*g.dart|JsonSerializable|fromJson|toJson|build_runner|MapGameplayZoneFromJson|GameplayZoneKind|movementEffect|migrateMapGameplayZoneJson" packages/map_core/lib packages/map_core/test pubspec.yaml packages/map_core/pubspec.yaml
```

Résultat notable : la commande a aussi signalé `rg: pubspec.yaml: No such file or directory` car il n’y a pas de `pubspec.yaml` à la racine. `packages/map_core/pubspec.yaml` contient `build_runner: ^2.4.8`.

Findings :

- `MapGameplayZone` et les payloads sont Freezed/JSON, donc build_runner était nécessaire.
- Fichiers générés modifiés : `map_data.freezed.dart`, `map_data.g.dart`, `map_gameplay_zone_payloads.freezed.dart`, `map_gameplay_zone_payloads.g.dart`.
- Aucun generated hors `packages/map_core` n’a été produit par la commande.
- Les anciens JSON sans champ `movementEffect` restent compatibles car le nouveau champ est nullable et absent par défaut.
- Le nouveau JSON encode `kind: "movementEffect"` et `movementEffect: {"effectKind":"slide","movementCost":1}` pour le cas slide par défaut.

## 8. Audit validations gameplay zones

Commande :

```bash
rg -n "addGameplayZoneToMap|updateGameplayZoneOnMap|validate|GameplayZone|gameplay zone|duplicate|area|MapRect|kind|payload|movementEffect" packages/map_core/lib packages/map_core/test
```

Findings :

- `addGameplayZoneToMap` et `updateGameplayZoneOnMap` normalisaient et validaient id, doublon, aire et propriétés `special`.
- `MapValidator.validate` validait aussi id, kind, background encounter, special props, aire, bounds, doublons.
- Il n’existait pas de validation kind/payload pour le nouveau besoin.
- Lot 116 ajoute une validation minimale : une zone `kind == movementEffect` exige `movementEffect != null`; tout payload `movementEffect` avec `movementCost <= 0` est rejeté.

## 9. Audit switches editor / compile impact

Commande :

```bash
rg -n "GameplayZoneKind\.|switch \(.*GameplayZoneKind|switch.*zone.kind|case GameplayZoneKind|movement|hazard|special|custom" packages/map_editor/lib packages/map_editor/test packages/map_runtime/lib packages/map_gameplay/lib packages/map_core/lib
```

Findings :

- `GameplayZonePropertiesPanel` avait des switches exhaustifs et un formulaire par kind.
- `MapGridPainter` avait un switch exhaustif pour les couleurs de zones gameplay.
- Les services éditeur de mise à jour de zone ne propageaient pas `movementEffect`.
- Ces adaptations ont été faites uniquement pour compilation et édition générique du nouveau kind; aucune action Ice, aucun dialog Ice et aucun comportement Surface Ice n’ont été ajoutés.

## 10. Décision de design

Décision retenue :

- Ajouter `GameplayZoneKind.movementEffect` dans `map_core`.
- Ajouter une enum core séparée `MovementEffectZoneKind` avec `slide` et `movementCost`.
- Ajouter un payload simple `MovementEffectZonePayload(effectKind, movementCost)`.
- Ajouter un champ nullable `MapGameplayZone.movementEffect`.
- Valider `movementCost > 0` côté opérations et `MapValidator`, plutôt que dans le constructeur Freezed, pour rester aligné avec le style existant des payloads.
- Garder `MovementZonePayload` comme gate de déplacement, et `MovementEffectZonePayload` comme source d’effet de mouvement.
- Ne pas importer `map_gameplay` dans `map_core`; un lot futur fera le mapping `MovementEffectZoneKind -> GameplayMovementEffectKind`.

## 11. Nouveau GameplayZoneKind

`GameplayZoneKind.movementEffect` existe maintenant avec JSON value `movementEffect`. Il est placé à côté de `movement` mais documenté comme distinct : `movement` reste une contrainte/gate, `movementEffect` porte des effets comme slide ou movement cost.

## 12. Nouveau MovementEffectZonePayload

Le payload V0 :

```dart
const MovementEffectZonePayload({
  MovementEffectZoneKind effectKind = MovementEffectZoneKind.slide,
  int movementCost = 1,
})
```

`movementCost` est conservé par défaut à `1` pour un JSON stable. Il est pertinent pour `MovementEffectZoneKind.movementCost`; pour `slide`, il n’est pas consommé par ce lot. La validation rejette `movementCost <= 0`.

## 13. JSON / compat

JSON réellement obtenu par le test roundtrip :

```json
{
  "id": "ice-slide",
  "name": "Ice Slide",
  "kind": "movementEffect",
  "area": {
    "pos": {"x": 1, "y": 2},
    "size": {"width": 3, "height": 2}
  },
  "priority": 4,
  "movementEffect": {
    "effectKind": "slide",
    "movementCost": 1
  }
}
```

Les anciens JSON `encounter`, `movement` et `hazard` sans `movementEffect` décodent toujours avec `movementEffect == null`, ce qui est couvert par le test dédié.

## 14. Build runner

Commande lancée :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Sortie complète :

```text
Generating the build script.
Reading the asset graph.
Checking for updates.
Updating the asset graph.
Building, incremental build.
0s freezed on 172 inputs; lib/map_core.dart
W SDK language version 3.10.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
0s freezed on 172 inputs: 1 no-op; lib/src/collision/element_collision_legacy_migration.dart
1s freezed on 172 inputs: 5 skipped, 1 same, 1 no-op; spent 1s analyzing; lib/src/models/enums.dart
3s freezed on 172 inputs: 12 skipped, 2 output, 7 same, 2 no-op; spent 2s analyzing; lib/src/models/scenario_asset.dart
3s freezed on 172 inputs: 145 skipped, 2 output, 9 same, 16 no-op; spent 2s analyzing
0s json_serializable on 344 inputs; lib/map_core.dart
1s json_serializable on 344 inputs: 1 no-op; lib/map_core.freezed.dart
W json_serializable on lib/src/models/element_collision_profile.dart:
The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
2s json_serializable on 344 inputs: 28 skipped, 2 output, 6 same, 5 no-op; spent 2s analyzing; lib/src/models/project_manifest.freezed.dart
3s json_serializable on 344 inputs: 120 skipped, 2 output, 9 same, 54 no-op; spent 3s analyzing; test/dialogue_library_tree_test.freezed.dart
4s json_serializable on 344 inputs: 180 skipped, 2 output, 9 same, 114 no-op; spent 3s analyzing; test/surface_catalog_authoring_diagnostics_test.freezed.dart
5s json_serializable on 344 inputs: 200 skipped, 2 output, 9 same, 133 no-op; spent 4s analyzing
0s source_gen:combining_builder on 344 inputs; lib/map_core.dart
0s source_gen:combining_builder on 344 inputs: 324 skipped, 2 output, 9 same, 9 no-op
Running the post build.
Writing the asset graph.
Built with build_runner in 9s; wrote 33 outputs.
```

Warnings documentés : version SDK/analyzer et contrainte `json_annotation` existante. Le build a réussi.

## 15. Tests lancés

Commandes de test et validation lancées :

```bash
cd packages/map_core && dart test test/map_gameplay_zone_movement_effect_payload_test.dart --reporter expanded
cd packages/map_core && dart test test/map_gameplay_zone_validation_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
cd packages/map_core && dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
cd packages/map_core && dart test
cd packages/map_gameplay && dart test test/gameplay_movement_effect_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/hazard_runtime_consumption_test.dart --reporter expanded
cd packages/map_gameplay && dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
cd packages/map_editor && flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
cd packages/map_runtime && flutter test test/surface --reporter expanded
```

Un test rouge TDD initial a aussi été lancé avant implémentation : `test/map_gameplay_zone_movement_effect_payload_test.dart` échouait au chargement parce que `MovementEffectZoneKind`, `MovementEffectZonePayload`, `GameplayZoneKind.movementEffect`, `MapGameplayZone.movementEffect` et le paramètre `movementEffect` n’existaient pas encore. C’était le rouge attendu.

## 16. Résultats

Lignes finales exactes observées :

```text
dart test test/map_gameplay_zone_movement_effect_payload_test.dart --reporter expanded
00:00 +14: All tests passed!

dart test test/map_gameplay_zone_validation_test.dart --reporter expanded
00:00 +1: All tests passed!

dart test test/surface_to_gameplay_zone_generation_plan_test.dart --reporter expanded
00:00 +16: All tests passed!

dart test test/surface_to_gameplay_zone_generation_assessment_test.dart --reporter expanded
00:00 +12: All tests passed!

dart test
00:02 +1297: All tests passed!

dart test test/gameplay_movement_effect_test.dart --reporter expanded
00:00 +12: All tests passed!

dart test test/hazard_runtime_consumption_test.dart --reporter expanded
00:00 +8: All tests passed!

dart test test/surface_generated_gameplay_zone_bridge_test.dart --reporter expanded
00:00 +6: All tests passed!

flutter test test/surface_painter/surface_to_gameplay_zone_action_test.dart --no-pub --reporter expanded
00:01 +29: All tests passed!

flutter test test/surface --reporter expanded
00:01 +29: All tests passed!
```

## 17. Analyse lancée

Commandes :

```bash
cd packages/map_core && dart analyze lib/src/models/enums.dart lib/src/models/map_data.dart lib/src/models/map_data.freezed.dart lib/src/models/map_data.g.dart lib/src/models/map_gameplay_zone_payloads.dart lib/src/models/map_gameplay_zone_payloads.freezed.dart lib/src/models/map_gameplay_zone_payloads.g.dart lib/src/operations/map_gameplay_zones.dart lib/src/validation/validators.dart test/map_gameplay_zone_movement_effect_payload_test.dart
cd packages/map_editor && flutter analyze lib/src/application/services/gameplay_zone_editing_coordinator.dart lib/src/application/services/gameplay_zone_editing_service.dart lib/src/application/use_cases/gameplay_zone_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart lib/src/ui/panels/gameplay_zone_properties_panel.dart
```

Note : une première passe `dart analyze` a remonté trois infos `curly_braces_in_flow_control_structures` dans `map_gameplay_zones.dart` et deux infos `constant_identifier_names` dans `enums.dart`. Les trois premières ont été corrigées par des accolades dans un fichier déjà touché. Les deux constantes legacy `upper_floor` et `sub_area` ont été couvertes par `ignore_for_file: constant_identifier_names` pour ne pas renommer une API historique.

## 18. Résultats analyze

Sorties finales exactes :

```text
Analyzing enums.dart, map_data.dart, map_data.freezed.dart, map_data.g.dart, map_gameplay_zone_payloads.dart, map_gameplay_zone_payloads.freezed.dart, map_gameplay_zone_payloads.g.dart, map_gameplay_zones.dart, validators.dart, map_gameplay_zone_movement_effect_payload_test.dart...
No issues found!

Analyzing 6 items...
No issues found! (ran in 1.8s)
```

## 19. Fichiers créés

- `packages/map_core/test/map_gameplay_zone_movement_effect_payload_test.dart`
- `reports/surface/surface_engine_lot_116_movement_effect_zone_payload_model.md`

Note : le rapport courant est listé comme fichier créé, mais il n’est pas recopié dans son propre contenu conformément à l’exception demandée.

## 20. Fichiers modifiés

- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_data.freezed.dart`
- `packages/map_core/lib/src/models/map_data.g.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.freezed.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.g.dart`
- `packages/map_core/lib/src/operations/map_gameplay_zones.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_editor/lib/src/application/services/gameplay_zone_editing_coordinator.dart`
- `packages/map_editor/lib/src/application/services/gameplay_zone_editing_service.dart`
- `packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart`

## 21. Fichiers supprimés

Aucun fichier supprimé.

## 22. Contenu complet des fichiers créés

### packages/map_core/test/map_gameplay_zone_movement_effect_payload_test.dart

````dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MovementEffectZonePayload', () {
    test('exposes slide and movementCost effect kinds', () {
      expect(MovementEffectZoneKind.values,
          contains(MovementEffectZoneKind.slide));
      expect(
        MovementEffectZoneKind.values,
        contains(MovementEffectZoneKind.movementCost),
      );
    });

    test('slide defaults to a valid payload', () {
      const payload = MovementEffectZonePayload();

      expect(payload.effectKind, MovementEffectZoneKind.slide);
      expect(payload.movementCost, 1);
    });

    test('movementCost supports positive cost and value equality', () {
      const first = MovementEffectZonePayload(
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 2,
      );
      const second = MovementEffectZonePayload(
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 2,
      );
      const different = MovementEffectZonePayload();

      expect(first.effectKind, MovementEffectZoneKind.movementCost);
      expect(first.movementCost, 2);
      expect(first, second);
      expect(first, isNot(different));
    });

    test('encodes and decodes slide JSON', () {
      const payload = MovementEffectZonePayload();

      final json = payload.toJson();
      final decoded = MovementEffectZonePayload.fromJson(json);

      expect(json, {'effectKind': 'slide', 'movementCost': 1});
      expect(decoded, payload);
    });

    test('encodes and decodes movementCost JSON', () {
      const payload = MovementEffectZonePayload(
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 3,
      );

      final json = payload.toJson();
      final decoded = MovementEffectZonePayload.fromJson(json);

      expect(json, {'effectKind': 'movementCost', 'movementCost': 3});
      expect(decoded, payload);
    });
  });

  group('MapGameplayZone movementEffect payload', () {
    test('can carry a movementEffect zone payload', () {
      const zone = MapGameplayZone(
        id: 'ice-slide',
        name: 'Ice Slide',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        priority: 4,
        movementEffect: MovementEffectZonePayload(),
      );

      expect(zone.movementEffect, const MovementEffectZonePayload());
      expect(zone.kind, GameplayZoneKind.movementEffect);
    });

    test('roundtrips movementEffect zone JSON', () {
      const zone = MapGameplayZone(
        id: 'ice-slide',
        name: 'Ice Slide',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        priority: 4,
        movementEffect: MovementEffectZonePayload(),
      );

      final json =
          jsonDecode(jsonEncode(zone.toJson())) as Map<String, dynamic>;
      final decoded = MapGameplayZone.fromJson(json);

      expect(json['kind'], 'movementEffect');
      expect(
          json['movementEffect'], {'effectKind': 'slide', 'movementCost': 1});
      expect(decoded, zone);
    });

    test('old encounter movement and hazard JSON remain compatible', () {
      final encounter = MapGameplayZone.fromJson({
        'id': 'encounter-zone',
        'kind': 'encounter',
        'area': _areaJson(),
        'encounter': {'encounterKind': 'walk'},
      });
      final movement = MapGameplayZone.fromJson({
        'id': 'movement-zone',
        'kind': 'movement',
        'area': _areaJson(),
        'movement': {'requiredMode': 'surf'},
      });
      final hazard = MapGameplayZone.fromJson({
        'id': 'hazard-zone',
        'kind': 'hazard',
        'area': _areaJson(),
        'hazard': {'hazardKind': 'lava', 'damagePerStep': 5},
      });

      expect(encounter.movementEffect, isNull);
      expect(movement.movementEffect, isNull);
      expect(hazard.movementEffect, isNull);
    });
  });

  group('movementEffect gameplay zone validation', () {
    test('addGameplayZoneToMap accepts a valid movementEffect zone', () {
      final updated = addGameplayZoneToMap(
        _map(),
        zone: _movementEffectZone(),
      );

      expect(
          updated.gameplayZones.single.kind, GameplayZoneKind.movementEffect);
      expect(
        updated.gameplayZones.single.movementEffect,
        const MovementEffectZonePayload(),
      );
    });

    test('updateGameplayZoneOnMap accepts a valid movementEffect zone', () {
      final updated = updateGameplayZoneOnMap(
        _map(gameplayZones: [_encounterZone()]),
        zoneId: 'zone',
        kind: GameplayZoneKind.movementEffect,
        encounter: null,
        movementEffect: const MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.movementCost,
          movementCost: 2,
        ),
      );

      expect(
          updated.gameplayZones.single.kind, GameplayZoneKind.movementEffect);
      expect(
        updated.gameplayZones.single.movementEffect,
        const MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.movementCost,
          movementCost: 2,
        ),
      );
    });

    test('MapValidator accepts a valid movementEffect zone', () {
      expect(
        () =>
            MapValidator.validate(_map(gameplayZones: [_movementEffectZone()])),
        returnsNormally,
      );
    });

    test('rejects movementEffect kind without payload', () {
      const zone = MapGameplayZone(
        id: 'ice-slide',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      );

      expect(
        () => addGameplayZoneToMap(_map(), zone: zone),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(_map(gameplayZones: [zone])),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive movementCost', () {
      const zone = MapGameplayZone(
        id: 'mud-cost',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
        movementEffect: MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.movementCost,
          movementCost: 0,
        ),
      );

      expect(
        () => addGameplayZoneToMap(_map(), zone: zone),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(_map(gameplayZones: [zone])),
        throwsA(isA<ValidationException>()),
      );
    });

    test('keeps duplicate id and invalid area validation intact', () {
      expect(
        () => addGameplayZoneToMap(
          _map(gameplayZones: [_movementEffectZone()]),
          zone: _movementEffectZone(),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => addGameplayZoneToMap(
          _map(),
          zone: _movementEffectZone(
            area: const MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 0, height: 1),
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

Map<String, dynamic> _areaJson() {
  return {
    'pos': {'x': 1, 'y': 1},
    'size': {'width': 1, 'height': 1},
  };
}

MapData _map({
  List<MapGameplayZone> gameplayZones = const [],
}) {
  return MapData(
    id: 'movement_effect_model_map',
    name: 'Movement Effect Model Map',
    size: const GridSize(width: 4, height: 4),
    gameplayZones: gameplayZones,
  );
}

MapGameplayZone _encounterZone() {
  return const MapGameplayZone(
    id: 'zone',
    kind: GameplayZoneKind.encounter,
    area: MapRect(
      pos: GridPos(x: 1, y: 1),
      size: GridSize(width: 1, height: 1),
    ),
    encounter: EncounterZonePayload(),
  );
}

MapGameplayZone _movementEffectZone({
  MapRect area = const MapRect(
    pos: GridPos(x: 1, y: 1),
    size: GridSize(width: 1, height: 1),
  ),
}) {
  return MapGameplayZone(
    id: 'ice-slide',
    kind: GameplayZoneKind.movementEffect,
    area: area,
    movementEffect: const MovementEffectZonePayload(),
  );
}

````

### reports/surface/surface_engine_lot_116_movement_effect_zone_payload_model.md

Le rapport courant n’est pas recopié en lui-même conformément à l’exception demandée.

## 23. Contenu complet des fichiers modifiés

### packages/map_core/lib/src/models/enums.dart

````dart
// ignore_for_file: constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

enum ProjectVersion { v1 }

enum MapGroupType {
  @JsonValue('city')
  city,
  @JsonValue('village')
  village,
  @JsonValue('route')
  route,
  @JsonValue('dungeon')
  dungeon,
  @JsonValue('cave')
  cave,
  @JsonValue('forest')
  forest,
  @JsonValue('tower')
  tower,
  @JsonValue('facility')
  facility,
  @JsonValue('special')
  special,
}

enum MapRole {
  @JsonValue('exterior')
  exterior,
  @JsonValue('interior')
  interior,
  @JsonValue('basement')
  basement,
  @JsonValue('upper_floor')
  upper_floor,
  @JsonValue('connector')
  connector,
  @JsonValue('gate')
  gate,
  @JsonValue('room')
  room,
  @JsonValue('section')
  section,
  @JsonValue('sub_area')
  sub_area,
}

enum MapConnectionDirection {
  @JsonValue('north')
  north,
  @JsonValue('south')
  south,
  @JsonValue('east')
  east,
  @JsonValue('west')
  west,
}

extension MapConnectionDirectionX on MapConnectionDirection {
  MapConnectionDirection get opposite => switch (this) {
        MapConnectionDirection.north => MapConnectionDirection.south,
        MapConnectionDirection.south => MapConnectionDirection.north,
        MapConnectionDirection.east => MapConnectionDirection.west,
        MapConnectionDirection.west => MapConnectionDirection.east,
      };

  bool get usesHorizontalOffset =>
      this == MapConnectionDirection.north ||
      this == MapConnectionDirection.south;
}

enum MapEntityKind {
  @JsonValue('npc')
  npc,
  @JsonValue('sign')
  sign,
  @JsonValue('item')
  item,
  @JsonValue('spawn')
  spawn,
  @JsonValue('custom')
  custom,
}

/// Orientation d’un sprite / d’un spawn sur la grille (vue top-down).
enum EntityFacing {
  @JsonValue('north')
  north,
  @JsonValue('south')
  south,
  @JsonValue('east')
  east,
  @JsonValue('west')
  west,
}

enum ItemPickupMode {
  @JsonValue('once')
  once,
  @JsonValue('always')
  always,
  @JsonValue('quest_gated')
  questGated,
}

enum ItemRespawnPolicy {
  @JsonValue('none')
  none,
  @JsonValue('on_map_reload')
  onMapReload,
  @JsonValue('timed')
  timed,
}

enum EntitySpawnRole {
  @JsonValue('player_start')
  playerStart,
  @JsonValue('event')
  event,
  @JsonValue('npc_spawn')
  npcSpawn,
  @JsonValue('debug')
  debug,
  @JsonValue('other')
  other,
}

enum TriggerType {
  @JsonValue('warp')
  warp,
  @JsonValue('message')
  message,
  @JsonValue('interaction')
  interaction,
  @JsonValue('event')
  event,
  @JsonValue('spawn')
  spawn,
  @JsonValue('camera')
  camera,
  @JsonValue('custom')
  custom,
}

enum MapLayerKind {
  @JsonValue('tile')
  tile,
  @JsonValue('collision')
  collision,
  @JsonValue('terrain')
  terrain,
  @JsonValue('path')
  path,
  @JsonValue('object')
  object,
}

enum TerrainType {
  @JsonValue('none')
  none,
  @JsonValue('grass')
  grass,
  @JsonValue('dirt')
  dirt,
  @JsonValue('sand')
  sand,
  @JsonValue('rock')
  rock,
  @JsonValue('stone')
  stone,
  @JsonValue('indoor')
  indoor,
}

extension TerrainTypeX on TerrainType {
  bool get isBackgroundPaintable => this != TerrainType.none;
}

enum TerrainPathVariant {
  isolated,
  endNorth,
  endEast,
  endSouth,
  endWest,
  horizontal,
  vertical,
  cornerNE,
  cornerSE,
  cornerSW,
  cornerNW,
  innerCornerNE,
  innerCornerSE,
  innerCornerSW,
  innerCornerNW,
  teeNorth,
  teeEast,
  teeSouth,
  teeWest,
  cross,
}

enum PresetLibraryKind {
  @JsonValue('terrain')
  terrain,
  @JsonValue('path')
  path,
}

enum PathSurfaceKind {
  @JsonValue('path')
  path,
  @JsonValue('road')
  road,
  @JsonValue('water')
  water,
  @JsonValue('tall_grass')
  tallGrass,
  @JsonValue('ice')
  ice,
  @JsonValue('lava')
  lava,
  @JsonValue('swamp')
  swamp,
  @JsonValue('rails')
  rails,
  @JsonValue('bridge')
  bridge,
  @JsonValue('special')
  special,
  @JsonValue('custom')
  custom,
}

enum PathAnimationMode {
  @JsonValue('always_active')
  alwaysActive,
  @JsonValue('triggered')
  triggered,
}

enum PathAnimationTriggerType {
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_step')
  onStep,
  @JsonValue('on_near')
  onNear,
  @JsonValue('on_action')
  onAction,
  @JsonValue('while_inside')
  whileInside,
  @JsonValue('on_bump')
  onBump,
}

enum PathAnimationPlaybackMode {
  @JsonValue('play_once')
  playOnce,
  @JsonValue('loop_while_active')
  loopWhileActive,
  @JsonValue('restart_on_trigger')
  restartOnTrigger,
}

enum PathAnimationActivationScope {
  @JsonValue('whole_layer')
  wholeLayer,
  @JsonValue('cell_only')
  cellOnly,
}

/// Kind de zone gameplay posée sur une map.
/// Sépare explicitement le visuel (PathSurfaceKind / TerrainType) du comportement.
///
/// Chaque kind correspond à un payload typé ([EncounterZonePayload],
/// [MovementZonePayload], [MovementEffectZonePayload],
/// [HazardZonePayload], [SpecialZonePayload]).
/// `custom` est réservé aux extensions futures — ne pas l'utiliser dans du
/// nouveau code ; préférer un kind typé.
enum GameplayZoneKind {
  @JsonValue('encounter')
  encounter, // Zone de rencontre aléatoire (herbes, grotte, surf, etc.)
  @JsonValue('movement')
  movement, // Zone à contrainte de déplacement (surf requis, etc.)
  @JsonValue('movementEffect')
  movementEffect, // Zone qui déclenche un effet de mouvement (glissade, coût, etc.)
  @JsonValue('hazard')
  hazard, // Danger environnemental (lave, marais, etc.)
  @JsonValue('special')
  special, // Comportement scripté ou spécial
  /// Fallback non-typé pour les extensions futures.
  /// Ne pas utiliser dans du nouveau code.
  @JsonValue('custom')
  custom,
}

/// Effet de mouvement persistant porté par [GameplayZoneKind.movementEffect].
///
/// Cette enum vit dans `map_core` pour rester indépendante du runtime
/// `map_gameplay`, qui fera plus tard le mapping vers GameplayMovementEffect.
enum MovementEffectZoneKind {
  @JsonValue('slide')
  slide,
  @JsonValue('movementCost')
  movementCost,
}

/// Sous-type de danger environnemental pour [GameplayZoneKind.hazard].
enum HazardKind {
  @JsonValue('lava')
  lava, // Contact : dommage direct
  @JsonValue('poison')
  poison, // Empoisonnement au passage
  @JsonValue('swamp')
  swamp, // Ralentissement / enlisement
  @JsonValue('pitfall')
  pitfall, // Chute dans un trou
  @JsonValue('other')
  other,
}

/// Mode de déplacement requis ou appliqué dans une zone gameplay.
enum MovementMode {
  @JsonValue('walk')
  walk,
  @JsonValue('surf')
  surf,
  @JsonValue('fly')
  fly,
  @JsonValue('cut')
  cut,
  @JsonValue('strength')
  strength,
  @JsonValue('rock_smash')
  rockSmash,
}

/// Capacité de terrain débloquable par la progression du joueur.
enum FieldAbility {
  @JsonValue('surf')
  surf,
  @JsonValue('cut')
  cut,
  @JsonValue('strength')
  strength,
  @JsonValue('flash')
  flash,
  @JsonValue('rock_smash')
  rockSmash,
  @JsonValue('waterfall')
  waterfall,
  @JsonValue('dive')
  dive;

  /// Identifiant canonique de la capacité, utilisé comme move ID dans [PlayerPokemon.knownMoveIds].
  String get moveId => switch (this) {
        FieldAbility.surf => 'surf',
        FieldAbility.cut => 'cut',
        FieldAbility.strength => 'strength',
        FieldAbility.flash => 'flash',
        FieldAbility.rockSmash => 'rock_smash',
        FieldAbility.waterfall => 'waterfall',
        FieldAbility.dive => 'dive',
      };
}

/// Mode de déclenchement d'une rencontre Pokémon-like.
enum EncounterKind {
  @JsonValue('walk')
  walk, // Herbes hautes, caverne, etc.
  @JsonValue('surf')
  surf, // Navigation sur l'eau
  @JsonValue('headbutt')
  headbutt, // Secouer un arbre
  @JsonValue('old_rod')
  oldRod,
  @JsonValue('good_rod')
  goodRod,
  @JsonValue('super_rod')
  superRod,
  @JsonValue('gift')
  gift, // Rencontre / don statique
  @JsonValue('special')
  special, // Déclenchement ad-hoc
}

enum CharacterAnimationState {
  @JsonValue('idle')
  idle,
  @JsonValue('walk')
  walk,
  @JsonValue('run')
  run,
}

enum TilesetScope {
  @JsonValue('global')
  global,
  @JsonValue('group')
  group,
}

enum ElementPresetKind {
  @JsonValue('generic')
  generic,
  @JsonValue('tree')
  tree,
  @JsonValue('building')
  building,
  @JsonValue('rock')
  rock,
  @JsonValue('cliff')
  cliff,
  @JsonValue('tall_decoration')
  tallDecoration,
}

enum ElementCollisionProfileSource {
  @JsonValue('generated')
  generated,
  @JsonValue('manual')
  manual,
}

/// Encodage d'un masque collision pixel-level.
///
/// `packed_bits_v1`:
/// - ordre des pixels: row-major (y puis x), origine en haut-gauche;
/// - 1 bit par pixel (1 = solide gameplay, 0 = passable);
/// - sérialisé en base64.
enum ElementCollisionMaskEncoding {
  @JsonValue('packed_bits_v1')
  packedBitsV1,
}

enum MapPlacedElementAnimationMode {
  @JsonValue('none')
  none,
  @JsonValue('loop')
  loop,
  @JsonValue('ping_pong')
  pingPong,
}

enum PaletteCategory {
  @JsonValue('floors')
  floors,
  @JsonValue('paths')
  paths,
  @JsonValue('water')
  water,
  @JsonValue('buildings')
  buildings,
  @JsonValue('roofs')
  roofs,
  @JsonValue('plants')
  plants,
  @JsonValue('trees')
  trees,
  @JsonValue('cliffs')
  cliffs,
  @JsonValue('decorations')
  decorations,
  @JsonValue('interiors')
  interiors,
  @JsonValue('objects')
  objects,
  @JsonValue('uncategorized')
  uncategorized,
}

````

### packages/map_core/lib/src/models/map_data.dart

````dart
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'map_entity_editor_visual.dart';
import 'map_entity_payloads.dart';
import 'map_event_definition.dart';
import 'map_gameplay_zone_payloads.dart';
import 'map_layer.dart';
import 'map_metadata.dart';

part 'map_data.freezed.dart';
part 'map_data.g.dart';

@freezed
class MapData with _$MapData {
  @JsonSerializable(explicitToJson: true)
  const factory MapData({
    required String id,
    required String name,
    required GridSize size,
    @Default(ProjectVersion.v1) ProjectVersion version,
    @Default('') String tilesetId,
    @Default([]) List<MapLayer> layers,
    @Default([]) List<MapPlacedElement> placedElements,
    @Default([]) List<MapEntity> entities,
    @Default([]) List<MapConnection> connections,
    @Default([]) List<MapWarp> warps,
    @Default([]) List<MapTrigger> triggers,

    /// Zones gameplay (rencontres, déplacement, dangers, etc.).
    /// Séparées des triggers (logiques scriptées) et des layers visuelles.
    @Default([]) List<MapGameplayZone> gameplayZones,
    @Default(MapMetadata()) MapMetadata mapMetadata,
    @Default({}) Map<String, dynamic> properties,
    @Default([]) List<MapEventDefinition> events,
  }) = _MapData;

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
}

// ---------------------------------------------------------------------------
// MapGameplayZone
// ---------------------------------------------------------------------------

/// Zone gameplay rectangulaire sur une map.
///
/// Sépare le **comportement gameplay** (rencontres, déplacement, danger)
/// du **visuel** ([PathSurfaceKind] / [TerrainType]).
///
/// Chaque [kind] dispose d'un payload typé :
/// - [encounter] → [EncounterZonePayload]
/// - [movement]  → [MovementZonePayload]
/// - [movementEffect] → [MovementEffectZonePayload]
/// - [hazard]    → [HazardZonePayload]
/// - [special] / [custom] → [SpecialZonePayload]
///
/// Le runtime peut lire ces zones pour décider : tirer une rencontre,
/// appliquer un effet de déplacement, déclencher un script, etc.
@freezed
class MapGameplayZone with _$MapGameplayZone {
  @JsonSerializable(explicitToJson: true)
  const factory MapGameplayZone({
    required String id,
    @Default('') String name,
    required GameplayZoneKind kind,
    required MapRect area,

    /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
    @Default(0) int priority,

    /// Payload pour [GameplayZoneKind.encounter].
    EncounterZonePayload? encounter,

    /// Payload pour [GameplayZoneKind.movement].
    MovementZonePayload? movement,

    /// Payload pour [GameplayZoneKind.movementEffect].
    MovementEffectZonePayload? movementEffect,

    /// Payload pour [GameplayZoneKind.hazard].
    HazardZonePayload? hazard,

    /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
    SpecialZonePayload? special,
  }) = _MapGameplayZone;

  factory MapGameplayZone.fromJson(Map<String, dynamic> json) =>
      _$MapGameplayZoneFromJson(migrateMapGameplayZoneJson(json));
}

@freezed
class MapPlacedElement with _$MapPlacedElement {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElement({
    required String id,
    required String layerId,
    required String elementId,
    required GridPos pos,
    @Default(true) bool applyCollision,
    MapPlacedElementAnimation? animation,
    @Default([]) List<MapPlacedElementBehavior> behaviors,
    @Default({}) Map<String, String> properties,
  }) = _MapPlacedElement;

  factory MapPlacedElement.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementFromJson(migrateMapPlacedElementJson(json));
}

enum MapPlacedElementTriggerType {
  @JsonValue('on_action')
  onAction,
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_bump')
  onBump,
  @JsonValue('on_exit')
  onExit,
  @JsonValue('on_near')
  onNear,
}

enum MapPlacedElementTriggerScope {
  @JsonValue('default')
  defaultScope,
  @JsonValue('once_per_enter')
  oncePerEnter,
  @JsonValue('while_inside_single_shot')
  whileInsideSingleShot,
  @JsonValue('facing_only')
  facingOnly,
  @JsonValue('near_cardinal_only')
  nearCardinalOnly,
}

@freezed
class MapPlacedElementBehavior with _$MapPlacedElementBehavior {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementBehavior({
    @Default('') String id,
    @Default(true) bool enabled,
    @Default(MapPlacedElementTriggerScope.defaultScope)
    MapPlacedElementTriggerScope triggerScope,
    int? cooldownMs,
    @Default(MapPlacedElementTriggerType.onAction)
    MapPlacedElementTriggerType trigger,
    required MapPlacedElementEffect effect,
  }) = _MapPlacedElementBehavior;

  factory MapPlacedElementBehavior.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementBehaviorFromJson(json);
}

enum MapPlacedElementEffectType {
  @JsonValue('show_message')
  showMessage,
  @JsonValue('open_dialogue')
  openDialogue,
  @JsonValue('set_animation_enabled')
  setAnimationEnabled,
  @JsonValue('play_animation_once')
  playAnimationOnce,
}

@freezed
class MapPlacedElementEffect with _$MapPlacedElementEffect {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementEffect({
    required MapPlacedElementEffectType type,
    String? message,
    DialogueRef? dialogue,
    bool? animationEnabled,
  }) = _MapPlacedElementEffect;

  factory MapPlacedElementEffect.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementEffectFromJson(json);
}

@freezed
class MapPlacedElementAnimation with _$MapPlacedElementAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementAnimation({
    @Default(false) bool enabled,
    @Default(MapPlacedElementAnimationMode.none)
    MapPlacedElementAnimationMode mode,
    @Default(true) bool autoplay,
    @Default(1.0) double speed,
    double? startOffsetMs,
    @Default(false) bool randomStart,
  }) = _MapPlacedElementAnimation;

  factory MapPlacedElementAnimation.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementAnimationFromJson(json);
}

@freezed
class MapEntity with _$MapEntity {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntity({
    required String id,
    @Default('') String name,
    required MapEntityKind kind,
    required GridPos pos,
    @Default(GridSize(width: 1, height: 1)) GridSize size,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
    @Default(true) bool blocksMovement,
    @Default({}) Map<String, String> properties,
  }) = _MapEntity;

  factory MapEntity.fromJson(Map<String, dynamic> json) =>
      _$MapEntityFromJson(migrateMapEntityJson(json));
}

extension MapEntityDisplayX on MapEntity {
  /// Libellé court pour listes / canvas (hors [id] technique).
  String get inspectorHeadline {
    switch (kind) {
      case MapEntityKind.npc:
        final d = npc?.displayName.trim();
        if (d != null && d.isNotEmpty) return d;
        break;
      case MapEntityKind.sign:
        final t = sign?.title.trim();
        if (t != null && t.isNotEmpty) return t;
        break;
      case MapEntityKind.item:
        final id = item?.gameItemId.trim();
        if (id != null && id.isNotEmpty) return id;
        break;
      case MapEntityKind.spawn:
        final k = spawn?.spawnKey.trim();
        if (k != null && k.isNotEmpty) return k;
        break;
      case MapEntityKind.custom:
        break;
    }
    final n = name.trim();
    return n.isNotEmpty ? n : id;
  }
}

extension MapEntityProjectElementVisualX on MapEntity {
  String? get canonicalEditorVisualProjectElementId {
    final id = editorVisual?.elementId.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  String? get legacyNpcVisualProjectElementId {
    if (kind != MapEntityKind.npc) {
      return null;
    }
    final leg = npc?.visualElementId.trim() ?? '';
    if (leg.isEmpty) {
      return null;
    }
    return leg;
  }

  String? get resolvedProjectElementIdForEditor {
    return canonicalEditorVisualProjectElementId ??
        legacyNpcVisualProjectElementId;
  }

  bool get shouldRenderProjectElementInForeground {
    return editorVisual?.renderInForeground ?? false;
  }
}

@freezed
class MapWarp with _$MapWarp {
  @JsonSerializable(explicitToJson: true)
  const factory MapWarp({
    required String id,
    required GridPos pos,
    required String targetMapId,
    required GridPos targetPos,
    @Default(MapWarpTriggerMode.onEnter) MapWarpTriggerMode triggerMode,
    @Default([]) List<EntityFacing> allowedApproachFacings,
    @Default(WarpTriggerPadding()) WarpTriggerPadding triggerPadding,
  }) = _MapWarp;

  factory MapWarp.fromJson(Map<String, dynamic> json) =>
      _$MapWarpFromJson(json);
}

enum MapWarpTriggerMode {
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_bump')
  onBump,
}

@freezed
class WarpTriggerPadding with _$WarpTriggerPadding {
  @JsonSerializable(explicitToJson: true)
  const factory WarpTriggerPadding({
    @Default(0) int top,
    @Default(0) int right,
    @Default(0) int bottom,
    @Default(0) int left,
  }) = _WarpTriggerPadding;

  factory WarpTriggerPadding.fromJson(Map<String, dynamic> json) =>
      _$WarpTriggerPaddingFromJson(json);
}

@freezed
class MapConnection with _$MapConnection {
  @JsonSerializable(explicitToJson: true)
  const factory MapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    @Default(0) int offset,
  }) = _MapConnection;

  factory MapConnection.fromJson(Map<String, dynamic> json) =>
      _$MapConnectionFromJson(json);
}

@freezed
class MapTrigger with _$MapTrigger {
  @JsonSerializable(explicitToJson: true)
  const factory MapTrigger({
    required String id,
    @Default('') String name,
    required TriggerType type,
    required MapRect area,
    @Default({}) Map<String, String> properties,
  }) = _MapTrigger;

  factory MapTrigger.fromJson(Map<String, dynamic> json) =>
      _$MapTriggerFromJson(json);
}

Map<String, dynamic> migrateMapPlacedElementJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  final instanceId = (out['id'] as String?)?.trim() ?? '';
  final existingBehaviorsRaw = out['behaviors'];
  final hasBehaviorList =
      existingBehaviorsRaw is List && existingBehaviorsRaw.isNotEmpty;
  if (hasBehaviorList) {
    out['behaviors'] = _migratePlacedElementBehaviorListJson(
      existingBehaviorsRaw,
      instanceId: instanceId,
    );
    out.remove('interaction');
    return out;
  }

  final interactionRaw = out['interaction'];
  if (interactionRaw is! Map) {
    out.remove('interaction');
    return out;
  }
  final interaction =
      Map<String, dynamic>.from(interactionRaw.cast<Object?, Object?>());
  final enabled = interaction['enabled'] == true;
  final modeRaw = (interaction['mode'] as String?)?.trim().toLowerCase();
  Map<String, dynamic>? behavior;
  if (modeRaw == 'message') {
    final message = (interaction['message'] as String?)?.trim() ?? '';
    if (message.isNotEmpty) {
      behavior = <String, dynamic>{
        'enabled': enabled,
        'trigger': 'on_action',
        'effect': <String, dynamic>{
          'type': 'show_message',
          'message': message,
        },
      };
    }
  } else if (modeRaw == 'dialogue') {
    final dialogueRaw = interaction['dialogue'];
    if (dialogueRaw is Map) {
      final dialogue = Map<String, dynamic>.from(
        dialogueRaw.cast<Object?, Object?>(),
      );
      final dialogueId = (dialogue['dialogueId'] as String?)?.trim() ?? '';
      if (dialogueId.isNotEmpty) {
        behavior = <String, dynamic>{
          'enabled': enabled,
          'trigger': 'on_action',
          'effect': <String, dynamic>{
            'type': 'open_dialogue',
            'dialogue': <String, dynamic>{
              'dialogueId': dialogueId,
              'scriptPathRelative':
                  (dialogue['scriptPathRelative'] as String?) ?? '',
              if ((dialogue['startNode'] as String?)?.trim().isNotEmpty == true)
                'startNode': (dialogue['startNode'] as String).trim(),
            },
          },
        };
      }
    }
  }
  if (behavior != null) {
    out['behaviors'] = <Map<String, dynamic>>[behavior];
  }
  final migratedBehaviorsRaw = out['behaviors'];
  if (migratedBehaviorsRaw is List) {
    out['behaviors'] = _migratePlacedElementBehaviorListJson(
      migratedBehaviorsRaw,
      instanceId: instanceId,
    );
  }
  out.remove('interaction');
  return out;
}

List<Map<String, dynamic>> _migratePlacedElementBehaviorListJson(
  List<dynamic> rawBehaviors, {
  required String instanceId,
}) {
  final out = <Map<String, dynamic>>[];
  final seenIds = <String>{};
  var nextOrdinal = 0;
  for (var i = 0; i < rawBehaviors.length; i++) {
    final raw = rawBehaviors[i];
    if (raw is! Map) {
      continue;
    }
    final behavior = Map<String, dynamic>.from(raw.cast<Object?, Object?>());
    var id = (behavior['id'] as String?)?.trim() ?? '';
    if (id.isEmpty || seenIds.contains(id)) {
      do {
        id = _buildMigratedPlacedElementBehaviorId(
          instanceId: instanceId,
          ordinal: nextOrdinal,
        );
        nextOrdinal += 1;
      } while (seenIds.contains(id));
    }
    behavior['id'] = id;
    seenIds.add(id);
    out.add(behavior);
  }
  return out;
}

String _buildMigratedPlacedElementBehaviorId({
  required String instanceId,
  required int ordinal,
}) {
  final base =
      instanceId.isEmpty ? 'placed_element' : Uri.encodeComponent(instanceId);
  return '$base::behavior::$ordinal';
}

````

### packages/map_core/lib/src/models/map_data.freezed.dart

````dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MapData _$MapDataFromJson(Map<String, dynamic> json) {
  return _MapData.fromJson(json);
}

/// @nodoc
mixin _$MapData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  GridSize get size => throw _privateConstructorUsedError;
  ProjectVersion get version => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<MapLayer> get layers => throw _privateConstructorUsedError;
  List<MapPlacedElement> get placedElements =>
      throw _privateConstructorUsedError;
  List<MapEntity> get entities => throw _privateConstructorUsedError;
  List<MapConnection> get connections => throw _privateConstructorUsedError;
  List<MapWarp> get warps => throw _privateConstructorUsedError;
  List<MapTrigger> get triggers => throw _privateConstructorUsedError;

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  List<MapGameplayZone> get gameplayZones => throw _privateConstructorUsedError;
  MapMetadata get mapMetadata => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;
  List<MapEventDefinition> get events => throw _privateConstructorUsedError;

  /// Serializes this MapData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapDataCopyWith<MapData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapDataCopyWith<$Res> {
  factory $MapDataCopyWith(MapData value, $Res Function(MapData) then) =
      _$MapDataCopyWithImpl<$Res, MapData>;
  @useResult
  $Res call(
      {String id,
      String name,
      GridSize size,
      ProjectVersion version,
      String tilesetId,
      List<MapLayer> layers,
      List<MapPlacedElement> placedElements,
      List<MapEntity> entities,
      List<MapConnection> connections,
      List<MapWarp> warps,
      List<MapTrigger> triggers,
      List<MapGameplayZone> gameplayZones,
      MapMetadata mapMetadata,
      Map<String, dynamic> properties,
      List<MapEventDefinition> events});

  $GridSizeCopyWith<$Res> get size;
  $MapMetadataCopyWith<$Res> get mapMetadata;
}

/// @nodoc
class _$MapDataCopyWithImpl<$Res, $Val extends MapData>
    implements $MapDataCopyWith<$Res> {
  _$MapDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? version = null,
    Object? tilesetId = null,
    Object? layers = null,
    Object? placedElements = null,
    Object? entities = null,
    Object? connections = null,
    Object? warps = null,
    Object? triggers = null,
    Object? gameplayZones = null,
    Object? mapMetadata = null,
    Object? properties = null,
    Object? events = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as ProjectVersion,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      layers: null == layers
          ? _value.layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<MapLayer>,
      placedElements: null == placedElements
          ? _value.placedElements
          : placedElements // ignore: cast_nullable_to_non_nullable
              as List<MapPlacedElement>,
      entities: null == entities
          ? _value.entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<MapEntity>,
      connections: null == connections
          ? _value.connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<MapConnection>,
      warps: null == warps
          ? _value.warps
          : warps // ignore: cast_nullable_to_non_nullable
              as List<MapWarp>,
      triggers: null == triggers
          ? _value.triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as List<MapTrigger>,
      gameplayZones: null == gameplayZones
          ? _value.gameplayZones
          : gameplayZones // ignore: cast_nullable_to_non_nullable
              as List<MapGameplayZone>,
      mapMetadata: null == mapMetadata
          ? _value.mapMetadata
          : mapMetadata // ignore: cast_nullable_to_non_nullable
              as MapMetadata,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      events: null == events
          ? _value.events
          : events // ignore: cast_nullable_to_non_nullable
              as List<MapEventDefinition>,
    ) as $Val);
  }

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridSizeCopyWith<$Res> get size {
    return $GridSizeCopyWith<$Res>(_value.size, (value) {
      return _then(_value.copyWith(size: value) as $Val);
    });
  }

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapMetadataCopyWith<$Res> get mapMetadata {
    return $MapMetadataCopyWith<$Res>(_value.mapMetadata, (value) {
      return _then(_value.copyWith(mapMetadata: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapDataImplCopyWith<$Res> implements $MapDataCopyWith<$Res> {
  factory _$$MapDataImplCopyWith(
          _$MapDataImpl value, $Res Function(_$MapDataImpl) then) =
      __$$MapDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      GridSize size,
      ProjectVersion version,
      String tilesetId,
      List<MapLayer> layers,
      List<MapPlacedElement> placedElements,
      List<MapEntity> entities,
      List<MapConnection> connections,
      List<MapWarp> warps,
      List<MapTrigger> triggers,
      List<MapGameplayZone> gameplayZones,
      MapMetadata mapMetadata,
      Map<String, dynamic> properties,
      List<MapEventDefinition> events});

  @override
  $GridSizeCopyWith<$Res> get size;
  @override
  $MapMetadataCopyWith<$Res> get mapMetadata;
}

/// @nodoc
class __$$MapDataImplCopyWithImpl<$Res>
    extends _$MapDataCopyWithImpl<$Res, _$MapDataImpl>
    implements _$$MapDataImplCopyWith<$Res> {
  __$$MapDataImplCopyWithImpl(
      _$MapDataImpl _value, $Res Function(_$MapDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? version = null,
    Object? tilesetId = null,
    Object? layers = null,
    Object? placedElements = null,
    Object? entities = null,
    Object? connections = null,
    Object? warps = null,
    Object? triggers = null,
    Object? gameplayZones = null,
    Object? mapMetadata = null,
    Object? properties = null,
    Object? events = null,
  }) {
    return _then(_$MapDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as ProjectVersion,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      layers: null == layers
          ? _value._layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<MapLayer>,
      placedElements: null == placedElements
          ? _value._placedElements
          : placedElements // ignore: cast_nullable_to_non_nullable
              as List<MapPlacedElement>,
      entities: null == entities
          ? _value._entities
          : entities // ignore: cast_nullable_to_non_nullable
              as List<MapEntity>,
      connections: null == connections
          ? _value._connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<MapConnection>,
      warps: null == warps
          ? _value._warps
          : warps // ignore: cast_nullable_to_non_nullable
              as List<MapWarp>,
      triggers: null == triggers
          ? _value._triggers
          : triggers // ignore: cast_nullable_to_non_nullable
              as List<MapTrigger>,
      gameplayZones: null == gameplayZones
          ? _value._gameplayZones
          : gameplayZones // ignore: cast_nullable_to_non_nullable
              as List<MapGameplayZone>,
      mapMetadata: null == mapMetadata
          ? _value.mapMetadata
          : mapMetadata // ignore: cast_nullable_to_non_nullable
              as MapMetadata,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      events: null == events
          ? _value._events
          : events // ignore: cast_nullable_to_non_nullable
              as List<MapEventDefinition>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapDataImpl implements _MapData {
  const _$MapDataImpl(
      {required this.id,
      required this.name,
      required this.size,
      this.version = ProjectVersion.v1,
      this.tilesetId = '',
      final List<MapLayer> layers = const [],
      final List<MapPlacedElement> placedElements = const [],
      final List<MapEntity> entities = const [],
      final List<MapConnection> connections = const [],
      final List<MapWarp> warps = const [],
      final List<MapTrigger> triggers = const [],
      final List<MapGameplayZone> gameplayZones = const [],
      this.mapMetadata = const MapMetadata(),
      final Map<String, dynamic> properties = const {},
      final List<MapEventDefinition> events = const []})
      : _layers = layers,
        _placedElements = placedElements,
        _entities = entities,
        _connections = connections,
        _warps = warps,
        _triggers = triggers,
        _gameplayZones = gameplayZones,
        _properties = properties,
        _events = events;

  factory _$MapDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final GridSize size;
  @override
  @JsonKey()
  final ProjectVersion version;
  @override
  @JsonKey()
  final String tilesetId;
  final List<MapLayer> _layers;
  @override
  @JsonKey()
  List<MapLayer> get layers {
    if (_layers is EqualUnmodifiableListView) return _layers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_layers);
  }

  final List<MapPlacedElement> _placedElements;
  @override
  @JsonKey()
  List<MapPlacedElement> get placedElements {
    if (_placedElements is EqualUnmodifiableListView) return _placedElements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_placedElements);
  }

  final List<MapEntity> _entities;
  @override
  @JsonKey()
  List<MapEntity> get entities {
    if (_entities is EqualUnmodifiableListView) return _entities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entities);
  }

  final List<MapConnection> _connections;
  @override
  @JsonKey()
  List<MapConnection> get connections {
    if (_connections is EqualUnmodifiableListView) return _connections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_connections);
  }

  final List<MapWarp> _warps;
  @override
  @JsonKey()
  List<MapWarp> get warps {
    if (_warps is EqualUnmodifiableListView) return _warps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warps);
  }

  final List<MapTrigger> _triggers;
  @override
  @JsonKey()
  List<MapTrigger> get triggers {
    if (_triggers is EqualUnmodifiableListView) return _triggers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_triggers);
  }

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  final List<MapGameplayZone> _gameplayZones;

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  @override
  @JsonKey()
  List<MapGameplayZone> get gameplayZones {
    if (_gameplayZones is EqualUnmodifiableListView) return _gameplayZones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_gameplayZones);
  }

  @override
  @JsonKey()
  final MapMetadata mapMetadata;
  final Map<String, dynamic> _properties;
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  final List<MapEventDefinition> _events;
  @override
  @JsonKey()
  List<MapEventDefinition> get events {
    if (_events is EqualUnmodifiableListView) return _events;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_events);
  }

  @override
  String toString() {
    return 'MapData(id: $id, name: $name, size: $size, version: $version, tilesetId: $tilesetId, layers: $layers, placedElements: $placedElements, entities: $entities, connections: $connections, warps: $warps, triggers: $triggers, gameplayZones: $gameplayZones, mapMetadata: $mapMetadata, properties: $properties, events: $events)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            const DeepCollectionEquality().equals(other._layers, _layers) &&
            const DeepCollectionEquality()
                .equals(other._placedElements, _placedElements) &&
            const DeepCollectionEquality().equals(other._entities, _entities) &&
            const DeepCollectionEquality()
                .equals(other._connections, _connections) &&
            const DeepCollectionEquality().equals(other._warps, _warps) &&
            const DeepCollectionEquality().equals(other._triggers, _triggers) &&
            const DeepCollectionEquality()
                .equals(other._gameplayZones, _gameplayZones) &&
            (identical(other.mapMetadata, mapMetadata) ||
                other.mapMetadata == mapMetadata) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties) &&
            const DeepCollectionEquality().equals(other._events, _events));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      size,
      version,
      tilesetId,
      const DeepCollectionEquality().hash(_layers),
      const DeepCollectionEquality().hash(_placedElements),
      const DeepCollectionEquality().hash(_entities),
      const DeepCollectionEquality().hash(_connections),
      const DeepCollectionEquality().hash(_warps),
      const DeepCollectionEquality().hash(_triggers),
      const DeepCollectionEquality().hash(_gameplayZones),
      mapMetadata,
      const DeepCollectionEquality().hash(_properties),
      const DeepCollectionEquality().hash(_events));

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapDataImplCopyWith<_$MapDataImpl> get copyWith =>
      __$$MapDataImplCopyWithImpl<_$MapDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapDataImplToJson(
      this,
    );
  }
}

abstract class _MapData implements MapData {
  const factory _MapData(
      {required final String id,
      required final String name,
      required final GridSize size,
      final ProjectVersion version,
      final String tilesetId,
      final List<MapLayer> layers,
      final List<MapPlacedElement> placedElements,
      final List<MapEntity> entities,
      final List<MapConnection> connections,
      final List<MapWarp> warps,
      final List<MapTrigger> triggers,
      final List<MapGameplayZone> gameplayZones,
      final MapMetadata mapMetadata,
      final Map<String, dynamic> properties,
      final List<MapEventDefinition> events}) = _$MapDataImpl;

  factory _MapData.fromJson(Map<String, dynamic> json) = _$MapDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  GridSize get size;
  @override
  ProjectVersion get version;
  @override
  String get tilesetId;
  @override
  List<MapLayer> get layers;
  @override
  List<MapPlacedElement> get placedElements;
  @override
  List<MapEntity> get entities;
  @override
  List<MapConnection> get connections;
  @override
  List<MapWarp> get warps;
  @override
  List<MapTrigger> get triggers;

  /// Zones gameplay (rencontres, déplacement, dangers, etc.).
  /// Séparées des triggers (logiques scriptées) et des layers visuelles.
  @override
  List<MapGameplayZone> get gameplayZones;
  @override
  MapMetadata get mapMetadata;
  @override
  Map<String, dynamic> get properties;
  @override
  List<MapEventDefinition> get events;

  /// Create a copy of MapData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapDataImplCopyWith<_$MapDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapGameplayZone _$MapGameplayZoneFromJson(Map<String, dynamic> json) {
  return _MapGameplayZone.fromJson(json);
}

/// @nodoc
mixin _$MapGameplayZone {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  GameplayZoneKind get kind => throw _privateConstructorUsedError;
  MapRect get area => throw _privateConstructorUsedError;

  /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
  int get priority => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.encounter].
  EncounterZonePayload? get encounter => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.movement].
  MovementZonePayload? get movement => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.movementEffect].
  MovementEffectZonePayload? get movementEffect =>
      throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.hazard].
  HazardZonePayload? get hazard => throw _privateConstructorUsedError;

  /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
  SpecialZonePayload? get special => throw _privateConstructorUsedError;

  /// Serializes this MapGameplayZone to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapGameplayZoneCopyWith<MapGameplayZone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapGameplayZoneCopyWith<$Res> {
  factory $MapGameplayZoneCopyWith(
          MapGameplayZone value, $Res Function(MapGameplayZone) then) =
      _$MapGameplayZoneCopyWithImpl<$Res, MapGameplayZone>;
  @useResult
  $Res call(
      {String id,
      String name,
      GameplayZoneKind kind,
      MapRect area,
      int priority,
      EncounterZonePayload? encounter,
      MovementZonePayload? movement,
      MovementEffectZonePayload? movementEffect,
      HazardZonePayload? hazard,
      SpecialZonePayload? special});

  $MapRectCopyWith<$Res> get area;
  $EncounterZonePayloadCopyWith<$Res>? get encounter;
  $MovementZonePayloadCopyWith<$Res>? get movement;
  $MovementEffectZonePayloadCopyWith<$Res>? get movementEffect;
  $HazardZonePayloadCopyWith<$Res>? get hazard;
  $SpecialZonePayloadCopyWith<$Res>? get special;
}

/// @nodoc
class _$MapGameplayZoneCopyWithImpl<$Res, $Val extends MapGameplayZone>
    implements $MapGameplayZoneCopyWith<$Res> {
  _$MapGameplayZoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? area = null,
    Object? priority = null,
    Object? encounter = freezed,
    Object? movement = freezed,
    Object? movementEffect = freezed,
    Object? hazard = freezed,
    Object? special = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GameplayZoneKind,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      encounter: freezed == encounter
          ? _value.encounter
          : encounter // ignore: cast_nullable_to_non_nullable
              as EncounterZonePayload?,
      movement: freezed == movement
          ? _value.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as MovementZonePayload?,
      movementEffect: freezed == movementEffect
          ? _value.movementEffect
          : movementEffect // ignore: cast_nullable_to_non_nullable
              as MovementEffectZonePayload?,
      hazard: freezed == hazard
          ? _value.hazard
          : hazard // ignore: cast_nullable_to_non_nullable
              as HazardZonePayload?,
      special: freezed == special
          ? _value.special
          : special // ignore: cast_nullable_to_non_nullable
              as SpecialZonePayload?,
    ) as $Val);
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapRectCopyWith<$Res> get area {
    return $MapRectCopyWith<$Res>(_value.area, (value) {
      return _then(_value.copyWith(area: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EncounterZonePayloadCopyWith<$Res>? get encounter {
    if (_value.encounter == null) {
      return null;
    }

    return $EncounterZonePayloadCopyWith<$Res>(_value.encounter!, (value) {
      return _then(_value.copyWith(encounter: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MovementZonePayloadCopyWith<$Res>? get movement {
    if (_value.movement == null) {
      return null;
    }

    return $MovementZonePayloadCopyWith<$Res>(_value.movement!, (value) {
      return _then(_value.copyWith(movement: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MovementEffectZonePayloadCopyWith<$Res>? get movementEffect {
    if (_value.movementEffect == null) {
      return null;
    }

    return $MovementEffectZonePayloadCopyWith<$Res>(_value.movementEffect!,
        (value) {
      return _then(_value.copyWith(movementEffect: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HazardZonePayloadCopyWith<$Res>? get hazard {
    if (_value.hazard == null) {
      return null;
    }

    return $HazardZonePayloadCopyWith<$Res>(_value.hazard!, (value) {
      return _then(_value.copyWith(hazard: value) as $Val);
    });
  }

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SpecialZonePayloadCopyWith<$Res>? get special {
    if (_value.special == null) {
      return null;
    }

    return $SpecialZonePayloadCopyWith<$Res>(_value.special!, (value) {
      return _then(_value.copyWith(special: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapGameplayZoneImplCopyWith<$Res>
    implements $MapGameplayZoneCopyWith<$Res> {
  factory _$$MapGameplayZoneImplCopyWith(_$MapGameplayZoneImpl value,
          $Res Function(_$MapGameplayZoneImpl) then) =
      __$$MapGameplayZoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      GameplayZoneKind kind,
      MapRect area,
      int priority,
      EncounterZonePayload? encounter,
      MovementZonePayload? movement,
      MovementEffectZonePayload? movementEffect,
      HazardZonePayload? hazard,
      SpecialZonePayload? special});

  @override
  $MapRectCopyWith<$Res> get area;
  @override
  $EncounterZonePayloadCopyWith<$Res>? get encounter;
  @override
  $MovementZonePayloadCopyWith<$Res>? get movement;
  @override
  $MovementEffectZonePayloadCopyWith<$Res>? get movementEffect;
  @override
  $HazardZonePayloadCopyWith<$Res>? get hazard;
  @override
  $SpecialZonePayloadCopyWith<$Res>? get special;
}

/// @nodoc
class __$$MapGameplayZoneImplCopyWithImpl<$Res>
    extends _$MapGameplayZoneCopyWithImpl<$Res, _$MapGameplayZoneImpl>
    implements _$$MapGameplayZoneImplCopyWith<$Res> {
  __$$MapGameplayZoneImplCopyWithImpl(
      _$MapGameplayZoneImpl _value, $Res Function(_$MapGameplayZoneImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? area = null,
    Object? priority = null,
    Object? encounter = freezed,
    Object? movement = freezed,
    Object? movementEffect = freezed,
    Object? hazard = freezed,
    Object? special = freezed,
  }) {
    return _then(_$MapGameplayZoneImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GameplayZoneKind,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      encounter: freezed == encounter
          ? _value.encounter
          : encounter // ignore: cast_nullable_to_non_nullable
              as EncounterZonePayload?,
      movement: freezed == movement
          ? _value.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as MovementZonePayload?,
      movementEffect: freezed == movementEffect
          ? _value.movementEffect
          : movementEffect // ignore: cast_nullable_to_non_nullable
              as MovementEffectZonePayload?,
      hazard: freezed == hazard
          ? _value.hazard
          : hazard // ignore: cast_nullable_to_non_nullable
              as HazardZonePayload?,
      special: freezed == special
          ? _value.special
          : special // ignore: cast_nullable_to_non_nullable
              as SpecialZonePayload?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapGameplayZoneImpl implements _MapGameplayZone {
  const _$MapGameplayZoneImpl(
      {required this.id,
      this.name = '',
      required this.kind,
      required this.area,
      this.priority = 0,
      this.encounter,
      this.movement,
      this.movementEffect,
      this.hazard,
      this.special});

  factory _$MapGameplayZoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapGameplayZoneImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final GameplayZoneKind kind;
  @override
  final MapRect area;

  /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
  @override
  @JsonKey()
  final int priority;

  /// Payload pour [GameplayZoneKind.encounter].
  @override
  final EncounterZonePayload? encounter;

  /// Payload pour [GameplayZoneKind.movement].
  @override
  final MovementZonePayload? movement;

  /// Payload pour [GameplayZoneKind.movementEffect].
  @override
  final MovementEffectZonePayload? movementEffect;

  /// Payload pour [GameplayZoneKind.hazard].
  @override
  final HazardZonePayload? hazard;

  /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
  @override
  final SpecialZonePayload? special;

  @override
  String toString() {
    return 'MapGameplayZone(id: $id, name: $name, kind: $kind, area: $area, priority: $priority, encounter: $encounter, movement: $movement, movementEffect: $movementEffect, hazard: $hazard, special: $special)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapGameplayZoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.area, area) || other.area == area) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.encounter, encounter) ||
                other.encounter == encounter) &&
            (identical(other.movement, movement) ||
                other.movement == movement) &&
            (identical(other.movementEffect, movementEffect) ||
                other.movementEffect == movementEffect) &&
            (identical(other.hazard, hazard) || other.hazard == hazard) &&
            (identical(other.special, special) || other.special == special));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, kind, area, priority,
      encounter, movement, movementEffect, hazard, special);

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapGameplayZoneImplCopyWith<_$MapGameplayZoneImpl> get copyWith =>
      __$$MapGameplayZoneImplCopyWithImpl<_$MapGameplayZoneImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapGameplayZoneImplToJson(
      this,
    );
  }
}

abstract class _MapGameplayZone implements MapGameplayZone {
  const factory _MapGameplayZone(
      {required final String id,
      final String name,
      required final GameplayZoneKind kind,
      required final MapRect area,
      final int priority,
      final EncounterZonePayload? encounter,
      final MovementZonePayload? movement,
      final MovementEffectZonePayload? movementEffect,
      final HazardZonePayload? hazard,
      final SpecialZonePayload? special}) = _$MapGameplayZoneImpl;

  factory _MapGameplayZone.fromJson(Map<String, dynamic> json) =
      _$MapGameplayZoneImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  GameplayZoneKind get kind;
  @override
  MapRect get area;

  /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
  @override
  int get priority;

  /// Payload pour [GameplayZoneKind.encounter].
  @override
  EncounterZonePayload? get encounter;

  /// Payload pour [GameplayZoneKind.movement].
  @override
  MovementZonePayload? get movement;

  /// Payload pour [GameplayZoneKind.movementEffect].
  @override
  MovementEffectZonePayload? get movementEffect;

  /// Payload pour [GameplayZoneKind.hazard].
  @override
  HazardZonePayload? get hazard;

  /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
  @override
  SpecialZonePayload? get special;

  /// Create a copy of MapGameplayZone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapGameplayZoneImplCopyWith<_$MapGameplayZoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapPlacedElement _$MapPlacedElementFromJson(Map<String, dynamic> json) {
  return _MapPlacedElement.fromJson(json);
}

/// @nodoc
mixin _$MapPlacedElement {
  String get id => throw _privateConstructorUsedError;
  String get layerId => throw _privateConstructorUsedError;
  String get elementId => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  bool get applyCollision => throw _privateConstructorUsedError;
  MapPlacedElementAnimation? get animation =>
      throw _privateConstructorUsedError;
  List<MapPlacedElementBehavior> get behaviors =>
      throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this MapPlacedElement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapPlacedElementCopyWith<MapPlacedElement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapPlacedElementCopyWith<$Res> {
  factory $MapPlacedElementCopyWith(
          MapPlacedElement value, $Res Function(MapPlacedElement) then) =
      _$MapPlacedElementCopyWithImpl<$Res, MapPlacedElement>;
  @useResult
  $Res call(
      {String id,
      String layerId,
      String elementId,
      GridPos pos,
      bool applyCollision,
      MapPlacedElementAnimation? animation,
      List<MapPlacedElementBehavior> behaviors,
      Map<String, String> properties});

  $GridPosCopyWith<$Res> get pos;
  $MapPlacedElementAnimationCopyWith<$Res>? get animation;
}

/// @nodoc
class _$MapPlacedElementCopyWithImpl<$Res, $Val extends MapPlacedElement>
    implements $MapPlacedElementCopyWith<$Res> {
  _$MapPlacedElementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? layerId = null,
    Object? elementId = null,
    Object? pos = null,
    Object? applyCollision = null,
    Object? animation = freezed,
    Object? behaviors = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
      elementId: null == elementId
          ? _value.elementId
          : elementId // ignore: cast_nullable_to_non_nullable
              as String,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      applyCollision: null == applyCollision
          ? _value.applyCollision
          : applyCollision // ignore: cast_nullable_to_non_nullable
              as bool,
      animation: freezed == animation
          ? _value.animation
          : animation // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementAnimation?,
      behaviors: null == behaviors
          ? _value.behaviors
          : behaviors // ignore: cast_nullable_to_non_nullable
              as List<MapPlacedElementBehavior>,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapPlacedElementAnimationCopyWith<$Res>? get animation {
    if (_value.animation == null) {
      return null;
    }

    return $MapPlacedElementAnimationCopyWith<$Res>(_value.animation!, (value) {
      return _then(_value.copyWith(animation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapPlacedElementImplCopyWith<$Res>
    implements $MapPlacedElementCopyWith<$Res> {
  factory _$$MapPlacedElementImplCopyWith(_$MapPlacedElementImpl value,
          $Res Function(_$MapPlacedElementImpl) then) =
      __$$MapPlacedElementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String layerId,
      String elementId,
      GridPos pos,
      bool applyCollision,
      MapPlacedElementAnimation? animation,
      List<MapPlacedElementBehavior> behaviors,
      Map<String, String> properties});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $MapPlacedElementAnimationCopyWith<$Res>? get animation;
}

/// @nodoc
class __$$MapPlacedElementImplCopyWithImpl<$Res>
    extends _$MapPlacedElementCopyWithImpl<$Res, _$MapPlacedElementImpl>
    implements _$$MapPlacedElementImplCopyWith<$Res> {
  __$$MapPlacedElementImplCopyWithImpl(_$MapPlacedElementImpl _value,
      $Res Function(_$MapPlacedElementImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? layerId = null,
    Object? elementId = null,
    Object? pos = null,
    Object? applyCollision = null,
    Object? animation = freezed,
    Object? behaviors = null,
    Object? properties = null,
  }) {
    return _then(_$MapPlacedElementImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
      elementId: null == elementId
          ? _value.elementId
          : elementId // ignore: cast_nullable_to_non_nullable
              as String,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      applyCollision: null == applyCollision
          ? _value.applyCollision
          : applyCollision // ignore: cast_nullable_to_non_nullable
              as bool,
      animation: freezed == animation
          ? _value.animation
          : animation // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementAnimation?,
      behaviors: null == behaviors
          ? _value._behaviors
          : behaviors // ignore: cast_nullable_to_non_nullable
              as List<MapPlacedElementBehavior>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapPlacedElementImpl implements _MapPlacedElement {
  const _$MapPlacedElementImpl(
      {required this.id,
      required this.layerId,
      required this.elementId,
      required this.pos,
      this.applyCollision = true,
      this.animation,
      final List<MapPlacedElementBehavior> behaviors = const [],
      final Map<String, String> properties = const {}})
      : _behaviors = behaviors,
        _properties = properties;

  factory _$MapPlacedElementImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapPlacedElementImplFromJson(json);

  @override
  final String id;
  @override
  final String layerId;
  @override
  final String elementId;
  @override
  final GridPos pos;
  @override
  @JsonKey()
  final bool applyCollision;
  @override
  final MapPlacedElementAnimation? animation;
  final List<MapPlacedElementBehavior> _behaviors;
  @override
  @JsonKey()
  List<MapPlacedElementBehavior> get behaviors {
    if (_behaviors is EqualUnmodifiableListView) return _behaviors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_behaviors);
  }

  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapPlacedElement(id: $id, layerId: $layerId, elementId: $elementId, pos: $pos, applyCollision: $applyCollision, animation: $animation, behaviors: $behaviors, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapPlacedElementImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.layerId, layerId) || other.layerId == layerId) &&
            (identical(other.elementId, elementId) ||
                other.elementId == elementId) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.applyCollision, applyCollision) ||
                other.applyCollision == applyCollision) &&
            (identical(other.animation, animation) ||
                other.animation == animation) &&
            const DeepCollectionEquality()
                .equals(other._behaviors, _behaviors) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      layerId,
      elementId,
      pos,
      applyCollision,
      animation,
      const DeepCollectionEquality().hash(_behaviors),
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapPlacedElementImplCopyWith<_$MapPlacedElementImpl> get copyWith =>
      __$$MapPlacedElementImplCopyWithImpl<_$MapPlacedElementImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapPlacedElementImplToJson(
      this,
    );
  }
}

abstract class _MapPlacedElement implements MapPlacedElement {
  const factory _MapPlacedElement(
      {required final String id,
      required final String layerId,
      required final String elementId,
      required final GridPos pos,
      final bool applyCollision,
      final MapPlacedElementAnimation? animation,
      final List<MapPlacedElementBehavior> behaviors,
      final Map<String, String> properties}) = _$MapPlacedElementImpl;

  factory _MapPlacedElement.fromJson(Map<String, dynamic> json) =
      _$MapPlacedElementImpl.fromJson;

  @override
  String get id;
  @override
  String get layerId;
  @override
  String get elementId;
  @override
  GridPos get pos;
  @override
  bool get applyCollision;
  @override
  MapPlacedElementAnimation? get animation;
  @override
  List<MapPlacedElementBehavior> get behaviors;
  @override
  Map<String, String> get properties;

  /// Create a copy of MapPlacedElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapPlacedElementImplCopyWith<_$MapPlacedElementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapPlacedElementBehavior _$MapPlacedElementBehaviorFromJson(
    Map<String, dynamic> json) {
  return _MapPlacedElementBehavior.fromJson(json);
}

/// @nodoc
mixin _$MapPlacedElementBehavior {
  String get id => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  MapPlacedElementTriggerScope get triggerScope =>
      throw _privateConstructorUsedError;
  int? get cooldownMs => throw _privateConstructorUsedError;
  MapPlacedElementTriggerType get trigger => throw _privateConstructorUsedError;
  MapPlacedElementEffect get effect => throw _privateConstructorUsedError;

  /// Serializes this MapPlacedElementBehavior to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapPlacedElementBehavior
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapPlacedElementBehaviorCopyWith<MapPlacedElementBehavior> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapPlacedElementBehaviorCopyWith<$Res> {
  factory $MapPlacedElementBehaviorCopyWith(MapPlacedElementBehavior value,
          $Res Function(MapPlacedElementBehavior) then) =
      _$MapPlacedElementBehaviorCopyWithImpl<$Res, MapPlacedElementBehavior>;
  @useResult
  $Res call(
      {String id,
      bool enabled,
      MapPlacedElementTriggerScope triggerScope,
      int? cooldownMs,
      MapPlacedElementTriggerType trigger,
      MapPlacedElementEffect effect});

  $MapPlacedElementEffectCopyWith<$Res> get effect;
}

/// @nodoc
class _$MapPlacedElementBehaviorCopyWithImpl<$Res,
        $Val extends MapPlacedElementBehavior>
    implements $MapPlacedElementBehaviorCopyWith<$Res> {
  _$MapPlacedElementBehaviorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapPlacedElementBehavior
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? enabled = null,
    Object? triggerScope = null,
    Object? cooldownMs = freezed,
    Object? trigger = null,
    Object? effect = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      triggerScope: null == triggerScope
          ? _value.triggerScope
          : triggerScope // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementTriggerScope,
      cooldownMs: freezed == cooldownMs
          ? _value.cooldownMs
          : cooldownMs // ignore: cast_nullable_to_non_nullable
              as int?,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementTriggerType,
      effect: null == effect
          ? _value.effect
          : effect // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementEffect,
    ) as $Val);
  }

  /// Create a copy of MapPlacedElementBehavior
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapPlacedElementEffectCopyWith<$Res> get effect {
    return $MapPlacedElementEffectCopyWith<$Res>(_value.effect, (value) {
      return _then(_value.copyWith(effect: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapPlacedElementBehaviorImplCopyWith<$Res>
    implements $MapPlacedElementBehaviorCopyWith<$Res> {
  factory _$$MapPlacedElementBehaviorImplCopyWith(
          _$MapPlacedElementBehaviorImpl value,
          $Res Function(_$MapPlacedElementBehaviorImpl) then) =
      __$$MapPlacedElementBehaviorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      bool enabled,
      MapPlacedElementTriggerScope triggerScope,
      int? cooldownMs,
      MapPlacedElementTriggerType trigger,
      MapPlacedElementEffect effect});

  @override
  $MapPlacedElementEffectCopyWith<$Res> get effect;
}

/// @nodoc
class __$$MapPlacedElementBehaviorImplCopyWithImpl<$Res>
    extends _$MapPlacedElementBehaviorCopyWithImpl<$Res,
        _$MapPlacedElementBehaviorImpl>
    implements _$$MapPlacedElementBehaviorImplCopyWith<$Res> {
  __$$MapPlacedElementBehaviorImplCopyWithImpl(
      _$MapPlacedElementBehaviorImpl _value,
      $Res Function(_$MapPlacedElementBehaviorImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapPlacedElementBehavior
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? enabled = null,
    Object? triggerScope = null,
    Object? cooldownMs = freezed,
    Object? trigger = null,
    Object? effect = null,
  }) {
    return _then(_$MapPlacedElementBehaviorImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      triggerScope: null == triggerScope
          ? _value.triggerScope
          : triggerScope // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementTriggerScope,
      cooldownMs: freezed == cooldownMs
          ? _value.cooldownMs
          : cooldownMs // ignore: cast_nullable_to_non_nullable
              as int?,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementTriggerType,
      effect: null == effect
          ? _value.effect
          : effect // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementEffect,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapPlacedElementBehaviorImpl implements _MapPlacedElementBehavior {
  const _$MapPlacedElementBehaviorImpl(
      {this.id = '',
      this.enabled = true,
      this.triggerScope = MapPlacedElementTriggerScope.defaultScope,
      this.cooldownMs,
      this.trigger = MapPlacedElementTriggerType.onAction,
      required this.effect});

  factory _$MapPlacedElementBehaviorImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapPlacedElementBehaviorImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final MapPlacedElementTriggerScope triggerScope;
  @override
  final int? cooldownMs;
  @override
  @JsonKey()
  final MapPlacedElementTriggerType trigger;
  @override
  final MapPlacedElementEffect effect;

  @override
  String toString() {
    return 'MapPlacedElementBehavior(id: $id, enabled: $enabled, triggerScope: $triggerScope, cooldownMs: $cooldownMs, trigger: $trigger, effect: $effect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapPlacedElementBehaviorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.triggerScope, triggerScope) ||
                other.triggerScope == triggerScope) &&
            (identical(other.cooldownMs, cooldownMs) ||
                other.cooldownMs == cooldownMs) &&
            (identical(other.trigger, trigger) || other.trigger == trigger) &&
            (identical(other.effect, effect) || other.effect == effect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, enabled, triggerScope, cooldownMs, trigger, effect);

  /// Create a copy of MapPlacedElementBehavior
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapPlacedElementBehaviorImplCopyWith<_$MapPlacedElementBehaviorImpl>
      get copyWith => __$$MapPlacedElementBehaviorImplCopyWithImpl<
          _$MapPlacedElementBehaviorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapPlacedElementBehaviorImplToJson(
      this,
    );
  }
}

abstract class _MapPlacedElementBehavior implements MapPlacedElementBehavior {
  const factory _MapPlacedElementBehavior(
          {final String id,
          final bool enabled,
          final MapPlacedElementTriggerScope triggerScope,
          final int? cooldownMs,
          final MapPlacedElementTriggerType trigger,
          required final MapPlacedElementEffect effect}) =
      _$MapPlacedElementBehaviorImpl;

  factory _MapPlacedElementBehavior.fromJson(Map<String, dynamic> json) =
      _$MapPlacedElementBehaviorImpl.fromJson;

  @override
  String get id;
  @override
  bool get enabled;
  @override
  MapPlacedElementTriggerScope get triggerScope;
  @override
  int? get cooldownMs;
  @override
  MapPlacedElementTriggerType get trigger;
  @override
  MapPlacedElementEffect get effect;

  /// Create a copy of MapPlacedElementBehavior
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapPlacedElementBehaviorImplCopyWith<_$MapPlacedElementBehaviorImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MapPlacedElementEffect _$MapPlacedElementEffectFromJson(
    Map<String, dynamic> json) {
  return _MapPlacedElementEffect.fromJson(json);
}

/// @nodoc
mixin _$MapPlacedElementEffect {
  MapPlacedElementEffectType get type => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  DialogueRef? get dialogue => throw _privateConstructorUsedError;
  bool? get animationEnabled => throw _privateConstructorUsedError;

  /// Serializes this MapPlacedElementEffect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapPlacedElementEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapPlacedElementEffectCopyWith<MapPlacedElementEffect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapPlacedElementEffectCopyWith<$Res> {
  factory $MapPlacedElementEffectCopyWith(MapPlacedElementEffect value,
          $Res Function(MapPlacedElementEffect) then) =
      _$MapPlacedElementEffectCopyWithImpl<$Res, MapPlacedElementEffect>;
  @useResult
  $Res call(
      {MapPlacedElementEffectType type,
      String? message,
      DialogueRef? dialogue,
      bool? animationEnabled});

  $DialogueRefCopyWith<$Res>? get dialogue;
}

/// @nodoc
class _$MapPlacedElementEffectCopyWithImpl<$Res,
        $Val extends MapPlacedElementEffect>
    implements $MapPlacedElementEffectCopyWith<$Res> {
  _$MapPlacedElementEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapPlacedElementEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? message = freezed,
    Object? dialogue = freezed,
    Object? animationEnabled = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementEffectType,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      animationEnabled: freezed == animationEnabled
          ? _value.animationEnabled
          : animationEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }

  /// Create a copy of MapPlacedElementEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DialogueRefCopyWith<$Res>? get dialogue {
    if (_value.dialogue == null) {
      return null;
    }

    return $DialogueRefCopyWith<$Res>(_value.dialogue!, (value) {
      return _then(_value.copyWith(dialogue: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapPlacedElementEffectImplCopyWith<$Res>
    implements $MapPlacedElementEffectCopyWith<$Res> {
  factory _$$MapPlacedElementEffectImplCopyWith(
          _$MapPlacedElementEffectImpl value,
          $Res Function(_$MapPlacedElementEffectImpl) then) =
      __$$MapPlacedElementEffectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MapPlacedElementEffectType type,
      String? message,
      DialogueRef? dialogue,
      bool? animationEnabled});

  @override
  $DialogueRefCopyWith<$Res>? get dialogue;
}

/// @nodoc
class __$$MapPlacedElementEffectImplCopyWithImpl<$Res>
    extends _$MapPlacedElementEffectCopyWithImpl<$Res,
        _$MapPlacedElementEffectImpl>
    implements _$$MapPlacedElementEffectImplCopyWith<$Res> {
  __$$MapPlacedElementEffectImplCopyWithImpl(
      _$MapPlacedElementEffectImpl _value,
      $Res Function(_$MapPlacedElementEffectImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapPlacedElementEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? message = freezed,
    Object? dialogue = freezed,
    Object? animationEnabled = freezed,
  }) {
    return _then(_$MapPlacedElementEffectImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementEffectType,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      animationEnabled: freezed == animationEnabled
          ? _value.animationEnabled
          : animationEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapPlacedElementEffectImpl implements _MapPlacedElementEffect {
  const _$MapPlacedElementEffectImpl(
      {required this.type, this.message, this.dialogue, this.animationEnabled});

  factory _$MapPlacedElementEffectImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapPlacedElementEffectImplFromJson(json);

  @override
  final MapPlacedElementEffectType type;
  @override
  final String? message;
  @override
  final DialogueRef? dialogue;
  @override
  final bool? animationEnabled;

  @override
  String toString() {
    return 'MapPlacedElementEffect(type: $type, message: $message, dialogue: $dialogue, animationEnabled: $animationEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapPlacedElementEffectImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.dialogue, dialogue) ||
                other.dialogue == dialogue) &&
            (identical(other.animationEnabled, animationEnabled) ||
                other.animationEnabled == animationEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, message, dialogue, animationEnabled);

  /// Create a copy of MapPlacedElementEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapPlacedElementEffectImplCopyWith<_$MapPlacedElementEffectImpl>
      get copyWith => __$$MapPlacedElementEffectImplCopyWithImpl<
          _$MapPlacedElementEffectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapPlacedElementEffectImplToJson(
      this,
    );
  }
}

abstract class _MapPlacedElementEffect implements MapPlacedElementEffect {
  const factory _MapPlacedElementEffect(
      {required final MapPlacedElementEffectType type,
      final String? message,
      final DialogueRef? dialogue,
      final bool? animationEnabled}) = _$MapPlacedElementEffectImpl;

  factory _MapPlacedElementEffect.fromJson(Map<String, dynamic> json) =
      _$MapPlacedElementEffectImpl.fromJson;

  @override
  MapPlacedElementEffectType get type;
  @override
  String? get message;
  @override
  DialogueRef? get dialogue;
  @override
  bool? get animationEnabled;

  /// Create a copy of MapPlacedElementEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapPlacedElementEffectImplCopyWith<_$MapPlacedElementEffectImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MapPlacedElementAnimation _$MapPlacedElementAnimationFromJson(
    Map<String, dynamic> json) {
  return _MapPlacedElementAnimation.fromJson(json);
}

/// @nodoc
mixin _$MapPlacedElementAnimation {
  bool get enabled => throw _privateConstructorUsedError;
  MapPlacedElementAnimationMode get mode => throw _privateConstructorUsedError;
  bool get autoplay => throw _privateConstructorUsedError;
  double get speed => throw _privateConstructorUsedError;
  double? get startOffsetMs => throw _privateConstructorUsedError;
  bool get randomStart => throw _privateConstructorUsedError;

  /// Serializes this MapPlacedElementAnimation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapPlacedElementAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapPlacedElementAnimationCopyWith<MapPlacedElementAnimation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapPlacedElementAnimationCopyWith<$Res> {
  factory $MapPlacedElementAnimationCopyWith(MapPlacedElementAnimation value,
          $Res Function(MapPlacedElementAnimation) then) =
      _$MapPlacedElementAnimationCopyWithImpl<$Res, MapPlacedElementAnimation>;
  @useResult
  $Res call(
      {bool enabled,
      MapPlacedElementAnimationMode mode,
      bool autoplay,
      double speed,
      double? startOffsetMs,
      bool randomStart});
}

/// @nodoc
class _$MapPlacedElementAnimationCopyWithImpl<$Res,
        $Val extends MapPlacedElementAnimation>
    implements $MapPlacedElementAnimationCopyWith<$Res> {
  _$MapPlacedElementAnimationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapPlacedElementAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? mode = null,
    Object? autoplay = null,
    Object? speed = null,
    Object? startOffsetMs = freezed,
    Object? randomStart = null,
  }) {
    return _then(_value.copyWith(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementAnimationMode,
      autoplay: null == autoplay
          ? _value.autoplay
          : autoplay // ignore: cast_nullable_to_non_nullable
              as bool,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as double,
      startOffsetMs: freezed == startOffsetMs
          ? _value.startOffsetMs
          : startOffsetMs // ignore: cast_nullable_to_non_nullable
              as double?,
      randomStart: null == randomStart
          ? _value.randomStart
          : randomStart // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapPlacedElementAnimationImplCopyWith<$Res>
    implements $MapPlacedElementAnimationCopyWith<$Res> {
  factory _$$MapPlacedElementAnimationImplCopyWith(
          _$MapPlacedElementAnimationImpl value,
          $Res Function(_$MapPlacedElementAnimationImpl) then) =
      __$$MapPlacedElementAnimationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool enabled,
      MapPlacedElementAnimationMode mode,
      bool autoplay,
      double speed,
      double? startOffsetMs,
      bool randomStart});
}

/// @nodoc
class __$$MapPlacedElementAnimationImplCopyWithImpl<$Res>
    extends _$MapPlacedElementAnimationCopyWithImpl<$Res,
        _$MapPlacedElementAnimationImpl>
    implements _$$MapPlacedElementAnimationImplCopyWith<$Res> {
  __$$MapPlacedElementAnimationImplCopyWithImpl(
      _$MapPlacedElementAnimationImpl _value,
      $Res Function(_$MapPlacedElementAnimationImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapPlacedElementAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? mode = null,
    Object? autoplay = null,
    Object? speed = null,
    Object? startOffsetMs = freezed,
    Object? randomStart = null,
  }) {
    return _then(_$MapPlacedElementAnimationImpl(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as MapPlacedElementAnimationMode,
      autoplay: null == autoplay
          ? _value.autoplay
          : autoplay // ignore: cast_nullable_to_non_nullable
              as bool,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as double,
      startOffsetMs: freezed == startOffsetMs
          ? _value.startOffsetMs
          : startOffsetMs // ignore: cast_nullable_to_non_nullable
              as double?,
      randomStart: null == randomStart
          ? _value.randomStart
          : randomStart // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapPlacedElementAnimationImpl implements _MapPlacedElementAnimation {
  const _$MapPlacedElementAnimationImpl(
      {this.enabled = false,
      this.mode = MapPlacedElementAnimationMode.none,
      this.autoplay = true,
      this.speed = 1.0,
      this.startOffsetMs,
      this.randomStart = false});

  factory _$MapPlacedElementAnimationImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapPlacedElementAnimationImplFromJson(json);

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final MapPlacedElementAnimationMode mode;
  @override
  @JsonKey()
  final bool autoplay;
  @override
  @JsonKey()
  final double speed;
  @override
  final double? startOffsetMs;
  @override
  @JsonKey()
  final bool randomStart;

  @override
  String toString() {
    return 'MapPlacedElementAnimation(enabled: $enabled, mode: $mode, autoplay: $autoplay, speed: $speed, startOffsetMs: $startOffsetMs, randomStart: $randomStart)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapPlacedElementAnimationImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.autoplay, autoplay) ||
                other.autoplay == autoplay) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.startOffsetMs, startOffsetMs) ||
                other.startOffsetMs == startOffsetMs) &&
            (identical(other.randomStart, randomStart) ||
                other.randomStart == randomStart));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, enabled, mode, autoplay, speed, startOffsetMs, randomStart);

  /// Create a copy of MapPlacedElementAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapPlacedElementAnimationImplCopyWith<_$MapPlacedElementAnimationImpl>
      get copyWith => __$$MapPlacedElementAnimationImplCopyWithImpl<
          _$MapPlacedElementAnimationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapPlacedElementAnimationImplToJson(
      this,
    );
  }
}

abstract class _MapPlacedElementAnimation implements MapPlacedElementAnimation {
  const factory _MapPlacedElementAnimation(
      {final bool enabled,
      final MapPlacedElementAnimationMode mode,
      final bool autoplay,
      final double speed,
      final double? startOffsetMs,
      final bool randomStart}) = _$MapPlacedElementAnimationImpl;

  factory _MapPlacedElementAnimation.fromJson(Map<String, dynamic> json) =
      _$MapPlacedElementAnimationImpl.fromJson;

  @override
  bool get enabled;
  @override
  MapPlacedElementAnimationMode get mode;
  @override
  bool get autoplay;
  @override
  double get speed;
  @override
  double? get startOffsetMs;
  @override
  bool get randomStart;

  /// Create a copy of MapPlacedElementAnimation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapPlacedElementAnimationImplCopyWith<_$MapPlacedElementAnimationImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MapEntity _$MapEntityFromJson(Map<String, dynamic> json) {
  return _MapEntity.fromJson(json);
}

/// @nodoc
mixin _$MapEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MapEntityKind get kind => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  GridSize get size => throw _privateConstructorUsedError;
  MapEntityNpcData? get npc => throw _privateConstructorUsedError;
  MapEntitySignData? get sign => throw _privateConstructorUsedError;
  MapEntityItemData? get item => throw _privateConstructorUsedError;
  MapEntitySpawnData? get spawn => throw _privateConstructorUsedError;
  MapEntityEditorVisual? get editorVisual => throw _privateConstructorUsedError;
  bool get blocksMovement => throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this MapEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntityCopyWith<MapEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntityCopyWith<$Res> {
  factory $MapEntityCopyWith(MapEntity value, $Res Function(MapEntity) then) =
      _$MapEntityCopyWithImpl<$Res, MapEntity>;
  @useResult
  $Res call(
      {String id,
      String name,
      MapEntityKind kind,
      GridPos pos,
      GridSize size,
      MapEntityNpcData? npc,
      MapEntitySignData? sign,
      MapEntityItemData? item,
      MapEntitySpawnData? spawn,
      MapEntityEditorVisual? editorVisual,
      bool blocksMovement,
      Map<String, String> properties});

  $GridPosCopyWith<$Res> get pos;
  $GridSizeCopyWith<$Res> get size;
  $MapEntityNpcDataCopyWith<$Res>? get npc;
  $MapEntitySignDataCopyWith<$Res>? get sign;
  $MapEntityItemDataCopyWith<$Res>? get item;
  $MapEntitySpawnDataCopyWith<$Res>? get spawn;
  $MapEntityEditorVisualCopyWith<$Res>? get editorVisual;
}

/// @nodoc
class _$MapEntityCopyWithImpl<$Res, $Val extends MapEntity>
    implements $MapEntityCopyWith<$Res> {
  _$MapEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? pos = null,
    Object? size = null,
    Object? npc = freezed,
    Object? sign = freezed,
    Object? item = freezed,
    Object? spawn = freezed,
    Object? editorVisual = freezed,
    Object? blocksMovement = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MapEntityKind,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      npc: freezed == npc
          ? _value.npc
          : npc // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcData?,
      sign: freezed == sign
          ? _value.sign
          : sign // ignore: cast_nullable_to_non_nullable
              as MapEntitySignData?,
      item: freezed == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as MapEntityItemData?,
      spawn: freezed == spawn
          ? _value.spawn
          : spawn // ignore: cast_nullable_to_non_nullable
              as MapEntitySpawnData?,
      editorVisual: freezed == editorVisual
          ? _value.editorVisual
          : editorVisual // ignore: cast_nullable_to_non_nullable
              as MapEntityEditorVisual?,
      blocksMovement: null == blocksMovement
          ? _value.blocksMovement
          : blocksMovement // ignore: cast_nullable_to_non_nullable
              as bool,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridSizeCopyWith<$Res> get size {
    return $GridSizeCopyWith<$Res>(_value.size, (value) {
      return _then(_value.copyWith(size: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityNpcDataCopyWith<$Res>? get npc {
    if (_value.npc == null) {
      return null;
    }

    return $MapEntityNpcDataCopyWith<$Res>(_value.npc!, (value) {
      return _then(_value.copyWith(npc: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntitySignDataCopyWith<$Res>? get sign {
    if (_value.sign == null) {
      return null;
    }

    return $MapEntitySignDataCopyWith<$Res>(_value.sign!, (value) {
      return _then(_value.copyWith(sign: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityItemDataCopyWith<$Res>? get item {
    if (_value.item == null) {
      return null;
    }

    return $MapEntityItemDataCopyWith<$Res>(_value.item!, (value) {
      return _then(_value.copyWith(item: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntitySpawnDataCopyWith<$Res>? get spawn {
    if (_value.spawn == null) {
      return null;
    }

    return $MapEntitySpawnDataCopyWith<$Res>(_value.spawn!, (value) {
      return _then(_value.copyWith(spawn: value) as $Val);
    });
  }

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityEditorVisualCopyWith<$Res>? get editorVisual {
    if (_value.editorVisual == null) {
      return null;
    }

    return $MapEntityEditorVisualCopyWith<$Res>(_value.editorVisual!, (value) {
      return _then(_value.copyWith(editorVisual: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapEntityImplCopyWith<$Res>
    implements $MapEntityCopyWith<$Res> {
  factory _$$MapEntityImplCopyWith(
          _$MapEntityImpl value, $Res Function(_$MapEntityImpl) then) =
      __$$MapEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      MapEntityKind kind,
      GridPos pos,
      GridSize size,
      MapEntityNpcData? npc,
      MapEntitySignData? sign,
      MapEntityItemData? item,
      MapEntitySpawnData? spawn,
      MapEntityEditorVisual? editorVisual,
      bool blocksMovement,
      Map<String, String> properties});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $GridSizeCopyWith<$Res> get size;
  @override
  $MapEntityNpcDataCopyWith<$Res>? get npc;
  @override
  $MapEntitySignDataCopyWith<$Res>? get sign;
  @override
  $MapEntityItemDataCopyWith<$Res>? get item;
  @override
  $MapEntitySpawnDataCopyWith<$Res>? get spawn;
  @override
  $MapEntityEditorVisualCopyWith<$Res>? get editorVisual;
}

/// @nodoc
class __$$MapEntityImplCopyWithImpl<$Res>
    extends _$MapEntityCopyWithImpl<$Res, _$MapEntityImpl>
    implements _$$MapEntityImplCopyWith<$Res> {
  __$$MapEntityImplCopyWithImpl(
      _$MapEntityImpl _value, $Res Function(_$MapEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? kind = null,
    Object? pos = null,
    Object? size = null,
    Object? npc = freezed,
    Object? sign = freezed,
    Object? item = freezed,
    Object? spawn = freezed,
    Object? editorVisual = freezed,
    Object? blocksMovement = null,
    Object? properties = null,
  }) {
    return _then(_$MapEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MapEntityKind,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as GridSize,
      npc: freezed == npc
          ? _value.npc
          : npc // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcData?,
      sign: freezed == sign
          ? _value.sign
          : sign // ignore: cast_nullable_to_non_nullable
              as MapEntitySignData?,
      item: freezed == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as MapEntityItemData?,
      spawn: freezed == spawn
          ? _value.spawn
          : spawn // ignore: cast_nullable_to_non_nullable
              as MapEntitySpawnData?,
      editorVisual: freezed == editorVisual
          ? _value.editorVisual
          : editorVisual // ignore: cast_nullable_to_non_nullable
              as MapEntityEditorVisual?,
      blocksMovement: null == blocksMovement
          ? _value.blocksMovement
          : blocksMovement // ignore: cast_nullable_to_non_nullable
              as bool,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityImpl implements _MapEntity {
  const _$MapEntityImpl(
      {required this.id,
      this.name = '',
      required this.kind,
      required this.pos,
      this.size = const GridSize(width: 1, height: 1),
      this.npc,
      this.sign,
      this.item,
      this.spawn,
      this.editorVisual,
      this.blocksMovement = true,
      final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$MapEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntityImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final MapEntityKind kind;
  @override
  final GridPos pos;
  @override
  @JsonKey()
  final GridSize size;
  @override
  final MapEntityNpcData? npc;
  @override
  final MapEntitySignData? sign;
  @override
  final MapEntityItemData? item;
  @override
  final MapEntitySpawnData? spawn;
  @override
  final MapEntityEditorVisual? editorVisual;
  @override
  @JsonKey()
  final bool blocksMovement;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapEntity(id: $id, name: $name, kind: $kind, pos: $pos, size: $size, npc: $npc, sign: $sign, item: $item, spawn: $spawn, editorVisual: $editorVisual, blocksMovement: $blocksMovement, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.npc, npc) || other.npc == npc) &&
            (identical(other.sign, sign) || other.sign == sign) &&
            (identical(other.item, item) || other.item == item) &&
            (identical(other.spawn, spawn) || other.spawn == spawn) &&
            (identical(other.editorVisual, editorVisual) ||
                other.editorVisual == editorVisual) &&
            (identical(other.blocksMovement, blocksMovement) ||
                other.blocksMovement == blocksMovement) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      kind,
      pos,
      size,
      npc,
      sign,
      item,
      spawn,
      editorVisual,
      blocksMovement,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntityImplCopyWith<_$MapEntityImpl> get copyWith =>
      __$$MapEntityImplCopyWithImpl<_$MapEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntityImplToJson(
      this,
    );
  }
}

abstract class _MapEntity implements MapEntity {
  const factory _MapEntity(
      {required final String id,
      final String name,
      required final MapEntityKind kind,
      required final GridPos pos,
      final GridSize size,
      final MapEntityNpcData? npc,
      final MapEntitySignData? sign,
      final MapEntityItemData? item,
      final MapEntitySpawnData? spawn,
      final MapEntityEditorVisual? editorVisual,
      final bool blocksMovement,
      final Map<String, String> properties}) = _$MapEntityImpl;

  factory _MapEntity.fromJson(Map<String, dynamic> json) =
      _$MapEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  MapEntityKind get kind;
  @override
  GridPos get pos;
  @override
  GridSize get size;
  @override
  MapEntityNpcData? get npc;
  @override
  MapEntitySignData? get sign;
  @override
  MapEntityItemData? get item;
  @override
  MapEntitySpawnData? get spawn;
  @override
  MapEntityEditorVisual? get editorVisual;
  @override
  bool get blocksMovement;
  @override
  Map<String, String> get properties;

  /// Create a copy of MapEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntityImplCopyWith<_$MapEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapWarp _$MapWarpFromJson(Map<String, dynamic> json) {
  return _MapWarp.fromJson(json);
}

/// @nodoc
mixin _$MapWarp {
  String get id => throw _privateConstructorUsedError;
  GridPos get pos => throw _privateConstructorUsedError;
  String get targetMapId => throw _privateConstructorUsedError;
  GridPos get targetPos => throw _privateConstructorUsedError;
  MapWarpTriggerMode get triggerMode => throw _privateConstructorUsedError;
  List<EntityFacing> get allowedApproachFacings =>
      throw _privateConstructorUsedError;
  WarpTriggerPadding get triggerPadding => throw _privateConstructorUsedError;

  /// Serializes this MapWarp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapWarpCopyWith<MapWarp> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapWarpCopyWith<$Res> {
  factory $MapWarpCopyWith(MapWarp value, $Res Function(MapWarp) then) =
      _$MapWarpCopyWithImpl<$Res, MapWarp>;
  @useResult
  $Res call(
      {String id,
      GridPos pos,
      String targetMapId,
      GridPos targetPos,
      MapWarpTriggerMode triggerMode,
      List<EntityFacing> allowedApproachFacings,
      WarpTriggerPadding triggerPadding});

  $GridPosCopyWith<$Res> get pos;
  $GridPosCopyWith<$Res> get targetPos;
  $WarpTriggerPaddingCopyWith<$Res> get triggerPadding;
}

/// @nodoc
class _$MapWarpCopyWithImpl<$Res, $Val extends MapWarp>
    implements $MapWarpCopyWith<$Res> {
  _$MapWarpCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pos = null,
    Object? targetMapId = null,
    Object? targetPos = null,
    Object? triggerMode = null,
    Object? allowedApproachFacings = null,
    Object? triggerPadding = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      targetPos: null == targetPos
          ? _value.targetPos
          : targetPos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      triggerMode: null == triggerMode
          ? _value.triggerMode
          : triggerMode // ignore: cast_nullable_to_non_nullable
              as MapWarpTriggerMode,
      allowedApproachFacings: null == allowedApproachFacings
          ? _value.allowedApproachFacings
          : allowedApproachFacings // ignore: cast_nullable_to_non_nullable
              as List<EntityFacing>,
      triggerPadding: null == triggerPadding
          ? _value.triggerPadding
          : triggerPadding // ignore: cast_nullable_to_non_nullable
              as WarpTriggerPadding,
    ) as $Val);
  }

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get pos {
    return $GridPosCopyWith<$Res>(_value.pos, (value) {
      return _then(_value.copyWith(pos: value) as $Val);
    });
  }

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get targetPos {
    return $GridPosCopyWith<$Res>(_value.targetPos, (value) {
      return _then(_value.copyWith(targetPos: value) as $Val);
    });
  }

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WarpTriggerPaddingCopyWith<$Res> get triggerPadding {
    return $WarpTriggerPaddingCopyWith<$Res>(_value.triggerPadding, (value) {
      return _then(_value.copyWith(triggerPadding: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapWarpImplCopyWith<$Res> implements $MapWarpCopyWith<$Res> {
  factory _$$MapWarpImplCopyWith(
          _$MapWarpImpl value, $Res Function(_$MapWarpImpl) then) =
      __$$MapWarpImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      GridPos pos,
      String targetMapId,
      GridPos targetPos,
      MapWarpTriggerMode triggerMode,
      List<EntityFacing> allowedApproachFacings,
      WarpTriggerPadding triggerPadding});

  @override
  $GridPosCopyWith<$Res> get pos;
  @override
  $GridPosCopyWith<$Res> get targetPos;
  @override
  $WarpTriggerPaddingCopyWith<$Res> get triggerPadding;
}

/// @nodoc
class __$$MapWarpImplCopyWithImpl<$Res>
    extends _$MapWarpCopyWithImpl<$Res, _$MapWarpImpl>
    implements _$$MapWarpImplCopyWith<$Res> {
  __$$MapWarpImplCopyWithImpl(
      _$MapWarpImpl _value, $Res Function(_$MapWarpImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pos = null,
    Object? targetMapId = null,
    Object? targetPos = null,
    Object? triggerMode = null,
    Object? allowedApproachFacings = null,
    Object? triggerPadding = null,
  }) {
    return _then(_$MapWarpImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pos: null == pos
          ? _value.pos
          : pos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      targetPos: null == targetPos
          ? _value.targetPos
          : targetPos // ignore: cast_nullable_to_non_nullable
              as GridPos,
      triggerMode: null == triggerMode
          ? _value.triggerMode
          : triggerMode // ignore: cast_nullable_to_non_nullable
              as MapWarpTriggerMode,
      allowedApproachFacings: null == allowedApproachFacings
          ? _value._allowedApproachFacings
          : allowedApproachFacings // ignore: cast_nullable_to_non_nullable
              as List<EntityFacing>,
      triggerPadding: null == triggerPadding
          ? _value.triggerPadding
          : triggerPadding // ignore: cast_nullable_to_non_nullable
              as WarpTriggerPadding,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapWarpImpl implements _MapWarp {
  const _$MapWarpImpl(
      {required this.id,
      required this.pos,
      required this.targetMapId,
      required this.targetPos,
      this.triggerMode = MapWarpTriggerMode.onEnter,
      final List<EntityFacing> allowedApproachFacings = const [],
      this.triggerPadding = const WarpTriggerPadding()})
      : _allowedApproachFacings = allowedApproachFacings;

  factory _$MapWarpImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapWarpImplFromJson(json);

  @override
  final String id;
  @override
  final GridPos pos;
  @override
  final String targetMapId;
  @override
  final GridPos targetPos;
  @override
  @JsonKey()
  final MapWarpTriggerMode triggerMode;
  final List<EntityFacing> _allowedApproachFacings;
  @override
  @JsonKey()
  List<EntityFacing> get allowedApproachFacings {
    if (_allowedApproachFacings is EqualUnmodifiableListView)
      return _allowedApproachFacings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedApproachFacings);
  }

  @override
  @JsonKey()
  final WarpTriggerPadding triggerPadding;

  @override
  String toString() {
    return 'MapWarp(id: $id, pos: $pos, targetMapId: $targetMapId, targetPos: $targetPos, triggerMode: $triggerMode, allowedApproachFacings: $allowedApproachFacings, triggerPadding: $triggerPadding)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapWarpImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pos, pos) || other.pos == pos) &&
            (identical(other.targetMapId, targetMapId) ||
                other.targetMapId == targetMapId) &&
            (identical(other.targetPos, targetPos) ||
                other.targetPos == targetPos) &&
            (identical(other.triggerMode, triggerMode) ||
                other.triggerMode == triggerMode) &&
            const DeepCollectionEquality().equals(
                other._allowedApproachFacings, _allowedApproachFacings) &&
            (identical(other.triggerPadding, triggerPadding) ||
                other.triggerPadding == triggerPadding));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      pos,
      targetMapId,
      targetPos,
      triggerMode,
      const DeepCollectionEquality().hash(_allowedApproachFacings),
      triggerPadding);

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapWarpImplCopyWith<_$MapWarpImpl> get copyWith =>
      __$$MapWarpImplCopyWithImpl<_$MapWarpImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapWarpImplToJson(
      this,
    );
  }
}

abstract class _MapWarp implements MapWarp {
  const factory _MapWarp(
      {required final String id,
      required final GridPos pos,
      required final String targetMapId,
      required final GridPos targetPos,
      final MapWarpTriggerMode triggerMode,
      final List<EntityFacing> allowedApproachFacings,
      final WarpTriggerPadding triggerPadding}) = _$MapWarpImpl;

  factory _MapWarp.fromJson(Map<String, dynamic> json) = _$MapWarpImpl.fromJson;

  @override
  String get id;
  @override
  GridPos get pos;
  @override
  String get targetMapId;
  @override
  GridPos get targetPos;
  @override
  MapWarpTriggerMode get triggerMode;
  @override
  List<EntityFacing> get allowedApproachFacings;
  @override
  WarpTriggerPadding get triggerPadding;

  /// Create a copy of MapWarp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapWarpImplCopyWith<_$MapWarpImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WarpTriggerPadding _$WarpTriggerPaddingFromJson(Map<String, dynamic> json) {
  return _WarpTriggerPadding.fromJson(json);
}

/// @nodoc
mixin _$WarpTriggerPadding {
  int get top => throw _privateConstructorUsedError;
  int get right => throw _privateConstructorUsedError;
  int get bottom => throw _privateConstructorUsedError;
  int get left => throw _privateConstructorUsedError;

  /// Serializes this WarpTriggerPadding to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WarpTriggerPadding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WarpTriggerPaddingCopyWith<WarpTriggerPadding> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WarpTriggerPaddingCopyWith<$Res> {
  factory $WarpTriggerPaddingCopyWith(
          WarpTriggerPadding value, $Res Function(WarpTriggerPadding) then) =
      _$WarpTriggerPaddingCopyWithImpl<$Res, WarpTriggerPadding>;
  @useResult
  $Res call({int top, int right, int bottom, int left});
}

/// @nodoc
class _$WarpTriggerPaddingCopyWithImpl<$Res, $Val extends WarpTriggerPadding>
    implements $WarpTriggerPaddingCopyWith<$Res> {
  _$WarpTriggerPaddingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WarpTriggerPadding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = null,
    Object? right = null,
    Object? bottom = null,
    Object? left = null,
  }) {
    return _then(_value.copyWith(
      top: null == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
              as int,
      right: null == right
          ? _value.right
          : right // ignore: cast_nullable_to_non_nullable
              as int,
      bottom: null == bottom
          ? _value.bottom
          : bottom // ignore: cast_nullable_to_non_nullable
              as int,
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WarpTriggerPaddingImplCopyWith<$Res>
    implements $WarpTriggerPaddingCopyWith<$Res> {
  factory _$$WarpTriggerPaddingImplCopyWith(_$WarpTriggerPaddingImpl value,
          $Res Function(_$WarpTriggerPaddingImpl) then) =
      __$$WarpTriggerPaddingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int top, int right, int bottom, int left});
}

/// @nodoc
class __$$WarpTriggerPaddingImplCopyWithImpl<$Res>
    extends _$WarpTriggerPaddingCopyWithImpl<$Res, _$WarpTriggerPaddingImpl>
    implements _$$WarpTriggerPaddingImplCopyWith<$Res> {
  __$$WarpTriggerPaddingImplCopyWithImpl(_$WarpTriggerPaddingImpl _value,
      $Res Function(_$WarpTriggerPaddingImpl) _then)
      : super(_value, _then);

  /// Create a copy of WarpTriggerPadding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = null,
    Object? right = null,
    Object? bottom = null,
    Object? left = null,
  }) {
    return _then(_$WarpTriggerPaddingImpl(
      top: null == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
              as int,
      right: null == right
          ? _value.right
          : right // ignore: cast_nullable_to_non_nullable
              as int,
      bottom: null == bottom
          ? _value.bottom
          : bottom // ignore: cast_nullable_to_non_nullable
              as int,
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$WarpTriggerPaddingImpl implements _WarpTriggerPadding {
  const _$WarpTriggerPaddingImpl(
      {this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});

  factory _$WarpTriggerPaddingImpl.fromJson(Map<String, dynamic> json) =>
      _$$WarpTriggerPaddingImplFromJson(json);

  @override
  @JsonKey()
  final int top;
  @override
  @JsonKey()
  final int right;
  @override
  @JsonKey()
  final int bottom;
  @override
  @JsonKey()
  final int left;

  @override
  String toString() {
    return 'WarpTriggerPadding(top: $top, right: $right, bottom: $bottom, left: $left)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WarpTriggerPaddingImpl &&
            (identical(other.top, top) || other.top == top) &&
            (identical(other.right, right) || other.right == right) &&
            (identical(other.bottom, bottom) || other.bottom == bottom) &&
            (identical(other.left, left) || other.left == left));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, top, right, bottom, left);

  /// Create a copy of WarpTriggerPadding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WarpTriggerPaddingImplCopyWith<_$WarpTriggerPaddingImpl> get copyWith =>
      __$$WarpTriggerPaddingImplCopyWithImpl<_$WarpTriggerPaddingImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WarpTriggerPaddingImplToJson(
      this,
    );
  }
}

abstract class _WarpTriggerPadding implements WarpTriggerPadding {
  const factory _WarpTriggerPadding(
      {final int top,
      final int right,
      final int bottom,
      final int left}) = _$WarpTriggerPaddingImpl;

  factory _WarpTriggerPadding.fromJson(Map<String, dynamic> json) =
      _$WarpTriggerPaddingImpl.fromJson;

  @override
  int get top;
  @override
  int get right;
  @override
  int get bottom;
  @override
  int get left;

  /// Create a copy of WarpTriggerPadding
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WarpTriggerPaddingImplCopyWith<_$WarpTriggerPaddingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapConnection _$MapConnectionFromJson(Map<String, dynamic> json) {
  return _MapConnection.fromJson(json);
}

/// @nodoc
mixin _$MapConnection {
  MapConnectionDirection get direction => throw _privateConstructorUsedError;
  String get targetMapId => throw _privateConstructorUsedError;
  int get offset => throw _privateConstructorUsedError;

  /// Serializes this MapConnection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapConnectionCopyWith<MapConnection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapConnectionCopyWith<$Res> {
  factory $MapConnectionCopyWith(
          MapConnection value, $Res Function(MapConnection) then) =
      _$MapConnectionCopyWithImpl<$Res, MapConnection>;
  @useResult
  $Res call({MapConnectionDirection direction, String targetMapId, int offset});
}

/// @nodoc
class _$MapConnectionCopyWithImpl<$Res, $Val extends MapConnection>
    implements $MapConnectionCopyWith<$Res> {
  _$MapConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? targetMapId = null,
    Object? offset = null,
  }) {
    return _then(_value.copyWith(
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as MapConnectionDirection,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapConnectionImplCopyWith<$Res>
    implements $MapConnectionCopyWith<$Res> {
  factory _$$MapConnectionImplCopyWith(
          _$MapConnectionImpl value, $Res Function(_$MapConnectionImpl) then) =
      __$$MapConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MapConnectionDirection direction, String targetMapId, int offset});
}

/// @nodoc
class __$$MapConnectionImplCopyWithImpl<$Res>
    extends _$MapConnectionCopyWithImpl<$Res, _$MapConnectionImpl>
    implements _$$MapConnectionImplCopyWith<$Res> {
  __$$MapConnectionImplCopyWithImpl(
      _$MapConnectionImpl _value, $Res Function(_$MapConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? targetMapId = null,
    Object? offset = null,
  }) {
    return _then(_$MapConnectionImpl(
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as MapConnectionDirection,
      targetMapId: null == targetMapId
          ? _value.targetMapId
          : targetMapId // ignore: cast_nullable_to_non_nullable
              as String,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapConnectionImpl implements _MapConnection {
  const _$MapConnectionImpl(
      {required this.direction, required this.targetMapId, this.offset = 0});

  factory _$MapConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapConnectionImplFromJson(json);

  @override
  final MapConnectionDirection direction;
  @override
  final String targetMapId;
  @override
  @JsonKey()
  final int offset;

  @override
  String toString() {
    return 'MapConnection(direction: $direction, targetMapId: $targetMapId, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapConnectionImpl &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.targetMapId, targetMapId) ||
                other.targetMapId == targetMapId) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, direction, targetMapId, offset);

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapConnectionImplCopyWith<_$MapConnectionImpl> get copyWith =>
      __$$MapConnectionImplCopyWithImpl<_$MapConnectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapConnectionImplToJson(
      this,
    );
  }
}

abstract class _MapConnection implements MapConnection {
  const factory _MapConnection(
      {required final MapConnectionDirection direction,
      required final String targetMapId,
      final int offset}) = _$MapConnectionImpl;

  factory _MapConnection.fromJson(Map<String, dynamic> json) =
      _$MapConnectionImpl.fromJson;

  @override
  MapConnectionDirection get direction;
  @override
  String get targetMapId;
  @override
  int get offset;

  /// Create a copy of MapConnection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapConnectionImplCopyWith<_$MapConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapTrigger _$MapTriggerFromJson(Map<String, dynamic> json) {
  return _MapTrigger.fromJson(json);
}

/// @nodoc
mixin _$MapTrigger {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  TriggerType get type => throw _privateConstructorUsedError;
  MapRect get area => throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this MapTrigger to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapTriggerCopyWith<MapTrigger> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapTriggerCopyWith<$Res> {
  factory $MapTriggerCopyWith(
          MapTrigger value, $Res Function(MapTrigger) then) =
      _$MapTriggerCopyWithImpl<$Res, MapTrigger>;
  @useResult
  $Res call(
      {String id,
      String name,
      TriggerType type,
      MapRect area,
      Map<String, String> properties});

  $MapRectCopyWith<$Res> get area;
}

/// @nodoc
class _$MapTriggerCopyWithImpl<$Res, $Val extends MapTrigger>
    implements $MapTriggerCopyWith<$Res> {
  _$MapTriggerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? area = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapRectCopyWith<$Res> get area {
    return $MapRectCopyWith<$Res>(_value.area, (value) {
      return _then(_value.copyWith(area: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapTriggerImplCopyWith<$Res>
    implements $MapTriggerCopyWith<$Res> {
  factory _$$MapTriggerImplCopyWith(
          _$MapTriggerImpl value, $Res Function(_$MapTriggerImpl) then) =
      __$$MapTriggerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      TriggerType type,
      MapRect area,
      Map<String, String> properties});

  @override
  $MapRectCopyWith<$Res> get area;
}

/// @nodoc
class __$$MapTriggerImplCopyWithImpl<$Res>
    extends _$MapTriggerCopyWithImpl<$Res, _$MapTriggerImpl>
    implements _$$MapTriggerImplCopyWith<$Res> {
  __$$MapTriggerImplCopyWithImpl(
      _$MapTriggerImpl _value, $Res Function(_$MapTriggerImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? area = null,
    Object? properties = null,
  }) {
    return _then(_$MapTriggerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as MapRect,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapTriggerImpl implements _MapTrigger {
  const _$MapTriggerImpl(
      {required this.id,
      this.name = '',
      required this.type,
      required this.area,
      final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$MapTriggerImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapTriggerImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  final TriggerType type;
  @override
  final MapRect area;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'MapTrigger(id: $id, name: $name, type: $type, area: $area, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapTriggerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.area, area) || other.area == area) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, type, area,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapTriggerImplCopyWith<_$MapTriggerImpl> get copyWith =>
      __$$MapTriggerImplCopyWithImpl<_$MapTriggerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapTriggerImplToJson(
      this,
    );
  }
}

abstract class _MapTrigger implements MapTrigger {
  const factory _MapTrigger(
      {required final String id,
      final String name,
      required final TriggerType type,
      required final MapRect area,
      final Map<String, String> properties}) = _$MapTriggerImpl;

  factory _MapTrigger.fromJson(Map<String, dynamic> json) =
      _$MapTriggerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  TriggerType get type;
  @override
  MapRect get area;
  @override
  Map<String, String> get properties;

  /// Create a copy of MapTrigger
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapTriggerImplCopyWith<_$MapTriggerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

````

### packages/map_core/lib/src/models/map_data.g.dart

````dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MapDataImpl _$$MapDataImplFromJson(Map<String, dynamic> json) =>
    _$MapDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      size: GridSize.fromJson(json['size'] as Map<String, dynamic>),
      version: $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
          ProjectVersion.v1,
      tilesetId: json['tilesetId'] as String? ?? '',
      layers: (json['layers'] as List<dynamic>?)
              ?.map((e) => MapLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      placedElements: (json['placedElements'] as List<dynamic>?)
              ?.map((e) => MapPlacedElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => MapEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      connections: (json['connections'] as List<dynamic>?)
              ?.map((e) => MapConnection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      warps: (json['warps'] as List<dynamic>?)
              ?.map((e) => MapWarp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => MapTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      gameplayZones: (json['gameplayZones'] as List<dynamic>?)
              ?.map((e) => MapGameplayZone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mapMetadata: json['mapMetadata'] == null
          ? const MapMetadata()
          : MapMetadata.fromJson(json['mapMetadata'] as Map<String, dynamic>),
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
      events: (json['events'] as List<dynamic>?)
              ?.map(
                  (e) => MapEventDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MapDataImplToJson(_$MapDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size.toJson(),
      'version': _$ProjectVersionEnumMap[instance.version]!,
      'tilesetId': instance.tilesetId,
      'layers': instance.layers.map((e) => e.toJson()).toList(),
      'placedElements': instance.placedElements.map((e) => e.toJson()).toList(),
      'entities': instance.entities.map((e) => e.toJson()).toList(),
      'connections': instance.connections.map((e) => e.toJson()).toList(),
      'warps': instance.warps.map((e) => e.toJson()).toList(),
      'triggers': instance.triggers.map((e) => e.toJson()).toList(),
      'gameplayZones': instance.gameplayZones.map((e) => e.toJson()).toList(),
      'mapMetadata': instance.mapMetadata.toJson(),
      'properties': instance.properties,
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
};

_$MapGameplayZoneImpl _$$MapGameplayZoneImplFromJson(
        Map<String, dynamic> json) =>
    _$MapGameplayZoneImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      kind: $enumDecode(_$GameplayZoneKindEnumMap, json['kind']),
      area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      encounter: json['encounter'] == null
          ? null
          : EncounterZonePayload.fromJson(
              json['encounter'] as Map<String, dynamic>),
      movement: json['movement'] == null
          ? null
          : MovementZonePayload.fromJson(
              json['movement'] as Map<String, dynamic>),
      movementEffect: json['movementEffect'] == null
          ? null
          : MovementEffectZonePayload.fromJson(
              json['movementEffect'] as Map<String, dynamic>),
      hazard: json['hazard'] == null
          ? null
          : HazardZonePayload.fromJson(json['hazard'] as Map<String, dynamic>),
      special: json['special'] == null
          ? null
          : SpecialZonePayload.fromJson(
              json['special'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapGameplayZoneImplToJson(
        _$MapGameplayZoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$GameplayZoneKindEnumMap[instance.kind]!,
      'area': instance.area.toJson(),
      'priority': instance.priority,
      'encounter': instance.encounter?.toJson(),
      'movement': instance.movement?.toJson(),
      'movementEffect': instance.movementEffect?.toJson(),
      'hazard': instance.hazard?.toJson(),
      'special': instance.special?.toJson(),
    };

const _$GameplayZoneKindEnumMap = {
  GameplayZoneKind.encounter: 'encounter',
  GameplayZoneKind.movement: 'movement',
  GameplayZoneKind.movementEffect: 'movementEffect',
  GameplayZoneKind.hazard: 'hazard',
  GameplayZoneKind.special: 'special',
  GameplayZoneKind.custom: 'custom',
};

_$MapPlacedElementImpl _$$MapPlacedElementImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementImpl(
      id: json['id'] as String,
      layerId: json['layerId'] as String,
      elementId: json['elementId'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      applyCollision: json['applyCollision'] as bool? ?? true,
      animation: json['animation'] == null
          ? null
          : MapPlacedElementAnimation.fromJson(
              json['animation'] as Map<String, dynamic>),
      behaviors: (json['behaviors'] as List<dynamic>?)
              ?.map((e) =>
                  MapPlacedElementBehavior.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapPlacedElementImplToJson(
        _$MapPlacedElementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'layerId': instance.layerId,
      'elementId': instance.elementId,
      'pos': instance.pos.toJson(),
      'applyCollision': instance.applyCollision,
      'animation': instance.animation?.toJson(),
      'behaviors': instance.behaviors.map((e) => e.toJson()).toList(),
      'properties': instance.properties,
    };

_$MapPlacedElementBehaviorImpl _$$MapPlacedElementBehaviorImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementBehaviorImpl(
      id: json['id'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      triggerScope: $enumDecodeNullable(
              _$MapPlacedElementTriggerScopeEnumMap, json['triggerScope']) ??
          MapPlacedElementTriggerScope.defaultScope,
      cooldownMs: (json['cooldownMs'] as num?)?.toInt(),
      trigger: $enumDecodeNullable(
              _$MapPlacedElementTriggerTypeEnumMap, json['trigger']) ??
          MapPlacedElementTriggerType.onAction,
      effect: MapPlacedElementEffect.fromJson(
          json['effect'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapPlacedElementBehaviorImplToJson(
        _$MapPlacedElementBehaviorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'enabled': instance.enabled,
      'triggerScope':
          _$MapPlacedElementTriggerScopeEnumMap[instance.triggerScope]!,
      'cooldownMs': instance.cooldownMs,
      'trigger': _$MapPlacedElementTriggerTypeEnumMap[instance.trigger]!,
      'effect': instance.effect.toJson(),
    };

const _$MapPlacedElementTriggerScopeEnumMap = {
  MapPlacedElementTriggerScope.defaultScope: 'default',
  MapPlacedElementTriggerScope.oncePerEnter: 'once_per_enter',
  MapPlacedElementTriggerScope.whileInsideSingleShot:
      'while_inside_single_shot',
  MapPlacedElementTriggerScope.facingOnly: 'facing_only',
  MapPlacedElementTriggerScope.nearCardinalOnly: 'near_cardinal_only',
};

const _$MapPlacedElementTriggerTypeEnumMap = {
  MapPlacedElementTriggerType.onAction: 'on_action',
  MapPlacedElementTriggerType.onEnter: 'on_enter',
  MapPlacedElementTriggerType.onBump: 'on_bump',
  MapPlacedElementTriggerType.onExit: 'on_exit',
  MapPlacedElementTriggerType.onNear: 'on_near',
};

_$MapPlacedElementEffectImpl _$$MapPlacedElementEffectImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementEffectImpl(
      type: $enumDecode(_$MapPlacedElementEffectTypeEnumMap, json['type']),
      message: json['message'] as String?,
      dialogue: json['dialogue'] == null
          ? null
          : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
      animationEnabled: json['animationEnabled'] as bool?,
    );

Map<String, dynamic> _$$MapPlacedElementEffectImplToJson(
        _$MapPlacedElementEffectImpl instance) =>
    <String, dynamic>{
      'type': _$MapPlacedElementEffectTypeEnumMap[instance.type]!,
      'message': instance.message,
      'dialogue': instance.dialogue?.toJson(),
      'animationEnabled': instance.animationEnabled,
    };

const _$MapPlacedElementEffectTypeEnumMap = {
  MapPlacedElementEffectType.showMessage: 'show_message',
  MapPlacedElementEffectType.openDialogue: 'open_dialogue',
  MapPlacedElementEffectType.setAnimationEnabled: 'set_animation_enabled',
  MapPlacedElementEffectType.playAnimationOnce: 'play_animation_once',
};

_$MapPlacedElementAnimationImpl _$$MapPlacedElementAnimationImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementAnimationImpl(
      enabled: json['enabled'] as bool? ?? false,
      mode: $enumDecodeNullable(
              _$MapPlacedElementAnimationModeEnumMap, json['mode']) ??
          MapPlacedElementAnimationMode.none,
      autoplay: json['autoplay'] as bool? ?? true,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      startOffsetMs: (json['startOffsetMs'] as num?)?.toDouble(),
      randomStart: json['randomStart'] as bool? ?? false,
    );

Map<String, dynamic> _$$MapPlacedElementAnimationImplToJson(
        _$MapPlacedElementAnimationImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'mode': _$MapPlacedElementAnimationModeEnumMap[instance.mode]!,
      'autoplay': instance.autoplay,
      'speed': instance.speed,
      'startOffsetMs': instance.startOffsetMs,
      'randomStart': instance.randomStart,
    };

const _$MapPlacedElementAnimationModeEnumMap = {
  MapPlacedElementAnimationMode.none: 'none',
  MapPlacedElementAnimationMode.loop: 'loop',
  MapPlacedElementAnimationMode.pingPong: 'ping_pong',
};

_$MapEntityImpl _$$MapEntityImplFromJson(Map<String, dynamic> json) =>
    _$MapEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      kind: $enumDecode(_$MapEntityKindEnumMap, json['kind']),
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      size: json['size'] == null
          ? const GridSize(width: 1, height: 1)
          : GridSize.fromJson(json['size'] as Map<String, dynamic>),
      npc: json['npc'] == null
          ? null
          : MapEntityNpcData.fromJson(json['npc'] as Map<String, dynamic>),
      sign: json['sign'] == null
          ? null
          : MapEntitySignData.fromJson(json['sign'] as Map<String, dynamic>),
      item: json['item'] == null
          ? null
          : MapEntityItemData.fromJson(json['item'] as Map<String, dynamic>),
      spawn: json['spawn'] == null
          ? null
          : MapEntitySpawnData.fromJson(json['spawn'] as Map<String, dynamic>),
      editorVisual: json['editorVisual'] == null
          ? null
          : MapEntityEditorVisual.fromJson(
              json['editorVisual'] as Map<String, dynamic>),
      blocksMovement: json['blocksMovement'] as bool? ?? true,
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapEntityImplToJson(_$MapEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$MapEntityKindEnumMap[instance.kind]!,
      'pos': instance.pos.toJson(),
      'size': instance.size.toJson(),
      'npc': instance.npc?.toJson(),
      'sign': instance.sign?.toJson(),
      'item': instance.item?.toJson(),
      'spawn': instance.spawn?.toJson(),
      'editorVisual': instance.editorVisual?.toJson(),
      'blocksMovement': instance.blocksMovement,
      'properties': instance.properties,
    };

const _$MapEntityKindEnumMap = {
  MapEntityKind.npc: 'npc',
  MapEntityKind.sign: 'sign',
  MapEntityKind.item: 'item',
  MapEntityKind.spawn: 'spawn',
  MapEntityKind.custom: 'custom',
};

_$MapWarpImpl _$$MapWarpImplFromJson(Map<String, dynamic> json) =>
    _$MapWarpImpl(
      id: json['id'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      targetMapId: json['targetMapId'] as String,
      targetPos: GridPos.fromJson(json['targetPos'] as Map<String, dynamic>),
      triggerMode: $enumDecodeNullable(
              _$MapWarpTriggerModeEnumMap, json['triggerMode']) ??
          MapWarpTriggerMode.onEnter,
      allowedApproachFacings: (json['allowedApproachFacings'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$EntityFacingEnumMap, e))
              .toList() ??
          const [],
      triggerPadding: json['triggerPadding'] == null
          ? const WarpTriggerPadding()
          : WarpTriggerPadding.fromJson(
              json['triggerPadding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapWarpImplToJson(_$MapWarpImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pos': instance.pos.toJson(),
      'targetMapId': instance.targetMapId,
      'targetPos': instance.targetPos.toJson(),
      'triggerMode': _$MapWarpTriggerModeEnumMap[instance.triggerMode]!,
      'allowedApproachFacings': instance.allowedApproachFacings
          .map((e) => _$EntityFacingEnumMap[e]!)
          .toList(),
      'triggerPadding': instance.triggerPadding.toJson(),
    };

const _$MapWarpTriggerModeEnumMap = {
  MapWarpTriggerMode.onEnter: 'on_enter',
  MapWarpTriggerMode.onBump: 'on_bump',
};

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_$WarpTriggerPaddingImpl _$$WarpTriggerPaddingImplFromJson(
        Map<String, dynamic> json) =>
    _$WarpTriggerPaddingImpl(
      top: (json['top'] as num?)?.toInt() ?? 0,
      right: (json['right'] as num?)?.toInt() ?? 0,
      bottom: (json['bottom'] as num?)?.toInt() ?? 0,
      left: (json['left'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$WarpTriggerPaddingImplToJson(
        _$WarpTriggerPaddingImpl instance) =>
    <String, dynamic>{
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
      'left': instance.left,
    };

_$MapConnectionImpl _$$MapConnectionImplFromJson(Map<String, dynamic> json) =>
    _$MapConnectionImpl(
      direction:
          $enumDecode(_$MapConnectionDirectionEnumMap, json['direction']),
      targetMapId: json['targetMapId'] as String,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MapConnectionImplToJson(_$MapConnectionImpl instance) =>
    <String, dynamic>{
      'direction': _$MapConnectionDirectionEnumMap[instance.direction]!,
      'targetMapId': instance.targetMapId,
      'offset': instance.offset,
    };

const _$MapConnectionDirectionEnumMap = {
  MapConnectionDirection.north: 'north',
  MapConnectionDirection.south: 'south',
  MapConnectionDirection.east: 'east',
  MapConnectionDirection.west: 'west',
};

_$MapTriggerImpl _$$MapTriggerImplFromJson(Map<String, dynamic> json) =>
    _$MapTriggerImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: $enumDecode(_$TriggerTypeEnumMap, json['type']),
      area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapTriggerImplToJson(_$MapTriggerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TriggerTypeEnumMap[instance.type]!,
      'area': instance.area.toJson(),
      'properties': instance.properties,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.warp: 'warp',
  TriggerType.message: 'message',
  TriggerType.interaction: 'interaction',
  TriggerType.event: 'event',
  TriggerType.spawn: 'spawn',
  TriggerType.camera: 'camera',
  TriggerType.custom: 'custom',
};

````

### packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart

````dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'map_gameplay_zone_payloads.freezed.dart';
part 'map_gameplay_zone_payloads.g.dart';

// ---------------------------------------------------------------------------
// Payloads typés par kind de zone gameplay
// ---------------------------------------------------------------------------

/// Payload d'une zone [GameplayZoneKind.encounter].
/// Lie la zone à une [ProjectEncounterTable] et précise le type de rencontre.
@freezed
class EncounterZonePayload with _$EncounterZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory EncounterZonePayload({
    /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
    String? encounterTableId,

    /// Type de rencontre déclenchée dans cette zone.
    @Default(EncounterKind.walk) EncounterKind encounterKind,

    /// Image de fond de combat authorée explicitement pour cette zone.
    ///
    /// Le chemin reste project-local et optionnel :
    /// - aucune bibliothèque média globale n'est introduite ici ;
    /// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
    /// - l'absence de valeur garde le comportement contextuel existant.
    String? battleBackgroundRelativePath,
  }) = _EncounterZonePayload;

  factory EncounterZonePayload.fromJson(Map<String, dynamic> json) =>
      _$EncounterZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.movement].
/// Contrainte ou mode de déplacement requis/appliqué dans la zone.
///
/// Les effets de surface comme la glissade ou le coût de déplacement restent
/// séparés dans [MovementEffectZonePayload] pour éviter de transformer ce
/// payload de gate en fourre-tout.
@freezed
class MovementZonePayload with _$MovementZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory MovementZonePayload({
    /// Mode de déplacement requis pour traverser la zone.
    @Default(MovementMode.walk) MovementMode requiredMode,

    /// Modes supplémentaires autorisés en plus de [requiredMode].
    @Default([]) List<MovementMode> allowedModes,
  }) = _MovementZonePayload;

  factory MovementZonePayload.fromJson(Map<String, dynamic> json) =>
      _$MovementZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.movementEffect].
///
/// Le payload décrit une source persistante typée. `map_gameplay` décidera
/// plus tard comment la transformer en `GameplayMovementEffect`.
@freezed
class MovementEffectZonePayload with _$MovementEffectZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory MovementEffectZonePayload({
    @Default(MovementEffectZoneKind.slide) MovementEffectZoneKind effectKind,

    /// Coût entier positif pour [MovementEffectZoneKind.movementCost].
    ///
    /// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
    /// pour garder un JSON stable, mais elle n'est pas consommée.
    @Default(1) int movementCost,
  }) = _MovementEffectZonePayload;

  factory MovementEffectZonePayload.fromJson(Map<String, dynamic> json) =>
      _$MovementEffectZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.hazard].
/// Définit le type de danger et son effet sur le personnage.
@freezed
class HazardZonePayload with _$HazardZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory HazardZonePayload({
    @Default(HazardKind.other) HazardKind hazardKind,

    /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
    @Default(0) int damagePerStep,
  }) = _HazardZonePayload;

  factory HazardZonePayload.fromJson(Map<String, dynamic> json) =>
      _$HazardZonePayloadFromJson(json);
}

/// Payload d'une zone [GameplayZoneKind.special] (et `custom`).
/// Données libres pour les comportements scriptés ou les extensions.
@freezed
class SpecialZonePayload with _$SpecialZonePayload {
  @JsonSerializable(explicitToJson: true)
  const factory SpecialZonePayload({
    /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
    String? scriptKey,

    /// Propriétés libres (clé → valeur).
    @Default({}) Map<String, String> properties,
  }) = _SpecialZonePayload;

  factory SpecialZonePayload.fromJson(Map<String, dynamic> json) =>
      _$SpecialZonePayloadFromJson(json);
}

// ---------------------------------------------------------------------------
// Migration JSON legacy → format typé
// ---------------------------------------------------------------------------

/// Migre un objet JSON [MapGameplayZone] depuis l'ancien format à plat
/// vers le nouveau format à payloads typés.
///
/// Transformations appliquées :
/// - `kind == 'transition'` → `'special'`
/// - champ plat `encounterTableId` → `encounter.encounterTableId`
/// - champ plat `movementMode`    → `movement.requiredMode`
/// - champ plat `properties`      → `special.properties`
Map<String, dynamic> migrateMapGameplayZoneJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);

  // transition n'existe plus → special
  if (out['kind'] == 'transition') {
    out['kind'] = 'special';
  }

  // encounterTableId plat → encounter payload
  final rawEncounterTableId = out.remove('encounterTableId');
  if (rawEncounterTableId is String && rawEncounterTableId.trim().isNotEmpty) {
    if (out['encounter'] == null) {
      out['encounter'] = <String, dynamic>{
        'encounterTableId': rawEncounterTableId,
        'encounterKind': 'walk',
      };
    }
  }

  // movementMode plat → movement payload
  final rawMovementMode = out.remove('movementMode');
  if (rawMovementMode is String && rawMovementMode.trim().isNotEmpty) {
    if (out['movement'] == null) {
      out['movement'] = <String, dynamic>{
        'requiredMode': rawMovementMode,
      };
    }
  }

  // properties plat → special.properties
  final rawProperties = out.remove('properties');
  if (rawProperties is Map && rawProperties.isNotEmpty) {
    final existing = out['special'] as Map<String, dynamic>?;
    if (existing == null) {
      out['special'] = <String, dynamic>{
        'properties': rawProperties,
      };
    } else {
      out['special'] = <String, dynamic>{
        ...existing,
        'properties': rawProperties,
      };
    }
  }

  return out;
}

````

### packages/map_core/lib/src/models/map_gameplay_zone_payloads.freezed.dart

````dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EncounterZonePayload _$EncounterZonePayloadFromJson(Map<String, dynamic> json) {
  return _EncounterZonePayload.fromJson(json);
}

/// @nodoc
mixin _$EncounterZonePayload {
  /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
  String? get encounterTableId => throw _privateConstructorUsedError;

  /// Type de rencontre déclenchée dans cette zone.
  EncounterKind get encounterKind => throw _privateConstructorUsedError;

  /// Image de fond de combat authorée explicitement pour cette zone.
  ///
  /// Le chemin reste project-local et optionnel :
  /// - aucune bibliothèque média globale n'est introduite ici ;
  /// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
  /// - l'absence de valeur garde le comportement contextuel existant.
  String? get battleBackgroundRelativePath =>
      throw _privateConstructorUsedError;

  /// Serializes this EncounterZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EncounterZonePayloadCopyWith<EncounterZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EncounterZonePayloadCopyWith<$Res> {
  factory $EncounterZonePayloadCopyWith(EncounterZonePayload value,
          $Res Function(EncounterZonePayload) then) =
      _$EncounterZonePayloadCopyWithImpl<$Res, EncounterZonePayload>;
  @useResult
  $Res call(
      {String? encounterTableId,
      EncounterKind encounterKind,
      String? battleBackgroundRelativePath});
}

/// @nodoc
class _$EncounterZonePayloadCopyWithImpl<$Res,
        $Val extends EncounterZonePayload>
    implements $EncounterZonePayloadCopyWith<$Res> {
  _$EncounterZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? encounterTableId = freezed,
    Object? encounterKind = null,
    Object? battleBackgroundRelativePath = freezed,
  }) {
    return _then(_value.copyWith(
      encounterTableId: freezed == encounterTableId
          ? _value.encounterTableId
          : encounterTableId // ignore: cast_nullable_to_non_nullable
              as String?,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
      battleBackgroundRelativePath: freezed == battleBackgroundRelativePath
          ? _value.battleBackgroundRelativePath
          : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EncounterZonePayloadImplCopyWith<$Res>
    implements $EncounterZonePayloadCopyWith<$Res> {
  factory _$$EncounterZonePayloadImplCopyWith(_$EncounterZonePayloadImpl value,
          $Res Function(_$EncounterZonePayloadImpl) then) =
      __$$EncounterZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? encounterTableId,
      EncounterKind encounterKind,
      String? battleBackgroundRelativePath});
}

/// @nodoc
class __$$EncounterZonePayloadImplCopyWithImpl<$Res>
    extends _$EncounterZonePayloadCopyWithImpl<$Res, _$EncounterZonePayloadImpl>
    implements _$$EncounterZonePayloadImplCopyWith<$Res> {
  __$$EncounterZonePayloadImplCopyWithImpl(_$EncounterZonePayloadImpl _value,
      $Res Function(_$EncounterZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? encounterTableId = freezed,
    Object? encounterKind = null,
    Object? battleBackgroundRelativePath = freezed,
  }) {
    return _then(_$EncounterZonePayloadImpl(
      encounterTableId: freezed == encounterTableId
          ? _value.encounterTableId
          : encounterTableId // ignore: cast_nullable_to_non_nullable
              as String?,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
      battleBackgroundRelativePath: freezed == battleBackgroundRelativePath
          ? _value.battleBackgroundRelativePath
          : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$EncounterZonePayloadImpl implements _EncounterZonePayload {
  const _$EncounterZonePayloadImpl(
      {this.encounterTableId,
      this.encounterKind = EncounterKind.walk,
      this.battleBackgroundRelativePath});

  factory _$EncounterZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$EncounterZonePayloadImplFromJson(json);

  /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
  @override
  final String? encounterTableId;

  /// Type de rencontre déclenchée dans cette zone.
  @override
  @JsonKey()
  final EncounterKind encounterKind;

  /// Image de fond de combat authorée explicitement pour cette zone.
  ///
  /// Le chemin reste project-local et optionnel :
  /// - aucune bibliothèque média globale n'est introduite ici ;
  /// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
  /// - l'absence de valeur garde le comportement contextuel existant.
  @override
  final String? battleBackgroundRelativePath;

  @override
  String toString() {
    return 'EncounterZonePayload(encounterTableId: $encounterTableId, encounterKind: $encounterKind, battleBackgroundRelativePath: $battleBackgroundRelativePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EncounterZonePayloadImpl &&
            (identical(other.encounterTableId, encounterTableId) ||
                other.encounterTableId == encounterTableId) &&
            (identical(other.encounterKind, encounterKind) ||
                other.encounterKind == encounterKind) &&
            (identical(other.battleBackgroundRelativePath,
                    battleBackgroundRelativePath) ||
                other.battleBackgroundRelativePath ==
                    battleBackgroundRelativePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, encounterTableId, encounterKind,
      battleBackgroundRelativePath);

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EncounterZonePayloadImplCopyWith<_$EncounterZonePayloadImpl>
      get copyWith =>
          __$$EncounterZonePayloadImplCopyWithImpl<_$EncounterZonePayloadImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EncounterZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _EncounterZonePayload implements EncounterZonePayload {
  const factory _EncounterZonePayload(
      {final String? encounterTableId,
      final EncounterKind encounterKind,
      final String? battleBackgroundRelativePath}) = _$EncounterZonePayloadImpl;

  factory _EncounterZonePayload.fromJson(Map<String, dynamic> json) =
      _$EncounterZonePayloadImpl.fromJson;

  /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
  @override
  String? get encounterTableId;

  /// Type de rencontre déclenchée dans cette zone.
  @override
  EncounterKind get encounterKind;

  /// Image de fond de combat authorée explicitement pour cette zone.
  ///
  /// Le chemin reste project-local et optionnel :
  /// - aucune bibliothèque média globale n'est introduite ici ;
  /// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
  /// - l'absence de valeur garde le comportement contextuel existant.
  @override
  String? get battleBackgroundRelativePath;

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EncounterZonePayloadImplCopyWith<_$EncounterZonePayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MovementZonePayload _$MovementZonePayloadFromJson(Map<String, dynamic> json) {
  return _MovementZonePayload.fromJson(json);
}

/// @nodoc
mixin _$MovementZonePayload {
  /// Mode de déplacement requis pour traverser la zone.
  MovementMode get requiredMode => throw _privateConstructorUsedError;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  List<MovementMode> get allowedModes => throw _privateConstructorUsedError;

  /// Serializes this MovementZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MovementZonePayloadCopyWith<MovementZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MovementZonePayloadCopyWith<$Res> {
  factory $MovementZonePayloadCopyWith(
          MovementZonePayload value, $Res Function(MovementZonePayload) then) =
      _$MovementZonePayloadCopyWithImpl<$Res, MovementZonePayload>;
  @useResult
  $Res call({MovementMode requiredMode, List<MovementMode> allowedModes});
}

/// @nodoc
class _$MovementZonePayloadCopyWithImpl<$Res, $Val extends MovementZonePayload>
    implements $MovementZonePayloadCopyWith<$Res> {
  _$MovementZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requiredMode = null,
    Object? allowedModes = null,
  }) {
    return _then(_value.copyWith(
      requiredMode: null == requiredMode
          ? _value.requiredMode
          : requiredMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      allowedModes: null == allowedModes
          ? _value.allowedModes
          : allowedModes // ignore: cast_nullable_to_non_nullable
              as List<MovementMode>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MovementZonePayloadImplCopyWith<$Res>
    implements $MovementZonePayloadCopyWith<$Res> {
  factory _$$MovementZonePayloadImplCopyWith(_$MovementZonePayloadImpl value,
          $Res Function(_$MovementZonePayloadImpl) then) =
      __$$MovementZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MovementMode requiredMode, List<MovementMode> allowedModes});
}

/// @nodoc
class __$$MovementZonePayloadImplCopyWithImpl<$Res>
    extends _$MovementZonePayloadCopyWithImpl<$Res, _$MovementZonePayloadImpl>
    implements _$$MovementZonePayloadImplCopyWith<$Res> {
  __$$MovementZonePayloadImplCopyWithImpl(_$MovementZonePayloadImpl _value,
      $Res Function(_$MovementZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requiredMode = null,
    Object? allowedModes = null,
  }) {
    return _then(_$MovementZonePayloadImpl(
      requiredMode: null == requiredMode
          ? _value.requiredMode
          : requiredMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      allowedModes: null == allowedModes
          ? _value._allowedModes
          : allowedModes // ignore: cast_nullable_to_non_nullable
              as List<MovementMode>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MovementZonePayloadImpl implements _MovementZonePayload {
  const _$MovementZonePayloadImpl(
      {this.requiredMode = MovementMode.walk,
      final List<MovementMode> allowedModes = const []})
      : _allowedModes = allowedModes;

  factory _$MovementZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MovementZonePayloadImplFromJson(json);

  /// Mode de déplacement requis pour traverser la zone.
  @override
  @JsonKey()
  final MovementMode requiredMode;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  final List<MovementMode> _allowedModes;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  @override
  @JsonKey()
  List<MovementMode> get allowedModes {
    if (_allowedModes is EqualUnmodifiableListView) return _allowedModes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedModes);
  }

  @override
  String toString() {
    return 'MovementZonePayload(requiredMode: $requiredMode, allowedModes: $allowedModes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MovementZonePayloadImpl &&
            (identical(other.requiredMode, requiredMode) ||
                other.requiredMode == requiredMode) &&
            const DeepCollectionEquality()
                .equals(other._allowedModes, _allowedModes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, requiredMode,
      const DeepCollectionEquality().hash(_allowedModes));

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MovementZonePayloadImplCopyWith<_$MovementZonePayloadImpl> get copyWith =>
      __$$MovementZonePayloadImplCopyWithImpl<_$MovementZonePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MovementZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _MovementZonePayload implements MovementZonePayload {
  const factory _MovementZonePayload(
      {final MovementMode requiredMode,
      final List<MovementMode> allowedModes}) = _$MovementZonePayloadImpl;

  factory _MovementZonePayload.fromJson(Map<String, dynamic> json) =
      _$MovementZonePayloadImpl.fromJson;

  /// Mode de déplacement requis pour traverser la zone.
  @override
  MovementMode get requiredMode;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  @override
  List<MovementMode> get allowedModes;

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MovementZonePayloadImplCopyWith<_$MovementZonePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MovementEffectZonePayload _$MovementEffectZonePayloadFromJson(
    Map<String, dynamic> json) {
  return _MovementEffectZonePayload.fromJson(json);
}

/// @nodoc
mixin _$MovementEffectZonePayload {
  MovementEffectZoneKind get effectKind => throw _privateConstructorUsedError;

  /// Coût entier positif pour [MovementEffectZoneKind.movementCost].
  ///
  /// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
  /// pour garder un JSON stable, mais elle n'est pas consommée.
  int get movementCost => throw _privateConstructorUsedError;

  /// Serializes this MovementEffectZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MovementEffectZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MovementEffectZonePayloadCopyWith<MovementEffectZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MovementEffectZonePayloadCopyWith<$Res> {
  factory $MovementEffectZonePayloadCopyWith(MovementEffectZonePayload value,
          $Res Function(MovementEffectZonePayload) then) =
      _$MovementEffectZonePayloadCopyWithImpl<$Res, MovementEffectZonePayload>;
  @useResult
  $Res call({MovementEffectZoneKind effectKind, int movementCost});
}

/// @nodoc
class _$MovementEffectZonePayloadCopyWithImpl<$Res,
        $Val extends MovementEffectZonePayload>
    implements $MovementEffectZonePayloadCopyWith<$Res> {
  _$MovementEffectZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MovementEffectZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? effectKind = null,
    Object? movementCost = null,
  }) {
    return _then(_value.copyWith(
      effectKind: null == effectKind
          ? _value.effectKind
          : effectKind // ignore: cast_nullable_to_non_nullable
              as MovementEffectZoneKind,
      movementCost: null == movementCost
          ? _value.movementCost
          : movementCost // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MovementEffectZonePayloadImplCopyWith<$Res>
    implements $MovementEffectZonePayloadCopyWith<$Res> {
  factory _$$MovementEffectZonePayloadImplCopyWith(
          _$MovementEffectZonePayloadImpl value,
          $Res Function(_$MovementEffectZonePayloadImpl) then) =
      __$$MovementEffectZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MovementEffectZoneKind effectKind, int movementCost});
}

/// @nodoc
class __$$MovementEffectZonePayloadImplCopyWithImpl<$Res>
    extends _$MovementEffectZonePayloadCopyWithImpl<$Res,
        _$MovementEffectZonePayloadImpl>
    implements _$$MovementEffectZonePayloadImplCopyWith<$Res> {
  __$$MovementEffectZonePayloadImplCopyWithImpl(
      _$MovementEffectZonePayloadImpl _value,
      $Res Function(_$MovementEffectZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of MovementEffectZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? effectKind = null,
    Object? movementCost = null,
  }) {
    return _then(_$MovementEffectZonePayloadImpl(
      effectKind: null == effectKind
          ? _value.effectKind
          : effectKind // ignore: cast_nullable_to_non_nullable
              as MovementEffectZoneKind,
      movementCost: null == movementCost
          ? _value.movementCost
          : movementCost // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MovementEffectZonePayloadImpl implements _MovementEffectZonePayload {
  const _$MovementEffectZonePayloadImpl(
      {this.effectKind = MovementEffectZoneKind.slide, this.movementCost = 1});

  factory _$MovementEffectZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MovementEffectZonePayloadImplFromJson(json);

  @override
  @JsonKey()
  final MovementEffectZoneKind effectKind;

  /// Coût entier positif pour [MovementEffectZoneKind.movementCost].
  ///
  /// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
  /// pour garder un JSON stable, mais elle n'est pas consommée.
  @override
  @JsonKey()
  final int movementCost;

  @override
  String toString() {
    return 'MovementEffectZonePayload(effectKind: $effectKind, movementCost: $movementCost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MovementEffectZonePayloadImpl &&
            (identical(other.effectKind, effectKind) ||
                other.effectKind == effectKind) &&
            (identical(other.movementCost, movementCost) ||
                other.movementCost == movementCost));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, effectKind, movementCost);

  /// Create a copy of MovementEffectZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MovementEffectZonePayloadImplCopyWith<_$MovementEffectZonePayloadImpl>
      get copyWith => __$$MovementEffectZonePayloadImplCopyWithImpl<
          _$MovementEffectZonePayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MovementEffectZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _MovementEffectZonePayload implements MovementEffectZonePayload {
  const factory _MovementEffectZonePayload(
      {final MovementEffectZoneKind effectKind,
      final int movementCost}) = _$MovementEffectZonePayloadImpl;

  factory _MovementEffectZonePayload.fromJson(Map<String, dynamic> json) =
      _$MovementEffectZonePayloadImpl.fromJson;

  @override
  MovementEffectZoneKind get effectKind;

  /// Coût entier positif pour [MovementEffectZoneKind.movementCost].
  ///
  /// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
  /// pour garder un JSON stable, mais elle n'est pas consommée.
  @override
  int get movementCost;

  /// Create a copy of MovementEffectZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MovementEffectZonePayloadImplCopyWith<_$MovementEffectZonePayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

HazardZonePayload _$HazardZonePayloadFromJson(Map<String, dynamic> json) {
  return _HazardZonePayload.fromJson(json);
}

/// @nodoc
mixin _$HazardZonePayload {
  HazardKind get hazardKind => throw _privateConstructorUsedError;

  /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
  int get damagePerStep => throw _privateConstructorUsedError;

  /// Serializes this HazardZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HazardZonePayloadCopyWith<HazardZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HazardZonePayloadCopyWith<$Res> {
  factory $HazardZonePayloadCopyWith(
          HazardZonePayload value, $Res Function(HazardZonePayload) then) =
      _$HazardZonePayloadCopyWithImpl<$Res, HazardZonePayload>;
  @useResult
  $Res call({HazardKind hazardKind, int damagePerStep});
}

/// @nodoc
class _$HazardZonePayloadCopyWithImpl<$Res, $Val extends HazardZonePayload>
    implements $HazardZonePayloadCopyWith<$Res> {
  _$HazardZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hazardKind = null,
    Object? damagePerStep = null,
  }) {
    return _then(_value.copyWith(
      hazardKind: null == hazardKind
          ? _value.hazardKind
          : hazardKind // ignore: cast_nullable_to_non_nullable
              as HazardKind,
      damagePerStep: null == damagePerStep
          ? _value.damagePerStep
          : damagePerStep // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HazardZonePayloadImplCopyWith<$Res>
    implements $HazardZonePayloadCopyWith<$Res> {
  factory _$$HazardZonePayloadImplCopyWith(_$HazardZonePayloadImpl value,
          $Res Function(_$HazardZonePayloadImpl) then) =
      __$$HazardZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({HazardKind hazardKind, int damagePerStep});
}

/// @nodoc
class __$$HazardZonePayloadImplCopyWithImpl<$Res>
    extends _$HazardZonePayloadCopyWithImpl<$Res, _$HazardZonePayloadImpl>
    implements _$$HazardZonePayloadImplCopyWith<$Res> {
  __$$HazardZonePayloadImplCopyWithImpl(_$HazardZonePayloadImpl _value,
      $Res Function(_$HazardZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hazardKind = null,
    Object? damagePerStep = null,
  }) {
    return _then(_$HazardZonePayloadImpl(
      hazardKind: null == hazardKind
          ? _value.hazardKind
          : hazardKind // ignore: cast_nullable_to_non_nullable
              as HazardKind,
      damagePerStep: null == damagePerStep
          ? _value.damagePerStep
          : damagePerStep // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$HazardZonePayloadImpl implements _HazardZonePayload {
  const _$HazardZonePayloadImpl(
      {this.hazardKind = HazardKind.other, this.damagePerStep = 0});

  factory _$HazardZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$HazardZonePayloadImplFromJson(json);

  @override
  @JsonKey()
  final HazardKind hazardKind;

  /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
  @override
  @JsonKey()
  final int damagePerStep;

  @override
  String toString() {
    return 'HazardZonePayload(hazardKind: $hazardKind, damagePerStep: $damagePerStep)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HazardZonePayloadImpl &&
            (identical(other.hazardKind, hazardKind) ||
                other.hazardKind == hazardKind) &&
            (identical(other.damagePerStep, damagePerStep) ||
                other.damagePerStep == damagePerStep));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hazardKind, damagePerStep);

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HazardZonePayloadImplCopyWith<_$HazardZonePayloadImpl> get copyWith =>
      __$$HazardZonePayloadImplCopyWithImpl<_$HazardZonePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HazardZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _HazardZonePayload implements HazardZonePayload {
  const factory _HazardZonePayload(
      {final HazardKind hazardKind,
      final int damagePerStep}) = _$HazardZonePayloadImpl;

  factory _HazardZonePayload.fromJson(Map<String, dynamic> json) =
      _$HazardZonePayloadImpl.fromJson;

  @override
  HazardKind get hazardKind;

  /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
  @override
  int get damagePerStep;

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HazardZonePayloadImplCopyWith<_$HazardZonePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpecialZonePayload _$SpecialZonePayloadFromJson(Map<String, dynamic> json) {
  return _SpecialZonePayload.fromJson(json);
}

/// @nodoc
mixin _$SpecialZonePayload {
  /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
  String? get scriptKey => throw _privateConstructorUsedError;

  /// Propriétés libres (clé → valeur).
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this SpecialZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpecialZonePayloadCopyWith<SpecialZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpecialZonePayloadCopyWith<$Res> {
  factory $SpecialZonePayloadCopyWith(
          SpecialZonePayload value, $Res Function(SpecialZonePayload) then) =
      _$SpecialZonePayloadCopyWithImpl<$Res, SpecialZonePayload>;
  @useResult
  $Res call({String? scriptKey, Map<String, String> properties});
}

/// @nodoc
class _$SpecialZonePayloadCopyWithImpl<$Res, $Val extends SpecialZonePayload>
    implements $SpecialZonePayloadCopyWith<$Res> {
  _$SpecialZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scriptKey = freezed,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      scriptKey: freezed == scriptKey
          ? _value.scriptKey
          : scriptKey // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpecialZonePayloadImplCopyWith<$Res>
    implements $SpecialZonePayloadCopyWith<$Res> {
  factory _$$SpecialZonePayloadImplCopyWith(_$SpecialZonePayloadImpl value,
          $Res Function(_$SpecialZonePayloadImpl) then) =
      __$$SpecialZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? scriptKey, Map<String, String> properties});
}

/// @nodoc
class __$$SpecialZonePayloadImplCopyWithImpl<$Res>
    extends _$SpecialZonePayloadCopyWithImpl<$Res, _$SpecialZonePayloadImpl>
    implements _$$SpecialZonePayloadImplCopyWith<$Res> {
  __$$SpecialZonePayloadImplCopyWithImpl(_$SpecialZonePayloadImpl _value,
      $Res Function(_$SpecialZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scriptKey = freezed,
    Object? properties = null,
  }) {
    return _then(_$SpecialZonePayloadImpl(
      scriptKey: freezed == scriptKey
          ? _value.scriptKey
          : scriptKey // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SpecialZonePayloadImpl implements _SpecialZonePayload {
  const _$SpecialZonePayloadImpl(
      {this.scriptKey, final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$SpecialZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpecialZonePayloadImplFromJson(json);

  /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
  @override
  final String? scriptKey;

  /// Propriétés libres (clé → valeur).
  final Map<String, String> _properties;

  /// Propriétés libres (clé → valeur).
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'SpecialZonePayload(scriptKey: $scriptKey, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpecialZonePayloadImpl &&
            (identical(other.scriptKey, scriptKey) ||
                other.scriptKey == scriptKey) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, scriptKey, const DeepCollectionEquality().hash(_properties));

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpecialZonePayloadImplCopyWith<_$SpecialZonePayloadImpl> get copyWith =>
      __$$SpecialZonePayloadImplCopyWithImpl<_$SpecialZonePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpecialZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _SpecialZonePayload implements SpecialZonePayload {
  const factory _SpecialZonePayload(
      {final String? scriptKey,
      final Map<String, String> properties}) = _$SpecialZonePayloadImpl;

  factory _SpecialZonePayload.fromJson(Map<String, dynamic> json) =
      _$SpecialZonePayloadImpl.fromJson;

  /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
  @override
  String? get scriptKey;

  /// Propriétés libres (clé → valeur).
  @override
  Map<String, String> get properties;

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpecialZonePayloadImplCopyWith<_$SpecialZonePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

````

### packages/map_core/lib/src/models/map_gameplay_zone_payloads.g.dart

````dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EncounterZonePayloadImpl _$$EncounterZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$EncounterZonePayloadImpl(
      encounterTableId: json['encounterTableId'] as String?,
      encounterKind:
          $enumDecodeNullable(_$EncounterKindEnumMap, json['encounterKind']) ??
              EncounterKind.walk,
      battleBackgroundRelativePath:
          json['battleBackgroundRelativePath'] as String?,
    );

Map<String, dynamic> _$$EncounterZonePayloadImplToJson(
        _$EncounterZonePayloadImpl instance) =>
    <String, dynamic>{
      'encounterTableId': instance.encounterTableId,
      'encounterKind': _$EncounterKindEnumMap[instance.encounterKind]!,
      'battleBackgroundRelativePath': instance.battleBackgroundRelativePath,
    };

const _$EncounterKindEnumMap = {
  EncounterKind.walk: 'walk',
  EncounterKind.surf: 'surf',
  EncounterKind.headbutt: 'headbutt',
  EncounterKind.oldRod: 'old_rod',
  EncounterKind.goodRod: 'good_rod',
  EncounterKind.superRod: 'super_rod',
  EncounterKind.gift: 'gift',
  EncounterKind.special: 'special',
};

_$MovementZonePayloadImpl _$$MovementZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$MovementZonePayloadImpl(
      requiredMode:
          $enumDecodeNullable(_$MovementModeEnumMap, json['requiredMode']) ??
              MovementMode.walk,
      allowedModes: (json['allowedModes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MovementModeEnumMap, e))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MovementZonePayloadImplToJson(
        _$MovementZonePayloadImpl instance) =>
    <String, dynamic>{
      'requiredMode': _$MovementModeEnumMap[instance.requiredMode]!,
      'allowedModes':
          instance.allowedModes.map((e) => _$MovementModeEnumMap[e]!).toList(),
    };

const _$MovementModeEnumMap = {
  MovementMode.walk: 'walk',
  MovementMode.surf: 'surf',
  MovementMode.fly: 'fly',
  MovementMode.cut: 'cut',
  MovementMode.strength: 'strength',
  MovementMode.rockSmash: 'rock_smash',
};

_$MovementEffectZonePayloadImpl _$$MovementEffectZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$MovementEffectZonePayloadImpl(
      effectKind: $enumDecodeNullable(
              _$MovementEffectZoneKindEnumMap, json['effectKind']) ??
          MovementEffectZoneKind.slide,
      movementCost: (json['movementCost'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$MovementEffectZonePayloadImplToJson(
        _$MovementEffectZonePayloadImpl instance) =>
    <String, dynamic>{
      'effectKind': _$MovementEffectZoneKindEnumMap[instance.effectKind]!,
      'movementCost': instance.movementCost,
    };

const _$MovementEffectZoneKindEnumMap = {
  MovementEffectZoneKind.slide: 'slide',
  MovementEffectZoneKind.movementCost: 'movementCost',
};

_$HazardZonePayloadImpl _$$HazardZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$HazardZonePayloadImpl(
      hazardKind:
          $enumDecodeNullable(_$HazardKindEnumMap, json['hazardKind']) ??
              HazardKind.other,
      damagePerStep: (json['damagePerStep'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$HazardZonePayloadImplToJson(
        _$HazardZonePayloadImpl instance) =>
    <String, dynamic>{
      'hazardKind': _$HazardKindEnumMap[instance.hazardKind]!,
      'damagePerStep': instance.damagePerStep,
    };

const _$HazardKindEnumMap = {
  HazardKind.lava: 'lava',
  HazardKind.poison: 'poison',
  HazardKind.swamp: 'swamp',
  HazardKind.pitfall: 'pitfall',
  HazardKind.other: 'other',
};

_$SpecialZonePayloadImpl _$$SpecialZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$SpecialZonePayloadImpl(
      scriptKey: json['scriptKey'] as String?,
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SpecialZonePayloadImplToJson(
        _$SpecialZonePayloadImpl instance) =>
    <String, dynamic>{
      'scriptKey': instance.scriptKey,
      'properties': instance.properties,
    };

````

### packages/map_core/lib/src/operations/map_gameplay_zones.dart

````dart
import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_gameplay_zone_payloads.dart';

// ---------------------------------------------------------------------------
// Lookup
// ---------------------------------------------------------------------------

MapGameplayZone? findGameplayZoneById(
  MapData map,
  String zoneId,
) {
  final normalized = zoneId.trim();
  if (normalized.isEmpty) return null;
  for (final zone in map.gameplayZones) {
    if (zone.id == normalized) return zone;
  }
  return null;
}

/// Retourne la zone de priorité la plus haute à la position donnée (dernière posée si égalité).
MapGameplayZone? findGameplayZoneAtPos(
  MapData map,
  GridPos pos,
) {
  MapGameplayZone? best;
  for (final zone in map.gameplayZones) {
    if (_containsPos(zone.area, pos)) {
      if (best == null || zone.priority >= best.priority) {
        best = zone;
      }
    }
  }
  return best;
}

/// Retourne toutes les zones couvrant [pos], triées par priorité décroissante.
List<MapGameplayZone> findAllGameplayZonesAtPos(
  MapData map,
  GridPos pos,
) {
  final result = map.gameplayZones
      .where((z) => _containsPos(z.area, pos))
      .toList(growable: false);
  result.sort((a, b) => b.priority.compareTo(a.priority));
  return result;
}

// ---------------------------------------------------------------------------
// Mutations
// ---------------------------------------------------------------------------

MapData addGameplayZoneToMap(
  MapData map, {
  required MapGameplayZone zone,
}) {
  final normalized = _normalizeZone(zone);
  _validateZone(map, normalized,
      duplicateIdLabel: 'Gameplay zone ID already exists');
  return map.copyWith(gameplayZones: [...map.gameplayZones, normalized]);
}

MapData updateGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  String? id,
  String? name,
  GameplayZoneKind? kind,
  MapRect? area,
  int? priority,

  /// Passer `null` pour effacer le payload, `_kUnset` (défaut) pour conserver.
  Object? encounter = _kUnset,
  Object? movement = _kUnset,
  Object? movementEffect = _kUnset,
  Object? hazard = _kUnset,
  Object? special = _kUnset,
}) {
  final index = map.gameplayZones.indexWhere((z) => z.id == zoneId);
  if (index < 0) throw ValidationException('Gameplay zone not found: $zoneId');

  final current = map.gameplayZones[index];
  var draft = current.copyWith(
    id: id?.trim() ?? current.id,
    name: name?.trim() ?? current.name,
    kind: kind ?? current.kind,
    area: area ?? current.area,
    priority: priority ?? current.priority,
  );
  if (!identical(encounter, _kUnset)) {
    draft = draft.copyWith(encounter: encounter as EncounterZonePayload?);
  }
  if (!identical(movement, _kUnset)) {
    draft = draft.copyWith(movement: movement as MovementZonePayload?);
  }
  if (!identical(movementEffect, _kUnset)) {
    draft = draft.copyWith(
        movementEffect: movementEffect as MovementEffectZonePayload?);
  }
  if (!identical(hazard, _kUnset)) {
    draft = draft.copyWith(hazard: hazard as HazardZonePayload?);
  }
  if (!identical(special, _kUnset)) {
    draft = draft.copyWith(special: special as SpecialZonePayload?);
  }

  final next = _normalizeZone(draft);
  _validateZone(
    map,
    next,
    excludedZoneId: current.id,
    duplicateIdLabel: 'Gameplay zone ID already exists',
  );
  final updated =
      List<MapGameplayZone>.from(map.gameplayZones, growable: false);
  updated[index] = next;
  return map.copyWith(gameplayZones: updated);
}

MapData moveGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  required GridPos pos,
}) {
  final zone = findGameplayZoneById(map, zoneId);
  if (zone == null) {
    throw ValidationException('Gameplay zone not found: $zoneId');
  }
  return updateGameplayZoneOnMap(
    map,
    zoneId: zoneId,
    area: zone.area.copyWith(pos: pos),
  );
}

MapData resizeGameplayZoneOnMap(
  MapData map, {
  required String zoneId,
  required GridSize size,
}) {
  final zone = findGameplayZoneById(map, zoneId);
  if (zone == null) {
    throw ValidationException('Gameplay zone not found: $zoneId');
  }
  return updateGameplayZoneOnMap(
    map,
    zoneId: zoneId,
    area: zone.area.copyWith(size: size),
  );
}

MapData removeGameplayZoneFromMap(
  MapData map, {
  required String zoneId,
}) {
  final index = map.gameplayZones.indexWhere((z) => z.id == zoneId);
  if (index < 0) throw ValidationException('Gameplay zone not found: $zoneId');
  final updated = List<MapGameplayZone>.from(map.gameplayZones, growable: true)
    ..removeAt(index);
  return map.copyWith(gameplayZones: updated);
}

// ---------------------------------------------------------------------------
// Helpers internes
// ---------------------------------------------------------------------------

/// Valeur sentinelle pour les paramètres optionnels (distingue null de "non fourni").
const Object _kUnset = Object();

MapGameplayZone _normalizeZone(MapGameplayZone zone) {
  return zone.copyWith(
    id: zone.id.trim(),
    name: zone.name.trim(),
  );
}

void _validateZone(
  MapData map,
  MapGameplayZone zone, {
  String? excludedZoneId,
  required String duplicateIdLabel,
}) {
  final id = zone.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Gameplay zone ID cannot be empty');
  }

  if (map.gameplayZones.any(
    (z) => z.id == id && z.id != excludedZoneId,
  )) {
    throw ValidationException('$duplicateIdLabel: $id');
  }

  final area = zone.area;
  if (area.size.width <= 0 || area.size.height <= 0) {
    throw ValidationException(
      'Gameplay zone $id has invalid area size: (${area.size.width}x${area.size.height})',
    );
  }
  if (area.pos.x < 0 ||
      area.pos.y < 0 ||
      area.pos.x + area.size.width > map.size.width ||
      area.pos.y + area.size.height > map.size.height) {
    throw ValidationException(
      'Gameplay zone $id area is out of map bounds at (${area.pos.x}, ${area.pos.y}) '
      'with size (${area.size.width}x${area.size.height})',
    );
  }
  final specialProps = zone.special?.properties;
  if (specialProps != null) {
    for (final key in specialProps.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
            'Gameplay zone $id has an empty special property key');
      }
    }
  }
  final movementEffect = zone.movementEffect;
  if (zone.kind == GameplayZoneKind.movementEffect && movementEffect == null) {
    throw ValidationException(
      'Gameplay zone $id requires a movement effect payload',
    );
  }
  if (movementEffect != null && movementEffect.movementCost <= 0) {
    throw ValidationException(
      'Gameplay zone $id movement effect movementCost must be positive',
    );
  }
}

bool _containsPos(MapRect rect, GridPos pos) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}

````

### packages/map_core/lib/src/validation/validators.dart

````dart
import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';
import '../operations/map_entities.dart';
import 'dialogue_validation.dart';
import 'entity_editor_visual_validation.dart';

class ProjectValidator {
  // Scenario action/source kinds partagés avec l'éditeur/runtime.
  // On garde ces chaînes localisées ici pour valider de manière
  // déterministe sans dépendre d'un package runtime.
  static const Set<String> _scenarioWorldSourceKinds = <String>{
    'sourceMapEnter',
    'sourceTriggerEnter',
    'sourceEntityInteract',
  };
  static const String _scenarioOutcomeSourceKind = 'sourceOutcome';
  static const String _scenarioEmitOutcomeKind = 'emitOutcome';

  /// Rectangles sources valides, [durationMs] > 0 si présent, au moins une frame,
  /// tailles identiques si plusieurs frames (préparation animation).
  static void _validateVisualFrames(
    List<TilesetVisualFrame> frames, {
    required String context,
    required Set<String> knownTilesetIds,
  }) {
    if (frames.isEmpty) {
      throw ValidationException('$context must have at least one visual frame');
    }
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final src = frame.source;
      if (src.x < 0 || src.y < 0) {
        throw ValidationException(
          '$context frame $i has invalid source coordinates',
        );
      }
      if (src.width <= 0 || src.height <= 0) {
        throw ValidationException('$context frame $i has invalid source size');
      }
      final overrideId = frame.tilesetId.trim();
      if (overrideId.isNotEmpty && !knownTilesetIds.contains(overrideId)) {
        throw ValidationException(
          '$context frame $i references missing tileset: $overrideId',
        );
      }
      final d = frame.durationMs;
      if (d != null && d <= 0) {
        throw ValidationException(
          '$context frame $i durationMs must be positive when set',
        );
      }
    }
    if (frames.length > 1) {
      final w = frames.first.source.width;
      final h = frames.first.source.height;
      for (var i = 1; i < frames.length; i++) {
        final s = frames[i].source;
        if (s.width != w || s.height != h) {
          throw ValidationException(
            '$context animation frames must share the same width and height',
          );
        }
      }
    }
  }

  static void validate(ProjectManifest manifest) {
    _validateUniqueness(manifest);
    _validateHierarchy(manifest);
    _validateEncounterTables(manifest.encounterTables);
    _validateProjectDialogues(manifest);
    _validateTrainers(manifest);
    _validateCharacters(manifest);
    _validateSettings(manifest.settings);
  }

  static void _validateUniqueness(ProjectManifest manifest) {
    _validateUniqueIds(
      manifest.maps,
      (map) => map.id,
      duplicateMessagePrefix: 'Duplicate map ID',
    );
    _validateUniqueIds(
      manifest.groups,
      (group) => group.id,
      duplicateMessagePrefix: 'Duplicate group ID',
    );
    _validateUniqueIds(
      manifest.tilesets,
      (tileset) => tileset.id,
      duplicateMessagePrefix: 'Duplicate tileset ID',
    );
    _validateUniqueIds(
      manifest.tilesetFolders,
      (folder) => folder.id,
      duplicateMessagePrefix: 'Duplicate tileset folder ID',
    );
    _validateUniqueIds(
      manifest.elementCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate element category ID',
    );
    _validateUniqueIds(
      manifest.elements,
      (element) => element.id,
      duplicateMessagePrefix: 'Duplicate element ID',
    );
    _validateUniqueIds(
      manifest.terrainCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate terrain category ID',
    );
    _validateUniqueIds(
      manifest.pathCategories,
      (category) => category.id,
      duplicateMessagePrefix: 'Duplicate path category ID',
    );
    _validateUniqueIds(
      manifest.terrainPresets,
      (preset) => preset.id,
      duplicateMessagePrefix: 'Duplicate terrain preset ID',
    );
    _validateUniqueIds(
      manifest.pathPresets,
      (preset) => preset.id,
      duplicateMessagePrefix: 'Duplicate path preset ID',
    );
    _validateUniqueIds(
      manifest.encounterTables,
      (table) => table.id,
      duplicateMessagePrefix: 'Duplicate encounter table ID',
    );
    _validateUniqueIds(
      manifest.dialogueFolders,
      (f) => f.id,
      duplicateMessagePrefix: 'Duplicate dialogue folder ID',
    );
    _validateUniqueIds(
      manifest.dialogues,
      (d) => d.id,
      duplicateMessagePrefix: 'Duplicate dialogue ID',
    );
    _validateUniqueIds(
      manifest.scenarios,
      (s) => s.id,
      duplicateMessagePrefix: 'Duplicate scenario ID',
    );
    _validateUniqueIds(
      manifest.trainers,
      (t) => t.id,
      duplicateMessagePrefix: 'Duplicate trainer ID',
    );
    _validateUniqueIds(
      manifest.characters,
      (c) => c.id,
      duplicateMessagePrefix: 'Duplicate character ID',
    );
  }

  static void _validateProjectDialogues(ProjectManifest manifest) {
    final dialogueFolderIds = manifest.dialogueFolders.map((f) => f.id).toSet();
    final dialogueRelativePaths = <String>{};
    for (final d in manifest.dialogues) {
      final id = d.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Dialogue entry has an empty id');
      }
      if (d.name.trim().isEmpty) {
        throw ValidationException('Dialogue $id has an empty name');
      }
      assertValidProjectDialogueRelativePath(d.relativePath, dialogueId: id);
      final rpNorm = d.relativePath.replaceAll(r'\', '/');
      if (!dialogueRelativePaths.add(rpNorm)) {
        throw ValidationException(
          'Duplicate dialogue relativePath in manifest: $rpNorm',
        );
      }
      assertValidDialogueStartNode(
        d.defaultStartNode,
        contextLabel: 'Dialogue $id defaultStartNode',
      );
      final df = d.folderId?.trim();
      if (df != null && df.isNotEmpty && !dialogueFolderIds.contains(df)) {
        throw ValidationException(
          'Dialogue $id references unknown dialogue folder: $df',
        );
      }
    }
  }

  static void _validateHierarchy(ProjectManifest manifest) {
    final groupIds = manifest.groups.map((g) => g.id).toSet();

    for (final group in manifest.groups) {
      if (group.parentGroupId != null &&
          !groupIds.contains(group.parentGroupId)) {
        throw ValidationException(
          'Group ${group.id} references non-existent parent: ${group.parentGroupId}',
        );
      }
      if (group.parentGroupId == group.id) {
        throw ValidationException('Group ${group.id} cannot be its own parent');
      }

      var current = group;
      final visited = {group.id};
      while (current.parentGroupId != null) {
        if (!groupIds.contains(current.parentGroupId)) {
          break;
        }
        if (!visited.add(current.parentGroupId!)) {
          throw ValidationException(
            'Cycle detected in group hierarchy at ${group.id}',
          );
        }
        current = manifest.groups
            .firstWhere((candidate) => candidate.id == current.parentGroupId);
      }
    }

    for (final map in manifest.maps) {
      if (map.groupId != null && !groupIds.contains(map.groupId)) {
        throw ValidationException(
          'Map ${map.id} references non-existent group: ${map.groupId}',
        );
      }
      _validateRelativePath(map.relativePath, 'Map ${map.id}');
    }

    _validateTilesetFolders(manifest);
    _validateDialogueFolders(manifest);
    _validateTilesets(manifest, groupIds);
    _validateElementCategories(manifest);
    _validateElements(manifest, groupIds);
    _validatePresetCategories(
      manifest.terrainCategories,
      label: 'terrain category',
    );
    _validatePresetCategories(
      manifest.pathCategories,
      label: 'path category',
    );
    _validateTerrainPresets(manifest);
    _validatePathPresets(manifest);
    _validateScenarios(manifest);
  }

  static void _validateTilesetFolders(ProjectManifest manifest) {
    final folderById = <String, ProjectTilesetFolder>{};
    for (final folder in manifest.tilesetFolders) {
      if (folder.id.trim().isEmpty) {
        throw const ValidationException('Tileset folder ID cannot be empty');
      }
      if (folder.name.trim().isEmpty) {
        throw ValidationException(
          'Tileset folder "${folder.id}" has an empty name',
        );
      }
      folderById[folder.id] = folder;
    }

    for (final folder in manifest.tilesetFolders) {
      final parentId = folder.parentFolderId;
      if (parentId == null) continue;
      if (!folderById.containsKey(parentId)) {
        throw ValidationException(
          'Tileset folder ${folder.id} references missing parent: $parentId',
        );
      }
      if (parentId == folder.id) {
        throw ValidationException(
          'Tileset folder ${folder.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final chain = <String>{};
      while (cursor != null) {
        if (!chain.add(cursor)) {
          throw ValidationException(
            'Cycle detected in tileset folder hierarchy at ${folder.id}',
          );
        }
        cursor = folderById[cursor]?.parentFolderId;
      }
    }

    final folderIds = folderById.keys.toSet();
    for (final tileset in manifest.tilesets) {
      final fid = tileset.folderId?.trim();
      if (fid == null || fid.isEmpty) continue;
      if (!folderIds.contains(fid)) {
        throw ValidationException(
          'Tileset ${tileset.id} references unknown tileset folder: $fid',
        );
      }
    }
  }

  static void _validateDialogueFolders(ProjectManifest manifest) {
    final folderById = <String, ProjectDialogueFolder>{};
    for (final folder in manifest.dialogueFolders) {
      if (folder.id.trim().isEmpty) {
        throw const ValidationException('Dialogue folder ID cannot be empty');
      }
      if (folder.name.trim().isEmpty) {
        throw ValidationException(
          'Dialogue folder "${folder.id}" has an empty name',
        );
      }
      folderById[folder.id] = folder;
    }

    for (final folder in manifest.dialogueFolders) {
      final parentId = folder.parentFolderId;
      if (parentId == null) continue;
      if (!folderById.containsKey(parentId)) {
        throw ValidationException(
          'Dialogue folder ${folder.id} references missing parent: $parentId',
        );
      }
      if (parentId == folder.id) {
        throw ValidationException(
          'Dialogue folder ${folder.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final chain = <String>{};
      while (cursor != null) {
        if (!chain.add(cursor)) {
          throw ValidationException(
            'Cycle detected in dialogue folder hierarchy at ${folder.id}',
          );
        }
        cursor = folderById[cursor]?.parentFolderId;
      }
    }
  }

  static void _validateTilesets(
      ProjectManifest manifest, Set<String> groupIds) {
    var worldTilesetCount = 0;
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{};
    final allTilesetIds = manifest.tilesets.map((t) => t.id).toSet();

    for (final tileset in manifest.tilesets) {
      _validateRelativePath(tileset.relativePath, 'Tileset ${tileset.id}');

      if (tileset.scope == TilesetScope.global) {
        if (tileset.groupId != null) {
          throw ValidationException(
            'Global tileset ${tileset.id} cannot have groupId',
          );
        }
      } else {
        final groupId = tileset.groupId;
        if (groupId == null || !groupIds.contains(groupId)) {
          throw ValidationException(
            'Group-scoped tileset ${tileset.id} must reference an existing group',
          );
        }
      }

      if (tileset.isWorldTileset) {
        worldTilesetCount++;
        if (tileset.scope != TilesetScope.global) {
          throw ValidationException(
              'World tileset ${tileset.id} must be global');
        }
      }

      final elementGroupById = <String, TilesetElementGroup>{};
      for (final group in tileset.elementGroups) {
        if (group.id.trim().isEmpty) {
          throw ValidationException(
            'Tileset ${tileset.id} has an internal group with empty ID',
          );
        }
        if (group.name.trim().isEmpty) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} has an empty name',
          );
        }
        if (elementGroupById.containsKey(group.id)) {
          throw ValidationException(
            'Duplicate internal group ID in tileset ${tileset.id}: ${group.id}',
          );
        }
        elementGroupById[group.id] = group;
      }

      for (final group in tileset.elementGroups) {
        final parentId = group.parentGroupId;
        if (parentId == null) continue;
        if (!elementGroupById.containsKey(parentId)) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} references missing parent: $parentId',
          );
        }
        if (parentId == group.id) {
          throw ValidationException(
            'Tileset ${tileset.id} internal group ${group.id} cannot be its own parent',
          );
        }
        String? cursor = parentId;
        final visited = <String>{group.id};
        while (cursor != null) {
          if (!visited.add(cursor)) {
            throw ValidationException(
              'Cycle detected in tileset ${tileset.id} internal groups at ${group.id}',
            );
          }
          cursor = elementGroupById[cursor]?.parentGroupId;
        }
      }

      tilesetElementGroupIdsByTileset[tileset.id] =
          elementGroupById.keys.toSet();

      final paletteIds = <String>{};
      for (final entry in tileset.paletteEntries) {
        if (entry.id.trim().isEmpty) {
          throw ValidationException(
            'Palette entry in tileset ${tileset.id} has an empty ID',
          );
        }
        if (!paletteIds.add(entry.id)) {
          throw ValidationException(
            'Duplicate palette entry ID in tileset ${tileset.id}: ${entry.id}',
          );
        }
        _validateVisualFrames(
          entry.frames,
          context: 'Palette entry ${entry.id} in tileset ${tileset.id}',
          knownTilesetIds: allTilesetIds,
        );
      }
    }

    if (worldTilesetCount > 1) {
      throw const ValidationException('Only one world tileset can be defined');
    }
  }

  static void _validateElementCategories(ProjectManifest manifest) {
    final categoryById = <String, ProjectElementCategory>{};
    for (final category in manifest.elementCategories) {
      if (category.id.trim().isEmpty) {
        throw const ValidationException('Element category ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
          'Element category ${category.id} has an empty name',
        );
      }
      categoryById[category.id] = category;
    }

    for (final category in manifest.elementCategories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!categoryById.containsKey(parentId)) {
        throw ValidationException(
          'Element category ${category.id} references missing parent: $parentId',
        );
      }
      if (parentId == category.id) {
        throw ValidationException(
          'Element category ${category.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
            'Cycle detected in element categories at ${category.id}',
          );
        }
        cursor = categoryById[cursor]?.parentCategoryId;
      }
    }
  }

  static void _validateElements(
      ProjectManifest manifest, Set<String> groupIds) {
    final tilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    final tilesetElementGroupIdsByTileset = <String, Set<String>>{
      for (final tileset in manifest.tilesets)
        tileset.id: tileset.elementGroups.map((group) => group.id).toSet(),
    };
    final categoryIds = manifest.elementCategories.map((e) => e.id).toSet();

    for (final element in manifest.elements) {
      if (element.id.trim().isEmpty) {
        throw const ValidationException('Element ID cannot be empty');
      }
      if (element.name.trim().isEmpty) {
        throw ValidationException('Element ${element.id} has an empty name');
      }
      if (!tilesetIds.contains(element.tilesetId)) {
        throw ValidationException(
          'Element ${element.id} references missing tileset: ${element.tilesetId}',
        );
      }
      if (!categoryIds.contains(element.categoryId)) {
        throw ValidationException(
          'Element ${element.id} references missing category: ${element.categoryId}',
        );
      }
      if (element.groupId != null && !groupIds.contains(element.groupId)) {
        throw ValidationException(
          'Element ${element.id} references missing group: ${element.groupId}',
        );
      }
      if (element.tilesetGroupId != null &&
          element.tilesetGroupId!.trim().isEmpty) {
        throw ValidationException(
          'Element ${element.id} has an empty tilesetGroupId',
        );
      }
      if (element.tilesetGroupId != null) {
        final tilesetGroups =
            tilesetElementGroupIdsByTileset[element.tilesetId] ?? const {};
        if (!tilesetGroups.contains(element.tilesetGroupId)) {
          throw ValidationException(
            'Element ${element.id} references missing tileset group ${element.tilesetGroupId} in tileset ${element.tilesetId}',
          );
        }
      }
      _validateVisualFrames(
        element.frames,
        context: 'Element ${element.id}',
        knownTilesetIds: tilesetIds,
      );
      _validateElementCollisionProfile(element);
    }
  }

  static void _validateElementCollisionProfile(ProjectElementEntry element) {
    final profile = element.collisionProfile;
    if (profile == null) {
      return;
    }
    final padding = profile.padding;
    if (padding.top < 0 ||
        padding.right < 0 ||
        padding.bottom < 0 ||
        padding.left < 0) {
      throw ValidationException(
        'Element ${element.id} collision profile contains negative padding values',
      );
    }
    final source = element.frames.primarySource;
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.shapeCells,
      label: 'shape',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.cells,
      label: 'final',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.manualAddedCells,
      label: 'manualAdded',
    );
    _validateCollisionCellsList(
      elementId: element.id,
      source: source,
      cells: profile.manualRemovedCells,
      label: 'manualRemoved',
    );
  }

  static void _validateCollisionCellsList({
    required String elementId,
    required TilesetSourceRect source,
    required List<GridPos> cells,
    required String label,
  }) {
    final seen = <String>{};
    for (final cell in cells) {
      if (cell.x < 0 || cell.y < 0) {
        throw ValidationException(
          'Element $elementId collision profile contains negative $label cell coordinates',
        );
      }
      if (cell.x >= source.width || cell.y >= source.height) {
        throw ValidationException(
          'Element $elementId $label collision cell (${cell.x}, ${cell.y}) is outside source bounds ${source.width}x${source.height}',
        );
      }
      final key = '${cell.x}:${cell.y}';
      if (!seen.add(key)) {
        throw ValidationException(
          'Element $elementId collision profile contains duplicate $label cell ($key)',
        );
      }
    }
  }

  static void _validatePresetCategories(
    List<ProjectPresetCategory> categories, {
    required String label,
  }) {
    final byId = <String, ProjectPresetCategory>{};
    for (final category in categories) {
      if (category.id.trim().isEmpty) {
        throw ValidationException('${_capitalize(label)} ID cannot be empty');
      }
      if (category.name.trim().isEmpty) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} has an empty name',
        );
      }
      byId[category.id] = category;
    }

    for (final category in categories) {
      final parentId = category.parentCategoryId;
      if (parentId == null) continue;
      if (!byId.containsKey(parentId)) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} references missing parent: $parentId',
        );
      }
      if (parentId == category.id) {
        throw ValidationException(
          '${_capitalize(label)} ${category.id} cannot be its own parent',
        );
      }
      String? cursor = parentId;
      final visited = <String>{category.id};
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw ValidationException(
            'Cycle detected in ${label}s at ${category.id}',
          );
        }
        cursor = byId[cursor]?.parentCategoryId;
      }
    }
  }

  static void _validateTerrainPresets(ProjectManifest manifest) {
    final tilesetIds = manifest.tilesets.map((tileset) => tileset.id).toSet();
    final categoryIds =
        manifest.terrainCategories.map((category) => category.id).toSet();

    for (final preset in manifest.terrainPresets) {
      if (preset.id.trim().isEmpty) {
        throw const ValidationException('Terrain preset ID cannot be empty');
      }
      if (preset.name.trim().isEmpty) {
        throw ValidationException(
          'Terrain preset ${preset.id} has an empty name',
        );
      }
      if (preset.terrainType == TerrainType.none) {
        throw ValidationException(
          'Terrain preset ${preset.id} cannot target terrain type "none"',
        );
      }
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && !tilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Terrain preset ${preset.id} references missing tileset: $tilesetId',
        );
      }
      final categoryId = preset.categoryId?.trim();
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !categoryIds.contains(categoryId)) {
        throw ValidationException(
          'Terrain preset ${preset.id} references missing terrain category: $categoryId',
        );
      }
      for (var vi = 0; vi < preset.variants.length; vi++) {
        final variant = preset.variants[vi];
        if (variant.weight <= 0) {
          throw ValidationException(
            'Terrain preset ${preset.id} has an invalid variant weight',
          );
        }
        _validateVisualFrames(
          variant.frames,
          context: 'Terrain preset ${preset.id} variant index $vi',
          knownTilesetIds: tilesetIds,
        );
      }
    }
  }

  static void _validatePathPresets(ProjectManifest manifest) {
    final tilesetIds = manifest.tilesets.map((tileset) => tileset.id).toSet();
    final categoryIds =
        manifest.pathCategories.map((category) => category.id).toSet();

    for (final preset in manifest.pathPresets) {
      if (preset.id.trim().isEmpty) {
        throw const ValidationException('Path preset ID cannot be empty');
      }
      if (preset.name.trim().isEmpty) {
        throw ValidationException('Path preset ${preset.id} has an empty name');
      }
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && !tilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Path preset ${preset.id} references missing tileset: $tilesetId',
        );
      }
      final categoryId = preset.categoryId?.trim();
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          !categoryIds.contains(categoryId)) {
        throw ValidationException(
          'Path preset ${preset.id} references missing path category: $categoryId',
        );
      }
      final variants = <TerrainPathVariant>{};
      for (final mapping in preset.variants) {
        if (!variants.add(mapping.variant)) {
          throw ValidationException(
            'Path preset ${preset.id} has duplicate variant mapping: ${mapping.variant.name}',
          );
        }
        _validateVisualFrames(
          mapping.frames,
          context: 'Path preset ${preset.id} variant ${mapping.variant.name}',
          knownTilesetIds: tilesetIds,
        );
      }
    }

    final terrainTilesetIds = manifest.terrainPresets
        .map((preset) => preset.tilesetId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    for (final preset in manifest.pathPresets) {
      final tilesetId = preset.tilesetId.trim();
      if (tilesetId.isNotEmpty && terrainTilesetIds.contains(tilesetId)) {
        throw ValidationException(
          'Tileset $tilesetId cannot be shared between terrain and path presets',
        );
      }
    }
  }

  static void _validateScenarios(ProjectManifest manifest) {
    final knownScriptIds = manifest.scripts.map((script) => script.id).toSet();
    final knownDialogueIds =
        manifest.dialogues.map((dialogue) => dialogue.id).toSet();
    final knownMapIds = manifest.maps.map((map) => map.id).toSet();
    final knownTrainerIds =
        manifest.trainers.map((trainer) => trainer.id).toSet();

    for (final scenario in manifest.scenarios) {
      final scenarioId = _requireProjectNonBlank(
        scenario.id,
        'Scenario ID cannot be empty',
      );
      _requireProjectNonBlank(
          scenario.name, 'Scenario $scenarioId has an empty name');

      // Outcomes déclarés: non vides et sans doublons.
      final declaredOutcomeIds = <String>{};
      for (final rawOutcomeId in scenario.declaredOutcomes) {
        final outcomeId = _requireProjectNonBlank(
          rawOutcomeId,
          'Scenario $scenarioId has an empty declared outcome',
        );
        if (!declaredOutcomeIds.add(outcomeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate declared outcome: $outcomeId',
          );
        }
      }

      // Condition d'activation scénario (gating global/local).
      if (scenario.activationCondition != null) {
        _validateScriptCondition(
          scenario.activationCondition!,
          contextLabel: 'Scenario $scenarioId activationCondition',
        );
      }

      if (scenario.nodes.isEmpty) {
        throw ValidationException('Scenario $scenarioId must contain nodes');
      }
      final nodeIds = <String>{};
      var startNodesCount = 0;
      for (final node in scenario.nodes) {
        final nodeId = _requireProjectNonBlank(
          node.id,
          'Scenario $scenarioId has a node with empty id',
        );
        if (!nodeIds.add(nodeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate node id: $nodeId',
          );
        }
        if (node.type == ScenarioNodeType.start) {
          startNodesCount++;
        }

        final actionKind = node.payload.actionKind?.trim() ?? '';
        final outcomeId = node.binding.outcomeId?.trim() ?? '';

        if (actionKind == _scenarioEmitOutcomeKind ||
            actionKind == _scenarioOutcomeSourceKind) {
          if (outcomeId.isEmpty) {
            throw ValidationException(
              'Scenario $scenarioId node $nodeId kind "$actionKind" requires outcomeId',
            );
          }
        }
        if (scenario.scope == ScenarioScope.globalStory &&
            _scenarioWorldSourceKinds.contains(actionKind)) {
          throw ValidationException(
            'Scenario $scenarioId is globalStory and cannot use world source kind: $actionKind',
          );
        }
        if (scenario.scope == ScenarioScope.localEventFlow &&
            actionKind == _scenarioOutcomeSourceKind) {
          throw ValidationException(
            'Scenario $scenarioId is localEventFlow and cannot use sourceOutcome',
          );
        }

        final binding = node.binding;
        final scriptId = binding.scriptId?.trim();
        if (scriptId != null &&
            scriptId.isNotEmpty &&
            !knownScriptIds.contains(scriptId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown script: $scriptId',
          );
        }
        final dialogueId = binding.dialogueId?.trim();
        if (dialogueId != null &&
            dialogueId.isNotEmpty &&
            !knownDialogueIds.contains(dialogueId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown dialogue: $dialogueId',
          );
        }
        final mapId = binding.mapId?.trim();
        if (mapId != null && mapId.isNotEmpty && !knownMapIds.contains(mapId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown map: $mapId',
          );
        }
        final trainerId = binding.trainerId?.trim();
        if (trainerId != null &&
            trainerId.isNotEmpty &&
            !knownTrainerIds.contains(trainerId)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId references unknown trainer: $trainerId',
          );
        }
        final eventId = binding.eventId?.trim();
        if (eventId != null &&
            eventId.isNotEmpty &&
            (mapId == null || mapId.isEmpty)) {
          throw ValidationException(
            'Scenario $scenarioId node $nodeId cannot define eventId without mapId',
          );
        }
        final condition = node.payload.condition;
        if (condition != null) {
          _validateScriptCondition(
            condition,
            contextLabel: 'Scenario $scenarioId node $nodeId condition',
          );
        }
      }
      if (startNodesCount != 1) {
        throw ValidationException(
          'Scenario $scenarioId must contain exactly one start node',
        );
      }
      final entryNodeId = _requireProjectNonBlank(
        scenario.entryNodeId,
        'Scenario $scenarioId has an empty entryNodeId',
      );
      if (!nodeIds.contains(entryNodeId)) {
        throw ValidationException(
          'Scenario $scenarioId entryNodeId references missing node: $entryNodeId',
        );
      }

      final edgeIds = <String>{};
      final outgoingByNode = <String, int>{};
      for (final edge in scenario.edges) {
        final edgeId = _requireProjectNonBlank(
          edge.id,
          'Scenario $scenarioId has an edge with empty id',
        );
        if (!edgeIds.add(edgeId)) {
          throw ValidationException(
            'Scenario $scenarioId has duplicate edge id: $edgeId',
          );
        }
        final fromNodeId = _requireProjectNonBlank(
          edge.fromNodeId,
          'Scenario $scenarioId edge $edgeId has empty fromNodeId',
        );
        final toNodeId = _requireProjectNonBlank(
          edge.toNodeId,
          'Scenario $scenarioId edge $edgeId has empty toNodeId',
        );
        if (!nodeIds.contains(fromNodeId)) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId references missing fromNodeId: $fromNodeId',
          );
        }
        if (!nodeIds.contains(toNodeId)) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId references missing toNodeId: $toNodeId',
          );
        }
        if (fromNodeId == toNodeId) {
          throw ValidationException(
            'Scenario $scenarioId edge $edgeId cannot target the same node',
          );
        }
        outgoingByNode[fromNodeId] = (outgoingByNode[fromNodeId] ?? 0) + 1;
      }

      final nodeById = <String, ScenarioNode>{
        for (final node in scenario.nodes) node.id: node,
      };
      for (final entry in nodeById.entries) {
        final node = entry.value;
        final outgoing = outgoingByNode[node.id] ?? 0;
        if (node.type == ScenarioNodeType.choice && outgoing < 2) {
          throw ValidationException(
            'Scenario $scenarioId choice node ${node.id} must have at least two outgoing edges',
          );
        }
        if (node.type == ScenarioNodeType.condition && outgoing < 2) {
          throw ValidationException(
            'Scenario $scenarioId condition node ${node.id} must have at least two outgoing edges',
          );
        }
        if (node.type == ScenarioNodeType.end && outgoing > 0) {
          throw ValidationException(
            'Scenario $scenarioId end node ${node.id} cannot have outgoing edges',
          );
        }
      }
    }
  }

  static void _validateScriptCondition(
    ScriptCondition condition, {
    required String contextLabel,
  }) {
    for (final key in condition.params.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('$contextLabel has an empty param key');
      }
    }
    switch (condition.type) {
      case ScriptConditionType.allOf:
      case ScriptConditionType.anyOf:
        if (condition.children.isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires at least one child',
          );
        }
        for (var i = 0; i < condition.children.length; i++) {
          _validateScriptCondition(
            condition.children[i],
            contextLabel: '$contextLabel.children[$i]',
          );
        }
        return;
      case ScriptConditionType.not:
        if (condition.children.length != 1) {
          throw ValidationException(
            '$contextLabel not requires exactly one child',
          );
        }
        _validateScriptCondition(
          condition.children.first,
          contextLabel: '$contextLabel.children[0]',
        );
        return;
      case ScriptConditionType.flagIsSet:
      case ScriptConditionType.flagIsUnset:
        final flagName = condition.params[ScriptConditionParams.flagName];
        if (flagName == null || flagName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty flagName',
          );
        }
        return;
      case ScriptConditionType.eventIsConsumed:
        final eventId = condition.params[ScriptConditionParams.eventId];
        if (eventId == null || eventId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel eventIsConsumed requires a non-empty eventId',
          );
        }
        return;
      case ScriptConditionType.playerOnMap:
        final mapId = condition.params[ScriptConditionParams.mapId];
        if (mapId == null || mapId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel playerOnMap requires a non-empty mapId',
          );
        }
        return;
      case ScriptConditionType.variableEquals:
      case ScriptConditionType.variableGreaterThan:
      case ScriptConditionType.variableLessThan:
        final variableName =
            condition.params[ScriptConditionParams.variableName];
        final value = condition.params[ScriptConditionParams.value];
        if (variableName == null || variableName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty variableName',
          );
        }
        if (value == null || value.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty value',
          );
        }
        return;
      case ScriptConditionType.fieldAbilityUnlocked:
        final ability = condition.params[ScriptConditionParams.ability];
        if (ability == null || ability.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel fieldAbilityUnlocked requires a non-empty ability',
          );
        }
        return;
      case ScriptConditionType.partyHasMove:
      case ScriptConditionType.partyHasUsableMove:
        final moveId = condition.params[ScriptConditionParams.moveId];
        if (moveId == null || moveId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty moveId',
          );
        }
        return;
    }
  }

  static String _requireProjectNonBlank(String value, String message) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException(message);
    }
    return trimmed;
  }

  static void _validateRelativePath(String path, String label) {
    final value = path.trim();
    if (value.isEmpty) {
      throw ValidationException('$label has an empty relativePath');
    }
    if (value.startsWith('/') || value.startsWith('\\')) {
      throw ValidationException('$label relativePath must be relative');
    }
    if (value.contains(':\\') || value.contains(':/')) {
      throw ValidationException('$label relativePath must not be absolute');
    }
    if (value.contains('..')) {
      throw ValidationException('$label relativePath must not escape project');
    }
  }

  static void _validateEncounterTables(List<ProjectEncounterTable> tables) {
    for (final table in tables) {
      final id = table.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Encounter table ID cannot be empty');
      }
      if (table.name.trim().isEmpty) {
        throw ValidationException('Encounter table $id name cannot be empty');
      }
      for (var i = 0; i < table.entries.length; i++) {
        final entry = table.entries[i];
        if (entry.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Encounter table $id entry $i has empty speciesId',
          );
        }
        if (entry.minLevel <= 0 || entry.maxLevel <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i levels must be positive',
          );
        }
        if (entry.minLevel > entry.maxLevel) {
          throw ValidationException(
            'Encounter table $id entry $i minLevel (${entry.minLevel}) > maxLevel (${entry.maxLevel})',
          );
        }
        if (entry.weight <= 0) {
          throw ValidationException(
            'Encounter table $id entry $i weight must be positive (got ${entry.weight})',
          );
        }
      }
    }
  }

  static void _validateTrainers(ProjectManifest manifest) {
    final elementIds = manifest.elements.map((e) => e.id).toSet();
    final characterIds = manifest.characters.map((c) => c.id).toSet();
    for (final trainer in manifest.trainers) {
      final id = trainer.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Trainer ID cannot be empty');
      }
      if (trainer.name.trim().isEmpty) {
        throw ValidationException('Trainer $id has an empty name');
      }
      if (trainer.trainerClass.trim().isEmpty) {
        throw ValidationException('Trainer $id has an empty trainerClass');
      }
      final battleDifficulty = trainer.battleDifficulty;
      if (battleDifficulty != null &&
          (battleDifficulty < 1 || battleDifficulty > 10)) {
        throw ValidationException(
          'Trainer $id battleDifficulty must stay within 1..10 (got $battleDifficulty)',
        );
      }
      final battleBackgroundRelativePath =
          trainer.battleBackgroundRelativePath?.trim();
      if (battleBackgroundRelativePath != null &&
          battleBackgroundRelativePath.isNotEmpty) {
        _validateRelativePath(
          battleBackgroundRelativePath,
          'Trainer $id battleBackgroundRelativePath',
        );
      }
      final characterId = trainer.characterId?.trim();
      if (characterId != null &&
          characterId.isNotEmpty &&
          !characterIds.contains(characterId)) {
        throw ValidationException(
          'Trainer $id characterId "$characterId" does not exist in project characters',
        );
      }
      final portraitId = trainer.portraitElementId?.trim();
      if (portraitId != null &&
          portraitId.isNotEmpty &&
          !elementIds.contains(portraitId)) {
        throw ValidationException(
          'Trainer $id portraitElementId "$portraitId" does not exist in project elements',
        );
      }
      for (var i = 0; i < trainer.team.length; i++) {
        final pokemon = trainer.team[i];
        if (pokemon.speciesId.trim().isEmpty) {
          throw ValidationException(
            'Trainer $id team[$i] has empty speciesId',
          );
        }
        if (pokemon.level <= 0) {
          throw ValidationException(
            'Trainer $id team[$i] level must be positive (got ${pokemon.level})',
          );
        }
      }
    }
  }

  static void _validateCharacters(ProjectManifest manifest) {
    final knownTilesetIds = manifest.tilesets.map((t) => t.id).toSet();
    for (final char in manifest.characters) {
      final id = char.id.trim();
      if (id.isEmpty) {
        throw const ValidationException('Character entry has an empty id');
      }
      if (char.name.trim().isEmpty) {
        throw ValidationException('Character $id has an empty name');
      }
      final tid = char.tilesetId.trim();
      if (tid.isEmpty) {
        throw ValidationException('Character $id has an empty tilesetId');
      }
      if (!knownTilesetIds.contains(tid)) {
        throw ValidationException(
          'Character $id references unknown tileset: $tid',
        );
      }
      if (char.frameWidth <= 0 || char.frameHeight <= 0) {
        throw ValidationException(
          'Character $id has invalid frame dimensions',
        );
      }
      for (var i = 0; i < char.animations.length; i++) {
        final anim = char.animations[i];
        for (var j = 0; j < anim.frames.length; j++) {
          final frame = anim.frames[j];
          final src = frame.source;
          if (src.x < 0 || src.y < 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j has invalid source coordinates',
            );
          }
          if (src.width <= 0 || src.height <= 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j has invalid source size',
            );
          }
          if (frame.durationMs <= 0) {
            throw ValidationException(
              'Character $id animation[$i] frame $j durationMs must be positive',
            );
          }
        }
      }
    }
    final playerCharId = manifest.settings.defaultPlayerCharacterId?.trim();
    if (playerCharId != null && playerCharId.isNotEmpty) {
      final charIds = manifest.characters.map((c) => c.id).toSet();
      if (!charIds.contains(playerCharId)) {
        throw ValidationException(
          'Settings defaultPlayerCharacterId "$playerCharId" references unknown character',
        );
      }
    }
  }

  static void _validateSettings(ProjectSettings settings) {
    if (settings.tileWidth <= 0 || settings.tileHeight <= 0) {
      throw const ValidationException('Tile size must be positive');
    }
    if (settings.displayScale <= 0) {
      throw const ValidationException('Display scale must be positive');
    }
    if (settings.defaultMapWidth <= 0 || settings.defaultMapHeight <= 0) {
      throw const ValidationException('Default map size must be positive');
    }
  }

  static void _validateUniqueIds<T>(
    List<T> items,
    String Function(T item) idSelector, {
    required String duplicateMessagePrefix,
  }) {
    final ids = <String>{};
    for (final item in items) {
      final id = idSelector(item).trim();
      if (id.isEmpty) continue;
      if (!ids.add(id)) {
        throw ValidationException('$duplicateMessagePrefix: $id');
      }
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class MapValidator {
  /// [projectDialogueContext] : si fourni, les [DialogueRef] sans chemin legacy doivent pointer vers [ProjectManifest.dialogues].
  static void validate(
    MapData map, {
    ProjectManifest? projectDialogueContext,
  }) {
    final mapId = _requireNonBlank(map.id, 'Map ID cannot be empty');
    _requireNonBlank(map.name, 'Map name cannot be empty');
    if (map.size.width <= 0 || map.size.height <= 0) {
      throw ValidationException(
        'Map $mapId has invalid size: ${map.size.width}x${map.size.height}',
      );
    }

    final expectedCellCount = map.size.width * map.size.height;
    for (final layer in map.layers) {
      _validateLayer(
        layer,
        expectedCellCount,
        mapWidth: map.size.width,
        mapHeight: map.size.height,
      );
    }

    _validateUniqueIds(
      map.layers,
      (layer) => layer.id,
      duplicateMessagePrefix: 'Duplicate layer ID',
    );

    for (final entity in map.entities) {
      final entityId = _requireNonBlank(entity.id, 'Entity ID cannot be empty');
      _requireNonBlank(entity.kind.name, 'Entity $entityId has invalid kind');
      if (entity.size.width <= 0 || entity.size.height <= 0) {
        throw ValidationException(
          'Entity $entityId has invalid size: (${entity.size.width}x${entity.size.height})',
        );
      }
      _validatePositionInBounds(
        entity.pos,
        map.size,
        errorLabel: 'Entity $entityId origin',
      );
      final entityRight = entity.pos.x + entity.size.width;
      final entityBottom = entity.pos.y + entity.size.height;
      if (entityRight > map.size.width || entityBottom > map.size.height) {
        throw ValidationException(
          'Entity $entityId has an invalid area extending outside map bounds',
        );
      }
      for (final key in entity.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
            'Entity $entityId has an empty property key',
          );
        }
      }
      assertValidMapEntityTypedPayloads(entity);
      if (projectDialogueContext != null) {
        assertEntityDialogueRefsAgainstProject(entity, projectDialogueContext);
        assertEntityTrainerRefsAgainstProject(entity, projectDialogueContext);
        assertEntityCharacterRefsAgainstProject(entity, projectDialogueContext);
        assertEntityEditorVisualAgainstProject(entity, projectDialogueContext);
      }
    }
    _validateUniqueIds(
      map.entities,
      (entity) => entity.id,
      duplicateMessagePrefix: 'Duplicate entity ID',
    );

    final layerById = <String, MapLayer>{
      for (final layer in map.layers) layer.id: layer,
    };
    final elementById = projectDialogueContext == null
        ? const <String, ProjectElementEntry>{}
        : {
            for (final element in projectDialogueContext.elements)
              element.id: element,
          };

    for (final instance in map.placedElements) {
      final instanceId = _requireNonBlank(
        instance.id,
        'Placed element instance ID cannot be empty',
      );
      final layerId = _requireNonBlank(
        instance.layerId,
        'Placed element instance $instanceId has empty layerId',
      );
      final elementId = _requireNonBlank(
        instance.elementId,
        'Placed element instance $instanceId has empty elementId',
      );
      final layer = layerById[layerId];
      if (layer == null) {
        throw ValidationException(
          'Placed element instance $instanceId references unknown layer: $layerId',
        );
      }
      if (layer is! TileLayer) {
        throw ValidationException(
          'Placed element instance $instanceId must reference a tile layer: $layerId',
        );
      }
      _validatePositionInBounds(
        instance.pos,
        map.size,
        errorLabel: 'Placed element instance $instanceId origin',
      );
      for (final key in instance.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId has an empty property key',
          );
        }
      }
      final animation = instance.animation;
      if (animation != null) {
        if (animation.speed <= 0) {
          throw ValidationException(
            'Placed element instance $instanceId has invalid animation speed: ${animation.speed}',
          );
        }
        final startOffsetMs = animation.startOffsetMs;
        if (startOffsetMs != null && startOffsetMs < 0) {
          throw ValidationException(
            'Placed element instance $instanceId has negative animation startOffsetMs: $startOffsetMs',
          );
        }
      }
      for (var behaviorIndex = 0;
          behaviorIndex < instance.behaviors.length;
          behaviorIndex++) {
        final behavior = instance.behaviors[behaviorIndex];
        final behaviorId = behavior.id.trim();
        const maxBehaviorCooldownMs = 600000;
        if (behaviorId.isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId behavior[$behaviorIndex] has empty id',
          );
        }
        for (var i = behaviorIndex + 1; i < instance.behaviors.length; i++) {
          if (instance.behaviors[i].id.trim() == behaviorId) {
            throw ValidationException(
              'Placed element instance $instanceId has duplicate behavior id "$behaviorId"',
            );
          }
        }
        final trigger = behavior.trigger;
        final triggerScope = behavior.triggerScope;
        switch (triggerScope) {
          case MapPlacedElementTriggerScope.defaultScope:
            break;
          case MapPlacedElementTriggerScope.oncePerEnter:
            if (trigger != MapPlacedElementTriggerType.onEnter) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope oncePerEnter requires trigger onEnter',
              );
            }
            break;
          case MapPlacedElementTriggerScope.whileInsideSingleShot:
            if (trigger != MapPlacedElementTriggerType.onEnter &&
                trigger != MapPlacedElementTriggerType.onNear) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope whileInsideSingleShot requires trigger onEnter or onNear',
              );
            }
            break;
          case MapPlacedElementTriggerScope.facingOnly:
            if (trigger != MapPlacedElementTriggerType.onAction &&
                trigger != MapPlacedElementTriggerType.onNear) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope facingOnly requires trigger onAction or onNear',
              );
            }
            break;
          case MapPlacedElementTriggerScope.nearCardinalOnly:
            if (trigger != MapPlacedElementTriggerType.onNear) {
              throw ValidationException(
                'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] triggerScope nearCardinalOnly requires trigger onNear',
              );
            }
            break;
        }
        final cooldownMs = behavior.cooldownMs;
        if (cooldownMs != null) {
          if (cooldownMs < 0) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] has negative cooldownMs: $cooldownMs',
            );
          }
          if (cooldownMs > maxBehaviorCooldownMs) {
            throw ValidationException(
              'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId] has excessive cooldownMs: $cooldownMs (max $maxBehaviorCooldownMs)',
            );
          }
        }
        final effect = behavior.effect;
        final behaviorLabel =
            'Placed element instance $instanceId behavior[$behaviorIndex id=$behaviorId]';
        switch (effect.type) {
          case MapPlacedElementEffectType.showMessage:
            final message = effect.message?.trim() ?? '';
            if (message.isEmpty) {
              throw ValidationException(
                '$behaviorLabel showMessage requires a non-empty message',
              );
            }
            break;
          case MapPlacedElementEffectType.openDialogue:
            final dialogue = effect.dialogue;
            if (dialogue == null) {
              throw ValidationException(
                '$behaviorLabel openDialogue requires a dialogue reference',
              );
            }
            final dialogueId = dialogue.dialogueId.trim();
            if (dialogueId.isEmpty) {
              throw ValidationException(
                '$behaviorLabel openDialogue requires a non-empty dialogueId',
              );
            }
            final scriptPath = dialogue.scriptPathRelative.trim();
            if (scriptPath.startsWith('/') || scriptPath.startsWith(r'\')) {
              throw ValidationException(
                '$behaviorLabel dialogue scriptPathRelative must be relative',
              );
            }
            if (scriptPath.contains('..')) {
              throw ValidationException(
                '$behaviorLabel dialogue scriptPathRelative must not contain ..',
              );
            }
            assertValidDialogueStartNode(
              dialogue.startNode,
              contextLabel: '$behaviorLabel dialogue',
            );
            if (projectDialogueContext != null && scriptPath.isEmpty) {
              final exists = projectDialogueContext.dialogues
                  .any((entry) => entry.id == dialogueId);
              if (!exists) {
                throw ValidationException(
                  '$behaviorLabel references unknown dialogue id "$dialogueId"',
                );
              }
            }
            break;
          case MapPlacedElementEffectType.setAnimationEnabled:
            if (effect.animationEnabled == null) {
              throw ValidationException(
                '$behaviorLabel setAnimationEnabled requires animationEnabled',
              );
            }
            break;
          case MapPlacedElementEffectType.playAnimationOnce:
            break;
        }
      }
      if (projectDialogueContext != null) {
        final element = elementById[elementId];
        if (element == null) {
          throw ValidationException(
            'Placed element instance $instanceId references unknown element: $elementId',
          );
        }
        final layerTilesetId = (layer.tilesetId ?? map.tilesetId).trim();
        final elementTilesetId = _resolveElementPrimaryTilesetId(element);
        if (layerTilesetId.isNotEmpty &&
            elementTilesetId.isNotEmpty &&
            layerTilesetId != elementTilesetId) {
          throw ValidationException(
            'Placed element instance $instanceId references element $elementId from tileset $elementTilesetId, but layer $layerId uses tileset $layerTilesetId',
          );
        }
        final source = element.frames.primarySource;
        final width = source.width <= 0 ? 1 : source.width;
        final height = source.height <= 0 ? 1 : source.height;
        final right = instance.pos.x + width;
        final bottom = instance.pos.y + height;
        if (right > map.size.width || bottom > map.size.height) {
          throw ValidationException(
            'Placed element instance $instanceId footprint ${width}x$height exceeds map bounds from origin (${instance.pos.x}, ${instance.pos.y})',
          );
        }
        if (animation != null && animation.enabled && element.frames.isEmpty) {
          throw ValidationException(
            'Placed element instance $instanceId enables animation but source element $elementId has no frames',
          );
        }
      }
    }
    _validateUniqueIds(
      map.placedElements,
      (instance) => instance.id,
      duplicateMessagePrefix: 'Duplicate placed element instance ID',
    );

    final seenConnectionDirections = <MapConnectionDirection>{};
    for (final connection in map.connections) {
      final targetMapId = _requireNonBlank(
        connection.targetMapId,
        'Map connection ${connection.direction.name} has empty targetMapId',
      );
      if (targetMapId == mapId) {
        throw ValidationException(
          'Map connection ${connection.direction.name} cannot target its own map',
        );
      }
      if (!seenConnectionDirections.add(connection.direction)) {
        throw ValidationException(
          'Duplicate map connection direction: ${connection.direction.name}',
        );
      }
    }

    final scriptIds = projectDialogueContext == null
        ? null
        : {
            for (final script in projectDialogueContext.scripts) script.id,
          };
    final layerIds = <String>{for (final layer in map.layers) layer.id};
    for (final event in map.events) {
      _validateMapEvent(
        map,
        event,
        layerIds: layerIds,
        knownScriptIds: scriptIds,
      );
    }
    _validateUniqueIds(
      map.events,
      (event) => event.id,
      duplicateMessagePrefix: 'Duplicate map event ID',
    );

    for (final warp in map.warps) {
      final warpId = _requireNonBlank(warp.id, 'Warp ID cannot be empty');
      _requireNonBlank(warp.targetMapId, 'Warp $warpId has empty targetMapId');
      _validatePositionInBounds(
        warp.pos,
        map.size,
        errorLabel: 'Warp $warpId',
      );
      if (warp.targetPos.x < 0 || warp.targetPos.y < 0) {
        throw ValidationException(
          'Warp $warpId has invalid target position: (${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      if (warp.triggerPadding.top < 0 ||
          warp.triggerPadding.right < 0 ||
          warp.triggerPadding.bottom < 0 ||
          warp.triggerPadding.left < 0) {
        throw ValidationException(
          'Warp $warpId has invalid negative trigger padding',
        );
      }
      final seenApproach = <EntityFacing>{};
      for (final facing in warp.allowedApproachFacings) {
        if (!seenApproach.add(facing)) {
          throw ValidationException(
            'Warp $warpId has duplicate allowed approach facing: ${facing.name}',
          );
        }
      }
    }
    _validateUniqueIds(
      map.warps,
      (warp) => warp.id,
      duplicateMessagePrefix: 'Duplicate warp ID',
    );

    for (final trigger in map.triggers) {
      final triggerId =
          _requireNonBlank(trigger.id, 'Trigger ID cannot be empty');
      _requireNonBlank(
          trigger.type.name, 'Trigger $triggerId has invalid type');
      for (final key in trigger.properties.keys) {
        if (key.trim().isEmpty) {
          throw ValidationException(
              'Trigger $triggerId has an empty property key');
        }
      }
      _validatePositionInBounds(
        trigger.area.pos,
        map.size,
        errorLabel: 'Trigger $triggerId area origin',
      );
      if (trigger.area.size.width <= 0 || trigger.area.size.height <= 0) {
        throw ValidationException(
          'Trigger $triggerId has invalid area size: (${trigger.area.size.width}x${trigger.area.size.height})',
        );
      }

      final zoneRight = trigger.area.pos.x + trigger.area.size.width;
      final zoneBottom = trigger.area.pos.y + trigger.area.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
          'Trigger $triggerId has an invalid area extending outside map bounds',
        );
      }
    }
    _validateUniqueIds(
      map.triggers,
      (trigger) => trigger.id,
      duplicateMessagePrefix: 'Duplicate trigger ID',
    );

    for (final zone in map.gameplayZones) {
      final zoneId =
          _requireNonBlank(zone.id, 'Gameplay zone ID cannot be empty');
      _requireNonBlank(
          zone.kind.name, 'Gameplay zone $zoneId has invalid kind');
      final encounterBattleBackgroundRelativePath =
          zone.encounter?.battleBackgroundRelativePath?.trim();
      if (encounterBattleBackgroundRelativePath != null &&
          encounterBattleBackgroundRelativePath.isNotEmpty) {
        ProjectValidator._validateRelativePath(
          encounterBattleBackgroundRelativePath,
          'Gameplay zone $zoneId encounter battleBackgroundRelativePath',
        );
      }
      final specialProps = zone.special?.properties;
      if (specialProps != null) {
        for (final key in specialProps.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
              'Gameplay zone $zoneId has an empty special property key',
            );
          }
        }
      }
      final movementEffect = zone.movementEffect;
      if (zone.kind == GameplayZoneKind.movementEffect &&
          movementEffect == null) {
        throw ValidationException(
          'Gameplay zone $zoneId requires a movement effect payload',
        );
      }
      if (movementEffect != null && movementEffect.movementCost <= 0) {
        throw ValidationException(
          'Gameplay zone $zoneId movement effect movementCost must be positive',
        );
      }
      _validatePositionInBounds(
        zone.area.pos,
        map.size,
        errorLabel: 'Gameplay zone $zoneId area origin',
      );
      if (zone.area.size.width <= 0 || zone.area.size.height <= 0) {
        throw ValidationException(
          'Gameplay zone $zoneId has invalid area size: '
          '(${zone.area.size.width}x${zone.area.size.height})',
        );
      }
      final zoneRight = zone.area.pos.x + zone.area.size.width;
      final zoneBottom = zone.area.pos.y + zone.area.size.height;
      if (zoneRight > map.size.width || zoneBottom > map.size.height) {
        throw ValidationException(
          'Gameplay zone $zoneId area extends outside map bounds',
        );
      }
    }
    _validateUniqueIds(
      map.gameplayZones,
      (zone) => zone.id,
      duplicateMessagePrefix: 'Duplicate gameplay zone ID',
    );

    _validateMapMetadata(map);
  }

  static void _validateMapMetadata(MapData map) {
    final md = map.mapMetadata;
    if (md.musicId != null && md.musicId!.trim().isEmpty) {
      throw ValidationException(
        'Map metadata musicId must be null or a non-blank string',
      );
    }
    if (md.defaultSpawnId != null && md.defaultSpawnId!.trim().isEmpty) {
      throw ValidationException(
        'Map metadata defaultSpawnId must be null or a non-blank string',
      );
    }
    final seenTags = <String>{};
    for (final tag in md.tags) {
      final t = tag.trim();
      if (t.isEmpty) {
        throw ValidationException(
          'Map metadata tags must not contain empty or whitespace-only entries',
        );
      }
      if (tag != t) {
        throw ValidationException(
          'Map metadata tags must be stored without leading or trailing whitespace',
        );
      }
      if (!seenTags.add(t)) {
        throw ValidationException(
          'Map metadata tags must be unique (duplicate: "$t")',
        );
      }
    }
    final spawnId = md.defaultSpawnId?.trim();
    if (spawnId != null && spawnId.isNotEmpty) {
      final keys = <String>{};
      final entityIds = <String>{};
      for (final e in map.entities) {
        if (e.kind == MapEntityKind.spawn) {
          entityIds.add(e.id);
          final k = e.spawn?.spawnKey.trim() ?? '';
          if (k.isNotEmpty) keys.add(k);
        }
      }
      if (!keys.contains(spawnId) && !entityIds.contains(spawnId)) {
        throw ValidationException(
          'Map metadata defaultSpawnId "$spawnId" does not match any spawn key or spawn entity id on this map',
        );
      }
    }
  }

  static void _validateMapEvent(
    MapData map,
    MapEventDefinition event, {
    required Set<String> layerIds,
    required Set<String>? knownScriptIds,
  }) {
    final eventId = _requireNonBlank(event.id, 'Map event ID cannot be empty');
    final layerId = _requireNonBlank(
      event.position.layerId,
      'Map event $eventId has empty layerId',
    );
    if (!layerIds.contains(layerId)) {
      throw ValidationException(
        'Map event $eventId references unknown layer: $layerId',
      );
    }
    _validatePositionInBounds(
      GridPos(x: event.position.x, y: event.position.y),
      map.size,
      errorLabel: 'Map event $eventId position',
    );
    if (event.pages.isEmpty) {
      throw ValidationException(
        'Map event $eventId must contain at least one page',
      );
    }
    for (final key in event.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $eventId has an empty metadata key',
        );
      }
    }

    final pageNumbers = <int>{};
    for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
      final page = event.pages[pageIndex];
      if (page.pageNumber < 0) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] has negative pageNumber: ${page.pageNumber}',
        );
      }
      if (!pageNumbers.add(page.pageNumber)) {
        throw ValidationException(
          'Map event $eventId has duplicate pageNumber: ${page.pageNumber}',
        );
      }
      _validateMapEventPage(
        eventId: eventId,
        pageIndex: pageIndex,
        page: page,
        knownScriptIds: knownScriptIds,
      );
    }
  }

  static void _validateMapEventPage({
    required String eventId,
    required int pageIndex,
    required MapEventPage page,
    required Set<String>? knownScriptIds,
  }) {
    for (final key in page.metadata.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] has an empty metadata key',
        );
      }
    }
    final script = page.script;
    if (script != null) {
      final scriptId = _requireNonBlank(
        script.scriptId,
        'Map event $eventId page[$pageIndex] has empty scriptId',
      );
      if (knownScriptIds != null && !knownScriptIds.contains(scriptId)) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] references unknown script: $scriptId',
        );
      }
      final startNode = script.startNode?.trim();
      if (startNode != null && startNode.isEmpty) {
        throw ValidationException(
          'Map event $eventId page[$pageIndex] startNode must be null or non-empty',
        );
      }
    }
    final condition = page.condition;
    if (condition != null) {
      _validateScriptCondition(
        condition,
        contextLabel: 'Map event $eventId page[$pageIndex] condition',
      );
    }
  }

  static void _validateScriptCondition(
    ScriptCondition condition, {
    required String contextLabel,
  }) {
    for (final key in condition.params.keys) {
      if (key.trim().isEmpty) {
        throw ValidationException('$contextLabel has an empty param key');
      }
    }
    switch (condition.type) {
      case ScriptConditionType.allOf:
      case ScriptConditionType.anyOf:
        if (condition.children.isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires at least one child',
          );
        }
        for (var i = 0; i < condition.children.length; i++) {
          _validateScriptCondition(
            condition.children[i],
            contextLabel: '$contextLabel.children[$i]',
          );
        }
        return;
      case ScriptConditionType.not:
        if (condition.children.length != 1) {
          throw ValidationException(
            '$contextLabel not requires exactly one child',
          );
        }
        _validateScriptCondition(
          condition.children.first,
          contextLabel: '$contextLabel.children[0]',
        );
        return;
      case ScriptConditionType.flagIsSet:
      case ScriptConditionType.flagIsUnset:
        final flagName = condition.params[ScriptConditionParams.flagName];
        if (flagName == null || flagName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty flagName',
          );
        }
        return;
      case ScriptConditionType.eventIsConsumed:
        final eventId = condition.params[ScriptConditionParams.eventId];
        if (eventId == null || eventId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel eventIsConsumed requires a non-empty eventId',
          );
        }
        return;
      case ScriptConditionType.playerOnMap:
        final mapId = condition.params[ScriptConditionParams.mapId];
        if (mapId == null || mapId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel playerOnMap requires a non-empty mapId',
          );
        }
        return;
      case ScriptConditionType.variableEquals:
      case ScriptConditionType.variableGreaterThan:
      case ScriptConditionType.variableLessThan:
        final variableName =
            condition.params[ScriptConditionParams.variableName];
        final value = condition.params[ScriptConditionParams.value];
        if (variableName == null || variableName.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty variableName',
          );
        }
        if (value == null || value.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty value',
          );
        }
        return;
      case ScriptConditionType.fieldAbilityUnlocked:
        final ability = condition.params[ScriptConditionParams.ability];
        if (ability == null || ability.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel fieldAbilityUnlocked requires a non-empty ability',
          );
        }
        return;
      case ScriptConditionType.partyHasMove:
      case ScriptConditionType.partyHasUsableMove:
        final moveId = condition.params[ScriptConditionParams.moveId];
        if (moveId == null || moveId.trim().isEmpty) {
          throw ValidationException(
            '$contextLabel ${condition.type.name} requires a non-empty moveId',
          );
        }
        return;
    }
  }

  static void _validateLayer(
    MapLayer layer,
    int expectedCellCount, {
    required int mapWidth,
    required int mapHeight,
  }) {
    final layerId = _requireNonBlank(layer.id, 'Layer ID cannot be empty');
    _requireNonBlank(layer.name, 'Layer $layerId name cannot be empty');
    if (layer.opacity < 0.0 || layer.opacity > 1.0) {
      throw ValidationException(
        'Layer $layerId has invalid opacity: ${layer.opacity}',
      );
    }

    layer.map<void>(
      tile: (tileLayer) {
        final layerTilesetId = tileLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isEmpty) {
          throw ValidationException(
              'Tile layer $layerId has an empty tilesetId');
        }
        if (tileLayer.tiles.length != expectedCellCount) {
          throw ValidationException(
            'Tile layer $layerId has invalid tile count: expected $expectedCellCount, got ${tileLayer.tiles.length}',
          );
        }
        for (var i = 0; i < tileLayer.tiles.length; i++) {
          if (tileLayer.tiles[i] < 0) {
            throw ValidationException(
              'Tile layer $layerId has negative tile ID at index $i: ${tileLayer.tiles[i]}',
            );
          }
        }
      },
      collision: (collisionLayer) {
        if (collisionLayer.collisions.length != expectedCellCount) {
          throw ValidationException(
            'Collision layer $layerId has invalid collision count: expected $expectedCellCount, got ${collisionLayer.collisions.length}',
          );
        }
      },
      terrain: (terrainLayer) {
        if (terrainLayer.terrains.length != expectedCellCount) {
          throw ValidationException(
            'Terrain layer $layerId has invalid terrain count: expected $expectedCellCount, got ${terrainLayer.terrains.length}',
          );
        }
      },
      path: (pathLayer) {
        if (pathLayer.cells.length != expectedCellCount) {
          throw ValidationException(
            'Path layer $layerId has invalid cell count: expected $expectedCellCount, got ${pathLayer.cells.length}',
          );
        }
        for (final key in pathLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
                'Path layer $layerId has an empty property key');
          }
        }
        final triggerIds = <String>{};
        for (var i = 0; i < pathLayer.animationTriggers.length; i++) {
          final trigger = pathLayer.animationTriggers[i];
          final resolvedId =
              trigger.id.trim().isEmpty ? 'rule_$i' : trigger.id.trim();
          if (!triggerIds.add(resolvedId)) {
            throw ValidationException(
              'Path layer $layerId has duplicate animation trigger id: $resolvedId',
            );
          }
          if (trigger.mode == PathAnimationPlaybackMode.loopWhileActive &&
              trigger.trigger != PathAnimationTriggerType.whileInside) {
            throw ValidationException(
              'Path layer $layerId trigger[$resolvedId] mode loopWhileActive requires trigger whileInside',
            );
          }
          if (trigger.trigger == PathAnimationTriggerType.whileInside &&
              trigger.mode != PathAnimationPlaybackMode.loopWhileActive) {
            throw ValidationException(
              'Path layer $layerId trigger[$resolvedId] trigger whileInside requires mode loopWhileActive',
            );
          }
        }
      },
      surface: (surfaceLayer) {
        final occupiedCells = <String>{};
        for (var i = 0; i < surfaceLayer.placements.length; i++) {
          final placement = surfaceLayer.placements[i];
          if (placement.surfacePresetId.trim().isEmpty) {
            throw ValidationException(
              'Surface layer $layerId placement[$i] has an empty surfacePresetId',
            );
          }
          if (placement.x < 0 ||
              placement.y < 0 ||
              placement.x >= mapWidth ||
              placement.y >= mapHeight) {
            throw ValidationException(
              'Surface layer $layerId placement[$i] is outside map bounds: (${placement.x}, ${placement.y})',
            );
          }
          final key = '${placement.x}:${placement.y}';
          if (!occupiedCells.add(key)) {
            throw ValidationException(
              'Surface layer $layerId has duplicate placement coordinates: (${placement.x}, ${placement.y})',
            );
          }
        }
        for (final key in surfaceLayer.properties.keys) {
          if (key.trim().isEmpty) {
            throw ValidationException(
                'Surface layer $layerId has an empty property key');
          }
        }
      },
      object: (_) {},
    );
  }

  static String _resolveElementPrimaryTilesetId(ProjectElementEntry element) {
    final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
    return element.tilesetId.trim();
  }

  static String _requireNonBlank(String value, String message) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ValidationException(message);
    }
    return trimmed;
  }

  static void _validatePositionInBounds(
    GridPos pos,
    GridSize mapSize, {
    required String errorLabel,
  }) {
    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= mapSize.width ||
        pos.y >= mapSize.height) {
      throw ValidationException(
        '$errorLabel is out of map bounds at (${pos.x}, ${pos.y})',
      );
    }
  }

  static void _validateUniqueIds<T>(
    List<T> items,
    String Function(T item) idSelector, {
    required String duplicateMessagePrefix,
  }) {
    final ids = <String>{};
    for (final item in items) {
      final id = idSelector(item).trim();
      if (id.isEmpty) continue;
      if (!ids.add(id)) {
        throw ValidationException('$duplicateMessagePrefix: $id');
      }
    }
  }
}

````

### packages/map_editor/lib/src/application/services/gameplay_zone_editing_coordinator.dart

````dart
import 'package:map_core/map_core.dart' as core;

class GameplayZoneEditingCoordinator {
  const GameplayZoneEditingCoordinator();

  core.MapGameplayZone? findZoneAtPos(
    core.MapData map,
    core.GridPos pos,
  ) {
    return core.findGameplayZoneAtPos(map, pos);
  }

  core.MapGameplayZone? findZoneById(
    core.MapData map,
    String zoneId,
  ) {
    return core.findGameplayZoneById(map, zoneId);
  }

  String generateUniqueZoneId(core.MapData map) {
    final ids = map.gameplayZones.map((z) => z.id).toSet();
    if (!ids.contains('zone')) return 'zone';
    var index = 1;
    while (ids.contains('zone_$index')) {
      index++;
    }
    return 'zone_$index';
  }

  /// Crée une zone par défaut (1×1) à la position [pos].
  core.MapGameplayZone createDefaultZone(
    core.MapData map,
    core.GridPos pos,
  ) {
    final id = generateUniqueZoneId(map);
    return core.MapGameplayZone(
      id: id,
      name: id,
      kind: core.GameplayZoneKind.encounter,
      area: core.MapRect(
        pos: pos,
        size: const core.GridSize(width: 1, height: 1),
      ),
      encounter: const core.EncounterZonePayload(),
    );
  }

  /// Crée une zone avec l'aire [rect] définie par clic+glisser.
  core.MapGameplayZone createZoneFromRect(
    core.MapData map,
    core.MapRect rect, {
    core.GameplayZoneKind kind = core.GameplayZoneKind.encounter,
  }) {
    final id = generateUniqueZoneId(map);
    return core.MapGameplayZone(
      id: id,
      name: id,
      kind: kind,
      area: rect,
      encounter: kind == core.GameplayZoneKind.encounter
          ? const core.EncounterZonePayload()
          : null,
      movementEffect: kind == core.GameplayZoneKind.movementEffect
          ? const core.MovementEffectZonePayload()
          : null,
    );
  }
}

````

### packages/map_editor/lib/src/application/services/gameplay_zone_editing_service.dart

````dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../use_cases/gameplay_zone_use_cases.dart';
import 'gameplay_zone_editing_coordinator.dart';

class GameplayZoneCreationResult {
  const GameplayZoneCreationResult({
    required this.updatedMap,
    required this.createdZone,
  });

  final MapData updatedMap;
  final MapGameplayZone createdZone;
}

class GameplayZoneUpdateResult {
  const GameplayZoneUpdateResult({
    required this.updatedMap,
    required this.selectedZoneId,
  });

  final MapData updatedMap;
  final String selectedZoneId;
}

class GameplayZoneEditingService {
  const GameplayZoneEditingService({
    required AddGameplayZoneToMapUseCase addGameplayZoneToMapUseCase,
    required UpdateGameplayZoneOnMapUseCase updateGameplayZoneOnMapUseCase,
    required DeleteGameplayZoneFromMapUseCase deleteGameplayZoneFromMapUseCase,
    required GameplayZoneEditingCoordinator coordinator,
  })  : _addUseCase = addGameplayZoneToMapUseCase,
        _updateUseCase = updateGameplayZoneOnMapUseCase,
        _deleteUseCase = deleteGameplayZoneFromMapUseCase,
        _coordinator = coordinator;

  final AddGameplayZoneToMapUseCase _addUseCase;
  final UpdateGameplayZoneOnMapUseCase _updateUseCase;
  final DeleteGameplayZoneFromMapUseCase _deleteUseCase;
  final GameplayZoneEditingCoordinator _coordinator;

  MapGameplayZone? findSelectedZone(
    MapData? map,
    String? selectedZoneId,
  ) {
    if (map == null || selectedZoneId == null) return null;
    return _coordinator.findZoneById(map, selectedZoneId);
  }

  MapGameplayZone? findZoneAtPos(MapData map, GridPos pos) {
    return _coordinator.findZoneAtPos(map, pos);
  }

  MapGameplayZone requireSelectedZone(MapData map, String? selectedZoneId) {
    if (selectedZoneId == null || selectedZoneId.trim().isEmpty) {
      throw const EditorInvalidOperationException('No gameplay zone selected');
    }
    final zone = _coordinator.findZoneById(map, selectedZoneId);
    if (zone == null) {
      throw EditorNotFoundException(
        'Selected gameplay zone not found: $selectedZoneId',
      );
    }
    return zone;
  }

  /// Crée une zone 1×1 à [pos] (clic simple).
  GameplayZoneCreationResult addZoneAt(MapData map, GridPos pos) {
    final zone = _coordinator.createDefaultZone(map, pos);
    final updated = _addUseCase.execute(map, zone: zone);
    return GameplayZoneCreationResult(updatedMap: updated, createdZone: zone);
  }

  /// Crée une zone avec l'aire [rect] issue d'un clic+glisser.
  GameplayZoneCreationResult addZoneInRect(
    MapData map,
    MapRect rect, {
    GameplayZoneKind kind = GameplayZoneKind.encounter,
  }) {
    final zone = _coordinator.createZoneFromRect(map, rect, kind: kind);
    final updated = _addUseCase.execute(map, zone: zone);
    return GameplayZoneCreationResult(updatedMap: updated, createdZone: zone);
  }

  GameplayZoneUpdateResult updateZone(
    MapData map, {
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final updated = _updateUseCase.execute(
      map,
      zoneId: zoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
    final nextId = id?.trim().isNotEmpty == true ? id!.trim() : zoneId;
    return GameplayZoneUpdateResult(
        updatedMap: updated, selectedZoneId: nextId);
  }

  MapData deleteZone(MapData map, {required String zoneId}) {
    return _deleteUseCase.execute(map, zoneId: zoneId);
  }
}

````

### packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart

````dart
import 'package:map_core/map_core.dart';

class AddGameplayZoneToMapUseCase {
  MapData execute(MapData map, {required MapGameplayZone zone}) {
    final updated = addGameplayZoneToMap(map, zone: zone);
    MapValidator.validate(updated);
    return updated;
  }
}

class UpdateGameplayZoneOnMapUseCase {
  MapData execute(
    MapData map, {
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,

    /// Passer `null` pour effacer le payload, sentinel pour conserver.
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final updated = updateGameplayZoneOnMap(
      map,
      zoneId: zoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
    MapValidator.validate(updated);
    return updated;
  }
}

class DeleteGameplayZoneFromMapUseCase {
  MapData execute(MapData map, {required String zoneId}) {
    final updated = removeGameplayZoneFromMap(map, zoneId: zoneId);
    MapValidator.validate(updated);
    return updated;
  }
}

````

### packages/map_editor/lib/src/features/editor/state/editor_notifier.dart

````dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/trainer_field_update.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/path_autotile_set.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_editing_controller.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';
import '../../surface_painter/surface_painting_controller.dart';

part 'editor_notifier.g.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

@riverpod
class EditorNotifier extends _$EditorNotifier {
  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController => MapSelectionController(
        terrainPresetSelectionCoordinator: _terrainPresetSelectionCoordinator,
      );
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  TerrainPresetResolver get _terrainPresetResolver =>
      ref.read(terrainPresetResolverProvider);
  TerrainPresetSelectionCoordinator get _terrainPresetSelectionCoordinator =>
      ref.read(terrainPresetSelectionCoordinatorProvider);
  PathAutotileResolver get _pathAutotileResolver =>
      ref.read(pathAutotileResolverProvider);
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  TerrainPaintingCoordinator get _terrainPaintingCoordinator =>
      ref.read(terrainPaintingCoordinatorProvider);
  PathLayerEditingCoordinator get _pathLayerEditingCoordinator =>
      ref.read(pathLayerEditingCoordinatorProvider);
  SurfacePaintingController get _surfacePaintingController =>
      const SurfacePaintingController();
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);

  TerrainPresetSelection _currentTerrainPresetSelection() {
    final selection = state.selection;
    return TerrainPresetSelection(
      selectionMode: selection.terrainSelectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  EditorState build() {
    return const EditorState();
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "$name" created successfully',
      );
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
  }) async {
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "${manifest.name}" loaded',
      );
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
    } catch (e) {
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(errorMessage: 'Failed to load project: $e');
      }
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  void applyInMemoryProjectManifest(ProjectManifest manifest) {
    state = state.copyWith(project: manifest);
  }

  Future<bool> saveProjectManifest() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to save.',
      );
      return false;
    }
    debugPrint('EditorNotifier: saveProjectManifest()');
    try {
      await ref.read(projectRepositoryProvider).saveProject(
            project,
            fs.projectManifestPath,
          );
      state = state.copyWith(
        statusMessage: 'Projet sauvegardé via le flux projet existant.',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('EditorNotifier: Error saving project manifest: $e');
      state = state.copyWith(
        errorMessage: 'Failed to save project: $e',
      );
      return false;
    }
  }

  Future<void> saveActiveMap() async {
    endMapStroke();
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = _projectSessionController.markMapSaving(state);

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(
        map,
        path,
        projectDialogueContext: state.project,
      );

      state = _projectSessionController.markMapSaved(
        current: state,
        map: map,
        statusMessage: 'Map "${map.id}" saved',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = _projectSessionController.markMapSaveFailed(
        current: state,
        errorMessage: 'Failed to save map: $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: project,
        current: _currentTerrainPresetSelection(),
      );
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(project: updatedProject),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.getMapPath(id),
          presetSelection: presetSelection,
          selectedTilesetEditorId:
              _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
            map,
          ),
        ),
        statusMessage: 'Map "$id" created successfully',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Failed to create map: $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = _projectWorkspace;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedMap = await useCase.execute(fs, relativePath);
      final map = project == null
          ? loadedMap
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: loadedMap,
              project: project,
            );
      final presetSelection = project == null
          ? _currentTerrainPresetSelection()
          : _terrainPresetSelectionCoordinator.normalize(
              project: project,
              current: _currentTerrainPresetSelection(),
            );
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
                  map,
                );
      state = _projectSessionController.openMapDocument(
        current: state,
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.resolveMapPath(relativePath),
          presetSelection: presetSelection,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Map "${map.id}" loaded',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final repo = ref.read(mapRepositoryProvider);
      return await repo.loadMap(mapPath);
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);
      final project = state.project;
      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );

      if (committed == map) {
        state = state.copyWith(
          statusMessage: 'Map "${map.id}" is already ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Map "${map.id}" resized to ${width}x$height',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(errorMessage: 'Failed to resize map: $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: updatedProject,
        oldId: oldId,
        newId: newId,
        newPath: fs.getMapPath(newId),
        statusMessage: 'Map renamed to "$newId"',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state = state.copyWith(errorMessage: 'Failed to rename map: $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Map "$mapId" deleted',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state = state.copyWith(errorMessage: 'Failed to delete map: $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map "$sourceId" duplicated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state = state.copyWith(errorMessage: 'Failed to duplicate map: $e');
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
    String? libraryFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        folderId: libraryFolderId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId:
            updated.tilesets.isNotEmpty ? updated.tilesets.last.id : null,
        selectedTilesetElementGroupId: null,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
    String? libraryFolderId,
    bool clearLibraryFolder = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
        folderId: libraryFolderId,
        clearLibraryFolder: clearLibraryFolder,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> createTilesetLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentFolderId: parentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create tileset folder: $e',
      );
    }
  }

  Future<void> renameTilesetLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset folder: $e',
      );
    }
  }

  Future<void> moveTilesetLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset folder: $e',
      );
    }
  }

  Future<void> deleteTilesetLibraryFolder(String folderId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete tileset folder: $e',
      );
    }
  }

  Future<void> assignTilesetToLibraryFolder({
    required String tilesetId,
    required String folderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(assignTilesetToLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to folder',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to folder: $e',
      );
    }
  }

  Future<void> moveTilesetToLibraryRoot(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetToLibraryRootUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to library root',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset to library root: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to library root: $e',
      );
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      String? selectedTilesetEditorId = state.selectedTilesetEditorId;
      var workspaceMode = state.workspaceMode;
      var activeBrush =
          _clearBrushIfTilesetRemoved(state.activeBrush, tilesetId);
      if (selectedTilesetEditorId == tilesetId) {
        selectedTilesetEditorId =
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
          state.activeMap,
          preferredLayerId: state.activeLayerId,
        );
        if (selectedTilesetEditorId != null &&
            !updated.tilesets.any((t) => t.id == selectedTilesetEditorId)) {
          selectedTilesetEditorId =
              updated.tilesets.isNotEmpty ? updated.tilesets.first.id : null;
        }
        if (selectedTilesetEditorId == null) {
          workspaceMode = EditorWorkspaceMode.map;
        }
      }
      state = state.copyWith(
        project: updated,
        workspaceMode: workspaceMode,
        activeBrush: activeBrush,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: null,
        terrainSelectionMode: presetSelection.selectionMode,
        selectedTerrainType: presetSelection.selectedTerrainType,
        selectedTerrainPresetId: presetSelection.selectedTerrainPresetId,
        selectedPathPresetId: presetSelection.selectedPathPresetId,
        selectedTerrainPresetByType:
            presetSelection.selectedTerrainPresetByType,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveLayer(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    final layerId = state.activeLayerId;
    if (project == null || map == null || mapPath == null || layerId == null) {
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Active layer must be a tile layer to assign a tileset',
      );
      return;
    }

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap = await useCase.execute(
        project,
        map,
        mapPath,
        layerId,
        tilesetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Tileset "$tilesetId" assigned to layer "${layer.name}"',
        updateSavedSnapshot: true,
      );
      state = state.copyWith(
        workspaceMode: EditorWorkspaceMode.map,
        activeBrush: const EditorBrush.none(),
        selectedTilesetEditorId: tilesetId,
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning layer tileset: $e');
      state =
          state.copyWith(errorMessage: 'Failed to assign layer tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    await assignTilesetToActiveLayer(tilesetId);
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  PathAutotileSet? getSelectedPathAutotileSet() {
    return _pathAutotileResolver.resolve(
      selectedPreset: getSelectedPathPreset(),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  PathAutotileSet? getPathAutotileSetForPresetId(String? presetId) {
    return _pathAutotileResolver.resolve(
      selectedPreset: getPathPresetById(presetId),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  Map<String, PathAutotileSet> getPathAutotileSetsByPresetId() {
    final result = <String, PathAutotileSet>{};
    for (final preset in getPathPresets()) {
      final resolved = getPathAutotileSetForPresetId(preset.id);
      if (resolved != null) {
        result[preset.id] = resolved;
      }
    }
    return result;
  }

  List<ProjectTerrainPreset> getTerrainPresets({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listTerrainPresets(
      project,
      terrainType: terrainType,
    );
  }

  List<ProjectPathPreset> getPathPresets() {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPathPresets(project);
  }

  List<ProjectSurfacePreset> getSurfacePresets() {
    return state.project?.surfaceCatalog.presets ?? const [];
  }

  List<ProjectPresetCategory> getPresetCategories({
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPresetCategories(
      project,
      kind: kind,
      parentCategoryId: parentCategoryId,
    );
  }

  ProjectPresetCategory? getPresetCategoryById({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPresetCategoryById(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  String? resolvePresetCategoryPath({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolvePresetCategoryPath(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  ProjectTerrainPreset? getTerrainPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findTerrainPresetById(project, presetId);
  }

  ProjectPathPreset? getPathPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPathPresetById(project, presetId);
  }

  ProjectSurfacePreset? getSurfacePresetById(String? presetId) {
    final normalizedPresetId = presetId?.trim();
    if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
      return null;
    }
    final project = state.project;
    if (project == null) return null;
    return project.surfaceCatalog.presetById(normalizedPresetId);
  }

  ProjectTerrainPreset? getSelectedTerrainPreset({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return null;
    final type = terrainType ?? state.selectedTerrainType;
    return _terrainPresetResolver.resolveSelectedTerrainPreset(
      project,
      terrainType: type,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  ProjectPathPreset? getSelectedPathPreset() {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolveSelectedPathPreset(
      project,
      selectedPathPresetId: state.selectedPathPresetId,
    );
  }

  ProjectSurfacePreset? getSelectedSurfacePreset() {
    return getSurfacePresetById(state.selectedSurfacePresetId);
  }

  Map<TerrainType, ProjectTerrainPreset> getTerrainPresetByType() {
    final result = <TerrainType, ProjectTerrainPreset>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) continue;
      final preset = getSelectedTerrainPreset(terrainType: type);
      if (preset != null) {
        result[type] = preset;
      }
    }
    return result;
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  void selectPokemonCatalogSection(PokemonCatalogSection section) {
    state = _editorWorkspaceController.selectPokemonCatalogSection(
      state,
      section,
    );
  }

  /// Ouvre le workspace central "Trainer Studio".
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Ouvre le workspace central Surface Studio (lecture seule, Lot 52+).
  void selectSurfaceStudioWorkspace() {
    if (state.project == null) {
      return;
    }
    state = _editorWorkspaceController.selectSurfaceStudioWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final selectedId = state.selectedTilesetEditorId;
    if (selectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == selectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId = activeLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'No tileset selected');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tileset path not found');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetEditorId: element.tilesetId,
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
  }) {
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    final preparedMap = _prepareMapForBrushTileset(
      map: layerContext.map,
      layerId: layerContext.layerId,
      activeLayer: layerContext.layer,
      brushTilesetId: resolvedBrush.tilesetId,
    );
    if (preparedMap == null) return;
    _paintPattern(
      map: preparedMap,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintTerrainAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active editable layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TerrainLayer) {
      final footprint = _resolveTerrainFootprint(emitErrors: true);
      if (footprint == null) return;
      _paintTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: state.selectedTerrainType,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final footprint = _resolvePathFootprint();
      final selectedPathPreset = getSelectedPathPreset();
      if (activeLayer.presetId.trim().isEmpty && selectedPathPreset != null) {
        try {
          final presetAssigned = _pathLayerEditingCoordinator.assignPreset(
            map: map,
            layerId: layerId,
            presetId: selectedPathPreset.id,
          );
          _paintPathPattern(
            map: presetAssigned,
            previousMap: map,
            layerId: layerId,
            pos: pos,
            patternSize: footprint.size,
            failureLabel: footprint.failureLabel,
          );
        } catch (e) {
          _setPaintError('Failed to assign path preset: $e');
        }
        return;
      }
      _paintPathPattern(
        map: map,
        previousMap: map,
        layerId: layerId,
        pos: pos,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  void paintSurfaceAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      _setPaintError('No active map selected');
      return;
    }
    final selectedPreset = getSelectedSurfacePreset();
    if (selectedPreset == null) {
      _setPaintError('Select a surface before painting');
      return;
    }

    try {
      final result = _surfacePaintingController.paint(
        map: map,
        targetLayerId: state.activeLayerId,
        surfacePresetId: selectedPreset.id,
        pos: pos,
      );
      if (!result.changed) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface painted: ${selectedPreset.name}',
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint surface: $e');
    }
  }

  void fillActiveTerrainLayer(TerrainType terrain) {
    final layerContext = _resolveActiveTerrainLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final map = layerContext.map;
    final layerId = layerContext.layerId;
    try {
      final committed = _terrainPaintingCoordinator.fill(
        map: map,
        layerId: layerId,
        terrain: terrain,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        statusMessage: 'Terrain layer filled with ${terrain.name}',
      );
    } catch (e) {
      _setPaintError('Failed to fill terrain layer: $e');
    }
  }

  void assignPathPresetToActivePathLayer(String presetId) {
    final layerContext = _resolveActivePathLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final normalizedPresetId = presetId.trim();
    if (layerContext.layer.presetId.trim() == normalizedPresetId) {
      final preset = getPathPresetById(normalizedPresetId);
      state = state.copyWith(
        statusMessage: preset == null
            ? 'Path layer preset unchanged'
            : 'Path layer preset: ${preset.name}',
        errorMessage: null,
      );
      return;
    }
    try {
      final updated = _pathLayerEditingCoordinator.assignPreset(
        map: layerContext.map,
        layerId: layerContext.layerId,
        presetId: normalizedPresetId,
      );
      final preset = getPathPresetById(normalizedPresetId);
      _applyMapMutation(
        previousMap: layerContext.map,
        updatedMap: updated,
        preferredActiveLayerId: layerContext.layerId,
        statusMessage: preset == null
            ? 'Path layer preset assigned'
            : 'Path layer preset: ${preset.name}',
      );
    } catch (e) {
      _setPaintError('Failed to assign path preset: $e');
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TileLayer) {
      final pattern = _resolveErasePattern(emitErrors: true);
      if (pattern == null) return;
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        failureLabel: pattern.failureLabel,
      );
      return;
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: true);
      if (collisionFootprint == null) return;
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: collisionFootprint.size,
        failureLabel: collisionFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: true);
      if (terrainFootprint == null) return;
      _eraseTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: terrainFootprint.size,
        failureLabel: terrainFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      _erasePathPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pathFootprint.size,
        failureLabel: pathFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is SurfaceLayer) {
      try {
        final erased = _surfacePaintingController.erase(
          map: map,
          targetLayerId: layerId,
          pos: pos,
        );
        if (!erased.changed) {
          state = state.copyWith(errorMessage: null);
          return;
        }
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased.map,
          preferredActiveLayerId: erased.layerId,
          statusMessage: 'Surface placement erased',
          partOfStroke: true,
        );
      } catch (e) {
        _setPaintError('Failed to erase surface: $e');
      }
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        movementEffect: movementEffect,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  bool applyGeneratedGameplayZones({
    required List<MapGameplayZone> zones,
    String? selectZoneId,
    String? statusMessage,
  }) {
    final map = state.activeMap;
    if (map == null || zones.isEmpty) return false;
    try {
      var updatedMap = map;
      for (final zone in zones) {
        updatedMap = addGameplayZoneToMap(updatedMap, zone: zone);
      }

      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: statusMessage ??
            'Generated ${zones.length} gameplay ${zones.length == 1 ? 'zone' : 'zones'}',
      );

      final requestedSelection = selectZoneId?.trim();
      final hasRequestedSelection = requestedSelection != null &&
          requestedSelection.isNotEmpty &&
          updatedMap.gameplayZones.any(
            (zone) => zone.id == requestedSelection,
          );
      state = state.copyWith(
        selectedGameplayZoneId:
            hasRequestedSelection ? requestedSelection : zones.first.id,
      );
      return true;
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to apply generated zones: $e');
      return false;
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(errorMessage: 'No project filesystem available');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'No active map loaded');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'No warp selected');
      return;
    }
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create return warp: $e');
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final updatedMap = await _mapConnectionEditingService.upsertConnection(
        fs,
        project,
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage:
            '${direction.name.toUpperCase()} connection saved to "${targetEntry.name}"',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save map connection: $e',
      );
    }
  }

  void deleteMapConnection(MapConnectionDirection direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = _mapConnectionEditingService.deleteConnection(
        map,
        direction: direction,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage: '${direction.name.toUpperCase()} connection deleted',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete map connection: $e',
      );
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return;
    }
    try {
      endMapStroke();
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      await loadMap(targetEntry.relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      final compatibility = _resolveLayerBrushCompatibility(
        activeLayer,
        resolvedBrush.tilesetId,
      );
      final validity = compatibility == _BrushLayerCompatibility.incompatible
          ? MapToolPreviewValidity.invalid
          : MapToolPreviewValidity.valid;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: validity,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is TerrainLayer) {
        final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
        if (terrainFootprint == null) return null;
        return MapToolPreview.terrainPaint(
          origin: hoveredTile,
          size: terrainFootprint.size,
          terrain: state.selectedTerrainType,
          validity: MapToolPreviewValidity.valid,
        );
      }
      if (activeLayer is PathLayer) {
        final pathFootprint = _resolvePathFootprint();
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: pathFootprint.size,
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (activeLayer is TileLayer) {
      final erasePattern = _resolveErasePattern(emitErrors: false);
      if (erasePattern == null) return null;
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: erasePattern.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
      if (terrainFootprint == null) return null;
      return MapToolPreview.terrainErase(
        origin: hoveredTile,
        size: terrainFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: pathFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
  }

  void undoMap() {
    endMapStroke();
    final restored = _mapEditingController.undo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  void redoMap() {
    endMapStroke();
    final restored = _mapEditingController.redo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required int tilesetColumns,
  }) {
    final tiles = List<int>.filled(
      source.width * source.height,
      0,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = sourceY * tilesetColumns + sourceX + 1;
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <int>[brush.tileId],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      final tilesetId = element.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected project element does not have a tileset');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'element',
        pattern: _buildPatternFromSource(
          element.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ErasePattern? _resolveErasePattern({
    required bool emitErrors,
  }) {
    final footprint = _resolveBrushFootprint(emitErrors: emitErrors);
    if (footprint == null) return null;
    return _ErasePattern(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveTerrainFootprint({
    required bool emitErrors,
  }) {
    final footprint = _terrainPaintingCoordinator.resolveFootprint(
      terrain: state.selectedTerrainType,
    );
    return _ResolvedBrushFootprint(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _paintTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _terrainPaintingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: terrain,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint terrain $failureLabel: $e');
    }
  }

  void _paintPathPattern({
    required MapData map,
    required MapData previousMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _pathLayerEditingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: previousMap,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint path $failureLabel: $e');
    }
  }

  void _eraseTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _terrainPaintingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase terrain $failureLabel: $e');
    }
  }

  void _erasePathPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _pathLayerEditingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase path $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveTerrainLayerContext? _resolveActiveTerrainLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active terrain layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TerrainLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a terrain layer');
      }
      return null;
    }
    return _ActiveTerrainLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  PathLayerBrushFootprint _resolvePathFootprint() {
    return _pathLayerEditingCoordinator.resolveFootprint();
  }

  _ActivePathLayerContext? _resolveActivePathLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active path layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! PathLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a path layer');
      }
      return null;
    }
    return _ActivePathLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _BrushLayerCompatibility _resolveLayerBrushCompatibility(
    TileLayer activeLayer,
    String brushTilesetId,
  ) {
    final currentTilesetId = activeLayer.tilesetId?.trim();
    if (currentTilesetId == brushTilesetId) {
      return _BrushLayerCompatibility.compatible;
    }
    if (currentTilesetId == null ||
        currentTilesetId.isEmpty ||
        _isTileLayerEmpty(activeLayer)) {
      return _BrushLayerCompatibility.rebindable;
    }
    return _BrushLayerCompatibility.incompatible;
  }

  MapData? _prepareMapForBrushTileset({
    required MapData map,
    required String layerId,
    required TileLayer activeLayer,
    required String brushTilesetId,
  }) {
    final compatibility = _resolveLayerBrushCompatibility(
      activeLayer,
      brushTilesetId,
    );
    if (compatibility == _BrushLayerCompatibility.compatible) {
      return map;
    }
    if (compatibility == _BrushLayerCompatibility.incompatible) {
      _setPaintError(
        'Layer "${activeLayer.name}" already contains tiles from another source',
      );
      return null;
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    final layerIndex = updatedLayers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      _setPaintError('Active layer not found: $layerId');
      return null;
    }
    final layer = updatedLayers[layerIndex];
    if (layer is! TileLayer) {
      _setPaintError('Active layer is not a tile layer');
      return null;
    }
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: brushTilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? brushTilesetId : map.tilesetId,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: layerId,
      statusMessage: 'Layer "${activeLayer.name}" updated for current brush',
      partOfStroke: true,
    );
    state = state.copyWith(
      selectedTilesetEditorId: brushTilesetId,
      selectedTilesetElementGroupId: null,
      paletteCategoryFilter: null,
    );
    return updatedMap;
  }

  bool _isTileLayerEmpty(TileLayer layer) {
    for (final tile in layer.tiles) {
      if (tile != 0) return false;
    }
    return true;
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        tileTilesetId: tileTilesetId,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void addSurfaceLayer({
    String name = 'Surfaces',
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.executeSurface(
        map,
        name: name,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Surface layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add surface layer: $e');
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Layer renamed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename layer: $e');
    }
  }

  void deleteMapLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Layer deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
    }
  }

  void deleteAllMapLayers() {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'All layers removed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove all layers: $e');
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Layer shown' : 'Layer hidden',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update layer: $e');
    }
  }

  void setMapLayerOpacity(String layerId, double opacity) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update layer opacity: $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  void selectTerrainType(TerrainType terrain) {
    state = _mapSelectionController.selectTerrainType(
      current: state,
      terrain: terrain,
    );
  }

  void selectTerrainPreset(String? presetId) {
    state = _mapSelectionController.selectTerrainPreset(
      current: state,
      preset: getTerrainPresetById(presetId),
    );
  }

  void selectPathPreset(String? presetId) {
    state = _mapSelectionController.selectPathPreset(
      current: state,
      preset: getPathPresetById(presetId),
    );
  }

  void selectSurfacePreset(String? presetId) {
    final preset = getSurfacePresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Surface not found');
      return;
    }
    state = state.copyWith(
      selectedSurfacePresetId: preset.id,
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface sélectionnée : ${preset.name}',
      errorMessage: null,
    );
  }

  void selectPathPresetForActivePathLayer(String? presetId) {
    final preset = getPathPresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Path preset not found');
      return;
    }
    selectPathPreset(presetId);
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! PathLayer) {
      return;
    }
    assignPathPresetToActivePathLayer(preset.id);
  }

  void selectTerrainPaintMode({
    TerrainType? terrainType,
  }) {
    state = _mapSelectionController.selectTerrainPaintMode(
      current: state,
      terrainType: terrainType,
    );
  }

  void selectPathPaintMode() {
    state = _mapSelectionController.selectPathPaintMode(
      current: state,
      selectedPathPreset: getSelectedPathPreset(),
    );
  }

  void selectSurfacePaintMode() {
    if (getSelectedSurfacePreset() == null) {
      state = state.copyWith(errorMessage: 'Select a surface before painting');
      return;
    }
    state = state.copyWith(
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface paint mode',
      errorMessage: null,
    );
  }

  Future<void> createTerrainPreset({
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create terrain preset: $e',
      );
    }
  }

  Future<void> updateTerrainPreset({
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selectedPreset =
          _terrainPresetResolver.findTerrainPresetById(updated, presetId) ??
              (throw EditorNotFoundException(
                'Terrain preset not found: $presetId',
              ));
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selectedPreset,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update terrain preset: $e',
      );
    }
  }

  Future<void> deleteTerrainPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete terrain preset: $e',
      );
    }
  }

  Future<void> createPathPreset({
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        activeTool: EditorToolType.terrainPaint,
        statusMessage: 'Path preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create path preset: $e');
    }
  }

  Future<void> updatePathPreset({
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updatePathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selected = updated.pathPresets.firstWhere(
        (preset) => preset.id == presetId,
        orElse: () => throw EditorNotFoundException(
          'Path preset not found: $presetId',
        ),
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selected,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update path preset: $e');
    }
  }

  List<PathLayer> getPathLayersForPreset(String presetId) {
    final map = state.activeMap;
    if (map == null) return const [];
    return map.layers
        .whereType<PathLayer>()
        .where((l) => l.presetId.trim() == presetId.trim())
        .toList(growable: false);
  }

  void applyPathLayerAnimationTriggers({
    required String layerId,
    required List<PathAnimationTriggerRule> triggers,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationTriggers(
        map,
        layerId: layerId,
        triggers: triggers,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation triggers updated',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update animation triggers: $e');
    }
  }

  void setPathLayerAnimationMode({
    required String layerId,
    required PathAnimationMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationModeInMap(
        map,
        layerId: layerId,
        mode: mode,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation mode updated',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update animation mode: $e');
    }
  }

  Future<void> deletePathPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePathPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete path preset: $e');
    }
  }

  Future<void> createPresetCategory({
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        kind: kind,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> renamePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renamePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> deletePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
      );
      final selection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Category deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void activateFirstTerrainLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is TerrainLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.terrain,
        name: 'Terrain',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No terrain layer found in this map',
    );
  }

  void activateFirstPathLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is PathLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.path,
        name: 'Path',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No path layer found in this map',
    );
  }

  void activateFirstSurfaceLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is SurfaceLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (!createIfMissing) {
      state = state.copyWith(
        errorMessage: 'No surface layer found in this map',
      );
      return;
    }

    try {
      final result = _surfacePaintingController.ensureSurfaceLayer(
        map: map,
        preferredLayerId: state.activeLayerId,
      );
      if (!result.changed) {
        state = state.copyWith(activeLayerId: result.layerId);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface layer created',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create surface layer: $e');
    }
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    state = state.copyWith(
      activeLayerId: layerId,
      selectedPlacedElementInstanceId: null,
      errorMessage: null,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final instance = map.placedElements[index];
    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next,
    );
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _trainerUnset,
    Object? battleBackgroundRelativePath = _trainerUnset,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: _trainerFieldUpdate<int>(battleDifficulty),
        battleBackgroundRelativePath:
            _trainerFieldUpdate<String>(battleBackgroundRelativePath),
        characterId: _trainerFieldUpdate<String>(characterId),
        portraitElementId: _trainerFieldUpdate<String>(portraitElementId),
        battleThemeId: _trainerFieldUpdate<String>(battleThemeId),
        victoryThemeId: _trainerFieldUpdate<String>(victoryThemeId),
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: _trainerFieldUpdate<String>(heldItemId),
        formId: _trainerFieldUpdate<String>(formId),
        gender: _trainerFieldUpdate<String>(gender),
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

TrainerFieldUpdate<T> _trainerFieldUpdate<T>(Object? rawValue) {
  if (identical(rawValue, _trainerUnset)) {
    return TrainerFieldUpdate<T>.keep();
  }
  return TrainerFieldUpdate<T>.set(rawValue as T?);
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<int> tiles;
}

enum _BrushLayerCompatibility {
  compatible,
  rebindable,
  incompatible,
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ErasePattern {
  const _ErasePattern({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _ActiveTerrainLayerContext {
  const _ActiveTerrainLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TerrainLayer layer;
}

class _ActivePathLayerContext {
  const _ActivePathLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final PathLayer layer;
}

````

### packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart

````dart
part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

enum _EditorMapTileRenderPass {
  background,
  foreground,
}

/// Rejoue côté éditeur la même séparation "fond / avant-plan" que la runtime.
///
/// Pourquoi cette logique existe :
/// - certains éléments posés (table, arbre, façade, etc.) occupent plusieurs
///   cellules ;
/// - seules les cellules de collision représentent le "socle" gameplay ;
/// - les autres cellules servent d'overlay visuel et doivent pouvoir passer
///   devant un acteur.
///
/// Sans cette séparation, l'éditeur peint toute la tile layer en fond puis les
/// entités par-dessus, ce qui donne une preview trompeuse : une entité semble
/// au-dessus d'une table alors qu'en runtime la frange avant de la table doit
/// repasser devant elle.
///
/// On reste volontairement aligné sur la règle runtime existante :
/// - cellules en collision -> restent dans le fond ;
/// - cellules hors collision -> passent dans l'avant-plan.
@visibleForTesting
Map<String, Set<int>> buildEditorForegroundTileCellIndicesByLayerId({
  required MapData map,
  required ProjectManifest? project,
}) {
  if (project == null || map.placedElements.isEmpty) {
    return const <String, Set<int>>{};
  }

  final tileLayerById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
  };
  if (tileLayerById.isEmpty) {
    return const <String, Set<int>>{};
  }

  final elementById = <String, ProjectElementEntry>{
    for (final entry in project.elements) entry.id: entry,
  };
  final out = <String, Set<int>>{};
  final mapWidth = map.size.width;
  final mapHeight = map.size.height;

  for (final instance in map.placedElements) {
    final layer = tileLayerById[instance.layerId];
    if (layer == null) {
      continue;
    }

    final entry = elementById[instance.elementId];
    if (entry == null || entry.frames.isEmpty) {
      continue;
    }

    final source = entry.frames.primarySource;
    final width = source.width <= 0 ? 1 : source.width;
    final height = source.height <= 0 ? 1 : source.height;
    if (width <= 1 && height <= 1) {
      continue;
    }

    final collisionCells = entry.collisionProfile?.cells;
    if (collisionCells == null || collisionCells.isEmpty) {
      continue;
    }

    final collisionSet = <int>{
      for (final cell in collisionCells) cell.y * width + cell.x,
    };
    final layerMask = out.putIfAbsent(layer.id, () => <int>{});

    for (var localY = 0; localY < height; localY++) {
      for (var localX = 0; localX < width; localX++) {
        final localIndex = localY * width + localX;
        if (collisionSet.contains(localIndex)) {
          // Les cellules de collision sont le "socle" gameplay. Elles restent
          // dans la passe de fond, comme en runtime.
          continue;
        }

        final x = instance.pos.x + localX;
        final y = instance.pos.y + localY;
        if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
          continue;
        }

        final globalIndex = y * mapWidth + x;
        if (globalIndex >= layer.tiles.length ||
            layer.tiles[globalIndex] <= 0) {
          continue;
        }

        layerMask.add(globalIndex);
      }
    }
  }

  return out;
}

@visibleForTesting
bool shouldPaintEditorTileCellInRenderPass({
  required bool explicitForeground,
  required bool isForegroundCell,
  required bool foregroundPass,
}) {
  if (foregroundPass) {
    return explicitForeground || isForegroundCell;
  }
  return explicitForeground ? false : !isForegroundCell;
}

@visibleForTesting
bool shouldPaintEditorEntityInForegroundPass(
  MapEntity entity, {
  required bool foregroundPass,
}) {
  final renderInForeground = entity.shouldRenderProjectElementInForeground;
  return foregroundPass ? renderInForeground : !renderInForeground;
}

bool _isExplicitForegroundTileLayerForEditor({
  required String layerId,
  required String layerName,
}) {
  final id = layerId.trim().toLowerCase();
  final name = layerName.trim().toLowerCase();
  const markers = <String>{
    'foreground',
    'fg',
    'above',
    'overlay',
    'front',
    'roof',
    'toit',
  };

  bool containsMarker(String value) {
    for (final marker in markers) {
      if (value == marker ||
          value.startsWith('${marker}_') ||
          value.endsWith('_$marker') ||
          value.contains('_${marker}_')) {
        return true;
      }
    }
    return false;
  }

  return containsMarker(id) || containsMarker(name);
}

/// Painter massif extrait tel quel du shell `MapCanvas`.
///
/// Cette extraction est volontairement mécanique : on ne change pas la
/// responsabilité ni le comportement du painter dans ce lot, on réduit
/// seulement le blast radius du fichier widget principal.
class MapGridPainter extends CustomPainter {
  final MapData map;
  final double zoom;
  final Offset offset;
  final GridPos? hoveredTile;
  final String? activeLayerId;
  final double tileWidth;
  final double tileHeight;
  final Map<String, ui.Image?> tilesetImagesById;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final Map<String, int> tilesPerRowById;
  final MapToolPreview? toolPreview;
  final List<MapWarp> warps;
  final List<MapGameplayZone> gameplayZones;
  final MapRect? gameplayZoneDraftArea;
  final String? selectedEntityId;
  final String? selectedMapEventId;
  final String? selectedWarpId;
  final String? selectedTriggerId;
  final String? selectedGameplayZoneId;
  final String? selectedPlacedElementInstanceId;
  final Map<MapConnectionDirection, String> connectionLabelsByDirection;
  final PathAutotileSet? selectedPathAutotileSet;
  final Map<String, PathAutotileSet> pathAutotileSetsByPresetId;
  final Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType;
  final ProjectManifest? project;
  final int editorEntityAnimationMs;

  MapGridPainter({
    required this.map,
    required this.zoom,
    required this.offset,
    this.hoveredTile,
    this.activeLayerId,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesetImagesById,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.tilesPerRowById,
    this.toolPreview,
    required this.warps,
    required this.gameplayZones,
    this.gameplayZoneDraftArea,
    this.selectedEntityId,
    this.selectedMapEventId,
    this.selectedWarpId,
    this.selectedTriggerId,
    this.selectedGameplayZoneId,
    this.selectedPlacedElementInstanceId,
    required this.connectionLabelsByDirection,
    this.selectedPathAutotileSet,
    required this.pathAutotileSetsByPresetId,
    required this.terrainPresetsByType,
    this.project,
    this.editorEntityAnimationMs = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);

    final gridWidth = map.size.width * tileWidth;
    final gridHeight = map.size.height * tileHeight;

    final visibleLayers = map.layers.where((layer) => layer.isVisible).toList();
    final foregroundTileCellIndicesByLayerId =
        buildEditorForegroundTileCellIndicesByLayerId(
      map: map,
      project: project,
    );

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TerrainLayer) {
        _paintTerrainLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is PathLayer) {
        _paintPathLayer(canvas, layer);
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TileLayer) {
        _paintTileLayer(
          canvas,
          layer,
          renderPass: _EditorMapTileRenderPass.background,
          foregroundTileCellIndicesByLayerId:
              foregroundTileCellIndicesByLayerId,
        );
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is SurfaceLayer) {
        paintSurfaceLayerAtlasTilePreview(
          canvas: canvas,
          layer: layer,
          mapSize: map.size,
          project: project,
          tilesetImagesById: tilesetImagesById,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          zoom: zoom,
          elapsedMs: editorEntityAnimationMs,
        );
      }
    }

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is CollisionLayer) {
        _paintCollisionLayer(canvas, layer,
            isActive: layer.id == activeLayerId);
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;

    for (int x = 0; x <= map.size.width; x++) {
      canvas.drawLine(
        Offset(x * tileWidth, 0),
        Offset(x * tileWidth, gridHeight),
        gridPaint,
      );
    }
    for (int y = 0; y <= map.size.height; y++) {
      canvas.drawLine(
        Offset(0, y * tileHeight),
        Offset(gridWidth, y * tileHeight),
        gridPaint,
      );
    }

    if (hoveredTile != null) {
      final hoverPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          hoveredTile!.x * tileWidth,
          hoveredTile!.y * tileHeight,
          tileWidth,
          tileHeight,
        ),
        hoverPaint,
      );

      final cursorBorder = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom;

      canvas.drawRect(
        Rect.fromLTWH(
          hoveredTile!.x * tileWidth,
          hoveredTile!.y * tileHeight,
          tileWidth,
          tileHeight,
        ),
        cursorBorder,
      );
    }

    _paintGameplayZones(canvas);
    _paintEntities(
      canvas,
      foregroundPass: false,
    );
    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TileLayer) {
        _paintTileLayer(
          canvas,
          layer,
          renderPass: _EditorMapTileRenderPass.foreground,
          foregroundTileCellIndicesByLayerId:
              foregroundTileCellIndicesByLayerId,
        );
      }
    }
    _paintEntities(
      canvas,
      foregroundPass: true,
    );
    _paintSelectedPlacedElementInstance(canvas);
    _paintToolPreview(canvas);
    _paintMapEvents(canvas);
    _paintTriggers(canvas);
    _paintWarps(canvas);
    _paintConnections(canvas, gridWidth, gridHeight);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, gridWidth, gridHeight),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  void _paintWarps(Canvas canvas) {
    if (warps.isEmpty) return;
    for (final warp in warps) {
      if (warp.pos.x < 0 ||
          warp.pos.y < 0 ||
          warp.pos.x >= map.size.width ||
          warp.pos.y >= map.size.height) {
        continue;
      }
      final isSelected = warp.id == selectedWarpId;
      final rect = Rect.fromLTWH(
        warp.pos.x * tileWidth,
        warp.pos.y * tileHeight,
        tileWidth,
        tileHeight,
      );
      final activationRect = _warpActivationRect(warp);
      if (activationRect != rect) {
        final areaPaint = Paint()
          ..color = (warp.triggerMode == MapWarpTriggerMode.onBump
                  ? Colors.orangeAccent
                  : Colors.cyanAccent)
              .withValues(alpha: isSelected ? 0.18 : 0.12)
          ..style = PaintingStyle.fill;
        final areaBorder = Paint()
          ..color = (warp.triggerMode == MapWarpTriggerMode.onBump
                  ? Colors.orangeAccent
                  : Colors.cyanAccent)
              .withValues(alpha: isSelected ? 0.75 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 / zoom : 1.2 / zoom;
        canvas.drawRect(activationRect, areaPaint);
        canvas.drawRect(activationRect, areaBorder);
      }
      final fillPaint = Paint()
        ..color = (isSelected
                ? (warp.triggerMode == MapWarpTriggerMode.onBump
                    ? Colors.orangeAccent
                    : Colors.cyanAccent)
                : Colors.purpleAccent)
            .withValues(alpha: isSelected ? 0.42 : 0.34)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.purpleAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 / zoom : 1.4 / zoom;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      _paintWarpApproachMarkers(
        canvas,
        activationRect: activationRect,
        allowedApproachFacings: warp.allowedApproachFacings,
        isSelected: isSelected,
      );
      final center = Offset(rect.center.dx, rect.center.dy);
      if (warp.triggerMode == MapWarpTriggerMode.onEnter) {
        canvas.drawCircle(
          center,
          (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.14,
          Paint()..color = isSelected ? Colors.white : Colors.purple.shade100,
        );
      } else {
        final symbolSize =
            (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.24;
        final symbolRect = Rect.fromCenter(
          center: center,
          width: symbolSize,
          height: symbolSize,
        );
        canvas.drawRect(
          symbolRect,
          Paint()..color = isSelected ? Colors.white : Colors.orange.shade100,
        );
      }
    }
  }

  void _paintSelectedPlacedElementInstance(Canvas canvas) {
    final selectedId = selectedPlacedElementInstanceId?.trim();
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }
    MapPlacedElement? selectedInstance;
    for (final instance in map.placedElements) {
      if (instance.id != selectedId) {
        continue;
      }
      selectedInstance = instance;
      break;
    }
    if (selectedInstance == null) {
      return;
    }
    if (selectedInstance.pos.x < 0 || selectedInstance.pos.y < 0) {
      return;
    }
    if (selectedInstance.pos.x >= map.size.width ||
        selectedInstance.pos.y >= map.size.height) {
      return;
    }
    final projectContext = project;
    if (projectContext == null) {
      return;
    }
    TilesetSourceRect? source;
    for (final entry in projectContext.elements) {
      if (entry.id == selectedInstance.elementId) {
        source = entry.frames.primarySource;
        break;
      }
    }
    final width = source?.width ?? 1;
    final height = source?.height ?? 1;
    if (width <= 0 || height <= 0) {
      return;
    }
    final rect = Rect.fromLTWH(
      selectedInstance.pos.x * tileWidth,
      selectedInstance.pos.y * tileHeight,
      width * tileWidth,
      height * tileHeight,
    );
    final fill = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.17)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / zoom;
    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  Rect _warpActivationRect(MapWarp warp) {
    final scaleX = sourceTileWidth > 0 ? tileWidth / sourceTileWidth : 1.0;
    final scaleY = sourceTileHeight > 0 ? tileHeight / sourceTileHeight : 1.0;
    final padding = warp.triggerPadding;
    final left = warp.pos.x * tileWidth - padding.left * scaleX;
    final top = warp.pos.y * tileHeight - padding.top * scaleY;
    final width = tileWidth + (padding.left + padding.right) * scaleX;
    final height = tileHeight + (padding.top + padding.bottom) * scaleY;
    return Rect.fromLTWH(left, top, width, height);
  }

  void _paintWarpApproachMarkers(
    Canvas canvas, {
    required Rect activationRect,
    required List<EntityFacing> allowedApproachFacings,
    required bool isSelected,
  }) {
    if (allowedApproachFacings.isEmpty) {
      return;
    }
    final markerPaint = Paint()
      ..color = (isSelected ? Colors.white : Colors.black)
          .withValues(alpha: isSelected ? 0.95 : 0.7)
      ..style = PaintingStyle.fill;
    final markerThickness = (1.8 / zoom).clamp(1.0, 3.0);
    final markerLength =
        ((tileWidth < tileHeight ? tileWidth : tileHeight) * 0.45)
            .clamp(6.0, 22.0);
    for (final facing in allowedApproachFacings) {
      Rect markerRect;
      switch (facing) {
        case EntityFacing.north:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.center.dx, activationRect.top),
            width: markerLength,
            height: markerThickness,
          );
          break;
        case EntityFacing.south:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.center.dx, activationRect.bottom),
            width: markerLength,
            height: markerThickness,
          );
          break;
        case EntityFacing.east:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.right, activationRect.center.dy),
            width: markerThickness,
            height: markerLength,
          );
          break;
        case EntityFacing.west:
          markerRect = Rect.fromCenter(
            center: Offset(activationRect.left, activationRect.center.dy),
            width: markerThickness,
            height: markerLength,
          );
          break;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          markerRect,
          Radius.circular(markerThickness),
        ),
        markerPaint,
      );
    }
  }

  void _paintEntities(
    Canvas canvas, {
    required bool foregroundPass,
  }) {
    if (map.entities.isEmpty) return;
    for (final entity in map.entities) {
      // Les entités "normales" restent entre fond et décor avant-plan.
      // Les props explicitement marqués "devant le décor" sont repeints après
      // la passe foreground pour coller au rendu runtime.
      if (!shouldPaintEditorEntityInForegroundPass(
        entity,
        foregroundPass: foregroundPass,
      )) {
        continue;
      }
      if (entity.pos.x < 0 ||
          entity.pos.y < 0 ||
          entity.pos.x >= map.size.width ||
          entity.pos.y >= map.size.height) {
        continue;
      }
      final isSelected = entity.id == selectedEntityId;
      final rect = Rect.fromLTWH(
        entity.pos.x * tileWidth,
        entity.pos.y * tileHeight,
        entity.size.width * tileWidth,
        entity.size.height * tileHeight,
      );
      final resolved = resolveEntityElementVisualForEditor(
        entity: entity,
        project: project,
        tilesetImagesById: tilesetImagesById,
        sourceTileWidth: sourceTileWidth,
        sourceTileHeight: sourceTileHeight,
        editorAnimationTimeMs: editorEntityAnimationMs,
      );
      if (resolved != null) {
        final shade = RRect.fromRectAndRadius(
          rect,
          Radius.circular(5 / zoom),
        );
        canvas.drawRRect(
          shade,
          Paint()
            ..color = Colors.black.withValues(alpha: isSelected ? 0.28 : 0.2)
            ..style = PaintingStyle.fill,
        );
        _paintEntityProjectElementFrame(
          canvas,
          resolved.image,
          resolved.srcRect,
          rect,
        );
      } else {
        _paintEntityFallbackBody(canvas, entity, rect, isSelected);
      }
      _paintEntitySelectionAndChrome(canvas, entity, rect, isSelected);
    }
  }

  void _paintMapEvents(Canvas canvas) {
    if (map.events.isEmpty) return;
    for (final event in map.events) {
      final x = event.position.x;
      final y = event.position.y;
      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
        continue;
      }
      final isSelected = event.id == selectedMapEventId;
      final rect = Rect.fromLTWH(
        x * tileWidth,
        y * tileHeight,
        tileWidth,
        tileHeight,
      );
      final fill = Paint()
        ..color = const Color(0xFF35E5D7).withValues(
          alpha: isSelected ? 0.4 : 0.26,
        )
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = isSelected
            ? Colors.white
            : const Color(0xFF35E5D7).withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 / zoom : 1.4 / zoom;
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);

      final center = rect.center;
      final radius = (tileWidth < tileHeight ? tileWidth : tileHeight) * 0.17;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = isSelected ? Colors.white : const Color(0xFF0A4955),
      );

      if (rect.width < (34 / zoom) || rect.height < (20 / zoom)) {
        continue;
      }
      final title = event.title.trim();
      final label = title.isNotEmpty ? title : event.id;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - (8 / zoom));
      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (4 / zoom),
          rect.top + (3 / zoom),
        ),
      );
    }
  }

  void _paintEntityProjectElementFrame(
    Canvas canvas,
    ui.Image image,
    Rect src,
    Rect bounds,
  ) {
    if (src.width <= 0 || src.height <= 0) {
      return;
    }
    final srcAr = src.width / src.height;
    final bAr = bounds.width / bounds.height;
    late Rect dst;
    if (srcAr > bAr) {
      final w = bounds.width;
      final h = w / srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    } else {
      final h = bounds.height;
      final w = h * srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    }
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(5 / zoom)),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  void _paintEntityFallbackBody(
    Canvas canvas,
    MapEntity entity,
    Rect rect,
    bool isSelected,
  ) {
    final color = _entityColor(entity.kind);
    final r = RRect.fromRectAndRadius(rect, Radius.circular(6 / zoom));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color.withValues(alpha: isSelected ? 0.32 : 0.2)
        ..style = PaintingStyle.fill,
    );
    final letter = _entityFallbackGlyph(entity.kind);
    final fontSize = math.min(rect.width, rect.height) * 0.38;
    if (fontSize < 4 / zoom) {
      return;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  String _entityFallbackGlyph(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'N',
      MapEntityKind.sign => 'S',
      MapEntityKind.item => 'I',
      MapEntityKind.spawn => 'P',
      MapEntityKind.custom => '+',
    };
  }

  void _paintEntitySelectionAndChrome(
    Canvas canvas,
    MapEntity entity,
    Rect rect,
    bool isSelected,
  ) {
    final color = _entityColor(entity.kind);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(5 / zoom)),
      Paint()
        ..color = (isSelected ? Colors.white : color)
            .withValues(alpha: isSelected ? 0.95 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 / zoom : 1.5 / zoom,
    );

    if (rect.width < (18 / zoom) || rect.height < (16 / zoom)) {
      return;
    }

    final badgeWidth = math.min(rect.width - (6 / zoom), 42 / zoom);
    final badgeRect = Rect.fromLTWH(
      rect.left + (3 / zoom),
      rect.top + (3 / zoom),
      badgeWidth,
      math.min(rect.height - (6 / zoom), 16 / zoom),
    );
    if (badgeRect.width <= 0 || badgeRect.height <= 0) {
      return;
    }

    final badge = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(4 / zoom),
    );
    canvas.drawRRect(
      badge,
      Paint()
        ..color = Colors.black.withValues(alpha: isSelected ? 0.72 : 0.56)
        ..style = PaintingStyle.fill,
    );

    final badgeTextPainter = TextPainter(
      text: TextSpan(
        text: _entityShortLabel(entity.kind),
        style: TextStyle(
          color: Colors.white,
          fontSize: 9 / zoom,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: badgeRect.width - (6 / zoom));
    if (badgeTextPainter.width > 0 && badgeTextPainter.height > 0) {
      badgeTextPainter.paint(
        canvas,
        Offset(
          badgeRect.left + (3 / zoom),
          badgeRect.top + ((badgeRect.height - badgeTextPainter.height) / 2),
        ),
      );
    }

    if (rect.width < (44 / zoom) || rect.height < (28 / zoom)) {
      return;
    }

    final label = entity.inspectorHeadline;
    final labelTextPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 / zoom,
          fontWeight: FontWeight.w600,
          shadows: const [
            Shadow(
              offset: Offset(0.5, 0.5),
              blurRadius: 2,
              color: Color(0xCC000000),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rect.width - (8 / zoom));
    if (labelTextPainter.width <= 0 || labelTextPainter.height <= 0) {
      return;
    }
    labelTextPainter.paint(
      canvas,
      Offset(
        rect.left + (4 / zoom),
        rect.bottom - labelTextPainter.height - (4 / zoom),
      ),
    );
  }

  void _paintTriggers(Canvas canvas) {
    if (map.triggers.isEmpty) return;
    for (final trigger in map.triggers) {
      final isSelected = trigger.id == selectedTriggerId;
      final left = trigger.area.pos.x * tileWidth;
      final top = trigger.area.pos.y * tileHeight;
      final width = trigger.area.size.width * tileWidth;
      final height = trigger.area.size.height * tileHeight;
      final rect = Rect.fromLTWH(left, top, width, height);
      final color = _triggerColor(trigger.type);

      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 0.24 : 0.16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = isSelected ? Colors.white : color.withValues(alpha: 0.92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 / zoom : 1.3 / zoom,
      );

      if (rect.width < (28 / zoom) || rect.height < (18 / zoom)) {
        continue;
      }
      final label = trigger.name.trim().isNotEmpty
          ? trigger.name.trim()
          : '${trigger.type.name}:${trigger.id}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - (8 / zoom));
      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (4 / zoom),
          rect.top + (3 / zoom),
        ),
      );
    }
  }

  void _paintConnections(
    Canvas canvas,
    double gridWidth,
    double gridHeight,
  ) {
    if (map.connections.isEmpty) {
      return;
    }
    for (final connection in map.connections) {
      final badgeRect = _connectionBadgeRect(
        connection.direction,
        gridWidth,
        gridHeight,
      );
      final fillPaint = Paint()
        ..color = const Color(0xFF13212D).withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / zoom;
      final badge = RRect.fromRectAndRadius(
        badgeRect,
        Radius.circular(6 / zoom),
      );
      canvas.drawRRect(badge, fillPaint);
      canvas.drawRRect(badge, borderPaint);

      final label = connectionLabelsByDirection[connection.direction] ??
          connection.targetMapId;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${_directionShortLabel(connection.direction)}  $label',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: badgeRect.width - (12 / zoom));
      final textOffset = Offset(
        badgeRect.left + ((badgeRect.width - textPainter.width) / 2),
        badgeRect.top + ((badgeRect.height - textPainter.height) / 2),
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  Rect _connectionBadgeRect(
    MapConnectionDirection direction,
    double gridWidth,
    double gridHeight,
  ) {
    final inset = 8 / zoom;
    final shortSide = 22 / zoom;
    final badgeWidth = math.max(
      52 / zoom,
      math.min(gridWidth - (inset * 2), 168 / zoom),
    );
    return switch (direction) {
      MapConnectionDirection.north => Rect.fromLTWH(
          (gridWidth - badgeWidth) / 2,
          inset,
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.south => Rect.fromLTWH(
          (gridWidth - badgeWidth) / 2,
          gridHeight - inset - shortSide,
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.east => Rect.fromLTWH(
          gridWidth - inset - badgeWidth,
          (gridHeight / 2) - shortSide - (2 / zoom),
          badgeWidth,
          shortSide,
        ),
      MapConnectionDirection.west => Rect.fromLTWH(
          inset,
          (gridHeight / 2) - shortSide - (2 / zoom),
          badgeWidth,
          shortSide,
        ),
    };
  }

  String _directionShortLabel(MapConnectionDirection direction) {
    return switch (direction) {
      MapConnectionDirection.north => 'N',
      MapConnectionDirection.south => 'S',
      MapConnectionDirection.east => 'E',
      MapConnectionDirection.west => 'W',
    };
  }

  void _paintToolPreview(Canvas canvas) {
    final preview = toolPreview;
    if (preview == null) return;
    if (preview.mode == MapToolPreviewMode.paint) {
      _paintPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.erase) {
      _paintErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.terrainPaint) {
      _paintTerrainPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.terrainErase) {
      _paintTerrainErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.pathPaint) {
      _paintPathPaintPreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.pathErase) {
      _paintPathErasePreview(canvas, preview);
      return;
    }
    if (preview.mode == MapToolPreviewMode.collisionPaint) {
      _paintCollisionPaintPreview(canvas, preview);
      return;
    }
    _paintCollisionErasePreview(canvas, preview);
  }

  void _paintPaintPreview(Canvas canvas, MapToolPreview preview) {
    final tiles = preview.tiles;
    final tilesetId = preview.tilesetId;
    if (tiles == null || tilesetId == null) return;
    final tilesetImage = tilesetImagesById[tilesetId];
    final tilesPerRow = tilesPerRowById[tilesetId] ?? 0;
    if (tilesetImage != null &&
        tilesPerRow > 0 &&
        sourceTileWidth > 0 &&
        sourceTileHeight > 0) {
      final alpha =
          preview.validity == MapToolPreviewValidity.valid ? 0.6 : 0.3;
      final tilePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
      for (var y = 0; y < preview.size.height; y++) {
        for (var x = 0; x < preview.size.width; x++) {
          final mapX = preview.origin.x + x;
          final mapY = preview.origin.y + y;
          if (mapX < 0 ||
              mapY < 0 ||
              mapX >= map.size.width ||
              mapY >= map.size.height) {
            continue;
          }
          final patternIndex = y * preview.size.width + x;
          if (patternIndex < 0 || patternIndex >= tiles.length) continue;
          final tileId = tiles[patternIndex];
          if (tileId <= 0) continue;
          final sourceIndex = tileId - 1;
          final sourceX = (sourceIndex % tilesPerRow) * sourceTileWidth;
          final sourceY = (sourceIndex ~/ tilesPerRow) * sourceTileHeight;
          if (sourceX < 0 ||
              sourceY < 0 ||
              sourceX + sourceTileWidth > tilesetImage.width ||
              sourceY + sourceTileHeight > tilesetImage.height) {
            continue;
          }
          final srcRect = Rect.fromLTWH(
            sourceX.toDouble(),
            sourceY.toDouble(),
            sourceTileWidth.toDouble(),
            sourceTileHeight.toDouble(),
          );
          final dstRect = Rect.fromLTWH(
            mapX * tileWidth,
            mapY * tileHeight,
            tileWidth,
            tileHeight,
          );
          canvas.drawImageRect(tilesetImage, srcRect, dstRect, tilePaint);
        }
      }
    }

    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    if (preview.validity == MapToolPreviewValidity.invalid) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom,
      );
      return;
    }
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom,
    );
  }

  void _paintErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintCollisionPaintPreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.orangeAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintTerrainPaintPreview(Canvas canvas, MapToolPreview preview) {
    final terrainPresetPreviewPainted =
        _paintTerrainPresetPreview(canvas, preview);
    if (terrainPresetPreviewPainted) {
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    final terrainColor = _terrainColor(preview.terrain ?? TerrainType.grass);
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = terrainColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = terrainColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathPaintPreview(Canvas canvas, MapToolPreview preview) {
    final pathPreviewPainted = _paintPathLayerPreview(canvas, preview);
    if (pathPreviewPainted) {
      return;
    }
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.tealAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  bool _paintPathLayerPreview(Canvas canvas, MapToolPreview preview) {
    if (preview.size.width != 1 || preview.size.height != 1) {
      return false;
    }
    final origin = preview.origin;
    if (origin.x < 0 ||
        origin.y < 0 ||
        origin.x >= map.size.width ||
        origin.y >= map.size.height) {
      return false;
    }
    final activePathLayer = _resolveActivePathLayer();
    if (activePathLayer == null) {
      return false;
    }
    final autotileSet = _resolvePreviewPathAutotileSet(activePathLayer);
    if (autotileSet == null) {
      return false;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }

    final expectedLength = map.size.width * map.size.height;
    final simulatedCells = List<bool>.filled(
      expectedLength,
      false,
      growable: false,
    );
    final sourceCells = activePathLayer.cells;
    final copyLength = sourceCells.length < expectedLength
        ? sourceCells.length
        : expectedLength;
    for (var index = 0; index < copyLength; index++) {
      simulatedCells[index] = sourceCells[index];
    }
    final previewIndex = origin.y * map.size.width + origin.x;
    if (previewIndex < 0 || previewIndex >= simulatedCells.length) {
      return false;
    }
    simulatedCells[previewIndex] = true;

    final variant = resolvePathVariantAt(
      cells: simulatedCells,
      mapSize: map.size,
      pos: origin,
    );
    final dstRect = Rect.fromLTWH(
      origin.x * tileWidth,
      origin.y * tileHeight,
      tileWidth,
      tileHeight,
    );

    // Check if the layer has animation triggers
    final hasAnimationTriggers = activePathLayer.animationTriggers.isNotEmpty;
    // If there are animation triggers, do not animate in the editor
    final elapsedMs =
        hasAnimationTriggers ? 0.0 : editorEntityAnimationMs.toDouble();

    final painted = _paintAutotileVariantCell(
      canvas,
      autotileSet: autotileSet,
      variant: variant,
      dstRect: dstRect,
      alpha: 0.66,
      elapsedMs: elapsedMs,
    );
    if (!painted) {
      return false;
    }
    canvas.drawRect(
      dstRect,
      Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
    return true;
  }

  bool _paintTerrainPresetPreview(Canvas canvas, MapToolPreview preview) {
    final terrain = preview.terrain;
    if (terrain == null || terrain == TerrainType.none) {
      return false;
    }
    final preset = terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    var rendered = false;
    for (var y = 0; y < preview.size.height; y++) {
      for (var x = 0; x < preview.size.width; x++) {
        final mapX = preview.origin.x + x;
        final mapY = preview.origin.y + y;
        if (mapX < 0 ||
            mapY < 0 ||
            mapX >= map.size.width ||
            mapY >= map.size.height) {
          continue;
        }
        final resolved = _resolveTerrainPresetFrame(
          preset: preset,
          x: mapX,
          y: mapY,
          elapsedMs: editorEntityAnimationMs.toDouble(),
        );
        if (resolved == null) continue;
        final tilesetId = resolved.tilesetId.trim();
        if (tilesetId.isEmpty) {
          continue;
        }
        final tilesetImage = tilesetImagesById[tilesetId];
        if (tilesetImage == null) {
          continue;
        }
        final sourceX = resolved.source.x * sourceTileWidth;
        final sourceY = resolved.source.y * sourceTileHeight;
        if (sourceX < 0 ||
            sourceY < 0 ||
            sourceX + sourceTileWidth > tilesetImage.width ||
            sourceY + sourceTileHeight > tilesetImage.height) {
          continue;
        }
        canvas.drawImageRect(
          tilesetImage,
          Rect.fromLTWH(
            sourceX.toDouble(),
            sourceY.toDouble(),
            sourceTileWidth.toDouble(),
            sourceTileHeight.toDouble(),
          ),
          Rect.fromLTWH(
            mapX * tileWidth,
            mapY * tileHeight,
            tileWidth,
            tileHeight,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.62),
        );
        rendered = true;
      }
    }
    if (!rendered) return false;
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect != null) {
      canvas.drawRect(
        previewRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 / zoom,
      );
    }
    return true;
  }

  void _paintTerrainErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.blueGrey.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.blueGrey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintPathErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  void _paintCollisionErasePreview(Canvas canvas, MapToolPreview preview) {
    final previewRect = _computePreviewRect(preview.origin, preview.size);
    if (previewRect == null) return;
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: 0.24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = Colors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 / zoom,
    );
  }

  Rect? _computePreviewRect(GridPos origin, GridSize size) {
    final left = origin.x.clamp(0, map.size.width);
    final top = origin.y.clamp(0, map.size.height);
    final right = (origin.x + size.width).clamp(0, map.size.width);
    final bottom = (origin.y + size.height).clamp(0, map.size.height);
    if (right <= left || bottom <= top) return null;
    return Rect.fromLTWH(
      left * tileWidth,
      top * tileHeight,
      (right - left) * tileWidth,
      (bottom - top) * tileHeight,
    );
  }

  void _paintTileLayer(
    Canvas canvas,
    TileLayer layer, {
    required _EditorMapTileRenderPass renderPass,
    required Map<String, Set<int>> foregroundTileCellIndicesByLayerId,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return;
    }
    final layerTilesetId = layer.tilesetId?.trim();
    if (layerTilesetId == null || layerTilesetId.isEmpty) {
      return;
    }
    final tilesetImage = tilesetImagesById[layerTilesetId];
    final tilesPerRow = tilesPerRowById[layerTilesetId] ?? 0;
    if (tilesetImage == null || tilesPerRow <= 0) {
      return;
    }

    final explicitForeground = _isExplicitForegroundTileLayerForEditor(
      layerId: layer.id,
      layerName: layer.name,
    );
    final foregroundCells = foregroundTileCellIndicesByLayerId[layer.id];
    final shouldRenderThisLayer =
        renderPass == _EditorMapTileRenderPass.background
            ? !explicitForeground ||
                (foregroundCells != null && foregroundCells.isNotEmpty)
            : explicitForeground ||
                (foregroundCells != null && foregroundCells.isNotEmpty);
    if (!shouldRenderThisLayer) {
      return;
    }

    final layerPaint = Paint();

    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final tileIndex = rowStart + x;
        if (tileIndex < 0 || tileIndex >= layer.tiles.length) continue;
        final tileId = layer.tiles[tileIndex];
        if (tileId <= 0) continue;
        final shouldDrawCell = shouldPaintEditorTileCellInRenderPass(
          explicitForeground: explicitForeground,
          isForegroundCell: foregroundCells?.contains(tileIndex) ?? false,
          foregroundPass: renderPass == _EditorMapTileRenderPass.foreground,
        );
        if (!shouldDrawCell) {
          continue;
        }

        final sourceIndex = tileId - 1;
        final sourceX = (sourceIndex % tilesPerRow) * sourceTileWidth;
        final sourceY = (sourceIndex ~/ tilesPerRow) * sourceTileHeight;

        if (sourceX < 0 ||
            sourceY < 0 ||
            sourceX + sourceTileWidth > tilesetImage.width ||
            sourceY + sourceTileHeight > tilesetImage.height) {
          continue;
        }

        final srcRect = Rect.fromLTWH(
          sourceX.toDouble(),
          sourceY.toDouble(),
          sourceTileWidth.toDouble(),
          sourceTileHeight.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawImageRect(tilesetImage, srcRect, dstRect, layerPaint);
      }
    }
  }

  void _paintCollisionLayer(
    Canvas canvas,
    CollisionLayer layer, {
    required bool isActive,
  }) {
    if (layer.collisions.isEmpty) return;
    final fillAlpha = (isActive ? 0.34 : 0.24) * layer.opacity;
    final borderAlpha = (isActive ? 0.75 : 0.5) * layer.opacity;
    final fillPaint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.deepOrangeAccent.withValues(alpha: borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / zoom;

    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.collisions.length) continue;
        if (!layer.collisions[index]) continue;
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(cell, fillPaint);
        canvas.drawRect(cell, borderPaint);
      }
    }
  }

  void _paintTerrainLayer(Canvas canvas, TerrainLayer layer) {
    if (layer.terrains.isEmpty) return;
    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.terrains.length) continue;
        final terrain = layer.terrains[index];
        if (terrain == TerrainType.none) {
          continue;
        }
        final terrainPresetDrawn = _paintTerrainPresetCell(
          canvas,
          terrain,
          x: x,
          y: y,
          alpha: 1.0,
        );
        if (terrainPresetDrawn) {
          continue;
        }
        final fillColor = _terrainColor(terrain);
        final borderColor = _terrainBorderColor(terrain);
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 / zoom,
        );
      }
    }
  }

  void _paintPathLayer(Canvas canvas, PathLayer layer) {
    if (layer.cells.isEmpty) return;
    const pathCellAlpha = 1.0;
    final autotileSet = _resolvePathAutotileSetForLayer(layer);
    for (var y = 0; y < map.size.height; y++) {
      final rowStart = y * map.size.width;
      for (var x = 0; x < map.size.width; x++) {
        final index = rowStart + x;
        if (index < 0 || index >= layer.cells.length) continue;
        if (!layer.cells[index]) continue;
        final cell = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        final pathDrawn = autotileSet == null
            ? false
            : _paintPathLayerCell(
                canvas,
                layer,
                autotileSet: autotileSet,
                x: x,
                y: y,
                alpha: pathCellAlpha,
              );
        if (pathDrawn) {
          continue;
        }
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.teal
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.tealAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 / zoom,
        );
      }
    }
  }

  bool _paintPathLayerCell(
    Canvas canvas,
    PathLayer layer, {
    required PathAutotileSet autotileSet,
    required int x,
    required int y,
    required double alpha,
  }) {
    final tilesetId = autotileSet.tilesetId.trim();
    if (tilesetId.isEmpty) return false;
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null || sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }

    final variant = resolvePathVariantAt(
      cells: layer.cells,
      mapSize: map.size,
      pos: GridPos(x: x, y: y),
    );
    final dstRect = Rect.fromLTWH(
      x * tileWidth,
      y * tileHeight,
      tileWidth,
      tileHeight,
    );

    // Check if the layer has animation triggers
    final hasAnimationTriggers = layer.animationTriggers.isNotEmpty;
    // If there are animation triggers, do not animate in the editor
    final elapsedMs =
        hasAnimationTriggers ? 0.0 : editorEntityAnimationMs.toDouble();

    return _paintAutotileVariantCell(
      canvas,
      autotileSet: autotileSet,
      variant: variant,
      dstRect: dstRect,
      alpha: alpha,
      elapsedMs: elapsedMs,
    );
  }

  bool _paintAutotileVariantCell(
    Canvas canvas, {
    required PathAutotileSet autotileSet,
    required TerrainPathVariant variant,
    required Rect dstRect,
    required double alpha,
    required double elapsedMs,
  }) {
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    final source = autotileSet.sourceForVariantAt(
      variant,
      elapsedMs: elapsedMs,
    );
    if (source == null) return false;
    final tilesetId = autotileSet.resolvedTilesetIdForVariantAt(
      variant,
      elapsedMs: elapsedMs,
    );
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null) {
      return false;
    }

    final sourceX = source.x * sourceTileWidth;
    final sourceY = source.y * sourceTileHeight;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + sourceTileWidth > tilesetImage.width ||
        sourceY + sourceTileHeight > tilesetImage.height) {
      return false;
    }

    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      sourceTileWidth.toDouble(),
      sourceTileHeight.toDouble(),
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  bool _paintTerrainPresetCell(
    Canvas canvas,
    TerrainType terrain, {
    required int x,
    required int y,
    required double alpha,
  }) {
    final preset = terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
      return false;
    }
    final resolved = _resolveTerrainPresetFrame(
      preset: preset,
      x: x,
      y: y,
      elapsedMs: editorEntityAnimationMs.toDouble(),
    );
    if (resolved == null) return false;
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tilesetImagesById[tilesetId];
    if (tilesetImage == null) {
      return false;
    }
    final sourceX = resolved.source.x * sourceTileWidth;
    final sourceY = resolved.source.y * sourceTileHeight;
    if (sourceX < 0 ||
        sourceY < 0 ||
        sourceX + sourceTileWidth > tilesetImage.width ||
        sourceY + sourceTileHeight > tilesetImage.height) {
      return false;
    }

    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      sourceTileWidth.toDouble(),
      sourceTileHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      x * tileWidth,
      y * tileHeight,
      tileWidth,
      tileHeight,
    );
    canvas.drawImageRect(
      tilesetImage,
      srcRect,
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  _ResolvedTerrainFrame? _resolveTerrainPresetFrame({
    required ProjectTerrainPreset preset,
    required int x,
    required int y,
    required double elapsedMs,
  }) {
    final variants = preset.variants;
    if (variants.isEmpty) return null;
    var totalWeight = 0;
    for (final variant in variants) {
      totalWeight += variant.weight <= 0 ? 1 : variant.weight;
    }
    if (totalWeight <= 0) return null;

    final seed = _stableCellSeed(x: x, y: y, salt: preset.id.hashCode);
    var selectedWeight = seed % totalWeight;
    TerrainPresetVariant chosen = variants.first;
    for (final variant in variants) {
      final weight = variant.weight <= 0 ? 1 : variant.weight;
      if (selectedWeight < weight) {
        chosen = variant;
        break;
      }
      selectedWeight -= weight;
    }

    if (chosen.frames.isEmpty) {
      return null;
    }
    final frameIndex = resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: normalizeElementFrameDurationsMs(
        chosen.frames.map((frame) => frame.durationMs).toList(growable: false),
      ),
      elapsedMs: elapsedMs,
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
      ),
    );
    final resolvedFrame =
        chosen.frames[frameIndex.clamp(0, chosen.frames.length - 1)];
    final frameSource = resolvedFrame.source;
    final width = frameSource.width <= 0 ? 1 : frameSource.width;
    final height = frameSource.height <= 0 ? 1 : frameSource.height;
    final cellSeed = _stableCellSeed(
      x: x,
      y: y,
      salt: frameSource.x * 73856093 + frameSource.y * 19349663,
    );
    final tileIndex = cellSeed % (width * height);
    final offsetX = tileIndex % width;
    final offsetY = tileIndex ~/ width;
    final frameTilesetId = resolvedFrame.tilesetId.trim();
    final resolvedTilesetId =
        frameTilesetId.isNotEmpty ? frameTilesetId : preset.tilesetId.trim();
    if (resolvedTilesetId.isEmpty) {
      return null;
    }
    return _ResolvedTerrainFrame(
      tilesetId: resolvedTilesetId,
      source: TilesetSourceRect(
        x: frameSource.x + offsetX,
        y: frameSource.y + offsetY,
      ),
    );
  }

  int _stableCellSeed({
    required int x,
    required int y,
    required int salt,
  }) {
    final raw = ((x + 1) * 73856093) ^ ((y + 1) * 19349663) ^ salt;
    return raw & 0x7fffffff;
  }

  PathLayer? _resolveActivePathLayer() {
    final id = activeLayerId;
    if (id == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == id && layer is PathLayer) {
        return layer;
      }
    }
    return null;
  }

  PathAutotileSet? _resolvePathAutotileSetForLayer(PathLayer layer) {
    final presetId = layer.presetId.trim();
    if (presetId.isEmpty) {
      return null;
    }
    return pathAutotileSetsByPresetId[presetId];
  }

  PathAutotileSet? _resolvePreviewPathAutotileSet(PathLayer layer) {
    final assigned = _resolvePathAutotileSetForLayer(layer);
    if (assigned != null) {
      return assigned;
    }
    return selectedPathAutotileSet;
  }

  Color _terrainColor(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.none => Colors.transparent,
      TerrainType.grass => Colors.lightGreenAccent,
      TerrainType.dirt => const Color(0xFFA46E3D),
      TerrainType.sand => Colors.amberAccent,
      TerrainType.rock => Colors.blueGrey,
      TerrainType.stone => Colors.grey,
      TerrainType.indoor => const Color(0xFFD8C3A5),
    };
  }

  Color _terrainBorderColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return Colors.green.shade900;
      case TerrainType.dirt:
        return const Color(0xFF6D4524);
      case TerrainType.sand:
        return Colors.orange.shade900;
      case TerrainType.rock:
        return Colors.blueGrey.shade900;
      case TerrainType.stone:
        return Colors.grey.shade800;
      case TerrainType.indoor:
        return const Color(0xFF8D6E63);
      case TerrainType.none:
        return Colors.transparent;
    }
  }

  void _paintGameplayZones(Canvas canvas) {
    // Fantôme de tracé en cours
    final draft = gameplayZoneDraftArea;
    if (draft != null) {
      final draftRect = Rect.fromLTWH(
        draft.pos.x * tileWidth,
        draft.pos.y * tileHeight,
        draft.size.width * tileWidth,
        draft.size.height * tileHeight,
      );
      canvas.drawRect(
        draftRect,
        Paint()
          ..color = const Color(0xFF66FF99).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        draftRect,
        Paint()
          ..color = const Color(0xFF66FF99).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / zoom
          ..strokeCap = StrokeCap.round,
      );
    }

    if (gameplayZones.isEmpty) return;
    for (final zone in gameplayZones) {
      final isSelected = zone.id == selectedGameplayZoneId;
      final left = zone.area.pos.x * tileWidth;
      final top = zone.area.pos.y * tileHeight;
      final width = zone.area.size.width * tileWidth;
      final height = zone.area.size.height * tileHeight;
      final rect = Rect.fromLTWH(left, top, width, height);
      final color = _gameplayZoneColor(zone.kind);

      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: isSelected ? 0.20 : 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = isSelected ? Colors.white : color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 / zoom : 1.3 / zoom,
      );

      if (rect.width < (28 / zoom) || rect.height < (18 / zoom)) {
        continue;
      }
      final label = zone.name.trim().isNotEmpty
          ? zone.name.trim()
          : '${zone.kind.name}:${zone.id}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10 / zoom,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: rect.width - (8 / zoom));
      if (textPainter.width <= 0 || textPainter.height <= 0) {
        continue;
      }
      textPainter.paint(
        canvas,
        Offset(
          rect.left + (4 / zoom),
          rect.top + (3 / zoom),
        ),
      );
    }
  }

  Color _gameplayZoneColor(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => const Color(0xFF66FF99),
      GameplayZoneKind.movement => const Color(0xFF66AAFF),
      GameplayZoneKind.movementEffect => const Color(0xFF66D9FF),
      GameplayZoneKind.hazard => const Color(0xFFFF6666),
      GameplayZoneKind.special => const Color(0xFFCC66FF),
      GameplayZoneKind.custom => const Color(0xFF66FFFF),
    };
  }

  Color _triggerColor(TriggerType type) {
    return switch (type) {
      TriggerType.warp => Colors.deepPurpleAccent,
      TriggerType.message => Colors.amberAccent,
      TriggerType.interaction => Colors.lightBlueAccent,
      TriggerType.event => Colors.orangeAccent,
      TriggerType.spawn => Colors.greenAccent,
      TriggerType.camera => Colors.pinkAccent,
      TriggerType.custom => Colors.cyanAccent,
    };
  }

  Color _entityColor(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => const Color(0xFF55D0FF),
      MapEntityKind.sign => const Color(0xFFFFC857),
      MapEntityKind.item => const Color(0xFF7CE38B),
      MapEntityKind.spawn => const Color(0xFFFF7B7B),
      MapEntityKind.custom => const Color(0xFFC18CFF),
    };
  }

  String _entityShortLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'SIGN',
      MapEntityKind.item => 'ITEM',
      MapEntityKind.spawn => 'SPAWN',
      MapEntityKind.custom => 'CUSTOM',
    };
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.hoveredTile != hoveredTile ||
        oldDelegate.activeLayerId != activeLayerId ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        !_sameToolPreview(oldDelegate.toolPreview, toolPreview) ||
        oldDelegate.selectedEntityId != selectedEntityId ||
        oldDelegate.selectedMapEventId != selectedMapEventId ||
        oldDelegate.selectedWarpId != selectedWarpId ||
        oldDelegate.selectedTriggerId != selectedTriggerId ||
        oldDelegate.selectedGameplayZoneId != selectedGameplayZoneId ||
        oldDelegate.selectedPlacedElementInstanceId !=
            selectedPlacedElementInstanceId ||
        oldDelegate.gameplayZoneDraftArea != gameplayZoneDraftArea ||
        !listEquals(oldDelegate.warps, warps) ||
        !listEquals(oldDelegate.gameplayZones, gameplayZones) ||
        !_samePathAutotileSet(
          oldDelegate.selectedPathAutotileSet,
          selectedPathAutotileSet,
        ) ||
        !mapEquals(
          oldDelegate.connectionLabelsByDirection,
          connectionLabelsByDirection,
        ) ||
        !_samePathAutotileSetsByPresetId(
          oldDelegate.pathAutotileSetsByPresetId,
          pathAutotileSetsByPresetId,
        ) ||
        !mapEquals(oldDelegate.terrainPresetsByType, terrainPresetsByType) ||
        oldDelegate.project != project ||
        !mapEquals(oldDelegate.tilesetImagesById, tilesetImagesById) ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        !mapEquals(oldDelegate.tilesPerRowById, tilesPerRowById) ||
        oldDelegate.editorEntityAnimationMs != editorEntityAnimationMs;
  }

  bool _sameToolPreview(MapToolPreview? previous, MapToolPreview? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    return previous.mode == next.mode &&
        previous.origin == next.origin &&
        previous.size == next.size &&
        previous.tilesetId == next.tilesetId &&
        previous.terrain == next.terrain &&
        previous.validity == next.validity &&
        previous.reason == next.reason &&
        listEquals(previous.tiles, next.tiles);
  }

  bool _samePathAutotileSet(PathAutotileSet? previous, PathAutotileSet? next) {
    if (identical(previous, next)) return true;
    if (previous == null || next == null) return previous == next;
    if (previous.id != next.id) return false;
    if (previous.tilesetId != next.tilesetId) return false;
    if (previous.variants.length != next.variants.length) return false;
    for (final entry in previous.variants.entries) {
      final other = next.variants[entry.key];
      if (other == null) return false;
      if (!listEquals(other, entry.value)) return false;
    }
    return true;
  }

  bool _samePathAutotileSetsByPresetId(
    Map<String, PathAutotileSet> previous,
    Map<String, PathAutotileSet> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (final entry in previous.entries) {
      if (!_samePathAutotileSet(entry.value, next[entry.key])) {
        return false;
      }
    }
    return true;
  }
}

````

### packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart

````dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/editor/state/editor_notifier.dart';
import 'battle_background_path_utils.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';

class GameplayZonePropertiesPanel extends ConsumerStatefulWidget {
  const GameplayZonePropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<GameplayZonePropertiesPanel> createState() =>
      _GameplayZonePropertiesPanelState();
}

class _GameplayZonePropertiesPanelState
    extends ConsumerState<GameplayZonePropertiesPanel> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _priorityController = TextEditingController();

  // ── Per-kind payload fields ──────────────────────────────────────────────────
  String? _boundFingerprint;
  GameplayZoneKind _selectedKind = GameplayZoneKind.encounter;

  // encounter
  String? _encounterTableId;
  EncounterKind _encounterKind = EncounterKind.walk;
  String? _encounterBattleBackgroundRelativePath;
  String? _encounterBattleBackgroundMessage;

  // movement
  MovementMode _movementMode = MovementMode.walk;

  // movement effect
  MovementEffectZoneKind _movementEffectKind = MovementEffectZoneKind.slide;
  int _movementEffectCost = 1;

  // hazard
  HazardKind _hazardKind = HazardKind.other;
  int _hazardDamagePerStep = 0;

  // special / custom
  String _scriptKey = '';

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final project = state.project;
    final selectedZone = notifier.getSelectedGameplayZone();
    _syncControllers(selectedZone);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyMint;
    final listAccent = widget.embedded ? accent : EditorPaintColors.greenAccent;
    final labelColor = CupertinoColors.label.resolveFrom(context);

    final encounterTableOptions = project?.encounterTables ?? const [];

    final content = map == null
        ? Center(
            child: Text(
              'No map loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : ListView(
            padding: widget.embedded
                ? kInspectorTileBodyPadding
                : const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              if (map.gameplayZones.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No gameplay zones on this map.\nSelect the Zone tool and draw a rectangle to add one.',
                    style: TextStyle(
                      color:
                          CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...map.gameplayZones.map(
                  (zone) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: zone.id == state.selectedGameplayZoneId
                            ? Color.lerp(
                                EditorChrome.islandFillElevated(context),
                                listAccent,
                                0.3,
                              )!
                            : EditorChrome.islandFillElevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: zone.id == state.selectedGameplayZoneId
                              ? listAccent.withValues(alpha: 0.78)
                              : EditorChrome.editorIslandRim(context),
                          width: 1,
                        ),
                        boxShadow:
                            EditorChrome.inspectorTileHardShadows(context),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        alignment: Alignment.centerLeft,
                        onPressed: () => notifier.selectGameplayZone(zone.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconForKind(zone.kind),
                              size: 16,
                              color: zone.id == state.selectedGameplayZoneId
                                  ? listAccent
                                  : subtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.name.trim().isNotEmpty
                                        ? zone.name
                                        : zone.id,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: labelColor,
                                      fontWeight: zone.id ==
                                              state.selectedGameplayZoneId
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_kindLabel(zone.kind)} | ${zone.id} | (${zone.area.pos.x},${zone.area.pos.y}) ${zone.area.size.width}×${zone.area.size.height}',
                                    style:
                                        TextStyle(fontSize: 11, color: subtle),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const EditorHorizontalDivider(),
              const SizedBox(height: 8),
              if (selectedZone == null)
                Text(
                  'Select a zone to edit its properties.',
                  style: TextStyle(
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 12,
                  ),
                )
              else
                _buildEditor(
                  context: context,
                  notifier: notifier,
                  zone: selectedZone,
                  encounterTableOptions: encounterTableOptions,
                  projectRootPath: state.projectRootPath?.trim(),
                ),
            ],
          );

    if (widget.embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(color: EditorChrome.islandFill(context)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'GAMEPLAY ZONES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.gameplayZones.length}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapGameplayZone zone,
    required List<ProjectEncounterTable> encounterTableOptions,
    required String? projectRootPath,
  }) {
    const coral = EditorChrome.inspectorJoyCoral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          const InspectorEmbeddedSectionLabel('Zone sélectionnée')
        else
          Text(
            'Selected Zone',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 8),
        _labeledField(context, label: 'ID', controller: _idController),
        const SizedBox(height: 8),
        _labeledField(context, label: 'Name', controller: _nameController),
        const SizedBox(height: 8),
        // Kind
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: coral,
            fieldLabel: 'Kind',
            valueLabel: _kindLabel(_selectedKind),
            orderedIds: GameplayZoneKind.values.map((k) => k.name).toList(),
            selectedMenuValue: _selectedKind.name,
            selectedIdForCheck: _selectedKind.name,
            idToLabel: (id) => _kindLabel(
              GameplayZoneKind.values.firstWhere((k) => k.name == id),
            ),
            onSelected: (id) {
              setState(() {
                _selectedKind =
                    GameplayZoneKind.values.firstWhere((k) => k.name == id);
              });
            },
            tooltip: 'Zone kind',
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<GameplayZoneKind>(
                context: context,
                title: 'Kind',
                items: GameplayZoneKind.values,
                labelOf: _kindLabel,
              );
              if (picked != null) setState(() => _selectedKind = picked);
            },
            child: Text('Kind: ${_kindLabel(_selectedKind)}'),
          ),
        const SizedBox(height: 8),

        // ── Payload fields per kind ────────────────────────────────────────────
        if (_selectedKind == GameplayZoneKind.encounter) ...[
          const _SectionDivider('Encounter'),
          const SizedBox(height: 8),
          if (encounterTableOptions.isNotEmpty)
            _buildEncounterTableDropdown(
              context,
              coral,
              encounterTableOptions,
            ),
          const SizedBox(height: 8),
          _buildEncounterKindDropdown(context, coral),
          const SizedBox(height: 8),
          _buildEncounterBattleBackgroundPicker(
            context: context,
            projectRootPath: projectRootPath,
          ),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.movement) ...[
          const _SectionDivider('Movement'),
          const SizedBox(height: 8),
          _buildMovementModeDropdown(context, coral),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.movementEffect) ...[
          const _SectionDivider('Movement Effect'),
          const SizedBox(height: 8),
          _buildMovementEffectKindDropdown(context, coral),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: 'Movement Cost',
            controller:
                TextEditingController(text: _movementEffectCost.toString())
                  ..selection = TextSelection.collapsed(
                    offset: _movementEffectCost.toString().length,
                  ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) setState(() => _movementEffectCost = parsed);
            },
          ),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.hazard) ...[
          const _SectionDivider('Hazard'),
          const SizedBox(height: 8),
          _buildHazardKindDropdown(context, coral),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: 'Damage / step',
            controller:
                TextEditingController(text: _hazardDamagePerStep.toString())
                  ..selection = TextSelection.collapsed(
                      offset: _hazardDamagePerStep.toString().length),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) setState(() => _hazardDamagePerStep = parsed);
            },
          ),
          const SizedBox(height: 8),
        ],

        if (_selectedKind == GameplayZoneKind.special ||
            _selectedKind == GameplayZoneKind.custom) ...[
          const _SectionDivider('Special'),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: 'Script Key',
            controller: TextEditingController(text: _scriptKey)
              ..selection = TextSelection.collapsed(offset: _scriptKey.length),
            onChanged: (v) => setState(() => _scriptKey = v),
          ),
          const SizedBox(height: 8),
        ],

        // ── Priority ──────────────────────────────────────────────────────────
        _labeledField(
          context,
          label: 'Priority',
          controller: _priorityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),

        // ── Actions ───────────────────────────────────────────────────────────
        if (widget.embedded)
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: coral,
                  icon: CupertinoIcons.checkmark_circle_fill,
                  label: 'Enregistrer',
                  prominent: true,
                  onPressed: () => _save(context, notifier),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: coral,
                  icon: CupertinoIcons.trash,
                  label: 'Supprimer',
                  enabled: true,
                  onPressed: notifier.deleteSelectedGameplayZone,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () => _save(context, notifier),
                  child: const Text('Save Zone'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  onPressed: notifier.deleteSelectedGameplayZone,
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Payload dropdowns ──────────────────────────────────────────────────────

  Widget _buildEncounterTableDropdown(
    BuildContext context,
    Color accent,
    List<ProjectEncounterTable> options,
  ) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Encounter Table',
        valueLabel: _encounterTableId == null
            ? '—'
            : (options
                .firstWhere(
                  (t) => t.id == _encounterTableId,
                  orElse: () => options.first,
                )
                .name),
        orderedIds: ['', ...options.map((t) => t.id)],
        selectedMenuValue: _encounterTableId ?? '',
        selectedIdForCheck: _encounterTableId ?? '',
        idToLabel: (id) => id.isEmpty
            ? '— None —'
            : (options
                .firstWhere((t) => t.id == id, orElse: () => options.first)
                .name),
        onSelected: (id) => setState(
          () => _encounterTableId = id.isEmpty ? null : id,
        ),
        tooltip: 'Encounter table',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<ProjectEncounterTable?>(
          context: context,
          title: 'Encounter Table',
          items: [null, ...options],
          labelOf: (t) => t == null ? '— None —' : t.name,
        );
        if (picked != null || _encounterTableId != null) {
          setState(() => _encounterTableId = picked?.id);
        }
      },
      child: Text(
        'Encounter Table: ${_encounterTableId == null ? '—' : options.firstWhere((t) => t.id == _encounterTableId!, orElse: () => options.first).name}',
      ),
    );
  }

  Widget _buildEncounterKindDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Encounter Kind',
        valueLabel: _encounterKindLabel(_encounterKind),
        orderedIds: EncounterKind.values.map((k) => k.name).toList(),
        selectedMenuValue: _encounterKind.name,
        selectedIdForCheck: _encounterKind.name,
        idToLabel: (id) => _encounterKindLabel(
          EncounterKind.values.firstWhere((k) => k.name == id),
        ),
        onSelected: (id) => setState(() {
          _encounterKind = EncounterKind.values.firstWhere((k) => k.name == id);
        }),
        tooltip: 'Encounter trigger kind',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<EncounterKind>(
          context: context,
          title: 'Encounter Kind',
          items: EncounterKind.values,
          labelOf: _encounterKindLabel,
        );
        if (picked != null) setState(() => _encounterKind = picked);
      },
      child: Text('Encounter Kind: ${_encounterKindLabel(_encounterKind)}'),
    );
  }

  Widget _buildEncounterBattleBackgroundPicker({
    required BuildContext context,
    required String? projectRootPath,
  }) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final relativePath = _encounterBattleBackgroundRelativePath?.trim();
    final hasExplicitPath = relativePath != null && relativePath.isNotEmpty;
    final absolutePath = !hasExplicitPath || projectRootPath == null
        ? null
        : p.normalize(p.join(projectRootPath, relativePath));
    final exists = absolutePath != null && File(absolutePath).existsSync();
    final statusLabel = !hasExplicitPath
        ? 'none'
        : exists
            ? 'linked'
            : 'missing';
    final statusColor = switch (statusLabel) {
      'linked' => EditorChrome.accentJade,
      'missing' => EditorChrome.inspectorJoyCoral,
      _ => subtle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Battle background',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subtle,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: EditorChrome.editorIslandRim(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasExplicitPath
                      ? relativePath
                      : 'No battle background linked.',
                  style: TextStyle(
                    color: hasExplicitPath ? labelColor : subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $statusLabel',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_encounterBattleBackgroundMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _encounterBattleBackgroundMessage!,
                    style: const TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    CupertinoButton(
                      key: const Key(
                        'gameplay-zone-encounter-background-pick-button',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(1, 30),
                      onPressed: () => _pickEncounterBattleBackground(
                        projectRootPath: projectRootPath,
                      ),
                      child: const Text(
                        'Choose battle background',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      key: const Key(
                        'gameplay-zone-encounter-background-clear-button',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(1, 30),
                      onPressed: hasExplicitPath
                          ? () {
                              setState(() {
                                _encounterBattleBackgroundRelativePath = null;
                                _encounterBattleBackgroundMessage = null;
                              });
                            }
                          : null,
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementModeDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Required Mode',
        valueLabel: _movementModeLabel(_movementMode),
        orderedIds: MovementMode.values.map((m) => m.name).toList(),
        selectedMenuValue: _movementMode.name,
        selectedIdForCheck: _movementMode.name,
        idToLabel: (id) => _movementModeLabel(
          MovementMode.values.firstWhere((m) => m.name == id),
        ),
        onSelected: (id) => setState(() {
          _movementMode = MovementMode.values.firstWhere((m) => m.name == id);
        }),
        tooltip: 'Required movement mode',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<MovementMode>(
          context: context,
          title: 'Required Mode',
          items: MovementMode.values,
          labelOf: _movementModeLabel,
        );
        if (picked != null) setState(() => _movementMode = picked);
      },
      child: Text('Required Mode: ${_movementModeLabel(_movementMode)}'),
    );
  }

  Widget _buildMovementEffectKindDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Effect Kind',
        valueLabel: _movementEffectKindLabel(_movementEffectKind),
        orderedIds: MovementEffectZoneKind.values.map((k) => k.name).toList(),
        selectedMenuValue: _movementEffectKind.name,
        selectedIdForCheck: _movementEffectKind.name,
        idToLabel: (id) => _movementEffectKindLabel(
          MovementEffectZoneKind.values.firstWhere((k) => k.name == id),
        ),
        onSelected: (id) => setState(() {
          _movementEffectKind =
              MovementEffectZoneKind.values.firstWhere((k) => k.name == id);
        }),
        tooltip: 'Movement effect kind',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<MovementEffectZoneKind>(
          context: context,
          title: 'Movement Effect',
          items: MovementEffectZoneKind.values,
          labelOf: _movementEffectKindLabel,
        );
        if (picked != null) setState(() => _movementEffectKind = picked);
      },
      child: Text(
        'Effect: ${_movementEffectKindLabel(_movementEffectKind)}',
      ),
    );
  }

  Widget _buildHazardKindDropdown(BuildContext context, Color accent) {
    if (widget.embedded) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: 'Hazard Kind',
        valueLabel: _hazardKindLabel(_hazardKind),
        orderedIds: HazardKind.values.map((k) => k.name).toList(),
        selectedMenuValue: _hazardKind.name,
        selectedIdForCheck: _hazardKind.name,
        idToLabel: (id) => _hazardKindLabel(
          HazardKind.values.firstWhere((k) => k.name == id),
        ),
        onSelected: (id) => setState(() {
          _hazardKind = HazardKind.values.firstWhere((k) => k.name == id);
        }),
        tooltip: 'Type of environmental hazard',
      );
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      onPressed: () async {
        final picked = await showCupertinoListPicker<HazardKind>(
          context: context,
          title: 'Hazard Kind',
          items: HazardKind.values,
          labelOf: _hazardKindLabel,
        );
        if (picked != null) setState(() => _hazardKind = picked);
      },
      child: Text('Hazard: ${_hazardKindLabel(_hazardKind)}'),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _syncControllers(MapGameplayZone? zone) {
    final fingerprint = zone == null
        ? 'none'
        : '${zone.id}|${zone.name}|${zone.kind.name}'
            '|${zone.area.pos.x}|${zone.area.pos.y}'
            '|${zone.area.size.width}|${zone.area.size.height}'
            '|${zone.priority}'
            '|${zone.encounter?.encounterTableId}|${zone.encounter?.encounterKind.name}|${zone.encounter?.battleBackgroundRelativePath}'
            '|${zone.movement?.requiredMode.name}'
            '|${zone.movementEffect?.effectKind.name}|${zone.movementEffect?.movementCost}'
            '|${zone.hazard?.hazardKind.name}|${zone.hazard?.damagePerStep}'
            '|${zone.special?.scriptKey}';
    if (_boundFingerprint == fingerprint) return;
    _boundFingerprint = fingerprint;

    _idController.text = zone?.id ?? '';
    _nameController.text = zone?.name ?? '';
    _priorityController.text = zone?.priority.toString() ?? '0';
    _selectedKind = zone?.kind ?? GameplayZoneKind.encounter;

    // encounter
    _encounterTableId = zone?.encounter?.encounterTableId;
    _encounterKind = zone?.encounter?.encounterKind ?? EncounterKind.walk;
    _encounterBattleBackgroundRelativePath =
        zone?.encounter?.battleBackgroundRelativePath;
    _encounterBattleBackgroundMessage = null;

    // movement
    _movementMode = zone?.movement?.requiredMode ?? MovementMode.walk;

    // movement effect
    _movementEffectKind =
        zone?.movementEffect?.effectKind ?? MovementEffectZoneKind.slide;
    _movementEffectCost = zone?.movementEffect?.movementCost ?? 1;

    // hazard
    _hazardKind = zone?.hazard?.hazardKind ?? HazardKind.other;
    _hazardDamagePerStep = zone?.hazard?.damagePerStep ?? 0;

    // special
    _scriptKey = zone?.special?.scriptKey ?? '';
  }

  Future<void> _save(BuildContext context, EditorNotifier notifier) async {
    final priority = int.tryParse(_priorityController.text.trim()) ?? 0;

    EncounterZonePayload? encounter;
    MovementZonePayload? movement;
    MovementEffectZonePayload? movementEffect;
    HazardZonePayload? hazard;
    SpecialZonePayload? special;

    switch (_selectedKind) {
      case GameplayZoneKind.encounter:
        encounter = EncounterZonePayload(
          encounterTableId: _encounterTableId,
          encounterKind: _encounterKind,
          battleBackgroundRelativePath: _normalizeOptionalProjectRelativePath(
            _encounterBattleBackgroundRelativePath,
          ),
        );
      case GameplayZoneKind.movement:
        movement = MovementZonePayload(requiredMode: _movementMode);
      case GameplayZoneKind.movementEffect:
        movementEffect = MovementEffectZonePayload(
          effectKind: _movementEffectKind,
          movementCost: _movementEffectCost,
        );
      case GameplayZoneKind.hazard:
        hazard = HazardZonePayload(
          hazardKind: _hazardKind,
          damagePerStep: _hazardDamagePerStep,
        );
      case GameplayZoneKind.special:
      case GameplayZoneKind.custom:
        special = SpecialZonePayload(
          scriptKey: _scriptKey.trim().isEmpty ? null : _scriptKey.trim(),
        );
    }

    notifier.updateSelectedGameplayZone(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      kind: _selectedKind,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  Future<void> _pickEncounterBattleBackground({
    required String? projectRootPath,
  }) async {
    final normalizedProjectRoot = projectRootPath?.trim();
    if (normalizedProjectRoot == null || normalizedProjectRoot.isEmpty) {
      setState(() {
        _encounterBattleBackgroundMessage =
            'A valid project workspace is required before linking a battle background.';
      });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>[
        'png',
        'jpg',
        'jpeg',
        'webp',
        'bmp',
        'gif',
      ],
      withData: false,
    );
    final pickedAbsolutePath = result?.files.single.path?.trim();
    if (pickedAbsolutePath == null || pickedAbsolutePath.isEmpty) {
      return;
    }

    final relativePath = _normalizePickedBattleBackgroundPath(
      projectRootPath: normalizedProjectRoot,
      pickedAbsolutePath: pickedAbsolutePath,
    );
    if (relativePath == null) {
      return;
    }

    setState(() {
      _encounterBattleBackgroundRelativePath = relativePath;
      _encounterBattleBackgroundMessage = null;
    });
  }

  String? _normalizePickedBattleBackgroundPath({
    required String projectRootPath,
    required String pickedAbsolutePath,
  }) {
    final relativePath = normalizeProjectLocalBattleBackgroundPath(
      projectRootPath: projectRootPath,
      pickedAbsolutePath: pickedAbsolutePath,
    );

    if (relativePath == null) {
      setState(() {
        _encounterBattleBackgroundMessage =
            'Only project-local images can be linked to a battle zone.';
      });
      return null;
    }

    return relativePath;
  }

  String? _normalizeOptionalProjectRelativePath(String? rawValue) {
    return normalizeOptionalBattleBackgroundRelativePath(rawValue);
  }

  static IconData _iconForKind(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => CupertinoIcons.leaf_arrow_circlepath,
      GameplayZoneKind.movement => CupertinoIcons.arrow_right_arrow_left,
      GameplayZoneKind.movementEffect => CupertinoIcons.arrow_2_circlepath,
      GameplayZoneKind.hazard => CupertinoIcons.exclamationmark_triangle,
      GameplayZoneKind.special => CupertinoIcons.star,
      GameplayZoneKind.custom => CupertinoIcons.square_stack_3d_up,
    };
  }

  static String _kindLabel(GameplayZoneKind kind) {
    return switch (kind) {
      GameplayZoneKind.encounter => 'Encounter',
      GameplayZoneKind.movement => 'Movement',
      GameplayZoneKind.movementEffect => 'Movement Effect',
      GameplayZoneKind.hazard => 'Hazard',
      GameplayZoneKind.special => 'Special',
      GameplayZoneKind.custom => 'Custom',
    };
  }

  static String _movementModeLabel(MovementMode mode) {
    return switch (mode) {
      MovementMode.walk => 'Walk',
      MovementMode.surf => 'Surf',
      MovementMode.fly => 'Fly',
      MovementMode.cut => 'Cut',
      MovementMode.strength => 'Strength',
      MovementMode.rockSmash => 'Rock Smash',
    };
  }

  static String _movementEffectKindLabel(MovementEffectZoneKind kind) {
    return switch (kind) {
      MovementEffectZoneKind.slide => 'Slide',
      MovementEffectZoneKind.movementCost => 'Movement Cost',
    };
  }

  static String _encounterKindLabel(EncounterKind kind) {
    return switch (kind) {
      EncounterKind.walk => 'Walk (tall grass)',
      EncounterKind.surf => 'Surf',
      EncounterKind.headbutt => 'Headbutt',
      EncounterKind.oldRod => 'Old Rod',
      EncounterKind.goodRod => 'Good Rod',
      EncounterKind.superRod => 'Super Rod',
      EncounterKind.gift => 'Gift',
      EncounterKind.special => 'Special',
    };
  }

  static String _hazardKindLabel(HazardKind kind) {
    return switch (kind) {
      HazardKind.lava => 'Lava',
      HazardKind.poison => 'Poison',
      HazardKind.swamp => 'Swamp',
      HazardKind.pitfall => 'Pitfall',
      HazardKind.other => 'Other',
    };
  }
}

/// Petit séparateur de section avec label.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = CupertinoColors.tertiaryLabel.resolveFrom(context);
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}

````

## 24. Git status final

`git diff --stat` final avant création du rapport :

```text
packages/map_core/lib/src/models/enums.dart        |  20 ++-
packages/map_core/lib/src/models/map_data.dart     |   4 +
.../map_core/lib/src/models/map_data.freezed.dart  |  50 +++++-
packages/map_core/lib/src/models/map_data.g.dart   |   6 +
.../lib/src/models/map_gameplay_zone_payloads.dart |  30 ++++
.../models/map_gameplay_zone_payloads.freezed.dart | 194 +++++++++++++++++++++
.../src/models/map_gameplay_zone_payloads.g.dart   |  21 +++
.../lib/src/operations/map_gameplay_zones.dart     |  38 +++-
.../map_core/lib/src/validation/validators.dart    |  12 ++
.../gameplay_zone_editing_coordinator.dart         |   3 +
.../services/gameplay_zone_editing_service.dart    |   5 +-
.../use_cases/gameplay_zone_use_cases.dart         |   3 +
.../src/features/editor/state/editor_notifier.dart |   4 +
.../src/ui/canvas/map_canvas/map_grid_painter.dart |   1 +
.../ui/panels/gameplay_zone_properties_panel.dart  | 118 +++++++++++--
15 files changed, 481 insertions(+), 28 deletions(-)
```

`git status --short --untracked-files=all` final après création du rapport :

```text
M packages/map_core/lib/src/models/enums.dart
M packages/map_core/lib/src/models/map_data.dart
M packages/map_core/lib/src/models/map_data.freezed.dart
M packages/map_core/lib/src/models/map_data.g.dart
M packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart
M packages/map_core/lib/src/models/map_gameplay_zone_payloads.freezed.dart
M packages/map_core/lib/src/models/map_gameplay_zone_payloads.g.dart
M packages/map_core/lib/src/operations/map_gameplay_zones.dart
M packages/map_core/lib/src/validation/validators.dart
M packages/map_editor/lib/src/application/services/gameplay_zone_editing_coordinator.dart
M packages/map_editor/lib/src/application/services/gameplay_zone_editing_service.dart
M packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart
M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
M packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart
?? packages/map_core/test/map_gameplay_zone_movement_effect_payload_test.dart
?? reports/surface/surface_engine_lot_115_ice_sliding_runtime_source_contract_prep.md
?? reports/surface/surface_engine_lot_116_movement_effect_zone_payload_model.md
```

Le fichier Lot 115 non suivi est préexistant. Le rapport Lot 116 est créé par ce lot.

## 25. Périmètre explicitement non touché

- `map_gameplay` production non modifié : Oui.
- `map_runtime` production non modifié : Oui.
- `map_battle` non modifié : Oui.
- `examples` non modifié : Oui.
- `GameplayMovementEffect` non modifié : Oui.
- `Moved` non modifié : Oui.
- `stepGameplayWorld` non modifié : Oui.
- `GameplayWorldState` non modifié : Oui.
- `PlayableMapGame` non modifié : Oui.
- `SurfaceBehaviorActionMenu` non modifié : Oui.
- `Surface Painter` non modifié hors plomberie générique Gameplay Zone : Oui.
- `EditorNotifier` modifié uniquement pour propagation générique du payload `movementEffect`, justifiée par compilation/édition du nouveau kind : Oui.
- `SurfaceLayer` non modifié : Oui.
- `SurfaceCellPlacement` non modifié : Oui.
- `ProjectManifest` non modifié : Oui.
- Aucun JSON fixture/data ajouté : Oui.
- Generated/build_runner limité à `packages/map_core` : Oui.
- Aucune action editor Ice : Oui.
- Aucun dialog Ice : Oui.
- Aucune glissade codée : Oui.
- Aucun movement effect produit runtime : Oui.
- Aucune migration legacy : Oui.
- Aucun filtre `surfacePresetId` dans `MapGameplayZone` : Oui.

## 26. ctx stats

Commande exécutée :

```bash
ctx stats
```

Résultat :

```text
zsh:1: command not found: ctx
```

Résumé compact : Context Mode indisponible, aucune économie mesurable.

## 27. Limites restantes

- `map_gameplay` ne lit pas encore les zones `GameplayZoneKind.movementEffect`.
- `stepGameplayWorld` ne produit toujours pas `Moved.movementEffect`.
- Aucun runtime ice, aucune glissade, aucun mouvement forcé, aucun coût de mouvement appliqué.
- `MovementEffectZonePayload.slide` ne porte pas encore de direction persistante; la direction pourra venir de l’intent/mouvement entrant dans un lot runtime futur.
- Le panel éditeur expose maintenant un formulaire générique “Movement Effect”, mais il ne constitue pas un workflow Surface Ice no-code.
- `movementCost` est stocké pour tous les payloads par simplicité V0; pour `slide`, il reste non consommé.

## 28. Auto-critique

- Est-ce que `GameplayZoneKind.movementEffect` existe ? Oui.
- Est-ce que `MovementEffectZonePayload` existe ? Oui.
- Est-ce que l’enum core des effects existe ? Oui, `MovementEffectZoneKind`.
- Est-ce que `MapGameplayZone` peut porter `movementEffect` ? Oui.
- Est-ce que JSON encode/decode fonctionne ? Oui, testé par roundtrip.
- Est-ce que les anciens JSON restent compatibles ? Oui, testé sur `encounter`, `movement`, `hazard`.
- Est-ce que les validations acceptent une zone `movementEffect` valide ? Oui.
- Est-ce que les validations rejettent les cas invalides ? Oui, sans payload et `movementCost <= 0`.
- Est-ce que build_runner a été lancé si nécessaire ? Oui, nécessaire pour Freezed/JSON `map_core`.
- Est-ce qu’aucun runtime ice n’est codé ? Oui.
- Est-ce qu’aucun editor ice n’est codé ? Oui.
- Est-ce qu’aucun `map_gameplay` n’est modifié ? Oui, aucune production `map_gameplay` modifiée.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que `map_core` complet passe ? Oui, `+1297`.
- Est-ce que les régressions gameplay passent ? Oui.
- Est-ce que l’analyse ciblée passe ? Oui.
- Est-ce que Context Mode a été utilisé agressivement ? Non, l’outil était indisponible; les commandes shell ont été ciblées.
- Est-ce que `ctx stats` est inclus ? Oui, avec échec `command not found`.
- Est-ce que le contenu complet des fichiers créés/modifiés est copié dans le rapport ? Oui pour les fichiers du lot, sauf le rapport lui-même conformément à l’exception.
- Est-ce qu’un Lot 116-bis est nécessaire ? Non. Le modèle persistant, le JSON, les validations, les tests et les analyses sont en place. Le prochain lot peut porter sur la consommation runtime de cette source.

## 29. Regard critique sur le prompt

Le prompt était très précis et a bien protégé le périmètre : il a évité une glissade codée trop tôt et forcé la séparation entre source persistante `map_core` et effet runtime `map_gameplay`. Deux points de friction pratiques :

- Le Evidence Pack avec contenu complet des fichiers modifiés devient très volumineux dès que Freezed et des fichiers éditeur larges sont touchés. Pour un reviewer humain, ce niveau de preuve est complet mais difficile à parcourir.
- Le nouveau enum `GameplayZoneKind` impose naturellement des adaptations `map_editor` pour compilation; le prompt l’autorisait, mais cela reste un rappel qu’un changement de modèle core a toujours un rayon d’impact UI même sans nouvelle feature produit.
