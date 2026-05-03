# Environment Studio Lot 7 — Environment Layer Usage Diagnostics V0

## 1. Résumé exécutif

Couche **`diagnoseMapEnvironmentLayerUsage(ProjectManifest, MapData)`** : 7 kinds (preset projet manquant pour une area, cible tuiles absente/type, mismatch masque / taille carte, masque vide, placements générés absents du `placedElements`). Rapport **`EnvironmentLayerUsageDiagnosticsReport`** analogue au Lot 6. **`+1331`** tests **`map_core`** verts ; **`dart analyze`** OK. **Aucune** modification **`ProjectManifest`** / **`MapLayer`** / **`MapValidator`** / UI / générateur / **`build_runner`**.

## 2. Périmètre du lot

Fichiers autorisés uniquement : **`environment_layer_usage_diagnostics.dart`**, **`map_core.dart`**, **`environment_layer_usage_diagnostics_test.dart`**, ce rapport.

## 3. Décisions de diagnostic

| Kind | Severity | Déclencheur |
|------|----------|-------------|
| `missingAreaPreset` | error | `presetId` absent de `manifest.environmentPresets` |
| `missingTargetTileLayerId` | warning | areas non vides et `targetTileLayerId == null` |
| `unknownTargetTileLayer` | error | id cible inexistant parmi `map.layers` |
| `targetLayerIsNotTileLayer` | error | layer trouvé mais pas `TileLayer` (y compris auto-cible) |
| `areaMaskSizeMismatch` | error | dimensions masque ≠ `map.size` |
| `emptyAreaMask` | warning | `!hasAnyActiveCell` |
| `missingGeneratedPlacement` | warning | id pas dans `map.placedElements` |

**Audit / remise en cause prompt** : l’ordre des variantes dans l’enum du prompt liste `missingAreaPreset` en tête alors que le **flux d’émission** suit la section §7 « target puis area » — l’enum sert uniquement à typer les diagnostics ; l’ordre réel est documenté dans le dartdoc et les tests (**§6**).

## 4. Types ajoutés

`EnvironmentLayerUsageDiagnosticSeverity`, `EnvironmentLayerUsageDiagnosticKind`, `EnvironmentLayerUsageDiagnostic`, `EnvironmentLayerUsageDiagnosticsReport`.

## 5. Fonction de diagnostic

`EnvironmentLayerUsageDiagnosticsReport diagnoseMapEnvironmentLayerUsage(ProjectManifest manifest, MapData map)` — uniquement lecture, aucune exception.

## 6. Ordre stable des diagnostics

Pour chaque **`EnvironmentLayer`** dans **`map.layers`** (ordre fichier) :

1. `missingTargetTileLayerId`
2. `unknownTargetTileLayer` (si cible renseignée et absente ; exclusif avec la suivante)
3. `targetLayerIsNotTileLayer` (si cible résolue et non-tuile)

Puis pour chaque **`EnvironmentArea`** dans **`content.areas`** :

a. `areaMaskSizeMismatch`  
b. `emptyAreaMask`  
c. `missingAreaPreset`  
d. `missingGeneratedPlacement` dans l’ordre de **`generatedPlacementIds`**.

## 7. Pourquoi aucun ProjectManifest / MapLayer / UI / générateur dans ce lot

Diagnostic croisé manifest + carte sans modifier les modèles ni le pipeline de validation carte existant (**`MapValidator`** inchangé).

## 8. Fichiers modifiés

- `packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart` (nouveau)
- `packages/map_core/lib/map_core.dart` (+1 export)
- `packages/map_core/test/environment_layer_usage_diagnostics_test.dart` (nouveau)
- `reports/forest/environment_studio_lot_7_environment_layer_usage_diagnostics.md`

## 9. Tests ajoutés

22 tests **`environment_layer_usage_diagnostics_test.dart`** (rapport + chaque kind + ordre agrégé) ; import public **`package:map_core/map_core.dart`**.

## 10. Commandes exécutées

```bash
cd packages/map_core
dart format lib/src/operations/environment_layer_usage_diagnostics.dart lib/map_core.dart test/environment_layer_usage_diagnostics_test.dart
dart analyze lib/src/operations/environment_layer_usage_diagnostics.dart lib/map_core.dart test/environment_layer_usage_diagnostics_test.dart
dart analyze
dart test test/environment_layer_usage_diagnostics_test.dart --reporter expanded
dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart test/environment_layer_content_json_codec_test.dart test/environment_layer_map_layer_integration_test.dart test/environment_preset_json_codec_test.dart test/project_manifest_environment_presets_test.dart test/environment_preset_diagnostics_test.dart --reporter expanded
dart test --reporter expanded
```

## 11. Résultats des commandes

### `dart analyze` (ciblé puis package)

```
Analyzing environment_layer_usage_diagnostics.dart, map_core.dart, environment_layer_usage_diagnostics_test.dart...
No issues found!
Analyzing map_core...
No issues found!
```

### Tests ciblés Lot 7 (expanded, sans ANSI)

```
00:00 +0: loading test/environment_layer_usage_diagnostics_test.dart
00:00 +0: EnvironmentLayerUsageDiagnosticsReport vide
00:00 +1: EnvironmentLayerUsageDiagnosticsReport copie défensive et liste immuable
00:00 +2: EnvironmentLayerUsageDiagnosticsReport counts et diagnosticsForLayer / Area / Kind
00:00 +3: EnvironmentLayerUsageDiagnosticsReport égalité
00:00 +4: missingAreaPreset preset présent => rien
00:00 +5: missingAreaPreset preset absent => error
00:00 +6: missingAreaPreset deux areas même preset absent => deux diagnostics
00:00 +7: missingTargetTileLayerId sans area => pas de warning
00:00 +8: missingTargetTileLayerId avec area sans target => warning
00:00 +9: unknownTargetTileLayer TileLayer existant => rien
00:00 +10: unknownTargetTileLayer cible inexistante => error
00:00 +11: targetLayerIsNotTileLayer ObjectLayer => error
00:00 +12: targetLayerIsNotTileLayer self EnvironmentLayer => error
00:00 +13: areaMaskSizeMismatch taille ok => rien
00:00 +14: areaMaskSizeMismatch width différent
00:00 +15: areaMaskSizeMismatch height différent
00:00 +16: emptyAreaMask au moins une cellule active => rien
00:00 +17: emptyAreaMask masque tout false => warning
00:00 +18: missingGeneratedPlacement ids présents => rien
00:00 +19: missingGeneratedPlacement id absent => warning avec message stable
00:00 +20: missingGeneratedPlacement plusieurs ids absents => ordre des generatedPlacementIds
00:00 +21: ordre stable targets puis areaMismatch, empty, preset, placements
00:00 +22: All tests passed!
```

### Régressions Environment (expanded, sans ANSI)

```
00:00 +0: loading test/environment_core_models_test.dart
00:00 +0: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item
00:00 +1: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +2: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +3: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +4: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +5: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +6: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +7: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +8: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +9: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +10: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +11: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +12: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +13: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +14: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content
00:00 +15: test/environment_core_models_test.dart: EnvironmentGenerationParams rejects negative minSpacingCells
00:00 +16: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts targetTileLayerId null
00:00 +17: test/environment_core_models_test.dart: EnvironmentGenerationParams standard factory
00:00 +18: test/environment_layer_content_test.dart: EnvironmentLayerContent construction trims targetTileLayerId when non-null
00:00 +19: test/environment_layer_content_test.dart: EnvironmentLayerContent construction trims targetTileLayerId when non-null
00:00 +20: test/environment_layer_content_test.dart: EnvironmentLayerContent construction trims targetTileLayerId when non-null
00:00 +21: test/environment_core_models_test.dart: EnvironmentAreaMask rejects width <= 0
00:00 +22: test/environment_layer_content_test.dart: EnvironmentLayerContent construction rejects targetTileLayerId whitespace only
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
00:00 +34: test/environment_core_models_test.dart: EnvironmentAreaMask cells copied defensively
00:00 +35: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea known id
00:00 +36: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea known id
00:00 +37: test/environment_core_models_test.dart: EnvironmentAreaMask cells list is unmodifiable
00:00 +38: test/environment_core_models_test.dart: EnvironmentAreaMask cells list is unmodifiable
00:00 +39: test/environment_core_models_test.dart: EnvironmentAreaMask cells list is unmodifiable
00:00 +40: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea trims argument
00:00 +41: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode targetTileLayerId whitespace => FormatException
00:00 +42: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode targetTileLayerId whitespace => FormatException
00:00 +43: test/environment_core_models_test.dart: EnvironmentAreaMask hasAnyActiveCell
00:00 +44: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for empty or whitespace id
00:00 +45: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for empty or whitespace id
00:00 +46: test/environment_core_models_test.dart: EnvironmentAreaMask activeCellCount
00:00 +47: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode area complète + paramsOverride + generatedPlacementIds
00:00 +48: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode area complète + paramsOverride + generatedPlacementIds
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
00:00 +63: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +64: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +65: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +66: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +67: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +68: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide
00:00 +69: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +70: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +71: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +72: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +73: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +74: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +75: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +76: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +77: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +78: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +79: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +80: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +81: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +82: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +83: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +84: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet
00:00 +85: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec codec strict int decode paramsOverride density hors plage => FormatException
00:00 +86: test/environment_core_models_test.dart: EnvironmentArea value equality
00:00 +87: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment fromJson sans content => content vide
00:00 +88: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet
00:00 +89: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet
00:00 +90: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet
00:00 +91: test/environment_core_models_test.dart: EnvironmentPreset accepts valid preset
00:00 +92: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds string vide => FormatException
00:00 +93: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +94: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +95: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +96: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +97: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +98: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +99: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +100: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +101: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode collisionMode absent/null => useElementDefault
00:00 +102: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict areas duplicate area id => FormatException
00:00 +103: test/environment_core_models_test.dart: EnvironmentPreset rejects duplicate elementId in palette
00:00 +104: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment insertIndex comme autres layers non-path
00:00 +105: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode collisionMode inconnu => FormatException
00:00 +106: test/environment_core_models_test.dart: EnvironmentPreset categoryId null ok
00:00 +107: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent remplace content et conserve méta
00:00 +108: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tags absent/null => set vide
00:00 +109: test/environment_core_models_test.dart: EnvironmentPreset categoryId whitespace rejected
00:00 +110: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layerId vide
00:00 +111: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag non-string => FormatException
00:00 +112: test/environment_core_models_test.dart: EnvironmentPreset value equality
00:00 +113: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layer inconnu
00:00 +114: test/environment_core_models_test.dart: public export map_core types reachable from package:map_core/map_core.dart
00:00 +115: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException
00:00 +116: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layer non EnvironmentLayer
00:00 +117: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode weight double => FormatException
00:00 +118: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent ne modifie pas placedElements
00:00 +119: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode sortOrder double => FormatException
00:00 +120: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +121: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +122: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +123: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +124: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +125: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +126: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decodeEnvironmentPresets duplicate preset ids => FormatException
00:00 +127: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer targetTileLayerId valide si TileLayer existe
00:00 +128: test/environment_preset_json_codec_test.dart: decodeEnvironmentGenerationParamsJson accepte int pour densités
00:00 +129: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si targetTileLayerId inconnu
00:00 +130: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si targetTileLayerId pointe vers le layer environment lui-même
00:00 +131: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer
00:00 +132: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si masque ne correspond pas à la taille carte
00:00 +133: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment JSON edge cases fromJson avec content null => emptyContent
00:00 +134: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment JSON edge cases properties roundtrip
00:00 +135: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées
00:00 +136: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer rétrécit la carte : cellules hors carte supprimées
00:00 +137: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson sans environmentPresets => []
00:00 +138: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets null => []
00:00 +139: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets complet => liste
00:00 +140: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics
00:00 +141: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics
00:00 +142: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics
00:00 +143: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics
00:00 +144: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets avec item invalide => FormatException
00:00 +145: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport copie défensive et liste immuable exposée
00:00 +146: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport copie défensive et liste immuable exposée
00:00 +147: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations hasProjectEnvironmentPresets false/true
00:00 +148: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport errorCount / warningCount / diagnosticCount
00:00 +149: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations findProjectEnvironmentPresetById trouve / trim / null
00:00 +150: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport diagnosticsForPreset trim et vide/inconnu => []
00:00 +151: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations replaceProjectEnvironmentPresets remplace et ordre
00:00 +152: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport diagnosticsForKind retourne liste immuable
00:00 +153: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport diagnosticsForKind retourne liste immuable
00:00 +154: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations upsert ajoute ou remplace même position
00:00 +155: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations upsert ajoute ou remplace même position
00:00 +156: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId aucun doublon => rien
00:00 +157: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId aucun doublon => rien
00:00 +158: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId aucun doublon => rien
00:00 +159: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId aucun doublon => rien
00:00 +160: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId deux presets même id => un diagnostic
00:00 +161: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId trois presets même id => un seul diagnostic pour cet id
00:00 +162: test/environment_preset_diagnostics_test.dart: diagnoseProjectEnvironmentPresets duplicatePresetId deux ids dupliqués distincts => deux diagnostics ordre stable
00:00 +163: test/environment_preset_diagnostics_test.dart: missingPaletteElement element présent => pas missing
00:00 +164: test/environment_preset_diagnostics_test.dart: missingPaletteElement element absent => error
00:00 +165: test/environment_preset_diagnostics_test.dart: missingPaletteElement deux presets référencent même absent => un diagnostic par preset
00:00 +166: test/environment_preset_diagnostics_test.dart: unknownTemplateId knownTemplateIds vide => aucun unknownTemplateId
00:00 +167: test/environment_preset_diagnostics_test.dart: unknownTemplateId template connu => rien
00:00 +168: test/environment_preset_diagnostics_test.dart: unknownTemplateId template inconnu => warning
00:00 +169: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile forceEnabled + collisionProfile non-null => rien
00:00 +170: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile forceEnabled + collisionProfile null => warning
00:00 +171: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile useElementDefault + collisionProfile null => rien
00:00 +172: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile forceDisabled + collisionProfile null => rien
00:00 +173: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile element absent + forceEnabled => seulement missingPaletteElement
00:00 +174: test/environment_preset_diagnostics_test.dart: ordre stable des diagnostics duplicate puis missing puis forced puis unknown
00:00 +175: All tests passed!
```

### Suite complète `dart test --reporter expanded`

**`00:02 +1331: All tests passed!`**

## 12. Git status initial et final

**Initial** : non capturé en début de session Lot 7 ; avant les fichiers **`environment_layer_usage_diagnostics*`** n’existaient pas.

**Final** :

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart
?? packages/map_core/test/environment_layer_usage_diagnostics_test.dart
```

## 13. Contenu complet des fichiers créés ou modifiés

### `environment_layer_usage_diagnostics.dart`

```dart
import '../models/environment.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';

/// Gravité d’un diagnostic d’usage Environment sur carte (Lot Environment-7).
enum EnvironmentLayerUsageDiagnosticSeverity {
  error,
  warning,
}

/// Catégorie de diagnostic d’usage (Lot Environment-7).
enum EnvironmentLayerUsageDiagnosticKind {
  missingAreaPreset,
  missingTargetTileLayerId,
  unknownTargetTileLayer,
  targetLayerIsNotTileLayer,
  areaMaskSizeMismatch,
  emptyAreaMask,
  missingGeneratedPlacement,
}

/// Un problème d’usage Environment sur une [MapData].
final class EnvironmentLayerUsageDiagnostic {
  const EnvironmentLayerUsageDiagnostic({
    required this.severity,
    required this.kind,
    required this.mapId,
    required this.layerId,
    this.areaId,
    this.presetId,
    this.targetTileLayerId,
    this.generatedPlacementId,
    required this.message,
  });

  final EnvironmentLayerUsageDiagnosticSeverity severity;
  final EnvironmentLayerUsageDiagnosticKind kind;
  final String mapId;
  final String layerId;
  final String? areaId;
  final String? presetId;
  final String? targetTileLayerId;
  final String? generatedPlacementId;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentLayerUsageDiagnostic &&
            severity == other.severity &&
            kind == other.kind &&
            mapId == other.mapId &&
            layerId == other.layerId &&
            areaId == other.areaId &&
            presetId == other.presetId &&
            targetTileLayerId == other.targetTileLayerId &&
            generatedPlacementId == other.generatedPlacementId &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        mapId,
        layerId,
        areaId,
        presetId,
        targetTileLayerId,
        generatedPlacementId,
        message,
      );
}

/// Rapport agrégé pour une carte.
final class EnvironmentLayerUsageDiagnosticsReport {
  factory EnvironmentLayerUsageDiagnosticsReport({
    required List<EnvironmentLayerUsageDiagnostic> diagnostics,
  }) {
    return EnvironmentLayerUsageDiagnosticsReport._(
      diagnostics: List<EnvironmentLayerUsageDiagnostic>.unmodifiable(
        List<EnvironmentLayerUsageDiagnostic>.from(diagnostics),
      ),
    );
  }

  const EnvironmentLayerUsageDiagnosticsReport._({
    required this.diagnostics,
  });

  final List<EnvironmentLayerUsageDiagnostic> diagnostics;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  bool get hasErrors => diagnostics.any(
        (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.warning,
      );

  int get diagnosticCount => diagnostics.length;

  int get errorCount => diagnostics
      .where((d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.error)
      .length;

  int get warningCount => diagnostics
      .where(
          (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.warning)
      .length;

  List<EnvironmentLayerUsageDiagnostic> diagnosticsForLayer(String layerId) {
    final key = layerId.trim();
    if (key.isEmpty) {
      return const [];
    }
    final out = <EnvironmentLayerUsageDiagnostic>[];
    for (final d in diagnostics) {
      if (d.layerId == key) {
        out.add(d);
      }
    }
    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(out);
  }

  List<EnvironmentLayerUsageDiagnostic> diagnosticsForArea(String areaId) {
    final key = areaId.trim();
    if (key.isEmpty) {
      return const [];
    }
    final out = <EnvironmentLayerUsageDiagnostic>[];
    for (final d in diagnostics) {
      if (d.areaId == key) {
        out.add(d);
      }
    }
    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(out);
  }

  List<EnvironmentLayerUsageDiagnostic> diagnosticsForKind(
    EnvironmentLayerUsageDiagnosticKind kind,
  ) {
    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentLayerUsageDiagnosticsReport &&
            _listEqualsUsage(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hashAll(diagnostics);
}

bool _listEqualsUsage(
  List<EnvironmentLayerUsageDiagnostic> a,
  List<EnvironmentLayerUsageDiagnostic> b,
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

String _mapLayerId(MapLayer layer) {
  return switch (layer) {
    TileLayer(:final id) => id,
    CollisionLayer(:final id) => id,
    TerrainLayer(:final id) => id,
    PathLayer(:final id) => id,
    SurfaceLayer(:final id) => id,
    ObjectLayer(:final id) => id,
    EnvironmentLayer(:final id) => id,
  };
}

/// Diagnostique les layers Environment d’une [MapData] (lecture seule, pas d’exception).
///
/// Ordre : pour chaque [EnvironmentLayer] dans [MapData.layers], d’abord les
/// diagnostics sur `targetTileLayerId` ([missingTargetTileLayerId],
/// [unknownTargetTileLayer], [targetLayerIsNotTileLayer]), puis pour chaque
/// [EnvironmentArea] dans l’ordre : [areaMaskSizeMismatch], [emptyAreaMask],
/// [missingAreaPreset], puis [missingGeneratedPlacement] dans l’ordre des ids.
EnvironmentLayerUsageDiagnosticsReport diagnoseMapEnvironmentLayerUsage(
  ProjectManifest manifest,
  MapData map,
) {
  final diagnostics = <EnvironmentLayerUsageDiagnostic>[];
  final presetIds = <String>{
    for (final p in manifest.environmentPresets) p.id,
  };
  final placedIds = <String>{
    for (final pe in map.placedElements) pe.id,
  };

  MapLayer? targetForId(String? targetId) {
    if (targetId == null) {
      return null;
    }
    for (final l in map.layers) {
      if (_mapLayerId(l) == targetId) {
        return l;
      }
    }
    return null;
  }

  for (final layer in map.layers) {
    if (layer is! EnvironmentLayer) {
      continue;
    }
    final layerId = layer.id;
    final content = layer.content;
    final areas = content.areas;

    if (areas.isNotEmpty && content.targetTileLayerId == null) {
      diagnostics.add(
        EnvironmentLayerUsageDiagnostic(
          severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
          kind: EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
          mapId: map.id,
          layerId: layerId,
          message:
              'Environment layer "$layerId" has areas but no target tile layer.',
        ),
      );
    }

    final targetId = content.targetTileLayerId;
    if (targetId != null) {
      final targetLayer = targetForId(targetId);
      if (targetLayer == null) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
            mapId: map.id,
            layerId: layerId,
            targetTileLayerId: targetId,
            message:
                'Environment layer "$layerId" targets missing tile layer "$targetId".',
          ),
        );
      } else if (targetLayer is! TileLayer) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
            mapId: map.id,
            layerId: layerId,
            targetTileLayerId: targetId,
            message:
                'Environment layer "$layerId" targets layer "$targetId", but it is not a TileLayer.',
          ),
        );
      }
    }

    for (final area in areas) {
      final aid = area.id;
      if (area.mask.width != map.size.width ||
          area.mask.height != map.size.height) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
            mapId: map.id,
            layerId: layerId,
            areaId: aid,
            message:
                'Environment area "$aid" mask size ${area.mask.width}x${area.mask.height} does not match map size ${map.size.width}x${map.size.height}.',
          ),
        );
      }
      if (!area.mask.hasAnyActiveCell) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
            kind: EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
            mapId: map.id,
            layerId: layerId,
            areaId: aid,
            message: 'Environment area "$aid" has an empty mask.',
          ),
        );
      }
      if (!presetIds.contains(area.presetId)) {
        diagnostics.add(
          EnvironmentLayerUsageDiagnostic(
            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
            kind: EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
            mapId: map.id,
            layerId: layerId,
            areaId: aid,
            presetId: area.presetId,
            message:
                'Environment area "$aid" on layer "$layerId" references missing preset "${area.presetId}".',
          ),
        );
      }
      for (final pid in area.generatedPlacementIds) {
        if (!placedIds.contains(pid)) {
          diagnostics.add(
            EnvironmentLayerUsageDiagnostic(
              severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
              kind:
                  EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
              mapId: map.id,
              layerId: layerId,
              areaId: aid,
              generatedPlacementId: pid,
              message:
                  'Environment area "$aid" references generated placement "$pid", but it is not present in map.placedElements.',
            ),
          );
        }
      }
    }
  }

  return EnvironmentLayerUsageDiagnosticsReport(diagnostics: diagnostics);
}

```

### `environment_layer_usage_diagnostics_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

EnvironmentPreset _manifestPreset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'n',
    templateId: 'tpl',
    palette: [EnvironmentPaletteItem(elementId: 'elm', weight: 1)],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectManifest _manifest({List<EnvironmentPreset> presets = const []}) {
  return ProjectManifest(
    name: 'test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: presets,
  );
}

EnvironmentAreaMask _mask(int w, int h, {bool allActive = true}) {
  return EnvironmentAreaMask(
    width: w,
    height: h,
    cells: List<bool>.filled(w * h, allActive),
  );
}

EnvironmentArea _area({
  required String id,
  required String presetId,
  EnvironmentAreaMask? mask,
  List<String>? generatedPlacementIds,
}) {
  return EnvironmentArea(
    id: id,
    name: 'area_$id',
    presetId: presetId,
    mask: mask ?? _mask(4, 3),
    seed: 0,
    generatedPlacementIds: generatedPlacementIds,
  );
}

MapData _map({
  List<MapLayer> layers = const [],
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map_1',
    name: 'Map 1',
    size: const GridSize(width: 4, height: 3),
    tilesetId: 'tileset',
    layers: layers,
    placedElements: placedElements,
  );
}

TileLayer _decorLayer() {
  return MapLayer.tile(
    id: 'decor',
    name: 'Decor',
    tiles: List<int>.filled(4 * 3, 0),
  ) as TileLayer;
}

EnvironmentLayer _envLayer({
  required String id,
  EnvironmentLayerContent? content,
}) {
  return MapLayer.environment(
    id: id,
    name: 'Environment',
    content: content ?? EnvironmentLayerContent.empty(),
  ) as EnvironmentLayer;
}

void main() {
  group('EnvironmentLayerUsageDiagnosticsReport', () {
    test('vide', () {
      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: []);
      expect(r.hasDiagnostics, isFalse);
      expect(r.errorCount, 0);
      expect(r.warningCount, 0);
    });

    test('copie défensive et liste immuable', () {
      final raw = <EnvironmentLayerUsageDiagnostic>[
        EnvironmentLayerUsageDiagnostic(
          severity: EnvironmentLayerUsageDiagnosticSeverity.error,
          kind: EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
          mapId: 'm',
          layerId: 'l',
          targetTileLayerId: 't',
          message: 'msg',
        ),
      ];
      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: raw);
      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
      raw.clear();
      expect(r.diagnosticCount, 1);
    });

    test('counts et diagnosticsForLayer / Area / Kind', () {
      final d1 = EnvironmentLayerUsageDiagnostic(
        severity: EnvironmentLayerUsageDiagnosticSeverity.error,
        kind: EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
        mapId: 'm',
        layerId: 'L',
        areaId: 'A',
        presetId: 'P',
        message: 'm1',
      );
      final d2 = EnvironmentLayerUsageDiagnostic(
        severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
        kind: EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
        mapId: 'm',
        layerId: 'L',
        areaId: 'B',
        message: 'm2',
      );
      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d1, d2]);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
      expect(r.diagnosticsForLayer('  L  ').length, 2);
      expect(r.diagnosticsForLayer(''), isEmpty);
      expect(r.diagnosticsForArea('A').length, 1);
      expect(r.diagnosticsForArea(''), isEmpty);
      final k = r.diagnosticsForKind(
        EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
      );
      expect(k.length, 1);
      expect(() => k.add(d1), throwsUnsupportedError);
    });

    test('égalité', () {
      final d = EnvironmentLayerUsageDiagnostic(
        severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
        kind: EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
        mapId: 'm',
        layerId: 'l',
        message: 'x',
      );
      final r1 = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d]);
      final r2 = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d]);
      expect(r1, equals(r2));
    });
  });

  group('missingAreaPreset', () {
    test('preset présent => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [_area(id: 'a1', presetId: 'pre')],
            ),
          ),
          _decorLayer(),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
        ),
        isEmpty,
      );
    });

    test('preset absent => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              areas: [
                _area(id: 'forest_north', presetId: 'selbrume_dense_forest'),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
          )
          .single;
      expect(d.areaId, 'forest_north');
      expect(d.presetId, 'selbrume_dense_forest');
      expect(
        d.message,
        'Environment area "forest_north" on layer "env_layer" references missing preset "selbrume_dense_forest".',
      );
    });

    test('deux areas même preset absent => deux diagnostics', () {
      final m = _manifest();
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(id: 'a1', presetId: 'gone'),
                _area(id: 'a2', presetId: 'gone'),
              ],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map)
            .diagnosticsForKind(
              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
            )
            .length,
        2,
      );
    });
  });

  group('missingTargetTileLayerId', () {
    test('sans area => pas de warning', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent.empty(),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
        ),
        isEmpty,
      );
    });

    test('avec area sans target => warning', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      final r = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
          )
          .single;
      expect(
        r.message,
        'Environment layer "env_layer" has areas but no target tile layer.',
      );
    });
  });

  group('unknownTargetTileLayer', () {
    test('TileLayer existant => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
          _decorLayer(),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
        ),
        isEmpty,
      );
    });

    test('cible inexistante => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
          )
          .single;
      expect(d.targetTileLayerId, 'decor');
      expect(
        d.message,
        'Environment layer "env_layer" targets missing tile layer "decor".',
      );
    });
  });

  group('targetLayerIsNotTileLayer', () {
    test('ObjectLayer => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'objects',
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
          MapLayer.object(id: 'objects', name: 'O'),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
          )
          .single;
      expect(d.targetTileLayerId, 'objects');
      expect(
        d.message,
        'Environment layer "env_layer" targets layer "objects", but it is not a TileLayer.',
      );
    });

    test('self EnvironmentLayer => error', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final env = _envLayer(
        id: 'env_self',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'env_self',
          areas: [_area(id: 'a', presetId: 'pre')],
        ),
      );
      final map = _map(layers: [env]);
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map)
            .diagnosticsForKind(
              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
            )
            .length,
        1,
      );
    });
  });

  group('areaMaskSizeMismatch', () {
    test('taille ok => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
        ),
        isEmpty,
      );
    });

    test('width différent', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  mask: EnvironmentAreaMask(
                    width: 8,
                    height: 3,
                    cells: List<bool>.filled(8 * 3, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
          )
          .single;
      expect(
        d.message,
        'Environment area "forest_north" mask size 8x3 does not match map size 4x3.',
      );
    });

    test('height différent', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'a',
                  presetId: 'pre',
                  mask: EnvironmentAreaMask(
                    width: 4,
                    height: 2,
                    cells: List<bool>.filled(8, true),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map)
            .diagnosticsForKind(
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
            )
            .length,
        1,
      );
    });
  });

  group('emptyAreaMask', () {
    test('au moins une cellule active => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [_area(id: 'a', presetId: 'pre')],
            ),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
        ),
        isEmpty,
      );
    });

    test('masque tout false => warning', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  mask: _mask(4, 3, allActive: false),
                ),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
          )
          .single;
      expect(
        d.message,
        'Environment area "forest_north" has an empty mask.',
      );
    });
  });

  group('missingGeneratedPlacement', () {
    test('ids présents => rien', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  generatedPlacementIds: ['tree_42'],
                ),
              ],
            ),
          ),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'tree_42',
            layerId: 'decor',
            elementId: 'oak',
            pos: const GridPos(x: 0, y: 0),
          ),
        ],
      );
      expect(
        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
          EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
        ),
        isEmpty,
      );
    });

    test('id absent => warning avec message stable', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'forest_north',
                  presetId: 'pre',
                  generatedPlacementIds: ['tree_42'],
                ),
              ],
            ),
          ),
        ],
      );
      final d = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
          )
          .single;
      expect(d.generatedPlacementId, 'tree_42');
      expect(
        d.message,
        'Environment area "forest_north" references generated placement "tree_42", but it is not present in map.placedElements.',
      );
    });

    test('plusieurs ids absents => ordre des generatedPlacementIds', () {
      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
      final map = _map(
        layers: [
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              areas: [
                _area(
                  id: 'a',
                  presetId: 'pre',
                  generatedPlacementIds: ['second', 'first'],
                ),
              ],
            ),
          ),
        ],
      );
      final ids = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnosticsForKind(
            EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
          )
          .map((e) => e.generatedPlacementId)
          .toList();
      expect(ids, ['second', 'first']);
    });
  });

  group('ordre stable', () {
    test('targets puis areaMismatch, empty, preset, placements', () {
      final m = _manifest(
        presets: [
          _manifestPreset(id: 'good_pre'),
        ],
      );

      final areaBadMask = EnvironmentAreaMask(
        width: 8,
        height: 8,
        cells: List<bool>.filled(64, false),
      );
      final areaEmptyOkSize = _mask(4, 3, allActive: false);

      final map = _map(
        layers: [
          MapLayer.object(id: 'objects', name: 'O'),
          _envLayer(
            id: 'env_layer',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'objects',
              areas: [
                _area(
                  id: 'r1',
                  presetId: 'good_pre',
                  mask: areaBadMask,
                ),
                EnvironmentArea(
                  id: 'r2',
                  name: 'R2',
                  presetId: 'missing_pre',
                  mask: areaEmptyOkSize,
                  seed: 0,
                ),
                _area(
                  id: 'r3',
                  presetId: 'good_pre',
                  generatedPlacementIds: ['z', 'y'],
                ),
              ],
            ),
          ),
        ],
      );

      final kinds = diagnoseMapEnvironmentLayerUsage(m, map)
          .diagnostics
          .map((e) => e.kind)
          .toList();

      expect(
        kinds.indexOf(
            EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer),
        lessThan(
          kinds.indexOf(
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch),
        ),
      );

      final idxMismatch = kinds.indexOf(
        EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
      );
      final idxEmpty =
          kinds.indexOf(EnvironmentLayerUsageDiagnosticKind.emptyAreaMask);
      final idxPreset = kinds.indexOf(
        EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
      );

      expect(idxMismatch, lessThan(idxEmpty));
      expect(idxEmpty, lessThan(idxPreset));

      expect(
        kinds.lastIndexWhere(
          (k) =>
              k ==
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
        ),
        greaterThan(idxPreset),
      );

      final report = diagnoseMapEnvironmentLayerUsage(m, map);
      final placementKinds = [
        for (final d in report.diagnostics)
          if (d.kind ==
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement)
            d.generatedPlacementId,
      ];
      expect(placementKinds, ['z', 'y']);
    });
  });
}

```

### Extrait `map_core.dart` — exports Environment

```dart
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
```

## 14. Diff complet

### `git diff packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 239002e5..73907663 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -77,6 +77,7 @@ export 'src/operations/environment_layer_content_json_codec.dart';
 export 'src/operations/environment_preset_json_codec.dart';
 export 'src/operations/project_manifest_environment_preset_operations.dart';
 export 'src/operations/environment_preset_diagnostics.dart';
+export 'src/operations/environment_layer_usage_diagnostics.dart';
 export 'src/operations/surface_layer_placements.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
```

### `git diff --no-index /dev/null` → usage diagnostics

```diff
diff --git a/packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart b/packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart
new file mode 100644
index 00000000..6a30ec9b
--- /dev/null
+++ b/packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart
@@ -0,0 +1,337 @@
+import '../models/environment.dart';
+import '../models/map_data.dart';
+import '../models/map_layer.dart';
+import '../models/project_manifest.dart';
+
+/// Gravité d’un diagnostic d’usage Environment sur carte (Lot Environment-7).
+enum EnvironmentLayerUsageDiagnosticSeverity {
+  error,
+  warning,
+}
+
+/// Catégorie de diagnostic d’usage (Lot Environment-7).
+enum EnvironmentLayerUsageDiagnosticKind {
+  missingAreaPreset,
+  missingTargetTileLayerId,
+  unknownTargetTileLayer,
+  targetLayerIsNotTileLayer,
+  areaMaskSizeMismatch,
+  emptyAreaMask,
+  missingGeneratedPlacement,
+}
+
+/// Un problème d’usage Environment sur une [MapData].
+final class EnvironmentLayerUsageDiagnostic {
+  const EnvironmentLayerUsageDiagnostic({
+    required this.severity,
+    required this.kind,
+    required this.mapId,
+    required this.layerId,
+    this.areaId,
+    this.presetId,
+    this.targetTileLayerId,
+    this.generatedPlacementId,
+    required this.message,
+  });
+
+  final EnvironmentLayerUsageDiagnosticSeverity severity;
+  final EnvironmentLayerUsageDiagnosticKind kind;
+  final String mapId;
+  final String layerId;
+  final String? areaId;
+  final String? presetId;
+  final String? targetTileLayerId;
+  final String? generatedPlacementId;
+  final String message;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentLayerUsageDiagnostic &&
+            severity == other.severity &&
+            kind == other.kind &&
+            mapId == other.mapId &&
+            layerId == other.layerId &&
+            areaId == other.areaId &&
+            presetId == other.presetId &&
+            targetTileLayerId == other.targetTileLayerId &&
+            generatedPlacementId == other.generatedPlacementId &&
+            message == other.message;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        severity,
+        kind,
+        mapId,
+        layerId,
+        areaId,
+        presetId,
+        targetTileLayerId,
+        generatedPlacementId,
+        message,
+      );
+}
+
+/// Rapport agrégé pour une carte.
+final class EnvironmentLayerUsageDiagnosticsReport {
+  factory EnvironmentLayerUsageDiagnosticsReport({
+    required List<EnvironmentLayerUsageDiagnostic> diagnostics,
+  }) {
+    return EnvironmentLayerUsageDiagnosticsReport._(
+      diagnostics: List<EnvironmentLayerUsageDiagnostic>.unmodifiable(
+        List<EnvironmentLayerUsageDiagnostic>.from(diagnostics),
+      ),
+    );
+  }
+
+  const EnvironmentLayerUsageDiagnosticsReport._({
+    required this.diagnostics,
+  });
+
+  final List<EnvironmentLayerUsageDiagnostic> diagnostics;
+
+  bool get hasDiagnostics => diagnostics.isNotEmpty;
+
+  bool get hasErrors => diagnostics.any(
+        (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.error,
+      );
+
+  bool get hasWarnings => diagnostics.any(
+        (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.warning,
+      );
+
+  int get diagnosticCount => diagnostics.length;
+
+  int get errorCount => diagnostics
+      .where((d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.error)
+      .length;
+
+  int get warningCount => diagnostics
+      .where(
+          (d) => d.severity == EnvironmentLayerUsageDiagnosticSeverity.warning)
+      .length;
+
+  List<EnvironmentLayerUsageDiagnostic> diagnosticsForLayer(String layerId) {
+    final key = layerId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    final out = <EnvironmentLayerUsageDiagnostic>[];
+    for (final d in diagnostics) {
+      if (d.layerId == key) {
+        out.add(d);
+      }
+    }
+    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(out);
+  }
+
+  List<EnvironmentLayerUsageDiagnostic> diagnosticsForArea(String areaId) {
+    final key = areaId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    final out = <EnvironmentLayerUsageDiagnostic>[];
+    for (final d in diagnostics) {
+      if (d.areaId == key) {
+        out.add(d);
+      }
+    }
+    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(out);
+  }
+
+  List<EnvironmentLayerUsageDiagnostic> diagnosticsForKind(
+    EnvironmentLayerUsageDiagnosticKind kind,
+  ) {
+    return List<EnvironmentLayerUsageDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.kind == kind).toList(growable: false),
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentLayerUsageDiagnosticsReport &&
+            _listEqualsUsage(other.diagnostics, diagnostics);
+  }
+
+  @override
+  int get hashCode => Object.hashAll(diagnostics);
+}
+
+bool _listEqualsUsage(
+  List<EnvironmentLayerUsageDiagnostic> a,
+  List<EnvironmentLayerUsageDiagnostic> b,
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
+String _mapLayerId(MapLayer layer) {
+  return switch (layer) {
+    TileLayer(:final id) => id,
+    CollisionLayer(:final id) => id,
+    TerrainLayer(:final id) => id,
+    PathLayer(:final id) => id,
+    SurfaceLayer(:final id) => id,
+    ObjectLayer(:final id) => id,
+    EnvironmentLayer(:final id) => id,
+  };
+}
+
+/// Diagnostique les layers Environment d’une [MapData] (lecture seule, pas d’exception).
+///
+/// Ordre : pour chaque [EnvironmentLayer] dans [MapData.layers], d’abord les
+/// diagnostics sur `targetTileLayerId` ([missingTargetTileLayerId],
+/// [unknownTargetTileLayer], [targetLayerIsNotTileLayer]), puis pour chaque
+/// [EnvironmentArea] dans l’ordre : [areaMaskSizeMismatch], [emptyAreaMask],
+/// [missingAreaPreset], puis [missingGeneratedPlacement] dans l’ordre des ids.
+EnvironmentLayerUsageDiagnosticsReport diagnoseMapEnvironmentLayerUsage(
+  ProjectManifest manifest,
+  MapData map,
+) {
+  final diagnostics = <EnvironmentLayerUsageDiagnostic>[];
+  final presetIds = <String>{
+    for (final p in manifest.environmentPresets) p.id,
+  };
+  final placedIds = <String>{
+    for (final pe in map.placedElements) pe.id,
+  };
+
+  MapLayer? targetForId(String? targetId) {
+    if (targetId == null) {
+      return null;
+    }
+    for (final l in map.layers) {
+      if (_mapLayerId(l) == targetId) {
+        return l;
+      }
+    }
+    return null;
+  }
+
+  for (final layer in map.layers) {
+    if (layer is! EnvironmentLayer) {
+      continue;
+    }
+    final layerId = layer.id;
+    final content = layer.content;
+    final areas = content.areas;
+
+    if (areas.isNotEmpty && content.targetTileLayerId == null) {
+      diagnostics.add(
+        EnvironmentLayerUsageDiagnostic(
+          severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
+          kind: EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
+          mapId: map.id,
+          layerId: layerId,
+          message:
+              'Environment layer "$layerId" has areas but no target tile layer.',
+        ),
+      );
+    }
+
+    final targetId = content.targetTileLayerId;
+    if (targetId != null) {
+      final targetLayer = targetForId(targetId);
+      if (targetLayer == null) {
+        diagnostics.add(
+          EnvironmentLayerUsageDiagnostic(
+            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
+            kind: EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
+            mapId: map.id,
+            layerId: layerId,
+            targetTileLayerId: targetId,
+            message:
+                'Environment layer "$layerId" targets missing tile layer "$targetId".',
+          ),
+        );
+      } else if (targetLayer is! TileLayer) {
+        diagnostics.add(
+          EnvironmentLayerUsageDiagnostic(
+            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
+            kind: EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
+            mapId: map.id,
+            layerId: layerId,
+            targetTileLayerId: targetId,
+            message:
+                'Environment layer "$layerId" targets layer "$targetId", but it is not a TileLayer.',
+          ),
+        );
+      }
+    }
+
+    for (final area in areas) {
+      final aid = area.id;
+      if (area.mask.width != map.size.width ||
+          area.mask.height != map.size.height) {
+        diagnostics.add(
+          EnvironmentLayerUsageDiagnostic(
+            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
+            kind: EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
+            mapId: map.id,
+            layerId: layerId,
+            areaId: aid,
+            message:
+                'Environment area "$aid" mask size ${area.mask.width}x${area.mask.height} does not match map size ${map.size.width}x${map.size.height}.',
+          ),
+        );
+      }
+      if (!area.mask.hasAnyActiveCell) {
+        diagnostics.add(
+          EnvironmentLayerUsageDiagnostic(
+            severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
+            kind: EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
+            mapId: map.id,
+            layerId: layerId,
+            areaId: aid,
+            message: 'Environment area "$aid" has an empty mask.',
+          ),
+        );
+      }
+      if (!presetIds.contains(area.presetId)) {
+        diagnostics.add(
+          EnvironmentLayerUsageDiagnostic(
+            severity: EnvironmentLayerUsageDiagnosticSeverity.error,
+            kind: EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+            mapId: map.id,
+            layerId: layerId,
+            areaId: aid,
+            presetId: area.presetId,
+            message:
+                'Environment area "$aid" on layer "$layerId" references missing preset "${area.presetId}".',
+          ),
+        );
+      }
+      for (final pid in area.generatedPlacementIds) {
+        if (!placedIds.contains(pid)) {
+          diagnostics.add(
+            EnvironmentLayerUsageDiagnostic(
+              severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
+              kind:
+                  EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
+              mapId: map.id,
+              layerId: layerId,
+              areaId: aid,
+              generatedPlacementId: pid,
+              message:
+                  'Environment area "$aid" references generated placement "$pid", but it is not present in map.placedElements.',
+            ),
+          );
+        }
+      }
+    }
+  }
+
+  return EnvironmentLayerUsageDiagnosticsReport(diagnostics: diagnostics);
+}
```

### `git diff --no-index /dev/null` → tests

```diff
diff --git a/packages/map_core/test/environment_layer_usage_diagnostics_test.dart b/packages/map_core/test/environment_layer_usage_diagnostics_test.dart
new file mode 100644
index 00000000..4e9732a0
--- /dev/null
+++ b/packages/map_core/test/environment_layer_usage_diagnostics_test.dart
@@ -0,0 +1,692 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+EnvironmentPreset _manifestPreset({required String id}) {
+  return EnvironmentPreset(
+    id: id,
+    name: 'n',
+    templateId: 'tpl',
+    palette: [EnvironmentPaletteItem(elementId: 'elm', weight: 1)],
+    defaultParams: EnvironmentGenerationParams.standard(),
+    sortOrder: 0,
+  );
+}
+
+ProjectManifest _manifest({List<EnvironmentPreset> presets = const []}) {
+  return ProjectManifest(
+    name: 'test',
+    maps: const [],
+    tilesets: const [],
+    surfaceCatalog: ProjectSurfaceCatalog(),
+    environmentPresets: presets,
+  );
+}
+
+EnvironmentAreaMask _mask(int w, int h, {bool allActive = true}) {
+  return EnvironmentAreaMask(
+    width: w,
+    height: h,
+    cells: List<bool>.filled(w * h, allActive),
+  );
+}
+
+EnvironmentArea _area({
+  required String id,
+  required String presetId,
+  EnvironmentAreaMask? mask,
+  List<String>? generatedPlacementIds,
+}) {
+  return EnvironmentArea(
+    id: id,
+    name: 'area_$id',
+    presetId: presetId,
+    mask: mask ?? _mask(4, 3),
+    seed: 0,
+    generatedPlacementIds: generatedPlacementIds,
+  );
+}
+
+MapData _map({
+  List<MapLayer> layers = const [],
+  List<MapPlacedElement> placedElements = const [],
+}) {
+  return MapData(
+    id: 'map_1',
+    name: 'Map 1',
+    size: const GridSize(width: 4, height: 3),
+    tilesetId: 'tileset',
+    layers: layers,
+    placedElements: placedElements,
+  );
+}
+
+TileLayer _decorLayer() {
+  return MapLayer.tile(
+    id: 'decor',
+    name: 'Decor',
+    tiles: List<int>.filled(4 * 3, 0),
+  ) as TileLayer;
+}
+
+EnvironmentLayer _envLayer({
+  required String id,
+  EnvironmentLayerContent? content,
+}) {
+  return MapLayer.environment(
+    id: id,
+    name: 'Environment',
+    content: content ?? EnvironmentLayerContent.empty(),
+  ) as EnvironmentLayer;
+}
+
+void main() {
+  group('EnvironmentLayerUsageDiagnosticsReport', () {
+    test('vide', () {
+      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: []);
+      expect(r.hasDiagnostics, isFalse);
+      expect(r.errorCount, 0);
+      expect(r.warningCount, 0);
+    });
+
+    test('copie défensive et liste immuable', () {
+      final raw = <EnvironmentLayerUsageDiagnostic>[
+        EnvironmentLayerUsageDiagnostic(
+          severity: EnvironmentLayerUsageDiagnosticSeverity.error,
+          kind: EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
+          mapId: 'm',
+          layerId: 'l',
+          targetTileLayerId: 't',
+          message: 'msg',
+        ),
+      ];
+      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: raw);
+      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
+      raw.clear();
+      expect(r.diagnosticCount, 1);
+    });
+
+    test('counts et diagnosticsForLayer / Area / Kind', () {
+      final d1 = EnvironmentLayerUsageDiagnostic(
+        severity: EnvironmentLayerUsageDiagnosticSeverity.error,
+        kind: EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+        mapId: 'm',
+        layerId: 'L',
+        areaId: 'A',
+        presetId: 'P',
+        message: 'm1',
+      );
+      final d2 = EnvironmentLayerUsageDiagnostic(
+        severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
+        kind: EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
+        mapId: 'm',
+        layerId: 'L',
+        areaId: 'B',
+        message: 'm2',
+      );
+      final r = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d1, d2]);
+      expect(r.errorCount, 1);
+      expect(r.warningCount, 1);
+      expect(r.diagnosticsForLayer('  L  ').length, 2);
+      expect(r.diagnosticsForLayer(''), isEmpty);
+      expect(r.diagnosticsForArea('A').length, 1);
+      expect(r.diagnosticsForArea(''), isEmpty);
+      final k = r.diagnosticsForKind(
+        EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+      );
+      expect(k.length, 1);
+      expect(() => k.add(d1), throwsUnsupportedError);
+    });
+
+    test('égalité', () {
+      final d = EnvironmentLayerUsageDiagnostic(
+        severity: EnvironmentLayerUsageDiagnosticSeverity.warning,
+        kind: EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
+        mapId: 'm',
+        layerId: 'l',
+        message: 'x',
+      );
+      final r1 = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d]);
+      final r2 = EnvironmentLayerUsageDiagnosticsReport(diagnostics: [d]);
+      expect(r1, equals(r2));
+    });
+  });
+
+  group('missingAreaPreset', () {
+    test('preset présent => rien', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [_area(id: 'a1', presetId: 'pre')],
+            ),
+          ),
+          _decorLayer(),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
+          EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('preset absent => error', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env_layer',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(id: 'forest_north', presetId: 'selbrume_dense_forest'),
+              ],
+            ),
+          ),
+        ],
+      );
+      final d = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+          )
+          .single;
+      expect(d.areaId, 'forest_north');
+      expect(d.presetId, 'selbrume_dense_forest');
+      expect(
+        d.message,
+        'Environment area "forest_north" on layer "env_layer" references missing preset "selbrume_dense_forest".',
+      );
+    });
+
+    test('deux areas même preset absent => deux diagnostics', () {
+      final m = _manifest();
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(id: 'a1', presetId: 'gone'),
+                _area(id: 'a2', presetId: 'gone'),
+              ],
+            ),
+          ),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map)
+            .diagnosticsForKind(
+              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+            )
+            .length,
+        2,
+      );
+    });
+  });
+
+  group('missingTargetTileLayerId', () {
+    test('sans area => pas de warning', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent.empty(),
+          ),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
+          EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('avec area sans target => warning', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env_layer',
+            content: EnvironmentLayerContent(
+              areas: [_area(id: 'a', presetId: 'pre')],
+            ),
+          ),
+        ],
+      );
+      final r = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId,
+          )
+          .single;
+      expect(
+        r.message,
+        'Environment layer "env_layer" has areas but no target tile layer.',
+      );
+    });
+  });
+
+  group('unknownTargetTileLayer', () {
+    test('TileLayer existant => rien', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [_area(id: 'a', presetId: 'pre')],
+            ),
+          ),
+          _decorLayer(),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
+          EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('cible inexistante => error', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env_layer',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [_area(id: 'a', presetId: 'pre')],
+            ),
+          ),
+        ],
+      );
+      final d = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer,
+          )
+          .single;
+      expect(d.targetTileLayerId, 'decor');
+      expect(
+        d.message,
+        'Environment layer "env_layer" targets missing tile layer "decor".',
+      );
+    });
+  });
+
+  group('targetLayerIsNotTileLayer', () {
+    test('ObjectLayer => error', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env_layer',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'objects',
+              areas: [_area(id: 'a', presetId: 'pre')],
+            ),
+          ),
+          MapLayer.object(id: 'objects', name: 'O'),
+        ],
+      );
+      final d = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
+          )
+          .single;
+      expect(d.targetTileLayerId, 'objects');
+      expect(
+        d.message,
+        'Environment layer "env_layer" targets layer "objects", but it is not a TileLayer.',
+      );
+    });
+
+    test('self EnvironmentLayer => error', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final env = _envLayer(
+        id: 'env_self',
+        content: EnvironmentLayerContent(
+          targetTileLayerId: 'env_self',
+          areas: [_area(id: 'a', presetId: 'pre')],
+        ),
+      );
+      final map = _map(layers: [env]);
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map)
+            .diagnosticsForKind(
+              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer,
+            )
+            .length,
+        1,
+      );
+    });
+  });
+
+  group('areaMaskSizeMismatch', () {
+    test('taille ok => rien', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [_area(id: 'a', presetId: 'pre')],
+            ),
+          ),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
+          EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('width différent', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(
+                  id: 'forest_north',
+                  presetId: 'pre',
+                  mask: EnvironmentAreaMask(
+                    width: 8,
+                    height: 3,
+                    cells: List<bool>.filled(8 * 3, true),
+                  ),
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+      final d = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
+          )
+          .single;
+      expect(
+        d.message,
+        'Environment area "forest_north" mask size 8x3 does not match map size 4x3.',
+      );
+    });
+
+    test('height différent', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(
+                  id: 'a',
+                  presetId: 'pre',
+                  mask: EnvironmentAreaMask(
+                    width: 4,
+                    height: 2,
+                    cells: List<bool>.filled(8, true),
+                  ),
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map)
+            .diagnosticsForKind(
+              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
+            )
+            .length,
+        1,
+      );
+    });
+  });
+
+  group('emptyAreaMask', () {
+    test('au moins une cellule active => rien', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [_area(id: 'a', presetId: 'pre')],
+            ),
+          ),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
+          EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('masque tout false => warning', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(
+                  id: 'forest_north',
+                  presetId: 'pre',
+                  mask: _mask(4, 3, allActive: false),
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+      final d = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.emptyAreaMask,
+          )
+          .single;
+      expect(
+        d.message,
+        'Environment area "forest_north" has an empty mask.',
+      );
+    });
+  });
+
+  group('missingGeneratedPlacement', () {
+    test('ids présents => rien', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(
+                  id: 'forest_north',
+                  presetId: 'pre',
+                  generatedPlacementIds: ['tree_42'],
+                ),
+              ],
+            ),
+          ),
+        ],
+        placedElements: [
+          MapPlacedElement(
+            id: 'tree_42',
+            layerId: 'decor',
+            elementId: 'oak',
+            pos: const GridPos(x: 0, y: 0),
+          ),
+        ],
+      );
+      expect(
+        diagnoseMapEnvironmentLayerUsage(m, map).diagnosticsForKind(
+          EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
+        ),
+        isEmpty,
+      );
+    });
+
+    test('id absent => warning avec message stable', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env_layer',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(
+                  id: 'forest_north',
+                  presetId: 'pre',
+                  generatedPlacementIds: ['tree_42'],
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+      final d = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
+          )
+          .single;
+      expect(d.generatedPlacementId, 'tree_42');
+      expect(
+        d.message,
+        'Environment area "forest_north" references generated placement "tree_42", but it is not present in map.placedElements.',
+      );
+    });
+
+    test('plusieurs ids absents => ordre des generatedPlacementIds', () {
+      final m = _manifest(presets: [_manifestPreset(id: 'pre')]);
+      final map = _map(
+        layers: [
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              areas: [
+                _area(
+                  id: 'a',
+                  presetId: 'pre',
+                  generatedPlacementIds: ['second', 'first'],
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+      final ids = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnosticsForKind(
+            EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
+          )
+          .map((e) => e.generatedPlacementId)
+          .toList();
+      expect(ids, ['second', 'first']);
+    });
+  });
+
+  group('ordre stable', () {
+    test('targets puis areaMismatch, empty, preset, placements', () {
+      final m = _manifest(
+        presets: [
+          _manifestPreset(id: 'good_pre'),
+        ],
+      );
+
+      final areaBadMask = EnvironmentAreaMask(
+        width: 8,
+        height: 8,
+        cells: List<bool>.filled(64, false),
+      );
+      final areaEmptyOkSize = _mask(4, 3, allActive: false);
+
+      final map = _map(
+        layers: [
+          MapLayer.object(id: 'objects', name: 'O'),
+          _envLayer(
+            id: 'env_layer',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'objects',
+              areas: [
+                _area(
+                  id: 'r1',
+                  presetId: 'good_pre',
+                  mask: areaBadMask,
+                ),
+                EnvironmentArea(
+                  id: 'r2',
+                  name: 'R2',
+                  presetId: 'missing_pre',
+                  mask: areaEmptyOkSize,
+                  seed: 0,
+                ),
+                _area(
+                  id: 'r3',
+                  presetId: 'good_pre',
+                  generatedPlacementIds: ['z', 'y'],
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+
+      final kinds = diagnoseMapEnvironmentLayerUsage(m, map)
+          .diagnostics
+          .map((e) => e.kind)
+          .toList();
+
+      expect(
+        kinds.indexOf(
+            EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer),
+        lessThan(
+          kinds.indexOf(
+              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch),
+        ),
+      );
+
+      final idxMismatch = kinds.indexOf(
+        EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch,
+      );
+      final idxEmpty =
+          kinds.indexOf(EnvironmentLayerUsageDiagnosticKind.emptyAreaMask);
+      final idxPreset = kinds.indexOf(
+        EnvironmentLayerUsageDiagnosticKind.missingAreaPreset,
+      );
+
+      expect(idxMismatch, lessThan(idxEmpty));
+      expect(idxEmpty, lessThan(idxPreset));
+
+      expect(
+        kinds.lastIndexWhere(
+          (k) =>
+              k ==
+              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement,
+        ),
+        greaterThan(idxPreset),
+      );
+
+      final report = diagnoseMapEnvironmentLayerUsage(m, map);
+      final placementKinds = [
+        for (final d in report.diagnostics)
+          if (d.kind ==
+              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement)
+            d.generatedPlacementId,
+      ];
+      expect(placementKinds, ['z', 'y']);
+    });
+  });
+}
```

## 15. Auto-review

- **Solide** — respect du prompt (7 kinds), pas de duplication Lot 6, messages stables alignés exemples.

- **Discutable** — si plusieurs **`MapLayer`** partagent le même **`id`**, la résolution prend le **premier** dans **`map.layers`** : signalé comme limite plausible ; hors périmètre corriger **`MapData`**.

- **Après auto-review** — test d’ordre affiné (indices), suppression variable inutilisée.

- **Risques** — pas de vérif **`generatedBy` / conventions** placements (explicitement hors lot).

- **Regard critique (prompt §14)** :
  - `missingTargetTileLayerId` en **warning** : aligné specs (draft possible).
  - `emptyAreaMask` **warning** : aligné specs.
  - Presets projet **non utilisés** par les maps : non diagnostiqué (prévoir agrégateur / Lot 8).
  - **`generatedBy`** : non (prompt).
  - Périmètre fichiers : respecté.

## 16. Verdict

Statut du lot :

- [x] Validé

- [ ] Validé avec réserve

- [ ] Non livré

Résumé :

```text
Usage Environment carte : 7 diagnostics + rapport + tests +1331 verts ; aucun manifest/layer/UI/build_runner touché.
```

Prochain lot recommandé :

```text
Environment-8 — Environment Diagnostics Aggregator / Presentation V0
```

---

### Evidence Pack

- §12 : **`git status`** final.
- §13 : sources intégrales op + test ; extrait **`map_core`**.
- §11 : analyzes + tests ciblés + régressions + ligne **`+1331`**.
- §14 : diffs **`git`**.
- **`Project.manifest` / modèles** : fichier **`project_manifest.dart`** non édité.
- **`MapLayer` / codecs / MapValidator`** : inchangés.
- **UI / générateur** : absents.
- **`build_runner` / generated** : non.
- **`git commit` / `git add` / `git push`** : non effectués.
