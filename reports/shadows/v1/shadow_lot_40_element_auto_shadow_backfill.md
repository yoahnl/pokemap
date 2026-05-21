# Shadow-40 — Element Auto Shadow Backfill V0

## 1. Résumé

Shadow-40 ajoute une action explicite `Ombres auto` dans le panneau de palette d’éléments. Cette action applique les suggestions automatiques Shadow-39 aux éléments sources existants, sans modifier le runtime, le canvas éditeur, `map_core`, les modèles persistants ou les codecs JSON.

Le lot ajoute :

- un helper pur `applyElementAutoShadowSuggestionsToProject(...)` ;
- un use case de sauvegarde via `ProjectRepository` ;
- une méthode `EditorNotifier.applyElementAutoShadowSuggestions()` ;
- un bouton compact `Ombres auto` avec confirmation ;
- des tests ciblés pour les règles de backfill, la sauvegarde, le notifier et le câblage UI.

Limite produit honnête : Shadow-40 ne crée pas encore les silhouettes Pokémon finales. Il rend surtout les améliorations Shadow-39 applicables en masse aux éléments existants.

## 2. Fichiers créés par Shadow-40

- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`
- `packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`
- `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`
- `packages/map_editor/test/tileset_palette_element_auto_shadow_backfill_test.dart`
- `reports/shadows/shadow_lot_40_element_auto_shadow_backfill.md`

## 3. Fichiers modifiés par Shadow-40

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`

## 4. Fichiers préexistants modifiés ou non suivis hors Shadow-40

Présents dès le début de Shadow-40 :

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_40_element_auto_shadow_backfill_plan.md
```

Apparus dans le worktree pendant la session mais non créés par Shadow-40 :

```text
?? reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md
?? reports/analysis/psdk_fight_parity_audit_2026-05-16.md
```

## 5. Règles de backfill

Une suggestion est appliquée si :

- `element.shadow == null` ;
- ou si l’ombre existante ressemble à une ancienne config générique pré-footprint :
  - `castsShadow == true` ;
  - `footprint == null` ;
  - `offsetX`, `offsetY`, `scaleX`, `scaleY`, `opacity` sont `null` ;
  - `shadowProfileId` est `null`, un id default ground-static connu, ou un id absent du catalogue.

Un élément est préservé si :

- l’ombre est désactivée ;
- un footprint manuel existe ;
- un override numérique manuel existe ;
- un profil custom existant est référencé ;
- aucune suggestion valide ne peut être construite.

Les profils par défaut ground-static sont ajoutés via `ensureDefaultGroundStaticShadowProfilesForProject(...)` avant le calcul, seulement si le catalogue ne possède pas déjà de profil compatible.

## 6. UI et sauvegarde

Le bouton `Ombres auto` est visible dans l’en-tête `Éléments à placer` et aussi dans l’état fallback `Tileset image unavailable`, afin que l’action reste accessible même si l’image du tileset n’est pas chargeable.

La confirmation affiche :

```text
Appliquer les ombres automatiques aux éléments ?
```

Puis appelle :

```dart
await notifier.applyElementAutoShadowSuggestions();
```

Le use case sauvegarde uniquement si `result.hasChanges == true`.

## 7. Tests ajoutés ou modifiés

Ajoutés :

- `element_auto_shadow_backfill_test.dart`
- `apply_element_auto_shadow_suggestions_use_case_test.dart`
- `tileset_palette_element_auto_shadow_backfill_test.dart`

Modifié :

- `editor_notifier_project_dirty_state_test.dart`

Note honnête : un test widget complet avec clic sur la boîte de dialogue macOS a été tenté, mais le `TilesetPalettePanel` complet bloque dans ce contexte de test autour de son chargement asynchrone existant. La couverture UI retenue vérifie donc le câblage source du bouton et de l’appel notifier ; le comportement réel d’application et de sauvegarde est couvert par les tests notifier/use case.

## 8. Commandes et résultats

### Tests ciblés Shadow-40

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_backfill_test.dart
```

```text
00:00 +0: applyElementAutoShadowSuggestionsToProject applies suggestions to elements without shadow configs
00:00 +1: applyElementAutoShadowSuggestionsToProject replaces generic pre-footprint active shadows
00:00 +2: applyElementAutoShadowSuggestionsToProject preserves disabled shadows
00:00 +3: applyElementAutoShadowSuggestionsToProject preserves manual footprints and numeric overrides
00:00 +4: applyElementAutoShadowSuggestionsToProject preserves non-default existing profile ids present in catalog
00:00 +5: applyElementAutoShadowSuggestionsToProject replaces generic shadows with missing profile ids
00:00 +6: applyElementAutoShadowSuggestionsToProject adds default profiles when the catalog has no compatible profile
00:00 +7: applyElementAutoShadowSuggestionsToProject records skippedNoSuggestion for invalid element frames
00:00 +8: applyElementAutoShadowSuggestionsToProject preserves element order and non-shadow fields
00:00 +9: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/application/shadow/element_auto_shadow_suggestion_test.dart
```

```text
00:00 +14: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
```

```text
00:00 +0: ApplyElementAutoShadowSuggestionsUseCase saves when at least one element changes
00:00 +1: ApplyElementAutoShadowSuggestionsUseCase does not save when no element is eligible
00:00 +2: ApplyElementAutoShadowSuggestionsUseCase returns counts and saves projects that round trip through JSON
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
```

```text
00:00 +11: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/tileset_palette_element_auto_shadow_backfill_test.dart
```

```text
00:00 +0: TilesetPalettePanel wires the Ombres auto action to EditorNotifier
00:00 +1: All tests passed!
```

### Suites élargies

```bash
cd packages/map_editor && flutter test test/application/shadow
```

```text
00:01 +86: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/features/tileset_library
```

```text
00:03 +48: All tests passed!
```

### Analyse

Commande large demandée :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/application/use_cases lib/src/features/editor/state lib/src/ui/panels/tileset_palette_panel.dart test/application/shadow test/features/tileset_library test/editor_notifier_project_dirty_state_test.dart test/tileset_palette_element_auto_shadow_backfill_test.dart
```

Résultat :

```text
info • The variable name 'updated_table' isn't a lowerCamelCase identifier • lib/src/application/use_cases/encounter_table_use_cases.dart:90:11 • non_constant_identifier_names
info • The variable name 'updated_table' isn't a lowerCamelCase identifier • lib/src/application/use_cases/encounter_table_use_cases.dart:171:11 • non_constant_identifier_names
info • The variable name 'updated_entry' isn't a lowerCamelCase identifier • lib/src/application/use_cases/encounter_table_use_cases.dart:225:11 • non_constant_identifier_names
info • The variable name 'updated_table' isn't a lowerCamelCase identifier • lib/src/application/use_cases/encounter_table_use_cases.dart:233:11 • non_constant_identifier_names
info • The variable name 'updated_table' isn't a lowerCamelCase identifier • lib/src/application/use_cases/encounter_table_use_cases.dart:267:11 • non_constant_identifier_names
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
6 issues found. (ran in 3.0s)
```

Interprétation : dette préexistante hors Shadow-40, située dans des use cases Pokémon SDK / Encounter Tables non modifiés par ce lot.

Analyse ciblée Shadow-40 :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow/element_auto_shadow_backfill.dart lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tileset_palette_panel.dart test/application/shadow/element_auto_shadow_backfill_test.dart test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart test/editor_notifier_project_dirty_state_test.dart test/tileset_palette_element_auto_shadow_backfill_test.dart
```

```text
No issues found! (ran in 1.3s)
```

### map_core guards

```bash
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart
```

```text
00:00 +6: All tests passed!
```

```bash
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
```

```text
00:00 +19: All tests passed!
```

```bash
cd packages/map_core && dart analyze lib test/shadow
```

```text
Analyzing lib, shadow...
No issues found!
```

## 9. Scans anti-dérive

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat : aucune sortie.

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Résultat : aucune sortie.

```bash
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
```

Résultat :

```text
4:packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Interprétation : sortie due aux fichiers Shadow-38 préexistants, pas à Shadow-40.

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Résultat :

```text
357:-    canvas.drawOval(
375:+        canvas.drawOval(
389:+          canvas.drawPath(path, paint);
```

Interprétation : sortie due aux diffs Shadow-38 préexistants dans le painter canvas, pas à Shadow-40.

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Résultat : aucune sortie.

```bash
git diff --check
```

Résultat : aucune sortie, exit code 0.

## 10. git status initial

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_40_element_auto_shadow_backfill_plan.md
```

## 11. git status final

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart
?? packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart
?? packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart
?? packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
?? packages/map_editor/test/tileset_palette_element_auto_shadow_backfill_test.dart
?? reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md
?? reports/analysis/psdk_fight_parity_audit_2026-05-16.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
?? reports/shadows/shadow_lot_40_element_auto_shadow_backfill.md
?? reports/shadows/shadow_lot_40_element_auto_shadow_backfill_plan.md
```

## 12. git diff --stat

```text
 AGENTS.md                                          | 1289 ++++++++++++--------
 .../shadow/editor_static_shadow_preview.dart       |  285 ++++-
 .../src/features/editor/state/editor_notifier.dart |   36 +
 .../editor_static_shadow_preview_painter.dart      |   54 +-
 .../lib/src/ui/panels/tileset_palette_panel.dart   |   37 +
 .../shadow/editor_static_shadow_preview_test.dart  |  390 +++++-
 .../editor_notifier_project_dirty_state_test.dart  |  174 +++
 .../editor_static_shadow_preview_painter_test.dart |   69 +-
 8 files changed, 1681 insertions(+), 653 deletions(-)
```

Note : les fichiers créés par Shadow-40 sont encore non suivis, donc absents de `git diff --stat`.

## 13. Code complet des fichiers créés

### `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_suggestion.dart';

enum ElementAutoShadowBackfillStatus {
  appliedMissing,
  appliedGeneric,
  skippedDisabled,
  skippedManual,
  skippedNoSuggestion,
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ElementAutoShadowBackfillEntry &&
            elementId == other.elementId &&
            elementName == other.elementName &&
            status == other.status &&
            suggestionKind == other.suggestionKind;
  }

  @override
  int get hashCode => Object.hash(
        elementId,
        elementName,
        status,
        suggestionKind,
      );
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

  int get appliedCount => entries
      .where(
        (entry) =>
            entry.status == ElementAutoShadowBackfillStatus.appliedMissing ||
            entry.status == ElementAutoShadowBackfillStatus.appliedGeneric,
      )
      .length;

  int get skippedCount => entries.length - appliedCount;

  bool get hasChanges => addedDefaultProfiles || appliedCount > 0;
}

ElementAutoShadowBackfillResult applyElementAutoShadowSuggestionsToProject(
  ProjectManifest project,
) {
  final projectWithDefaults =
      ensureDefaultGroundStaticShadowProfilesForProject(project);
  final addedDefaultProfiles = projectWithDefaults != project;
  final entries = <ElementAutoShadowBackfillEntry>[];
  final elements = <ProjectElementEntry>[];

  for (final element in projectWithDefaults.elements) {
    final currentShadow = element.shadow;
    if (currentShadow != null && !currentShadow.castsShadow) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedDisabled),
      );
      elements.add(element);
      continue;
    }
    if (currentShadow != null &&
        !_canReplaceExistingShadow(
          currentShadow,
          projectWithDefaults.shadowCatalog,
        )) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedManual),
      );
      elements.add(element);
      continue;
    }

    final suggestion = buildElementAutoShadowSuggestion(
      element: element,
      shadowCatalog: projectWithDefaults.shadowCatalog,
    );
    if (suggestion == null) {
      entries.add(
        _entry(element, ElementAutoShadowBackfillStatus.skippedNoSuggestion),
      );
      elements.add(element);
      continue;
    }

    final status = currentShadow == null
        ? ElementAutoShadowBackfillStatus.appliedMissing
        : ElementAutoShadowBackfillStatus.appliedGeneric;
    entries.add(
      _entry(
        element,
        status,
        suggestionKind: suggestion.kind,
      ),
    );
    elements.add(element.copyWith(shadow: suggestion.config));
  }

  return ElementAutoShadowBackfillResult(
    project: addedDefaultProfiles ||
            entries.any(
              (entry) =>
                  entry.status ==
                      ElementAutoShadowBackfillStatus.appliedMissing ||
                  entry.status ==
                      ElementAutoShadowBackfillStatus.appliedGeneric,
            )
        ? projectWithDefaults.copyWith(elements: elements)
        : project,
    entries: entries,
    addedDefaultProfiles: addedDefaultProfiles,
  );
}

ElementAutoShadowBackfillEntry _entry(
  ProjectElementEntry element,
  ElementAutoShadowBackfillStatus status, {
  ElementAutoShadowSuggestionKind? suggestionKind,
}) {
  return ElementAutoShadowBackfillEntry(
    elementId: element.id,
    elementName: element.name,
    status: status,
    suggestionKind: suggestionKind,
  );
}

bool _canReplaceExistingShadow(
  ProjectElementShadowConfig shadow,
  ProjectShadowCatalog catalog,
) {
  if (!shadow.castsShadow) {
    return false;
  }
  if (shadow.footprint != null) {
    return false;
  }
  if (shadow.offsetX != null ||
      shadow.offsetY != null ||
      shadow.scaleX != null ||
      shadow.scaleY != null ||
      shadow.opacity != null) {
    return false;
  }

  final profileId = shadow.shadowProfileId;
  if (profileId == null) {
    return true;
  }
  if (_defaultGroundStaticProfileIds.contains(profileId)) {
    return true;
  }
  return catalog.profileById(profileId) == null;
}

const _defaultGroundStaticProfileIds = <String>{
  'default-ground-soft-ellipse',
  'default-ground-wide-ellipse',
  'default-ground-contact-blob',
};
```

### `packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

final class ApplyElementAutoShadowSuggestionsUseCase {
  ApplyElementAutoShadowSuggestionsUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ElementAutoShadowBackfillResult> execute(
    ProjectWorkspace workspace,
    ProjectManifest project,
  ) async {
    final result = applyElementAutoShadowSuggestionsToProject(project);
    if (result.hasChanges) {
      await _repo.saveProject(result.project, workspace.projectManifestPath);
    }
    return result;
  }
}
```

### `packages/map_editor/test/tileset_palette_element_auto_shadow_backfill_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TilesetPalettePanel wires the Ombres auto action to EditorNotifier',
      () {
    final source = File(
      'lib/src/ui/panels/tileset_palette_panel.dart',
    ).readAsStringSync();

    expect(source, contains("child: const Text('Ombres auto')"));
    expect(source, contains('element-auto-shadow-backfill-button'));
    expect(
      source,
      contains('Appliquer les ombres automatiques aux éléments ?'),
    );
    expect(
      source,
      contains('await notifier.applyElementAutoShadowSuggestions();'),
    );
  });
}
```

Fichiers de tests créés additionnels :

- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`
- `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`

## 14. Diff complet des fichiers modifiés par Shadow-40

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index b88ac348..20b102b9 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -13,6 +13,7 @@ import '../../../app/providers/core_providers.dart';
 import '../../../app/providers/editor_workspace_providers.dart';
 import '../../../app/providers/use_case_providers.dart';
 import '../../../application/errors/application_errors.dart';
+import '../../../application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart';
 import '../../../application/use_cases/environment_generator_apply_use_cases.dart';
@@ -464,6 +465,41 @@ class EditorNotifier extends _$EditorNotifier {
     return updated;
   }
 
+  Future<void> applyElementAutoShadowSuggestions() async {
+    final fs = _projectWorkspace;
+    final project = state.project;
+    if (fs == null || project == null) {
+      state = state.copyWith(
+        errorMessage: 'No project open to update element shadows.',
+      );
+      return;
+    }
+    try {
+      final useCase = ApplyElementAutoShadowSuggestionsUseCase(
+        ref.read(projectRepositoryProvider),
+      );
+      final result = await useCase.execute(fs, project);
+      if (!result.hasChanges) {
+        state = state.copyWith(
+          statusMessage: 'Aucune ombre automatique à appliquer.',
+          errorMessage: null,
+        );
+        return;
+      }
+      state = state.copyWith(
+        project: result.project,
+        statusMessage:
+            'Ombres automatiques appliquées à ${result.appliedCount} éléments.',
+        errorMessage: null,
+      );
+      _resyncPlacedElementsForActiveMapFromProject();
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Failed to apply automatic element shadows: $e',
+      );
+    }
+  }
```

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
index 15b09ccf..5a0bae53 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
@@ -382,6 +382,17 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
+                const SizedBox(height: 12),
+                PushButton(
+                  key: const ValueKey('element-auto-shadow-backfill-button'),
+                  controlSize: ControlSize.small,
+                  secondary: true,
+                  onPressed: () => _showApplyElementAutoShadowsDialog(
+                    context,
+                    notifier: notifier,
+                  ),
+                  child: const Text('Ombres auto'),
+                ),
@@ -1237,6 +1248,17 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
+                const SizedBox(width: 8),
+                PushButton(
+                  key: const ValueKey('element-auto-shadow-backfill-button'),
+                  controlSize: ControlSize.small,
+                  secondary: true,
+                  onPressed: () => _showApplyElementAutoShadowsDialog(
+                    context,
+                    notifier: notifier,
+                  ),
+                  child: const Text('Ombres auto'),
+                ),
@@ -2903,6 +2925,21 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
+  Future<void> _showApplyElementAutoShadowsDialog(
+    BuildContext context, {
+    required EditorNotifier notifier,
+  }) async {
+    final shouldApply = await showMacosEditorTwoChoiceAlert(
+      context,
+      title: 'Appliquer les ombres automatiques aux éléments ?',
+      message:
+          'Les éléments sans ombre ou avec une ancienne ombre générique recevront une empreinte automatique. Les ombres manuelles et désactivées seront conservées.',
+      primaryLabel: 'Appliquer',
+    );
+    if (!shouldApply) return;
+    await notifier.applyElementAutoShadowSuggestions();
+  }
```

## 15. Non-objectifs respectés

- Aucun `packages/map_runtime/**` modifié.
- Aucun `packages/map_gameplay/**` modifié.
- Aucun `packages/map_battle/**` modifié.
- Aucun modèle ou codec `map_core` modifié.
- Aucun build_runner lancé.
- Aucun nouveau modèle de lumière globale.
- Aucun changement de renderer/canvas par Shadow-40.

## 16. Risques et réserves

- Le test UI complet avec interaction de dialogue n’est pas conservé car le panneau complet bloque en test widget dans ce contexte. La logique d’action est néanmoins couverte par le notifier, le use case et un test de câblage source.
- Shadow-40 applique des heuristiques Shadow-39 ; il améliore les éléments existants mais ne remplace pas les futurs lots de silhouettes/familles d’ombres.
- Les sorties anti-dérive canvas restent polluées par les changements Shadow-38 préexistants.

## 17. Auto-review

- Ai-je ajouté un backfill pur ? oui.
- Ai-je appliqué les suggestions aux éléments sans ombre ? oui.
- Ai-je remplacé les anciennes ombres génériques pré-footprint ? oui.
- Ai-je préservé les ombres désactivées ? oui.
- Ai-je préservé les footprints et overrides numériques manuels ? oui.
- Ai-je ajouté une action explicite plutôt qu’une mutation silencieuse au chargement ? oui.
- Ai-je sauvegardé via `ProjectRepository` seulement si changement ? oui.
- Ai-je évité runtime/gameplay/battle ? oui.
- Ai-je évité modèles/codecs core ? oui.
- Ai-je évité canvas/painter dans Shadow-40 ? oui.
- Ai-je documenté les dettes hors lot ? oui.

## 18. Regard critique sur le prompt

Le plan était bon pour débloquer l’amélioration visible sans mutation silencieuse. Le seul point discutable est l’exigence d’un test widget complet sur `TilesetPalettePanel` : ce panneau a déjà un chargement asynchrone d’image qui rend le test d’interaction fragile dans ce contexte. Une future amélioration serait d’extraire les actions d’en-tête de la palette dans un petit widget testable sans charger le tileset complet.
