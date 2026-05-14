# Shadow Lot 5 — ProjectShadowCatalog Manifest Integration V0

## 1. Résumé

Shadow-5 branche `ProjectShadowCatalog` au `ProjectManifest` avec un default vide et un decode backward-compatible.
Le catalogue Shadow devient persistant via la clé JSON `shadowCatalog`.

Les références `ProjectElementEntry.shadow.shadowProfileId` peuvent maintenant être diagnostiquées contre le catalogue avec un diagnostic authoring minimal.
Aucun override instance, aucun resolver runtime, aucune UI et aucun renderer n'est ajouté.

## 2. Fichiers créés

- `packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart`
- `packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart`
- `packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart`
- `packages/map_core/test/shadow/project_manifest_shadow_catalog_operations_test.dart`
- `packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart`
- `reports/shadows/shadow_lot_5_manifest_catalog_integration.md`

## 3. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/lib/src/models/shadow_catalog.dart`
- `packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart`

## 4. Champ ProjectManifest ajouté

Champ ajouté :

```dart
@Default(ProjectShadowCatalog.empty())
@ProjectShadowCatalogJsonConverter()
ProjectShadowCatalog shadowCatalog,
```

Le type est non-nullable : `ProjectShadowCatalog`.

Raison : les futurs lots ne doivent pas propager un `ProjectShadowCatalog?` partout. Pour garder les appels Dart existants compatibles, `ProjectShadowCatalog` reçoit aussi un constructeur `const ProjectShadowCatalog.empty()` utilisable par `@Default`.

Comportement :

- `ProjectManifest.fromJson` sans `shadowCatalog` -> `ProjectShadowCatalog.empty()`.
- `ProjectManifest.fromJson` avec `"shadowCatalog": null` -> `ProjectShadowCatalog.empty()`.
- `ProjectManifest.toJson` encode toujours `shadowCatalog` selon le style des champs générés existants.
- `copyWith(shadowCatalog: ...)` est généré par Freezed.

## 5. Converter / codec manifest

`ProjectShadowCatalogJsonConverter` a été ajouté dans `packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart`, près des fonctions manuelles existantes :

```dart
encodeProjectShadowCatalog(...)
decodeProjectShadowCatalog(...)
ProjectShadowCatalogJsonConverter
```

Règles de decode :

- `null` -> catalogue vide ;
- `{}` -> catalogue vide ;
- clé `profiles` absente -> catalogue vide ;
- `{"profiles": []}` -> catalogue vide ;
- catalogue complet -> `ProjectShadowCatalog` complet ;
- racine non-map non-null -> `ValidationException` ;
- `profiles` non-list -> `ValidationException` ;
- item non-map -> `ValidationException` ;
- duplicate ids -> rejet via `ProjectShadowCatalog` ;
- profil invalide, enum inconnue ou `softnessMode: "runtimeBlur"` -> rejet via les codecs/profils Shadow.

## 6. Compatibilité anciens JSON

Tests couverts :

- manifest ancien sans `shadowCatalog` ;
- manifest avec `"shadowCatalog": null` ;
- manifest avec `"shadowCatalog": {}` ;
- manifest avec `"shadowCatalog": {"profiles": []}` ;
- manifest avec anciens `elements` sans `shadow` ;
- manifest avec `ProjectElementEntry.shadow` et `shadowCatalog` complet dans le même payload.

## 7. Opérations manifest ajoutées

API ajoutée :

```dart
ProjectShadowCatalog shadowCatalogForProject(ProjectManifest manifest);

bool projectHasShadowProfiles(ProjectManifest manifest);

ProjectManifest replaceProjectShadowCatalog(
  ProjectManifest manifest,
  ProjectShadowCatalog shadowCatalog,
);

ProjectManifest updateProjectShadowCatalog(
  ProjectManifest manifest,
  ProjectShadowCatalog Function(ProjectShadowCatalog current) update,
);

ProjectManifest clearProjectShadowCatalog(ProjectManifest manifest);
```

Ces opérations sont pures : pas d'I/O, pas de repository, pas de provider, pas d'éditeur, pas de runtime, pas de diagnostic implicite.

## 8. Diagnostics authoring ajoutés

API ajoutée :

```dart
enum ShadowAuthoringDiagnosticKind {
  missingShadowProfile,
}

final class ShadowAuthoringDiagnostic { ... }

List<ShadowAuthoringDiagnostic> diagnoseProjectShadowAuthoring(
  ProjectManifest manifest,
);
```

Règles d'émission :

- ignore `element.shadow == null` ;
- ignore `element.shadow.castsShadow == false` ;
- ignore une référence qui existe dans `manifest.shadowCatalog` ;
- émet `missingShadowProfile` pour `castsShadow == true` + `shadowProfileId` absent du catalogue ;
- un diagnostic par élément ;
- ordre des diagnostics = ordre des éléments dans le manifest.

Ce diagnostic ne résout pas les ombres, ne merge aucun override et ne lit aucune donnée de map placée.

## 9. Tests ajoutés

`project_manifest_shadow_catalog_json_test.dart` couvre :

- backward compatibility JSON ;
- decode null/empty/complet ;
- toJson catalogue vide/complet ;
- `copyWith` ;
- duplicate ids ;
- profil invalide ;
- enum inconnue ;
- `runtimeBlur` rejeté ;
- coexistence `ProjectElementEntry.shadow` + `shadowCatalog` ;
- roundtrip JSON.

`project_manifest_shadow_catalog_operations_test.dart` couvre :

- lecture du catalogue ;
- présence de profils ;
- replace/update/clear ;
- propagation d'exception du callback update ;
- roundtrip JSON après opération ;
- préservation de `elements`, `surfaceCatalog`, `settings`, `pokemon` et collision data.

`shadow_authoring_diagnostics_test.dart` couvre :

- absence de diagnostics pour shadows absentes/désactivées ;
- référence existante ;
- référence manquante ;
- ordre des diagnostics ;
- deux éléments vers la même référence manquante ;
- égalité de valeur du diagnostic ;
- absence de mutation de `visualMask`, `collisionMask`, `occlusionMask` et `cells`.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
find . -name AGENTS.md -print
rg -n "Shadow-5|ProjectShadowCatalog|shadowCatalog|ProjectElementEntry.shadow|diagnostic|Prochain lot|Résumé|Décisions finales|ProjectManifest" reports/shadows/*.md
sed -n '1,130p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '360,390p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_core/lib/src/models/shadow_catalog.dart
sed -n '1,220p' packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
sed -n '1,180p' packages/map_core/lib/src/operations/project_manifest_surface_catalog_operations.dart
sed -n '1,170p' packages/map_core/test/project_manifest_surface_catalog_operations_test.dart
sed -n '1,260p' packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart
cd packages/map_core && dart test test/shadow/project_manifest_shadow_catalog_json_test.dart test/shadow/project_manifest_shadow_catalog_operations_test.dart test/shadow/shadow_authoring_diagnostics_test.dart
dart format packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart packages/map_core/test/shadow/project_manifest_shadow_catalog_operations_test.dart packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
dart format packages/map_core/lib/src/models/shadow_catalog.dart packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart packages/map_core/lib/map_core.dart
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd packages/map_core && dart test --reporter compact --no-color test/shadow/project_manifest_shadow_catalog_json_test.dart test/shadow/project_manifest_shadow_catalog_operations_test.dart test/shadow/shadow_authoring_diagnostics_test.dart
cd packages/map_core && dart test --reporter compact --no-color test/shadow
cd packages/map_core && dart analyze lib/src/models/project_manifest.dart lib/src/operations/project_shadow_catalog_json_codec.dart lib/src/operations/project_manifest_shadow_catalog_operations.dart lib/src/operations/shadow_authoring_diagnostics.dart test/shadow
cd packages/map_core && dart test --reporter compact --no-color
rg -n "MapPlacedElementShadowOverride|ShadowOverrideMode|ShadowResolvedConfig|ShadowRuntimeRenderInstruction|WorldLightState|ShadowLightProfile" packages/map_core/lib/src || true
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|shadowTilesetId|shadowSource|sourceMaskId" packages/map_core/lib/src/models packages/map_core/lib/src/operations || true
find packages/map_core/lib -name '*shadow*.g.dart' -o -name '*shadow*.freezed.dart'
git status --short --untracked-files=all -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés

RED initial attendu :

```text
Shadow-5 tests failed because ProjectManifest.shadowCatalog, shadow catalog operations,
and shadow authoring diagnostics did not exist yet.
```

GREEN final :

```text
00:00 +27: All tests passed!
```

## 12. Résultat de dart test test/shadow

```text
00:00 +104: All tests passed!
```

## 13. Résultat de dart analyze

```text
Analyzing project_manifest.dart, project_shadow_catalog_json_codec.dart, project_manifest_shadow_catalog_operations.dart, shadow_authoring_diagnostics.dart, shadow...
No issues found!
```

## 14. Résultat du test complet map_core

```text
00:02 +1460: All tests passed!
exit_code=0
```

## 15. Build runner / génération

`build_runner` lancé : oui.

Commande :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Raison : `ProjectManifest` est un modèle Freezed/JsonSerializable ; le nouveau champ `shadowCatalog` doit exister dans `copyWith`, `fromJson` et `toJson`.

Sortie finale :

```text
Built with build_runner in 8s; wrote 12 outputs.
```

Warnings préexistants observés :

```text
SDK language version 3.11.0 is newer than analyzer language version 3.9.0.
json_annotation constraint ^4.8.1 allows versions before 4.9.0.
```

Fichiers générés modifiés :

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Confirmation : aucun `*shadow*.g.dart` ou `*shadow*.freezed.dart` n'a été créé.

## 16. Vérifications anti-dérive

Confirmé par `rg`, `find`, `git status` et `git diff --check` :

- aucun `MapPlacedElement` modifié ;
- aucun `MapPlacedElementShadowOverride` ;
- aucun `ShadowOverrideMode` ;
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
- aucun `modeOverride`, `colorOverride`, `renderPassOverride`, `softnessOverride` ;
- aucun Shadow Studio ;
- aucune UI.

`git diff --check` : aucune sortie.

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
 M packages/map_core/lib/src/models/shadow_catalog.dart
 M packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
?? packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart
?? packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart
?? packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart
?? packages/map_core/test/shadow/project_manifest_shadow_catalog_operations_test.dart
?? packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
?? reports/shadows/shadow_lot_5_manifest_catalog_integration.md
```

## 19. Git diff stat final

Après création du rapport, pour les fichiers suivis :

```text
 packages/map_core/lib/map_core.dart                |   2 +
 .../map_core/lib/src/models/project_manifest.dart  |   5 +
 .../lib/src/models/project_manifest.freezed.dart   | 115 +++++++++++++--------
 .../lib/src/models/project_manifest.g.dart         |   6 ++
 .../map_core/lib/src/models/shadow_catalog.dart    |  21 ++--
 .../project_shadow_catalog_json_codec.dart         |  17 +++
 6 files changed, 114 insertions(+), 52 deletions(-)
```

Les fichiers non suivis sont listés dans le `git status final`.

## 20. Non-objectifs respectés

Ce lot n'a pas ajouté :

- `MapPlacedElementShadowOverride` ;
- `ShadowOverrideMode` ;
- `ShadowResolvedConfig` ;
- Shadow Config Resolver complet ;
- `ShadowRuntimeRenderInstruction` ;
- renderer Flame ;
- UI éditeur ;
- preview ;
- Shadow Studio ;
- time-of-day ;
- custom shadow sprite ;
- `shadowTilesetId` ;
- `shadowSource` ;
- loader d'image ;
- dépendance externe.

## 21. Risques / réserves

`ProjectShadowCatalog.empty()` a été ajouté pour permettre un champ manifest non-nullable avec `@Default`. Le constructeur historique `ProjectShadowCatalog()` reste disponible et conserve les mêmes validations, l'ordre et l'immutabilité.

Le diagnostic de référence manquante est volontairement authoring-only : il ne bloque pas le decode JSON et ne résout pas les ombres. La validation inter-références stricte et le merge des configs restent pour les lots suivants.

`ProjectManifest.toJson` encode `shadowCatalog` même vide, en cohérence avec le style explicite du manifest et des catalogues V0.

## 22. Prochain lot recommandé

Shadow-6 — MapPlacedElement Shadow Override V0.

## 23. Code généré / modifié dans ce lot

Cette section injecte le code produit par Shadow-5 dans le rapport. Convention retenue pour éviter de transformer le rapport en dump de fichiers générés géants :

- les nouveaux fichiers source créés sont reproduits intégralement ;
- les tests créés sont injectés avec leurs scénarios et helpers principaux ;
- les fichiers existants modifiés sont injectés sous forme d'extraits exacts ;
- les fichiers `project_manifest.freezed.dart` et `project_manifest.g.dart` sont injectés sous forme d'extraits générés pertinents pour `shadowCatalog`, pas au complet.

### 23.1 `packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart`

```dart
import '../models/project_manifest.dart';
import '../models/shadow_catalog.dart';

/// Returns the current project shadow profile catalog without copying it.
ProjectShadowCatalog shadowCatalogForProject(ProjectManifest manifest) {
  return manifest.shadowCatalog;
}

/// True when the project owns at least one shadow profile.
bool projectHasShadowProfiles(ProjectManifest manifest) {
  return manifest.shadowCatalog.isNotEmpty;
}

/// Returns a new manifest with only [shadowCatalog] replaced.
ProjectManifest replaceProjectShadowCatalog(
  ProjectManifest manifest,
  ProjectShadowCatalog shadowCatalog,
) {
  return manifest.copyWith(shadowCatalog: shadowCatalog);
}

/// Applies [update] once to the current shadow catalog and stores the result.
ProjectManifest updateProjectShadowCatalog(
  ProjectManifest manifest,
  ProjectShadowCatalog Function(ProjectShadowCatalog current) update,
) {
  return manifest.copyWith(shadowCatalog: update(manifest.shadowCatalog));
}

/// Replaces the project shadow catalog with an empty catalog.
ProjectManifest clearProjectShadowCatalog(ProjectManifest manifest) {
  return manifest.copyWith(shadowCatalog: const ProjectShadowCatalog.empty());
}
```

### 23.2 `packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart`

```dart
import '../models/project_manifest.dart';

enum ShadowAuthoringDiagnosticKind {
  missingShadowProfile,
}

final class ShadowAuthoringDiagnostic {
  const ShadowAuthoringDiagnostic({
    required this.kind,
    required this.elementId,
    required this.shadowProfileId,
    required this.message,
  });

  final ShadowAuthoringDiagnosticKind kind;
  final String elementId;
  final String shadowProfileId;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShadowAuthoringDiagnostic &&
            kind == other.kind &&
            elementId == other.elementId &&
            shadowProfileId == other.shadowProfileId &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        elementId,
        shadowProfileId,
        message,
      );
}

/// Diagnoses element shadow profile references for authoring tools.
///
/// This is intentionally not a shadow resolver: it does not merge profile
/// fields, inspect map instances, or produce runtime render instructions.
List<ShadowAuthoringDiagnostic> diagnoseProjectShadowAuthoring(
  ProjectManifest manifest,
) {
  final diagnostics = <ShadowAuthoringDiagnostic>[];
  final catalog = manifest.shadowCatalog;

  for (final element in manifest.elements) {
    final shadow = element.shadow;
    if (shadow == null || !shadow.castsShadow) {
      continue;
    }

    final shadowProfileId = shadow.shadowProfileId;
    if (shadowProfileId == null) {
      continue;
    }

    if (catalog.profileById(shadowProfileId) != null) {
      continue;
    }

    diagnostics.add(
      ShadowAuthoringDiagnostic(
        kind: ShadowAuthoringDiagnosticKind.missingShadowProfile,
        elementId: element.id,
        shadowProfileId: shadowProfileId,
        message:
            'Element "${element.id}" references missing shadow profile "$shadowProfileId".',
      ),
    );
  }

  return List<ShadowAuthoringDiagnostic>.unmodifiable(diagnostics);
}
```

### 23.3 `ProjectShadowCatalog` modifié

Extrait ajouté/modifié dans `packages/map_core/lib/src/models/shadow_catalog.dart` :

```dart
/// Introduced as a standalone value object in Shadow-2, then persisted through
/// [ProjectManifest] in Shadow-5. It owns list immutability, order, id
/// uniqueness, and lookup.
@immutable
final class ProjectShadowCatalog {
  const ProjectShadowCatalog.empty() : _profiles = const [];

  ProjectShadowCatalog({
    List<ProjectShadowProfile> profiles = const [],
  }) : _profiles = _copyProfiles(profiles);

  final List<ProjectShadowProfile> _profiles;

  /// Profiles in insertion order. The returned list is unmodifiable.
  List<ProjectShadowProfile> get profiles => _profiles;

  int get profileCount => _profiles.length;

  bool get isEmpty => _profiles.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Exact, case-sensitive lookup by [ProjectShadowProfile.id].
  ProjectShadowProfile? profileById(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectShadowCatalog &&
          _projectShadowProfilesEqualInOrder(_profiles, other._profiles);

  @override
  int get hashCode => Object.hashAll(_profiles);
}

List<ProjectShadowProfile> _copyProfiles(List<ProjectShadowProfile> profiles) {
  final copiedProfiles = List<ProjectShadowProfile>.from(profiles);
  _rejectDuplicateProfileIds(copiedProfiles);
  return List<ProjectShadowProfile>.unmodifiable(copiedProfiles);
}
```

### 23.4 `ProjectShadowCatalogJsonConverter`

Extrait ajouté dans `packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart` :

```dart
import 'package:json_annotation/json_annotation.dart';
```

```dart
class ProjectShadowCatalogJsonConverter
    implements JsonConverter<ProjectShadowCatalog, Object?> {
  const ProjectShadowCatalogJsonConverter();

  @override
  ProjectShadowCatalog fromJson(Object? json) {
    return decodeProjectShadowCatalog(json);
  }

  @override
  Object? toJson(ProjectShadowCatalog catalog) {
    return encodeProjectShadowCatalog(catalog);
  }
}
```

### 23.5 `ProjectManifest.shadowCatalog`

Extraits ajoutés dans `packages/map_core/lib/src/models/project_manifest.dart` :

```dart
import 'shadow_catalog.dart';
```

```dart
import '../operations/project_shadow_catalog_json_codec.dart';
```

```dart
@Default(ProjectShadowCatalog.empty())
@ProjectShadowCatalogJsonConverter()
ProjectShadowCatalog shadowCatalog,
```

### 23.6 Exports publics `map_core.dart`

Extraits ajoutés dans `packages/map_core/lib/map_core.dart` :

```dart
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
```

```dart
export 'src/operations/shadow_authoring_diagnostics.dart';
```

### 23.7 Extraits générés par `build_runner`

Extraits pertinents de `packages/map_core/lib/src/models/project_manifest.g.dart` :

```dart
shadowCatalog: json['shadowCatalog'] == null
    ? const ProjectShadowCatalog.empty()
    : const ProjectShadowCatalogJsonConverter()
        .fromJson(json['shadowCatalog']),
```

```dart
'shadowCatalog': const ProjectShadowCatalogJsonConverter()
    .toJson(instance.shadowCatalog),
```

Extraits pertinents de `packages/map_core/lib/src/models/project_manifest.freezed.dart` :

```dart
@ProjectShadowCatalogJsonConverter()
ProjectShadowCatalog get shadowCatalog => throw _privateConstructorUsedError;
```

```dart
@Default(ProjectShadowCatalog.empty())
@ProjectShadowCatalogJsonConverter()
ProjectShadowCatalog shadowCatalog,
```

```dart
shadowCatalog: null == shadowCatalog
    ? _value.shadowCatalog
    : shadowCatalog // ignore: cast_nullable_to_non_nullable
        as ProjectShadowCatalog,
```

### 23.8 Tests générés

Les fichiers de tests créés sont :

```text
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart
packages/map_core/test/shadow/project_manifest_shadow_catalog_operations_test.dart
packages/map_core/test/shadow/shadow_authoring_diagnostics_test.dart
```

Scénarios injectés dans `project_manifest_shadow_catalog_json_test.dart` :

```dart
test('decodes legacy manifest JSON without shadowCatalog as empty', () { ... });
test('decodes null, empty object, and empty profiles as empty', () { ... });
test('decodes a complete shadow catalog', () { ... });
test('toJson preserves a complete shadow catalog', () { ... });
test('toJson encodes an empty shadow catalog canonically', () { ... });
test('copyWith replaces shadowCatalog', () { ... });
test('rejects invalid shadow catalogs', () { ... });
test('rejects duplicate and invalid profiles', () { ... });
test('rejects unknown enums and runtimeBlur softnessMode', () { ... });
test('preserves ProjectElementEntry.shadow alongside shadowCatalog', () { ... });
test('roundtrips element shadow and catalog through JSON', () { ... });
```

Helpers principaux injectés dans `project_manifest_shadow_catalog_json_test.dart` :

```dart
Map<String, Object?> _manifestJson({
  Object? shadowCatalog = _shadowCatalogAbsent,
  List<Object?>? elements,
}) {
  return <String, Object?>{
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (!identical(shadowCatalog, _shadowCatalogAbsent))
      'shadowCatalog': shadowCatalog,
    if (elements != null) 'elements': elements,
  };
}

ProjectManifest _manifest({
  ProjectShadowCatalog? shadowCatalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: shadowCatalog ?? ProjectShadowCatalog(),
  );
}
```

Scénarios injectés dans `project_manifest_shadow_catalog_operations_test.dart` :

```dart
test('shadowCatalogForProject returns the manifest catalog', () { ... });
test('projectHasShadowProfiles reflects catalog emptiness', () { ... });
test('replaceProjectShadowCatalog replaces only shadowCatalog', () { ... });
test('updateProjectShadowCatalog receives current catalog once', () { ... });
test('updateProjectShadowCatalog propagates exceptions', () { ... });
test('clearProjectShadowCatalog yields an empty catalog', () { ... });
test('operations preserve JSON roundtrip contract', () { ... });
test('adding shadowCatalog does not modify element collision data', () { ... });
```

Scénarios injectés dans `shadow_authoring_diagnostics_test.dart` :

```dart
test('manifest without element shadows has no diagnostics', () { ... });
test('ignores null shadow and castsShadow false', () { ... });
test('castsShadow true with existing profile has no diagnostics', () { ... });
test('castsShadow true with missing profile produces a diagnostic', () { ... });
test('emits one diagnostic per element in manifest order', () { ... });
test('same missing profile on two elements emits two diagnostics', () { ... });
test('diagnostics use value equality', () { ... });
test('diagnostics do not modify collision data', () { ... });
```
