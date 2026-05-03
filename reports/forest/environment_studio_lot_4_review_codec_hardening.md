# Environment Studio Lot 4-review — Strict Audit and Codec Hardening V0

## 1. Résumé exécutif

Review strict du Lot Environment-4 portant sur l’intégration **MapLayer.environment**, le **codec JSON** et les chemins **resize** / **validation**. Le codec `environment_layer_content_json_codec.dart` a été **durci** : **`targetTileLayerId`** présent mais vide / whitespace → **`FormatException`** (plus de silent **null**) ; entiers JSON (**seed**, dimensions masque, **minSpacingCells**) → **`int` Dart uniquement** ; **`generatedPlacementIds`** avec types, espaces et doublons contrôlés ; erreurs **`EnvironmentLayerContent`** (ex. **areas** même **id**) → **`FormatException`**. Tests ajoutés (codec strict, resize **EnvironmentLayer**, JSON MapLayer). **Aucun** `build_runner`, **aucune** modification manifest/UI/générateur. Suite **`map_core`** : **`1253`** tests verts ; **`dart analyze`** sans problème.

## 2. Périmètre du review

- Audit factuel des livrables Lot 4 (liste §3).
- Durcissement **codec** + tests associés.
- Vérification **resizeMapData**, **MapValidator**, downstream neutre, **generated** (inchangés par ce review).
- Hors scope : **Environment-5**, **ProjectManifest**, UI Studio, générateur.

## 3. Audit initial du Lot 4

**Statut git (début review)** — arbre non commit, fichiers Lot 4 présents (dont codec et tests **non trackés** `??`).

**Fichiers inspectés (lecture / grep)** :

| Chemin | Verdict |
|--------|---------|
| `packages/map_core/lib/map_core.dart` | Export codec OK |
| `packages/map_core/lib/src/models/enums.dart` | `MapLayerKind.environment` OK |
| `packages/map_core/lib/src/models/environment.dart` | `emptyContent` OK |
| `packages/map_core/lib/src/models/map_layer.dart` | Variante `environment` OK |
| `packages/map_core/lib/src/models/map_layer.freezed.dart` / `.g.dart` | Union **`environment`**, **`content` null → emptyContent** OK |
| `packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart` | **Durci dans ce review** |
| `packages/map_core/lib/src/operations/map_layers.dart` | **`addMapLayer`**, **`setEnvironmentLayerContent`**, **`_copyLayer`** OK |
| `packages/map_core/lib/src/operations/map_resize.dart` | Branche **environment** OK |
| `packages/map_core/lib/src/validation/validators.dart` | Règles cible tuile + masque OK |
| Tests Lot 4 codec / intégration | **Étendus** ce review |
| `packages/map_editor/...` (3 fichiers) | Neutre — inchangé ce review |
| `packages/map_runtime/.../runtime_manifest_tilesets.dart` | **`environment` no-op** — inchangé ce review |

## 4. Switchs et intégration MapLayer inspectés

**Recherches effectuées** (`grep` sur `packages/map_core`, `map_editor`, `map_runtime`, `map_gameplay`) :

| Motif | Constats |
|-------|-----------|
| `MapLayerKind` | Définition **enum** ; **`addMapLayer`** exhaustif ; **`layer_use_cases`** préfixe **`l_environment`** |
| `layer.when` | **`runtime_manifest_tilesets`** (2×) : **`environment`** no-op ✓ ; **`map_gameplay`** **`whenOrNull(collision:)`** uniquement — **EnvironmentLayer** ignoré ✓ |
| `layer.map` | **`map_layers`** **`_copyLayer`** ✓ ; **`map_resize`** ✓ ; **`layers_panel`** ✓ |
| `MapLayer.environment` | Tests + sérialisation ✓ |
| `is EnvironmentLayer` | Usages tests / casts inspector — OK |

**Correction nécessaire lors du review** : uniquement le **codec** (strictesse JSON). Aucun switch downstream supplémentaire requis.

## 5. Audit du codec JSON

**Avant review**

- **`targetTileLayerId`** : chaîne trimée vide → **`null`** (contournait la règle métier « non-null ⇒ non vide »).
- **`_requireInt`** : **`num`** puis **`toInt()`** → risque **1.9 → 1**.
- **`generatedPlacementIds`** : **`as String`** → **`TypeError`** possible ; pas de garde doublon / vide avant **`EnvironmentArea`**.
- **`EnvironmentLayerContent`** doublons **areas** : **`ArgumentError`** depuis le modèle, pas toujours **`FormatException`** au périmètre decode.

**Après review**

- **`targetTileLayerId`** : **`null`** (absent ou valeur JSON **null**) → **`null`** ; chaîne → trim ; si vide après trim → **`FormatException`** ; non-string → **`FormatException`**.
- **`_requireIntStrict`** : uniquement **`v is int`** pour **seed**, **width**, **height**, **minSpacingCells**.
- **Unit doubles** (`density`, …) : **`_requireDoubleUnit`** — **`double`** ou **`int`** JSON uniquement (pas de **`num`** générique ambigu pour les entiers).
- **`generatedPlacementIds`** : liste typée, **`trim`**, non vide, pas de doublon → **`FormatException`** explicites.
- **`decodeEnvironmentLayerContent`** : **`try/catch ArgumentError`** → **`FormatException`** pour **`EnvironmentLayerContent`**.

## 6. Corrections appliquées

Fichier unique modifié côté production :  
**`packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart`** (réécriture comportementale comme ci-dessus).

Aucune modification **`environment.dart`**, **`map_layer.dart`**, **`map_layers.dart`**, **`map_resize.dart`**, **`validators.dart`**, downstream, ou **generated** dans ce review.

## 7. Tests ajoutés ou renforcés

**`environment_layer_content_json_codec_test.dart`**

- **`targetTileLayerId`** null explicite ; whitespace / chaîne vide → **`FormatException`**.
- Groupe **codec strict int** : **seed** double, **mask** width/height double, **minSpacingCells** double, **density** hors plage.
- **generatedPlacementIds** : non-string, vide, doublon.
- **areas** : élément non-map ; **duplicate area id**.

**`environment_layer_map_layer_integration_test.dart`**

- **fromJson** **`content: null`** ; **properties** roundtrip.
- **`resizeMapData`** : agrandissement (préservation coin + nouvelles cellules **false**) ; rétrécissement (troncature — cas coin bas-droit perdu).

## 8. Vérification resizeMapData

Comportement Lot 4 validé par tests : **`targetTileLayerId`**, **seed**, **paramsOverride**, **generatedPlacementIds**, **id/name/presetId** conservés ; masque redimensionné avec **`_resizeFlattened`** (même logique que autres layers).

## 9. Vérification MapValidator

Couverture existante + non-régression : content vide, cible tuile, rejets (inconnu, non-tile, self, masque taille). Pas de validation **presetId** manifest ni **placedElements** — conforme périmètre Lot 4.

## 10. Vérification downstream neutre

**`layer_use_cases`**, **`layers_panel`**, **`map_inspector_panel`**, **`runtime_manifest_tilesets`** : aucun ajout UI Studio / Generate ; fichiers non modifiés par ce review ; **`flutter analyze`** vert.

## 11. Vérification generated files

**`map_layer.freezed.dart`** / **`map_layer.g.dart`** : non modifiés dans ce review ; **`build_runner` non relancé** (aucun changement sur **`map_layer.dart`** ou annotations associées).

## 12. Fichiers modifiés par ce review

| Fichier | Rôle |
|---------|------|
| `packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart` | Durcissement codec |
| `packages/map_core/test/environment_layer_content_json_codec_test.dart` | Tests stricts |
| `packages/map_core/test/environment_layer_map_layer_integration_test.dart` | Resize + JSON edge cases |
| `reports/forest/environment_studio_lot_4_review_codec_hardening.md` | Ce rapport |

## 13. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all

cd packages/map_core
dart format lib/src/operations/environment_layer_content_json_codec.dart \
  test/environment_layer_content_json_codec_test.dart \
  test/environment_layer_map_layer_integration_test.dart

dart analyze lib/src/operations/environment_layer_content_json_codec.dart \
  test/environment_layer_content_json_codec_test.dart \
  test/environment_layer_map_layer_integration_test.dart

dart analyze

dart test test/environment_layer_content_json_codec_test.dart --reporter expanded
dart test test/environment_layer_map_layer_integration_test.dart --reporter expanded
dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart --reporter expanded
dart test

cd ../map_editor
flutter analyze lib/src/application/use_cases/layer_use_cases.dart \
  lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/map_inspector_panel.dart

cd ../map_runtime
flutter analyze lib/src/application/runtime_manifest_tilesets.dart
```

## 14. Résultats des commandes

| Commande | Résultat |
|----------|----------|
| `dart analyze` (ciblés puis package **map_core**) | **`No issues found!`** |
| `dart test` codec seul | Voir bloc verbatim §14.1 ci-dessous |
| `dart test` intégration seul | Voir bloc verbatim §14.2 ci-dessous |
| `dart test` Env-2 + Env-3 | Voir bloc verbatim §14.3 ci-dessous |
| `dart test` suite **map_core** (`--reporter compact`) | Ligne finale du flux : **`00:02 +1253: All tests passed!`** (répétée sans séquences ANSI dans §14.4) |
| `flutter analyze` **map_editor** / **map_runtime** | **`No issues found!`** |

### 14.1 `dart test test/environment_layer_content_json_codec_test.dart --reporter expanded` (sortie intégrale)

```
00:00 +0: loading test/environment_layer_content_json_codec_test.dart
00:00 +0: EnvironmentLayerContent JSON codec decode null => emptyContent
00:00 +1: EnvironmentLayerContent JSON codec decode map minimal => content vide
00:00 +2: EnvironmentLayerContent JSON codec decode targetTileLayerId trimé
00:00 +3: EnvironmentLayerContent JSON codec decode targetTileLayerId null explicite => null
00:00 +4: EnvironmentLayerContent JSON codec decode targetTileLayerId whitespace => FormatException
00:00 +5: EnvironmentLayerContent JSON codec decode areas absent/null => []
00:00 +6: EnvironmentLayerContent JSON codec decode area complète + paramsOverride + generatedPlacementIds
00:00 +7: EnvironmentLayerContent JSON codec encode content vide
00:00 +8: EnvironmentLayerContent JSON codec encode content avec targetTileLayerId
00:00 +9: EnvironmentLayerContent JSON codec roundtrip content complet
00:00 +10: EnvironmentLayerContent JSON codec json non-map rejeté
00:00 +11: EnvironmentLayerContent JSON codec areas non-list rejeté
00:00 +12: EnvironmentLayerContent JSON codec mask invalide rejeté
00:00 +13: EnvironmentLayerContent JSON codec codec strict int decode seed double => FormatException
00:00 +14: EnvironmentLayerContent JSON codec codec strict int decode mask width double => FormatException
00:00 +15: EnvironmentLayerContent JSON codec codec strict int decode mask height double => FormatException
00:00 +16: EnvironmentLayerContent JSON codec codec strict int decode minSpacingCells double => FormatException
00:00 +17: EnvironmentLayerContent JSON codec codec strict int decode paramsOverride density hors plage => FormatException
00:00 +18: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds avec int => FormatException
00:00 +19: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds string vide => FormatException
00:00 +20: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds doublon => FormatException
00:00 +21: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict areas item non-map => FormatException
00:00 +22: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict areas duplicate area id => FormatException
00:00 +23: All tests passed!
```

### 14.2 `dart test test/environment_layer_map_layer_integration_test.dart --reporter expanded` (sortie intégrale)

```
00:00 +0: loading test/environment_layer_map_layer_integration_test.dart
00:00 +0: MapLayer.environment valeurs par défaut et content vide
00:00 +1: MapLayer.environment toJson/fromJson roundtrip
00:00 +2: MapLayer.environment fromJson sans content => content vide
00:00 +3: MapLayer.environment copyWith préserve content et properties si non passés
00:00 +4: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide
00:00 +5: addMapLayer MapLayerKind.environment insertIndex comme autres layers non-path
00:00 +6: setEnvironmentLayerContent remplace content et conserve méta
00:00 +7: setEnvironmentLayerContent refuse layerId vide
00:00 +8: setEnvironmentLayerContent refuse layer inconnu
00:00 +9: setEnvironmentLayerContent refuse layer non EnvironmentLayer
00:00 +10: setEnvironmentLayerContent ne modifie pas placedElements
00:00 +11: MapValidator EnvironmentLayer map valide avec EnvironmentLayer vide
00:00 +12: MapValidator EnvironmentLayer targetTileLayerId valide si TileLayer existe
00:00 +13: MapValidator EnvironmentLayer invalide si targetTileLayerId inconnu
00:00 +14: MapValidator EnvironmentLayer invalide si targetTileLayerId pointe vers le layer environment lui-même
00:00 +15: MapValidator EnvironmentLayer invalide si target pointe vers non-TileLayer
00:00 +16: MapValidator EnvironmentLayer invalide si masque ne correspond pas à la taille carte
00:00 +17: MapLayer.environment JSON edge cases fromJson avec content null => emptyContent
00:00 +18: MapLayer.environment JSON edge cases properties roundtrip
00:00 +19: resizeMapData EnvironmentLayer agrandit la carte : masque redimensionné, métadonnées conservées
00:00 +20: resizeMapData EnvironmentLayer rétrécit la carte : cellules hors carte supprimées
00:00 +21: All tests passed!
```

### 14.3 `dart test test/environment_core_models_test.dart test/environment_layer_content_test.dart --reporter expanded` (sortie intégrale)

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
00:00 +11: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts valid areas and preserves order
00:00 +12: test/environment_core_models_test.dart: EnvironmentPaletteItem tags are immutable
00:00 +13: test/environment_layer_content_test.dart: EnvironmentLayerContent construction empty factory
00:00 +14: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty tag
00:00 +15: test/environment_layer_content_test.dart: EnvironmentLayerContent defensive copy and immutability copies areas list defensively
00:00 +16: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +17: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +18: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality
00:00 +19: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers hasAreas false when empty
00:00 +20: test/environment_core_models_test.dart: EnvironmentGenerationParams accepts valid params
00:00 +21: test/environment_core_models_test.dart: EnvironmentGenerationParams accepts valid params
00:00 +22: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaCount
00:00 +23: test/environment_core_models_test.dart: EnvironmentGenerationParams rejects density out of range
00:00 +24: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea known id
00:00 +25: test/environment_core_models_test.dart: EnvironmentGenerationParams rejects variation out of range
00:00 +26: test/environment_core_models_test.dart: EnvironmentGenerationParams rejects variation out of range
00:00 +27: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for unknown
00:00 +28: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for unknown
00:00 +29: test/environment_core_models_test.dart: EnvironmentGenerationParams rejects negative minSpacingCells
00:00 +30: test/environment_core_models_test.dart: EnvironmentGenerationParams rejects negative minSpacingCells
00:00 +31: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById returns area
00:00 +32: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById returns area
00:00 +33: test/environment_core_models_test.dart: EnvironmentGenerationParams value equality
00:00 +34: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById trims argument
00:00 +35: test/environment_core_models_test.dart: EnvironmentAreaMask accepts valid mask
00:00 +36: test/environment_core_models_test.dart: EnvironmentAreaMask accepts valid mask
00:00 +37: test/environment_core_models_test.dart: EnvironmentAreaMask accepts valid mask
00:00 +38: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements false when none
00:00 +39: test/environment_core_models_test.dart: EnvironmentAreaMask rejects width <= 0
00:00 +40: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements true when any area has ids
00:00 +41: test/environment_core_models_test.dart: EnvironmentAreaMask rejects height <= 0
00:00 +42: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order
00:00 +43: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order
00:00 +44: test/environment_core_models_test.dart: EnvironmentAreaMask cells copied defensively
00:00 +45: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds returns unmodifiable list
00:00 +46: test/environment_core_models_test.dart: EnvironmentAreaMask cells list is unmodifiable
00:00 +47: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal
00:00 +48: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal
00:00 +49: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal
00:00 +50: test/environment_core_models_test.dart: EnvironmentAreaMask contains
00:00 +51: test/environment_layer_content_test.dart: EnvironmentLayerContent equality different targetTileLayerId not equal
00:00 +52: test/environment_core_models_test.dart: EnvironmentAreaMask isActiveAt returns false out of bounds without throwing
00:00 +53: test/environment_layer_content_test.dart: EnvironmentLayerContent equality different areas order not equal
00:00 +54: test/environment_core_models_test.dart: EnvironmentAreaMask equality order-sensitive on cells
00:00 +55: test/environment_core_models_test.dart: EnvironmentArea accepts valid area
00:00 +56: test/environment_core_models_test.dart: EnvironmentArea rejects empty id
00:00 +57: test/environment_core_models_test.dart: EnvironmentArea rejects empty name
00:00 +58: test/environment_core_models_test.dart: EnvironmentArea rejects empty presetId
00:00 +59: test/environment_core_models_test.dart: EnvironmentArea accepts negative seed
00:00 +60: test/environment_core_models_test.dart: EnvironmentArea paramsOverride null and non-null
00:00 +61: test/environment_core_models_test.dart: EnvironmentArea generatedPlacementIds defensive copy and immutable
00:00 +62: test/environment_core_models_test.dart: EnvironmentArea rejects empty placement id
00:00 +63: test/environment_core_models_test.dart: EnvironmentArea rejects duplicate placement ids
00:00 +64: test/environment_core_models_test.dart: EnvironmentArea hasGeneratedPlacements
00:00 +65: test/environment_core_models_test.dart: EnvironmentArea value equality
00:00 +66: test/environment_core_models_test.dart: EnvironmentPreset accepts valid preset
00:00 +67: test/environment_core_models_test.dart: EnvironmentPreset rejects empty id name templateId
00:00 +68: test/environment_core_models_test.dart: EnvironmentPreset rejects empty palette
00:00 +69: test/environment_core_models_test.dart: EnvironmentPreset palette defensive copy and immutable
00:00 +70: test/environment_core_models_test.dart: EnvironmentPreset rejects duplicate elementId in palette
00:00 +71: test/environment_core_models_test.dart: EnvironmentPreset categoryId null ok
00:00 +72: test/environment_core_models_test.dart: EnvironmentPreset categoryId whitespace rejected
00:00 +73: test/environment_core_models_test.dart: EnvironmentPreset value equality
00:00 +74: test/environment_core_models_test.dart: public export map_core types reachable from package:map_core/map_core.dart
00:00 +75: All tests passed!
```

### 14.4 `dart test` (suite complète **map_core**, `--reporter compact`)

Le rapporteur **`compact`** émet une ligne très longue de progression ; la **dernière assertion exploitable** est :

```text
00:02 +1253: All tests passed!
```

(L’horodatage **`00:02`** peut varier selon la machine ; le compteur **`+1253`** et le message **`All tests passed!`** sont la preuve de succès.)

## 15. Git status initial et final

**Initial** : même base que fin Lot 4 (changements Lot 4 non commit ; codec/tests **`??`**).

**Final** (`git status --short --untracked-files=all`) :

```
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/enums.dart
 M packages/map_core/lib/src/models/environment.dart
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/operations/map_layers.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
?? packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart
?? packages/map_core/test/environment_layer_content_json_codec_test.dart
?? packages/map_core/test/environment_layer_map_layer_integration_test.dart
?? reports/forest/environment_studio_lot_4_environment_layer_map_layer_integration.md
?? reports/forest/environment_studio_lot_4_review_codec_hardening.md
```

Les fichiers **`??`** du codec/tests reflètent un dépôt sans **`git add`** ; le review met à jour le même contenu sur disque.

## 16. Contenu complet des fichiers créés ou modifiés par ce review

### 16.1 Codec (`environment_layer_content_json_codec.dart`)

```dart
import '../models/environment.dart';

/// Codec JSON pour [EnvironmentLayerContent] et sous-structures (Lot Environment-4).
/// Les [EnvironmentPreset] restent hors périmètre manifest / carte.
///
/// Lot Environment-4-review : JSON strict (`targetTileLayerId` non vide si présent,
/// entiers JSON typés `int` uniquement pour les champs entiers, placements typés et uniques).
EnvironmentLayerContent decodeEnvironmentLayerContent(Object? json) {
  if (json == null) {
    return EnvironmentLayerContent.emptyContent;
  }
  if (json is! Map) {
    throw FormatException(
      'EnvironmentLayerContent JSON must be a Map or null, got ${json.runtimeType}',
    );
  }
  final map = Map<String, dynamic>.from(json);

  final rawTarget = map['targetTileLayerId'];
  final String? targetTileLayerId;
  if (rawTarget == null) {
    targetTileLayerId = null;
  } else if (rawTarget is String) {
    final t = rawTarget.trim();
    if (t.isEmpty) {
      throw FormatException(
        'EnvironmentLayerContent targetTileLayerId cannot be empty or whitespace-only when provided',
      );
    }
    targetTileLayerId = t;
  } else {
    throw FormatException(
      'EnvironmentLayerContent targetTileLayerId must be a String or null',
    );
  }

  final rawAreas = map['areas'];
  final List<EnvironmentArea> areas;
  if (rawAreas == null) {
    areas = const [];
  } else if (rawAreas is List) {
    areas = <EnvironmentArea>[];
    for (var i = 0; i < rawAreas.length; i++) {
      final e = rawAreas[i];
      areas.add(
        decodeEnvironmentArea(_requireMap(e, 'areas[$i]')),
      );
    }
  } else {
    throw FormatException(
      'EnvironmentLayerContent areas must be a List or null, got ${rawAreas.runtimeType}',
    );
  }

  try {
    return EnvironmentLayerContent(
      targetTileLayerId: targetTileLayerId,
      areas: areas,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentLayerContent: ${e.message}');
  }
}

/// JSON compatible `json_serializable` / persistance carte.
Map<String, dynamic> encodeEnvironmentLayerContent(
  EnvironmentLayerContent content,
) {
  return <String, dynamic>{
    if (content.targetTileLayerId != null)
      'targetTileLayerId': content.targetTileLayerId,
    'areas': content.areas.map(encodeEnvironmentArea).toList(growable: false),
  };
}

EnvironmentArea decodeEnvironmentArea(Map<String, dynamic> json) {
  try {
    final id = _requireString(json, 'id');
    final name = _requireString(json, 'name');
    final presetId = _requireString(json, 'presetId');
    final mask = decodeEnvironmentAreaMask(
      _requireMap(json['mask'], 'mask'),
    );
    final seed = _requireIntStrict(json, 'seed');

    final rawOverride = json['paramsOverride'];
    final EnvironmentGenerationParams? paramsOverride;
    if (rawOverride == null) {
      paramsOverride = null;
    } else {
      paramsOverride = decodeEnvironmentGenerationParams(
        _requireMap(rawOverride, 'paramsOverride'),
      );
    }

    final rawPlacementIds = json['generatedPlacementIds'];
    final List<String>? generatedPlacementIds =
        _decodeGeneratedPlacementIdsField(rawPlacementIds);

    return EnvironmentArea(
      id: id,
      name: name,
      presetId: presetId,
      mask: mask,
      seed: seed,
      paramsOverride: paramsOverride,
      generatedPlacementIds: generatedPlacementIds,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentArea: ${e.message}');
  }
}

/// `null` ou liste ; IDs trimés, non vides, sans doublon (aligné sur [EnvironmentArea]).
List<String>? _decodeGeneratedPlacementIdsField(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is! List) {
    throw FormatException(
      'generatedPlacementIds must be a List or null, got ${raw.runtimeType}',
    );
  }
  final seen = <String>{};
  final out = <String>[];
  for (var i = 0; i < raw.length; i++) {
    final e = raw[i];
    if (e is! String) {
      throw FormatException(
        'generatedPlacementIds[$i] must be a String, got ${e.runtimeType}',
      );
    }
    final t = e.trim();
    if (t.isEmpty) {
      throw FormatException(
        'generatedPlacementIds[$i] cannot be empty or whitespace-only',
      );
    }
    if (!seen.add(t)) {
      throw FormatException(
        'generatedPlacementIds contains duplicate placement id: $t',
      );
    }
    out.add(t);
  }
  return out;
}

Map<String, dynamic> encodeEnvironmentArea(EnvironmentArea area) {
  return <String, dynamic>{
    'id': area.id,
    'name': area.name,
    'presetId': area.presetId,
    'mask': encodeEnvironmentAreaMask(area.mask),
    'seed': area.seed,
    if (area.paramsOverride != null)
      'paramsOverride': encodeEnvironmentGenerationParams(area.paramsOverride!),
    'generatedPlacementIds': area.generatedPlacementIds.toList(growable: false),
  };
}

EnvironmentAreaMask decodeEnvironmentAreaMask(Map<String, dynamic> json) {
  try {
    final width = _requireIntStrict(json, 'width');
    final height = _requireIntStrict(json, 'height');
    final rawCells = json['cells'];
    if (rawCells is! List) {
      throw FormatException(
        'EnvironmentAreaMask cells must be a List, got ${rawCells.runtimeType}',
      );
    }
    final cells = rawCells.map((e) {
      if (e is! bool) {
        throw FormatException(
          'EnvironmentAreaMask cells must be List<bool>, got element ${e.runtimeType}',
        );
      }
      return e;
    }).toList(growable: false);

    return EnvironmentAreaMask(
      width: width,
      height: height,
      cells: cells,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentAreaMask: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentAreaMask(EnvironmentAreaMask mask) {
  return <String, dynamic>{
    'width': mask.width,
    'height': mask.height,
    'cells': mask.cells.toList(growable: false),
  };
}

EnvironmentGenerationParams decodeEnvironmentGenerationParams(
  Map<String, dynamic> json,
) {
  try {
    return EnvironmentGenerationParams(
      density: _requireDoubleUnit(json, 'density'),
      variation: _requireDoubleUnit(json, 'variation'),
      edgeDensity: _requireDoubleUnit(json, 'edgeDensity'),
      minSpacingCells: _requireIntStrict(json, 'minSpacingCells'),
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'Invalid EnvironmentGenerationParams: ${e.message}',
    );
  }
}

/// Double ou entier JSON pour les paramètres \[0,1\] ; rejette les doubles non entiers
/// ambigus pour les champs qui doivent être entiers (voir [_requireIntStrict]).
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

Map<String, dynamic> encodeEnvironmentGenerationParams(
  EnvironmentGenerationParams params,
) {
  return <String, dynamic>{
    'density': params.density,
    'variation': params.variation,
    'edgeDensity': params.edgeDensity,
    'minSpacingCells': params.minSpacingCells,
  };
}

Map<String, dynamic> _requireMap(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  throw FormatException('$field must be a Map, got ${value.runtimeType}');
}

String _requireString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) {
    return v;
  }
  throw FormatException('Missing or invalid String for key "$key"');
}

/// JSON strict : seuls les littéraux entiers Dart (`int`) sont acceptés — pas de `double`,
/// pour éviter une troncature silencieuse (ex. 1.9 → 1).
int _requireIntStrict(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is int) {
    return v;
  }
  throw FormatException(
    'Missing or invalid strict int for key "$key" (got ${v.runtimeType})',
  );
}
```

### 16.2 `environment_layer_content_json_codec_test.dart` (texte intégral)

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentLayerContent JSON codec', () {
    test('decode null => emptyContent', () {
      final c = decodeEnvironmentLayerContent(null);
      expect(c, EnvironmentLayerContent.emptyContent);
    });

    test('decode map minimal => content vide', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{});
      expect(c.targetTileLayerId, isNull);
      expect(c.areas, isEmpty);
    });

    test('decode targetTileLayerId trimé', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'targetTileLayerId': '  decor  ',
      });
      expect(c.targetTileLayerId, 'decor');
    });

    test('decode targetTileLayerId null explicite => null', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'targetTileLayerId': null,
      });
      expect(c.targetTileLayerId, isNull);
    });

    test('decode targetTileLayerId whitespace => FormatException', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'targetTileLayerId': '   ',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'targetTileLayerId': '',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('decode areas absent/null => []', () {
      final a = decodeEnvironmentLayerContent(
        <String, dynamic>{'targetTileLayerId': 't'},
      );
      final b = decodeEnvironmentLayerContent(
        <String, dynamic>{'targetTileLayerId': 't', 'areas': null},
      );
      expect(a.areas, isEmpty);
      expect(b.areas, isEmpty);
    });

    test('decode area complète + paramsOverride + generatedPlacementIds', () {
      final c = decodeEnvironmentLayerContent(<String, dynamic>{
        'areas': [
          <String, dynamic>{
            'id': 'a1',
            'name': 'Zone A',
            'presetId': 'p1',
            'mask': <String, dynamic>{
              'width': 2,
              'height': 2,
              'cells': <bool>[true, false, true, false],
            },
            'seed': 7,
            'paramsOverride': <String, dynamic>{
              'density': 0.5,
              'variation': 0.5,
              'edgeDensity': 0.5,
              'minSpacingCells': 1,
            },
            'generatedPlacementIds': <String>['x1', 'x2'],
          },
        ],
      });
      expect(c.areas, hasLength(1));
      final a = c.areas.single;
      expect(a.id, 'a1');
      expect(a.presetId, 'p1');
      expect(a.mask.width, 2);
      expect(a.mask.height, 2);
      expect(a.paramsOverride, isNotNull);
      expect(a.generatedPlacementIds, ['x1', 'x2']);
    });

    test('encode content vide', () {
      final m =
          encodeEnvironmentLayerContent(EnvironmentLayerContent.emptyContent);
      expect(m, <String, dynamic>{'areas': <dynamic>[]});
    });

    test('encode content avec targetTileLayerId', () {
      final m = encodeEnvironmentLayerContent(
        EnvironmentLayerContent(
          targetTileLayerId: 'd1',
          areas: null,
        ),
      );
      expect(m['targetTileLayerId'], 'd1');
      expect(m['areas'], isEmpty);
    });

    test('roundtrip content complet', () {
      final original = EnvironmentLayerContent(
        targetTileLayerId: 't1',
        areas: [
          EnvironmentArea(
            id: 'z1',
            name: 'Z',
            presetId: 'preset',
            mask: EnvironmentAreaMask(
              width: 1,
              height: 1,
              cells: [true],
            ),
            seed: 1,
            paramsOverride: EnvironmentGenerationParams(
              density: 0.25,
              variation: 0.5,
              edgeDensity: 0.75,
              minSpacingCells: 0,
            ),
            generatedPlacementIds: ['g1'],
          ),
        ],
      );
      final round = decodeEnvironmentLayerContent(
          encodeEnvironmentLayerContent(original));
      expect(round, original);
    });

    test('json non-map rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(1),
        throwsA(isA<FormatException>()),
      );
    });

    test('areas non-list rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{'areas': 3}),
        throwsA(isA<FormatException>()),
      );
    });

    test('mask invalide rejeté', () {
      expect(
        () => decodeEnvironmentLayerContent(<String, dynamic>{
          'areas': [
            <String, dynamic>{
              'id': 'a',
              'name': 'b',
              'presetId': 'c',
              'mask': <String, dynamic>{
                'width': 1,
                'height': 1,
                'cells': <bool>[true, false],
              },
              'seed': 0,
            },
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    group('codec strict int', () {
      Map<String, dynamic> minimalAreaJson({
        required Object seed,
        Object? maskWidth,
        Object? maskHeight,
      }) =>
          <String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': maskWidth ?? 1,
                  'height': maskHeight ?? 1,
                  'cells': <bool>[true],
                },
                'seed': seed,
              },
            ],
          };

      test('decode seed double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(minimalAreaJson(seed: 1.5)),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode mask width double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(minimalAreaJson(
            seed: 0,
            maskWidth: 1.5,
          )),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode mask height double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(minimalAreaJson(
            seed: 0,
            maskHeight: 1.5,
          )),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode minSpacingCells double => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'paramsOverride': <String, dynamic>{
                  'density': 0.5,
                  'variation': 0.5,
                  'edgeDensity': 0.5,
                  'minSpacingCells': 1.5,
                },
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('decode paramsOverride density hors plage => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'paramsOverride': <String, dynamic>{
                  'density': 2.0,
                  'variation': 0.5,
                  'edgeDensity': 0.5,
                  'minSpacingCells': 0,
                },
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('generatedPlacementIds et areas strict', () {
      test('generatedPlacementIds avec int => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'generatedPlacementIds': <Object>[1],
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('generatedPlacementIds string vide => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'generatedPlacementIds': <String>[''],
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('generatedPlacementIds doublon => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'a',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
                'generatedPlacementIds': <String>['x', 'x'],
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('areas item non-map => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': <Object>[1],
          }),
          throwsA(isA<FormatException>()),
        );
      });

      test('areas duplicate area id => FormatException', () {
        expect(
          () => decodeEnvironmentLayerContent(<String, dynamic>{
            'areas': [
              <String, dynamic>{
                'id': 'dup',
                'name': 'b',
                'presetId': 'c',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[true],
                },
                'seed': 0,
              },
              <String, dynamic>{
                'id': 'dup',
                'name': 'b2',
                'presetId': 'c2',
                'mask': <String, dynamic>{
                  'width': 1,
                  'height': 1,
                  'cells': <bool>[false],
                },
                'seed': 1,
              },
            ],
          }),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}

```

### 16.3 `environment_layer_map_layer_integration_test.dart` (texte intégral)

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

MapData _minimalMap({
  required List<MapLayer> layers,
  List<MapPlacedElement>? placedElements,
}) {
  return MapData(
    id: 'm_test',
    name: 'Test',
    size: const GridSize(width: 10, height: 8),
    tilesetId: 'ts',
    layers: layers,
    placedElements: placedElements ?? const [],
  );
}

EnvironmentArea _areaFor1024({
  required String id,
  String presetId = 'preset_a',
}) {
  final cells = List<bool>.filled(10 * 8, false);
  return EnvironmentArea(
    id: id,
    name: 'n$id',
    presetId: presetId,
    mask: EnvironmentAreaMask(width: 10, height: 8, cells: cells),
    seed: 0,
  );
}

void main() {
  group('MapLayer.environment', () {
    test('valeurs par défaut et content vide', () {
      const layer = MapLayer.environment(id: 'e1', name: 'Env');
      final env = layer as EnvironmentLayer;
      expect(env.isVisible, isTrue);
      expect(env.opacity, 1.0);
      expect(env.content, EnvironmentLayerContent.emptyContent);
      expect(env.properties, isEmpty);
    });

    test('toJson/fromJson roundtrip', () {
      final layer = MapLayer.environment(
        id: 'env1',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles_main',
          areas: [_areaFor1024(id: 'z1')],
        ),
        properties: {'k': 'v'},
      );
      final json = layer.toJson();
      final decoded = MapLayer.fromJson(json);
      expect(decoded, layer);
    });

    test('fromJson sans content => content vide', () {
      final decoded = MapLayer.fromJson(<String, dynamic>{
        'runtimeType': 'environment',
        'id': 'e',
        'name': 'E',
        'isVisible': true,
        'opacity': 1.0,
        'properties': <String, String>{},
      });
      expect(decoded, isA<EnvironmentLayer>());
      expect((decoded as EnvironmentLayer).content,
          EnvironmentLayerContent.emptyContent);
    });

    test('copyWith préserve content et properties si non passés', () {
      final layer = MapLayer.environment(
        id: 'e',
        name: 'Old',
        content: EnvironmentLayerContent(targetTileLayerId: 't', areas: null),
        properties: {'a': 'b'},
      );
      final next = layer.copyWith(name: 'New') as EnvironmentLayer;
      expect(next.name, 'New');
      expect(next.content.targetTileLayerId, 't');
      expect(next.properties, {'a': 'b'});
    });
  });

  group('addMapLayer MapLayerKind.environment', () {
    test('crée EnvironmentLayer avec ids normalisés et content vide', () {
      final map = _minimalMap(layers: []);
      final updated = addMapLayer(
        map,
        kind: MapLayerKind.environment,
        id: '  my_env  ',
        name: '  Meta  ',
      );
      expect(updated.layers, hasLength(1));
      final layer = updated.layers.single as EnvironmentLayer;
      expect(layer.id, 'my_env');
      expect(layer.name, 'Meta');
      expect(layer.content, EnvironmentLayerContent.emptyContent);
      expect(layer.content.targetTileLayerId, isNull);
      expect(updated.placedElements, isEmpty);
    });

    test('insertIndex comme autres layers non-path', () {
      final base = _minimalMap(layers: [
        MapLayer.tile(
          id: 't1',
          name: 'T',
          tiles: List<int>.filled(80, 0),
        ),
      ]);
      final updated = addMapLayer(
        base,
        kind: MapLayerKind.environment,
        id: 'env',
        name: 'Env',
        insertIndex: 0,
      );
      expect(updated.layers.first.id, 'env');
      expect(updated.layers[1].id, 't1');
    });
  });

  group('setEnvironmentLayerContent', () {
    test('remplace content et conserve méta', () {
      final env =
          MapLayer.environment(id: 'e', name: 'N', properties: {'x': 'y'});
      final map = _minimalMap(layers: [env]);
      final nextContent = EnvironmentLayerContent(
        targetTileLayerId: 'tiles_main',
        areas: [_areaFor1024(id: 'a1')],
      );
      final out = setEnvironmentLayerContent(
        map,
        layerId: 'e',
        content: nextContent,
      );
      final layer = out.layers.single as EnvironmentLayer;
      expect(layer.content, nextContent);
      expect(layer.name, 'N');
      expect(layer.isVisible, isTrue);
      expect(layer.opacity, 1.0);
      expect(layer.properties, {'x': 'y'});
    });

    test('refuse layerId vide', () {
      expect(
        () => setEnvironmentLayerContent(
          _minimalMap(layers: []),
          layerId: '   ',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuse layer inconnu', () {
      expect(
        () => setEnvironmentLayerContent(
          _minimalMap(layers: []),
          layerId: 'x',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuse layer non EnvironmentLayer', () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 't',
          name: 'T',
          tiles: List<int>.filled(80, 0),
        ),
      ]);
      expect(
        () => setEnvironmentLayerContent(
          map,
          layerId: 't',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ne modifie pas placedElements', () {
      final placed = MapPlacedElement(
        id: 'pe1',
        layerId: 't',
        elementId: 'elm',
        pos: const GridPos(x: 0, y: 0),
      );
      final map = _minimalMap(
        layers: [
          MapLayer.environment(id: 'e', name: 'E'),
          MapLayer.tile(
            id: 't',
            name: 'T',
            tiles: List<int>.filled(80, 0),
          ),
        ],
        placedElements: [placed],
      );
      final out = setEnvironmentLayerContent(
        map,
        layerId: 'e',
        content: EnvironmentLayerContent(targetTileLayerId: 't', areas: null),
      );
      expect(out.placedElements, map.placedElements);
    });
  });

  group('MapValidator EnvironmentLayer', () {
    test('map valide avec EnvironmentLayer vide', () {
      final map = _minimalMap(layers: [
        MapLayer.environment(id: 'e', name: 'E'),
      ]);
      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('targetTileLayerId valide si TileLayer existe', () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'D',
          tiles: List<int>.filled(80, 0),
        ),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'decor',
            areas: null,
          ),
        ),
      ]);
      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('invalide si targetTileLayerId inconnu', () {
      final map = _minimalMap(layers: [
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'missing',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'invalide si targetTileLayerId pointe vers le layer environment lui-même',
        () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'D',
          tiles: List<int>.filled(80, 0),
        ),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'e',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalide si target pointe vers non-TileLayer', () {
      final map = _minimalMap(layers: [
        MapLayer.object(id: 'o', name: 'O'),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'o',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalide si masque ne correspond pas à la taille carte', () {
      final badMask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: List<bool>.filled(4, false),
      );
      final map = _minimalMap(layers: [
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'z',
                name: 'Z',
                presetId: 'p',
                mask: badMask,
                seed: 0,
              ),
            ],
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MapLayer.environment JSON edge cases', () {
    test('fromJson avec content null => emptyContent', () {
      final decoded = MapLayer.fromJson(<String, dynamic>{
        'runtimeType': 'environment',
        'id': 'e',
        'name': 'E',
        'content': null,
        'properties': <String, String>{},
      });
      expect((decoded as EnvironmentLayer).content,
          EnvironmentLayerContent.emptyContent);
    });

    test('properties roundtrip', () {
      final layer = MapLayer.environment(
        id: 'e',
        name: 'E',
        properties: {'k': 'v', 'x': 'y'},
      );
      final back = MapLayer.fromJson(layer.toJson()) as EnvironmentLayer;
      expect(back.properties, {'k': 'v', 'x': 'y'});
    });
  });

  group('resizeMapData EnvironmentLayer', () {
    test('agrandit la carte : masque redimensionné, métadonnées conservées',
        () {
      final envLayer = MapLayer.environment(
        id: 'env',
        name: 'Env',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'z',
              name: 'Z',
              presetId: 'p',
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: [true, false, false, false],
              ),
              seed: 3,
              paramsOverride: EnvironmentGenerationParams(
                density: 0.5,
                variation: 0.5,
                edgeDensity: 0.5,
                minSpacingCells: 2,
              ),
              generatedPlacementIds: ['p1'],
            ),
          ],
        ),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'ts',
        layers: [envLayer],
      );
      final resized = resizeMapData(map, width: 3, height: 3);
      final env = resized.layers.single as EnvironmentLayer;
      expect(env.content.targetTileLayerId, 'tiles');
      final area = env.content.areas.single;
      expect(area.id, 'z');
      expect(area.name, 'Z');
      expect(area.presetId, 'p');
      expect(area.seed, 3);
      expect(area.paramsOverride, isNotNull);
      expect(area.generatedPlacementIds, ['p1']);
      expect(area.mask.width, 3);
      expect(area.mask.height, 3);
      expect(area.mask.cells, hasLength(9));
      expect(area.mask.cells[0], isTrue);
      expect(area.mask.cells[8], isFalse);
    });

    test('rétrécit la carte : cellules hors carte supprimées', () {
      final cells = List<bool>.filled(9, false);
      cells[8] = true;
      final envLayer = MapLayer.environment(
        id: 'env',
        name: 'Env',
        content: EnvironmentLayerContent(
          areas: [
            EnvironmentArea(
              id: 'z',
              name: 'Z',
              presetId: 'p',
              mask: EnvironmentAreaMask(
                width: 3,
                height: 3,
                cells: cells,
              ),
              seed: 0,
            ),
          ],
        ),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 3, height: 3),
        tilesetId: 'ts',
        layers: [envLayer],
      );
      final resized = resizeMapData(map, width: 2, height: 2);
      final area =
          (resized.layers.single as EnvironmentLayer).content.areas.single;
      expect(area.mask.width, 2);
      expect(area.mask.height, 2);
      expect(area.mask.cells, everyElement(isFalse));
    });
  });
}

```

## 17. Diff complet

Tant que **`environment_layer_content_json_codec.dart`** et les deux fichiers de test restent **`??`**, le diff textuel par rapport à l’index Git vide est **identique au contenu verbatim** des §16.1 (**270** lignes), §16.2 (**384** lignes) et §16.3 (**444** lignes) — aucune ellipse.

Pour reproduction locale sur fichier non versionné :

```bash
git diff --no-index /dev/null packages/map_core/lib/src/operations/environment_layer_content_json_codec.dart
# code de sortie 1 si le patch est non vide — normal pour une création pure
```

## 18. Points non modifiés volontairement

- **`map_gameplay`** **`whenOrNull`** : pas de branche **environment** — acceptable (**no-op** implicite).
- **Validation** **presetId** / **placedElements** / collisions : hors périmètre Lot 4 et review.
- **`double` JSON pour densités** `0.5` : conservé (**double** ou **int** entier via **`_requireDoubleUnit`**).
- **Pas de `build_runner`** : **`map_layer.dart`** inchangé.

## 19. Auto-review

**Points solides** — JSON aligné sur **`EnvironmentLayerContent`** / **`EnvironmentArea`** ; tests couvrent régression Lot 4 + strict + resize.

**Points discutables** — **`int` strict** pour **seed** / dimensions : si un jour les pipelines JSON injectent **`1.0`** (double) pour un entier, le decode échouera ; acceptable pour carte **authoring** contrôlée ; sinon étape **`round`** documentée plus tard.

**Corrections après auto-review** — Clarification messages **`FormatException`** ; boucle **`areas[i]`** avec indices pour erreurs localisées.

**Risques restants** — Consommateurs externes du JSON hors contrôle strict pourraient nécessiter une migration ou une étape « normaliser les types JSON ».

**Regard critique sur le prompt**

- **Int strict** : volontairement strict ; cohérent avec éviter **toInt()** silencieux.
- **Whitespace `targetTileLayerId`** : aligné **`EnvironmentLayerContent`** (non vide si fourni).
- **`build_runner`** : non nécessaire — pas de changement modèle.
- **Périmètre** : limité codec + tests + rapport — OK.

## 20. Verdict

Statut du review :

- [x] Lot 4 validé sans réserve après review
- [ ] Lot 4 validé avec réserve
- [ ] Lot 4 non validé

Résumé :

```text
Codec durci (targetTileLayerId, int strict, placements, doublons areas) ; tests + resize + JSON edge ; map_core 1253 tests verts ; analyze OK ; pas de manifest/UI/générateur/build_runner/commit.
```

Prochain lot recommandé :

```text
Environment-5 — ProjectManifest Environment Presets V0
```

---

### Evidence Pack

- **Git** : §15.
- **Fichiers inspectés** : §3.
- **Switchs** : §4.
- **Codec avant/après** : §5–6.
- **Tests** : §7 + §14 (sorties **`expanded`** intégrales pour codec, intégration, régressions Env-2/3 ; §14.4 pour la suite **`map_core`** en **`compact`** — ligne finale **`+1253: All tests passed!`**).
- **Sources tests review** : texte intégral **`environment_layer_content_json_codec_test.dart`** (**384** lignes) et **`environment_layer_map_layer_integration_test.dart`** (**444** lignes) — §16.2 et §16.3.
- **`ProjectManifest`** : non modifié.
- **UI Environment Studio / générateur** : non créés.
- **`build_runner`** : **non lancé** (§11).
- **Commit / git add / push** : **non effectués**.
