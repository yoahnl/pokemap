# Shadow Lot 4 — ProjectElement Shadow Config V0

## 1. Résumé

Shadow-4 ajoute `ProjectElementShadowConfig` et `ProjectElementEntry.shadow`.
La config est optionnelle et reste limitée à `castsShadow`, `shadowProfileId` et aux overrides numériques `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity`.

Aucun `ProjectShadowCatalog` n'est branché au manifest. Aucun renderer, UI, override instance, éditeur, runtime ou gameplay n'est ajouté.

## 2. Fichiers créés

- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/test/shadow/project_element_shadow_config_test.dart`
- `packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart`
- `packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart`
- `reports/shadows/shadow_lot_4_project_element_shadow_config.md`

## 3. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

## 4. Modèle ajouté

`ProjectElementShadowConfig` vit dans `packages/map_core/lib/src/models/shadow.dart`.

Champs V0 exacts :

```dart
final bool castsShadow;
final String? shadowProfileId;
final double? offsetX;
final double? offsetY;
final double? scaleX;
final double? scaleY;
final double? opacity;
```

Le modèle est un value object pur Dart, sans API JSON directe, sans Flutter, sans Flame, et avec égalité de valeur.

## 5. Champ ProjectElementEntry ajouté

`ProjectElementEntry` reçoit :

```dart
@ProjectElementShadowConfigJsonConverter()
ProjectElementShadowConfig? shadow,
```

Le champ est nullable pour préserver les anciens éléments et distinguer :

- `shadow == null` : aucun contrat Shadow configuré sur l'élément.
- `shadow.castsShadow == false` : config présente mais ombre désactivée.
- `shadow.castsShadow == true` : ombre par défaut active via `shadowProfileId`.

Les anciens JSON sans clé `shadow` décodent avec `shadow == null`. Les JSON avec `"shadow": null` restent valides. `copyWith`, `fromJson` et `toJson` ont été mis à jour par `build_runner`.

## 6. Codec / converter JSON ajouté

API ajoutée :

```dart
Map<String, Object?> encodeProjectElementShadowConfig(
  ProjectElementShadowConfig config,
);

ProjectElementShadowConfig? decodeProjectElementShadowConfig(Object? json);

class ProjectElementShadowConfigJsonConverter
    implements JsonConverter<ProjectElementShadowConfig?, Object?>;
```

Encodage canonique :

```json
{
  "castsShadow": true,
  "shadowProfileId": "tree_large",
  "offsetX": 4.0,
  "offsetY": 12.0,
  "scaleX": 1.2,
  "scaleY": 0.45,
  "opacity": 0.35
}
```

L'encodage émet toujours `castsShadow`, puis seulement les champs optionnels non nuls.

## 7. Compatibilité anciens JSON

- `decodeProjectElementShadowConfig(null) -> null`
- `decodeProjectElementShadowConfig({}) -> ProjectElementShadowConfig(castsShadow: false)`
- `ProjectElementEntry.fromJson` sans `shadow` garde `shadow == null`
- `ProjectElementEntry.fromJson` avec `"shadow": null` garde `shadow == null`
- `ProjectManifest.fromJson` avec anciens éléments sans `shadow` continue de décoder
- `ProjectManifest.toJson` préserve la config `shadow` des éléments quand elle est non nulle

## 8. Validations implémentées

`ProjectElementShadowConfig` rejette :

- `shadowProfileId` vide ou whitespace quand fourni ;
- `castsShadow == true` sans `shadowProfileId` ;
- `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity` non finis ;
- `scaleX <= 0` et `scaleY <= 0` quand fournis ;
- `opacity < 0` ou `opacity > 1` quand fourni.

Le codec rejette :

- racine non-map non-null ;
- `castsShadow` non-bool ;
- `shadowProfileId` non-string ;
- `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity` non-numériques.

Les champs inconnus sont ignorés au decode et jamais réémis par encode.

## 9. Tests ajoutés

`project_element_shadow_config_test.dart` couvre les defaults, les configs valides, les validations numériques et l'égalité de valeur.

`project_element_shadow_config_json_codec_test.dart` couvre l'encodage canonique, le decode complet/minimal/null, les roundtrips, les champs inconnus et les types invalides.

`project_element_entry_shadow_json_test.dart` couvre les anciens JSON élément/manifest, `shadow: null`, `toJson`, `copyWith`, la préservation via `ProjectManifest` et le fait que `collisionProfile` reste inchangé quand une ombre est ajoutée.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
cd packages/map_core && dart test test/shadow/project_element_shadow_config_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/project_element_entry_shadow_json_test.dart
dart format packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/map_core.dart packages/map_core/test/shadow/project_element_shadow_config_test.dart packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd packages/map_core && dart test --reporter compact --no-color test/shadow/project_element_shadow_config_test.dart test/shadow/project_element_shadow_config_json_codec_test.dart test/shadow/project_element_entry_shadow_json_test.dart
cd packages/map_core && dart test --reporter compact --no-color test/shadow
cd packages/map_core && dart analyze lib/src/models/shadow.dart lib/src/operations/project_element_shadow_config_json_codec.dart lib/src/models/project_manifest.dart test/shadow
cd packages/map_core && set -o pipefail && dart test --reporter compact --no-color | tail -40
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|timeMode|affectedByTimeOfDay|shadowTilesetId|shadowSource|sourceMaskId" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart packages/map_core/lib/src/models/project_manifest.dart || true
rg -n "shadowCatalog|MapPlacedElementShadowOverride|ShadowResolvedConfig|ShadowRuntimeRenderInstruction|WorldLightState|ShadowLightProfile" packages/map_core/lib/src || true
find packages/map_core/lib -name '*shadow*.g.dart' -o -name '*shadow*.freezed.dart'
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_core/lib/src/models/shadow.dart || true
git status --short --untracked-files=all -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés

RED initial attendu :

```text
Error: Method not found: 'encodeProjectElementShadowConfig'
Error: Method not found: 'decodeProjectElementShadowConfig'
ProjectElementShadowConfig missing before implementation
```

GREEN final :

```text
00:00 +30: All tests passed!
```

## 12. Résultat de dart test test/shadow

```text
00:00 +77: All tests passed!
```

## 13. Résultat de dart analyze

```text
Analyzing shadow.dart, project_element_shadow_config_json_codec.dart, project_manifest.dart, shadow...
No issues found!
```

## 14. Résultat du test complet map_core

```text
00:02 +1433: All tests passed!
```

## 15. Build runner / génération

`build_runner` lancé : oui.

Commande :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Raison : `ProjectElementEntry` est un modèle Freezed/JsonSerializable ; le nouveau champ `shadow` doit exister dans `copyWith`, `fromJson` et `toJson`.

Résultat :

```text
Built with build_runner in 8s; wrote 12 outputs.
```

Warnings préexistants observés :

```text
SDK language version 3.11.0 is newer than analyzer language version 3.9.0.
json_annotation constraint ^4.8.1 allows versions before 4.9.0.
```

Fichiers générés modifiés dans git :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Aucun fichier généré `*shadow*.g.dart` ou `*shadow*.freezed.dart` n'a été créé.

## 16. Vérifications anti-dérive

Confirmé par commandes `rg`, `find` et `git status` :

- aucun `ProjectManifest.shadowCatalog` ;
- aucun `ProjectShadowCatalog` branché au manifest ;
- aucun `MapPlacedElement` modifié ;
- aucun `MapPlacedElementShadowOverride` ;
- aucun `ShadowResolvedConfig` ;
- aucun `ShadowRuntimeRenderInstruction` ;
- aucun `map_editor` modifié ;
- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucune collision modifiée ;
- aucune occlusion modifiée ;
- aucun `visualMask` modifié ;
- aucun `cells` modifié ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ;
- aucun `zOrder` / `zIndex` ;
- aucun `modeOverride`, `colorOverride`, `renderPassOverride` ou `softnessOverride` en V0 ;
- aucun `toJson` / `fromJson` ajouté aux modèles Shadow purs.

`git diff --check` : aucune sortie, exit code 0.

## 17. Git status initial

```text
clean
```

## 18. Git status final

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/models/shadow.dart
?? packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
?? packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart
?? packages/map_core/test/shadow/project_element_shadow_config_json_codec_test.dart
?? packages/map_core/test/shadow/project_element_shadow_config_test.dart
?? reports/shadows/shadow_lot_4_project_element_shadow_config.md
```

## 19. Git diff stat final

Avant création du rapport, `git diff --stat` sur les fichiers suivis :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../map_core/lib/src/models/project_manifest.dart  |   4 +
 .../lib/src/models/project_manifest.freezed.dart   |  29 +++++-
 .../lib/src/models/project_manifest.g.dart         |   4 +
 packages/map_core/lib/src/models/shadow.dart       | 113 +++++++++++++++++++++
 5 files changed, 150 insertions(+), 1 deletion(-)
```

Les fichiers non suivis sont listés dans `git status final`.

## 20. Non-objectifs respectés

Ce lot n'a pas ajouté :

- `ProjectManifest.shadowCatalog` ;
- intégration manifest de `ProjectShadowCatalog` ;
- `MapPlacedElementShadowOverride` ;
- `ShadowResolvedConfig` ;
- resolver Shadow ;
- renderer Flame ;
- actor blob shadows ;
- static placed element shadows ;
- editor preview ;
- UI Edit Element ;
- Shadow Studio ;
- time-of-day ;
- custom shadow sprite ;
- atlas shadow ;
- blur runtime ;
- chunk cache ;
- culling ;
- render order regression.

## 21. Risques / réserves

Le codec accepte uniquement des nombres JSON réels pour les overrides. Les strings numériques restent rejetées volontairement.

`shadowProfileId` n'est pas résolu contre un catalogue dans Shadow-4. C'est volontaire : le catalogue n'est pas encore branché au manifest et la validation inter-références appartient à Shadow-5/Shadow-7.

`ProjectElementEntry.toJson` suit le style généré existant et émet aussi `"shadow": null` quand le champ est nul. Le decode reste backward-compatible avec les JSON anciens sans clé `shadow`.

## 22. Prochain lot recommandé

Shadow-5 — ProjectShadowCatalog Manifest Integration V0.
