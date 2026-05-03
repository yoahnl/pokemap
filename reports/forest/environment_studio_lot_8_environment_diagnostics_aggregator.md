# Environment Studio Lot 8 — Environment Diagnostics Aggregator / Presentation V0

## 1. Résumé exécutif

Le Lot 8 introduit une couche **pure `map_core`** qui agrège les diagnostics Environment des lots 6 (`diagnoseProjectEnvironmentPresets`) et 7 (`diagnoseMapEnvironmentLayerUsage`) en un seul modèle présentable : `EnvironmentAuthoringDiagnostic`, `EnvironmentAuthoringDiagnosticsSummary`, `EnvironmentAuthoringDiagnosticsReport`, et la fonction `diagnoseProjectEnvironmentAuthoring`. Aucune mutation du manifest ni des cartes, aucune lecture disque, aucune modification des opérations existantes des lots 6–7.

## 2. Périmètre du lot

Fichiers **uniquement** touchés (conformément au contrat) :

- `packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart` (créé)
- `packages/map_core/test/environment_authoring_diagnostics_test.dart` (créé)
- `packages/map_core/lib/map_core.dart` (export)
- `reports/forest/environment_studio_lot_8_environment_diagnostics_aggregator.md` (ce rapport)

Hors périmètre : UI Environment Studio, générateur, `ProjectManifest`, `MapLayer`, `MapData`, codecs, `MapValidator`, `build_runner`, fichiers générés, autres packages.

## 3. Décisions d'agrégation

- **Source explicite** : chaque ligne porte `EnvironmentAuthoringDiagnosticSource` (`presetManifest` vs `layerUsage`) pour que l'UI filtre sans heuristique.
- **Kinds unifiés** : union stricte des enums des lots 6 et 7, mappage exhaustif par `switch` (évolution type-safe).
- **Cartes** : le caller passe `List<MapData>` déjà chargées — pas d'usage de `ProjectManifest.maps` ni de filesystem (aligné contrat Lot 8).
- **Ordre** : tous les diagnostics preset (ordre Lot 6), puis pour chaque carte dans l'ordre du paramètre `maps`, les diagnostics d'usage (ordre Lot 7 inchangé).
- **Summary** : compteurs dérivés de la liste finale ; `mapsWithDiagnosticsCount` = nombre de `mapId` **non null distincts** ; `presetsWithDiagnosticsCount` = nombre de `presetId` **non null distincts** (manifest + usages, ex. `missingAreaPreset`).

## 4. Types ajoutés

- `EnvironmentAuthoringDiagnosticSeverity` : `error`, `warning`.
- `EnvironmentAuthoringDiagnosticSource` : `presetManifest`, `layerUsage`.
- `EnvironmentAuthoringDiagnosticKind` : 11 variantes (union lots 6+7).
- `EnvironmentAuthoringDiagnostic` : value object avec champs optionnels recopiés, `==` / `hashCode`.
- `EnvironmentAuthoringDiagnosticsSummary` : compteurs + booléens `has*`, `==` / `hashCode`.
- `EnvironmentAuthoringDiagnosticsReport` : liste immuable, `summary`, filtres `diagnosticsForSource|Kind|Map|Layer|Area|Preset`, `==` / `hashCode`.

## 5. Fonction principale

`diagnoseProjectEnvironmentAuthoring(ProjectManifest manifest, { required List<MapData> maps, Set<String> knownTemplateIds = const <String>{}, })` :

1. `diagnoseProjectEnvironmentPresets(manifest, knownTemplateIds: knownTemplateIds)`
2. pour chaque `map` dans `maps` : `diagnoseMapEnvironmentLayerUsage(manifest, map)`
3. conversion en `EnvironmentAuthoringDiagnostic` et construction du rapport.

## 6. Mapping des diagnostics

- **Sévérités** : identiques par nom entre sources et cible.
- **Kinds preset** : `duplicatePresetId`, `missingPaletteElement`, `unknownTemplateId`, `forcedCollisionWithoutProfile` → mêmes noms côté authoring.
- **Kinds usage** : les 7 kinds Lot 7 → mêmes noms côté authoring.
- **Champs** : recopie des ids / messages tels quels depuis les diagnostics source.

## 7. Summary et helpers de présentation

- `summary.totalCount` = `diagnostics.length` ; erreurs / warnings par sévérité.
- `presetManifestCount` / `layerUsageCount` par `source`.
- Helpers : trim sur `String`, liste vide si clé vide ou sans correspondance, résultats `List.unmodifiable`.

## 8. Ordre stable des diagnostics

Documenté dans le dartdoc de `diagnoseProjectEnvironmentAuthoring` et vérifié par le test `ordre stable` (comparaison à la concaténation des kinds des rapports Lot 6 et Lot 7).

## 9. Pourquoi aucun ProjectManifest / MapLayer / UI / générateur dans ce lot

Seule une **nouvelle opération** et des **types de présentation** sont ajoutés ; les modèles et layers restent inchangés ; aucun widget ni générateur.

## 10. Fichiers modifiés

Voir sections 14 (git), 15 (contenus complets) et 16 (diffs).

## 11. Tests ajoutés

Fichier `packages/map_core/test/environment_authoring_diagnostics_test.dart` : **20** tests (rapport, summary, mapping preset/usage, ordre stable, fonction principale, `knownTemplateIds`), import public `package:map_core/map_core.dart`.

## 12. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart format lib/src/operations/environment_authoring_diagnostics.dart lib/map_core.dart test/environment_authoring_diagnostics_test.dart
dart analyze lib/src/operations/environment_authoring_diagnostics.dart lib/map_core.dart test/environment_authoring_diagnostics_test.dart
dart analyze
dart test test/environment_authoring_diagnostics_test.dart --reporter expanded
dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart test/environment_layer_content_json_codec_test.dart test/environment_layer_map_layer_integration_test.dart test/environment_preset_json_codec_test.dart test/project_manifest_environment_presets_test.dart test/environment_preset_diagnostics_test.dart test/environment_layer_usage_diagnostics_test.dart --reporter expanded
dart test
```

## 13. Résultats des commandes

### dart analyze (ciblé)

```
Analyzing environment_authoring_diagnostics.dart, map_core.dart, environment_authoring_diagnostics_test.dart...
No issues found!
```

### dart analyze (package map_core complet)

```
Analyzing map_core...
No issues found!
```

### dart test (ciblé Lot 8)

Sortie complète :

```
00:00 [32m+0[0m: [1m[90mloading test/environment_authoring_diagnostics_test.dart[0m[0m
00:00 [32m+0[0m: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m
00:00 [32m+1[0m: EnvironmentAuthoringDiagnosticsReport copie défensive et liste immuable[0m
00:00 [32m+2[0m: EnvironmentAuthoringDiagnosticsReport diagnosticCount / errorCount / warningCount[0m
00:00 [32m+3[0m: EnvironmentAuthoringDiagnosticsReport diagnosticsForSource[0m
00:00 [32m+4[0m: EnvironmentAuthoringDiagnosticsReport diagnosticsForKind retourne liste immuable[0m
00:00 [32m+5[0m: EnvironmentAuthoringDiagnosticsReport diagnosticsForMap trim et inconnu[0m
00:00 [32m+6[0m: EnvironmentAuthoringDiagnosticsReport diagnosticsForLayer trim et inconnu[0m
00:00 [32m+7[0m: EnvironmentAuthoringDiagnosticsReport diagnosticsForArea trim et inconnu[0m
00:00 [32m+8[0m: EnvironmentAuthoringDiagnosticsReport diagnosticsForPreset trim et inconnu[0m
00:00 [32m+9[0m: EnvironmentAuthoringDiagnosticsReport égalité de valeur du rapport[0m
00:00 [32m+10[0m: EnvironmentAuthoringDiagnosticsSummary vide : compteurs à 0[0m
00:00 [32m+11[0m: EnvironmentAuthoringDiagnosticsSummary hasDiagnostics / hasErrors / hasWarnings[0m
00:00 [32m+12[0m: EnvironmentAuthoringDiagnosticsSummary compteurs agrégés depuis le rapport[0m
00:00 [32m+13[0m: mapping preset diagnostic missingPaletteElement conservé[0m
00:00 [32m+14[0m: mapping usage diagnostic missingAreaPreset conservé[0m
00:00 [32m+15[0m: ordre stable preset puis maps dans l’ordre fourni, ordre interne usage inchangé[0m
00:00 [32m+16[0m: diagnoseProjectEnvironmentAuthoring maps vide : seulement diagnostics preset[0m
00:00 [32m+17[0m: diagnoseProjectEnvironmentAuthoring manifest et maps sans problème : rapport vide[0m
00:00 [32m+18[0m: diagnoseProjectEnvironmentAuthoring agrège preset + usage[0m
00:00 [32m+19[0m: diagnoseProjectEnvironmentAuthoring knownTemplateIds transmis à diagnoseProjectEnvironmentPresets[0m
00:00 [32m+20[0m: All tests passed![0m
```

### dart test (régressions Environment)

Sortie complète (199 lignes, fichier `/tmp/map_core_lot8_regress_nocolor.txt`) :

```
00:00 [32m+0[0m: [1m[90mloading test/environment_core_models_test.dart[0m[0m
00:00 [32m+0[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item[0m
00:00 [32m+1[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item[0m
00:00 [32m+2[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+3[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+4[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+5[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+6[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+7[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+8[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m
00:00 [32m+9[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects weight <= 0[0m
00:00 [32m+10[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts valid areas and preserves order[0m
00:00 [32m+11[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts valid areas and preserves order[0m
00:00 [32m+12[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide[0m
00:00 [32m+13[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem copies tags defensively[0m
00:00 [32m+14[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction empty factory[0m
00:00 [32m+15[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode targetTileLayerId trimé[0m
00:00 [32m+16[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem tags are immutable[0m
00:00 [32m+17[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem tags are immutable[0m
00:00 [32m+18[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode targetTileLayerId null explicite => null[0m
00:00 [32m+19[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent defensive copy and immutability areas is unmodifiable[0m
00:00 [32m+20[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty tag[0m
00:00 [32m+21[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode targetTileLayerId whitespace => FormatException[0m
00:00 [32m+22[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode targetTileLayerId whitespace => FormatException[0m
00:00 [32m+23[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m
00:00 [32m+24[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m
00:00 [32m+25[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m
00:00 [32m+26[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m
00:00 [32m+27[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+28[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+29[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+30[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+31[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+32[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+33[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+34[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+35[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+36[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+37[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+38[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+39[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+40[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+41[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+42[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+43[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+44[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+45[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+46[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+47[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+48[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+49[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+50[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+51[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+52[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+53[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+54[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+55[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+56[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+57[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+58[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+59[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m
00:00 [32m+60[0m: test/environment_core_models_test.dart: EnvironmentAreaMask cells copied defensively[0m
00:00 [32m+61[0m: test/environment_core_models_test.dart: EnvironmentAreaMask cells copied defensively[0m
00:00 [32m+62[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal[0m
00:00 [32m+63[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal[0m
00:00 [32m+64[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal[0m
00:00 [32m+65[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+66[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+67[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+68[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+69[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+70[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+71[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+72[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+73[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+74[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+75[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m
00:00 [32m+76[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+77[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+78[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+79[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+80[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+81[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+82[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+83[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+84[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+85[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+86[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+87[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+88[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+89[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+90[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+91[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+92[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+93[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+94[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+95[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m
00:00 [32m+96[0m: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent refuse layerId vide[0m
00:00 [32m+97[0m: test/environment_core_models_test.dart: EnvironmentArea value equality[0m
00:00 [32m+98[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet[0m
00:00 [32m+99[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet[0m
00:00 [32m+100[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet[0m
00:00 [32m+101[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet[0m
00:00 [32m+102[0m: test/environment_core_models_test.dart: EnvironmentPreset rejects empty id name templateId[0m
00:00 [32m+103[0m: test/environment_layer_map_layer_integration_test.dart: setEnvironmentLayerContent ne modifie pas placedElements[0m
00:00 [32m+104[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec roundtrip preset complet[0m
00:00 [32m+105[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec roundtrip preset complet[0m
00:00 [32m+106[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+107[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+108[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+109[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+110[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+111[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+112[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+113[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+114[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+115[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+116[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide[0m
00:00 [32m+117[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag non-string => FormatException[0m
00:00 [32m+118[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer targetTileLayerId valide si TileLayer existe[0m
00:00 [32m+119[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException[0m
00:00 [32m+120[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException[0m
00:00 [32m+121[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si targetTileLayerId pointe vers le layer environment lui-même[0m
00:00 [32m+122[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode weight double => FormatException[0m
00:00 [32m+123[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer[0m
00:00 [32m+124[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer[0m
00:00 [32m+125[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode minSpacingCells double => FormatException[0m
00:00 [32m+126[0m: test/environment_layer_map_layer_integration_test.dart: MapValidator EnvironmentLayer invalide si masque ne correspond pas à la taille carte[0m
00:00 [32m+127[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode density hors [0,1] => FormatException[0m
00:00 [32m+128[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode density hors [0,1] => FormatException[0m
00:00 [32m+129[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment JSON edge cases properties roundtrip[0m
00:00 [32m+130[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode palette vide => FormatException via modèle[0m
00:00 [32m+131[0m: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées[0m
00:00 [32m+132[0m: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées[0m
00:00 [32m+133[0m: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées[0m
00:00 [32m+134[0m: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées[0m
00:00 [32m+135[0m: test/environment_preset_json_codec_test.dart: decodeEnvironmentGenerationParamsJson accepte int pour densités[0m
00:00 [32m+136[0m: test/environment_layer_map_layer_integration_test.dart: resizeMapData EnvironmentLayer rétrécit la carte : cellules hors carte supprimées[0m
00:00 [32m+137[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson sans environmentPresets => [][0m
00:00 [32m+138[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m
00:00 [32m+139[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m
00:00 [32m+140[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets complet => liste[0m
00:00 [32m+141[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport copie défensive et liste immuable exposée[0m
00:00 [32m+142[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON toJson inclut environmentPresets[0m
00:00 [32m+143[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport errorCount / warningCount / diagnosticCount[0m
00:00 [32m+144[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet[0m
00:00 [32m+145[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet[0m
00:00 [32m+146[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet[0m
00:00 [32m+147[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+148[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+149[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+150[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+151[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+152[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+153[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+154[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+155[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+156[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+157[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+158[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+159[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+160[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+161[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+162[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+163[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+164[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+165[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m
00:00 [32m+166[0m: test/environment_preset_diagnostics_test.dart: missingPaletteElement deux presets référencent même absent => un diagnostic par preset[0m
00:00 [32m+167[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport copie défensive et liste immuable[0m
00:00 [32m+168[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport copie défensive et liste immuable[0m
00:00 [32m+169[0m: test/environment_preset_diagnostics_test.dart: unknownTemplateId template connu => rien[0m
00:00 [32m+170[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport counts et diagnosticsForLayer / Area / Kind[0m
00:00 [32m+171[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport counts et diagnosticsForLayer / Area / Kind[0m
00:00 [32m+172[0m: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile forceEnabled + collisionProfile non-null => rien[0m
00:00 [32m+173[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport égalité[0m
00:00 [32m+174[0m: test/environment_preset_diagnostics_test.dart: forcedCollisionWithoutProfile forceEnabled + collisionProfile null => warning[0m
00:00 [32m+175[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m
00:00 [32m+176[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m
00:00 [32m+177[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m
00:00 [32m+178[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m
00:00 [32m+179[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m
00:00 [32m+180[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset absent => error[0m
00:00 [32m+181[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset deux areas même preset absent => deux diagnostics[0m
00:00 [32m+182[0m: test/environment_layer_usage_diagnostics_test.dart: missingTargetTileLayerId sans area => pas de warning[0m
00:00 [32m+183[0m: test/environment_layer_usage_diagnostics_test.dart: missingTargetTileLayerId avec area sans target => warning[0m
00:00 [32m+184[0m: test/environment_layer_usage_diagnostics_test.dart: unknownTargetTileLayer TileLayer existant => rien[0m
00:00 [32m+185[0m: test/environment_layer_usage_diagnostics_test.dart: unknownTargetTileLayer cible inexistante => error[0m
00:00 [32m+186[0m: test/environment_layer_usage_diagnostics_test.dart: targetLayerIsNotTileLayer ObjectLayer => error[0m
00:00 [32m+187[0m: test/environment_layer_usage_diagnostics_test.dart: targetLayerIsNotTileLayer self EnvironmentLayer => error[0m
00:00 [32m+188[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch taille ok => rien[0m
00:00 [32m+189[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch width différent[0m
00:00 [32m+190[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch height différent[0m
00:00 [32m+191[0m: test/environment_layer_usage_diagnostics_test.dart: emptyAreaMask au moins une cellule active => rien[0m
00:00 [32m+192[0m: test/environment_layer_usage_diagnostics_test.dart: emptyAreaMask masque tout false => warning[0m
00:00 [32m+193[0m: test/environment_layer_usage_diagnostics_test.dart: missingGeneratedPlacement ids présents => rien[0m
00:00 [32m+194[0m: test/environment_layer_usage_diagnostics_test.dart: missingGeneratedPlacement id absent => warning avec message stable[0m
00:00 [32m+195[0m: test/environment_layer_usage_diagnostics_test.dart: missingGeneratedPlacement plusieurs ids absents => ordre des generatedPlacementIds[0m
00:00 [32m+196[0m: test/environment_layer_usage_diagnostics_test.dart: ordre stable targets puis areaMismatch, empty, preset, placements[0m
00:00 [32m+197[0m: All tests passed![0m
```

### dart test (suite complète map_core)

Ligne finale exacte extraite du journal brut (`/tmp/map_core_test_full.txt`) autour de `All tests passed` :

```
'       \n00:02 \x1b[32m+1351\x1b[0m: All tests passed!\x1b[0m    '
```

Interprétation lisible (sans séquences ANSI) : **`00:02 +1351: All tests passed!`**

## 14. Git status initial et final

**Initial** (avant modifications Lot 8, même session) : (sortie vide : arbre de travail propre au moment du début du Lot 8 dans cette session — commande `git status --short --untracked-files=all` exécutée avant modifications.)

**Final** (commande `git status --short --untracked-files=all` à la racine du dépôt, après écriture de ce rapport) :

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
?? packages/map_core/test/environment_authoring_diagnostics_test.dart
?? reports/forest/environment_studio_lot_8_environment_diagnostics_aggregator.md
```

## 15. Contenu complet des fichiers créés ou modifiés

### 15.1 `environment_authoring_diagnostics.dart`

```dart
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'environment_layer_usage_diagnostics.dart';
import 'environment_preset_diagnostics.dart';

/// Gravité unifiée pour l’UI auteur Environment (Lot Environment-8).
enum EnvironmentAuthoringDiagnosticSeverity {
  error,
  warning,
}

/// Origine du diagnostic dans la pile Environment.
enum EnvironmentAuthoringDiagnosticSource {
  /// Issu de [diagnoseProjectEnvironmentPresets].
  presetManifest,

  /// Issu de [diagnoseMapEnvironmentLayerUsage].
  layerUsage,
}

/// Union des kinds des lots Environment-6 et Environment-7.
enum EnvironmentAuthoringDiagnosticKind {
  duplicatePresetId,
  missingPaletteElement,
  unknownTemplateId,
  forcedCollisionWithoutProfile,
  missingAreaPreset,
  missingTargetTileLayerId,
  unknownTargetTileLayer,
  targetLayerIsNotTileLayer,
  areaMaskSizeMismatch,
  emptyAreaMask,
  missingGeneratedPlacement,
}

/// Ligne de diagnostic prête pour agrégation / UI.
final class EnvironmentAuthoringDiagnostic {
  const EnvironmentAuthoringDiagnostic({
    required this.source,
    required this.severity,
    required this.kind,
    required this.message,
    this.mapId,
    this.layerId,
    this.areaId,
    this.presetId,
    this.elementId,
    this.templateId,
    this.targetTileLayerId,
    this.generatedPlacementId,
  });

  final EnvironmentAuthoringDiagnosticSource source;
  final EnvironmentAuthoringDiagnosticSeverity severity;
  final EnvironmentAuthoringDiagnosticKind kind;
  final String message;

  final String? mapId;
  final String? layerId;
  final String? areaId;
  final String? presetId;
  final String? elementId;
  final String? templateId;
  final String? targetTileLayerId;
  final String? generatedPlacementId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAuthoringDiagnostic &&
            source == other.source &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            mapId == other.mapId &&
            layerId == other.layerId &&
            areaId == other.areaId &&
            presetId == other.presetId &&
            elementId == other.elementId &&
            templateId == other.templateId &&
            targetTileLayerId == other.targetTileLayerId &&
            generatedPlacementId == other.generatedPlacementId;
  }

  @override
  int get hashCode => Object.hash(
        source,
        severity,
        kind,
        message,
        mapId,
        layerId,
        areaId,
        presetId,
        elementId,
        templateId,
        targetTileLayerId,
        generatedPlacementId,
      );
}

/// Compteurs globaux pour un tableau de bord auteur.
final class EnvironmentAuthoringDiagnosticsSummary {
  const EnvironmentAuthoringDiagnosticsSummary({
    required this.totalCount,
    required this.errorCount,
    required this.warningCount,
    required this.presetManifestCount,
    required this.layerUsageCount,
    required this.mapsWithDiagnosticsCount,
    required this.presetsWithDiagnosticsCount,
  });

  final int totalCount;
  final int errorCount;
  final int warningCount;
  final int presetManifestCount;
  final int layerUsageCount;
  final int mapsWithDiagnosticsCount;
  final int presetsWithDiagnosticsCount;

  bool get hasDiagnostics => totalCount > 0;

  bool get hasErrors => errorCount > 0;

  bool get hasWarnings => warningCount > 0;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAuthoringDiagnosticsSummary &&
            totalCount == other.totalCount &&
            errorCount == other.errorCount &&
            warningCount == other.warningCount &&
            presetManifestCount == other.presetManifestCount &&
            layerUsageCount == other.layerUsageCount &&
            mapsWithDiagnosticsCount == other.mapsWithDiagnosticsCount &&
            presetsWithDiagnosticsCount == other.presetsWithDiagnosticsCount;
  }

  @override
  int get hashCode => Object.hash(
        totalCount,
        errorCount,
        warningCount,
        presetManifestCount,
        layerUsageCount,
        mapsWithDiagnosticsCount,
        presetsWithDiagnosticsCount,
      );
}

/// Rapport unifié presets + usages cartes (lecture seule côté entrées).
final class EnvironmentAuthoringDiagnosticsReport {
  factory EnvironmentAuthoringDiagnosticsReport({
    required List<EnvironmentAuthoringDiagnostic> diagnostics,
  }) {
    final copy = List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      List<EnvironmentAuthoringDiagnostic>.from(diagnostics),
    );
    return EnvironmentAuthoringDiagnosticsReport._(
      diagnostics: copy,
      summary: _computeSummary(copy),
    );
  }

  const EnvironmentAuthoringDiagnosticsReport._({
    required this.diagnostics,
    required this.summary,
  });

  final List<EnvironmentAuthoringDiagnostic> diagnostics;

  final EnvironmentAuthoringDiagnosticsSummary summary;

  bool get hasDiagnostics => summary.hasDiagnostics;

  bool get hasErrors => summary.hasErrors;

  bool get hasWarnings => summary.hasWarnings;

  int get diagnosticCount => diagnostics.length;

  int get errorCount => summary.errorCount;

  int get warningCount => summary.warningCount;

  List<EnvironmentAuthoringDiagnostic> diagnosticsForSource(
    EnvironmentAuthoringDiagnosticSource source,
  ) {
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.source == source).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForKind(
    EnvironmentAuthoringDiagnosticKind kind,
  ) {
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.kind == kind).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForMap(String mapId) {
    final key = mapId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.mapId == key).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForLayer(String layerId) {
    final key = layerId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.layerId == key).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForArea(String areaId) {
    final key = areaId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.areaId == key).toList(growable: false),
    );
  }

  List<EnvironmentAuthoringDiagnostic> diagnosticsForPreset(String presetId) {
    final key = presetId.trim();
    if (key.isEmpty) {
      return const [];
    }
    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
      diagnostics.where((d) => d.presetId == key).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAuthoringDiagnosticsReport &&
            _listEqualsAuthoring(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hashAll(diagnostics);
}

EnvironmentAuthoringDiagnosticsSummary _computeSummary(
  List<EnvironmentAuthoringDiagnostic> diagnostics,
) {
  var errors = 0;
  var warnings = 0;
  var presetSrc = 0;
  var layerSrc = 0;
  final mapIds = <String>{};
  final presetIds = <String>{};

  for (final d in diagnostics) {
    switch (d.severity) {
      case EnvironmentAuthoringDiagnosticSeverity.error:
        errors++;
      case EnvironmentAuthoringDiagnosticSeverity.warning:
        warnings++;
    }
    switch (d.source) {
      case EnvironmentAuthoringDiagnosticSource.presetManifest:
        presetSrc++;
      case EnvironmentAuthoringDiagnosticSource.layerUsage:
        layerSrc++;
    }
    final mid = d.mapId;
    if (mid != null) {
      mapIds.add(mid);
    }
    final pid = d.presetId;
    if (pid != null) {
      presetIds.add(pid);
    }
  }

  final n = diagnostics.length;

  return EnvironmentAuthoringDiagnosticsSummary(
    totalCount: n,
    errorCount: errors,
    warningCount: warnings,
    presetManifestCount: presetSrc,
    layerUsageCount: layerSrc,
    mapsWithDiagnosticsCount: mapIds.length,
    presetsWithDiagnosticsCount: presetIds.length,
  );
}

bool _listEqualsAuthoring(
  List<EnvironmentAuthoringDiagnostic> a,
  List<EnvironmentAuthoringDiagnostic> b,
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

EnvironmentAuthoringDiagnosticSeverity _mapPresetSeverity(
  EnvironmentPresetDiagnosticSeverity s,
) {
  return switch (s) {
    EnvironmentPresetDiagnosticSeverity.error =>
      EnvironmentAuthoringDiagnosticSeverity.error,
    EnvironmentPresetDiagnosticSeverity.warning =>
      EnvironmentAuthoringDiagnosticSeverity.warning,
  };
}

EnvironmentAuthoringDiagnosticKind _mapPresetKind(
  EnvironmentPresetDiagnosticKind k,
) {
  return switch (k) {
    EnvironmentPresetDiagnosticKind.duplicatePresetId =>
      EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
    EnvironmentPresetDiagnosticKind.missingPaletteElement =>
      EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
    EnvironmentPresetDiagnosticKind.unknownTemplateId =>
      EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
    EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile =>
      EnvironmentAuthoringDiagnosticKind.forcedCollisionWithoutProfile,
  };
}

EnvironmentAuthoringDiagnostic _fromPreset(EnvironmentPresetDiagnostic d) {
  return EnvironmentAuthoringDiagnostic(
    source: EnvironmentAuthoringDiagnosticSource.presetManifest,
    severity: _mapPresetSeverity(d.severity),
    kind: _mapPresetKind(d.kind),
    message: d.message,
    presetId: d.presetId,
    elementId: d.elementId,
    templateId: d.templateId,
  );
}

EnvironmentAuthoringDiagnosticSeverity _mapUsageSeverity(
  EnvironmentLayerUsageDiagnosticSeverity s,
) {
  return switch (s) {
    EnvironmentLayerUsageDiagnosticSeverity.error =>
      EnvironmentAuthoringDiagnosticSeverity.error,
    EnvironmentLayerUsageDiagnosticSeverity.warning =>
      EnvironmentAuthoringDiagnosticSeverity.warning,
  };
}

EnvironmentAuthoringDiagnosticKind _mapUsageKind(
  EnvironmentLayerUsageDiagnosticKind k,
) {
  return switch (k) {
    EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
      EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
    EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
      EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
    EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
      EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
    EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
      EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
    EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
      EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
    EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
      EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
    EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
      EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
  };
}

EnvironmentAuthoringDiagnostic _fromUsage(EnvironmentLayerUsageDiagnostic d) {
  return EnvironmentAuthoringDiagnostic(
    source: EnvironmentAuthoringDiagnosticSource.layerUsage,
    severity: _mapUsageSeverity(d.severity),
    kind: _mapUsageKind(d.kind),
    message: d.message,
    mapId: d.mapId,
    layerId: d.layerId,
    areaId: d.areaId,
    presetId: d.presetId,
    targetTileLayerId: d.targetTileLayerId,
    generatedPlacementId: d.generatedPlacementId,
  );
}

/// Agrège les diagnostics Environment presets (Lot 6) et usages cartes (Lot 7).
///
/// [maps] : uniquement les cartes déjà chargées ; aucune lecture disque ni
/// chargement depuis [ProjectManifest.maps].
///
/// Ordre : diagnostics presets dans l’ordre de [diagnoseProjectEnvironmentPresets],
/// puis pour chaque entrée de [maps] dans l’ordre, les diagnostics de
/// [diagnoseMapEnvironmentLayerUsage] pour cette carte.
EnvironmentAuthoringDiagnosticsReport diagnoseProjectEnvironmentAuthoring(
  ProjectManifest manifest, {
  required List<MapData> maps,
  Set<String> knownTemplateIds = const <String>{},
}) {
  final out = <EnvironmentAuthoringDiagnostic>[];

  final presetReport = diagnoseProjectEnvironmentPresets(
    manifest,
    knownTemplateIds: knownTemplateIds,
  );
  for (final d in presetReport.diagnostics) {
    out.add(_fromPreset(d));
  }

  for (final map in maps) {
    final usageReport = diagnoseMapEnvironmentLayerUsage(manifest, map);
    for (final d in usageReport.diagnostics) {
      out.add(_fromUsage(d));
    }
  }

  return EnvironmentAuthoringDiagnosticsReport(diagnostics: out);
}

```

### 15.2 `environment_authoring_diagnostics_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'authoring_diag',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: environmentPresets,
    elements: elements,
  );
}

EnvironmentPreset _preset({
  required String id,
  String templateId = 'tpl',
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

MapData _map({
  required String id,
  List<MapLayer> layers = const [],
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: id,
    name: 'Map $id',
    size: const GridSize(width: 4, height: 3),
    tilesetId: 'tileset',
    layers: layers,
    placedElements: placedElements,
  );
}

void main() {
  group('EnvironmentAuthoringDiagnosticsReport', () {
    test('vide : hasDiagnostics / erreurs / warnings', () {
      final r = EnvironmentAuthoringDiagnosticsReport(diagnostics: []);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.hasWarnings, isFalse);
      expect(r.diagnosticCount, 0);
      expect(r.summary.totalCount, 0);
    });

    test('copie défensive et liste immuable', () {
      final raw = <EnvironmentAuthoringDiagnostic>[
        EnvironmentAuthoringDiagnostic(
          source: EnvironmentAuthoringDiagnosticSource.layerUsage,
          severity: EnvironmentAuthoringDiagnosticSeverity.error,
          kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
          message: 'm',
          mapId: 'x',
          layerId: 'l',
        ),
      ];
      final r = EnvironmentAuthoringDiagnosticsReport(diagnostics: raw);
      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
      raw.clear();
      expect(r.diagnosticCount, 1);
    });

    test('diagnosticCount / errorCount / warningCount', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'e',
            presetId: 'p',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
            message: 'w',
            mapId: 'm',
            layerId: 'l',
            areaId: 'a',
          ),
        ],
      );
      expect(r.diagnosticCount, 2);
      expect(r.errorCount, 1);
      expect(r.warningCount, 1);
    });

    test('diagnosticsForSource', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
            message: 'a',
            presetId: 'p1',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'b',
            mapId: 'm',
            layerId: 'l',
            presetId: 'p2',
          ),
        ],
      );
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.presetManifest)
              .length,
          1);
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.layerUsage)
              .length,
          1);
      expect(
        () => r
            .diagnosticsForSource(
                EnvironmentAuthoringDiagnosticSource.presetManifest)
            .add(
              r.diagnostics.first,
            ),
        throwsUnsupportedError,
      );
    });

    test('diagnosticsForKind retourne liste immuable', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'x',
            presetId: 'dup',
          ),
        ],
      );
      final list = r.diagnosticsForKind(
          EnvironmentAuthoringDiagnosticKind.duplicatePresetId);
      expect(list.length, 1);
      expect(() => list.add(r.diagnostics.first), throwsUnsupportedError);
    });

    test('diagnosticsForMap trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
            message: 'msg',
            mapId: 'map_a',
            layerId: 'env',
            targetTileLayerId: 'x',
          ),
        ],
      );
      expect(r.diagnosticsForMap('  map_a  ').length, 1);
      expect(r.diagnosticsForMap(''), isEmpty);
      expect(r.diagnosticsForMap('   '), isEmpty);
      expect(r.diagnosticsForMap('missing'), isEmpty);
      expect(() => r.diagnosticsForMap('map_a').add(r.diagnostics.first),
          throwsUnsupportedError);
    });

    test('diagnosticsForLayer trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
            message: 'm',
            mapId: 'm1',
            layerId: 'env_layer',
          ),
        ],
      );
      expect(r.diagnosticsForLayer(' env_layer ').length, 1);
      expect(r.diagnosticsForLayer(''), isEmpty);
      expect(r.diagnosticsForLayer('nope'), isEmpty);
    });

    test('diagnosticsForArea trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
            message: 'e',
            mapId: 'm',
            layerId: 'l',
            areaId: 'forest',
          ),
        ],
      );
      expect(r.diagnosticsForArea(' forest ').length, 1);
      expect(r.diagnosticsForArea(''), isEmpty);
      expect(r.diagnosticsForArea('other'), isEmpty);
    });

    test('diagnosticsForPreset trim et inconnu', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
            message: 'msg',
            presetId: 'preset_x',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'usage',
            mapId: 'm',
            layerId: 'l',
            areaId: 'a',
            presetId: 'preset_x',
          ),
        ],
      );
      expect(r.diagnosticsForPreset(' preset_x ').length, 2);
      expect(r.diagnosticsForPreset(''), isEmpty);
      expect(r.diagnosticsForPreset('absent'), isEmpty);
    });

    test('égalité de valeur du rapport', () {
      final a = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'm',
            presetId: 'p',
          ),
        ],
      );
      final b = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
            message: 'm',
            presetId: 'p',
          ),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('EnvironmentAuthoringDiagnosticsSummary', () {
    test('vide : compteurs à 0', () {
      const s = EnvironmentAuthoringDiagnosticsSummary(
        totalCount: 0,
        errorCount: 0,
        warningCount: 0,
        presetManifestCount: 0,
        layerUsageCount: 0,
        mapsWithDiagnosticsCount: 0,
        presetsWithDiagnosticsCount: 0,
      );
      expect(s.hasDiagnostics, isFalse);
      expect(s.hasErrors, isFalse);
      expect(s.hasWarnings, isFalse);
    });

    test('hasDiagnostics / hasErrors / hasWarnings', () {
      const s = EnvironmentAuthoringDiagnosticsSummary(
        totalCount: 2,
        errorCount: 1,
        warningCount: 1,
        presetManifestCount: 1,
        layerUsageCount: 1,
        mapsWithDiagnosticsCount: 1,
        presetsWithDiagnosticsCount: 1,
      );
      expect(s.hasDiagnostics, isTrue);
      expect(s.hasErrors, isTrue);
      expect(s.hasWarnings, isTrue);
    });

    test('compteurs agrégés depuis le rapport', () {
      final r = EnvironmentAuthoringDiagnosticsReport(
        diagnostics: [
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
            message: 'm1',
            presetId: 'same_preset',
            elementId: 'missing_elm',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'm2',
            mapId: 'map_1',
            layerId: 'env',
            areaId: 'a1',
            presetId: 'same_preset',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.error,
            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
            message: 'm3',
            mapId: 'map_1',
            layerId: 'env',
            areaId: 'a2',
            presetId: 'same_preset',
          ),
          EnvironmentAuthoringDiagnostic(
            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
            message: 'm4',
            mapId: 'map_2',
            layerId: 'env',
            areaId: 'a3',
          ),
        ],
      );
      final s = r.summary;
      expect(s.totalCount, 4);
      expect(s.errorCount, 3);
      expect(s.warningCount, 1);
      expect(s.presetManifestCount, 1);
      expect(s.layerUsageCount, 3);
      expect(s.mapsWithDiagnosticsCount, 2);
      expect(s.presetsWithDiagnosticsCount, 1);
    });
  });

  group('mapping preset diagnostic', () {
    test('missingPaletteElement conservé', () {
      final m = _manifest(
        environmentPresets: [
          _preset(
            id: 'p1',
            palette: [
              EnvironmentPaletteItem(elementId: 'ghost_elm', weight: 1),
            ],
          ),
        ],
        elements: const [],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: const []);
      expect(r.diagnosticCount, 1);
      final d = r.diagnostics.single;
      expect(d.source, EnvironmentAuthoringDiagnosticSource.presetManifest);
      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.error);
      expect(d.kind, EnvironmentAuthoringDiagnosticKind.missingPaletteElement);
      expect(d.presetId, 'p1');
      expect(d.elementId, 'ghost_elm');
      expect(d.message, contains('p1'));
      expect(d.mapId, isNull);
      expect(d.layerId, isNull);
    });
  });

  group('mapping usage diagnostic', () {
    test('missingAreaPreset conservé', () {
      final m = _manifest(
        environmentPresets: [
          _preset(id: 'ok_preset'),
        ],
      );
      final map = _map(
        id: 'terrain_map',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'env1',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'zone_a', presetId: 'nope'),
              ],
            ),
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
      final d = r
          .diagnosticsForKind(
              EnvironmentAuthoringDiagnosticKind.missingAreaPreset)
          .single;
      expect(d.source, EnvironmentAuthoringDiagnosticSource.layerUsage);
      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.error);
      expect(d.mapId, 'terrain_map');
      expect(d.layerId, 'env1');
      expect(d.areaId, 'zone_a');
      expect(d.presetId, 'nope');
      expect(d.message, contains('zone_a'));
    });
  });

  group('ordre stable', () {
    test('preset puis maps dans l’ordre fourni, ordre interne usage inchangé',
        () {
      final m = _manifest(
        environmentPresets: [
          _preset(id: 'dup'),
          _preset(id: 'dup'),
        ],
        elements: [_element(id: 'elm_ok')],
      );

      final mapA = _map(
        id: 'first_map',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'e',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'a1', presetId: 'dup', mask: _mask(2, 2)),
              ],
            ),
          ),
        ],
      );

      final mapB = _map(
        id: 'second_map',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'e2',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'missing_decor',
              areas: [
                _area(id: 'b1', presetId: 'dup'),
              ],
            ),
          ),
        ],
      );

      final aggregated =
          diagnoseProjectEnvironmentAuthoring(m, maps: [mapA, mapB]);
      final presetOnly = diagnoseProjectEnvironmentPresets(m);
      final usageA = diagnoseMapEnvironmentLayerUsage(m, mapA);
      final usageB = diagnoseMapEnvironmentLayerUsage(m, mapB);

      final kinds = aggregated.diagnostics.map((d) => d.kind).toList();
      final expectedKinds = <EnvironmentAuthoringDiagnosticKind>[
        ...presetOnly.diagnostics.map((d) => switch (d.kind) {
              EnvironmentPresetDiagnosticKind.duplicatePresetId =>
                EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
              EnvironmentPresetDiagnosticKind.missingPaletteElement =>
                EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
              EnvironmentPresetDiagnosticKind.unknownTemplateId =>
                EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
              EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile =>
                EnvironmentAuthoringDiagnosticKind
                    .forcedCollisionWithoutProfile,
            }),
        ...usageA.diagnostics.map((d) => switch (d.kind) {
              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
                EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
              EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
                EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
              EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
                EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
                EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
                EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
              EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
                EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
                EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
            }),
        ...usageB.diagnostics.map((d) => switch (d.kind) {
              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
                EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
              EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
                EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
              EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
                EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
                EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
                EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
              EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
                EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
                EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
            }),
      ];
      expect(kinds, expectedKinds);
    });
  });

  group('diagnoseProjectEnvironmentAuthoring', () {
    test('maps vide : seulement diagnostics preset', () {
      final m = _manifest(
        environmentPresets: [
          _preset(
            id: 'p',
            palette: [
              EnvironmentPaletteItem(elementId: 'missing', weight: 1),
            ],
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: const []);
      expect(
          r.diagnostics.every((d) =>
              d.source == EnvironmentAuthoringDiagnosticSource.presetManifest),
          isTrue);
      expect(r.summary.layerUsageCount, 0);
      expect(r.summary.mapsWithDiagnosticsCount, 0);
    });

    test('manifest et maps sans problème : rapport vide', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'forest')],
        elements: [_element(id: 'elm_ok')],
      );
      final map = _map(
        id: 'clean',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'a', presetId: 'forest'),
              ],
            ),
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
      expect(r.hasDiagnostics, isFalse);
    });

    test('agrège preset + usage', () {
      final m = _manifest(
        environmentPresets: [
          _preset(
            id: 'p1',
            palette: [
              EnvironmentPaletteItem(elementId: 'bad', weight: 1),
            ],
          ),
        ],
      );
      final map = _map(
        id: 'agg',
        layers: [
          _decorLayer(),
          _envLayer(
            id: 'env',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                _area(id: 'ar', presetId: 'unknown_preset'),
              ],
            ),
          ),
        ],
      );
      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
      expect(r.diagnosticCount, 2);
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.presetManifest)
              .length,
          1);
      expect(
          r
              .diagnosticsForSource(
                  EnvironmentAuthoringDiagnosticSource.layerUsage)
              .length,
          1);
    });

    test('knownTemplateIds transmis à diagnoseProjectEnvironmentPresets', () {
      final m = _manifest(
        environmentPresets: [_preset(id: 'p', templateId: 'my_tpl')],
        elements: [_element(id: 'elm_ok')],
      );
      final withoutKnown =
          diagnoseProjectEnvironmentAuthoring(m, maps: const []);
      expect(
        withoutKnown.diagnosticsForKind(
            EnvironmentAuthoringDiagnosticKind.unknownTemplateId),
        isEmpty,
      );

      final withKnown = diagnoseProjectEnvironmentAuthoring(
        m,
        maps: const [],
        knownTemplateIds: {'other'},
      );
      expect(
        withKnown
            .diagnosticsForKind(
                EnvironmentAuthoringDiagnosticKind.unknownTemplateId)
            .length,
        1,
      );
      final d = withKnown.diagnostics.single;
      expect(d.templateId, 'my_tpl');
      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.warning);
    });
  });
}

```

### 15.3 Extrait `map_core.dart` (exports Environment + nouveau)

```
  72|export 'src/operations/element_collision_mask_codec.dart';
  73|export 'src/collision/pixel_rect.dart';
  74|export 'src/collision/player_collision_conventions_v1.dart';
  75|export 'src/operations/map_layers.dart';
  76|export 'src/operations/environment_layer_content_json_codec.dart';
  77|export 'src/operations/environment_preset_json_codec.dart';
  78|export 'src/operations/project_manifest_environment_preset_operations.dart';
  79|export 'src/operations/environment_preset_diagnostics.dart';
  80|export 'src/operations/environment_layer_usage_diagnostics.dart';
  81|export 'src/operations/environment_authoring_diagnostics.dart';
  82|export 'src/operations/surface_layer_placements.dart';
  83|export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
  84|export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
  85|export 'src/operations/surface_variant_role_resolver.dart';
```

## 16. Diff complet

### 16.1 `git diff -- packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 73907663..0a79f909 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -78,6 +78,7 @@ export 'src/operations/environment_preset_json_codec.dart';
 export 'src/operations/project_manifest_environment_preset_operations.dart';
 export 'src/operations/environment_preset_diagnostics.dart';
 export 'src/operations/environment_layer_usage_diagnostics.dart';
+export 'src/operations/environment_authoring_diagnostics.dart';
 export 'src/operations/surface_layer_placements.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
 export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
```

### 16.2 `git diff --no-index /dev/null ... environment_authoring_diagnostics.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart b/packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
new file mode 100644
index 00000000..c3e00a30
--- /dev/null
+++ b/packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
@@ -0,0 +1,435 @@
+import '../models/map_data.dart';
+import '../models/project_manifest.dart';
+import 'environment_layer_usage_diagnostics.dart';
+import 'environment_preset_diagnostics.dart';
+
+/// Gravité unifiée pour l’UI auteur Environment (Lot Environment-8).
+enum EnvironmentAuthoringDiagnosticSeverity {
+  error,
+  warning,
+}
+
+/// Origine du diagnostic dans la pile Environment.
+enum EnvironmentAuthoringDiagnosticSource {
+  /// Issu de [diagnoseProjectEnvironmentPresets].
+  presetManifest,
+
+  /// Issu de [diagnoseMapEnvironmentLayerUsage].
+  layerUsage,
+}
+
+/// Union des kinds des lots Environment-6 et Environment-7.
+enum EnvironmentAuthoringDiagnosticKind {
+  duplicatePresetId,
+  missingPaletteElement,
+  unknownTemplateId,
+  forcedCollisionWithoutProfile,
+  missingAreaPreset,
+  missingTargetTileLayerId,
+  unknownTargetTileLayer,
+  targetLayerIsNotTileLayer,
+  areaMaskSizeMismatch,
+  emptyAreaMask,
+  missingGeneratedPlacement,
+}
+
+/// Ligne de diagnostic prête pour agrégation / UI.
+final class EnvironmentAuthoringDiagnostic {
+  const EnvironmentAuthoringDiagnostic({
+    required this.source,
+    required this.severity,
+    required this.kind,
+    required this.message,
+    this.mapId,
+    this.layerId,
+    this.areaId,
+    this.presetId,
+    this.elementId,
+    this.templateId,
+    this.targetTileLayerId,
+    this.generatedPlacementId,
+  });
+
+  final EnvironmentAuthoringDiagnosticSource source;
+  final EnvironmentAuthoringDiagnosticSeverity severity;
+  final EnvironmentAuthoringDiagnosticKind kind;
+  final String message;
+
+  final String? mapId;
+  final String? layerId;
+  final String? areaId;
+  final String? presetId;
+  final String? elementId;
+  final String? templateId;
+  final String? targetTileLayerId;
+  final String? generatedPlacementId;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentAuthoringDiagnostic &&
+            source == other.source &&
+            severity == other.severity &&
+            kind == other.kind &&
+            message == other.message &&
+            mapId == other.mapId &&
+            layerId == other.layerId &&
+            areaId == other.areaId &&
+            presetId == other.presetId &&
+            elementId == other.elementId &&
+            templateId == other.templateId &&
+            targetTileLayerId == other.targetTileLayerId &&
+            generatedPlacementId == other.generatedPlacementId;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        source,
+        severity,
+        kind,
+        message,
+        mapId,
+        layerId,
+        areaId,
+        presetId,
+        elementId,
+        templateId,
+        targetTileLayerId,
+        generatedPlacementId,
+      );
+}
+
+/// Compteurs globaux pour un tableau de bord auteur.
+final class EnvironmentAuthoringDiagnosticsSummary {
+  const EnvironmentAuthoringDiagnosticsSummary({
+    required this.totalCount,
+    required this.errorCount,
+    required this.warningCount,
+    required this.presetManifestCount,
+    required this.layerUsageCount,
+    required this.mapsWithDiagnosticsCount,
+    required this.presetsWithDiagnosticsCount,
+  });
+
+  final int totalCount;
+  final int errorCount;
+  final int warningCount;
+  final int presetManifestCount;
+  final int layerUsageCount;
+  final int mapsWithDiagnosticsCount;
+  final int presetsWithDiagnosticsCount;
+
+  bool get hasDiagnostics => totalCount > 0;
+
+  bool get hasErrors => errorCount > 0;
+
+  bool get hasWarnings => warningCount > 0;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentAuthoringDiagnosticsSummary &&
+            totalCount == other.totalCount &&
+            errorCount == other.errorCount &&
+            warningCount == other.warningCount &&
+            presetManifestCount == other.presetManifestCount &&
+            layerUsageCount == other.layerUsageCount &&
+            mapsWithDiagnosticsCount == other.mapsWithDiagnosticsCount &&
+            presetsWithDiagnosticsCount == other.presetsWithDiagnosticsCount;
+  }
+
+  @override
+  int get hashCode => Object.hash(
+        totalCount,
+        errorCount,
+        warningCount,
+        presetManifestCount,
+        layerUsageCount,
+        mapsWithDiagnosticsCount,
+        presetsWithDiagnosticsCount,
+      );
+}
+
+/// Rapport unifié presets + usages cartes (lecture seule côté entrées).
+final class EnvironmentAuthoringDiagnosticsReport {
+  factory EnvironmentAuthoringDiagnosticsReport({
+    required List<EnvironmentAuthoringDiagnostic> diagnostics,
+  }) {
+    final copy = List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      List<EnvironmentAuthoringDiagnostic>.from(diagnostics),
+    );
+    return EnvironmentAuthoringDiagnosticsReport._(
+      diagnostics: copy,
+      summary: _computeSummary(copy),
+    );
+  }
+
+  const EnvironmentAuthoringDiagnosticsReport._({
+    required this.diagnostics,
+    required this.summary,
+  });
+
+  final List<EnvironmentAuthoringDiagnostic> diagnostics;
+
+  final EnvironmentAuthoringDiagnosticsSummary summary;
+
+  bool get hasDiagnostics => summary.hasDiagnostics;
+
+  bool get hasErrors => summary.hasErrors;
+
+  bool get hasWarnings => summary.hasWarnings;
+
+  int get diagnosticCount => diagnostics.length;
+
+  int get errorCount => summary.errorCount;
+
+  int get warningCount => summary.warningCount;
+
+  List<EnvironmentAuthoringDiagnostic> diagnosticsForSource(
+    EnvironmentAuthoringDiagnosticSource source,
+  ) {
+    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.source == source).toList(growable: false),
+    );
+  }
+
+  List<EnvironmentAuthoringDiagnostic> diagnosticsForKind(
+    EnvironmentAuthoringDiagnosticKind kind,
+  ) {
+    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.kind == kind).toList(growable: false),
+    );
+  }
+
+  List<EnvironmentAuthoringDiagnostic> diagnosticsForMap(String mapId) {
+    final key = mapId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.mapId == key).toList(growable: false),
+    );
+  }
+
+  List<EnvironmentAuthoringDiagnostic> diagnosticsForLayer(String layerId) {
+    final key = layerId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.layerId == key).toList(growable: false),
+    );
+  }
+
+  List<EnvironmentAuthoringDiagnostic> diagnosticsForArea(String areaId) {
+    final key = areaId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.areaId == key).toList(growable: false),
+    );
+  }
+
+  List<EnvironmentAuthoringDiagnostic> diagnosticsForPreset(String presetId) {
+    final key = presetId.trim();
+    if (key.isEmpty) {
+      return const [];
+    }
+    return List<EnvironmentAuthoringDiagnostic>.unmodifiable(
+      diagnostics.where((d) => d.presetId == key).toList(growable: false),
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentAuthoringDiagnosticsReport &&
+            _listEqualsAuthoring(other.diagnostics, diagnostics);
+  }
+
+  @override
+  int get hashCode => Object.hashAll(diagnostics);
+}
+
+EnvironmentAuthoringDiagnosticsSummary _computeSummary(
+  List<EnvironmentAuthoringDiagnostic> diagnostics,
+) {
+  var errors = 0;
+  var warnings = 0;
+  var presetSrc = 0;
+  var layerSrc = 0;
+  final mapIds = <String>{};
+  final presetIds = <String>{};
+
+  for (final d in diagnostics) {
+    switch (d.severity) {
+      case EnvironmentAuthoringDiagnosticSeverity.error:
+        errors++;
+      case EnvironmentAuthoringDiagnosticSeverity.warning:
+        warnings++;
+    }
+    switch (d.source) {
+      case EnvironmentAuthoringDiagnosticSource.presetManifest:
+        presetSrc++;
+      case EnvironmentAuthoringDiagnosticSource.layerUsage:
+        layerSrc++;
+    }
+    final mid = d.mapId;
+    if (mid != null) {
+      mapIds.add(mid);
+    }
+    final pid = d.presetId;
+    if (pid != null) {
+      presetIds.add(pid);
+    }
+  }
+
+  final n = diagnostics.length;
+
+  return EnvironmentAuthoringDiagnosticsSummary(
+    totalCount: n,
+    errorCount: errors,
+    warningCount: warnings,
+    presetManifestCount: presetSrc,
+    layerUsageCount: layerSrc,
+    mapsWithDiagnosticsCount: mapIds.length,
+    presetsWithDiagnosticsCount: presetIds.length,
+  );
+}
+
+bool _listEqualsAuthoring(
+  List<EnvironmentAuthoringDiagnostic> a,
+  List<EnvironmentAuthoringDiagnostic> b,
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
+EnvironmentAuthoringDiagnosticSeverity _mapPresetSeverity(
+  EnvironmentPresetDiagnosticSeverity s,
+) {
+  return switch (s) {
+    EnvironmentPresetDiagnosticSeverity.error =>
+      EnvironmentAuthoringDiagnosticSeverity.error,
+    EnvironmentPresetDiagnosticSeverity.warning =>
+      EnvironmentAuthoringDiagnosticSeverity.warning,
+  };
+}
+
+EnvironmentAuthoringDiagnosticKind _mapPresetKind(
+  EnvironmentPresetDiagnosticKind k,
+) {
+  return switch (k) {
+    EnvironmentPresetDiagnosticKind.duplicatePresetId =>
+      EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+    EnvironmentPresetDiagnosticKind.missingPaletteElement =>
+      EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
+    EnvironmentPresetDiagnosticKind.unknownTemplateId =>
+      EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
+    EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile =>
+      EnvironmentAuthoringDiagnosticKind.forcedCollisionWithoutProfile,
+  };
+}
+
+EnvironmentAuthoringDiagnostic _fromPreset(EnvironmentPresetDiagnostic d) {
+  return EnvironmentAuthoringDiagnostic(
+    source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+    severity: _mapPresetSeverity(d.severity),
+    kind: _mapPresetKind(d.kind),
+    message: d.message,
+    presetId: d.presetId,
+    elementId: d.elementId,
+    templateId: d.templateId,
+  );
+}
+
+EnvironmentAuthoringDiagnosticSeverity _mapUsageSeverity(
+  EnvironmentLayerUsageDiagnosticSeverity s,
+) {
+  return switch (s) {
+    EnvironmentLayerUsageDiagnosticSeverity.error =>
+      EnvironmentAuthoringDiagnosticSeverity.error,
+    EnvironmentLayerUsageDiagnosticSeverity.warning =>
+      EnvironmentAuthoringDiagnosticSeverity.warning,
+  };
+}
+
+EnvironmentAuthoringDiagnosticKind _mapUsageKind(
+  EnvironmentLayerUsageDiagnosticKind k,
+) {
+  return switch (k) {
+    EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
+      EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+    EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
+      EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
+    EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
+      EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
+    EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
+      EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
+    EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
+      EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
+    EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
+      EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
+    EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
+      EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
+  };
+}
+
+EnvironmentAuthoringDiagnostic _fromUsage(EnvironmentLayerUsageDiagnostic d) {
+  return EnvironmentAuthoringDiagnostic(
+    source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+    severity: _mapUsageSeverity(d.severity),
+    kind: _mapUsageKind(d.kind),
+    message: d.message,
+    mapId: d.mapId,
+    layerId: d.layerId,
+    areaId: d.areaId,
+    presetId: d.presetId,
+    targetTileLayerId: d.targetTileLayerId,
+    generatedPlacementId: d.generatedPlacementId,
+  );
+}
+
+/// Agrège les diagnostics Environment presets (Lot 6) et usages cartes (Lot 7).
+///
+/// [maps] : uniquement les cartes déjà chargées ; aucune lecture disque ni
+/// chargement depuis [ProjectManifest.maps].
+///
+/// Ordre : diagnostics presets dans l’ordre de [diagnoseProjectEnvironmentPresets],
+/// puis pour chaque entrée de [maps] dans l’ordre, les diagnostics de
+/// [diagnoseMapEnvironmentLayerUsage] pour cette carte.
+EnvironmentAuthoringDiagnosticsReport diagnoseProjectEnvironmentAuthoring(
+  ProjectManifest manifest, {
+  required List<MapData> maps,
+  Set<String> knownTemplateIds = const <String>{},
+}) {
+  final out = <EnvironmentAuthoringDiagnostic>[];
+
+  final presetReport = diagnoseProjectEnvironmentPresets(
+    manifest,
+    knownTemplateIds: knownTemplateIds,
+  );
+  for (final d in presetReport.diagnostics) {
+    out.add(_fromPreset(d));
+  }
+
+  for (final map in maps) {
+    final usageReport = diagnoseMapEnvironmentLayerUsage(manifest, map);
+    for (final d in usageReport.diagnostics) {
+      out.add(_fromUsage(d));
+    }
+  }
+
+  return EnvironmentAuthoringDiagnosticsReport(diagnostics: out);
+}
```

### 16.3 `git diff --no-index /dev/null ... environment_authoring_diagnostics_test.dart`

```diff
diff --git a/packages/map_core/test/environment_authoring_diagnostics_test.dart b/packages/map_core/test/environment_authoring_diagnostics_test.dart
new file mode 100644
index 00000000..16a84f10
--- /dev/null
+++ b/packages/map_core/test/environment_authoring_diagnostics_test.dart
@@ -0,0 +1,706 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+ProjectManifest _manifest({
+  List<EnvironmentPreset> environmentPresets = const [],
+  List<ProjectElementEntry> elements = const [],
+}) {
+  return ProjectManifest(
+    name: 'authoring_diag',
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
+  String templateId = 'tpl',
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
+MapData _map({
+  required String id,
+  List<MapLayer> layers = const [],
+  List<MapPlacedElement> placedElements = const [],
+}) {
+  return MapData(
+    id: id,
+    name: 'Map $id',
+    size: const GridSize(width: 4, height: 3),
+    tilesetId: 'tileset',
+    layers: layers,
+    placedElements: placedElements,
+  );
+}
+
+void main() {
+  group('EnvironmentAuthoringDiagnosticsReport', () {
+    test('vide : hasDiagnostics / erreurs / warnings', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(diagnostics: []);
+      expect(r.hasDiagnostics, isFalse);
+      expect(r.hasErrors, isFalse);
+      expect(r.hasWarnings, isFalse);
+      expect(r.diagnosticCount, 0);
+      expect(r.summary.totalCount, 0);
+    });
+
+    test('copie défensive et liste immuable', () {
+      final raw = <EnvironmentAuthoringDiagnostic>[
+        EnvironmentAuthoringDiagnostic(
+          source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+          severity: EnvironmentAuthoringDiagnosticSeverity.error,
+          kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+          message: 'm',
+          mapId: 'x',
+          layerId: 'l',
+        ),
+      ];
+      final r = EnvironmentAuthoringDiagnosticsReport(diagnostics: raw);
+      expect(() => r.diagnostics.add(raw.first), throwsUnsupportedError);
+      raw.clear();
+      expect(r.diagnosticCount, 1);
+    });
+
+    test('diagnosticCount / errorCount / warningCount', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+            message: 'e',
+            presetId: 'p',
+          ),
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
+            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
+            message: 'w',
+            mapId: 'm',
+            layerId: 'l',
+            areaId: 'a',
+          ),
+        ],
+      );
+      expect(r.diagnosticCount, 2);
+      expect(r.errorCount, 1);
+      expect(r.warningCount, 1);
+    });
+
+    test('diagnosticsForSource', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
+            message: 'a',
+            presetId: 'p1',
+          ),
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+            message: 'b',
+            mapId: 'm',
+            layerId: 'l',
+            presetId: 'p2',
+          ),
+        ],
+      );
+      expect(
+          r
+              .diagnosticsForSource(
+                  EnvironmentAuthoringDiagnosticSource.presetManifest)
+              .length,
+          1);
+      expect(
+          r
+              .diagnosticsForSource(
+                  EnvironmentAuthoringDiagnosticSource.layerUsage)
+              .length,
+          1);
+      expect(
+        () => r
+            .diagnosticsForSource(
+                EnvironmentAuthoringDiagnosticSource.presetManifest)
+            .add(
+              r.diagnostics.first,
+            ),
+        throwsUnsupportedError,
+      );
+    });
+
+    test('diagnosticsForKind retourne liste immuable', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+            message: 'x',
+            presetId: 'dup',
+          ),
+        ],
+      );
+      final list = r.diagnosticsForKind(
+          EnvironmentAuthoringDiagnosticKind.duplicatePresetId);
+      expect(list.length, 1);
+      expect(() => list.add(r.diagnostics.first), throwsUnsupportedError);
+    });
+
+    test('diagnosticsForMap trim et inconnu', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
+            message: 'msg',
+            mapId: 'map_a',
+            layerId: 'env',
+            targetTileLayerId: 'x',
+          ),
+        ],
+      );
+      expect(r.diagnosticsForMap('  map_a  ').length, 1);
+      expect(r.diagnosticsForMap(''), isEmpty);
+      expect(r.diagnosticsForMap('   '), isEmpty);
+      expect(r.diagnosticsForMap('missing'), isEmpty);
+      expect(() => r.diagnosticsForMap('map_a').add(r.diagnostics.first),
+          throwsUnsupportedError);
+    });
+
+    test('diagnosticsForLayer trim et inconnu', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
+            kind: EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
+            message: 'm',
+            mapId: 'm1',
+            layerId: 'env_layer',
+          ),
+        ],
+      );
+      expect(r.diagnosticsForLayer(' env_layer ').length, 1);
+      expect(r.diagnosticsForLayer(''), isEmpty);
+      expect(r.diagnosticsForLayer('nope'), isEmpty);
+    });
+
+    test('diagnosticsForArea trim et inconnu', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
+            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
+            message: 'e',
+            mapId: 'm',
+            layerId: 'l',
+            areaId: 'forest',
+          ),
+        ],
+      );
+      expect(r.diagnosticsForArea(' forest ').length, 1);
+      expect(r.diagnosticsForArea(''), isEmpty);
+      expect(r.diagnosticsForArea('other'), isEmpty);
+    });
+
+    test('diagnosticsForPreset trim et inconnu', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
+            message: 'msg',
+            presetId: 'preset_x',
+          ),
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+            message: 'usage',
+            mapId: 'm',
+            layerId: 'l',
+            areaId: 'a',
+            presetId: 'preset_x',
+          ),
+        ],
+      );
+      expect(r.diagnosticsForPreset(' preset_x ').length, 2);
+      expect(r.diagnosticsForPreset(''), isEmpty);
+      expect(r.diagnosticsForPreset('absent'), isEmpty);
+    });
+
+    test('égalité de valeur du rapport', () {
+      final a = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+            message: 'm',
+            presetId: 'p',
+          ),
+        ],
+      );
+      final b = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+            message: 'm',
+            presetId: 'p',
+          ),
+        ],
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+  });
+
+  group('EnvironmentAuthoringDiagnosticsSummary', () {
+    test('vide : compteurs à 0', () {
+      const s = EnvironmentAuthoringDiagnosticsSummary(
+        totalCount: 0,
+        errorCount: 0,
+        warningCount: 0,
+        presetManifestCount: 0,
+        layerUsageCount: 0,
+        mapsWithDiagnosticsCount: 0,
+        presetsWithDiagnosticsCount: 0,
+      );
+      expect(s.hasDiagnostics, isFalse);
+      expect(s.hasErrors, isFalse);
+      expect(s.hasWarnings, isFalse);
+    });
+
+    test('hasDiagnostics / hasErrors / hasWarnings', () {
+      const s = EnvironmentAuthoringDiagnosticsSummary(
+        totalCount: 2,
+        errorCount: 1,
+        warningCount: 1,
+        presetManifestCount: 1,
+        layerUsageCount: 1,
+        mapsWithDiagnosticsCount: 1,
+        presetsWithDiagnosticsCount: 1,
+      );
+      expect(s.hasDiagnostics, isTrue);
+      expect(s.hasErrors, isTrue);
+      expect(s.hasWarnings, isTrue);
+    });
+
+    test('compteurs agrégés depuis le rapport', () {
+      final r = EnvironmentAuthoringDiagnosticsReport(
+        diagnostics: [
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.presetManifest,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
+            message: 'm1',
+            presetId: 'same_preset',
+            elementId: 'missing_elm',
+          ),
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+            message: 'm2',
+            mapId: 'map_1',
+            layerId: 'env',
+            areaId: 'a1',
+            presetId: 'same_preset',
+          ),
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.error,
+            kind: EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+            message: 'm3',
+            mapId: 'map_1',
+            layerId: 'env',
+            areaId: 'a2',
+            presetId: 'same_preset',
+          ),
+          EnvironmentAuthoringDiagnostic(
+            source: EnvironmentAuthoringDiagnosticSource.layerUsage,
+            severity: EnvironmentAuthoringDiagnosticSeverity.warning,
+            kind: EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
+            message: 'm4',
+            mapId: 'map_2',
+            layerId: 'env',
+            areaId: 'a3',
+          ),
+        ],
+      );
+      final s = r.summary;
+      expect(s.totalCount, 4);
+      expect(s.errorCount, 3);
+      expect(s.warningCount, 1);
+      expect(s.presetManifestCount, 1);
+      expect(s.layerUsageCount, 3);
+      expect(s.mapsWithDiagnosticsCount, 2);
+      expect(s.presetsWithDiagnosticsCount, 1);
+    });
+  });
+
+  group('mapping preset diagnostic', () {
+    test('missingPaletteElement conservé', () {
+      final m = _manifest(
+        environmentPresets: [
+          _preset(
+            id: 'p1',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'ghost_elm', weight: 1),
+            ],
+          ),
+        ],
+        elements: const [],
+      );
+      final r = diagnoseProjectEnvironmentAuthoring(m, maps: const []);
+      expect(r.diagnosticCount, 1);
+      final d = r.diagnostics.single;
+      expect(d.source, EnvironmentAuthoringDiagnosticSource.presetManifest);
+      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.error);
+      expect(d.kind, EnvironmentAuthoringDiagnosticKind.missingPaletteElement);
+      expect(d.presetId, 'p1');
+      expect(d.elementId, 'ghost_elm');
+      expect(d.message, contains('p1'));
+      expect(d.mapId, isNull);
+      expect(d.layerId, isNull);
+    });
+  });
+
+  group('mapping usage diagnostic', () {
+    test('missingAreaPreset conservé', () {
+      final m = _manifest(
+        environmentPresets: [
+          _preset(id: 'ok_preset'),
+        ],
+      );
+      final map = _map(
+        id: 'terrain_map',
+        layers: [
+          _decorLayer(),
+          _envLayer(
+            id: 'env1',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [
+                _area(id: 'zone_a', presetId: 'nope'),
+              ],
+            ),
+          ),
+        ],
+      );
+      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
+      final d = r
+          .diagnosticsForKind(
+              EnvironmentAuthoringDiagnosticKind.missingAreaPreset)
+          .single;
+      expect(d.source, EnvironmentAuthoringDiagnosticSource.layerUsage);
+      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.error);
+      expect(d.mapId, 'terrain_map');
+      expect(d.layerId, 'env1');
+      expect(d.areaId, 'zone_a');
+      expect(d.presetId, 'nope');
+      expect(d.message, contains('zone_a'));
+    });
+  });
+
+  group('ordre stable', () {
+    test('preset puis maps dans l’ordre fourni, ordre interne usage inchangé',
+        () {
+      final m = _manifest(
+        environmentPresets: [
+          _preset(id: 'dup'),
+          _preset(id: 'dup'),
+        ],
+        elements: [_element(id: 'elm_ok')],
+      );
+
+      final mapA = _map(
+        id: 'first_map',
+        layers: [
+          _decorLayer(),
+          _envLayer(
+            id: 'e',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [
+                _area(id: 'a1', presetId: 'dup', mask: _mask(2, 2)),
+              ],
+            ),
+          ),
+        ],
+      );
+
+      final mapB = _map(
+        id: 'second_map',
+        layers: [
+          _decorLayer(),
+          _envLayer(
+            id: 'e2',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'missing_decor',
+              areas: [
+                _area(id: 'b1', presetId: 'dup'),
+              ],
+            ),
+          ),
+        ],
+      );
+
+      final aggregated =
+          diagnoseProjectEnvironmentAuthoring(m, maps: [mapA, mapB]);
+      final presetOnly = diagnoseProjectEnvironmentPresets(m);
+      final usageA = diagnoseMapEnvironmentLayerUsage(m, mapA);
+      final usageB = diagnoseMapEnvironmentLayerUsage(m, mapB);
+
+      final kinds = aggregated.diagnostics.map((d) => d.kind).toList();
+      final expectedKinds = <EnvironmentAuthoringDiagnosticKind>[
+        ...presetOnly.diagnostics.map((d) => switch (d.kind) {
+              EnvironmentPresetDiagnosticKind.duplicatePresetId =>
+                EnvironmentAuthoringDiagnosticKind.duplicatePresetId,
+              EnvironmentPresetDiagnosticKind.missingPaletteElement =>
+                EnvironmentAuthoringDiagnosticKind.missingPaletteElement,
+              EnvironmentPresetDiagnosticKind.unknownTemplateId =>
+                EnvironmentAuthoringDiagnosticKind.unknownTemplateId,
+              EnvironmentPresetDiagnosticKind.forcedCollisionWithoutProfile =>
+                EnvironmentAuthoringDiagnosticKind
+                    .forcedCollisionWithoutProfile,
+            }),
+        ...usageA.diagnostics.map((d) => switch (d.kind) {
+              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
+                EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+              EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
+                EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
+              EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
+                EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
+              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
+                EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
+              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
+                EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
+              EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
+                EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
+              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
+                EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
+            }),
+        ...usageB.diagnostics.map((d) => switch (d.kind) {
+              EnvironmentLayerUsageDiagnosticKind.missingAreaPreset =>
+                EnvironmentAuthoringDiagnosticKind.missingAreaPreset,
+              EnvironmentLayerUsageDiagnosticKind.missingTargetTileLayerId =>
+                EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId,
+              EnvironmentLayerUsageDiagnosticKind.unknownTargetTileLayer =>
+                EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer,
+              EnvironmentLayerUsageDiagnosticKind.targetLayerIsNotTileLayer =>
+                EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer,
+              EnvironmentLayerUsageDiagnosticKind.areaMaskSizeMismatch =>
+                EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch,
+              EnvironmentLayerUsageDiagnosticKind.emptyAreaMask =>
+                EnvironmentAuthoringDiagnosticKind.emptyAreaMask,
+              EnvironmentLayerUsageDiagnosticKind.missingGeneratedPlacement =>
+                EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement,
+            }),
+      ];
+      expect(kinds, expectedKinds);
+    });
+  });
+
+  group('diagnoseProjectEnvironmentAuthoring', () {
+    test('maps vide : seulement diagnostics preset', () {
+      final m = _manifest(
+        environmentPresets: [
+          _preset(
+            id: 'p',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'missing', weight: 1),
+            ],
+          ),
+        ],
+      );
+      final r = diagnoseProjectEnvironmentAuthoring(m, maps: const []);
+      expect(
+          r.diagnostics.every((d) =>
+              d.source == EnvironmentAuthoringDiagnosticSource.presetManifest),
+          isTrue);
+      expect(r.summary.layerUsageCount, 0);
+      expect(r.summary.mapsWithDiagnosticsCount, 0);
+    });
+
+    test('manifest et maps sans problème : rapport vide', () {
+      final m = _manifest(
+        environmentPresets: [_preset(id: 'forest')],
+        elements: [_element(id: 'elm_ok')],
+      );
+      final map = _map(
+        id: 'clean',
+        layers: [
+          _decorLayer(),
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [
+                _area(id: 'a', presetId: 'forest'),
+              ],
+            ),
+          ),
+        ],
+      );
+      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
+      expect(r.hasDiagnostics, isFalse);
+    });
+
+    test('agrège preset + usage', () {
+      final m = _manifest(
+        environmentPresets: [
+          _preset(
+            id: 'p1',
+            palette: [
+              EnvironmentPaletteItem(elementId: 'bad', weight: 1),
+            ],
+          ),
+        ],
+      );
+      final map = _map(
+        id: 'agg',
+        layers: [
+          _decorLayer(),
+          _envLayer(
+            id: 'env',
+            content: EnvironmentLayerContent(
+              targetTileLayerId: 'decor',
+              areas: [
+                _area(id: 'ar', presetId: 'unknown_preset'),
+              ],
+            ),
+          ),
+        ],
+      );
+      final r = diagnoseProjectEnvironmentAuthoring(m, maps: [map]);
+      expect(r.diagnosticCount, 2);
+      expect(
+          r
+              .diagnosticsForSource(
+                  EnvironmentAuthoringDiagnosticSource.presetManifest)
+              .length,
+          1);
+      expect(
+          r
+              .diagnosticsForSource(
+                  EnvironmentAuthoringDiagnosticSource.layerUsage)
+              .length,
+          1);
+    });
+
+    test('knownTemplateIds transmis à diagnoseProjectEnvironmentPresets', () {
+      final m = _manifest(
+        environmentPresets: [_preset(id: 'p', templateId: 'my_tpl')],
+        elements: [_element(id: 'elm_ok')],
+      );
+      final withoutKnown =
+          diagnoseProjectEnvironmentAuthoring(m, maps: const []);
+      expect(
+        withoutKnown.diagnosticsForKind(
+            EnvironmentAuthoringDiagnosticKind.unknownTemplateId),
+        isEmpty,
+      );
+
+      final withKnown = diagnoseProjectEnvironmentAuthoring(
+        m,
+        maps: const [],
+        knownTemplateIds: {'other'},
+      );
+      expect(
+        withKnown
+            .diagnosticsForKind(
+                EnvironmentAuthoringDiagnosticKind.unknownTemplateId)
+            .length,
+        1,
+      );
+      final d = withKnown.diagnostics.single;
+      expect(d.templateId, 'my_tpl');
+      expect(d.severity, EnvironmentAuthoringDiagnosticSeverity.warning);
+    });
+  });
+}
```

## 17. Auto-review

**Points solides** : agrégation triviale sans dupliquer la logique métier ; ordre et mapping testés ; `knownTemplateIds` correctement relayé.

**Points discutables** : `EnvironmentAuthoringDiagnosticsReport.==` ignore le champ `summary` (dérivé des diagnostics — cohérent mais à noter). Les diagnostics preset n'ont pas de `mapId` : `mapsWithDiagnosticsCount` ne les compte pas (intention prompt : distincts **non null**).

**Corrections après auto-review** : ajout du test `maps vide` vérifiant `mapsWithDiagnosticsCount == 0` ; validation de l'ordre par concaténation des kinds sources.

**Risques restants** : l'UI devra charger explicitement les `MapData` à passer ; oublier une carte = diagnostic manquant (documenté).

**Regard critique sur le prompt** :

- Fusion en enum unique vs deux familles : l'enum unique sert l'UI unifiée tout en conservant `source` pour le filtrage — bon compromis.
- Summary orienté UI : reste des entiers purs, acceptable dans `map_core` pour un presenter.
- `mapsWithDiagnosticsCount` ignore les entrées sans `mapId` : oui, les presets seuls ne gonflent pas ce compteur — cohérent avec la sémantique « cartes touchées ».
- `presetsWithDiagnosticsCount` inclut les `presetId` d'usage : oui, exigence Lot 8 (ex. `missingAreaPreset`).
- Périmètre respecté : pas de toucher à `ProjectManifest` / `MapLayer` / UI / générateur.

## 18. Verdict

Statut du lot :

- [x] Validé

Résumé :

```
Lot Environment-8 livré : agrégateur diagnoseProjectEnvironmentAuthoring + rapport + 20 tests ; dart analyze OK ; régressions Environment 197 tests OK ; suite map_core +1351 OK ; aucun build_runner ; aucun commit.
```

Prochain lot recommandé :

```
Environment-9 — Environment Studio Workspace Shell V0
```

---
## Evidence Pack — confirmations obligatoires

- **Aucun `ProjectManifest` modifié** : confirmé (fichier modèle non présent dans le diff Lot 8).
- **Aucun `MapLayer` modifié** : confirmé.
- **Aucune UI Environment Studio** : confirmé.
- **Aucun générateur** : confirmé.
- **Aucun `build_runner` lancé** : confirmé.
- **Aucun fichier generated modifié** : confirmé.
- **Aucun commit / git add / git push** : confirmé (politique Lot respectée).
