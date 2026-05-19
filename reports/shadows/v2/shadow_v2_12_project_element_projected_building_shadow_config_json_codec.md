# ShadowV2-12 — Project Element Projected Building Shadow Config JSON Codec V0

## 1. Résumé exécutif

ShadowV2-12 ajoute uniquement le codec JSON manuel de `ProjectElementProjectedBuildingShadowConfig`.

Le codec :

- encode toujours `enabled`, `presetId`, `anchor`, `localOffset` ;
- exige ces quatre champs au decode ;
- accepte `enabled: true` et `enabled: false` sans changer l’exigence de `presetId` ;
- ignore les unknown keys au niveau config ;
- réutilise `encodeProjectedShadowAnchor`, `decodeProjectedShadowAnchor`, `encodeProjectedShadowOffset`, `decodeProjectedShadowOffset` ;
- ne branche rien dans `ProjectElementEntry`, `ProjectManifest`, `MapPlacedElement`, le runtime ou l’éditeur.

## 2. Objectif du lot

Objectif exécuté :

```text
Créer uniquement le codec JSON de ProjectElementProjectedBuildingShadowConfig,
manuel,
testé,
sans effet de bord,
sans intégration ProjectElementEntry.
```

Question centrale traitée :

```text
Comment sérialiser la config d’ombre projetée V2 d’un élément,
sans encore ajouter le champ projectedBuildingShadow à ProjectElementEntry ?
```

## 3. Rappel ShadowV2-11

ShadowV2-11 a créé le codec JSON manuel de `ProjectBuildingShadowPresetCatalog`.

ShadowV2-12 ne modifie pas ce codec et n’ajoute pas d’intégration manifest. Il traite seulement la fiche élément V2 pure créée en ShadowV2-7.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text

```

Interprétation :

- aucun changement local n’était présent au démarrage du lot ShadowV2-12 ;
- les livrables ShadowV2-11 étaient déjà intégrés dans l’état courant du repo local.

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

Décision :

- ShadowV2-8 a validé le design JSON ;
- ShadowV2-9 a implémenté les codecs atomiques ;
- ShadowV2-12 est une implémentation bornée du codec config élément prévu ;
- aucun nouveau design gate bloquant n’a été identifié.

Fichiers audités :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Synthèse d’audit :

- les codecs ShadowV2 récents utilisent `ValidationException` pour les erreurs de forme JSON ;
- `ProjectElementProjectedBuildingShadowConfig` valide déjà `presetId` non vide via `ArgumentError` ;
- les codecs atomiques anchor/offset gèrent les ratios, nombres finis et unknown keys ;
- `map_core.dart` exporte déjà les codecs manuels ShadowV2 publics.

## 6. Fichiers créés / modifiés

### Créés

```text
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
reports/shadows/v2/shadow_v2_12_project_element_projected_building_shadow_config_json_codec.md
```

### Modifiés

```text
packages/map_core/lib/map_core.dart
```

### Supprimés

```text
Aucun
```

### Generated files

```text
Aucun
```

### Fichiers Selbrume

```text
Aucun fichier Selbrume modifié
```

## 7. Codec créé

Fichier :

```text
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
```

Fonctions créées :

```dart
Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
  ProjectElementProjectedBuildingShadowConfig config,
)

ProjectElementProjectedBuildingShadowConfig
    decodeProjectElementProjectedBuildingShadowConfig(Object? json)
```

## 8. JSON canonique

Avec `enabled: true` :

```json
{
  "enabled": true,
  "presetId": "short-west-building-shadow",
  "anchor": {
    "xRatio": 0.5,
    "yRatio": 0.98
  },
  "localOffset": {
    "x": 0,
    "y": 0
  }
}
```

Avec `enabled: false` :

```json
{
  "enabled": false,
  "presetId": "short-west-building-shadow",
  "anchor": {
    "xRatio": 0.5,
    "yRatio": 0.98
  },
  "localOffset": {
    "x": 0,
    "y": 0
  }
}
```

## 9. Champs requis / optionnels

Champs requis au decode :

```text
enabled
presetId
anchor
localOffset
```

Champs optionnels :

```text
Aucun
```

Defaults silencieux :

```text
Aucun
```

Le codec ne crée pas de default `enabled: true`, pas de default anchor, pas de default offset, et pas de `presetId` magique.

## 10. Stratégie enabled false

Décision appliquée :

```text
enabled=false reste une config complète.
presetId reste requis.
anchor reste requis.
localOffset reste requis.
```

Raison :

```text
Le modèle actuel permet de conserver une intention authorée désactivée,
mais ne crée pas de forme disabled incomplète.
```

## 11. Stratégie unknown keys

Décision appliquée :

- unknown keys au niveau config : ignorées au decode ;
- unknown keys dans `anchor` : ignorées par `decodeProjectedShadowAnchor` ;
- unknown keys dans `localOffset` : ignorées par `decodeProjectedShadowOffset` ;
- encode ne réémet aucune unknown key.

## 12. Stratégie d’erreurs

Conventions appliquées :

- `ValidationException` pour forme JSON invalide, type invalide, champ requis manquant ;
- `ArgumentError` laissé au modèle pour `presetId` vide ;
- `ValidationException` laissé aux value objects pour anchor/offset invalides.

Cas rejetés par les tests :

- `enabled` absent ;
- `presetId` absent ;
- `anchor` absent ;
- `localOffset` absent ;
- `enabled` non-bool ;
- `presetId` non-string ;
- `anchor` non-map ;
- `localOffset` non-map ;
- `presetId` vide ;
- anchor ratio invalide ;
- localOffset non fini.

## 13. Réutilisation des codecs atomiques

Le codec config élément réutilise directement :

```dart
encodeProjectedShadowAnchor(config.anchor)
decodeProjectedShadowAnchor(...)
encodeProjectedShadowOffset(config.localOffset)
decodeProjectedShadowOffset(...)
```

Il ne duplique pas la logique de parsing :

- `anchor.xRatio` ;
- `anchor.yRatio` ;
- `localOffset.x` ;
- `localOffset.y`.

## 14. Tests ajoutés

Fichier :

```text
packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Couverture ajoutée :

- encode canonique enabled true ;
- encode canonique enabled false ;
- decode canonique enabled true ;
- decode canonique enabled false ;
- round-trip config -> JSON -> config ;
- round-trip JSON -> config -> JSON canonique ;
- unknown keys ignorées ;
- champs requis manquants rejetés ;
- types invalides rejetés ;
- valeurs invalides déléguées au modèle/value objects.

## 15. Résultats des tests

### Test rouge TDD

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Sortie rouge observée avant implémentation :

```text
00:00 +0: loading test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
00:00 +0 -1: loading test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart [E]
Failed to load "test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart":
test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart:10:9: Error: Method not found: 'encodeProjectElementProjectedBuildingShadowConfig'.
        encodeProjectElementProjectedBuildingShadowConfig(config),
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart:25:22: Error: Method not found: 'decodeProjectElementProjectedBuildingShadowConfig'.
      final config = decodeProjectElementProjectedBuildingShadowConfig(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### Test ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
00:00 +0: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:00 +1: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:00 +1: ProjectElementProjectedBuildingShadowConfig JSON codec encodes enabled false while keeping explicit preset and placement
00:00 +2: ProjectElementProjectedBuildingShadowConfig JSON codec encodes enabled false while keeping explicit preset and placement
00:00 +2: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true
00:00 +3: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true
00:00 +3: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled false
00:00 +4: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled false
00:00 +4: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config instances through canonical JSON
00:00 +5: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config instances through canonical JSON
00:00 +5: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectElementProjectedBuildingShadowConfig JSON codec rejects missing required fields
00:00 +7: ProjectElementProjectedBuildingShadowConfig JSON codec rejects missing required fields
00:00 +7: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid field types
00:00 +8: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid field types
00:00 +8: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid values delegated to model and value objects
00:00 +9: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid values delegated to model and value objects
00:00 +9: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +113: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

## 16. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Sortie :

```text
Analyzing project_element_projected_building_shadow_config_json_codec.dart, project_element_projected_building_shadow_config_json_codec_test.dart...
No issues found!
```

## 17. Export public

Export ajouté dans `packages/map_core/lib/map_core.dart` :

```dart
export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
```

Raison :

- les codecs atomiques V2-9, preset V2-10 et catalogue V2-11 sont exportés publiquement ;
- le codec config élément suit cette convention.

## 18. Ce qui n’a volontairement pas été créé

Non créés :

- intégration `ProjectElementEntry` ;
- champ `projectedBuildingShadow` sur élément ;
- intégration `ProjectManifest` ;
- intégration `MapPlacedElement` ;
- `MapPlacedElementProjectedShadowOverride` ;
- codec `ProjectManifest` ;
- migrations JSON ;
- runtime ;
- éditeur ;
- renderer ;
- screenshots/baselines ;
- generated files.

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : les nouveaux fichiers non suivis sont listés dans `git status final`.

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
?? packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
?? reports/shadows/v2/shadow_v2_12_project_element_projected_building_shadow_config_json_codec.md
```

## 23. Risques / réserves

- Le codec est strict : aucun default silencieux n’est appliqué. Les futurs codecs `ProjectElementEntry` ou `ProjectManifest` devront gérer explicitement l’absence du champ `projectedBuildingShadow`.
- `enabled=false` exige encore `presetId`, `anchor` et `localOffset`, conformément au modèle V0. Si l’UX veut plus tard une forme disabled incomplète, ce sera un changement de modèle séparé.
- Les unknown keys sont ignorées et non réémises. C’est cohérent avec les codecs ShadowV2 actuels mais ne préserve pas des extensions non connues.

## 24. Auto-critique

Le lot reste bien borné : il crée le codec de la fiche élément sans ajouter de champ persistant. La seule modification hors nouveau fichier est l’export public dans `map_core.dart`, cohérent avec les codecs V2 précédents.

Le point à surveiller au prochain lot est la frontière d’intégration : il ne faudra pas laisser le futur champ `projectedBuildingShadow` produire une config par défaut. L’absence doit rester `null`.

## 25. Regard critique sur le prompt

Le prompt force correctement la discipline : encoder la fiche sans la ranger dans `ProjectElementEntry`. Cette séparation évite d’activer trop tôt une sérialisation persistante d’ombres projetées, et garde la règle produit intacte :

```text
Le runtime consomme des données authorées.
L’éditeur aide à authorer.
Le runtime ne devine jamais.
```

## 26. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-13 — Projected Building Shadow Manifest / Element Integration Design Gate
```

Pourquoi maintenant :

- les value objects existent ;
- le preset existe ;
- le catalogue existe ;
- la config élément existe ;
- les codecs atomiques, preset, catalogue et config élément existent ;
- avant d’ajouter `projectedBuildingShadow` à `ProjectElementEntry` ou `projectedBuildingShadowCatalog` à `ProjectManifest`, il faut un design gate d’intégration pour verrouiller absence/null/empty, migration et golden JSON.

## Code complet des fichiers créés/modifiés

### packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'projected_shadow_value_object_json_codecs.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

Map<String, Object?> _requiredObject(Object? json, String label) {
  if (json is! Map) {
    throw ValidationException(
      '$label JSON must be an Object, got ${json.runtimeType}',
    );
  }
  return _stringKeyMapFrom(json);
}

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldKey is required');
  }
  return json[key];
}

bool _requiredBool(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! bool) {
    throw ValidationException('$fieldKey must be a bool');
  }
  return value;
}

String _requiredString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

/// Encodes an element-level authored projected building shadow config.
Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
  ProjectElementProjectedBuildingShadowConfig config,
) {
  return <String, dynamic>{
    'enabled': config.enabled,
    'presetId': config.presetId,
    'anchor': encodeProjectedShadowAnchor(config.anchor),
    'localOffset': encodeProjectedShadowOffset(config.localOffset),
  };
}

/// Decodes an element-level authored projected building shadow config.
///
/// All fields are required, including `presetId` when `enabled` is false.
/// Unknown keys are ignored; anchor and offset are delegated to the ShadowV2
/// atomic value-object codecs.
ProjectElementProjectedBuildingShadowConfig
    decodeProjectElementProjectedBuildingShadowConfig(Object? json) {
  final map = _requiredObject(
    json,
    'ProjectElementProjectedBuildingShadowConfig',
  );
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: _requiredBool(
      map,
      'enabled',
      'ProjectElementProjectedBuildingShadowConfig.enabled',
    ),
    presetId: _requiredString(
      map,
      'presetId',
      'ProjectElementProjectedBuildingShadowConfig.presetId',
    ),
    anchor: decodeProjectedShadowAnchor(
      _valueForRequiredKey(
        map,
        'anchor',
        'ProjectElementProjectedBuildingShadowConfig.anchor',
      ),
    ),
    localOffset: decodeProjectedShadowOffset(
      _valueForRequiredKey(
        map,
        'localOffset',
        'ProjectElementProjectedBuildingShadowConfig.localOffset',
      ),
    ),
  );
}
```

### packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig JSON codec', () {
    test('encodes canonical config with enabled true', () {
      final config = _config();

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(),
      );
    });

    test('encodes enabled false while keeping explicit preset and placement',
        () {
      final config = _config(enabled: false);

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(enabled: false),
      );
    });

    test('decodes canonical config with enabled true', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(),
      );

      expect(config.enabled, isTrue);
      expect(config.presetId, 'short-west-building-shadow');
      expect(config.anchor, ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98));
      expect(config.localOffset, ProjectedShadowOffset(x: 0, y: 0));
    });

    test('decodes canonical config with enabled false', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(enabled: false),
      );

      expect(config, _config(enabled: false));
    });

    test('round-trips config instances through canonical JSON', () {
      final config = _config(
        enabled: false,
        presetId: 'long-east-building-shadow',
        anchorXRatio: 0.25,
        anchorYRatio: 0.9,
        offsetX: 3,
        offsetY: -2.5,
      );

      expect(
        decodeProjectElementProjectedBuildingShadowConfig(
          encodeProjectElementProjectedBuildingShadowConfig(config),
        ),
        config,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _configJson(
        localOffset: _offsetJson(x: 3, y: -2.5),
      )
        ..['futureField'] = 'ignored'
        ..['anchor'] = (_anchorJson()..['futureAnchorField'] = true)
        ..['localOffset'] =
            (_offsetJson(x: 3, y: -2.5)..['futureOffsetField'] = true);

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(
          decodeProjectElementProjectedBuildingShadowConfig(json),
        ),
        _configJson(localOffset: _offsetJson(x: 3, y: -2.5)),
      );
    });

    test('rejects missing required fields', () {
      for (final field in <String>[
        'enabled',
        'presetId',
        'anchor',
        'localOffset',
      ]) {
        expect(
          () => decodeProjectElementProjectedBuildingShadowConfig(
            _without(_configJson(), field),
          ),
          throwsA(isA<ValidationException>()),
          reason: '$field should be required',
        );
      }
    });

    test('rejects invalid field types', () {
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(enabled: 'yes'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(presetId: 42),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(anchor: 'south-door'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(localOffset: 'origin'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid values delegated to model and value objects', () {
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(presetId: ''),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(
            anchor: _anchorJson(xRatio: 1.01),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(
            localOffset: _offsetJson(x: double.nan),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'short-west-building-shadow',
  double anchorXRatio = 0.5,
  double anchorYRatio = 0.98,
  double offsetX = 0,
  double offsetY = 0,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(
      xRatio: anchorXRatio,
      yRatio: anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: offsetX, y: offsetY),
  );
}

Map<String, Object?> _configJson({
  Object? enabled = true,
  Object? presetId = 'short-west-building-shadow',
  Object? anchor,
  Object? localOffset,
}) {
  return <String, Object?>{
    'enabled': enabled,
    'presetId': presetId,
    'anchor': anchor ?? _anchorJson(),
    'localOffset': localOffset ?? _offsetJson(),
  };
}

Map<String, Object?> _anchorJson({
  Object? xRatio = 0.5,
  Object? yRatio = 0.98,
}) {
  return <String, Object?>{
    'xRatio': xRatio,
    'yRatio': yRatio,
  };
}

Map<String, Object?> _offsetJson({
  Object? x = 0,
  Object? y = 0,
}) {
  return <String, Object?>{
    'x': x,
    'y': y,
  };
}

Map<String, Object?> _without(Map<String, Object?> source, String key) {
  return Map<String, Object?>.from(source)..remove(key);
}
```

### packages/map_core/lib/map_core.dart

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_path_pattern_preset.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/shadow.dart';
export 'src/models/shadow_catalog.dart';
export 'src/models/projected_building_shadow.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/terrain_preset_subtile_for_map_cell.dart';
export 'src/operations/terrain_preset_variant_pick.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/path_pattern_visual_resolution.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/project_element_shadow_config_json_codec.dart';
export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
export 'src/operations/project_building_shadow_preset_json_codec.dart';
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
export 'src/operations/projected_shadow_value_object_json_codecs.dart';
export 'src/operations/static_shadow_family_json_codec.dart';
export 'src/operations/static_shadow_footprint_config_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
export 'src/operations/default_shadow_profiles.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/static_shadow_geometry.dart';
export 'src/operations/static_shadow_family_projection.dart';
export 'src/operations/static_shadow_projection_geometry.dart';
export 'src/operations/static_shadow_contact_ledge_geometry.dart';
export 'src/operations/element_auto_shadow_policy.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/operations/element_collision_profile_normalizer.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
export 'src/operations/environment_authoring_diagnostics.dart';
export 'src/operations/shadow_authoring_diagnostics.dart';
export 'src/operations/shadow_config_resolver.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
```

## Diff de map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 4511f4b9..78feeccd 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -43,6 +43,7 @@ export 'src/operations/path_center_pattern_resolver.dart';
 export 'src/operations/path_pattern_visual_resolution.dart';
 export 'src/operations/project_path_preset_center_pattern_adapter.dart';
 export 'src/operations/project_element_shadow_config_json_codec.dart';
+export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
 export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
 export 'src/operations/project_building_shadow_preset_json_codec.dart';
 export 'src/operations/project_manifest_shadow_catalog_operations.dart';
```
