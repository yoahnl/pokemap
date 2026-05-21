# Shadow Lot 7 — Shadow Config Resolver / Merge Rules V0

## 1. Résumé

Shadow-7 ajoute un resolver pur qui combine `ProjectShadowCatalog`, `ProjectElementShadowConfig` et `MapPlacedElementShadowOverride` en une résolution Shadow V0.

Aucun renderer, aucune UI, aucun runtime, aucun editor et aucun JSON n'est ajouté.

Le resolver répond à la question :

```text
catalog + config élément + override instance
→ ResolvedShadowConfig?
→ diagnostics éventuels
```

Le rapport inclut le code généré/modifié du lot, conformément à la règle de reporting ajoutée.

## 2. Fichiers créés

- `packages/map_core/lib/src/operations/shadow_config_resolver.dart`
- `packages/map_core/test/shadow/shadow_config_resolver_test.dart`
- `reports/shadows/shadow_lot_7_config_resolver.md`

## 3. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

Aucun modèle persistant n'a été modifié.

## 4. API ajoutée

API publique ajoutée :

```dart
ShadowConfigResolution resolveShadowConfig({
  required ProjectShadowCatalog catalog,
  required ProjectElementShadowConfig? elementShadow,
  MapPlacedElementShadowOverride? placedOverride,
});
```

Types ajoutés :

- `ResolvedShadowConfig`
- `ShadowConfigResolution`
- `ShadowConfigResolutionDiagnostic`
- `ShadowConfigResolutionDiagnosticKind`

Export public ajouté :

```dart
export 'src/operations/shadow_config_resolver.dart';
```

## 5. Règles de merge implémentées

Ordre de merge :

```text
ProjectShadowProfile
→ ProjectElementShadowConfig overrides
→ MapPlacedElementShadowOverride overrides
```

Règles implémentées :

- `placedOverride == null` équivaut à `inherit`.
- `placedOverride.mode == inherit` équivaut à absent.
- `placedOverride.mode == disabled` gagne toujours et retourne aucune ombre sans diagnostic.
- `elementShadow == null` sans override custom actif retourne aucune ombre.
- `elementShadow.castsShadow == false` sans override custom actif retourne aucune ombre.
- `elementShadow.castsShadow == true` utilise `elementShadow.shadowProfileId`.
- `placedOverride.custom.shadowProfileId` remplace le profile id élément.
- `placedOverride.custom` sans `shadowProfileId` garde le profil élément.
- `placedOverride.custom` avec profil peut activer une instance même si l'élément n'a pas de Shadow actif.
- Les overrides numériques élément remplacent les valeurs profil.
- Les overrides numériques instance remplacent les valeurs déjà mergées.
- `ShadowCasterMode.none` est un profil valide et retourne aucune ombre sans diagnostic.
- Un profil manquant retourne aucune ombre avec diagnostic `missingShadowProfile`.
- Un custom numérique sans base active retourne aucune ombre avec diagnostic `customOverrideWithoutBaseProfile`.
- Un custom vide sans base active retourne aucune ombre sans diagnostic.

Champs résolus :

- `shadowProfileId`
- `mode`
- `renderPass`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`
- `colorHexRgb`
- `softnessMode`

## 6. Modèles de résolution ajoutés

`ResolvedShadowConfig` contient exactement les champs V0 utiles au prochain read model/editor/runtime :

- profil final ;
- mode et render pass du profil ;
- offsets/scales/opacity mergés ;
- couleur et softness du profil.

`ShadowConfigResolution` contient :

- `ResolvedShadowConfig? resolved`
- `List<ShadowConfigResolutionDiagnostic> diagnostics`
- `hasShadow`
- `isNone`
- `hasDiagnostics`

La liste de diagnostics est copiée et exposée en immutable.

## 7. Diagnostics ajoutés

`ShadowConfigResolutionDiagnosticKind` :

- `missingShadowProfile`
- `customOverrideWithoutBaseProfile`

`missingShadowProfile` est émis quand un profile id est déterminé mais absent du catalogue.

`customOverrideWithoutBaseProfile` est émis quand un override instance `custom` ajuste des valeurs numériques sans profil instance et sans profil élément actif.

## 8. Décisions d’implémentation

Le resolver vit dans `operations/shadow_config_resolver.dart`, car ses résultats sont calculés, non persistés.

Aucun JSON n'est ajouté : les entrées du resolver utilisent les value objects existants des lots Shadow-2 à Shadow-6.

Aucun `ProjectManifest` n'est requis par l'API générique : `resolveShadowConfig(...)` prend seulement le catalogue, la config élément optionnelle et l'override instance optionnel.

Aucun `MapData` ni `MapPlacedElement` n'est requis par l'API générique. L'appelant extrait plus tard `placedElement.shadowOverride`, mais le resolver ne dépend pas du modèle de map.

Les références manquantes ne crashent pas. Elles retournent `resolved == null` et un diagnostic lisible.

Le profil `mode == none` est traité comme une absence volontaire d'ombre, sans diagnostic.

## 9. Tests ajoutés

Fichier ajouté :

- `packages/map_core/test/shadow/shadow_config_resolver_test.dart`

Couverture :

- absence de shadow élément ;
- `castsShadow false` ;
- résolution profil existant ;
- champs profil conservés ;
- profil `none` ;
- overrides élément complets et partiels ;
- inherit absent / explicite ;
- disabled wins ;
- custom remplace le profil ;
- custom ajuste offset/scale/opacity après élément ;
- custom partiel garde les valeurs restantes ;
- custom sans profil garde le profil élément ;
- custom avec profil active une instance sans shadow élément ;
- profil manquant élément ;
- profil manquant instance ;
- custom numérique sans base ;
- custom vide sans base ;
- immutabilité diagnostics ;
- égalité/hash des trois types de résolution ;
- absence de mutation des objets d'entrée ;
- API générique sans `ProjectManifest` / `MapPlacedElement`.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
rg -n "resolve.*Config|Resolution|Diagnostic|diagnose|Resolver|Resolved" packages/map_core/lib/src/operations packages/map_core/test | head -160
sed -n '1,240p' packages/map_core/lib/src/operations/shadow_authoring_diagnostics.dart
sed -n '1,220p' packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart
sed -n '1,220p' packages/map_core/lib/src/models/shadow_catalog.dart
sed -n '1,140p' packages/map_core/lib/map_core.dart
dart test test/shadow/shadow_config_resolver_test.dart
dart format lib/src/operations/shadow_config_resolver.dart lib/map_core.dart test/shadow/shadow_config_resolver_test.dart
dart test test/shadow/shadow_config_resolver_test.dart
dart test --reporter compact --no-color test/shadow/shadow_config_resolver_test.dart
dart test --reporter compact --no-color test/shadow
dart analyze lib/src/operations/shadow_config_resolver.dart test/shadow
dart test --reporter compact --no-color
dart analyze
rg -n "ShadowRuntimeRenderInstruction|WorldLightState|ShadowLightProfile|Flame|Canvas|drawOval|drawPath|drawImage|ImageFilter|saveLayer" packages/map_core/lib/src || true
rg -n "toJson|fromJson|JsonSerializable|freezed|part .*\\.g\\.dart|part .*\\.freezed\\.dart" packages/map_core/lib/src/operations/shadow_config_resolver.dart || true
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|shadowTilesetId|shadowSource|sourceMaskId|timeMode|affectedByTimeOfDay" packages/map_core/lib/src/models packages/map_core/lib/src/operations || true
find packages/map_core/lib -name "*shadow*.g.dart" -o -name "*shadow*.freezed.dart"
git diff --check
git diff --stat
git status --short --untracked-files=all
git status --short --untracked-files=all -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle
git log -1 --oneline
git ls-files packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart reports/shadows/shadow_lot_6_map_placed_element_override.md packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart
```

## 11. Résultats des tests ciblés

RED initial :

```text
Failed to load "test/shadow/shadow_config_resolver_test.dart"
Error: Method not found: 'resolveShadowConfig'.
Error: Couldn't find constructor 'ResolvedShadowConfig'.
Error: Undefined name 'ShadowConfigResolutionDiagnosticKind'.
Some tests failed.
```

Après implémentation, un premier GREEN a révélé une erreur de null-safety dans le resolver :

```text
Property 'offsetX' cannot be accessed on 'MapPlacedElementShadowOverride?' because it is potentially null.
```

Correction : capture explicite de `placedOverride!` dans le bloc `custom`.

Deuxième échec : message de diagnostic avec `Custom` majuscule alors que le test cherchait `custom`.

Correction : message normalisé en minuscule.

Résultat ciblé final :

```text
00:00 +23: All tests passed!
```

## 12. Résultat de dart test test/shadow

```text
00:00 +152: All tests passed!
```

## 13. Résultat de dart analyze

Analyse ciblée :

```text
Analyzing shadow_config_resolver.dart, shadow...
No issues found!
```

Analyse complète `map_core` :

```text
Analyzing map_core...
No issues found!
```

## 14. Résultat du test complet map_core

```text
00:03 +1508: All tests passed!
```

## 15. Build runner / génération

Build runner lancé : non.

Fichiers generated : aucun.

Raison : Shadow-7 ajoute seulement un fichier d'opération pur et un test. Aucun modèle Freezed/JsonSerializable n'a été modifié.

## 16. Vérifications anti-dérive

Confirmé :

- aucun `ProjectManifest` modifié ;
- aucun `ProjectElementEntry` modifié ;
- aucun `MapPlacedElement` modifié ;
- aucun `ProjectShadowCatalog` modifié ;
- aucun `ProjectShadowProfile` modifié ;
- aucun JSON ajouté ;
- aucun `toJson` / `fromJson` ajouté au resolver ;
- aucun `build_runner` ;
- aucun generated file ;
- aucun `ShadowRuntimeRenderInstruction` ;
- aucun `WorldLightState` ;
- aucun `ShadowLightProfile` ;
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
- aucune UI ;
- aucun renderer.

Anti-dérive runtime/rendu :

```text
rg ShadowRuntimeRenderInstruction/WorldLightState/.../saveLayer packages/map_core/lib/src
```

Résultat :

```text
packages/map_core/lib/src/models/shadow.dart:46:/// This model has no JSON API and no dependency on Flutter or Flame.
packages/map_core/lib/src/models/shadow.dart:118:/// occlusion, cells, gameplay, Flutter, or Flame.
```

Ces deux occurrences sont des commentaires préexistants dans `shadow.dart`, pas une implémentation de rendu/runtime.

Anti-dérive JSON dans le resolver :

```text
aucune sortie
```

Anti-dérive blur/zOrder/time/source :

```text
aucune sortie
```

Generated Shadow :

```text
aucune sortie
```

`git diff --check` :

```text
aucune sortie
```

## 17. Git status initial

Status capturé au début de Shadow-7 :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/map_data.dart
 M packages/map_core/lib/src/models/map_data.freezed.dart
 M packages/map_core/lib/src/models/map_data.g.dart
 M packages/map_core/lib/src/models/shadow.dart
?? packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_json_codec_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_test.dart
?? reports/shadows/shadow_lot_6_map_placed_element_override.md
```

Observation : pendant l'exécution de Shadow-7, la base Git courante est devenue :

```text
b439f0d8 lot 6 shadow
```

Les fichiers Shadow-6 sont désormais suivis par Git :

```text
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/test/shadow/map_placed_element_shadow_json_test.dart
reports/shadows/shadow_lot_6_map_placed_element_override.md
```

Aucune commande Git d'écriture n'a été lancée par ce lot.

## 18. Git status final

Status final après ajout de ce rapport :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/shadow_config_resolver.dart
?? packages/map_core/test/shadow/shadow_config_resolver_test.dart
?? reports/shadows/shadow_lot_7_config_resolver.md
```

## 19. Git diff stat final

`git diff --stat` final :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : `git diff --stat` ne liste pas les nouveaux fichiers non suivis (`shadow_config_resolver.dart`, tests, rapport).

## 20. Non-objectifs respectés

Non implémenté :

- pas de JSON ;
- pas de `toJson` / `fromJson` ;
- pas de build runner ;
- pas de generated file ;
- pas de modification `ProjectManifest` ;
- pas de modification `ProjectElementEntry` ;
- pas de modification `MapPlacedElement` ;
- pas de renderer ;
- pas de Flame ;
- pas de runtime ;
- pas d'éditeur ;
- pas de gameplay ;
- pas de collision/occlusion ;
- pas de `runtimeBlur` ;
- pas de `blurRadius` ;
- pas de `zOrder` / `zIndex` ;
- pas de source sprite/atlas shadow ;
- pas de time-of-day.

## 21. Risques / réserves

- Le resolver applique les overrides élément même quand l'instance custom remplace le profil par un autre profil, tant que `elementShadow.castsShadow == true`. C'est conforme à l'ordre demandé `profile -> element overrides -> instance override`, mais il faudra valider que l'UX future rend ce comportement clair.
- `custom` vide sans base est traité comme none sans diagnostic. C'est intentionnel pour éviter un bruit authoring inutile.
- `ShadowCasterMode.none` retourne none sans diagnostic. Ce profil exprime une absence volontaire d'ombre.
- Le resolver ne vérifie pas la validité numérique des inputs, car les value objects des lots précédents le font déjà.

## 22. Prochain lot recommandé

Shadow-8 — Editor Shadow Read Model V0.

Ne pas l'implémenter dans Shadow-7.

## 23. Code généré / modifié dans ce lot

### 23.1 `packages/map_core/lib/src/operations/shadow_config_resolver.dart`

```dart
import '../models/shadow.dart';
import '../models/shadow_catalog.dart';

bool _diagnosticsEqualInOrder(
  List<ShadowConfigResolutionDiagnostic> a,
  List<ShadowConfigResolutionDiagnostic> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

bool _hasNumericCustomFields(MapPlacedElementShadowOverride override) {
  return override.offsetX != null ||
      override.offsetY != null ||
      override.scaleX != null ||
      override.scaleY != null ||
      override.opacity != null;
}

/// Fully merged V0 shadow values ready for a later editor or runtime adapter.
///
/// This is not persisted and does not describe a render instruction.
final class ResolvedShadowConfig {
  const ResolvedShadowConfig({
    required this.shadowProfileId,
    required this.mode,
    required this.renderPass,
    required this.offsetX,
    required this.offsetY,
    required this.scaleX,
    required this.scaleY,
    required this.opacity,
    required this.colorHexRgb,
    required this.softnessMode,
  });

  final String shadowProfileId;
  final ShadowCasterMode mode;
  final ShadowRenderPass renderPass;
  final double offsetX;
  final double offsetY;
  final double scaleX;
  final double scaleY;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedShadowConfig &&
          other.shadowProfileId == shadowProfileId &&
          other.mode == mode &&
          other.renderPass == renderPass &&
          other.offsetX == offsetX &&
          other.offsetY == offsetY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode;

  @override
  int get hashCode => Object.hash(
        shadowProfileId,
        mode,
        renderPass,
        offsetX,
        offsetY,
        scaleX,
        scaleY,
        opacity,
        colorHexRgb,
        softnessMode,
      );
}

/// Non-throwing result of V0 shadow config resolution.
final class ShadowConfigResolution {
  ShadowConfigResolution({
    required this.resolved,
    required List<ShadowConfigResolutionDiagnostic> diagnostics,
  }) : diagnostics =
            List<ShadowConfigResolutionDiagnostic>.unmodifiable(diagnostics);

  final ResolvedShadowConfig? resolved;
  final List<ShadowConfigResolutionDiagnostic> diagnostics;

  bool get hasShadow => resolved != null;

  bool get isNone => resolved == null;

  bool get hasDiagnostics => diagnostics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowConfigResolution &&
          other.resolved == resolved &&
          _diagnosticsEqualInOrder(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        resolved,
        Object.hashAll(diagnostics),
      );
}

enum ShadowConfigResolutionDiagnosticKind {
  missingShadowProfile,
  customOverrideWithoutBaseProfile,
}

final class ShadowConfigResolutionDiagnostic {
  const ShadowConfigResolutionDiagnostic({
    required this.kind,
    required this.shadowProfileId,
    required this.message,
  });

  final ShadowConfigResolutionDiagnosticKind kind;
  final String? shadowProfileId;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowConfigResolutionDiagnostic &&
          other.kind == kind &&
          other.shadowProfileId == shadowProfileId &&
          other.message == message;

  @override
  int get hashCode => Object.hash(
        kind,
        shadowProfileId,
        message,
      );
}

/// Resolves V0 shadow authoring data without touching maps, collision,
/// occlusion, gameplay, editor state, or runtime rendering.
ShadowConfigResolution resolveShadowConfig({
  required ProjectShadowCatalog catalog,
  required ProjectElementShadowConfig? elementShadow,
  MapPlacedElementShadowOverride? placedOverride,
}) {
  final overrideMode = placedOverride?.mode ?? ShadowOverrideMode.inherit;
  if (overrideMode == ShadowOverrideMode.disabled) {
    return ShadowConfigResolution(
      resolved: null,
      diagnostics: const [],
    );
  }

  final elementShadowActive =
      elementShadow != null && elementShadow.castsShadow;
  final isCustomOverride = overrideMode == ShadowOverrideMode.custom;
  final customProfileId =
      isCustomOverride ? placedOverride!.shadowProfileId : null;
  final profileId = customProfileId ??
      (elementShadowActive ? elementShadow.shadowProfileId : null);

  if (profileId == null) {
    if (isCustomOverride && _hasNumericCustomFields(placedOverride!)) {
      return ShadowConfigResolution(
        resolved: null,
        diagnostics: const [
          ShadowConfigResolutionDiagnostic(
            kind: ShadowConfigResolutionDiagnosticKind
                .customOverrideWithoutBaseProfile,
            shadowProfileId: null,
            message:
                'custom shadow override cannot adjust numeric fields without a base shadow profile.',
          ),
        ],
      );
    }

    return ShadowConfigResolution(
      resolved: null,
      diagnostics: const [],
    );
  }

  final profile = catalog.profileById(profileId);
  if (profile == null) {
    return ShadowConfigResolution(
      resolved: null,
      diagnostics: [
        ShadowConfigResolutionDiagnostic(
          kind: ShadowConfigResolutionDiagnosticKind.missingShadowProfile,
          shadowProfileId: profileId,
          message: 'Missing shadow profile "$profileId".',
        ),
      ],
    );
  }

  if (profile.mode == ShadowCasterMode.none) {
    return ShadowConfigResolution(
      resolved: null,
      diagnostics: const [],
    );
  }

  var offsetX = profile.offsetX;
  var offsetY = profile.offsetY;
  var scaleX = profile.scaleX;
  var scaleY = profile.scaleY;
  var opacity = profile.opacity;

  if (elementShadowActive) {
    offsetX = elementShadow.offsetX ?? offsetX;
    offsetY = elementShadow.offsetY ?? offsetY;
    scaleX = elementShadow.scaleX ?? scaleX;
    scaleY = elementShadow.scaleY ?? scaleY;
    opacity = elementShadow.opacity ?? opacity;
  }

  if (isCustomOverride) {
    final customOverride = placedOverride!;
    offsetX = customOverride.offsetX ?? offsetX;
    offsetY = customOverride.offsetY ?? offsetY;
    scaleX = customOverride.scaleX ?? scaleX;
    scaleY = customOverride.scaleY ?? scaleY;
    opacity = customOverride.opacity ?? opacity;
  }

  return ShadowConfigResolution(
    resolved: ResolvedShadowConfig(
      shadowProfileId: profile.id,
      mode: profile.mode,
      renderPass: profile.renderPass,
      offsetX: offsetX,
      offsetY: offsetY,
      scaleX: scaleX,
      scaleY: scaleY,
      opacity: opacity,
      colorHexRgb: profile.colorHexRgb,
      softnessMode: profile.softnessMode,
    ),
    diagnostics: const [],
  );
}
```

### 23.2 `packages/map_core/lib/map_core.dart`

```dart
export 'src/operations/shadow_config_resolver.dart';
```

### 23.3 `packages/map_core/test/shadow/shadow_config_resolver_test.dart`

Extraits représentatifs des tests ajoutés :

```dart
test('elementShadow null and override null yields no shadow', () {
  final resolution = resolveShadowConfig(
    catalog: _catalog([_profile('tree_large')]),
    elementShadow: null,
  );

  expect(resolution.hasShadow, isFalse);
  expect(resolution.isNone, isTrue);
  expect(resolution.resolved, isNull);
  expect(resolution.diagnostics, isEmpty);
  expect(resolution.hasDiagnostics, isFalse);
});
```

```dart
test('castsShadow true with existing profile resolves profile fields', () {
  final profile = _profile(
    'tree_large',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: 4,
    offsetY: 12,
    scaleX: 1.2,
    scaleY: 0.45,
    opacity: 0.35,
    colorHexRgb: '102030',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );

  final resolution = resolveShadowConfig(
    catalog: _catalog([profile]),
    elementShadow: ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'tree_large',
    ),
  );

  expect(
    resolution.resolved,
    const ResolvedShadowConfig(
      shadowProfileId: 'tree_large',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      offsetX: 4,
      offsetY: 12,
      scaleX: 1.2,
      scaleY: 0.45,
      opacity: 0.35,
      colorHexRgb: '102030',
      softnessMode: ShadowSoftnessMode.hardEdge,
    ),
  );
});
```

```dart
test('disabled always wins and emits no diagnostics', () {
  final resolution = resolveShadowConfig(
    catalog: _catalog([_profile('tree_large')]),
    elementShadow: ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'tree_large',
    ),
    placedOverride: MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.disabled,
    ),
  );

  expect(resolution.resolved, isNull);
  expect(resolution.hasShadow, isFalse);
  expect(resolution.diagnostics, isEmpty);
});
```

```dart
test('custom numeric overrides replace values after element overrides', () {
  final resolution = resolveShadowConfig(
    catalog: _catalog([
      _profile(
        'tree_large',
        offsetX: 1,
        offsetY: 2,
        scaleX: 3,
        scaleY: 4,
        opacity: 0.5,
      ),
    ]),
    elementShadow: ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'tree_large',
      offsetX: 10,
      offsetY: 20,
      scaleX: 0.8,
      scaleY: 0.3,
      opacity: 0.4,
    ),
    placedOverride: MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.custom,
      offsetX: 100,
      offsetY: 200,
      scaleX: 1.1,
      scaleY: 1.2,
      opacity: 0.2,
    ),
  );

  expect(resolution.resolved!.offsetX, 100);
  expect(resolution.resolved!.offsetY, 200);
  expect(resolution.resolved!.scaleX, 1.1);
  expect(resolution.resolved!.scaleY, 1.2);
  expect(resolution.resolved!.opacity, 0.2);
});
```

```dart
test('custom with profile can activate when element has no active shadow', () {
  for (final elementShadow in <ProjectElementShadowConfig?>[
    null,
    ProjectElementShadowConfig(
      castsShadow: false,
      shadowProfileId: 'tree_large',
    ),
  ]) {
    final resolution = resolveShadowConfig(
      catalog: _catalog([_profile('rock_small')]),
      elementShadow: elementShadow,
      placedOverride: MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        shadowProfileId: 'rock_small',
      ),
    );

    expect(resolution.resolved!.shadowProfileId, 'rock_small');
    expect(resolution.diagnostics, isEmpty);
  }
});
```

```dart
test('custom numeric override without base produces diagnostic', () {
  for (final elementShadow in <ProjectElementShadowConfig?>[
    null,
    ProjectElementShadowConfig(
      castsShadow: false,
      shadowProfileId: 'tree_large',
    ),
  ]) {
    final resolution = resolveShadowConfig(
      catalog: _catalog([_profile('tree_large')]),
      elementShadow: elementShadow,
      placedOverride: MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        opacity: 0.2,
      ),
    );

    expect(resolution.resolved, isNull);
    expect(
      resolution.diagnostics.single.kind,
      ShadowConfigResolutionDiagnosticKind.customOverrideWithoutBaseProfile,
    );
    expect(resolution.diagnostics.single.shadowProfileId, isNull);
    expect(resolution.diagnostics.single.message, contains('custom'));
  }
});
```
