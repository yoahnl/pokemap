# Shadow-48 — Core Auto Shadow Policy / Runtime Auto Apply V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** make the automatic shadow policy actually affect runtime-loaded projects without requiring a manual editor click, while preserving manual shadows and explicit disabled shadows.

**Architecture:** extract the pure automatic shadow suggestion/backfill policy from `map_editor` into `map_core`, keep editor compatibility wrappers, then apply the shared policy in memory when `map_runtime` loads a `ProjectManifest`. The runtime must not import `map_editor`, must not save project files, and must not mutate map data.

**Tech Stack:** Dart, Flutter tests, `map_core` pure operations, `map_runtime` project loading, existing JSON models and validators.

---

## 1. Pourquoi ce lot

Les lots 46 et 47 ont amélioré la géométrie et la politique automatique, mais ils ne règlent pas encore le problème visible si un projet contient déjà des ombres persistées ou si le runtime charge un projet qui n’a jamais reçu le backfill éditeur.

Le symptôme utilisateur actuel est cohérent :

```text
Le code sait mieux calculer les ombres.
Mais le runtime peut encore charger des configs anciennes ou absentes.
Donc l’écran peut rester visuellement mauvais.
```

Shadow-48 doit faire passer la politique automatique au bon niveau :

```text
map_core = source de vérité pure
map_editor = peut appliquer et sauvegarder
map_runtime = applique en mémoire au chargement
```

## 2. Décision produit

Recommandation retenue : appliquer automatiquement la politique au runtime en mémoire.

Conséquences :

- un projet ouvert dans le runtime bénéficie des nettoyages Shadow-47 sans action manuelle ;
- les petites ombres auto reconnues sont retirées ;
- les éléments éligibles sans shadow config reçoivent une config auto en mémoire ;
- les ombres manuelles et `castsShadow: false` sont conservées ;
- aucune sauvegarde runtime ;
- aucun couplage `map_runtime -> map_editor`.

Ce lot ne promet pas encore des ombres Pokémon finales pour chaque asset. Il retire surtout la pollution automatique et rend la politique réellement active dans le runtime. Les lots suivants pourront travailler la calibration visuelle par famille/asset.

## 3. Flame docs

`flame_docs` a été consulté pour éviter d’inventer une intégration Flame.

Recherches lancées :

```text
Flame GameWidget rendering screenshot testing components render order priority canvas
Flame component priority render order
components priority
```

Résultat : aucun résultat exploitable retourné par le serveur pour ces requêtes.

Décision : Shadow-48 ne touche pas aux APIs Flame, aux `Component`, au render order, au canvas, ni au `GameWidget`. Le branchement se fait avant Flame, au niveau du chargement du manifest runtime (`load_runtime_map_bundle.dart`), ce qui respecte les frontières PokeMap.

## 4. Périmètre autorisé

Créer :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart
packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
reports/shadows/shadow_lot_48_core_auto_shadow_policy_runtime_auto_apply.md
```

Modifier :

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
packages/map_editor/test/application/shadow/element_auto_shadow_suggestion_test.dart
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
```

Modifier seulement si nécessaire après audit :

```text
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
```

## 5. Périmètre interdit

Ne pas modifier :

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
packages/map_editor/lib/src/ui/canvas/**
packages/map_runtime/lib/src/presentation/flame/**
packages/map_gameplay/**
packages/map_battle/**
examples/playable_runtime_host/golden_battle_slice/**
```

Ne pas créer :

```text
nouveau Flame Component
nouveau renderer
Shadow Studio
lumière globale
time-of-day
saveLayer
ImageFilter
blur
sprite shadow atlas
zOrder / zIndex
build_runner
migration JSON destructive
```

Ne pas faire :

```text
runtime save project.json
runtime mutate MapData
map_runtime import package:map_editor
map_core import Flutter ou Flame
```

## 6. API core recommandée

Créer dans `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart` :

```dart
enum ElementAutoShadowSuggestionKind {
  tallThin,
  buildingLarge,
  wideLow,
  smallSquare,
  defaultProp,
}

enum ElementAutoShadowBackfillStatus {
  appliedMissing,
  appliedGeneric,
  skippedDisabled,
  skippedManual,
  skippedNoSuggestion,
  clearedAutoNoSuggestion,
}

final class ElementAutoShadowSuggestion {
  const ElementAutoShadowSuggestion({
    required this.kind,
    required this.config,
    required this.summary,
  });

  final ElementAutoShadowSuggestionKind kind;
  final ProjectElementShadowConfig config;
  final String summary;
}

final class ElementAutoShadowBackfillEntry {
  const ElementAutoShadowBackfillEntry({
    required this.elementId,
    required this.elementName,
    required this.status,
    this.suggestionKind,
  });

  final String elementId;
  final String elementName;
  final ElementAutoShadowBackfillStatus status;
  final ElementAutoShadowSuggestionKind? suggestionKind;
}

final class ElementAutoShadowBackfillResult {
  const ElementAutoShadowBackfillResult({
    required this.project,
    required this.entries,
    required this.addedDefaultProfiles,
  });

  final ProjectManifest project;
  final List<ElementAutoShadowBackfillEntry> entries;
  final bool addedDefaultProfiles;

  int get appliedCount;
  int get clearedCount;
  int get changedCount;
  int get skippedCount;
  bool get hasChanges;
}

ElementAutoShadowSuggestion? buildElementAutoShadowSuggestion({
  required ProjectElementEntry element,
  required ProjectShadowCatalog shadowCatalog,
});

ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
  ProjectManifest project,
);
```

Nom volontaire : `applyElementAutoShadowPolicyToProject`, pas seulement `Suggestions`, car la fonction applique aussi le nettoyage `clearedAutoNoSuggestion`.

## 7. Compatibilité editor

Les fichiers editor existants doivent devenir des wrappers de compatibilité :

```dart
export 'package:map_core/map_core.dart'
    show
        ElementAutoShadowSuggestionKind,
        ElementAutoShadowSuggestion,
        buildElementAutoShadowSuggestion;
```

et :

```dart
export 'package:map_core/map_core.dart'
    show
        ElementAutoShadowBackfillStatus,
        ElementAutoShadowBackfillEntry,
        ElementAutoShadowBackfillResult,
        applyElementAutoShadowPolicyToProject;

import 'package:map_core/map_core.dart';

ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
  ProjectManifest project,
) {
  return applyElementAutoShadowPolicyToProject(project);
}
```

Pourquoi garder `applyElementAutoShadowSuggestionsToProject` côté editor :

- éviter de casser les imports existants ;
- limiter le diff UI ;
- permettre une migration progressive des tests.

## 8. Runtime auto-apply

Modifier `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`.

Dans `loadProjectManifestFromFile`, après decode/migration et avant retour :

```dart
final manifest = ProjectManifest.fromJson(migrated);
final normalized = applyElementAutoShadowPolicyToProject(manifest).project;
ProjectValidator.validate(normalized);
return normalized;
```

Règles :

- ne pas écrire sur disque ;
- ne pas changer le chemin du projet ;
- ne pas modifier `loadMapDataFromFile` ;
- ne pas modifier le runtime Flame ;
- préserver les validations existantes ;
- si la politique ajoute les profils par défaut, ils existent seulement en mémoire côté runtime.

## 9. Tâches détaillées

### Task 1 — RED core policy tests

**Files:**

- Create: `packages/map_core/test/shadow/element_auto_shadow_policy_test.dart`

- [ ] Écrire les tests qui couvrent les comportements déjà validés côté editor :

```dart
test('small square and default prop return null', () {
  expect(
    buildElementAutoShadowSuggestion(
      element: _element(width: 2, height: 2),
      shadowCatalog: _defaultCatalog(),
    ),
    isNull,
  );
  expect(
    buildElementAutoShadowSuggestion(
      element: _element(width: 2, height: 3),
      shadowCatalog: _defaultCatalog(),
    ),
    isNull,
  );
});

test('wide low needs enough surface', () {
  expect(
    buildElementAutoShadowSuggestion(
      element: _element(width: 3, height: 2),
      shadowCatalog: _defaultCatalog(),
    ),
    isNull,
  );
  final suggestion = buildElementAutoShadowSuggestion(
    element: _element(width: 4, height: 2),
    shadowCatalog: _defaultCatalog(),
  );
  expect(suggestion!.kind, ElementAutoShadowSuggestionKind.wideLow);
});

test('backfill clears recognized old auto shadows without suggestion', () {
  final result = applyElementAutoShadowPolicyToProject(
    _project(
      elements: [
        _element(
          id: 'small',
          width: 2,
          height: 2,
          shadow: _oldAutoSmallSquareShadow(),
        ),
      ],
      shadowCatalog: _defaultCatalog(),
    ),
  );
  expect(result.changedCount, 1);
  expect(result.clearedCount, 1);
  expect(result.entries.single.status,
      ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion);
  expect(result.project.elements.single.shadow, isNull);
});

test('manual and disabled shadows are preserved', () {
  final manual = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'custom-ground-shadow',
  );
  final disabled = ProjectElementShadowConfig(castsShadow: false);
  final result = applyElementAutoShadowPolicyToProject(
    _project(
      elements: [
        _element(id: 'manual', width: 2, height: 2, shadow: manual),
        _element(id: 'disabled', width: 4, height: 3, shadow: disabled),
      ],
      shadowCatalog: ProjectShadowCatalog(
        profiles: [
          ...createDefaultGroundStaticShadowProfiles(),
          ProjectShadowProfile(
            id: 'custom-ground-shadow',
            name: 'Custom ground shadow',
            mode: ShadowCasterMode.ellipse,
            renderPass: ShadowRenderPass.groundStatic,
          ),
        ],
      ),
    ),
  );
  expect(result.changedCount, 0);
  expect(result.project.elements[0].shadow, manual);
  expect(result.project.elements[1].shadow, disabled);
});
```

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
```

Expected: fail because the core API does not exist.

### Task 2 — Implement core policy

**Files:**

- Create: `packages/map_core/lib/src/operations/element_auto_shadow_policy.dart`
- Modify: `packages/map_core/lib/map_core.dart`

- [ ] Move the current pure implementation from:

```text
packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
```

into `map_core`.

- [ ] Keep exactly the Shadow-47 policy:

```text
micro decor 1x1 / 1x2 -> null
smallSquare -> null
defaultProp -> null
wideLow -> only if width >= 4 OR width * height >= 10
tallThin -> auto
buildingLarge -> auto
```

- [ ] Add `clearedCount`:

```dart
int get clearedCount => entries
    .where((entry) =>
        entry.status == ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion)
    .length;
```

- [ ] Export from `packages/map_core/lib/map_core.dart`:

```dart
export 'src/operations/element_auto_shadow_policy.dart';
```

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
cd packages/map_core && dart analyze lib test/shadow
```

Expected: pass.

### Task 3 — Editor compatibility wrappers

**Files:**

- Modify: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_suggestion.dart`
- Modify: `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`
- Modify tests only if imports need cleanup.

- [ ] Replace the implementation files with wrapper exports.

- [ ] Preserve the old editor function name:

```dart
ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
  ProjectManifest project,
) {
  return applyElementAutoShadowPolicyToProject(project);
}
```

- [ ] Run:

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
```

Expected: pass with no UI changes.

### Task 4 — Runtime in-memory auto policy

**Files:**

- Modify: `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- Create: `packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart`

- [ ] Write RED tests:

```dart
test('loadProjectManifestFromFile clears recognized obsolete auto shadows in memory',
    () async {
  final root = await Directory.systemTemp.createTemp('runtime_shadow_policy_');
  addTearDown(() => root.delete(recursive: true));
  final manifestPath = p.join(root.path, 'project.json');
  await File(manifestPath).writeAsString(jsonEncode(
    _project(
      elements: [
        _element(
          id: 'small',
          width: 2,
          height: 2,
          shadow: _oldAutoSmallSquareShadow(),
        ),
      ],
      shadowCatalog: _defaultCatalog(),
    ).toJson(),
  ));

  final manifest = await loadProjectManifestFromFile(manifestPath);

  expect(manifest.elements.single.shadow, isNull);
});
```

```dart
test('loadProjectManifestFromFile applies eligible missing auto shadows in memory',
    () async {
  final root = await Directory.systemTemp.createTemp('runtime_shadow_policy_');
  addTearDown(() => root.delete(recursive: true));
  final manifestPath = p.join(root.path, 'project.json');
  await File(manifestPath).writeAsString(jsonEncode(
    _project(
      elements: [
        _element(id: 'lamp', width: 1, height: 4),
      ],
      shadowCatalog: const ProjectShadowCatalog.empty(),
    ).toJson(),
  ));

  final manifest = await loadProjectManifestFromFile(manifestPath);

  expect(manifest.elements.single.shadow, isNotNull);
  expect(
    manifest.elements.single.shadow!.shadowProfileId,
    'default-ground-contact-blob',
  );
});
```

```dart
test('loadProjectManifestFromFile preserves manual and disabled shadows',
    () async {
  final manual = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'custom-ground-shadow',
  );
  final disabled = ProjectElementShadowConfig(castsShadow: false);
  final root = await Directory.systemTemp.createTemp('runtime_shadow_policy_');
  addTearDown(() => root.delete(recursive: true));
  final manifestPath = p.join(root.path, 'project.json');
  await File(manifestPath).writeAsString(jsonEncode(
    _project(
      elements: [
        _element(id: 'manual', width: 2, height: 2, shadow: manual),
        _element(id: 'disabled', width: 4, height: 3, shadow: disabled),
      ],
      shadowCatalog: ProjectShadowCatalog(
        profiles: [
          ...createDefaultGroundStaticShadowProfiles(),
          ProjectShadowProfile(
            id: 'custom-ground-shadow',
            name: 'Custom ground shadow',
            mode: ShadowCasterMode.ellipse,
            renderPass: ShadowRenderPass.groundStatic,
          ),
        ],
      ),
    ).toJson(),
  ));

  final manifest = await loadProjectManifestFromFile(manifestPath);

  expect(manifest.elements[0].shadow, manual);
  expect(manifest.elements[1].shadow, disabled);
});
```

- [ ] Run RED:

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
```

Expected: fail until `loadProjectManifestFromFile` applies the core policy.

- [ ] Implement:

```dart
final manifest = ProjectManifest.fromJson(migrated);
final normalized = applyElementAutoShadowPolicyToProject(manifest).project;
ProjectValidator.validate(normalized);
return normalized;
```

- [ ] Run GREEN:

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
cd packages/map_runtime && flutter analyze lib/src/application test/application
```

Expected: pass.

### Task 5 — Editor status message for cleanups

**Files:**

- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify: `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`

- [ ] Add a test where an old auto shadow is cleared and the editor reports a cleanup.

Expected message:

```text
Ombres automatiques mises à jour : 0 appliquée(s), 1 retirée(s).
```

- [ ] Update `applyElementAutoShadowSuggestions()` status logic:

```dart
final applied = result.appliedCount;
final cleared = result.clearedCount;
state = state.copyWith(
  project: result.project,
  statusMessage:
      'Ombres automatiques mises à jour : $applied appliquée(s), $cleared retirée(s).',
  errorMessage: null,
);
```

- [ ] Preserve no-op message:

```text
Aucune ombre automatique à appliquer.
```

- [ ] Run:

```bash
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
```

Expected: pass.

### Task 6 — Regression matrix

Run all targeted checks:

```bash
cd packages/map_core && dart test test/shadow/element_auto_shadow_policy_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow

cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/features/editor/state test/application/shadow test/features/tileset_library test/editor_notifier_project_dirty_state_test.dart

cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/application test/application test/shadow
```

Optional broader smoke if time allows:

```bash
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
```

### Task 7 — Anti-drift scans

Run:

```bash
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core \
  | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas|package:map_editor"
git diff --check
git status --short --untracked-files=all
```

Expected for Shadow-48:

```text
No map_battle/map_gameplay changes from this lot.
No model/codec/generated changes from this lot.
No advanced renderer/lights/import map_editor in runtime.
git diff --check no output.
```

If the worktree already contains unrelated files, document them in the report instead of touching them.

### Task 8 — Report

**File:**

- Create: `reports/shadows/shadow_lot_48_core_auto_shadow_policy_runtime_auto_apply.md`

Include:

1. Résumé du lot
2. Pourquoi Shadow-47 ne suffisait pas
3. Design retenu
4. Fichiers créés
5. Fichiers modifiés
6. Fichiers hors lot préexistants
7. API core extraite
8. Runtime in-memory auto apply
9. Editor compatibility wrappers
10. Status message cleanup
11. Flame docs consultées
12. Tests ajoutés/modifiés
13. Commandes lancées
14. Résultats complets utiles des tests ciblés
15. Résultats des tests globaux ciblés
16. Analyse
17. Scans anti-dérive
18. git status initial/final
19. git diff --stat
20. Non-objectifs respectés
21. Risques / réserves
22. Auto-review finale
23. Contenu complet des fichiers créés/modifiés
24. Diff complet ciblé Shadow-48

## 10. Critères d’acceptation

Shadow-48 est réussi si :

- `map_core` possède la politique auto-shadow pure ;
- `map_editor` utilise encore les anciens imports sans casser ;
- `map_runtime` applique la politique en mémoire au chargement manifest ;
- le runtime ne sauvegarde rien ;
- les petites anciennes ombres auto reconnues sont retirées au runtime ;
- les éléments éligibles sans shadow reçoivent une shadow auto au runtime ;
- les ombres manuelles et disabled sont préservées ;
- aucun modèle/codec/generated modifié ;
- aucun Flame component/render order modifié ;
- tests ciblés verts ;
- analyse ciblée verte ;
- rapport complet créé ;
- aucun commit.

## 11. Estimation

Lot de taille moyenne, 1 session raisonnable :

```text
Task 1-2 core extraction: 35-60 min
Task 3 editor wrappers: 15-25 min
Task 4 runtime auto apply: 25-40 min
Task 5 status message: 15-25 min
Task 6-8 validation/report: 25-45 min
```

Total estimé : 2h à 3h selon l’état du worktree et les tests Flutter.

## 12. Ce que ça devrait changer visuellement

Sur Selbrume/runtime :

- les petits carrés/losanges d’ombre automatiques déjà reconnus devraient disparaître sans clic éditeur ;
- les lampadaires et grands bâtiments devraient garder des ombres plus sobres ;
- les ombres manuelles resteront telles quelles ;
- les artefacts non reconnus comme auto devront encore être traités par un lot de calibration ou d’audit asset.

Shadow-48 devrait donc produire un vrai changement perceptible, mais il ne transforme pas encore chaque bâtiment en silhouette Pokémon parfaite.
