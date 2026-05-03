# Environment Studio Lot 5 — ProjectManifest Environment Presets V0

## 1. Résumé exécutif

Ajout du champ **`environmentPresets`** au **`ProjectManifest`** (liste d’**`EnvironmentPreset`**), codec JSON manuel externe aligné sur **`pathPatternPresets`** et **`EnvironmentLayerContent`** (review), opérations pures calquées sur **`project_manifest_path_pattern_preset_operations`**. **`dart run build_runner`** régénère **`project_manifest.freezed.dart`** / **`.g.dart`**. Suite **`map_core`** : **`+1287`** tests verts ; **`dart analyze`** sans problème. Aucune modification **`MapLayer`**, **`map_editor`**, **`map_runtime`**.

## 2. Périmètre du lot

Manifest + codec + opérations + tests **`map_core`** uniquement. Hors UI, générateur, **`map_gameplay`**, **`map_battle`**, fixtures projet.

## 3. Audit initial des patterns ProjectManifest

- **`pathPatternPresets`** : **`@JsonKey`** + **`decodeProjectPathPatternPresets`** / **`encodeProjectPathPatternPresets`** ; liste absente/`null` ⇒ **`[]`** ; erreurs liste → **`ValidationException`** (ici **`FormatException`** pour **`environmentPresets`** conformément au prompt codec).
- **`surfaceCatalog`** : wrappers **`_projectSurfaceCatalogFromJson`**.
- **Opérations** : **`project_manifest_path_pattern_preset_operations.dart`** — **`read*`**, **`replace*`**, **`upsert*`**, **`remove*`**, **`clear*`**, **`ValidationException`** pour doublons d’id, **`ArgumentError`** pour id vide sur remove.
- Ce lot reproduit ce schéma pour **`environmentPresets`** avec **`decodeEnvironmentPresets`** / **`encodeEnvironmentPresets`**.

## 4. Décisions JSON EnvironmentPreset

- Clés requises : **`id`**, **`name`**, **`templateId`**, **`palette`**, **`defaultParams`**, **`sortOrder`**.
- **`categoryId`** : absent/`null` ⇒ **`null`** ; sinon **`String`**.
- **`collisionMode`** palette : chaînes **`useElementDefault`** / **`forceEnabled`** / **`forceDisabled`** ; absent/`null` ⇒ **`useElementDefault`**.
- **`defaultParams`** : même strictesse **`EnvironmentGenerationParams`** que le codec layer (**`minSpacingCells`** littéral **`int`** JSON).
- Liste manifeste : **`decodeEnvironmentPresets`** rejette les **ids dupliqués** dans le JSON (**`FormatException`**), en plus des **`ValidationException`** sur **`replace`** / état corrompu **`upsert`**.

## 5. Modifications ProjectManifest

Import **`environment.dart`** et **`environment_preset_json_codec.dart`** ; champ **`@Default([])`** + **`@JsonKey(name: 'environmentPresets', ...)`** entre **`pathPatternPresets`** et **`encounterTables`**.

## 6. Opérations ProjectManifest ajoutées

Voir **`project_manifest_environment_preset_operations.dart`** : **`readProjectEnvironmentPresets`**, **`hasProjectEnvironmentPresets`**, **`findProjectEnvironmentPresetById`**, **`replaceProjectEnvironmentPresets`**, **`upsertProjectEnvironmentPreset`**, **`removeProjectEnvironmentPresetById`**, **`clearProjectEnvironmentPresets`**.

## 7. Exports publics

**`map_core.dart`** exporte **`environment_preset_json_codec.dart`** et **`project_manifest_environment_preset_operations.dart`**.

## 8. Pourquoi aucun MapLayer / UI / générateur dans ce lot

Périmètre manifest uniquement : référence **`presetId`** sur carte reste hors scope ; pas de **`MapPlacedElement`** ni Studio.

## 9. Fichiers modifiés

- **`packages/map_core/lib/src/models/project_manifest.dart`** (édité à la main)
- **`packages/map_core/lib/src/models/project_manifest.freezed.dart`**, **`.g.dart`** (build_runner)
- **`packages/map_core/lib/src/operations/environment_preset_json_codec.dart`** (nouveau)
- **`packages/map_core/lib/src/operations/project_manifest_environment_preset_operations.dart`** (nouveau)
- **`packages/map_core/lib/map_core.dart`**
- **`packages/map_core/test/environment_preset_json_codec_test.dart`**
- **`packages/map_core/test/project_manifest_environment_presets_test.dart`**
- **`reports/forest/environment_studio_lot_5_project_manifest_environment_presets.md`** (ce fichier)

## 10. Tests ajoutés

- **`environment_preset_json_codec_test.dart`** : decode/encode/roundtrip, **`collisionMode`**, tags, entiers stricts, densités, liste doublons ids, etc.
- **`project_manifest_environment_presets_test.dart`** : **`fromJson`** défauts, **`toJson`**, erreurs manifeste, toutes les opérations.

## 11. Commandes exécutées

```bash
cd packages/map_core
dart format lib/src/models/project_manifest.dart \
  lib/src/operations/environment_preset_json_codec.dart \
  lib/src/operations/project_manifest_environment_preset_operations.dart \
  lib/map_core.dart \
  test/environment_preset_json_codec_test.dart \
  test/project_manifest_environment_presets_test.dart
dart run build_runner build --delete-conflicting-outputs
dart analyze lib/src/models/project_manifest.dart lib/src/operations/environment_preset_json_codec.dart \
  lib/src/operations/project_manifest_environment_preset_operations.dart lib/map_core.dart \
  test/environment_preset_json_codec_test.dart test/project_manifest_environment_presets_test.dart
dart analyze
dart test test/environment_preset_json_codec_test.dart --reporter expanded
dart test test/project_manifest_environment_presets_test.dart --reporter expanded
dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart \
  test/environment_layer_content_json_codec_test.dart test/environment_layer_map_layer_integration_test.dart --reporter expanded
dart test --reporter expanded
```

## 12. Résultats des commandes

### `dart analyze` (ciblé puis package)

```
Analyzing project_manifest.dart, environment_preset_json_codec.dart, project_manifest_environment_preset_operations.dart, map_core.dart, environment_preset_json_codec_test.dart, project_manifest_environment_presets_test.dart...
No issues found!
Analyzing map_core...
No issues found!
```

### Tests ciblés Lot 5 (expanded, sans ANSI)

```
00:00 +0: loading test/environment_preset_json_codec_test.dart
00:00 +0: EnvironmentPreset JSON codec decode preset complet
00:00 +1: EnvironmentPreset JSON codec encode preset complet
00:00 +2: EnvironmentPreset JSON codec roundtrip preset complet
00:00 +3: EnvironmentPreset JSON codec decode categoryId absent/null => null
00:00 +4: EnvironmentPreset JSON codec decode collisionMode absent/null => useElementDefault
00:00 +5: EnvironmentPreset JSON codec decode collisionMode inconnu => FormatException
00:00 +6: EnvironmentPreset JSON codec decode tags absent/null => set vide
00:00 +7: EnvironmentPreset JSON codec decode tag non-string => FormatException
00:00 +8: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException
00:00 +9: EnvironmentPreset JSON codec decode weight double => FormatException
00:00 +10: EnvironmentPreset JSON codec decode sortOrder double => FormatException
00:00 +11: EnvironmentPreset JSON codec decode minSpacingCells double => FormatException
00:00 +12: EnvironmentPreset JSON codec decode density hors [0,1] => FormatException
00:00 +13: EnvironmentPreset JSON codec decode palette vide => FormatException via modèle
00:00 +14: EnvironmentPreset JSON codec decode duplicate palette elementId => FormatException via modèle
00:00 +15: EnvironmentPreset JSON codec json non-map preset => FormatException
00:00 +16: EnvironmentPreset JSON codec decodeEnvironmentPresets duplicate preset ids => FormatException
00:00 +17: decodeEnvironmentGenerationParamsJson accepte int pour densités
00:00 +18: All tests passed!
```

```
00:00 +0: loading test/project_manifest_environment_presets_test.dart
00:00 +0: ProjectManifest environmentPresets JSON fromJson sans environmentPresets => []
00:00 +1: ProjectManifest environmentPresets JSON fromJson avec environmentPresets null => []
00:00 +2: ProjectManifest environmentPresets JSON fromJson avec environmentPresets complet => liste
00:00 +3: ProjectManifest environmentPresets JSON toJson inclut environmentPresets
00:00 +4: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet
00:00 +5: ProjectManifest environmentPresets JSON environmentPresets non-list => FormatException
00:00 +6: ProjectManifest environmentPresets JSON environmentPresets avec item invalide => FormatException
00:00 +7: project_manifest_environment_preset_operations readProjectEnvironmentPresets retourne la liste
00:00 +8: project_manifest_environment_preset_operations hasProjectEnvironmentPresets false/true
00:00 +9: project_manifest_environment_preset_operations findProjectEnvironmentPresetById trouve / trim / null
00:00 +10: project_manifest_environment_preset_operations replaceProjectEnvironmentPresets remplace et ordre
00:00 +11: project_manifest_environment_preset_operations replaceProjectEnvironmentPresets refuse doublons
00:00 +12: project_manifest_environment_preset_operations upsert ajoute ou remplace même position
00:00 +13: project_manifest_environment_preset_operations upsert refuse doublons préexistants dans le manifest
00:00 +14: project_manifest_environment_preset_operations remove supprime / inconnu no-op / id vide erreur
00:00 +15: project_manifest_environment_preset_operations clearProjectEnvironmentPresets vide la liste
00:00 +16: All tests passed!
```

### Régressions Environment (fichiers demandés)

```
00:00 +0: loading test/environment_core_models_test.dart
00:00 +0: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item
00:00 +1: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item
00:00 +2: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +3: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +4: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +5: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +6: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +7: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +8: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +9: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +10: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +11: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +12: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +13: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +14: test/environment_core_models_test.dart: EnvironmentPaletteItem tags are immutable
00:00 +15: test/environment_core_models_test.dart: EnvironmentPaletteItem tags are immutable
00:00 +16: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +17: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +18: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +19: test/environment_layer_content_test.dart: EnvironmentLayerContent duplicate area ids rejects duplicate area id
00:00 +20: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +21: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +22: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +23: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +24: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +25: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaCount
00:00 +26: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +27: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +28: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +29: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +30: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +31: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +32: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +33: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +34: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +35: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +36: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +37: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +38: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +39: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +40: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +41: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +42: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +43: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +44: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +45: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +46: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +47: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +48: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +49: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +50: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +51: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +52: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +53: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +54: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +55: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +56: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +57: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +58: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +59: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +60: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +61: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +62: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal
00:00 +63: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal
00:00 +64: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal
00:00 +65: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +66: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +67: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +68: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +69: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +70: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +71: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +72: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +73: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +74: test/environment_core_models_test.dart: EnvironmentAreaMask equality order-sensitive on cells
00:00 +75: test/environment_core_models_test.dart: EnvironmentAreaMask equality order-sensitive on cells
00:00 +76: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment fromJson sans content => content vide
00:00 +77: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds string vide => FormatException
00:00 +78: test/environment_core_models_test.dart: EnvironmentArea accepts valid area
00:00 +79: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment copyWith préserve content et properties si non passés
00:00 +80: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment copyWith préserve content et properties si non passés
00:00 +81: test/environment_core_models_test.dart: EnvironmentArea rejects empty id
00:00 +82: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict areas item non-map => FormatException
00:00 +83: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +84: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +85: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +86: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +87: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +88: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +89: test/environment_core_models_test.dart: EnvironmentArea generatedPlacementIds defensive copy and immutable
00:00 +90: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment insertIndex comme autres layers non-path
00:00 +91: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment insertIndex comme autres layers non-path
00:00 +92: test/environment_core_models_test.dart: EnvironmentArea rejects duplicate placement ids
00:00 +93: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent remplace content et conserve méta
00:00 +94: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent remplace content et conserve méta
00:00 +95: test/environment_core_models_test.dart: EnvironmentArea value equality
00:00 +96: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layerId vide
00:00 +97: test/environment_core_models_test.dart: EnvironmentPreset accepts valid preset
00:00 +98: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layer inconnu
00:00 +99: test/environment_core_models_test.dart: EnvironmentPreset rejects empty id name templateId
00:00 +100: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layer non EnvironmentLayer
00:00 +101: test/environment_core_models_test.dart: EnvironmentPreset rejects empty palette
00:00 +102: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent ne modifie pas placedElements
00:00 +103: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent ne modifie pas placedElements
00:00 +104: test/environment_core_models_test.dart: EnvironmentPreset rejects duplicate elementId in palette
00:00 +105: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +106: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +107: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +108: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +109: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +110: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer targetTileLayerId valide si TileLayer existe
00:00 +111: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si targetTileLayerId inconnu
00:00 +112: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si targetTileLayerId pointe vers le layer environment lui-même
00:00 +113: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer
00:00 +114: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si masque ne correspond pas à la taille carte
00:00 +115: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment JSON edge cases fromJson avec content null => emptyContent
00:00 +116: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment JSON edge cases properties roundtrip
00:00 +117: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées
00:00 +118: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer rétrécit la carte : cellules hors carte supprimées
00:00 +119: All tests passed!
```

### Suite complète `dart test --reporter expanded`

Ligne finale : **`00:03 +1287: All tests passed!`**

## 13. Git status initial et final

**Final** (après implémentation Lot 5) :

```
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
?? packages/map_core/lib/src/operations/environment_preset_json_codec.dart
?? packages/map_core/lib/src/operations/project_manifest_environment_preset_operations.dart
?? packages/map_core/test/environment_preset_json_codec_test.dart
?? packages/map_core/test/project_manifest_environment_presets_test.dart
```

**Note** : l’état initial du worktree dépend des commits locaux ; au moment de la rédaction, seuls les fichiers Lot 5 apparaissaient modifiés/non suivis pour **`map_core`**.

## 14. Contenu complet des fichiers écrits à la main

### `environment_preset_json_codec.dart`

```dart
// JSON codec manuel (Lot Environment-5) — [EnvironmentPreset] / [EnvironmentPaletteItem] /
// [EnvironmentGenerationParams] pour [ProjectManifest.environmentPresets].
// Aucun toJson/fromJson sur les modèles Environment (classes finales hors Freezed).

import '../models/environment.dart';

Map<String, dynamic> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, dynamic>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value,
      ),
    ),
  );
}

void _assertNoDuplicatePresetIds(List<EnvironmentPreset> presets) {
  final seen = <String>{};
  for (final p in presets) {
    if (!seen.add(p.id)) {
      throw FormatException(
        'environmentPresets contains duplicate EnvironmentPreset id: ${p.id}',
      );
    }
  }
}

/// Décodage manifeste : clé absente ou `null` => liste vide.
List<EnvironmentPreset> decodeEnvironmentPresets(Object? json) {
  if (json == null) {
    return const [];
  }
  if (json is! List) {
    throw FormatException(
      'environmentPresets must be a List, got ${json.runtimeType}',
    );
  }
  final out = <EnvironmentPreset>[];
  for (var i = 0; i < json.length; i++) {
    final item = json[i];
    if (item is! Map) {
      throw FormatException(
        'environmentPresets[$i] must be a JSON object, got ${item.runtimeType}',
      );
    }
    out.add(decodeEnvironmentPreset(_stringKeyMapFrom(item)));
  }
  _assertNoDuplicatePresetIds(out);
  return out;
}

/// Encodage manifeste : liste de presets prête pour `project.json`.
List<Map<String, dynamic>> encodeEnvironmentPresets(
  List<EnvironmentPreset> presets,
) {
  return [
    for (final p in presets) encodeEnvironmentPreset(p),
  ];
}

/// JSON objet unique ; `null` est refusé (utiliser [decodeEnvironmentPresets] pour liste).
EnvironmentPreset decodeEnvironmentPreset(Object? json) {
  if (json == null || json is! Map) {
    throw FormatException(
      'EnvironmentPreset JSON must be a Map, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);

  void requireKeys() {
    for (final key in <String>[
      'id',
      'name',
      'templateId',
      'palette',
      'defaultParams',
      'sortOrder',
    ]) {
      if (!map.containsKey(key)) {
        throw FormatException(
            'EnvironmentPreset JSON missing required key "$key"');
      }
    }
  }

  requireKeys();

  final id = map['id'];
  final name = map['name'];
  final templateId = map['templateId'];
  if (id is! String || name is! String || templateId is! String) {
    throw FormatException(
      'EnvironmentPreset id, name, templateId must be non-null Strings',
    );
  }

  final rawPalette = map['palette'];
  if (rawPalette is! List) {
    throw FormatException(
      'EnvironmentPreset.palette must be a List, got ${rawPalette.runtimeType}',
    );
  }
  final palette = <EnvironmentPaletteItem>[];
  for (var i = 0; i < rawPalette.length; i++) {
    final e = rawPalette[i];
    palette.add(decodeEnvironmentPaletteItem(e));
  }

  final rawDefault = map['defaultParams'];
  if (rawDefault is! Map) {
    throw FormatException(
      'EnvironmentPreset.defaultParams must be a Map, got ${rawDefault.runtimeType}',
    );
  }
  final defaultParams = decodeEnvironmentGenerationParamsJson(rawDefault);

  final rawCategory = map['categoryId'];
  final String? categoryId;
  if (rawCategory == null) {
    categoryId = null;
  } else if (rawCategory is String) {
    categoryId = rawCategory;
  } else {
    throw FormatException(
      'EnvironmentPreset.categoryId must be a String or null, got ${rawCategory.runtimeType}',
    );
  }

  final sortOrder = _requireIntStrict(
    Map<String, dynamic>.from(map),
    'sortOrder',
    fieldLabel: 'EnvironmentPreset.sortOrder',
  );

  try {
    return EnvironmentPreset(
      id: id,
      name: name,
      templateId: templateId,
      palette: palette,
      defaultParams: defaultParams,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentPreset: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentPreset(EnvironmentPreset preset) {
  final out = <String, dynamic>{
    'id': preset.id,
    'name': preset.name,
    'templateId': preset.templateId,
    'palette': [
      for (final item in preset.palette) encodeEnvironmentPaletteItem(item),
    ],
    'defaultParams':
        encodeEnvironmentGenerationParamsJson(preset.defaultParams),
    'sortOrder': preset.sortOrder,
  };
  if (preset.categoryId != null) {
    out['categoryId'] = preset.categoryId;
  }
  return out;
}

EnvironmentPaletteItem decodeEnvironmentPaletteItem(Object? json) {
  if (json == null || json is! Map) {
    throw FormatException(
      'EnvironmentPaletteItem JSON must be a Map, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);
  if (!map.containsKey('elementId') || !map.containsKey('weight')) {
    throw FormatException(
      'EnvironmentPaletteItem JSON missing elementId or weight',
    );
  }
  final elementId = map['elementId'];
  final weightRaw = map['weight'];
  if (elementId is! String) {
    throw FormatException('EnvironmentPaletteItem.elementId must be a String');
  }
  if (weightRaw is! int) {
    throw FormatException(
      'EnvironmentPaletteItem.weight must be a strict int (got ${weightRaw.runtimeType})',
    );
  }

  final rawMode = map['collisionMode'];
  final EnvironmentCollisionMode collisionMode;
  if (rawMode == null) {
    collisionMode = EnvironmentCollisionMode.useElementDefault;
  } else if (rawMode is String) {
    collisionMode = _decodeCollisionMode(rawMode);
  } else {
    throw FormatException(
      'EnvironmentPaletteItem.collisionMode must be a String or null',
    );
  }

  final rawTags = map['tags'];
  final Set<String>? tags;
  if (rawTags == null) {
    tags = null;
  } else if (rawTags is List) {
    tags = <String>{};
    for (var i = 0; i < rawTags.length; i++) {
      final t = rawTags[i];
      if (t is! String) {
        throw FormatException(
          'EnvironmentPaletteItem.tags[$i] must be a String',
        );
      }
      tags.add(t);
    }
  } else {
    throw FormatException(
      'EnvironmentPaletteItem.tags must be a List or null, got ${rawTags.runtimeType}',
    );
  }

  try {
    return EnvironmentPaletteItem(
      elementId: elementId,
      weight: weightRaw,
      collisionMode: collisionMode,
      tags: tags,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentPaletteItem: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentPaletteItem(EnvironmentPaletteItem item) {
  final tagsList = item.tags.toList()..sort();
  return <String, dynamic>{
    'elementId': item.elementId,
    'weight': item.weight,
    'collisionMode': _collisionModeToJson(item.collisionMode),
    'tags': tagsList,
  };
}

EnvironmentCollisionMode _decodeCollisionMode(String value) {
  switch (value) {
    case 'useElementDefault':
      return EnvironmentCollisionMode.useElementDefault;
    case 'forceEnabled':
      return EnvironmentCollisionMode.forceEnabled;
    case 'forceDisabled':
      return EnvironmentCollisionMode.forceDisabled;
    default:
      throw FormatException(
          'Unknown EnvironmentPaletteItem.collisionMode: $value');
  }
}

String _collisionModeToJson(EnvironmentCollisionMode mode) {
  switch (mode) {
    case EnvironmentCollisionMode.useElementDefault:
      return 'useElementDefault';
    case EnvironmentCollisionMode.forceEnabled:
      return 'forceEnabled';
    case EnvironmentCollisionMode.forceDisabled:
      return 'forceDisabled';
  }
}

/// Même contrat strict que le codec Environment Layer (Ent. 4-review) :
/// densités : `int` ou `double` JSON ; `minSpacingCells` : littéral `int` uniquement.
EnvironmentGenerationParams decodeEnvironmentGenerationParamsJson(
    Object? json) {
  if (json == null || json is! Map) {
    throw FormatException(
      'EnvironmentGenerationParams JSON must be a Map, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);
  try {
    return EnvironmentGenerationParams(
      density: _requireDoubleUnit(map, 'density'),
      variation: _requireDoubleUnit(map, 'variation'),
      edgeDensity: _requireDoubleUnit(map, 'edgeDensity'),
      minSpacingCells: _requireIntStrict(
        map,
        'minSpacingCells',
        fieldLabel: 'EnvironmentGenerationParams.minSpacingCells',
      ),
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentGenerationParams: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentGenerationParamsJson(
  EnvironmentGenerationParams params,
) {
  return <String, dynamic>{
    'density': params.density,
    'variation': params.variation,
    'edgeDensity': params.edgeDensity,
    'minSpacingCells': params.minSpacingCells,
  };
}

double _requireDoubleUnit(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is double) {
    return v;
  }
  if (v is int) {
    return v.toDouble();
  }
  throw FormatException(
    'Missing or invalid num for key "$key" (expected int or double, got ${v.runtimeType})',
  );
}

int _requireIntStrict(
  Map<String, dynamic> json,
  String key, {
  required String fieldLabel,
}) {
  final v = json[key];
  if (v is int) {
    return v;
  }
  throw FormatException(
    'Missing or invalid strict int for $fieldLabel (got ${v.runtimeType})',
  );
}

```

### `project_manifest_environment_preset_operations.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/environment.dart';
import '../models/project_manifest.dart';

/// Retourne la liste exposée par [ProjectManifest.environmentPresets].
List<EnvironmentPreset> readProjectEnvironmentPresets(
  ProjectManifest manifest,
) {
  return manifest.environmentPresets;
}

/// `true` lorsque le manifest contient au moins un preset environnement.
bool hasProjectEnvironmentPresets(ProjectManifest manifest) {
  return manifest.environmentPresets.isNotEmpty;
}

/// Retourne le preset dont [presetId] égale [EnvironmentPreset.id], ou `null`.
///
/// [presetId] est trimé ; `null` si vide / whitespace uniquement ou inconnu.
/// Ne lève pas si absent.
EnvironmentPreset? findProjectEnvironmentPresetById(
  ProjectManifest manifest,
  String presetId,
) {
  final key = presetId.trim();
  if (key.isEmpty) {
    return null;
  }
  for (final preset in manifest.environmentPresets) {
    if (preset.id == key) {
      return preset;
    }
  }
  return null;
}

/// Remplace toute la liste ; refuse deux [EnvironmentPreset.id] identiques.
ProjectManifest replaceProjectEnvironmentPresets(
  ProjectManifest manifest,
  List<EnvironmentPreset> presets,
) {
  _validateUniqueEnvironmentPresetIds(presets);
  return manifest.copyWith(
      environmentPresets: List<EnvironmentPreset>.from(presets));
}

/// Insère ou remplace par [EnvironmentPreset.id] à la même position si existant.
///
/// Exige que le manifest courant n’ait pas de doublons d’id (état corrompu).
ProjectManifest upsertProjectEnvironmentPreset(
  ProjectManifest manifest,
  EnvironmentPreset preset,
) {
  _validateUniqueEnvironmentPresetIds(manifest.environmentPresets);
  final next = List<EnvironmentPreset>.from(
    manifest.environmentPresets,
    growable: true,
  );
  final index = next.indexWhere((existing) => existing.id == preset.id);
  if (index < 0) {
    next.add(preset);
  } else {
    next[index] = preset;
  }
  return manifest.copyWith(environmentPresets: next);
}

/// Supprime le preset dont l’id correspond à [presetId] trimé.
///
/// Comme [removeProjectPathPatternPreset] : identifiant vide ⇒ [ArgumentError].
/// Si inconnu après trim : manifest inchangé.
ProjectManifest removeProjectEnvironmentPresetById(
  ProjectManifest manifest,
  String presetId,
) {
  _validatePresetIdArgument(presetId);
  _validateNoDuplicateEnvironmentPresetIds(
      manifest.environmentPresets, presetId);
  final next = [
    for (final preset in manifest.environmentPresets)
      if (preset.id != presetId.trim()) preset,
  ];
  return manifest.copyWith(environmentPresets: next);
}

/// Liste vide.
ProjectManifest clearProjectEnvironmentPresets(ProjectManifest manifest) {
  return manifest.copyWith(environmentPresets: const []);
}

void _validateUniqueEnvironmentPresetIds(List<EnvironmentPreset> presets) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ValidationException(
        'Duplicate EnvironmentPreset id: ${preset.id}',
      );
    }
  }
}

/// Détecte plusieurs entrées avec le même id que [presetId] (cohérence manifeste).
void _validateNoDuplicateEnvironmentPresetIds(
  List<EnvironmentPreset> presets,
  String presetId,
) {
  final key = presetId.trim();
  var count = 0;
  for (final preset in presets) {
    if (preset.id == key) {
      count += 1;
      if (count > 1) {
        throw ValidationException(
          'Duplicate EnvironmentPreset id: $key',
        );
      }
    }
  }
}

void _validatePresetIdArgument(String presetId) {
  if (presetId.trim().isEmpty) {
    throw ArgumentError.value(
      presetId,
      'presetId',
      'EnvironmentPreset id must not be blank.',
    );
  }
}

```

### `map_core.dart`

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
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
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
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
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

### `project_manifest.dart`

```dart
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'element_collision_profile.dart';
import 'environment.dart';
import 'enums.dart';
import 'project_trainer.dart';
import 'project_path_pattern_preset.dart';
import 'scenario_asset.dart';
import 'script_asset.dart';
import 'surface_catalog.dart';
import 'tileset_transparent_color.dart';
import 'visual_frame_json.dart';

import '../exceptions/map_exceptions.dart';
import '../operations/environment_preset_json_codec.dart';
import '../operations/project_path_pattern_preset_json_codec.dart';
import '../operations/project_surface_catalog_json_codec.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
/// Clé absente ou `null` : catalogue vide. Non-map : [ValidationException].
ProjectSurfaceCatalog _projectSurfaceCatalogFromJson(Object? json) {
  if (json == null) {
    return ProjectSurfaceCatalog();
  }
  if (json is! Map) {
    throw const ValidationException('surfaceCatalog must be a JSON object');
  }
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(json),
  );
}

Map<String, Object?> _projectSurfaceCatalogToJson(
  ProjectSurfaceCatalog catalog,
) {
  return encodeProjectSurfaceCatalog(catalog);
}

Object? _readDefaultPlayerCharacterId(Map json, String _) {
  return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
}

TilesetTransparentColor? _tilesetTransparentColorFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    final value = json.trim();
    if (value.isEmpty) {
      return null;
    }
    return TilesetTransparentColor.fromHexRgb(value);
  }
  throw ArgumentError.value(
    json,
    'transparentColor',
    'Expected a hex RGB string',
  );
}

String? _tilesetTransparentColorToJson(TilesetTransparentColor? color) {
  return color?.toHexRgb();
}

const Map<String, String> _defaultPokemonCatalogFiles = <String, String>{
  'moves': 'data/pokemon/catalogs/moves.json',
  'abilities': 'data/pokemon/catalogs/abilities.json',
  'items': 'data/pokemon/catalogs/items.json',
  'types': 'data/pokemon/catalogs/types.json',
  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
  'natures': 'data/pokemon/catalogs/natures.json',
  'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
  'habitats': 'data/pokemon/catalogs/habitats.json',
  'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  'generations': 'data/pokemon/catalogs/generations.json',
  'version_groups': 'data/pokemon/catalogs/version_groups.json',
};

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  factory ProjectManifest({
    required String name,
    @Default(ProjectVersion.v1) ProjectVersion version,
    required List<ProjectMapEntry> maps,
    @Default([]) List<ProjectMapGroup> groups,
    @Default([]) List<ProjectTilesetFolder> tilesetFolders,
    required List<ProjectTilesetEntry> tilesets,
    @Default([]) List<ProjectElementCategory> elementCategories,
    @Default([]) List<ProjectElementEntry> elements,
    @Default([]) List<ProjectPresetCategory> terrainCategories,
    @Default([]) List<ProjectPresetCategory> pathCategories,
    @Default([]) List<ProjectTerrainPreset> terrainPresets,
    @Default([]) List<ProjectPathPreset> pathPresets,
    @Default([])
    @JsonKey(
      name: 'pathPatternPresets',
      fromJson: decodeProjectPathPatternPresets,
      toJson: encodeProjectPathPatternPresets,
    )
    List<ProjectPathPatternPreset> pathPatternPresets,
    @Default([])
    @JsonKey(
      name: 'environmentPresets',
      fromJson: decodeEnvironmentPresets,
      toJson: encodeEnvironmentPresets,
    )
    List<EnvironmentPreset> environmentPresets,
    @Default([]) List<ProjectEncounterTable> encounterTables,
    @Default([]) List<ProjectDialogueFolder> dialogueFolders,
    @Default([]) List<ProjectDialogueEntry> dialogues,
    @Default([]) List<ProjectScriptEntry> scripts,
    @Default([]) List<ScenarioAsset> scenarios,
    @Default([]) List<ProjectTrainerEntry> trainers,
    @Default([]) List<ProjectCharacterEntry> characters,
    @Default(ProjectSettings()) ProjectSettings settings,
    @Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
    @Default({}) Map<String, dynamic> globalProperties,
    @JsonKey(
      name: 'surfaceCatalog',
      fromJson: _projectSurfaceCatalogFromJson,
      toJson: _projectSurfaceCatalogToJson,
    )
    required ProjectSurfaceCatalog surfaceCatalog,
  }) = _ProjectManifest;

  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
      _$ProjectManifestFromJson(json);
}

@freezed
class ProjectPokemonConfig with _$ProjectPokemonConfig {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectPokemonConfig({
    @Default(true) bool enabled,
    @Default('data/pokemon') String dataRoot,
    @Default('data/pokemon/species') String speciesDir,
    @Default('data/pokemon/learnsets') String learnsetsDir,
    @Default('data/pokemon/evolutions') String evolutionsDir,
    @Default('data/pokemon/media') String mediaDir,
    @Default(_defaultPokemonCatalogFiles) Map<String, String> catalogFiles,
  }) = _ProjectPokemonConfig;

  factory ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectPokemonConfigFromJson(json);
}

@freezed
class ProjectSettings with _$ProjectSettings {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSettings({
    @Default(16) int tileWidth,
    @Default(16) int tileHeight,
    @Default(2.0) double displayScale,
    @Default(20) int defaultMapWidth,
    @Default(15) int defaultMapHeight,
    @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId,
    )
    String? defaultPlayerCharacterId,

    /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
    ///
    /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
    /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
    @JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey,
  }) = _ProjectSettings;

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);
}

@freezed
class ProjectMapGroup with _$ProjectMapGroup {
  const factory ProjectMapGroup({
    required String id,
    required String name,
    required MapGroupType type,
    String? parentGroupId,
    @Default(0) int sortOrder,
    @Default([]) List<String> tags,
    @Default({}) Map<String, dynamic> properties,
  }) = _ProjectMapGroup;

  factory ProjectMapGroup.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapGroupFromJson(json);
}

@freezed
class ProjectMapEntry with _$ProjectMapEntry {
  const factory ProjectMapEntry({
    required String id,
    required String name,
    required String relativePath,
    String? groupId,
    @Default(MapRole.exterior) MapRole role,
    @Default(0) int sortOrder,
  }) = _ProjectMapEntry;

  factory ProjectMapEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapEntryFromJson(json);
}

@freezed
class ProjectDialogueFolder with _$ProjectDialogueFolder {
  const factory ProjectDialogueFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueFolder;

  factory ProjectDialogueFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueFolderFromJson(json);
}

@freezed
class ProjectDialogueEntry with _$ProjectDialogueEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectDialogueEntry({
    required String id,
    required String name,

    /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
    required String relativePath,
    @Default([]) List<String> tags,
    @Default('') String description,

    /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
    String? defaultStartNode,

    /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
    String? folderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueEntry;

  factory ProjectDialogueEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueEntryFromJson(json);
}

@freezed
class ProjectTilesetFolder with _$ProjectTilesetFolder {
  const factory ProjectTilesetFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectTilesetFolder;

  factory ProjectTilesetFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetFolderFromJson(json);
}

@freezed
class ProjectTilesetEntry with _$ProjectTilesetEntry {
  const factory ProjectTilesetEntry({
    required String id,
    required String name,
    required String relativePath,
    @Default(TilesetScope.global) TilesetScope scope,
    String? groupId,

    /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
    String? folderId,
    @Default(0) int sortOrder,
    @Default(false) bool isWorldTileset,
    @JsonKey(
      fromJson: _tilesetTransparentColorFromJson,
      toJson: _tilesetTransparentColorToJson,
      includeIfNull: false,
    )
    TilesetTransparentColor? transparentColor,
    @Default([]) List<TilesetElementGroup> elementGroups,
    @Default([]) List<TilesetPaletteEntry> paletteEntries,
  }) = _ProjectTilesetEntry;

  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetEntryFromJson(json);
}

@freezed
class TilesetPaletteEntry with _$TilesetPaletteEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetPaletteEntry({
    required String id,
    @Default('') String name,
    @Default(PaletteCategory.uncategorized) PaletteCategory category,

    /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
    required List<TilesetVisualFrame> frames,
    String? recommendedLayerId,
  }) = _TilesetPaletteEntry;

  factory TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =>
      _$TilesetPaletteEntryFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class TilesetSourceRect with _$TilesetSourceRect {
  const factory TilesetSourceRect({
    required int x,
    required int y,
    @Default(1) int width,
    @Default(1) int height,
  }) = _TilesetSourceRect;

  factory TilesetSourceRect.fromJson(Map<String, dynamic> json) =>
      _$TilesetSourceRectFromJson(json);
}

/// Une frame d'animation ou l'unique frame d'un visuel statique dans un tileset.
///
/// [tilesetId] vide = utiliser le tileset du contexte parent (élément, preset, entrée palette).
@freezed
class TilesetVisualFrame with _$TilesetVisualFrame {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetVisualFrame({
    @Default('') String tilesetId,
    required TilesetSourceRect source,

    /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
    int? durationMs,
  }) = _TilesetVisualFrame;

  factory TilesetVisualFrame.fromJson(Map<String, dynamic> json) =>
      _$TilesetVisualFrameFromJson(json);
}

@freezed
class TilesetElementGroup with _$TilesetElementGroup {
  const factory TilesetElementGroup({
    required String id,
    required String name,
    String? parentGroupId,
    @Default(0) int sortOrder,
  }) = _TilesetElementGroup;

  factory TilesetElementGroup.fromJson(Map<String, dynamic> json) =>
      _$TilesetElementGroupFromJson(json);
}

@freezed
class ProjectElementCategory with _$ProjectElementCategory {
  const factory ProjectElementCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectElementCategory;

  factory ProjectElementCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementCategoryFromJson(json);
}

@freezed
class ProjectElementEntry with _$ProjectElementEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectElementEntry({
    required String id,
    required String name,
    required String tilesetId,
    required String categoryId,
    String? tilesetGroupId,

    /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(ElementPresetKind.generic) ElementPresetKind presetKind,
    ElementCollisionProfile? collisionProfile,
    String? groupId,
    String? recommendedLayerId,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectElementEntry;

  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class ProjectTerrainPreset with _$ProjectTerrainPreset {
  const factory ProjectTerrainPreset({
    required String id,
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<TerrainPresetVariant> variants,
    @Default(0) int sortOrder,
  }) = _ProjectTerrainPreset;

  factory ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectTerrainPresetFromJson(json);
}

@freezed
class TerrainPresetVariant with _$TerrainPresetVariant {
  @JsonSerializable(explicitToJson: true)
  const factory TerrainPresetVariant({
    /// Au moins une frame ; rendu éditeur = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(1) int weight,

    /// When [frames] primary source spans W×H tiles (>1), controls sub-tile
    /// choice per map cell (see [terrainPresetSubtileOffsetsForMapCell]).
    @Default(TerrainVariantMultiTileLayout.tessellated)
    TerrainVariantMultiTileLayout multiTileLayout,
  }) = _TerrainPresetVariant;

  factory TerrainPresetVariant.fromJson(Map<String, dynamic> json) =>
      _$TerrainPresetVariantFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class ProjectPathPreset with _$ProjectPathPreset {
  const factory ProjectPathPreset({
    required String id,
    required String name,
    @Default(PathSurfaceKind.path) PathSurfaceKind surfaceKind,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<PathPresetVariantMapping> variants,
    @Default(0) int sortOrder,
  }) = _ProjectPathPreset;

  factory ProjectPathPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectPathPresetFromJson(json);
}

@freezed
class PathPresetVariantMapping with _$PathPresetVariantMapping {
  @JsonSerializable(explicitToJson: true)
  const factory PathPresetVariantMapping({
    required TerrainPathVariant variant,

    /// Au moins une frame ; rendu éditeur / autotile = première frame.
    required List<TilesetVisualFrame> frames,
  }) = _PathPresetVariantMapping;

  factory PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =>
      _$PathPresetVariantMappingFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class PathAnimationTriggerRule with _$PathAnimationTriggerRule {
  @JsonSerializable(explicitToJson: true)
  const factory PathAnimationTriggerRule({
    @Default('') String id,
    @Default(true) bool enabled,
    @Default(PathAnimationTriggerType.onStep) PathAnimationTriggerType trigger,
    @Default(PathAnimationPlaybackMode.restartOnTrigger)
    PathAnimationPlaybackMode mode,
    @Default(PathAnimationActivationScope.wholeLayer)
    PathAnimationActivationScope scope,
  }) = _PathAnimationTriggerRule;

  factory PathAnimationTriggerRule.fromJson(Map<String, dynamic> json) =>
      _$PathAnimationTriggerRuleFromJson(json);
}

@freezed
class ProjectPresetCategory with _$ProjectPresetCategory {
  const factory ProjectPresetCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectPresetCategory;

  factory ProjectPresetCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresetCategoryFromJson(json);
}

// ---------------------------------------------------------------------------
// ProjectEncounterEntry / ProjectEncounterTable
// ---------------------------------------------------------------------------

/// Entrée pondérée dans une table de rencontres.
@freezed
class ProjectEncounterEntry with _$ProjectEncounterEntry {
  const factory ProjectEncounterEntry({
    /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
    required String speciesId,
    required int minLevel,
    required int maxLevel,

    /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
    @Default(1) int weight,
  }) = _ProjectEncounterEntry;

  factory ProjectEncounterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterEntryFromJson(json);
}

/// Table de rencontres réutilisable au niveau projet.
///
/// Une [MapGameplayZone] peut y faire référence via [MapGameplayZone.encounterTableId].
/// Le runtime choisit une entrée au tirage pondéré et déclenche le système de combat.
@freezed
class ProjectEncounterTable with _$ProjectEncounterTable {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectEncounterTable({
    required String id,
    required String name,
    required EncounterKind encounterKind,
    @Default([]) List<ProjectEncounterEntry> entries,
    @Default([]) List<String> tags,
  }) = _ProjectEncounterTable;

  factory ProjectEncounterTable.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterTableFromJson(json);
}

extension TilesetVisualFrameListX on List<TilesetVisualFrame> {
  TilesetVisualFrame get primaryFrame {
    if (isEmpty) {
      throw StateError('At least one TilesetVisualFrame is required');
    }
    return first;
  }

  TilesetSourceRect get primarySource => primaryFrame.source;
}

@freezed
class ProjectScriptEntry with _$ProjectScriptEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectScriptEntry({
    required String id,
    required String name,
    required ScriptAsset asset,
    @Default([]) List<String> tags,
  }) = _ProjectScriptEntry;

  factory ProjectScriptEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectScriptEntryFromJson(json);
}

@freezed
class ProjectCharacterEntry with _$ProjectCharacterEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectCharacterEntry({
    required String id,
    required String name,
    required String tilesetId,
    @Default(1) int frameWidth,
    @Default(2) int frameHeight,
    @Default([]) List<CharacterAnimation> animations,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectCharacterEntry;

  factory ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectCharacterEntryFromJson(json);
}

@freezed
class CharacterAnimation with _$CharacterAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimation({
    required CharacterAnimationState state,
    required EntityFacing direction,
    @Default([]) List<CharacterAnimationFrame> frames,
  }) = _CharacterAnimation;

  factory CharacterAnimation.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFromJson(json);
}

@freezed
class CharacterAnimationFrame with _$CharacterAnimationFrame {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimationFrame({
    required TilesetSourceRect source,
    @Default(150) int durationMs,
  }) = _CharacterAnimationFrame;

  factory CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFrameFromJson(json);
}

```

### `environment_preset_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentPaletteItem _paletteItem(String id, {int weight = 1}) {
  return EnvironmentPaletteItem(elementId: id, weight: weight);
}

EnvironmentGenerationParams _params({
  double density = 0.5,
  double variation = 0.5,
  double edgeDensity = 0.5,
  int minSpacingCells = 1,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacingCells,
  );
}

EnvironmentPreset _preset({
  String id = 'selbrume_dense_forest',
  String name = 'Forêt dense',
  String templateId = 'forest_dense',
  List<EnvironmentPaletteItem>? palette,
  EnvironmentGenerationParams? defaultParams,
  String? categoryId,
  int sortOrder = 0,
}) {
  return EnvironmentPreset(
    id: id,
    name: name,
    templateId: templateId,
    palette: palette ?? [_paletteItem('oak_tree_large', weight: 5)],
    defaultParams: defaultParams ?? _params(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

Map<String, dynamic> _presetJson({
  Object? categoryId,
  String collisionMode = 'forceEnabled',
  List<String>? tags,
}) {
  return <String, dynamic>{
    'id': 'selbrume_dense_forest',
    'name': 'Forêt dense de Selbrume',
    'templateId': 'forest_dense',
    'palette': <Map<String, dynamic>>[
      <String, dynamic>{
        'elementId': 'oak_tree_large',
        'weight': 5,
        'collisionMode': collisionMode,
        'tags': tags ?? <String>['tree', 'canopy'],
      },
    ],
    'defaultParams': <String, dynamic>{
      'density': 0.75,
      'variation': 0.45,
      'edgeDensity': 0.8,
      'minSpacingCells': 1,
    },
    'sortOrder': 0,
    if (categoryId != null) 'categoryId': categoryId,
  };
}

void main() {
  group('EnvironmentPreset JSON codec', () {
    test('decode preset complet', () {
      final j = _presetJson();
      final p = decodeEnvironmentPreset(j);
      expect(p.id, 'selbrume_dense_forest');
      expect(p.name, 'Forêt dense de Selbrume');
      expect(p.templateId, 'forest_dense');
      expect(p.palette.length, 1);
      expect(p.palette.single.elementId, 'oak_tree_large');
      expect(p.palette.single.weight, 5);
      expect(p.palette.single.collisionMode,
          EnvironmentCollisionMode.forceEnabled);
      expect(p.palette.single.tags, containsAll(<String>['tree', 'canopy']));
      expect(p.defaultParams.density, 0.75);
      expect(p.sortOrder, 0);
      expect(p.categoryId, isNull);
    });

    test('encode preset complet', () {
      final p = _preset();
      final m = encodeEnvironmentPreset(p);
      expect(m['id'], 'selbrume_dense_forest');
      expect(m['templateId'], 'forest_dense');
      expect(m['palette'], isA<List>());
      expect(m['defaultParams'], isA<Map>());
      expect(m['sortOrder'], 0);
      expect(m.containsKey('categoryId'), isFalse);
    });

    test('roundtrip preset complet', () {
      final original = _preset(
        categoryId: 'biomes',
        sortOrder: 42,
      );
      final back = decodeEnvironmentPreset(encodeEnvironmentPreset(original));
      expect(back, equals(original));
    });

    test('decode categoryId absent/null => null', () {
      final j = _presetJson(categoryId: null);
      j.remove('categoryId');
      expect(decodeEnvironmentPreset(j).categoryId, isNull);

      final j2 = _presetJson();
      j2['categoryId'] = null;
      expect(decodeEnvironmentPreset(j2).categoryId, isNull);
    });

    test('decode collisionMode absent/null => useElementDefault', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal.remove('collisionMode');
      expect(
        decodeEnvironmentPreset(j).palette.single.collisionMode,
        EnvironmentCollisionMode.useElementDefault,
      );

      final j2 = _presetJson();
      final pal2 = (j2['palette'] as List).single as Map<String, dynamic>;
      pal2['collisionMode'] = null;
      expect(
        decodeEnvironmentPreset(j2).palette.single.collisionMode,
        EnvironmentCollisionMode.useElementDefault,
      );
    });

    test('decode collisionMode inconnu => FormatException', () {
      final j = _presetJson(collisionMode: 'nope');
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode tags absent/null => set vide', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal.remove('tags');
      expect(decodeEnvironmentPreset(j).palette.single.tags, isEmpty);

      final j2 = _presetJson();
      final pal2 = (j2['palette'] as List).single as Map<String, dynamic>;
      pal2['tags'] = null;
      expect(decodeEnvironmentPreset(j2).palette.single.tags, isEmpty);
    });

    test('decode tag non-string => FormatException', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal['tags'] = <Object?>[1];
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode tag vide/whitespace => FormatException', () {
      final j = _presetJson(tags: <String>['  ']);
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode weight double => FormatException', () {
      final j = _presetJson();
      final pal = (j['palette'] as List).single as Map<String, dynamic>;
      pal['weight'] = 1.5;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode sortOrder double => FormatException', () {
      final j = _presetJson();
      j['sortOrder'] = 0.0;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode minSpacingCells double => FormatException', () {
      final j = _presetJson();
      final dp = j['defaultParams'] as Map<String, dynamic>;
      dp['minSpacingCells'] = 1.0;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode density hors [0,1] => FormatException', () {
      final j = _presetJson();
      final dp = j['defaultParams'] as Map<String, dynamic>;
      dp['density'] = 1.5;
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode palette vide => FormatException via modèle', () {
      final j = _presetJson();
      j['palette'] = <Map<String, dynamic>>[];
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('decode duplicate palette elementId => FormatException via modèle',
        () {
      final j = _presetJson();
      j['palette'] = <Map<String, dynamic>>[
        <String, dynamic>{
          'elementId': 'same',
          'weight': 1,
        },
        <String, dynamic>{
          'elementId': 'same',
          'weight': 2,
        },
      ];
      expect(() => decodeEnvironmentPreset(j), throwsFormatException);
    });

    test('json non-map preset => FormatException', () {
      expect(() => decodeEnvironmentPreset(1), throwsFormatException);
    });

    test('decodeEnvironmentPresets duplicate preset ids => FormatException',
        () {
      final list = <Map<String, dynamic>>[
        encodeEnvironmentPreset(_preset(id: 'dup')),
        encodeEnvironmentPreset(_preset(id: 'dup', name: 'Autre')),
      ];
      expect(() => decodeEnvironmentPresets(list), throwsFormatException);
    });
  });

  group('decodeEnvironmentGenerationParamsJson', () {
    test('accepte int pour densités', () {
      final p = decodeEnvironmentGenerationParamsJson(<String, dynamic>{
        'density': 1,
        'variation': 0,
        'edgeDensity': 1,
        'minSpacingCells': 2,
      });
      expect(p.density, 1.0);
      expect(p.minSpacingCells, 2);
    });
  });
}

```

### `project_manifest_environment_presets_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentPaletteItem _item(String id) =>
    EnvironmentPaletteItem(elementId: id, weight: 1);

EnvironmentGenerationParams _params() => EnvironmentGenerationParams.standard();

EnvironmentPreset _ep(String id, {int sortOrder = 0}) => EnvironmentPreset(
      id: id,
      name: 'n_$id',
      templateId: 'tpl',
      palette: [_item('el_$id')],
      defaultParams: _params(),
      sortOrder: sortOrder,
    );

ProjectManifest _minimalManifest() {
  return ProjectManifest(
    name: 'Env5',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

void main() {
  group('ProjectManifest environmentPresets JSON', () {
    test('fromJson sans environmentPresets => []', () {
      final m = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'x',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[],
          'animations': <dynamic>[],
          'presets': <dynamic>[],
        },
      });
      expect(m.environmentPresets, isEmpty);
    });

    test('fromJson avec environmentPresets null => []', () {
      final m = ProjectManifest.fromJson(<String, dynamic>{
        'name': 'x',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'environmentPresets': null,
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[],
          'animations': <dynamic>[],
          'presets': <dynamic>[],
        },
      });
      expect(m.environmentPresets, isEmpty);
    });

    test('fromJson avec environmentPresets complet => liste', () {
      final preset = _ep('p1', sortOrder: 3);
      final manifest = _minimalManifest().copyWith(
        environmentPresets: [preset],
      );
      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded.environmentPresets.length, 1);
      expect(decoded.environmentPresets.single.id, 'p1');
      expect(decoded.environmentPresets.single.sortOrder, 3);
    });

    test('toJson inclut environmentPresets', () {
      final preset = _ep('x');
      final j =
          _minimalManifest().copyWith(environmentPresets: [preset]).toJson();
      expect(j.containsKey('environmentPresets'), isTrue);
      expect(j['environmentPresets'], isA<List>());
    });

    test('JSON roundtrip avec un preset complet', () {
      final preset = EnvironmentPreset(
        id: 'full',
        name: 'Full',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'e1',
            weight: 2,
            collisionMode: EnvironmentCollisionMode.forceDisabled,
            tags: {'a', 'b'},
          ),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 0.25,
          variation: 0.5,
          edgeDensity: 0.75,
          minSpacingCells: 4,
        ),
        categoryId: 'cat',
        sortOrder: 7,
      );
      final m = _minimalManifest().copyWith(environmentPresets: [preset]);
      final back = ProjectManifest.fromJson(m.toJson());
      expect(back.environmentPresets.single, preset);
    });

    test('environmentPresets non-list => FormatException', () {
      expect(
        () => ProjectManifest.fromJson(<String, dynamic>{
          'name': 'x',
          'maps': <dynamic>[],
          'tilesets': <dynamic>[],
          'environmentPresets': 'bad',
          'surfaceCatalog': <String, dynamic>{
            'atlases': <dynamic>[],
            'animations': <dynamic>[],
            'presets': <dynamic>[],
          },
        }),
        throwsFormatException,
      );
    });

    test('environmentPresets avec item invalide => FormatException', () {
      expect(
        () => ProjectManifest.fromJson(<String, dynamic>{
          'name': 'x',
          'maps': <dynamic>[],
          'tilesets': <dynamic>[],
          'environmentPresets': <dynamic>[
            <String, dynamic>{'oops': true},
          ],
          'surfaceCatalog': <String, dynamic>{
            'atlases': <dynamic>[],
            'animations': <dynamic>[],
            'presets': <dynamic>[],
          },
        }),
        throwsFormatException,
      );
    });
  });

  group('project_manifest_environment_preset_operations', () {
    test('readProjectEnvironmentPresets retourne la liste', () {
      final p = _ep('a');
      final m = _minimalManifest().copyWith(environmentPresets: [p]);
      expect(readProjectEnvironmentPresets(m), m.environmentPresets);
    });

    test('hasProjectEnvironmentPresets false/true', () {
      expect(hasProjectEnvironmentPresets(_minimalManifest()), isFalse);
      expect(
        hasProjectEnvironmentPresets(
          _minimalManifest().copyWith(environmentPresets: [_ep('x')]),
        ),
        isTrue,
      );
    });

    test('findProjectEnvironmentPresetById trouve / trim / null', () {
      final m = _minimalManifest().copyWith(environmentPresets: [_ep('abc')]);
      expect(findProjectEnvironmentPresetById(m, '  abc  ')?.id, 'abc');
      expect(findProjectEnvironmentPresetById(m, '  '), isNull);
      expect(findProjectEnvironmentPresetById(m, 'nope'), isNull);
    });

    test('replaceProjectEnvironmentPresets remplace et ordre', () {
      final base = _minimalManifest().copyWith(
        environmentPresets: [_ep('a'), _ep('b')],
      );
      final next = replaceProjectEnvironmentPresets(
        base,
        [_ep('z', sortOrder: 9), _ep('y')],
      );
      expect(next.environmentPresets.map((e) => e.id).toList(), ['z', 'y']);
    });

    test('replaceProjectEnvironmentPresets refuse doublons', () {
      expect(
        () => replaceProjectEnvironmentPresets(
          _minimalManifest(),
          [_ep('x'), _ep('x')],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('upsert ajoute ou remplace même position', () {
      final a = _ep('a', sortOrder: 0);
      final b = _ep('b', sortOrder: 0);
      final m0 = _minimalManifest().copyWith(environmentPresets: [a, b]);

      final a2 = EnvironmentPreset(
        id: 'a',
        name: 'updated',
        templateId: 'tpl',
        palette: [_item('el_a')],
        defaultParams: _params(),
        sortOrder: 99,
      );
      final m1 = upsertProjectEnvironmentPreset(m0, a2);
      expect(m1.environmentPresets.map((e) => e.name).toList(),
          ['updated', 'n_b']);

      final c = _ep('c');
      final m2 = upsertProjectEnvironmentPreset(m1, c);
      expect(m2.environmentPresets.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('upsert refuse doublons préexistants dans le manifest', () {
      final corrupt = ProjectManifest(
        name: 'bad',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: ProjectSurfaceCatalog(),
        environmentPresets: [_ep('dup'), _ep('dup')],
      );
      expect(
        () => upsertProjectEnvironmentPreset(corrupt, _ep('z')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('remove supprime / inconnu no-op / id vide erreur', () {
      final m = _minimalManifest().copyWith(environmentPresets: [_ep('k')]);
      final removed = removeProjectEnvironmentPresetById(m, 'k');
      expect(removed.environmentPresets, isEmpty);

      final m2 = removeProjectEnvironmentPresetById(m, 'ghost');
      expect(m2.environmentPresets.single.id, 'k');

      expect(
        () => removeProjectEnvironmentPresetById(m, '   '),
        throwsArgumentError,
      );
    });

    test('clearProjectEnvironmentPresets vide la liste', () {
      final m = _minimalManifest().copyWith(environmentPresets: [_ep('u')]);
      final cleared = clearProjectEnvironmentPresets(m);
      expect(cleared.environmentPresets, isEmpty);
    });
  });
}

```

## 15. Generated files modifiés

- **`packages/map_core/lib/src/models/project_manifest.freezed.dart`** — régénéré par **freezed** (nouveau champ **`environmentPresets`** sur **`ProjectManifest`**).
- **`packages/map_core/lib/src/models/project_manifest.g.dart`** — **`json_serializable`** : branche **`environmentPresets`** null ⇒ **`[]`** ; **`toJson`** ⇒ **`encodeEnvironmentPresets`**.
- Autres sorties build_runner du lot : uniquement les artefacts liés à **`project_manifest`** (pas d’autres modèles touchés à la main).

### Hunks pertinents `project_manifest.g.dart`

```dart
      environmentPresets: json['environmentPresets'] == null
          ? const []
          : decodeEnvironmentPresets(json['environmentPresets']),
...
      'environmentPresets':
          encodeEnvironmentPresets(instance.environmentPresets),
```

## 16. Diff complet

### Fichiers suivis modifiés (`git diff`)

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index ba2a115a..aa9d8682 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -74,6 +74,8 @@ export 'src/collision/pixel_rect.dart';
 export 'src/collision/player_collision_conventions_v1.dart';
 export 'src/operations/map_layers.dart';
 export 'src/operations/environment_layer_content_json_codec.dart';
+export 'src/operations/environment_preset_json_codec.dart';
+export 'src/operations/project_manifest_environment_preset_operations.dart';
 export 'src/operations/surface_layer_placements.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index fdfea1eb..56af3958 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -2,6 +2,7 @@
 
 import 'package:freezed_annotation/freezed_annotation.dart';
 import 'element_collision_profile.dart';
+import 'environment.dart';
 import 'enums.dart';
 import 'project_trainer.dart';
 import 'project_path_pattern_preset.dart';
@@ -12,6 +13,7 @@ import 'tileset_transparent_color.dart';
 import 'visual_frame_json.dart';
 
 import '../exceptions/map_exceptions.dart';
+import '../operations/environment_preset_json_codec.dart';
 import '../operations/project_path_pattern_preset_json_codec.dart';
 import '../operations/project_surface_catalog_json_codec.dart';
 
@@ -101,6 +103,13 @@ class ProjectManifest with _$ProjectManifest {
       toJson: encodeProjectPathPatternPresets,
     )
     List<ProjectPathPatternPreset> pathPatternPresets,
+    @Default([])
+    @JsonKey(
+      name: 'environmentPresets',
+      fromJson: decodeEnvironmentPresets,
+      toJson: encodeEnvironmentPresets,
+    )
+    List<EnvironmentPreset> environmentPresets,
     @Default([]) List<ProjectEncounterTable> encounterTables,
     @Default([]) List<ProjectDialogueFolder> dialogueFolders,
     @Default([]) List<ProjectDialogueEntry> dialogues,
```

### Nouveaux fichiers (équivalent `git diff --no-index /dev/null ...`)

Le contenu intégral des fichiers **`??`** est dans **§14** ; pas de réduction.

## 17. Auto-review

- **Points solides** — alignement **`pathPatternPresets`** ; **`FormatException`** cohérente avec codec layer ; doublons ids JSON bloqués tôt.
- **Points discutables** — duplication légère des helpers **`_requireDoubleUnit`** / **`_requireIntStrict`** avec **`environment_layer_content_json_codec.dart`** (volontaire pour dépendances unidirectionnelles manifest → models).
- **`environmentPresets`** : nom aligné sur l’exemple produit ; symétrie **`pathPatternPresets`**.
- **`collisionMode`** en **string** : contrat stable avec l’exemple JSON ; enum côté Dart inchangé.
- **Doublons** : liste JSON → codec ; remplacement liste → **`ValidationException`** comme PathPattern.
- **Corrections après auto-review** — cas tag whitespace ; analyzer **`avoid_init_to_null`**.
- **Risques** — projets avec JSON **`environmentPresets`** mal formés échouent au chargement (comportement attendu).
- **Prompt** — périmètre respecté (pas **`MapLayer`**, pas UI).

## 18. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
environmentPresets au manifest + codec + opérations ; build_runner ; +1287 tests map_core verts ; analyze OK ; aucune UI/générateur/MapLayer.
```

Prochain lot recommandé :

```text
Environment-6 — Environment Preset Manifest Diagnostics V0
```

---

### Evidence Pack

- **Git** : §13.
- **Patterns audités** : §3.
- **Fichiers manuscrits intégraux** : §14.
- **Diff `project_manifest.dart` / `map_core.dart`** : §16.
- **Generated** : §15 ; source **build_runner** uniquement.
- **Tests** : §12 (sorties complètes codec + manifest + régressions + ligne **`+1287`**).
- **`MapLayer`** : non modifié.
- **UI Environment Studio / générateur** : non créés.
- **Commit / git add / push** : non effectués.
