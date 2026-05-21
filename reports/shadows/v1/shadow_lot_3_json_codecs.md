# Shadow Lot 3 — Shadow JSON Codecs V0

## 1. Résumé

Shadow-3 ajoute des codecs JSON manuels externes pour `ProjectShadowProfile` et `ProjectShadowCatalog`.

Aucun modèle Shadow n'a reçu `toJson` / `fromJson`. `ProjectManifest` reste intact. Le lot reste limité à `map_core`, sans `build_runner`, sans Freezed/JsonSerializable, sans editor, sans runtime et sans gameplay.

## 2. Fichiers créés

- `packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart`
- `packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart`
- `packages/map_core/test/shadow/project_shadow_profile_json_codec_test.dart`
- `packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart`
- `reports/shadows/shadow_lot_3_json_codecs.md`

## 3. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

Modification unique : export public des codecs Shadow, cohérent avec les codecs `project_path_pattern_preset_json_codec.dart`, Surface et Environment déjà exportés par le barrel public.

## 4. API de codec ajoutée

```dart
Map<String, Object?> encodeProjectShadowProfile(ProjectShadowProfile profile);

ProjectShadowProfile decodeProjectShadowProfile(Object? json);

Map<String, Object?> encodeProjectShadowCatalog(ProjectShadowCatalog catalog);

ProjectShadowCatalog decodeProjectShadowCatalog(Object? json);
```

## 5. Forme JSON canonique

Profil complet :

```json
{
  "id": "tree_large",
  "name": "Large tree shadow",
  "mode": "ellipse",
  "renderPass": "groundStatic",
  "offsetX": 4.0,
  "offsetY": 12.0,
  "scaleX": 1.2,
  "scaleY": 0.45,
  "opacity": 0.35,
  "colorHexRgb": "000000",
  "softnessMode": "hardEdge"
}
```

Catalogue complet :

```json
{
  "profiles": [
    {
      "id": "tree_large",
      "name": "Large tree shadow",
      "mode": "ellipse",
      "renderPass": "groundStatic",
      "offsetX": 4.0,
      "offsetY": 12.0,
      "scaleX": 1.2,
      "scaleY": 0.45,
      "opacity": 0.35,
      "colorHexRgb": "000000",
      "softnessMode": "hardEdge"
    }
  ]
}
```

Catalogue vide canonique :

```json
{
  "profiles": []
}
```

L'encodage écrit tous les champs V0, même quand ils valent les defaults.

## 6. Décisions d’implémentation

Les codecs vivent dans `packages/map_core/lib/src/operations`, comme les codecs Surface / Environment / PathPattern existants.

Aucun `toJson` / `fromJson` n'est ajouté aux modèles : `ProjectShadowProfile` et `ProjectShadowCatalog` restent des value objects purs.

Aucun `build_runner` n'est utilisé : pas de `JsonSerializable`, pas de Freezed, pas de `part`, pas de fichier généré.

`ProjectManifest` reste intact : aucun champ `shadowCatalog`, aucun converter manifest, aucune migration.

Les codecs sont exportés depuis `packages/map_core/lib/map_core.dart`, car les codecs similaires `project_path_pattern_preset_json_codec.dart`, `project_surface_catalog_json_codec.dart`, `project_surface_preset_json_codec.dart` et `environment_preset_json_codec.dart` sont déjà publics depuis ce barrel.

Les enums sont encodés avec `.name` :

- `ShadowCasterMode.ellipse` -> `"ellipse"`
- `ShadowRenderPass.groundStatic` -> `"groundStatic"`
- `ShadowSoftnessMode.hardEdge` -> `"hardEdge"`

## 7. Gestion des erreurs

La convention retenue est `ValidationException`, cohérente avec les value objects Shadow-2 et les codecs Surface récents.

Le codec rejette directement :

- racine profile non-object ;
- `id`, `name`, `mode`, `renderPass`, `colorHexRgb`, `softnessMode` non-string ;
- `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity` non-numériques ;
- enum inconnue ;
- `profiles` présent mais non-list ;
- item `profiles[i]` non-object.

Les constructeurs des modèles rejettent ensuite :

- `id` / `name` vides ;
- `scaleX <= 0` ;
- `scaleY <= 0` ;
- `opacity < 0` ou `opacity > 1` ;
- `NaN`, `Infinity`, `-Infinity` ;
- `colorHexRgb` invalide après tolérance codec ;
- duplicate ids dans `ProjectShadowCatalog`.

## 8. Tolérances de decode

Tolérances implémentées :

- `decodeProjectShadowCatalog(null)` -> catalogue vide ;
- `decodeProjectShadowCatalog({})` -> catalogue vide ;
- `profiles` absent -> catalogue vide ;
- `colorHexRgb: "#RRGGBB"` accepté puis normalisé par le modèle ;
- `colorHexRgb` lowercase accepté puis normalisé uppercase ;
- champs inconnus ignorés au decode ;
- champs inconnus jamais réémis par encode.

Non toléré :

- enum inconnue ;
- `softnessMode: "runtimeBlur"` ;
- nombres transmis comme strings ;
- strings transmises comme nombres/booléens ;
- `profiles: null`, car `profiles` est alors présent avec une valeur non-list.

## 9. Tests ajoutés

`project_shadow_profile_json_codec_test.dart` couvre :

- encode complet canonique ;
- decode complet ;
- roundtrip encode -> decode ;
- roundtrip decode -> encode canonique ;
- decode minimal avec defaults V0 ;
- couleur lowercase normalisée ;
- couleur avec `#` acceptée puis encodée sans `#` ;
- couleurs invalides rejetées ;
- mode/renderPass/softnessMode inconnus rejetés ;
- `softnessMode: runtimeBlur` rejeté ;
- champs requis manquants rejetés ;
- types string invalides rejetés ;
- types numériques invalides rejetés ;
- valeurs invalidées par le modèle rejetées ;
- champs inconnus ignorés ;
- encode sans champs inconnus ;
- racine non-object rejetée.

`project_shadow_catalog_json_codec_test.dart` couvre :

- encode catalogue vide ;
- decode `null`, `{}` et `{"profiles": []}` en catalogue vide ;
- encode catalogue complet avec ordre préservé ;
- decode catalogue complet avec ordre préservé ;
- roundtrip encode -> decode ;
- roundtrip decode -> encode canonique ;
- `profileById` après decode ;
- lookup case-sensitive après decode ;
- `profiles` non-list rejeté ;
- item non-map rejeté ;
- duplicate ids rejetés ;
- profil invalide dans `profiles` rejeté.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
dart test test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
dart format lib/src/operations/project_shadow_profile_json_codec.dart lib/src/operations/project_shadow_catalog_json_codec.dart test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
dart test test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
dart test test/shadow
dart analyze lib/src/operations/project_shadow_profile_json_codec.dart lib/src/operations/project_shadow_catalog_json_codec.dart test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/models/shadow_catalog.dart
rg -n "build_runner|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
find packages/map_core/lib \( -name "*shadow*.g.dart" -o -name "*shadow*.freezed.dart" \) -print
dart test --reporter compact
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés

### RED TDD initial

Commande :

```bash
cd packages/map_core && dart test test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
```

Résultat attendu et observé avant implémentation :

```text
Failed to load "test/shadow/project_shadow_profile_json_codec_test.dart":
Error: Method not found: 'encodeProjectShadowProfile'.
Error: Method not found: 'decodeProjectShadowProfile'.

Failed to load "test/shadow/project_shadow_catalog_json_codec_test.dart":
Error: Method not found: 'encodeProjectShadowCatalog'.
Error: Method not found: 'decodeProjectShadowCatalog'.
Some tests failed.
```

### GREEN final ciblé

Commande :

```bash
cd packages/map_core && dart test test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
```

Résultat :

```text
+26: All tests passed!
```

## 12. Résultat de dart test test/shadow

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat :

```text
+47: All tests passed!
```

## 13. Résultat de dart analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/project_shadow_profile_json_codec.dart lib/src/operations/project_shadow_catalog_json_codec.dart test/shadow/project_shadow_profile_json_codec_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart
```

Résultat :

```text
Analyzing project_shadow_profile_json_codec.dart, project_shadow_catalog_json_codec.dart, project_shadow_profile_json_codec_test.dart, project_shadow_catalog_json_codec_test.dart...
No issues found!
```

## 14. Résultat du test complet map_core

Commande :

```bash
cd packages/map_core && dart test --reporter compact
```

Résultat :

```text
+1403: All tests passed!
```

## 15. Vérifications anti-dérive

Commande modèles :

```bash
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/models/shadow_catalog.dart
```

Résultat :

```text
(aucune sortie, exit code 1 de rg car aucun match)
```

Commande codecs :

```bash
rg -n "build_runner|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
```

Résultat :

```text
(aucune sortie, exit code 1 de rg car aucun match)
```

Commande generated files :

```bash
find packages/map_core/lib \( -name "*shadow*.g.dart" -o -name "*shadow*.freezed.dart" \) -print
```

Résultat :

```text
(aucune sortie)
```

Vérifications respectées :

- aucun `ProjectManifest` modifié ;
- aucun `MapData` modifié ;
- aucun `ProjectElementEntry` modifié ;
- aucun `MapPlacedElement` modifié ;
- aucun `map_editor` modifié ;
- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun `toJson/fromJson` ajouté aux modèles Shadow ;
- aucun `JsonSerializable` ;
- aucun Freezed ;
- aucun `build_runner` ;
- aucun generated file ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ;
- aucun `zOrder/zIndex`.

## 16. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
(aucune sortie)
```

## 17. Git status final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
?? packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart
?? packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart
?? packages/map_core/test/shadow/project_shadow_profile_json_codec_test.dart
?? reports/shadows/shadow_lot_3_json_codecs.md
```

## 18. Git diff stat final

```text
 packages/map_core/lib/map_core.dart | 2 ++
 1 file changed, 2 insertions(+)
```

Note : les fichiers créés sont non suivis et n'apparaissent donc pas dans `git diff --stat` tant qu'ils ne sont pas staged.

## 19. Non-objectifs respectés

Non implémenté dans ce lot :

- `ProjectManifest.shadowCatalog` ;
- `ProjectElementEntry.shadow` ;
- `ProjectElementShadowConfig` ;
- `MapPlacedElement.shadowOverride` ;
- Shadow Config Resolver ;
- Shadow Runtime Render Instruction ;
- renderer Flame ;
- actor blob shadows ;
- static placed element shadows ;
- editor preview ;
- Edit Element UI ;
- Shadow Studio ;
- time-of-day ;
- custom shadow sprite ;
- atlas shadow ;
- blur runtime ;
- chunk cache ;
- culling ;
- render order regression.

## 20. Risques / réserves

Les codecs Shadow utilisent `ValidationException`, ce qui est cohérent avec Shadow-2 et Surface. Environment utilise parfois `FormatException`, mais Shadow est plus proche des modèles Surface purs.

`decodeProjectShadowCatalog(null)` retourne un catalogue vide pour préparer Shadow-5. En revanche, `{"profiles": null}` est rejeté parce que `profiles` est explicitement présent avec une valeur non-list.

Les champs inconnus sont ignorés au decode. Cela aide la compatibilité future, mais il faudra que les validations manifest Shadow-5 distinguent les erreurs de référence métier des simples extensions JSON.

## 21. Prochain lot recommandé

Shadow-4 — ProjectElement Shadow Config V0.

Ce prochain lot devra ajouter la config Shadow optionnelle par élément, sans encore implémenter renderer ou UI complète.
