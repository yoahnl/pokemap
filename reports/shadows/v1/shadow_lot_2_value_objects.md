# Shadow Lot 2 — Shadow Value Objects V0

## 1. Résumé

Shadow-2 ajoute les value objects purs Shadow dans `map_core` :

- `ShadowCasterMode`
- `ShadowRenderPass`
- `ShadowSoftnessMode`
- `ProjectShadowProfile`
- `ProjectShadowCatalog`

Le lot reste limité au contrat modèle pur : aucun JSON, aucun `toJson/fromJson`, aucun `ProjectManifest`, aucun `MapData`, aucun éditeur, aucun runtime Flame, aucun gameplay, aucun `build_runner`.

## 2. Fichiers créés

- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/shadow_catalog.dart`
- `packages/map_core/test/shadow/project_shadow_profile_test.dart`
- `packages/map_core/test/shadow/project_shadow_catalog_test.dart`
- `reports/shadows/shadow_lot_2_value_objects.md`

## 3. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

Modification unique : export public des nouveaux modèles Shadow.

## 4. Modèles ajoutés

### ShadowCasterMode

Valeurs exactes :

```dart
none
contactBlob
ellipse
```

### ShadowRenderPass

Valeurs exactes :

```dart
groundStatic
actorContact
```

### ShadowSoftnessMode

Valeur exacte :

```dart
hardEdge
```

`runtimeBlur` n'existe pas dans l'enum V0.

### ProjectShadowProfile

Champs publics :

```dart
final String id;
final String name;
final ShadowCasterMode mode;
final ShadowRenderPass renderPass;
final double offsetX;
final double offsetY;
final double scaleX;
final double scaleY;
final double opacity;
final String colorHexRgb;
final ShadowSoftnessMode softnessMode;
```

Defaults V0 :

```text
offsetX = 0
offsetY = 0
scaleX = 1
scaleY = 1
opacity = 0.35
colorHexRgb = 000000
softnessMode = hardEdge
```

### ProjectShadowCatalog

Champs et API publics :

```dart
List<ProjectShadowProfile> get profiles;
int get profileCount;
bool get isEmpty;
bool get isNotEmpty;
ProjectShadowProfile? profileById(String id);
```

Le catalogue préserve l'ordre, copie défensivement la liste reçue, expose une liste immuable et fait un lookup exact case-sensitive.

## 5. Validations implémentées

`ProjectShadowProfile` valide :

- `id.trim().isNotEmpty`
- `name.trim().isNotEmpty`
- `offsetX.isFinite`
- `offsetY.isFinite`
- `scaleX.isFinite`
- `scaleY.isFinite`
- `opacity.isFinite`
- `scaleX > 0`
- `scaleY > 0`
- `opacity >= 0 && opacity <= 1`
- `colorHexRgb` contient exactement 6 caractères hexadécimaux ;
- `colorHexRgb` ne contient pas `#` ;
- `colorHexRgb` est normalisé en uppercase.

`ProjectShadowCatalog` valide :

- ids de profils uniques ;
- liste copiée défensivement ;
- liste exposée non modifiable.

## 6. Décisions d’implémentation

`ProjectShadowCatalog` vit dans `packages/map_core/lib/src/models/shadow_catalog.dart`, séparé de `shadow.dart`, pour suivre le pattern `surface.dart` / `surface_catalog.dart`.

Aucune API JSON n'est ajoutée : Shadow-2 suit la décision Shadow-1. Les codecs manuels externes appartiennent au prochain lot Shadow-3.

La convention d'exception suivie est `ValidationException`, comme les value objects Surface récents (`SurfaceAtlasTileSize`, `ProjectSurfaceAtlas`, `ProjectSurfaceCatalog`). `TilesetTransparentColor` utilise `ArgumentError`, mais Shadow-2 est plus proche de la chaîne Surface.

`colorHexRgb` est stocké en forme canonique `RRGGBB`, sans `#`, uppercase, sans alpha. Une entrée lowercase comme `0a0b0c` est acceptée puis stockée `0A0B0C`.

L'égalité de valeur est implémentée manuellement avec `operator ==` et `hashCode`, sans Freezed. Pour `ProjectShadowCatalog`, l'égalité respecte l'ordre des profils.

`ProjectManifest` reste intact : aucun champ `shadowCatalog`, aucune migration, aucun codec manifest.

## 7. Tests ajoutés

`project_shadow_profile_test.dart` couvre :

- création valide avec valeurs explicites ;
- defaults V0 ;
- rejet id vide / whitespace ;
- rejet name vide / whitespace ;
- rejet `scaleX == 0`, `scaleX < 0`, `scaleY == 0`, `scaleY < 0` ;
- rejet opacity hors bornes ;
- acceptation `opacity == 0` et `opacity == 1` ;
- rejet `NaN`, `Infinity`, `-Infinity` pour offset/scale/opacity ;
- rejet couleur avec `#`, trop courte, trop longue, non hex, vide ;
- normalisation lowercase vers uppercase ;
- égalité de valeur et `hashCode` ;
- absence de `runtimeBlur` dans `ShadowSoftnessMode.values`.

`project_shadow_catalog_test.dart` couvre :

- catalogue vide valide ;
- ordre préservé ;
- copie défensive ;
- liste immuable ;
- lookup par id ;
- lookup inconnu `null` ;
- lookup exact case-sensitive ;
- rejet duplicate ids ;
- égalité ordonnée et `hashCode` ;
- absence de besoin JSON au niveau API testée.

## 8. Commandes lancées

```bash
git status --short --untracked-files=all
dart test test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
dart format lib/src/models/shadow.dart lib/src/models/shadow_catalog.dart test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
dart test test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
dart analyze lib/src/models/shadow.dart lib/src/models/shadow_catalog.dart test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\.g\.dart|part .*\.freezed\.dart" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/models/shadow_catalog.dart
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|JsonSerializable|freezed|toJson|fromJson" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/models/shadow_catalog.dart
dart test
dart test --reporter compact
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 9. Résultats des tests

### RED TDD initial

Commande :

```bash
cd packages/map_core && dart test test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
```

Résultat attendu et observé avant implémentation :

```text
Failed to load "test/shadow/project_shadow_profile_test.dart":
Error: Type 'ProjectShadowProfile' not found.
Error: Type 'ShadowCasterMode' not found.
Error: Type 'ShadowRenderPass' not found.
Error: Type 'ShadowSoftnessMode' not found.

Failed to load "test/shadow/project_shadow_catalog_test.dart":
Error: Type 'ProjectShadowProfile' not found.
Error: Method not found: 'ProjectShadowCatalog'.
Some tests failed.
```

### Tests ciblés après implémentation

Commande :

```bash
cd packages/map_core && dart test test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
```

Résultat final :

```text
+21: All tests passed!
```

### Test complet map_core

Commande :

```bash
cd packages/map_core && dart test --reporter compact
```

Résultat final :

```text
+1377: All tests passed!
```

## 10. Résultat de dart analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/shadow.dart lib/src/models/shadow_catalog.dart test/shadow/project_shadow_profile_test.dart test/shadow/project_shadow_catalog_test.dart
```

Résultat :

```text
Analyzing shadow.dart, shadow_catalog.dart, project_shadow_profile_test.dart, project_shadow_catalog_test.dart...
No issues found!
```

## 11. Vérifications anti-dérive

Commande JSON / génération :

```bash
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\.g\.dart|part .*\.freezed\.dart" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/models/shadow_catalog.dart
```

Résultat :

```text
(aucune sortie, exit code 1 de rg car aucun match)
```

Commande champs interdits :

```bash
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|JsonSerializable|freezed|toJson|fromJson" packages/map_core/lib/src/models/shadow.dart packages/map_core/lib/src/models/shadow_catalog.dart
```

Résultat :

```text
(aucune sortie, exit code 1 de rg car aucun match)
```

Vérifications respectées :

- aucun `ProjectManifest` modifié ;
- aucun `MapData` modifié ;
- aucun `ProjectElementEntry` modifié ;
- aucun `MapPlacedElement` modifié ;
- aucun `map_editor` modifié ;
- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun codec JSON ;
- aucun `toJson/fromJson` ;
- aucun `build_runner` ;
- aucun generated file ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ;
- aucun `zOrder/zIndex`.

## 12. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
(aucune sortie)
```

## 13. Git status final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/shadow.dart
?? packages/map_core/lib/src/models/shadow_catalog.dart
?? packages/map_core/test/shadow/project_shadow_catalog_test.dart
?? packages/map_core/test/shadow/project_shadow_profile_test.dart
?? reports/shadows/shadow_lot_2_value_objects.md
```

## 14. Git diff stat final

```text
 packages/map_core/lib/map_core.dart | 2 ++
 1 file changed, 2 insertions(+)
```

Note : les fichiers créés sont non suivis et n'apparaissent donc pas dans `git diff --stat` tant qu'ils ne sont pas staged.

## 15. Non-objectifs respectés

Non implémenté dans ce lot :

- Shadow JSON Codecs ;
- `ProjectManifest.shadowCatalog` ;
- `ProjectElementEntry.shadow` ;
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

## 16. Risques / réserves

Le choix `ValidationException` est cohérent avec Surface, mais `TilesetTransparentColor` utilise `ArgumentError`. Si l'équipe veut unifier tous les petits value objects color/geometry autour d'`ArgumentError`, Shadow devra être réévalué avant Shadow-3.

Les tests confirment l'absence de JSON dans les nouveaux modèles par recherche textuelle et par absence de méthodes ajoutées. Dart ne fournit pas ici de réflexion naturelle robuste pour tester l'absence de méthodes statiques comme `fromJson`, donc le contrôle anti-dérive repose sur `rg` et revue du diff.

## 17. Prochain lot recommandé

Shadow-3 — Shadow JSON Codecs V0.

Ce prochain lot doit ajouter uniquement les codecs manuels externes `ProjectShadowProfile` / `ProjectShadowCatalog`, sans brancher `ProjectManifest`.
