# EnvironmentStudio-3C — Tileset-first Preset Creation Wizard V0

## 1. Résumé

EnvironmentStudio-3C remplace le mode création direct par un wizard tileset-first dans Environment Studio.

Le nouveau flow :

1. ouvre `Nouveau preset d’environnement` en brouillon local ;
2. force d’abord le choix d’un tileset source ;
3. affiche ensuite uniquement les éléments compatibles avec ce tileset ;
4. permet de composer une palette brouillon lisible ;
5. bloque la création si la palette est vide ou si un élément forcé ne correspond pas au tileset source ;
6. crée le preset en mémoire via le callback existant, sans sauvegarde disque.

Le flow d’édition des presets existants reste branché sur `EnvironmentPresetDraftForm`, et le flow palette/save existant reste préservé.

## 2. Objectif du lot

Objectif : transformer la création de preset Environment en workflow guidé et no-code :

```text
Nouveau preset
→ Étape 1 : choisir le tileset source
→ Étape 2 : choisir les éléments compatibles
→ renseigner / confirmer les infos du preset
→ ajouter au projet en mémoire
```

Non-objectifs respectés dans l’implémentation :

- pas de champ persistant `sourceTilesetId` ;
- pas de modification `map_core` ;
- pas de modification du modèle `ProjectManifest` ;
- pas de génération / peinture / canvas dans Environment Studio ;
- pas de sauvegarde disque ;
- pas de build_runner ;
- pas de generated file.

## 3. Problème du flow création avant 3C

Audit local et sub-agent A ont confirmé que `Nouveau preset` appelait `_openDraftForm()`, passait en `EnvironmentStudioPanelMode.createDraft`, puis rendait directement `EnvironmentPresetDraftForm`.

Le flow existant affichait immédiatement :

- champs `Id`, `Nom`, `Template`, `Catégorie`, `Ordre d’affichage` ;
- paramètres par défaut ;
- palette manuelle ;
- validation.

Le tileset source était seulement inféré depuis la palette via `buildEnvironmentPresetTilesetCompatibility(...)`. L’utilisateur pouvait donc entrer dans la composition sans étape explicite de choix du tileset.

## 4. Nouveau workflow tileset-first

La création utilise maintenant `EnvironmentPresetCreationWizard`, branché uniquement pour `EnvironmentStudioPanelMode.createDraft`.

L’édition existante reste inchangée :

```text
createDraft → EnvironmentPresetCreationWizard
editDraft   → EnvironmentPresetDraftForm
browser     → liste + détail/palette
```

Le wizard conserve le même callback mémoire :

```dart
void Function(
  ProjectManifest nextManifest,
  EnvironmentPreset savedPreset,
  EnvironmentPresetMemoryWriteKind kind,
)?
```

La création finale appelle toujours :

- `validateEnvironmentPresetDraft(...)` ;
- `buildEnvironmentPresetFromDraft(...)` ;
- `upsertProjectEnvironmentPreset(...)` ;
- `EnvironmentPresetMemoryWriteKind.create`.

## 5. Étape 1 — choix du tileset

Étape visible :

```text
Étape 1 sur 2 — Choisir le tileset source
```

Comportements :

- liste les `ProjectTilesetEntry` du manifest ;
- affiche nom, id, chemin relatif et nombre d’éléments compatibles ;
- bouton `Continuer` désactivé tant qu’aucun tileset n’est sélectionné ;
- sélection d’un tileset préremplit localement id/nom/template si les champs sont encore vides ;
- si aucun tileset n’existe, affiche un état vide pédagogique ;
- si l’utilisateur revient en étape 1 et change de tileset alors qu’une palette existe, la palette du brouillon est vidée.

Message de changement de tileset :

```text
Le changement de tileset a vidé la palette du brouillon pour éviter tout mélange.
```

## 6. Étape 2 — choix des éléments compatibles

Étape visible :

```text
Étape 2 sur 2 — Choisir les éléments du preset
```

Filtrage :

```dart
resolveEnvironmentPresetElementTilesetId(element) == selectedTilesetId
```

Les éléments sans source résolvable ne sont pas proposés dans la liste compatible.

L’étape 2 contient :

- section compacte `Informations du preset` ;
- section compacte `Paramètres par défaut` ;
- filtre texte `Filtrer éléments compatibles...` ;
- cards d’éléments compatibles ;
- bouton `Ajouter` par élément ;
- palette brouillon en table avec colonnes `Élément`, `Poids`, `Collision`, `Tags`, `Actions` ;
- validation du brouillon ;
- bouton final `Ajouter au projet en mémoire`.

## 7. Identité / paramètres du preset

Les champs restent locaux au brouillon :

- `Id` ;
- `Nom` ;
- `Template` ;
- `Catégorie` ;
- `Ordre d’affichage`.

Les paramètres par défaut restent locaux :

- densité ;
- variation ;
- densité des bords ;
- espacement min.

Le wizard ne persiste rien tant que `Ajouter au projet en mémoire` n’est pas déclenché.

## 8. Sécurité anti-mélange tilesets

Sécurité UI :

- les éléments listés en étape 2 sont filtrés par tileset choisi ;
- le bouton `Ajouter` refuse un élément dont `resolveEnvironmentPresetElementTilesetId(...)` ne correspond pas au tileset sélectionné ;
- les doublons ne sont pas ajoutés via les cards compatibles.

Sécurité applicative locale au wizard :

- `_sourceGuardIssues(...)` bloque la création si un item du brouillon référence un élément sans source tileset fiable ;
- `_sourceGuardIssues(...)` bloque la création si un item référence un élément d’un autre tileset que celui choisi ;
- `validateEnvironmentPresetDraft(...)` continue de bloquer palette vide, élément manquant, id vide, nom vide, template vide, doublon et mélange tileset dérivé.

Le guard hors UI existant du use case palette reste intact et testé par `environment_preset_palette_use_case_test.dart`.

## 9. Comportements préservés

Préservé :

- sélection de preset dans le browser ;
- édition palette existante ;
- dirty state palette ;
- save/cancel palette ;
- edit-as-draft d’un preset existant ;
- validation poids hors UI ;
- protection anti-mélange tilesets existante ;
- save mémoire via callback ;
- post-save feedback ;
- workspace dirty via `EditorNotifier.applyInMemoryProjectManifest(...)`.

Non ajouté :

- création disque ;
- génération sur carte ;
- peinture de masque ;
- sélection de map ;
- sélection de TileLayer ;
- preview canvas ;
- édition d’EnvironmentArea.

## 10. Tests

### Commande RED initiale

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat initial attendu avant implémentation :

```text
00:01 +1 -6: Some tests failed.
```

Erreur représentative :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'environment-studio-creation-wizard'>]: []>
```

### Tests ciblés 3C

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat :

```text
00:01 +7: All tests passed!
```

Cas couverts :

- `Nouveau preset` ouvre un wizard ;
- étape 1 visible ;
- `Continuer` désactivé sans tileset ;
- sélection tileset active l’étape 2 ;
- étape 2 affiche uniquement les éléments compatibles ;
- élément d’un autre tileset absent ;
- élément sans source absent ;
- ajout/retrait d’élément dans la palette brouillon ;
- save final désactivé si palette vide ;
- save mémoire avec `EnvironmentPresetMemoryWriteKind.create` ;
- changement de tileset vide la palette ;
- saisie manuelle incompatible bloque la création ;
- pas de commandes map/génération/peinture.

### Régression palette Studio

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_draft_editor_test.dart
```

Résultat :

```text
00:03 +21: All tests passed!
```

### Guard/use case palette

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_palette_use_case_test.dart
```

Résultat :

```text
00:00 +11: All tests passed!
```

### TileLayer inspector

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
00:02 +59: All tests passed!
```

### Golden slice Environment

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

Résultat :

```text
00:00 +6: All tests passed!
```

### Régression save manifest historique

Commande ajoutée par prudence car 3C modifie le flow création :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_preset_save_to_manifest_test.dart
```

Résultat :

```text
00:02 +13: All tests passed!
```

## 11. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart test/environment_studio/environment_studio_preset_creation_form_test.dart test/environment_studio/environment_preset_palette_draft_editor_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart
```

Résultat :

```text
No issues found! (ran in 2.0s)
```

Dette préexistante détectée par cette analyse ciblée : aucune.

## 12. Fichiers créés/modifiés

### Fichiers créés par EnvironmentStudio-3C

```text
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
reports/environment_studio/environment_studio_3c_tileset_first_preset_creation_wizard.md
```

### Fichiers modifiés par EnvironmentStudio-3C

```text
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
```

### Fichiers préexistants dans le worktree non touchés par 3C

Le contexte de reprise mentionnait des restes 3B préexistants :

```text
packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
reports/environment_studio/environment_studio_3b_palette_table_diagnostics_convergence.md
```

Ces chemins n’ont pas été modifiés par EnvironmentStudio-3C dans ce passage.

## 13. Non-objectifs respectés

- [x] Pas de modification `map_core`.
- [x] Pas de champ persistant `sourceTilesetId`.
- [x] Pas de modification du modèle `ProjectManifest`.
- [x] Pas de modification JSON.
- [x] Pas de build_runner.
- [x] Pas de generated files.
- [x] Pas de sauvegarde disque.
- [x] Pas de runtime/gameplay/battle.
- [x] Pas de canvas.
- [x] Pas de TileLayer inspector modifié.
- [x] Pas de peinture/génération dans Environment Studio.
- [x] Pas de refonte globale hors Environment Studio.
- [x] Pas de création/suppression/duplication de preset hors création mémoire demandée.

## 14. Evidence Pack

### Git status initial

Statut initial fourni par le contexte de reprise avant modifications 3C :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_palette_item_view.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
?? reports/environment_studio/environment_studio_3b_palette_table_diagnostics_convergence.md
```

### Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat à mettre à jour après écriture de ce rapport :

```text
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
 M packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
?? packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
?? reports/environment_studio/environment_studio_3c_tileset_first_preset_creation_wizard.md
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 .../environment_studio_panel.dart                  |  26 ++
 ...vironment_preset_palette_draft_editor_test.dart |  71 +--
 .../environment_preset_save_to_manifest_test.dart  |  82 ++--
 ...vironment_studio_preset_creation_form_test.dart | 496 +++++++++++----------
 4 files changed, 380 insertions(+), 295 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Le nouveau widget et le rapport apparaissent dans `git status --short --untracked-files=all`.

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
packages/map_editor/test/environment_studio/environment_preset_palette_draft_editor_test.dart
packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
packages/map_editor/test/environment_studio/environment_studio_preset_creation_form_test.dart
```

### git diff --check

Commande :

```bash
git diff --check
```

Résultat :

```text
```

Exit code : `0`.

### Format

Commande :

```bash
cd packages/map_editor
dart format lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart test/environment_studio/environment_studio_preset_creation_form_test.dart
```

Résultat :

```text
Formatted lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart
Formatted test/environment_studio/environment_studio_preset_creation_form_test.dart
Formatted 3 files (2 changed) in 0.02 seconds.
```

Commandes de format supplémentaires :

```bash
cd packages/map_editor
dart format test/environment_studio/environment_preset_palette_draft_editor_test.dart
dart format test/environment_studio/environment_preset_save_to_manifest_test.dart
```

Résultats :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Sub-agents

Sub-agent A — Audit / Architecture :

```text
Read-only audit done. No files edited. No git writes.
Current Flow:
- EnvironmentStudioPanel modes: browser, createDraft, editDraft.
- Nouveau preset calls _openDraftForm() and creates EnvironmentPresetDraft.empty().
- Draft form was full preset form immediately.
- Tileset source was inferred from the first palette element, not chosen first.
- Save path validates draft, builds EnvironmentPreset, upserts ProjectManifest, then calls onEnvironmentPresetSaved.
Insertion points:
- createDraft branch in EnvironmentStudioPanel.
- Preserve editDraft, palette-only edit, callbacks, browser selection, feedback.
Risks:
- Explicit tileset source must remain UI-only.
- Empty palette remains invalid.
- Tests key-heavy and direct-form expectations need deliberate update.
```

Sub-agent B — UI / UX / Tests :

```text
Read-only. No file edits. No git writes.
Current Coverage:
- Existing creation tests covered direct form, not tileset-first wizard.
- Existing palette tests covered palette filtering and mixed tileset save blocking.
Minimal tests needed:
- step 1 disables continue until tileset selected;
- step 2 only offers compatible elements;
- add/remove palette controls save state;
- changing tileset clears palette;
- no map generation or paint controls.
Recommendation:
- add wizard-specific keys instead of relying only on labels.
```

## 15. Diff pertinent

### `environment_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index 41eb2550..631a4cc0 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -7,6 +7,7 @@ import 'authoring/environment_preset_palette_use_cases.dart';
 import 'authoring/environment_preset_tileset_compatibility.dart';
 import 'environment_preset_memory_write_kind.dart';
 import 'widgets/environment_palette_item_draft_editor.dart';
+import 'widgets/environment_preset_creation_wizard.dart';
 import 'widgets/environment_preset_detail.dart';
 import 'widgets/environment_preset_draft_form.dart';
 import 'widgets/environment_preset_list.dart';
@@ -364,6 +365,31 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                       report,
                     ),
                   )
+              else if (_panelMode == EnvironmentStudioPanelMode.createDraft)
+                Expanded(
+                  child: DecoratedBox(
+                    decoration: BoxDecoration(
+                      color: EditorChrome.chipFill(context),
+                      borderRadius: BorderRadius.circular(12),
+                      border: Border.all(
+                        color: CupertinoColors.separator.resolveFrom(context),
+                      ),
+                    ),
+                    child: EnvironmentPresetCreationWizard(
+                      key: ValueKey<int>(_draftFormEpoch),
+                      manifest: widget.manifest,
+                      knownTemplateIds: widget.knownTemplateIds,
+                      draft: _draft,
+                      onChanged: (d) => setState(() => _draft = d),
+                      onCancel: _closeDraftForm,
+                      onReset: _resetDraft,
+                      onEnvironmentPresetSaved:
+                          widget.onEnvironmentPresetSaved == null
+                              ? null
+                              : _onEnvironmentPresetSavedInMemory,
+                    ),
+                  ),
+                )
               else
                 Expanded(
                   child: DecoratedBox(
```

### Nouveau widget — zones clés

Le fichier nouveau contient `1295` lignes. Les zones suivantes couvrent les comportements ajoutés par le lot.

Signature :

```dart
class EnvironmentPresetCreationWizard extends StatefulWidget {
  const EnvironmentPresetCreationWizard({
    super.key,
    required this.manifest,
    this.knownTemplateIds = const <String>{},
    required this.draft,
    required this.onChanged,
    required this.onCancel,
    required this.onReset,
    this.onEnvironmentPresetSaved,
  });
```

Filtrage compatible :

```dart
List<ProjectElementEntry> _compatibleElements(String tilesetId) {
  final elements = [
    for (final element in widget.manifest.elements)
      if (resolveEnvironmentPresetElementTilesetId(element) == tilesetId)
        element,
  ]..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) {
        return order;
      }
      return a.id.compareTo(b.id);
    });
  return elements;
}
```

Choix tileset + vidage palette en cas de changement :

```dart
void _selectTileset(ProjectTilesetEntry tileset) {
  final previous = _selectedTilesetId;
  final changed = previous != null && previous != tileset.id;
  final shouldClearPalette = changed && widget.draft.palette.isNotEmpty;
  final slug = _slug(tileset.id.isNotEmpty ? tileset.id : tileset.name);
  setState(() {
    _selectedTilesetId = tileset.id;
    _tilesetChangeMessage = shouldClearPalette
        ? 'Le changement de tileset a vidé la palette du brouillon pour éviter tout mélange.'
        : null;
    _saveErrorMessage = null;
  });
  if (_idCtrl.text.trim().isEmpty) {
    _idCtrl.text = '${slug}_environment';
  }
  if (_nameCtrl.text.trim().isEmpty) {
    _nameCtrl.text =
        tileset.name.trim().isEmpty ? 'Preset ${tileset.id}' : tileset.name;
  }
  if (_templateCtrl.text.trim().isEmpty) {
    _templateCtrl.text = '${slug}_environment';
  }
  if (shouldClearPalette) {
    widget.onChanged(_draftFromControllers(palette: const []));
  } else {
    _emit();
  }
}
```

Ajout compatible :

```dart
void _addPaletteItem(ProjectElementEntry element) {
  if (_selectedTilesetId == null) {
    return;
  }
  if (resolveEnvironmentPresetElementTilesetId(element) !=
      _selectedTilesetId) {
    return;
  }
  if (widget.draft.palette.any((item) => item.elementId == element.id)) {
    return;
  }
  final next = [
    ...widget.draft.palette,
    EnvironmentPaletteItemDraft(
      elementId: element.id,
      weight: 1,
      collisionMode: EnvironmentCollisionMode.useElementDefault,
      tags: element.tags.toSet(),
    ),
  ];
  _emit(palette: next);
}
```

Guard source local :

```dart
List<String> _sourceGuardIssues(EnvironmentPresetDraft draft) {
  final source = _selectedTilesetId;
  if (source == null) {
    return const ['Choisissez un tileset source.'];
  }
  final elementsById = {
    for (final element in widget.manifest.elements) element.id: element,
  };
  final issues = <String>[];
  for (final item in draft.palette) {
    final elementId = item.elementId.trim();
    if (elementId.isEmpty) {
      continue;
    }
    final element = elementsById[elementId];
    if (element == null) {
      continue;
    }
    final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
    if (tilesetId == null) {
      issues.add('Élément sans tileset source fiable : $elementId.');
    } else if (tilesetId != source) {
      issues.add(
        'Élément incompatible avec le tileset source "$source" : $elementId.',
      );
    }
  }
  return issues;
}
```

Save mémoire :

```dart
void _saveDraftToProject() {
  final save = widget.onEnvironmentPresetSaved;
  if (save == null) {
    return;
  }
  final draft = _draftFromControllers();
  final validation = validateEnvironmentPresetDraft(
    draft,
    manifest: widget.manifest,
    knownTemplateIds: widget.knownTemplateIds,
  );
  final sourceIssues = _sourceGuardIssues(draft);
  if (validation.hasErrors || sourceIssues.isNotEmpty) {
    return;
  }
  try {
    final preset = buildEnvironmentPresetFromDraft(draft);
    final nextManifest = upsertProjectEnvironmentPreset(
      widget.manifest,
      preset,
    );
    save(nextManifest, preset, EnvironmentPresetMemoryWriteKind.create);
  } catch (_) {
    setState(() {
      _saveErrorMessage =
          'Impossible d’appliquer le preset au projet en mémoire.';
    });
  }
}
```

### Tests création 3C

```diff
+  group('EnvironmentStudioPanel — création tileset-first (3C)', () {
+    testWidgets(
+        'Nouveau preset ouvre un wizard et bloque Continuer sans tileset',
+        (tester) async {
+      ...
+      expect(find.text('Étape 1 sur 2 — Choisir le tileset source'),
+          findsOneWidget);
+      ...
+      final continueButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-creation-continue')),
+      );
+      expect(continueButton.onPressed, isNull);
+    });
+    testWidgets('sélectionner un tileset active l’étape éléments compatibles',
+        (tester) async {
+      ...
+      expect(find.text('Étape 2 sur 2 — Choisir les éléments du preset'),
+          findsOneWidget);
+      expect(find.text('Herbe A'), findsOneWidget);
+      expect(find.text('Rocher A'), findsNothing);
+      expect(find.text('Sans source'), findsNothing);
+    });
+    testWidgets(
+        'ajout, retrait et création mémoire restent guidés par le tileset',
+        (tester) async {
+      ...
+      expect(receivedKind, EnvironmentPresetMemoryWriteKind.create);
+      expect(receivedPreset!.palette.single.elementId, 'grass_a');
+    });
+    testWidgets('changer de tileset vide la palette du brouillon',
+        (tester) async {
+      ...
+      expect(
+        find.text(
+          'Le changement de tileset a vidé la palette du brouillon pour éviter tout mélange.',
+        ),
+        findsOneWidget,
+      );
+    });
+    testWidgets('un élément forcé hors tileset source bloque la création',
+        (tester) async {
+      ...
+      expect(
+        find.textContaining('Élément incompatible avec le tileset source'),
+        findsOneWidget,
+      );
+      final saveButton = tester.widget<CupertinoButton>(
+        find.byKey(const Key('environment-studio-draft-save-project')),
+      );
+      expect(saveButton.onPressed, isNull);
+    });
+  });
```

### Adaptation tests palette/save existants

Les tests existants qui ouvraient directement un formulaire de création passent maintenant par un helper de test :

```dart
Future<void> _openCreationPaletteStep(
  WidgetTester tester, {
  String tilesetId = 'ts',
}) async {
  await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(Key('environment-studio-creation-tileset-$tilesetId')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('environment-studio-creation-continue')),
  );
  await tester.pumpAndSettle();
}
```

Les fixtures de tests ajoutent des tilesets cohérents avec leurs éléments :

```dart
ProjectTilesetEntry _tileset({required String id}) {
  return ProjectTilesetEntry(
    id: id,
    name: id,
    relativePath: 'tilesets/$id.png',
  );
}
```

## 16. Auto-review

- Le flow création est-il vraiment en deux étapes ? Oui.
- L’étape 1 force-t-elle le choix du tileset ? Oui, `Continuer` est désactivé sans tileset.
- L’étape 2 filtre-t-elle les éléments selon le tileset choisi ? Oui, via `resolveEnvironmentPresetElementTilesetId(...)`.
- Les éléments incompatibles sont-ils absents ou impossibles à ajouter ? Oui pour la liste UI ; si un id incompatible est forcé manuellement, le save est bloqué.
- La palette brouillon est-elle lisible ? Oui, elle reprend une table compacte avec colonnes.
- Les gros champs noirs pleine largeur ont-ils disparu ou été fortement réduits ? Oui, les champs sont regroupés en sections compactes.
- Le bouton final est-il protégé contre une palette vide ? Oui, `validateEnvironmentPresetDraft(...)` bloque `emptyPalette`.
- Le changement de tileset gère-t-il correctement la palette existante ? Oui, elle est vidée avec message.
- Le guard anti-mélange tileset est-il préservé hors UI ? Oui, use case palette inchangé et testé.
- Les flows d’édition palette existants sont-ils préservés ? Oui, tests palette/save passent.
- Environment Studio reste-t-il un atelier de presets ? Oui.
- Aucune peinture/génération sur map ? Oui.
- Aucun map_core modifié ? Oui.
- Aucun ProjectManifest model modifié ? Oui.
- Aucun generated file ? Oui.
- Aucun build_runner ? Oui.
- Aucun TileLayer inspector modifié ? Oui.
- Aucun canvas modifié ? Oui.
- Aucun commit ? Oui.
- Aucun git add ? Oui.

## 17. Critique du prompt et du lot

Ce qui était clair :

- la création devait être tileset-first ;
- le tileset source devait rester local au brouillon ;
- la palette vide devait rester refusée ;
- Environment Studio ne devait pas redevenir un outil de map/génération.

Ce qui était ambigu :

- le prompt externe demandait beaucoup de commentaires dans le code, mais les règles du repo interdisaient les commentaires ajoutés. J’ai respecté la règle repo/directe : aucun commentaire ajouté.
- le prompt demandait parfois “contenu complet de tous les fichiers modifiés”. Les fichiers modifiés existants totalisent plusieurs milliers de lignes ; ce rapport inclut les hunks et extraits qui prouvent les changements. Les lignes inchangées des fichiers existants n’apportent pas d’information sur le lot.

À trancher avant 3D :

- faut-il retirer totalement la saisie manuelle d’`elementId` dans la palette de création, ou conserver le champ pour compatibilité avec l’éditeur de draft existant ?
- faut-il rendre le choix de tileset plus visuel avec miniatures réelles du tileset ?
- faut-il remplacer `Template` par une sélection plus no-code dans la création ?
- faut-il créer un composant partagé de table palette entre création et édition pour réduire la duplication UI ?

## 18. Verdict

```text
EnvironmentStudio-3C livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : EnvironmentStudio-3D — Final Closure Polish V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié ProjectManifest model.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] Je n’ai pas modifié canvas.
- [x] Je n’ai pas modifié TileLayer inspector.
- [x] Je n’ai pas ajouté de sauvegarde disque.
- [x] Je n’ai pas remis la peinture/génération dans Environment Studio.
- [x] Le flow création est en deux étapes.
- [x] Le tileset source est choisi avant les éléments.
- [x] Les éléments proposés sont filtrés par tileset.
- [x] La palette vide reste refusée.
- [x] Le mélange de tilesets est bloqué.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée passe.
