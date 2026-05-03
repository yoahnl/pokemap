# Environment Studio Lot 6 — Environment Preset Manifest Diagnostics V0

## 1. Résumé exécutif

Ajout d’une couche **diagnostics auteur** pure sur **`ProjectManifest.environmentPresets`** : doublons d’id, **`elementId`** manquant dans **`elements`**, **`templateId`** inconnu si liste fournie (warning), **`forceEnabled`** sans **`collisionProfile`** sur l’élément (warning). Fonction **`diagnoseProjectEnvironmentPresets`**, types **`EnvironmentPresetDiagnostic*`**, tests **`+22`**, suite **`map_core`** **`+1309`** verts. **Aucune** modification **`ProjectManifest`**, **`MapLayer`**, codec, **`build_runner`**.

## 2. Périmètre du lot

Uniquement **`environment_preset_diagnostics.dart`**, **`map_core.dart`** (export), **`environment_preset_diagnostics_test.dart`**, ce rapport. Pas d’UI, pas de générateur, pas de validation carte / **`EnvironmentLayer`**.

## 3. Décisions de diagnostic

- **`duplicatePresetId`** : erreur, un message par id dupliqué, ordre par première apparition dans **`environmentPresets`**.
- **`missingPaletteElement`** : erreur ; si élément absent, pas de **`forcedCollisionWithoutProfile`** pour cet item.
- **`unknownTemplateId`** : warning ; désactivé si **`knownTemplateIds`** vide.
- **`forcedCollisionWithoutProfile`** : warning si **`forceEnabled`** et élément présent sans **`collisionProfile`**.

## 4. Types ajoutés

**`EnvironmentPresetDiagnosticSeverity`**, **`EnvironmentPresetDiagnosticKind`**, **`EnvironmentPresetDiagnostic`**, **`EnvironmentPresetDiagnosticsReport`** (voir §13).

## 5. Fonction de diagnostic

**`diagnoseProjectEnvironmentPresets(ProjectManifest manifest, { Set<String> knownTemplateIds = const {} })`** → **`EnvironmentPresetDiagnosticsReport`**. Ne modifie pas le manifest ; ne lève pas.

## 6. Ordre stable des diagnostics

1. **`duplicatePresetId`** (ids dupliqués triés par index de première occurrence).
2. Pour chaque preset dans l’ordre **`manifest.environmentPresets`** :
   - **`missingPaletteElement`** (ordre palette) ;
   - **`forcedCollisionWithoutProfile`** (ordre palette) ;
   - **`unknownTemplateId`** (une fois par preset si applicable).

## 7. Pourquoi aucun ProjectManifest / MapLayer / UI / générateur dans ce lot

Lecture seule via **`ProjectManifest`** passé en argument ; aucun schéma ni runtime modifié ; diagnostic pour préparer une future UI.

## 8. Fichiers modifiés

- **`packages/map_core/lib/src/operations/environment_preset_diagnostics.dart`** (nouveau)
- **`packages/map_core/lib/map_core.dart`** (export)
- **`packages/map_core/test/environment_preset_diagnostics_test.dart`** (nouveau)
- **`reports/forest/environment_studio_lot_6_environment_preset_diagnostics.md`**

## 9. Tests ajoutés

**`environment_preset_diagnostics_test.dart`** : rapport (compteurs, immuabilité, **`diagnosticsForPreset`**, **`diagnosticsForKind`**, égalité), tous les kinds, ordre agrégé, import **`package:map_core/map_core.dart`** uniquement.

## 10. Commandes exécutées

```bash
cd packages/map_core
dart format lib/src/operations/environment_preset_diagnostics.dart lib/map_core.dart \
  test/environment_preset_diagnostics_test.dart
dart analyze lib/src/operations/environment_preset_diagnostics.dart lib/map_core.dart \
  test/environment_preset_diagnostics_test.dart
dart analyze
dart test test/environment_preset_diagnostics_test.dart --reporter expanded
dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart \
  test/environment_layer_content_json_codec_test.dart test/environment_layer_map_layer_integration_test.dart \
  test/environment_preset_json_codec_test.dart test/project_manifest_environment_presets_test.dart \
  --reporter expanded
dart test --reporter expanded
```

## 11. Résultats des commandes

### `dart analyze` (ciblé puis package)

```
Analyzing environment_preset_diagnostics.dart, map_core.dart, environment_preset_diagnostics_test.dart...
No issues found!
Analyzing map_core...
No issues found!
```

### Tests ciblés `environment_preset_diagnostics_test.dart` (expanded, sans ANSI)

```
00:00 +0: loading test/environment_preset_diagnostics_test.dart
00:00 +0: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics
00:00 +1: EnvironmentPresetDiagnosticsReport copie défensive et liste immuable exposée
00:00 +2: EnvironmentPresetDiagnosticsReport errorCount / warningCount / diagnosticCount
00:00 +3: EnvironmentPresetDiagnosticsReport diagnosticsForPreset trim et vide/inconnu => []
00:00 +4: EnvironmentPresetDiagnosticsReport diagnosticsForKind retourne liste immuable
00:00 +5: EnvironmentPresetDiagnosticsReport égalité de valeur report et diagnostic
00:00 +6: diagnoseProjectEnvironmentPresets duplicatePresetId aucun doublon => rien
00:00 +7: diagnoseProjectEnvironmentPresets duplicatePresetId deux presets même id => un diagnostic
00:00 +8: diagnoseProjectEnvironmentPresets duplicatePresetId trois presets même id => un seul diagnostic pour cet id
00:00 +9: diagnoseProjectEnvironmentPresets duplicatePresetId deux ids dupliqués distincts => deux diagnostics ordre stable
00:00 +10: missingPaletteElement element présent => pas missing
00:00 +11: missingPaletteElement element absent => error
00:00 +12: missingPaletteElement deux presets référencent même absent => un diagnostic par preset
00:00 +13: unknownTemplateId knownTemplateIds vide => aucun unknownTemplateId
00:00 +14: unknownTemplateId template connu => rien
00:00 +15: unknownTemplateId template inconnu => warning
00:00 +16: forcedCollisionWithoutProfile forceEnabled + collisionProfile non-null => rien
00:00 +17: forcedCollisionWithoutProfile forceEnabled + collisionProfile null => warning
00:00 +18: forcedCollisionWithoutProfile useElementDefault + collisionProfile null => rien
00:00 +19: forcedCollisionWithoutProfile forceDisabled + collisionProfile null => rien
00:00 +20: forcedCollisionWithoutProfile element absent + forceEnabled => seulement missingPaletteElement
00:00 +21: ordre stable des diagnostics duplicate puis missing puis forced puis unknown
00:00 +22: All tests passed!
```

### Régressions Environment (sortie intégrale `lot6_regression.txt`, 155 lignes)

```
00:00 +0: loading test/environment_core_models_test.dart
00:00 +0: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item
00:00 +1: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item
00:00 +2: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts targetTileLayerId null
00:00 +3: test/environment_core_models_test.dart: EnvironmentPaletteItem trims elementId
00:00 +4: test/environment_layer_content_test.dart: EnvironmentLayerContent construction trims targetTileLayerId when non-null
00:00 +5: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty elementId
00:00 +6: test/environment_layer_content_test.dart: EnvironmentLayerContent construction rejects targetTileLayerId whitespace only
00:00 +7: test/environment_layer_content_test.dart: EnvironmentLayerContent construction rejects targetTileLayerId whitespace only
00:00 +8: test/environment_layer_content_test.dart: EnvironmentLayerContent construction rejects targetTileLayerId whitespace only
00:00 +9: test/environment_core_models_test.dart: EnvironmentPaletteItem defaults collisionMode to useElementDefault
00:00 +10: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts valid areas and preserves order
00:00 +11: test/environment_core_models_test.dart: EnvironmentPaletteItem copies tags defensively
00:00 +12: test/environment_layer_content_test.dart: EnvironmentLayerContent construction empty factory
00:00 +13: test/environment_core_models_test.dart: EnvironmentPaletteItem tags are immutable
00:00 +14: test/environment_layer_content_test.dart: EnvironmentLayerContent defensive copy and immutability copies areas list defensively
00:00 +15: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty tag
00:00 +16: test/environment_layer_content_test.dart: EnvironmentLayerContent defensive copy and immutability areas is unmodifiable
00:00 +17: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +18: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +19: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +20: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +21: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +22: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +23: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +24: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +25: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +26: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +27: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +28: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +29: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +30: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +31: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +32: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +33: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +34: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +35: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +36: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +37: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +38: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +39: test/environment_core_models_test.dart: EnvironmentAreaMask rejects width <= 0
00:00 +40: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements false when none
00:00 +41: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +42: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +43: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +44: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order
00:00 +45: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order
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
00:00 +62: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +63: test/environment_core_models_test.dart: EnvironmentArea accepts valid area
00:00 +64: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec encode content vide
00:00 +65: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec encode content vide
00:00 +66: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +67: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +68: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +69: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +70: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +71: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +72: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +73: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +74: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +75: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +76: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +77: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +78: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip
00:00 +79: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +80: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +81: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +82: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +83: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +84: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +85: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +86: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +87: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +88: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +89: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +90: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +91: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +92: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +93: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +94: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +95: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +96: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +97: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +98: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +99: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +100: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +101: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +102: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +103: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +104: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +105: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +106: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layerId vide
00:00 +107: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layer inconnu
00:00 +108: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet
00:00 +109: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet
00:00 +110: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet
00:00 +111: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +112: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +113: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +114: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +115: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +116: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tags absent/null => set vide
00:00 +117: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer targetTileLayerId valide si TileLayer existe
00:00 +118: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer targetTileLayerId valide si TileLayer existe
00:00 +119: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException
00:00 +120: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException
00:00 +121: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si targetTileLayerId pointe vers le layer environment lui-même
00:00 +122: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode weight double => FormatException
00:00 +123: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer
00:00 +124: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer
00:00 +125: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode minSpacingCells double => FormatException
00:00 +126: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si masque ne correspond pas à la taille carte
00:00 +127: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode density hors [0,1] => FormatException
00:00 +128: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment JSON edge cases fromJson avec content null => emptyContent
00:00 +129: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode palette vide => FormatException via modèle
00:00 +130: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode palette vide => FormatException via modèle
00:00 +131: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode duplicate palette elementId => FormatException via modèle
00:00 +132: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées
00:00 +133: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées
00:00 +134: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decodeEnvironmentPresets duplicate preset ids => FormatException
00:00 +135: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer rétrécit la carte : cellules hors carte supprimées
00:00 +136: test/environment_preset_json_codec_test.dart: decodeEnvironmentGenerationParamsJson accepte int pour densités
00:00 +137: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson sans environmentPresets => []
00:00 +138: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets null => []
00:00 +139: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets complet => liste
00:00 +140: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON toJson inclut environmentPresets
00:00 +141: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet
00:00 +142: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets non-list => FormatException
00:00 +143: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets avec item invalide => FormatException
00:00 +144: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations readProjectEnvironmentPresets retourne la liste
00:00 +145: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations hasProjectEnvironmentPresets false/true
00:00 +146: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations findProjectEnvironmentPresetById trouve / trim / null
00:00 +147: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations replaceProjectEnvironmentPresets remplace et ordre
00:00 +148: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations replaceProjectEnvironmentPresets refuse doublons
00:00 +149: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations upsert ajoute ou remplace même position
00:00 +150: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations upsert refuse doublons préexistants dans le manifest
00:00 +151: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations remove supprime / inconnu no-op / id vide erreur
00:00 +152: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations clearProjectEnvironmentPresets vide la liste
00:00 +153: All tests passed!
```

### Suite complète `dart test --reporter expanded`

Ligne finale : **`00:01 +1309: All tests passed!`**

## 12. Git status initial et final

**Initial** : avant création des fichiers Lot 6, ils n’existaient pas sur disque ; le dépôt pouvait déjà contenir des changements non commit des lots précédents (non figés ici).

**Final** (`git status --short --untracked-files=all`) :

```
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
?? packages/map_core/lib/src/operations/environment_preset_diagnostics.dart
?? packages/map_core/lib/src/operations/environment_preset_json_codec.dart
?? packages/map_core/lib/src/operations/project_manifest_environment_preset_operations.dart
?? packages/map_core/test/environment_preset_diagnostics_test.dart
?? packages/map_core/test/environment_preset_json_codec_test.dart
?? packages/map_core/test/project_manifest_environment_presets_test.dart
?? reports/forest/environment_studio_lot_5_project_manifest_environment_presets.md
```

## 13. Contenu complet des fichiers créés ou modifiés

### `environment_preset_diagnostics.dart`

```dart
import '../models/environment.dart';
import '../models/project_manifest.dart';

/// Gravité d’un diagnostic preset environnement (Lot Environment-6).
enum EnvironmentPresetDiagnosticSeverity {
  error,
  warning,
}

/// Catégorie de diagnostic (Lot Environment-6).
enum EnvironmentPresetDiagnosticKind {
  duplicatePresetId,
  missingPaletteElement,
  unknownTemplateId,
  forcedCollisionWithoutProfile,
}

/// Un problème détecté sur les presets Environment du manifest.
final class EnvironmentPresetDiagnostic {
  const EnvironmentPresetDiagnostic({
    required this.severity,
    required this.kind,
    required this.presetId,
    this.elementId,
    this.templateId,
    required this.message,
  });

  final EnvironmentPresetDiagnosticSeverity severity;
  final EnvironmentPresetDiagnosticKind kind;
  final String presetId;
  final String? elementId;
  final String? templateId;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDiagnostic &&
            severity == other.severity &&
            kind == other.kind &&
            presetId == other.presetId &&
            elementId == other.elementId &&
            templateId == other.templateId &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        presetId,
        elementId,
        templateId,
        message,
      );
}

/// Rapport agrégé des diagnostics [`EnvironmentPreset`] pour un [`ProjectManifest`].
final class EnvironmentPresetDiagnosticsReport {
  factory EnvironmentPresetDiagnosticsReport({
    required List<EnvironmentPresetDiagnostic> diagnostics,
  }) {
    return EnvironmentPresetDiagnosticsReport._(
      diagnostics: List<EnvironmentPresetDiagnostic>.unmodifiable(
        List<EnvironmentPresetDiagnostic>.from(diagnostics),
      ),
    );
  }

  const EnvironmentPresetDiagnosticsReport._({
    required this.diagnostics,
  });

  final List<EnvironmentPresetDiagnostic> diagnostics;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  bool get hasErrors => diagnostics.any(
        (d) => d.severity == EnvironmentPresetDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (d) => d.severity == EnvironmentPresetDiagnosticSeverity.warning,
      );

  int get diagnosticCount => diagnostics.length;

  int get errorCount => diagnostics
      .where((d) => d.severity == EnvironmentPresetDiagnosticSeverity.error)
      .length;

  int get warningCount => diagnostics
      .where((d) => d.severity == EnvironmentPresetDiagnosticSeverity.warning)
      .length;

  List<EnvironmentPresetDiagnostic> diagnosticsForPreset(String presetId) {
    final key = presetId.trim();
    if (key.isEmpty) {
      return const [];
    }
    final out = <EnvironmentPresetDiagnostic>[];
    for (final d in diagnostics) {
      if (d.presetId == key) {
        out.add(d);
      }
    }
    return List<EnvironmentPresetDiagnostic>.unmodifiable(out);
  }

  List<EnvironmentPresetDiagnostic> diagnosticsForKind(
    EnvironmentPresetDiagnosticKind kind,
  ) {
    return List<EnvironmentPresetDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPresetDiagnosticsReport &&
            _listEqualsDiagnostics(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hashAll(diagnostics);
}

bool _listEqualsDiagnostics(
  List<EnvironmentPresetDiagnostic> a,
  List<EnvironmentPresetDiagnostic> b,
) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Diagnostique les [`EnvironmentPreset`] du manifest (aucune mutation, jamais d’exception).
///
/// [knownTemplateIds] vide : aucun diagnostic [unknownTemplateId]. Sinon, tout
/// [EnvironmentPreset.templateId] absent du set génère un avertissement.
EnvironmentPresetDiagnosticsReport diagnoseProjectEnvironmentPresets(
  ProjectManifest manifest, {
  Set<String> knownTemplateIds = const <String>{},
}) {
  final diagnostics = <EnvironmentPresetDiagnostic>[];
  final presets = manifest.environmentPresets;

  final firstIndex = <String, int>{};
  final duplicateIds = <String>{};
  for (var i = 0; i < presets.length; i++) {
    final id = presets[i].id;
    if (firstIndex.containsKey(id)) {
      duplicateIds.add(id);
    } else {
      firstIndex[id] = i;
    }
  }
  final orderedDuplicateIds = duplicateIds.toList(growable: false)
    ..sort((a, b) => firstIndex[a]!.compareTo(firstIndex[b]!));

  for (final dupId in orderedDuplicateIds) {
    diagnostics.add(
      EnvironmentPresetDiagnostic(
        severity: EnvironmentPresetDiagnosticSeverity.error,
        kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
        presetId: dupId,
        message: 'Environment preset "$dupId" is declared more than once.',
      ),
    );
  }

  final elementsById = <String, ProjectElementEntry>{
    for (final e in manifest.elements) e.id: e,
  };

  for (final preset in presets) {
    for (final item in preset.palette) {
      if (!elementsById.containsKey(item.elementId)) {
        diagnostics.add(
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.error,
            kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
            presetId: preset.id,
            elementId: item.elementId,
            message:
                'Environment preset "${preset.id}" references missing element "${item.elementId}".',
          ),
        );
      }
    }

    for (final item in preset.palette) {
      if (item.collisionMode != EnvironmentCollisionMode.forceEnabled) {
        continue;
      }
      final entry = elementsById[item.elementId];
      if (entry == null) {
        continue;
      }
      if (entry.collisionProfile == null) {
        diagnostics.add(
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.warning,
            kind: EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
            presetId: preset.id,
            elementId: item.elementId,
            message:
                'Environment preset "${preset.id}" forces collision for element "${item.elementId}", but this element has no collision profile.',
          ),
        );
      }
    }

    if (knownTemplateIds.isNotEmpty &&
        !knownTemplateIds.contains(preset.templateId)) {
      diagnostics.add(
        EnvironmentPresetDiagnostic(
          severity: EnvironmentPresetDiagnosticSeverity.warning,
          kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
          presetId: preset.id,
          templateId: preset.templateId,
          message:
              'Environment preset "${preset.id}" uses unknown template "${preset.templateId}".',
        ),
      );
    }
  }

  return EnvironmentPresetDiagnosticsReport(diagnostics: diagnostics);
}

```

### `environment_preset_diagnostics_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'diag_test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: environmentPresets,
    elements: elements,
  );
}

EnvironmentPreset _preset({
  required String id,
  required String templateId,
  List<EnvironmentPaletteItem>? palette,
}) {
  return EnvironmentPreset(
    id: id,
    name: 'n_$id',
    templateId: templateId,
    palette: palette ??
        [
          EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
        ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({
  required String id,
  ElementCollisionProfile? collisionProfile,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'name_$id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
    collisionProfile: collisionProfile,
  );
}

void main() {
  group('EnvironmentPresetDiagnosticsReport', () {
    test('vide : pas de diagnostics', () {
      final r = EnvironmentPresetDiagnosticsReport(diagnostics: []);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.hasWarnings, isFalse);
      expect(r.diagnosticCount, 0);
      expect(r.errorCount, 0);
      expect(r.warningCount, 0);
    });

    test('copie défensive et liste immuable exposée', () {
      final raw = <EnvironmentPresetDiagnostic>[
        EnvironmentPresetDiagnostic(
          severity: EnvironmentPresetDiagnosticSeverity.error,
          kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
          presetId: 'x',
          message: 'm',
        ),
      ];
      final r = EnvironmentPresetDiagnosticsReport(diagnostics: raw);
      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
      raw.clear();
      expect(r.diagnosticCount, 1);
    });

    test('errorCount / warningCount / diagnosticCount', () {
      final r = EnvironmentPresetDiagnosticsReport(
        diagnostics: [
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.error,
            kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
            presetId: 'p',
            elementId: 'e',
            message: 'm1',
          ),
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.warning,
            kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
            presetId: 'p',
            templateId: 't',
            message: 'm2',
          ),
        ],
      );
      expect(r.diagnosticCount, 2);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
    });

    test('diagnosticsForPreset trim et vide/inconnu => []', () {
      final r = EnvironmentPresetDiagnosticsReport(
        diagnostics: [
          EnvironmentPresetDiagnostic(
            severity: EnvironmentPresetDiagnosticSeverity.error,
            kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
            presetId: 'ab',
            message: 'dup',
          ),
        ],
      );
      expect(r.diagnosticsForPreset('  ab  ').length, 1);
      expect(r.diagnosticsForPreset(''), isEmpty);
      expect(r.diagnosticsForPreset('zz'), isEmpty);
    });

    test('diagnosticsForKind retourne liste immuable', () {
      final d = EnvironmentPresetDiagnostic(
        severity: EnvironmentPresetDiagnosticSeverity.error,
        kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
        presetId: 'p',
        elementId: 'e',
        message: 'm',
      );
      final r = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
      final list = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.missingPaletteElement,
      );
      expect(list.length, 1);
      expect(() => list.add(d), throwsUnsupportedError);
    });

    test('égalité de valeur report et diagnostic', () {
      final d = EnvironmentPresetDiagnostic(
        severity: EnvironmentPresetDiagnosticSeverity.warning,
        kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
        presetId: 'p',
        templateId: 't',
        message: 'msg',
      );
      final r1 = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
      final r2 = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
      expect(r1, equals(r2));
      expect(d == d, isTrue);
    });
  });

  group('diagnoseProjectEnvironmentPresets duplicatePresetId', () {
    test('aucun doublon => rien', () {
      final m = _manifest(
        environmentPresets: [
          _preset(id: 'a', templateId: 't'),
          _preset(id: 'b', templateId: 't'),
        ],
        elements: [_element(id: 'elm_ok')],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      expect(
        r.diagnosticsForKind(EnvironmentPresetDiagnosticKind.duplicatePresetId),
        isEmpty,
      );
    });

    test('deux presets même id => un diagnostic', () {
      final dup = _preset(id: 'forest_dense', templateId: 'tpl');
      final m = _manifest(
        environmentPresets: [dup, dup],
        elements: [_element(id: 'elm_ok')],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      final dups = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.duplicatePresetId,
      );
      expect(dups.length, 1);
      expect(dups.single.presetId, 'forest_dense');
      expect(dups.single.severity, EnvironmentPresetDiagnosticSeverity.error);
      expect(
        dups.single.message,
        'Environment preset "forest_dense" is declared more than once.',
      );
    });

    test('trois presets même id => un seul diagnostic pour cet id', () {
      final p = _preset(id: 'x', templateId: 't');
      final m = _manifest(
        environmentPresets: [p, p, p],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m)
            .diagnosticsForKind(
              EnvironmentPresetDiagnosticKind.duplicatePresetId,
            )
            .length,
        1,
      );
    });

    test('deux ids dupliqués distincts => deux diagnostics ordre stable', () {
      final a = _preset(id: 'a', templateId: 't');
      final b = _preset(id: 'b', templateId: 't');
      final m = _manifest(
        environmentPresets: [a, a, b, b],
        elements: [_element(id: 'elm_ok')],
      );
      final kinds = diagnoseProjectEnvironmentPresets(m)
          .diagnostics
          .map((e) => e.kind)
          .toList();
      expect(
        kinds
            .where(
                (k) => k == EnvironmentPresetDiagnosticKind.duplicatePresetId)
            .length,
        2,
      );
      final dupMsgs = diagnoseProjectEnvironmentPresets(m)
          .diagnosticsForKind(
            EnvironmentPresetDiagnosticKind.duplicatePresetId,
          )
          .map((e) => e.presetId)
          .toList();
      expect(dupMsgs, ['a', 'b']);
    });
  });

  group('missingPaletteElement', () {
    test('element présent => pas missing', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 't')],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.missingPaletteElement,
        ),
        isEmpty,
      );
    });

    test('element absent => error', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'forest_dense',
            name: 'F',
            templateId: 'tpl',
            palette: [
              EnvironmentPaletteItem(elementId: 'oak_tree_large', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      final miss = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.missingPaletteElement,
      );
      expect(miss.length, 1);
      expect(miss.single.elementId, 'oak_tree_large');
      expect(
        miss.single.message,
        'Environment preset "forest_dense" references missing element "oak_tree_large".',
      );
    });

    test('deux presets référencent même absent => un diagnostic par preset',
        () {
      final palette = [
        EnvironmentPaletteItem(elementId: 'ghost', weight: 1),
      ];
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p1',
            name: 'A',
            templateId: 't',
            palette: palette,
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
          EnvironmentPreset(
            id: 'p2',
            name: 'B',
            templateId: 't',
            palette: palette,
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 1,
          ),
        ],
        elements: [],
      );
      final miss = diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.missingPaletteElement,
      );
      expect(miss.length, 2);
      expect(miss.map((e) => e.presetId).toList(), ['p1', 'p2']);
    });
  });

  group('unknownTemplateId', () {
    test('knownTemplateIds vide => aucun unknownTemplateId', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'anything')],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
        ),
        isEmpty,
      );
    });

    test('template connu => rien', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'forest_dense')],
        elements: [_element(id: 'elm_ok')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(
          m,
          knownTemplateIds: {'forest_dense'},
        ).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
        ),
        isEmpty,
      );
    });

    test('template inconnu => warning', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'forest_dense_v9')],
        elements: [_element(id: 'elm_ok')],
      );
      final r = diagnoseProjectEnvironmentPresets(
        m,
        knownTemplateIds: {'other'},
      );
      final w = r.diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.unknownTemplateId,
      );
      expect(w.length, 1);
      expect(w.single.templateId, 'forest_dense_v9');
      expect(w.single.severity, EnvironmentPresetDiagnosticSeverity.warning);
      expect(
        w.single.message,
        'Environment preset "p" uses unknown template "forest_dense_v9".',
      );
    });
  });

  group('forcedCollisionWithoutProfile', () {
    test('forceEnabled + collisionProfile non-null => rien', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [
          _element(
            id: 'oak',
            collisionProfile: const ElementCollisionProfile(),
          ),
        ],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });

    test('forceEnabled + collisionProfile null => warning', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'forest_dense',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak_tree_large',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [
          _element(id: 'oak_tree_large', collisionProfile: null),
        ],
      );
      final w = diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
        EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
      );
      expect(w.length, 1);
      expect(w.single.elementId, 'oak_tree_large');
      expect(
        w.single.message,
        'Environment preset "forest_dense" forces collision for element "oak_tree_large", but this element has no collision profile.',
      );
    });

    test('useElementDefault + collisionProfile null => rien', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.useElementDefault,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [_element(id: 'oak')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });

    test('forceDisabled + collisionProfile null => rien', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'oak',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceDisabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [_element(id: 'oak')],
      );
      expect(
        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });

    test('element absent + forceEnabled => seulement missingPaletteElement',
        () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p',
            name: 'P',
            templateId: 't',
            palette: [
              EnvironmentPaletteItem(
                elementId: 'missing_el',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: [],
      );
      final r = diagnoseProjectEnvironmentPresets(m);
      expect(
        r
            .diagnosticsForKind(
              EnvironmentPresetDiagnosticKind.missingPaletteElement,
            )
            .length,
        1,
      );
      expect(
        r.diagnosticsForKind(
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
        ),
        isEmpty,
      );
    });
  });

  group('ordre stable des diagnostics', () {
    test('duplicate puis missing puis forced puis unknown', () {
      final m = _manifest(
        environmentPresets: [
          EnvironmentPreset(
            id: 'dup',
            name: 'A',
            templateId: 'bad_tpl',
            palette: [
              EnvironmentPaletteItem(elementId: 'missing', weight: 1),
              EnvironmentPaletteItem(
                elementId: 'no_profile',
                weight: 1,
                collisionMode: EnvironmentCollisionMode.forceEnabled,
              ),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
          EnvironmentPreset(
            id: 'dup',
            name: 'B',
            templateId: 'bad_tpl',
            palette: [
              EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 1,
          ),
        ],
        elements: [
          _element(id: 'elm_ok'),
          _element(id: 'no_profile', collisionProfile: null),
        ],
      );
      final r = diagnoseProjectEnvironmentPresets(
        m,
        knownTemplateIds: {'known_only'},
      );
      final kinds = r.diagnostics.map((e) => e.kind).toList();
      // duplicatePresetId, puis 1er preset: missing, forced, unknown ; 2e preset: unknown seulement
      expect(
        kinds,
        [
          EnvironmentPresetDiagnosticKind.duplicatePresetId,
          EnvironmentPresetDiagnosticKind.missingPaletteElement,
          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
          EnvironmentPresetDiagnosticKind.unknownTemplateId,
        ],
      );
    });
  });
}

```

### Extraits `map_core.dart` — exports Environment (Lot 5 + 6)

```dart
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
```

## 14. Diff complet

### `git diff packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index ba2a115a..239002e5 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -74,6 +74,9 @@ export 'src/collision/pixel_rect.dart';
 export 'src/collision/player_collision_conventions_v1.dart';
 export 'src/operations/map_layers.dart';
 export 'src/operations/environment_layer_content_json_codec.dart';
+export 'src/operations/environment_preset_json_codec.dart';
+export 'src/operations/project_manifest_environment_preset_operations.dart';
+export 'src/operations/environment_preset_diagnostics.dart';
 export 'src/operations/surface_layer_placements.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';

```

### `git diff --no-index /dev/null` → `environment_preset_diagnostics.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/environment_preset_diagnostics.dart b/packages/map_core/lib/src/operations/environment_preset_diagnostics.dart
new file mode 100644
index 00000000..399cdd8c
--- /dev/null
+++ b/packages/map_core/lib/src/operations/environment_preset_diagnostics.dart
@@ -0,0 +1,241 @@
+import '../models/environment.dart';
+import '../models/project_manifest.dart';
+
+/// Gravité d’un diagnostic preset environnement (Lot Environment-6).
+enum EnvironmentPresetDiagnosticSeverity {
+  error,
+  warning,
+}
+
+/// Catégorie de diagnostic (Lot Environment-6).
+enum EnvironmentPresetDiagnosticKind {
+  duplicatePresetId,
+  missingPaletteElement,
+  unknownTemplateId,
+  forcedCollisionWithoutProfile,
+}
+
+/// Un problème détecté sur les presets Environment du manifest.
+final class EnvironmentPresetDiagnostic {
+  const EnvironmentPresetDiagnostic({
+    required this.severity,
+    required this.kind,
+    required this.presetId,
+    this.elementId,
+    this.templateId,
+    required this.message,
+  });
+
+  final EnvironmentPresetDiagnosticSeverity severity;
+  final EnvironmentPresetDiagnosticKind kind;
+  final String presetId;
+  final String? elementId;
+  final String? templateId;
+  final String message;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentPresetDiagnostic &&
+            severity == other.severity &&
+            kind == other.kind &&
+            presetId == other.presetId &&
+            elementId == other.elementId &&
+            templateId == other.templateId &&
+            message == other.message;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        severity,
+        kind,
+        presetId,
+        elementId,
+        templateId,
+        message,
+      );
+}
+
+/// Rapport agrégé des diagnostics [`EnvironmentPreset`] pour un [`ProjectManifest`].
+final class EnvironmentPresetDiagnosticsReport {
+  factory EnvironmentPresetDiagnosticsReport({
+    required List<EnvironmentPresetDiagnostic> diagnostics,
+  }) {
+    return EnvironmentPresetDiagnosticsReport._(
+      diagnostics: List<EnvironmentPresetDiagnostic>.unmodifiable(
+        List<EnvironmentPresetDiagnostic>.from(diagnostics),
+      ),
+    );
+  }
+
+  const EnvironmentPresetDiagnosticsReport._({
+    required this.diagnostics,
+  });
+
+  final List<EnvironmentPresetDiagnostic> diagnostics;
+
+  bool get hasDiagnostics => diagnostics.isNotEmpty;
+
+  bool get hasErrors => diagnostics.any(
+        (d) => d.severity == EnvironmentPresetDiagnosticSeverity.error,
+      );
+
+  bool get hasWarnings => diagnostics.any(
+        (d) => d.severity == EnvironmentPresetDiagnosticSeverity.warning,
+      );
+
+  int get diagnosticCount => diagnostics.length;
+
+  int get errorCount => diagnostics
+      .where((d) => d.severity == EnvironmentPresetDiagnosticSeverity.error)
+      .length;
+
+  int get warningCount => diagnostics
+      .where((d) => d.severity == EnvironmentPresetDiagnosticSeverity.warning)
+      .length;
+
+  List<EnvironmentPresetDiagnostic> diagnosticsForPreset(String presetId) {
+    final key = presetId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    final out = <EnvironmentPresetDiagnostic>[];
+    for (final d in diagnostics) {
+      if (d.presetId == key) {
+        out.add(d);
+      }
+    }
+    return List<EnvironmentPresetDiagnostic>.unmodifiable(out);
+  }
+
+  List<EnvironmentPresetDiagnostic> diagnosticsForKind(
+    EnvironmentPresetDiagnosticKind kind,
+  ) {
+    return List<EnvironmentPresetDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.kind == kind).toList(growable: false),
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentPresetDiagnosticsReport &&
+            _listEqualsDiagnostics(other.diagnostics, diagnostics);
+  }
+
+  @override
+  int get hashCode => Object.hashAll(diagnostics);
+}
+
+bool _listEqualsDiagnostics(
+  List<EnvironmentPresetDiagnostic> a,
+  List<EnvironmentPresetDiagnostic> b,
+) {
+  if (identical(a, b)) {
+    return true;
+  }
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+/// Diagnostique les [`EnvironmentPreset`] du manifest (aucune mutation, jamais d’exception).
+///
+/// [knownTemplateIds] vide : aucun diagnostic [unknownTemplateId]. Sinon, tout
+/// [EnvironmentPreset.templateId] absent du set génère un avertissement.
+EnvironmentPresetDiagnosticsReport diagnoseProjectEnvironmentPresets(
+  ProjectManifest manifest, {
+  Set<String> knownTemplateIds = const <String>{},
+}) {
+  final diagnostics = <EnvironmentPresetDiagnostic>[];
+  final presets = manifest.environmentPresets;
+
+  final firstIndex = <String, int>{};
+  final duplicateIds = <String>{};
+  for (var i = 0; i < presets.length; i++) {
+    final id = presets[i].id;
+    if (firstIndex.containsKey(id)) {
+      duplicateIds.add(id);
+    } else {
+      firstIndex[id] = i;
+    }
+  }
+  final orderedDuplicateIds = duplicateIds.toList(growable: false)
+    ..sort((a, b) => firstIndex[a]!.compareTo(firstIndex[b]!));
+
+  for (final dupId in orderedDuplicateIds) {
+    diagnostics.add(
+      EnvironmentPresetDiagnostic(
+        severity: EnvironmentPresetDiagnosticSeverity.error,
+        kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
+        presetId: dupId,
+        message: 'Environment preset "$dupId" is declared more than once.',
+      ),
+    );
+  }
+
+  final elementsById = <String, ProjectElementEntry>{
+    for (final e in manifest.elements) e.id: e,
+  };
+
+  for (final preset in presets) {
+    for (final item in preset.palette) {
+      if (!elementsById.containsKey(item.elementId)) {
+        diagnostics.add(
+          EnvironmentPresetDiagnostic(
+            severity: EnvironmentPresetDiagnosticSeverity.error,
+            kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
+            presetId: preset.id,
+            elementId: item.elementId,
+            message:
+                'Environment preset "${preset.id}" references missing element "${item.elementId}".',
+          ),
+        );
+      }
+    }
+
+    for (final item in preset.palette) {
+      if (item.collisionMode != EnvironmentCollisionMode.forceEnabled) {
+        continue;
+      }
+      final entry = elementsById[item.elementId];
+      if (entry == null) {
+        continue;
+      }
+      if (entry.collisionProfile == null) {
+        diagnostics.add(
+          EnvironmentPresetDiagnostic(
+            severity: EnvironmentPresetDiagnosticSeverity.warning,
+            kind: EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+            presetId: preset.id,
+            elementId: item.elementId,
+            message:
+                'Environment preset "${preset.id}" forces collision for element "${item.elementId}", but this element has no collision profile.',
+          ),
+        );
+      }
+    }
+
+    if (knownTemplateIds.isNotEmpty &&
+        !knownTemplateIds.contains(preset.templateId)) {
+      diagnostics.add(
+        EnvironmentPresetDiagnostic(
+          severity: EnvironmentPresetDiagnosticSeverity.warning,
+          kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
+          presetId: preset.id,
+          templateId: preset.templateId,
+          message:
+              'Environment preset "${preset.id}" uses unknown template "${preset.templateId}".',
+        ),
+      );
+    }
+  }
+
+  return EnvironmentPresetDiagnosticsReport(diagnostics: diagnostics);
+}

```

### `git diff --no-index /dev/null` → `environment_preset_diagnostics_test.dart`

```diff
diff --git a/packages/map_core/test/environment_preset_diagnostics_test.dart b/packages/map_core/test/environment_preset_diagnostics_test.dart
new file mode 100644
index 00000000..79169909
--- /dev/null
+++ b/packages/map_core/test/environment_preset_diagnostics_test.dart
@@ -0,0 +1,574 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+ProjectManifest _manifest({
+  List<EnvironmentPreset> environmentPresets = const [],
+  List<ProjectElementEntry> elements = const [],
+}) {
+  return ProjectManifest(
+    name: 'diag_test',
+    maps: const [],
+    tilesets: const [],
+    surfaceCatalog: ProjectSurfaceCatalog(),
+    environmentPresets: environmentPresets,
+    elements: elements,
+  );
+}
+
+EnvironmentPreset _preset({
+  required String id,
+  required String templateId,
+  List<EnvironmentPaletteItem>? palette,
+}) {
+  return EnvironmentPreset(
+    id: id,
+    name: 'n_$id',
+    templateId: templateId,
+    palette: palette ??
+        [
+          EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
+        ],
+    defaultParams: EnvironmentGenerationParams.standard(),
+    sortOrder: 0,
+  );
+}
+
+ProjectElementEntry _element({
+  required String id,
+  ElementCollisionProfile? collisionProfile,
+}) {
+  return ProjectElementEntry(
+    id: id,
+    name: 'name_$id',
+    tilesetId: 'ts',
+    categoryId: 'cat',
+    frames: [
+      TilesetVisualFrame(
+        source: TilesetSourceRect(x: 0, y: 0),
+      ),
+    ],
+    collisionProfile: collisionProfile,
+  );
+}
+
+void main() {
+  group('EnvironmentPresetDiagnosticsReport', () {
+    test('vide : pas de diagnostics', () {
+      final r = EnvironmentPresetDiagnosticsReport(diagnostics: []);
+      expect(r.hasDiagnostics, isFalse);
+      expect(r.hasErrors, isFalse);
+      expect(r.hasWarnings, isFalse);
+      expect(r.diagnosticCount, 0);
+      expect(r.errorCount, 0);
+      expect(r.warningCount, 0);
+    });
+
+    test('copie défensive et liste immuable exposée', () {
+      final raw = <EnvironmentPresetDiagnostic>[
+        EnvironmentPresetDiagnostic(
+          severity: EnvironmentPresetDiagnosticSeverity.error,
+          kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
+          presetId: 'x',
+          message: 'm',
+        ),
+      ];
+      final r = EnvironmentPresetDiagnosticsReport(diagnostics: raw);
+      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
+      raw.clear();
+      expect(r.diagnosticCount, 1);
+    });
+
+    test('errorCount / warningCount / diagnosticCount', () {
+      final r = EnvironmentPresetDiagnosticsReport(
+        diagnostics: [
+          EnvironmentPresetDiagnostic(
+            severity: EnvironmentPresetDiagnosticSeverity.error,
+            kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
+            presetId: 'p',
+            elementId: 'e',
+            message: 'm1',
+          ),
+          EnvironmentPresetDiagnostic(
+            severity: EnvironmentPresetDiagnosticSeverity.warning,
+            kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
+            presetId: 'p',
+            templateId: 't',
+            message: 'm2',
+          ),
+        ],
+      );
+      expect(r.diagnosticCount, 2);
+      expect(r.errorCount, 1);
+      expect(r.warningCount, 1);
+    });
+
+    test('diagnosticsForPreset trim et vide/inconnu => []', () {
+      final r = EnvironmentPresetDiagnosticsReport(
+        diagnostics: [
+          EnvironmentPresetDiagnostic(
+            severity: EnvironmentPresetDiagnosticSeverity.error,
+            kind: EnvironmentPresetDiagnosticKind.duplicatePresetId,
+            presetId: 'ab',
+            message: 'dup',
+          ),
+        ],
+      );
+      expect(r.diagnosticsForPreset('  ab  ').length, 1);
+      expect(r.diagnosticsForPreset(''), isEmpty);
+      expect(r.diagnosticsForPreset('zz'), isEmpty);
+    });
+
+    test('diagnosticsForKind retourne liste immuable', () {
+      final d = EnvironmentPresetDiagnostic(
+        severity: EnvironmentPresetDiagnosticSeverity.error,
+        kind: EnvironmentPresetDiagnosticKind.missingPaletteElement,
+        presetId: 'p',
+        elementId: 'e',
+        message: 'm',
+      );
+      final r = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
+      final list = r.diagnosticsForKind(
+        EnvironmentPresetDiagnosticKind.missingPaletteElement,
+      );
+      expect(list.length, 1);
+      expect(() => list.add(d), throwsUnsupportedError);
+    });
+
+    test('égalité de valeur report et diagnostic', () {
+      final d = EnvironmentPresetDiagnostic(
+        severity: EnvironmentPresetDiagnosticSeverity.warning,
+        kind: EnvironmentPresetDiagnosticKind.unknownTemplateId,
+        presetId: 'p',
+        templateId: 't',
+        message: 'msg',
+      );
+      final r1 = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
+      final r2 = EnvironmentPresetDiagnosticsReport(diagnostics: [d]);
+      expect(r1, equals(r2));
+      expect(d == d, isTrue);
+    });
+  });
+
+  group('diagnoseProjectEnvironmentPresets duplicatePresetId', () {
+    test('aucun doublon => rien', () {
+      final m = _manifest(
+        environmentPresets: [
+          _preset(id: 'a', templateId: 't'),
+          _preset(id: 'b', templateId: 't'),
+        ],
+        elements: [_element(id: 'elm_ok')],
+      );
+      final r = diagnoseProjectEnvironmentPresets(m);
+      expect(
+        r.diagnosticsForKind(EnvironmentPresetDiagnosticKind.duplicatePresetId),
+        isEmpty,
+      );
+    });
+
+    test('deux presets même id => un diagnostic', () {
+      final dup = _preset(id: 'forest_dense', templateId: 'tpl');
+      final m = _manifest(
+        environmentPresets: [dup, dup],
+        elements: [_element(id: 'elm_ok')],
+      );
+      final r = diagnoseProjectEnvironmentPresets(m);
+      final dups = r.diagnosticsForKind(
+        EnvironmentPresetDiagnosticKind.duplicatePresetId,
+      );
+      expect(dups.length, 1);
+      expect(dups.single.presetId, 'forest_dense');
+      expect(dups.single.severity, EnvironmentPresetDiagnosticSeverity.error);
+      expect(
+        dups.single.message,
+        'Environment preset "forest_dense" is declared more than once.',
+      );
+    });
+
+    test('trois presets même id => un seul diagnostic pour cet id', () {
+      final p = _preset(id: 'x', templateId: 't');
+      final m = _manifest(
+        environmentPresets: [p, p, p],
+        elements: [_element(id: 'elm_ok')],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(m)
+            .diagnosticsForKind(
+              EnvironmentPresetDiagnosticKind.duplicatePresetId,
+            )
+            .length,
+        1,
+      );
+    });
+
+    test('deux ids dupliqués distincts => deux diagnostics ordre stable', () {
+      final a = _preset(id: 'a', templateId: 't');
+      final b = _preset(id: 'b', templateId: 't');
+      final m = _manifest(
+        environmentPresets: [a, a, b, b],
+        elements: [_element(id: 'elm_ok')],
+      );
+      final kinds = diagnoseProjectEnvironmentPresets(m)
+          .diagnostics
+          .map((e) => e.kind)
+          .toList();
+      expect(
+        kinds
+            .where(
+                (k) => k == EnvironmentPresetDiagnosticKind.duplicatePresetId)
+            .length,
+        2,
+      );
+      final dupMsgs = diagnoseProjectEnvironmentPresets(m)
+          .diagnosticsForKind(
+            EnvironmentPresetDiagnosticKind.duplicatePresetId,
+          )
+          .map((e) => e.presetId)
+          .toList();
+      expect(dupMsgs, ['a', 'b']);
+    });
+  });
+
+  group('missingPaletteElement', () {
+    test('element présent => pas missing', () {
+      final m = _manifest(
+        environmentPresets: [_preset(id: 'p', templateId: 't')],
+        elements: [_element(id: 'elm_ok')],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.missingPaletteElement,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('element absent => error', () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'forest_dense',
+            name: 'F',
+            templateId: 'tpl',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'oak_tree_large', weight: 1),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+        elements: [],
+      );
+      final r = diagnoseProjectEnvironmentPresets(m);
+      final miss = r.diagnosticsForKind(
+        EnvironmentPresetDiagnosticKind.missingPaletteElement,
+      );
+      expect(miss.length, 1);
+      expect(miss.single.elementId, 'oak_tree_large');
+      expect(
+        miss.single.message,
+        'Environment preset "forest_dense" references missing element "oak_tree_large".',
+      );
+    });
+
+    test('deux presets référencent même absent => un diagnostic par preset',
+        () {
+      final palette = [
+        EnvironmentPaletteItem(elementId: 'ghost', weight: 1),
+      ];
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'p1',
+            name: 'A',
+            templateId: 't',
+            palette: palette,
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+          EnvironmentPreset(
+            id: 'p2',
+            name: 'B',
+            templateId: 't',
+            palette: palette,
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 1,
+          ),
+        ],
+        elements: [],
+      );
+      final miss = diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+        EnvironmentPresetDiagnosticKind.missingPaletteElement,
+      );
+      expect(miss.length, 2);
+      expect(miss.map((e) => e.presetId).toList(), ['p1', 'p2']);
+    });
+  });
+
+  group('unknownTemplateId', () {
+    test('knownTemplateIds vide => aucun unknownTemplateId', () {
+      final m = _manifest(
+        environmentPresets: [_preset(id: 'p', templateId: 'anything')],
+        elements: [_element(id: 'elm_ok')],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.unknownTemplateId,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('template connu => rien', () {
+      final m = _manifest(
+        environmentPresets: [_preset(id: 'p', templateId: 'forest_dense')],
+        elements: [_element(id: 'elm_ok')],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(
+          m,
+          knownTemplateIds: {'forest_dense'},
+        ).diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.unknownTemplateId,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('template inconnu => warning', () {
+      final m = _manifest(
+        environmentPresets: [_preset(id: 'p', templateId: 'forest_dense_v9')],
+        elements: [_element(id: 'elm_ok')],
+      );
+      final r = diagnoseProjectEnvironmentPresets(
+        m,
+        knownTemplateIds: {'other'},
+      );
+      final w = r.diagnosticsForKind(
+        EnvironmentPresetDiagnosticKind.unknownTemplateId,
+      );
+      expect(w.length, 1);
+      expect(w.single.templateId, 'forest_dense_v9');
+      expect(w.single.severity, EnvironmentPresetDiagnosticSeverity.warning);
+      expect(
+        w.single.message,
+        'Environment preset "p" uses unknown template "forest_dense_v9".',
+      );
+    });
+  });
+
+  group('forcedCollisionWithoutProfile', () {
+    test('forceEnabled + collisionProfile non-null => rien', () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'p',
+            name: 'P',
+            templateId: 't',
+            palette: [
+              EnvironmentPaletteItem(
+                elementId: 'oak',
+                weight: 1,
+                collisionMode: EnvironmentCollisionMode.forceEnabled,
+              ),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+        elements: [
+          _element(
+            id: 'oak',
+            collisionProfile: const ElementCollisionProfile(),
+          ),
+        ],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('forceEnabled + collisionProfile null => warning', () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'forest_dense',
+            name: 'P',
+            templateId: 't',
+            palette: [
+              EnvironmentPaletteItem(
+                elementId: 'oak_tree_large',
+                weight: 1,
+                collisionMode: EnvironmentCollisionMode.forceEnabled,
+              ),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+        elements: [
+          _element(id: 'oak_tree_large', collisionProfile: null),
+        ],
+      );
+      final w = diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+        EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+      );
+      expect(w.length, 1);
+      expect(w.single.elementId, 'oak_tree_large');
+      expect(
+        w.single.message,
+        'Environment preset "forest_dense" forces collision for element "oak_tree_large", but this element has no collision profile.',
+      );
+    });
+
+    test('useElementDefault + collisionProfile null => rien', () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'p',
+            name: 'P',
+            templateId: 't',
+            palette: [
+              EnvironmentPaletteItem(
+                elementId: 'oak',
+                weight: 1,
+                collisionMode: EnvironmentCollisionMode.useElementDefault,
+              ),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+        elements: [_element(id: 'oak')],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('forceDisabled + collisionProfile null => rien', () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'p',
+            name: 'P',
+            templateId: 't',
+            palette: [
+              EnvironmentPaletteItem(
+                elementId: 'oak',
+                weight: 1,
+                collisionMode: EnvironmentCollisionMode.forceDisabled,
+              ),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+        elements: [_element(id: 'oak')],
+      );
+      expect(
+        diagnoseProjectEnvironmentPresets(m).diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('element absent + forceEnabled => seulement missingPaletteElement',
+        () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'p',
+            name: 'P',
+            templateId: 't',
+            palette: [
+              EnvironmentPaletteItem(
+                elementId: 'missing_el',
+                weight: 1,
+                collisionMode: EnvironmentCollisionMode.forceEnabled,
+              ),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+        ],
+        elements: [],
+      );
+      final r = diagnoseProjectEnvironmentPresets(m);
+      expect(
+        r
+            .diagnosticsForKind(
+              EnvironmentPresetDiagnosticKind.missingPaletteElement,
+            )
+            .length,
+        1,
+      );
+      expect(
+        r.diagnosticsForKind(
+          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+        ),
+        isEmpty,
+      );
+    });
+  });
+
+  group('ordre stable des diagnostics', () {
+    test('duplicate puis missing puis forced puis unknown', () {
+      final m = _manifest(
+        environmentPresets: [
+          EnvironmentPreset(
+            id: 'dup',
+            name: 'A',
+            templateId: 'bad_tpl',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'missing', weight: 1),
+              EnvironmentPaletteItem(
+                elementId: 'no_profile',
+                weight: 1,
+                collisionMode: EnvironmentCollisionMode.forceEnabled,
+              ),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 0,
+          ),
+          EnvironmentPreset(
+            id: 'dup',
+            name: 'B',
+            templateId: 'bad_tpl',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'elm_ok', weight: 1),
+            ],
+            defaultParams: EnvironmentGenerationParams.standard(),
+            sortOrder: 1,
+          ),
+        ],
+        elements: [
+          _element(id: 'elm_ok'),
+          _element(id: 'no_profile', collisionProfile: null),
+        ],
+      );
+      final r = diagnoseProjectEnvironmentPresets(
+        m,
+        knownTemplateIds: {'known_only'},
+      );
+      final kinds = r.diagnostics.map((e) => e.kind).toList();
+      // duplicatePresetId, puis 1er preset: missing, forced, unknown ; 2e preset: unknown seulement
+      expect(
+        kinds,
+        [
+          EnvironmentPresetDiagnosticKind.duplicatePresetId,
+          EnvironmentPresetDiagnosticKind.missingPaletteElement,
+          EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile,
+          EnvironmentPresetDiagnosticKind.unknownTemplateId,
+          EnvironmentPresetDiagnosticKind.unknownTemplateId,
+        ],
+      );
+    });
+  });
+}

```

## 15. Auto-review

- **Points solides** — règles alignées prompt ; pas d’exception ; ordre documenté et testé.
- **Points discutables** — **`unknownTemplateId`** en warning : permet projets avec templates futurs ; **`knownTemplateIds`** vide désactive le diagnostic (opt-in). **`forcedCollisionWithoutProfile`** utile pour éviter des presets incohérents avec des éléments sans masque.
- **Pas de diagnostic carte** — **`presetId`** sur **`EnvironmentLayer`** : hors scope (**Environment-7**).
- **Corrections après auto-review** — test d’ordre ajusté au nombre réel de diagnostics (5 entrées).
- **Risques** — si **`elements`** contient des doublons d’id, la map **`elementsById`** garde le dernier ; hors périmètre manifest valide.
- **Prompt** — périmètre strict respecté (fichiers autorisés uniquement).

#### Regard critique (questions prompt)

- **`unknownTemplateId`** warning : oui, pour ne pas bloquer les projets avec templates customs.
- **`knownTemplateIds`** vide : désactive le diagnostic ; opt-in explicite.
- **`forcedCollisionWithoutProfile`** : strict côté auteur si collision forcée sans données ; pertinent avant générateur.
- **EnvironmentLayer** : non ; lot suivant.
- **ProjectManifest / MapLayer / UI** : non modifiés / non créés.

## 16. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
Diagnostics Environment presets (4 kinds) + tests + export ; map_core +1309 tests ; analyze OK ; pas ProjectManifest/MapLayer/UI/build_runner.
```

Prochain lot recommandé :

```text
Environment-7 — Environment Layer Usage Diagnostics V0
```

---

### Evidence Pack

- **Git** : §12.
- **`environment_preset_diagnostics.dart` intégral** : §13.
- **`environment_preset_diagnostics_test.dart` intégral** : §13.
- **Export `map_core`** : §13.
- **Diffs** : §14.
- **Tests ciblés / régressions** : §11.
- **`ProjectManifest` modèle** : fichier source non modifié.
- **`MapLayer`** : non modifié.
- **UI / générateur** : non créés.
- **`build_runner` / generated** : non lancé / non modifié.
- **Commit / git add / push** : non effectués.
