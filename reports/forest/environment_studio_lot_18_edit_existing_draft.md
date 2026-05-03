# Environment Studio Lot 18 — Edit Existing Draft V0

## 1. Résumé exécutif

Le panneau **Environment Studio** permet désormais d’ouvrir un **preset existant** en **brouillon** (`editDraft`), avec **id verrouillé** (non renommable), validation via `existingPresetId`, upsert mémoire `upsertProjectEnvironmentPreset`, callback parent à **trois arguments** (`EnvironmentPresetMemoryWriteKind`), messages shell et feedback local **create vs update**, sans aucune persistance disque ni toucher `map_core` / `EnvironmentLayer` / `EnvironmentArea`.

## 2. Périmètre du lot

- Inclus : mode `editDraft`, action **« Modifier en brouillon »**, formulaire partagé, bouton **« Mettre à jour le projet en mémoire »**, `EnvironmentPresetMemoryWriteKind`, tests Lot 18, adaptation tests Lot 17, grep non-persistance.
- Exclus (comme demandé) : rename d’id, delete, duplicate, disque, générateur, `EnvironmentLayer` / `EnvironmentArea`, `editor_notifier` hors `applyInMemoryProjectManifest` via workspace existant, `map_core` / `map_runtime` / etc., `build_runner`, commit git.

## 3. Audit initial du flux create/update

Fichiers relus en amont : `environment_studio_panel.dart`, `environment_studio_workspace.dart`, `environment_preset_draft.dart` (validation `existingPresetId`), `environment_preset_detail.dart`, `environment_preset_draft_form.dart`, `environment_preset_save_feedback.dart`, tests save / browser / workspace.

Constats : le flux Lot 17 passait un callback à **deux** arguments ; la validation panel ne couvrait que `createDraft` ; le formulaire ne recevait pas `existingPresetId` ; pas d’entrée UI pour l’édition existante.

Pattern retenu : **un seul** `EnvironmentPresetDraftForm`, paramètre `existingPresetId` pour verrouiller l’id et passer à `validateEnvironmentPresetDraft` / `_saveDraftToProject` ; enum **`EnvironmentPresetMemoryWriteKind`** pour le callback et le feedback ; **`EnvironmentStudioPanelMode.editDraft`** + `_editingPresetId` synchronisé avec le preset source.

## 4. Décisions UX édition existante

- Libellé d’action : **« Modifier en brouillon »** (clé `environment-studio-edit-as-draft`), pas Edit/Save/Create/Generate.
- Titre formulaire : **« Modifier un preset d’environnement »** ; badge **« Brouillon de modification non sauvegardé »** ; intro alignée spec §6.2.
- Bouton principal : **« Mettre à jour le projet en mémoire »** si `existingPresetId != null`.
- Message d’erreur catch : **« Impossible d’appliquer le preset au projet en mémoire. »** (neutre create/update).
- **« Modifier en brouillon »** masqué si `onEnvironmentPresetSaved == null` (tests sans callback : pas de promesse de persistance mémoire).

## 5. Mode editDraft ajouté

`EnvironmentStudioPanelMode` : `browser` | `createDraft` | **`editDraft`**.

Ouverture : `_openEditDraftFromPreset` → `_editingPresetId = preset.id`, `_draft = EnvironmentPresetDraft.fromPreset(preset)`, `++_draftFormEpoch`.

Validation panel : `createDraft || editDraft`, avec `existingPresetId: _editingPresetId` uniquement en `editDraft`.

## 6. Id verrouillé et justification

- UI : `CupertinoTextField(..., enabled: !isEdit)` + aide `environment-studio-draft-id-locked-hint`.
- Données : `_effectiveIdForDraft()` force l’id du manifest verrouillé pour `_emit` / `_draftFromControllers` même si le contrôleur divergeait.
- **Pas de rename** : les futurs `EnvironmentArea.presetId` restent stables ; lot dédié pour migration / confirmation.

## 7. Mise à jour manifest en mémoire

Flux inchangé côté contrat `map_core` : `buildEnvironmentPresetFromDraft` → `upsertProjectEnvironmentPreset` → callback parent. L’id inchangé garantit un **upsert** sur la même entrée (pas de doublon).

## 8. Feedback local update

`EnvironmentPresetSaveFeedback` prend `writeKind` : ligne 1 **« ajouté »** ou **« mis à jour dans le projet en mémoire »** ; ligne 2 inchangée (rappel sauvegarde projet disque).

## 9. Dirty state / statusMessage

`EnvironmentStudioWorkspace` : `switch (kind)` →  
`Preset d'environnement « … » ajouté au projet.` **ou** `… mis à jour dans le projet.`  
Toujours `applyInMemoryProjectManifest(nextManifest, statusMessage: msg)` (inchangé, `isProjectDirty: true` dans le notifier).

## 10. Non-persistance disque garantie

Commande exécutée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n lib/src/features/environment_studio lib/src/features/editor/state/editor_notifier.dart || true
```

Sortie exacte :

```
lib/src/features/editor/state/editor_notifier.dart:437:  Future<bool> saveProjectManifest() async {
lib/src/features/editor/state/editor_notifier.dart:446:      debugPrint('EditorNotifier: saveProjectManifest()');
lib/src/features/editor/state/editor_notifier.dart:448:      await ref.read(projectRepositoryProvider).saveProject(
lib/src/features/editor/state/editor_notifier.dart:1488:  Future<void> saveProjectDialogueYarnBody({
lib/src/features/editor/state/editor_notifier.dart:1492:      state = await _projectContentController.saveProjectDialogueYarnBody(
```

**Aucune** occurrence sous `lib/src/features/environment_studio/`. Aucun nouvel appel disque dans le flux Lot 18.

## 11. Pourquoi aucun rename / delete / générateur / EnvironmentLayer dans ce lot

Conformité stricte au cahier : périmètre limité à l’édition brouillon + upsert mémoire + UX ; rename d’id réservé à un lot avec migration des références ; pas de suppression/duplication ; pas de génération carte ; pas de couches / zones environnement.

## 12. Fichiers modifiés

| Fichier | Rôle |
|---------|------|
| `packages/map_editor/lib/src/features/environment_studio/environment_preset_memory_write_kind.dart` | **Nouveau** — enum `create` / `update`. |
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart` | Mode `editDraft`, état, validation, callback 3-args, bannière, feedback, bouton détail. |
| `packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart` | Messages `statusMessage` selon `kind`. |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart` | `onEditAsDraft` + bouton. |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart` | `existingPresetId`, UI create/edit, validation/save, message neutre. |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart` | `writeKind` pour la ligne 1. |
| `packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart` | Callback 3-args + textes formulaire. |
| `packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart` | `_pumpPanel` + test bouton détail. |
| `packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart` | **Nouveau** — couverture Lot 18. |

## 13. Tests ajoutés ou modifiés

- **Nouveau** : `environment_preset_edit_existing_test.dart` (8 scénarios : ouverture, préremplissage, id verrouillé, update + feedback, pas duplicateId sur soi, nom vide, callback throw, intégration `EditorCanvasHost`).
- **Modifié** : `environment_preset_save_to_manifest_test.dart`, `environment_studio_workspace_test.dart`.

## 14. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
dart format lib/src/features/environment_studio/environment_preset_memory_write_kind.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/environment_studio_workspace.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart test/environment_studio/environment_preset_edit_existing_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart test/environment_studio/environment_studio_workspace_test.dart
flutter analyze lib/src/features/environment_studio/environment_preset_memory_write_kind.dart lib/src/features/environment_studio/environment_studio_panel.dart lib/src/features/environment_studio/environment_studio_workspace.dart lib/src/features/environment_studio/widgets/environment_preset_detail.dart lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart test/environment_studio/environment_preset_edit_existing_test.dart test/environment_studio/environment_preset_save_to_manifest_test.dart
grep -R "FileProjectRepository\|saveProject\|saveProjectManifest" -n lib/src/features/environment_studio lib/src/features/editor/state/editor_notifier.dart || true
flutter test test/environment_studio --reporter expanded
flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart --reporter expanded
flutter test
```

## 15. Résultats des commandes

- **`dart format`** : exit 0 ; 10 fichiers formatés (3 modifiés lors du premier passage).
- **`flutter analyze` (ciblé)** : après correction import inutilisé dans le test Lot 18 : **No issues found!** (exit 0).
- **`flutter test test/environment_studio`** : **All tests passed!** — **106** tests ; ligne finale du résumé : `00:05 +106: All tests passed!`
- **`flutter test test/editor_workspace_controller_test.dart test/top_toolbar_test.dart`** : **All tests passed!** — **14** tests ; dernière ligne : `00:00 +14: All tests passed!`
- **`flutter test` (package complet)** : **échec** avec dette préexistante — **939** passés, **34** échoués ; dernière ligne : `00:57 +939 -34: Some tests failed.` (ex. suites items catalog / sync — hors périmètre Environment Studio ; aucun lien avec les fichiers modifiés du Lot 18).

## 16. Git status initial et final

**Initial (extrait conversation utilisateur / dépôt au début de session)** : modifications non commit sur `packages/map_core/...` et déjà `packages/map_editor/...` (lots précédents).

**Final** (`git status --short --untracked-files=all` à la racine du dépôt) :

```
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
 M packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
 M packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
 M packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
?? packages/map_editor/lib/src/features/environment_studio/environment_preset_memory_write_kind.dart
?? packages/map_editor/test/environment_studio/environment_preset_edit_existing_test.dart
?? reports/forest/environment_studio_lot_18_edit_existing_draft.md
```

Les fichiers `packages/map_core/...` listés au **git_status** initial de la conversation restent hors Lot 18 et ne sont pas modifiés par ce lot.

## 17. Contenu complet des fichiers créés ou modifiés

Les fichiers **modifiés** existants sont entièrement décrits par le **diff unifié** de la section 18 (état HEAD vs working tree pour les chemins Lot 18).

### 17.1 Fichier créé — `environment_preset_memory_write_kind.dart` (intégral)

```1:8:packages/map_editor/lib/src/features/environment_studio/environment_preset_memory_write_kind.dart
/// Écriture mémoire d’un preset d’environnement sur le [ProjectManifest] de session.
///
/// Utilisé par le callback [EnvironmentStudioPanel.onEnvironmentPresetSaved] pour
/// distinguer création et mise à jour (messages shell / feedback local).
enum EnvironmentPresetMemoryWriteKind {
  create,
  update,
}
```

### 17.2 Fichier créé — `environment_preset_edit_existing_test.dart` (intégral)

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Lot 18 — édition preset existant en brouillon', () {
    testWidgets(
        'action Modifier en brouillon ouvre le formulaire (titre + badge)',
        (tester) async {
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [
            _preset(
              id: 'meadow',
              name: 'Prairie',
              templateId: 'tpl_m',
              categoryId: 'cat_a',
              sortOrder: 3,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) {},
      );

      expect(find.byKey(const Key('environment-studio-edit-as-draft')),
          findsOneWidget);
      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      expect(
        find.text('Modifier un preset d’environnement'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('environment-studio-draft-edit-badge')),
          findsOneWidget);
      expect(
        find.text('Brouillon de modification non sauvegardé'),
        findsOneWidget,
      );
    });

    testWidgets('formulaire prérempli (id, nom, template, catégorie, ordre)',
        (tester) async {
      final params = EnvironmentGenerationParams(
        density: 0.42,
        variation: 0.51,
        edgeDensity: 0.33,
        minSpacingCells: 7,
      );
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [
            EnvironmentPreset(
              id: 'forest_x',
              name: 'Forêt X',
              templateId: 'forest_tpl',
              categoryId: 'biome_cat',
              palette: [
                EnvironmentPaletteItem(elementId: 'e1', weight: 2),
              ],
              defaultParams: params,
              sortOrder: 12,
            ),
          ],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) {},
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-id'))))
            .controller
            ?.text,
        'forest_x',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-name'))))
            .controller
            ?.text,
        'Forêt X',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-template'))))
            .controller
            ?.text,
        'forest_tpl',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-field-category'))))
            .controller
            ?.text,
        'biome_cat',
      );
      expect(
        (tester.widget<CupertinoTextField>(
                find.byKey(const Key('environment-studio-draft-field-sort'))))
            .controller
            ?.text,
        '12',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-draft-params-density'))))
            .controller
            ?.text,
        '0.42',
      );
      expect(
        (tester.widget<CupertinoTextField>(find
                .byKey(const Key('environment-studio-palette-draft-weight-0'))))
            .controller
            ?.text,
        '2',
      );
    });

    testWidgets('id verrouillé : champ désactivé, aide visible',
        (tester) async {
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [_preset(id: 'lock_id')],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) {},
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      final idField = tester.widget<CupertinoTextField>(
        find.byKey(const Key('environment-studio-draft-field-id')),
      );
      expect(idField.enabled, isFalse);
      expect(
        find.byKey(const Key('environment-studio-draft-id-locked-hint')),
        findsOneWidget,
      );
      expect(
        find.textContaining('verrouillé'),
        findsWidgets,
      );

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'hacked',
      );
      await tester.pumpAndSettle();
      expect(idField.controller?.text, 'lock_id');
    });

    testWidgets(
      'mise à jour valide : callback kind update, même nombre d’ids, browser + feedback',
      (tester) async {
        ProjectManifest? receivedM;
        EnvironmentPreset? receivedP;
        EnvironmentPresetMemoryWriteKind? receivedK;

        await _pumpPanel(
          tester,
          manifest: _manifest(
            environmentPresets: [_preset(id: 'p1', name: 'Ancien')],
            elements: [_element(id: 'e1')],
          ),
          onSaved: (m, p, k) {
            receivedM = m;
            receivedP = p;
            receivedK = k;
          },
        );

        await tester
            .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Nouveau nom',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          'new_tpl',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(receivedK, EnvironmentPresetMemoryWriteKind.update);
        expect(receivedP!.id, 'p1');
        expect(receivedP!.name, 'Nouveau nom');
        expect(receivedP!.templateId, 'new_tpl');
        expect(receivedM!.environmentPresets.length, 1);
        expect(receivedM!.environmentPresets.single.id, 'p1');

        expect(find.byKey(const Key('environment-studio-preset-list')),
            findsOneWidget);
        expect(
          (tester.widget<Text>(
                  find.byKey(const Key('environment-studio-detail-name'))))
              .data,
          'Nouveau nom',
        );
        expect(
          find.textContaining('mis à jour dans le projet en mémoire'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
        'édition : pas d’erreur Id déjà utilisé pour le preset lui-même',
        (tester) async {
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [_preset(id: 'solo')],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) {},
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Id déjà utilisé'), findsNothing);
      final saveBtn = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('nom vide : bouton update désactivé, callback non appelé',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [_preset(id: 'x')],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) => calls++,
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        '',
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const Key('environment-studio-draft-save-project')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byKey(const Key('environment-studio-draft-form-title')),
          findsOneWidget);
    });

    testWidgets(
        'callback qui lève en update : formulaire visible, message neutre',
        (tester) async {
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [_preset(id: 'boom')],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) => throw StateError('simulé'),
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Ok',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible d’appliquer le preset au projet en mémoire.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('environment-studio-preset-list')),
          findsNothing);
    });

    testWidgets(
        'workspace : update met à jour environmentPresets, dirty, statusMessage',
        (tester) async {
      final preset = EnvironmentPreset(
        id: 'ws_edit',
        name: 'Avant',
        templateId: 'tpl_ws',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree_a', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      );
      final container = await pumpEditorCanvasHostHarness(
        tester,
        surfaceSize: const Size(960, 2200),
        initialState: EditorState(
          projectRootPath: '/tmp/lot18_env',
          project: buildShellChromeProject(
            environmentPresets: [preset],
            elements: const [
              ProjectElementEntry(
                id: 'tree_a',
                name: 'Arbre',
                tilesetId: 'ts',
                categoryId: 'c',
                frames: [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                  ),
                ],
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      await tester
          .tap(find.byKey(const Key('environment-studio-edit-as-draft')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Après workspace',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();

      final snap = container.read(editorNotifierProvider);
      expect(snap.isProjectDirty, isTrue);
      expect(
        snap.project!.environmentPresets
            .singleWhere((e) => e.id == 'ws_edit')
            .name,
        'Après workspace',
      );
      expect(
        snap.statusMessage,
        'Preset d’environnement « Après workspace » mis à jour dans le projet.',
      );
    });
  });
}

/// Rejoue le rafraîchissement du manifest (copié du test save Lot 17).
class _ManifestSyncPanelHost extends StatefulWidget {
  const _ManifestSyncPanelHost({
    required this.initialManifest,
    this.knownTemplateIds = const {},
    this.onSaved,
  });

  final ProjectManifest initialManifest;
  final Set<String> knownTemplateIds;
  final void Function(
    ProjectManifest,
    EnvironmentPreset,
    EnvironmentPresetMemoryWriteKind,
  )? onSaved;

  @override
  State<_ManifestSyncPanelHost> createState() => _ManifestSyncPanelHostState();
}

class _ManifestSyncPanelHostState extends State<_ManifestSyncPanelHost> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.initialManifest;
  }

  @override
  void didUpdateWidget(covariant _ManifestSyncPanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialManifest, widget.initialManifest)) {
      _manifest = widget.initialManifest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EnvironmentStudioPanel(
      manifest: _manifest,
      knownTemplateIds: widget.knownTemplateIds,
      onEnvironmentPresetSaved: widget.onSaved == null
          ? null
          : (next, preset, kind) {
              widget.onSaved!(next, preset, kind);
              setState(() => _manifest = next);
            },
    );
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required ProjectManifest manifest,
  Set<String> knownTemplateIds = const {},
  void Function(
    ProjectManifest,
    EnvironmentPreset,
    EnvironmentPresetMemoryWriteKind,
  )? onSaved,
}) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MacosApp(
      home: CupertinoPageScaffold(
        child: _ManifestSyncPanelHost(
          initialManifest: manifest,
          knownTemplateIds: knownTemplateIds,
          onSaved: onSaved,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 't-edit-existing',
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

EnvironmentPreset _preset({
  required String id,
  String name = 'P',
  String templateId = 'tpl',
  String? categoryId,
  int sortOrder = 0,
}) {
  return EnvironmentPreset(
    id: id,
    name: name,
    templateId: templateId,
    categoryId: categoryId,
    palette: [
      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: sortOrder,
  );
}

ProjectElementEntry _element({required String id}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
```

## 18. Diff complet

Le diff unifié **complet** (809 lignes) pour tous les chemins suivants est inclus dans le bloc suivant (sortie brute de `git diff` sur le working tree, fichiers trackés + modifications ; les fichiers **untracked** `environment_preset_memory_write_kind.dart` et `environment_preset_edit_existing_test.dart` n’apparaissent pas dans `git diff` et sont donnés intégralement en §17.1–17.2).

```diff
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
index 37adb49d..3b9a298f 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
@@ -3,18 +3,22 @@ import 'package:map_core/map_core.dart';
 
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'authoring/environment_preset_draft.dart';
+import 'environment_preset_memory_write_kind.dart';
 import 'widgets/environment_preset_detail.dart';
 import 'widgets/environment_preset_draft_form.dart';
 import 'widgets/environment_preset_list.dart';
 import 'widgets/environment_preset_save_feedback.dart';
 
-/// Modes locaux du panneau Environment Studio (Lot Environment-13).
+/// Modes locaux du panneau Environment Studio (Lot Environment-13, 18).
 enum EnvironmentStudioPanelMode {
   /// Liste + détail des presets existants (non mutateur).
   browser,
 
   /// Formulaire de brouillon ; persistance manifest via callback parent (mémoire).
   createDraft,
+
+  /// Brouillon prérempli depuis un preset existant ; id verrouillé (Lot 18).
+  editDraft,
 }
 
 /// Browser read-only des presets Environment (Lot Environment-10, polish 11).
@@ -41,11 +45,14 @@ class EnvironmentStudioPanel extends StatefulWidget {
   /// Quand non vide, restreint les templates reconnus (diagnostics auteur).
   final Set<String> knownTemplateIds;
 
-  /// Après validation sans erreur : manifest mis à jour + preset créé ;
-  /// le parent (ex. workspace) applique l’état éditeur ; pas d’I/O disque ici.
+  /// Après validation sans erreur : manifest mis à jour + preset créé ou mis
+  /// à jour ; le parent (ex. workspace) applique l’état éditeur ; pas d’I/O
+  /// disque ici.
   final void Function(
-          ProjectManifest nextManifest, EnvironmentPreset savedPreset)?
-      onEnvironmentPresetSaved;
+    ProjectManifest nextManifest,
+    EnvironmentPreset savedPreset,
+    EnvironmentPresetMemoryWriteKind kind,
+  )? onEnvironmentPresetSaved;
 
   @override
   State<EnvironmentStudioPanel> createState() => _EnvironmentStudioPanelState();
@@ -57,9 +64,15 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   EnvironmentPresetDraft _draft = EnvironmentPresetDraft.empty();
   int _draftFormEpoch = 0;
 
-  /// Lot 17 : message local browser après ajout mémoire (pas au 1er chargement).
+  /// Lot 18 : id du preset en cours d’édition (brouillon) ; `null` en création.
+  String? _editingPresetId;
+
+  /// Lot 17–18 : message local browser après écriture mémoire (pas au 1er chargement).
   String? _localSaveFeedbackPresetName;
 
+  /// Lot 18 : dernier type d’écriture pour le feedback local (create/update).
+  EnvironmentPresetMemoryWriteKind? _lastMemoryWriteKind;
+
   @override
   void initState() {
     super.initState();
@@ -119,21 +132,49 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   void _openDraftForm() {
     setState(() {
       _localSaveFeedbackPresetName = null;
+      _lastMemoryWriteKind = null;
+      _editingPresetId = null;
       _panelMode = EnvironmentStudioPanelMode.createDraft;
       _draft = EnvironmentPresetDraft.empty();
       _draftFormEpoch++;
     });
   }
 
+  void _openEditDraftFromPreset(EnvironmentPreset preset) {
+    setState(() {
+      _localSaveFeedbackPresetName = null;
+      _lastMemoryWriteKind = null;
+      _panelMode = EnvironmentStudioPanelMode.editDraft;
+      _editingPresetId = preset.id;
+      _draft = EnvironmentPresetDraft.fromPreset(preset);
+      _draftFormEpoch++;
+    });
+  }
+
   void _closeDraftForm() {
     setState(() {
       _panelMode = EnvironmentStudioPanelMode.browser;
+      _editingPresetId = null;
     });
   }
 
   void _resetDraft() {
     setState(() {
-      _draft = EnvironmentPresetDraft.empty();
+      if (_panelMode == EnvironmentStudioPanelMode.editDraft &&
+          _editingPresetId != null) {
+        EnvironmentPreset? source;
+        for (final p in widget.manifest.environmentPresets) {
+          if (p.id == _editingPresetId) {
+            source = p;
+            break;
+          }
+        }
+        _draft = source != null
+            ? EnvironmentPresetDraft.fromPreset(source)
+            : EnvironmentPresetDraft.empty();
+      } else {
+        _draft = EnvironmentPresetDraft.empty();
+      }
       _draftFormEpoch++;
     });
   }
@@ -141,14 +182,17 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
   void _onEnvironmentPresetSavedInMemory(
     ProjectManifest nextManifest,
     EnvironmentPreset savedPreset,
+    EnvironmentPresetMemoryWriteKind kind,
   ) {
-    widget.onEnvironmentPresetSaved!.call(nextManifest, savedPreset);
+    widget.onEnvironmentPresetSaved!.call(nextManifest, savedPreset, kind);
     setState(() {
       _panelMode = EnvironmentStudioPanelMode.browser;
       _selectedPresetId = savedPreset.id;
       _draft = EnvironmentPresetDraft.empty();
+      _editingPresetId = null;
       _draftFormEpoch++;
       _localSaveFeedbackPresetName = savedPreset.name;
+      _lastMemoryWriteKind = kind;
     });
   }
 
@@ -165,11 +209,16 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     );
     final s = report.summary;
 
-    final draftValidation = _panelMode == EnvironmentStudioPanelMode.createDraft
+    final isDraftMode = _panelMode == EnvironmentStudioPanelMode.createDraft ||
+        _panelMode == EnvironmentStudioPanelMode.editDraft;
+    final draftValidation = isDraftMode
         ? validateEnvironmentPresetDraft(
             _draft,
             manifest: widget.manifest,
             knownTemplateIds: widget.knownTemplateIds,
+            existingPresetId: _panelMode == EnvironmentStudioPanelMode.editDraft
+                ? _editingPresetId
+                : null,
           )
         : null;
 
@@ -234,6 +283,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                           manifest: widget.manifest,
                           knownTemplateIds: widget.knownTemplateIds,
                           draft: _draft,
+                          existingPresetId: _editingPresetId,
                           validation: draftValidation!,
                           projectElements: widget.manifest.elements,
                           onChanged: (d) => setState(() => _draft = d),
@@ -265,7 +315,9 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     Color subtle,
     int presetCount,
   ) {
-    final isDraft = _panelMode == EnvironmentStudioPanelMode.createDraft;
+    final isDraft = _panelMode == EnvironmentStudioPanelMode.createDraft ||
+        _panelMode == EnvironmentStudioPanelMode.editDraft;
+    final isEditDraft = _panelMode == EnvironmentStudioPanelMode.editDraft;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
@@ -299,12 +351,16 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
             ),
           ),
           child: Text(
-            isDraft
-                ? 'Brouillon : utilisez « Ajouter au projet en mémoire » pour intégrer '
-                    'le preset au manifest en session. Aucune sauvegarde disque automatique. '
-                    'La génération sur carte reste à venir.'
-                : 'Lecture seule sur les presets existants — édition d’un preset '
-                    'existant et génération sur carte arrivent dans les prochains lots.',
+            !isDraft
+                ? 'Lecture seule sur les presets existants — génération sur carte et '
+                    'renommage d’id arrivent dans les prochains lots.'
+                : isEditDraft
+                    ? 'Brouillon de modification : utilisez « Mettre à jour le projet en mémoire » '
+                        'pour intégrer les changements au manifest en session. Aucune sauvegarde disque '
+                        'automatique. L’id du preset reste verrouillé dans cette version.'
+                    : 'Brouillon : utilisez « Ajouter au projet en mémoire » pour intégrer '
+                        'le preset au manifest en session. Aucune sauvegarde disque automatique. '
+                        'La génération sur carte reste à venir.',
             key: const Key('environment-studio-read-only-banner'),
             style: const TextStyle(
               color: EditorChrome.accentJade,
@@ -363,9 +419,11 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
-        if (_localSaveFeedbackPresetName != null) ...[
+        if (_localSaveFeedbackPresetName != null &&
+            _lastMemoryWriteKind != null) ...[
           EnvironmentPresetSaveFeedback(
             presetName: _localSaveFeedbackPresetName!,
+            writeKind: _lastMemoryWriteKind!,
           ),
           const SizedBox(height: 12),
         ],
@@ -412,6 +470,10 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
                             report: report,
                             labelColor: label,
                             subtleColor: subtle,
+                            onEditAsDraft:
+                                widget.onEnvironmentPresetSaved == null
+                                    ? null
+                                    : () => _openEditDraftFromPreset(selected),
                           ),
                         ),
                 ),
@@ -482,7 +544,7 @@ class _EnvironmentStudioPanelState extends State<EnvironmentStudioPanel> {
         const SizedBox(height: 8),
         Text(
           '• sauvegarde disque du manifest projet ;\n'
-          '• édition des presets existants ;\n'
+          '• renommage d’id preset (migration des références) ;\n'
           '• utilisation dans les Environment Layers ;\n'
           '• génération organique sur les maps.',
           key: const Key('environment-studio-soon-bullets'),
diff --git a/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart b/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
index 155563b5..7c951e71 100644
--- a/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/environment_studio_workspace.dart
@@ -3,6 +3,7 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
 
 import '../editor/state/editor_notifier.dart';
 import '../editor/state/editor_selectors.dart';
+import 'environment_preset_memory_write_kind.dart';
 import 'environment_studio_panel.dart';
 
 /// Point d’entrée Riverpod pour le workspace Environment Studio.
@@ -20,11 +21,16 @@ class EnvironmentStudioWorkspace extends ConsumerWidget {
     }
     return EnvironmentStudioPanel(
       manifest: manifest,
-      onEnvironmentPresetSaved: (nextManifest, preset) {
+      onEnvironmentPresetSaved: (nextManifest, preset, kind) {
+        final msg = switch (kind) {
+          EnvironmentPresetMemoryWriteKind.create =>
+            'Preset d’environnement « ${preset.name} » ajouté au projet.',
+          EnvironmentPresetMemoryWriteKind.update =>
+            'Preset d’environnement « ${preset.name} » mis à jour dans le projet.',
+        };
         ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
               nextManifest,
-              statusMessage:
-                  'Preset d’environnement « ${preset.name} » ajouté au projet.',
+              statusMessage: msg,
             );
       },
     );
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
index 8c6a8aa8..3ea1a694 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_detail.dart
@@ -13,6 +13,7 @@ class EnvironmentPresetDetail extends StatelessWidget {
     required this.report,
     required this.labelColor,
     required this.subtleColor,
+    this.onEditAsDraft,
   });
 
   final EnvironmentPreset preset;
@@ -20,6 +21,9 @@ class EnvironmentPresetDetail extends StatelessWidget {
   final Color labelColor;
   final Color subtleColor;
 
+  /// Lot 18 : ouvre le brouillon d’édition (null = action masquée).
+  final VoidCallback? onEditAsDraft;
+
   @override
   Widget build(BuildContext context) {
     final p = preset;
@@ -31,13 +35,30 @@ class EnvironmentPresetDetail extends StatelessWidget {
       crossAxisAlignment: CrossAxisAlignment.stretch,
       key: const Key('environment-studio-detail-root'),
       children: [
-        Text(
-          'Détail du preset',
-          style: TextStyle(
-            color: labelColor,
-            fontSize: 17,
-            fontWeight: FontWeight.w800,
-          ),
+        Row(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Expanded(
+              child: Text(
+                'Détail du preset',
+                style: TextStyle(
+                  color: labelColor,
+                  fontSize: 17,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+            ),
+            if (onEditAsDraft != null) ...[
+              const SizedBox(width: 10),
+              CupertinoButton(
+                key: const Key('environment-studio-edit-as-draft'),
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
+                onPressed: onEditAsDraft,
+                child: const Text('Modifier en brouillon'),
+              ),
+            ],
+          ],
         ),
         const SizedBox(height: 14),
         _sectionCard(
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
index 73d1e885..e5f74914 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart
@@ -3,6 +3,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../../ui/shared/cupertino_editor_widgets.dart';
 import '../authoring/environment_preset_draft.dart';
+import '../environment_preset_memory_write_kind.dart';
 import 'environment_generation_params_draft_editor.dart';
 import 'environment_palette_item_draft_editor.dart';
 import 'environment_preset_draft_validation_view.dart';
@@ -15,6 +16,7 @@ class EnvironmentPresetDraftForm extends StatefulWidget {
     required this.manifest,
     this.knownTemplateIds = const <String>{},
     required this.draft,
+    this.existingPresetId,
     required this.validation,
     required this.projectElements,
     required this.onChanged,
@@ -33,6 +35,10 @@ class EnvironmentPresetDraftForm extends StatefulWidget {
   final List<ProjectElementEntry> projectElements;
 
   final EnvironmentPresetDraft draft;
+
+  /// Lot 18 : si non null, id verrouillé + validation `existingPresetId`.
+  final String? existingPresetId;
+
   final EnvironmentPresetDraftValidationReport validation;
   final ValueChanged<EnvironmentPresetDraft> onChanged;
   final VoidCallback onCancel;
@@ -40,8 +46,10 @@ class EnvironmentPresetDraftForm extends StatefulWidget {
 
   /// `null` : enregistrement indisponible (bouton désactivé + note).
   final void Function(
-          ProjectManifest nextManifest, EnvironmentPreset savedPreset)?
-      onEnvironmentPresetSaved;
+    ProjectManifest nextManifest,
+    EnvironmentPreset savedPreset,
+    EnvironmentPresetMemoryWriteKind kind,
+  )? onEnvironmentPresetSaved;
 
   @override
   State<EnvironmentPresetDraftForm> createState() =>
@@ -70,6 +78,19 @@ class _EnvironmentPresetDraftFormState
     _sortCtrl = TextEditingController(text: d.sortOrder.toString());
   }
 
+  String _lockedIdText() {
+    final id = widget.existingPresetId?.trim();
+    return (id == null || id.isEmpty) ? '' : id;
+  }
+
+  String _effectiveIdForDraft() {
+    final locked = _lockedIdText();
+    if (locked.isNotEmpty) {
+      return locked;
+    }
+    return _idCtrl.text;
+  }
+
   @override
   void dispose() {
     _idCtrl.dispose();
@@ -83,7 +104,7 @@ class _EnvironmentPresetDraftFormState
   EnvironmentPresetDraft _draftFromControllers() {
     final so = int.tryParse(_sortCtrl.text.trim());
     return EnvironmentPresetDraft(
-      id: _idCtrl.text,
+      id: _effectiveIdForDraft(),
       name: _nameCtrl.text,
       templateId: _templateCtrl.text,
       palette: widget.draft.palette,
@@ -103,7 +124,7 @@ class _EnvironmentPresetDraftFormState
     final so = int.tryParse(_sortCtrl.text.trim());
     widget.onChanged(
       EnvironmentPresetDraft(
-        id: _idCtrl.text,
+        id: _effectiveIdForDraft(),
         name: _nameCtrl.text,
         templateId: _templateCtrl.text,
         palette: palette ?? widget.draft.palette,
@@ -146,6 +167,7 @@ class _EnvironmentPresetDraftFormState
       draft,
       manifest: widget.manifest,
       knownTemplateIds: widget.knownTemplateIds,
+      existingPresetId: widget.existingPresetId,
     );
     if (validation.hasErrors) {
       return;
@@ -156,13 +178,16 @@ class _EnvironmentPresetDraftFormState
         widget.manifest,
         preset,
       );
-      save(nextManifest, preset);
+      final kind = widget.existingPresetId != null
+          ? EnvironmentPresetMemoryWriteKind.update
+          : EnvironmentPresetMemoryWriteKind.create;
+      save(nextManifest, preset, kind);
     } catch (e, st) {
       debugPrint('EnvironmentPresetDraftForm: ajout mémoire impossible: $e');
       debugPrint('$st');
       setState(() {
         _saveErrorMessage =
-            'Impossible d’ajouter le preset au projet en mémoire.';
+            'Impossible d’appliquer le preset au projet en mémoire.';
       });
     }
   }
@@ -173,6 +198,7 @@ class _EnvironmentPresetDraftFormState
     final subtle = EditorChrome.subtleLabel(context);
     final canSaveToProject =
         widget.onEnvironmentPresetSaved != null && !widget.validation.hasErrors;
+    final isEdit = widget.existingPresetId != null;
 
     return SingleChildScrollView(
       key: const Key('environment-studio-draft-form-scroll'),
@@ -181,7 +207,9 @@ class _EnvironmentPresetDraftFormState
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           Text(
-            'Nouveau preset d’environnement',
+            isEdit
+                ? 'Modifier un preset d’environnement'
+                : 'Nouveau preset d’environnement',
             key: const Key('environment-studio-draft-form-title'),
             style: TextStyle(
               color: label,
@@ -199,10 +227,16 @@ class _EnvironmentPresetDraftFormState
                 color: EditorChrome.accentWarm.withValues(alpha: 0.45),
               ),
             ),
-            child: const Text(
-              'Brouillon local non sauvegardé',
-              key: Key('environment-studio-draft-local-badge'),
-              style: TextStyle(
+            child: Text(
+              isEdit
+                  ? 'Brouillon de modification non sauvegardé'
+                  : 'Brouillon local non sauvegardé',
+              key: Key(
+                isEdit
+                    ? 'environment-studio-draft-edit-badge'
+                    : 'environment-studio-draft-local-badge',
+              ),
+              style: const TextStyle(
                 color: EditorChrome.accentWarm,
                 fontSize: 12,
                 fontWeight: FontWeight.w700,
@@ -211,9 +245,12 @@ class _EnvironmentPresetDraftFormState
           ),
           const SizedBox(height: 10),
           Text(
-            'Remplissez le brouillon puis « Ajouter au projet en mémoire » pour '
-            'l’intégrer au manifest de la session (projet marqué modifié ; '
-            'aucune sauvegarde disque automatique).',
+            isEdit
+                ? 'Modifiez ce preset en brouillon, puis mettez à jour le projet en mémoire. '
+                    'Aucune sauvegarde disque automatique.'
+                : 'Remplissez le brouillon puis « Ajouter au projet en mémoire » pour '
+                    'l’intégrer au manifest de la session (projet marqué modifié ; '
+                    'aucune sauvegarde disque automatique).',
             key: const Key('environment-studio-draft-form-intro'),
             style: TextStyle(
               color: subtle,
@@ -227,10 +264,24 @@ class _EnvironmentPresetDraftFormState
           CupertinoTextField(
             key: const Key('environment-studio-draft-field-id'),
             controller: _idCtrl,
+            enabled: !isEdit,
             placeholder: 'Identifiant unique',
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
             onChanged: (_) => _emit(),
           ),
+          if (isEdit) ...[
+            const SizedBox(height: 6),
+            Text(
+              'L’id est verrouillé dans cette version pour préserver les références des maps.',
+              key: const Key('environment-studio-draft-id-locked-hint'),
+              style: TextStyle(
+                color: subtle,
+                fontSize: 11,
+                fontWeight: FontWeight.w600,
+                height: 1.35,
+              ),
+            ),
+          ],
           const SizedBox(height: 14),
           _fieldLabel(context, 'Nom'),
           const SizedBox(height: 4),
@@ -291,7 +342,7 @@ class _EnvironmentPresetDraftFormState
           const SizedBox(height: 8),
           Text(
             'Les éléments doivent exister dans le projet ; ils sont copiés dans le '
-            'preset lors de l’ajout en mémoire.',
+            'preset lors de l’application au projet en mémoire.',
             key: const Key('environment-studio-draft-palette-local-note'),
             style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
           ),
@@ -346,7 +397,7 @@ class _EnvironmentPresetDraftFormState
           if (widget.validation.hasErrors) ...[
             const SizedBox(height: 10),
             Text(
-              'Corrigez les erreurs du brouillon pour l’ajouter au projet.',
+              'Corrigez les erreurs du brouillon pour appliquer au projet en mémoire.',
               key: const Key('environment-studio-draft-save-disabled-hint'),
               style: TextStyle(
                 color: CupertinoColors.systemOrange.resolveFrom(context),
@@ -360,7 +411,7 @@ class _EnvironmentPresetDraftFormState
               !widget.validation.hasErrors) ...[
             const SizedBox(height: 10),
             Text(
-              'Les avertissements ne bloquent pas l’ajout au projet.',
+              'Les avertissements ne bloquent pas l’application au projet en mémoire.',
               key: const Key('environment-studio-draft-save-warnings-hint'),
               style: TextStyle(
                 color: CupertinoColors.systemYellow.resolveFrom(context),
@@ -407,7 +458,11 @@ class _EnvironmentPresetDraftFormState
                 padding:
                     const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                 onPressed: canSaveToProject ? _saveDraftToProject : null,
-                child: const Text('Ajouter au projet en mémoire'),
+                child: Text(
+                  isEdit
+                      ? 'Mettre à jour le projet en mémoire'
+                      : 'Ajouter au projet en mémoire',
+                ),
               ),
             ],
           ),
diff --git a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
index 3b107f45..00df0f98 100644
--- a/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
+++ b/packages/map_editor/lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart
@@ -1,22 +1,31 @@
 import 'package:flutter/cupertino.dart';
 
 import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../environment_preset_memory_write_kind.dart';
 
-/// Retour visuel local après ajout d’un preset au manifest en mémoire (Lot 17).
+/// Retour visuel local après écriture mémoire d’un preset (Lots 17–18).
 ///
 /// Complète le [statusMessage] du shell sans le remplacer ; reste dans le panel.
 class EnvironmentPresetSaveFeedback extends StatelessWidget {
   const EnvironmentPresetSaveFeedback({
     super.key,
     required this.presetName,
+    required this.writeKind,
   });
 
   final String presetName;
+  final EnvironmentPresetMemoryWriteKind writeKind;
 
   @override
   Widget build(BuildContext context) {
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
+    final line1 = switch (writeKind) {
+      EnvironmentPresetMemoryWriteKind.create =>
+        'Preset « $presetName » ajouté au projet en mémoire.',
+      EnvironmentPresetMemoryWriteKind.update =>
+        'Preset « $presetName » mis à jour dans le projet en mémoire.',
+    };
     return DecoratedBox(
       key: const Key('environment-studio-post-save-local-feedback'),
       decoration: BoxDecoration(
@@ -32,7 +41,7 @@ class EnvironmentPresetSaveFeedback extends StatelessWidget {
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             Text(
-              'Preset « $presetName » ajouté au projet en mémoire.',
+              line1,
               key: const Key('environment-studio-post-save-line-1'),
               style: TextStyle(
                 color: label,
diff --git a/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart b/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
index 66c21913..a79d5b3d 100644
--- a/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_preset_save_to_manifest_test.dart
@@ -5,6 +5,7 @@ import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
 import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
 
 import '../shell_chrome_test_harness.dart';
@@ -17,7 +18,7 @@ void main() {
         await _pumpPanel(
           tester,
           manifest: _manifest(elements: [_element(id: 'e1')]),
-          onSaved: (_, __) {},
+          onSaved: (_, __, ___) {},
         );
         await tester
             .tap(find.byKey(const Key('environment-studio-open-draft')));
@@ -41,7 +42,7 @@ void main() {
         );
         expect(
           find.text(
-            'Corrigez les erreurs du brouillon pour l’ajouter au projet.',
+            'Corrigez les erreurs du brouillon pour appliquer au projet en mémoire.',
           ),
           findsOneWidget,
         );
@@ -85,9 +86,10 @@ void main() {
         await _pumpPanel(
           tester,
           manifest: initial,
-          onSaved: (m, p) {
+          onSaved: (m, p, k) {
             receivedManifest = m;
             receivedPreset = p;
+            expect(k, EnvironmentPresetMemoryWriteKind.create);
           },
         );
         await tester
@@ -177,7 +179,7 @@ void main() {
           environmentPresets: [_preset(id: 'forest')],
           elements: [_element(id: 'e1')],
         ),
-        onSaved: (_, __) => calls++,
+        onSaved: (_, __, ___) => calls++,
       );
       await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
       await tester.pumpAndSettle();
@@ -222,7 +224,7 @@ void main() {
       await _pumpPanel(
         tester,
         manifest: _manifest(elements: [_element(id: 'e1')]),
-        onSaved: (_, __) => calls++,
+        onSaved: (_, __, ___) => calls++,
       );
       await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
       await tester.pumpAndSettle();
@@ -268,7 +270,7 @@ void main() {
         tester,
         manifest: _manifest(elements: [_element(id: 'e1')]),
         knownTemplateIds: {'only_this'},
-        onSaved: (_, __) => calls++,
+        onSaved: (_, __, ___) => calls++,
       );
       await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
       await tester.pumpAndSettle();
@@ -301,7 +303,8 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.text('Les avertissements ne bloquent pas l’ajout au projet.'),
+        find.text(
+            'Les avertissements ne bloquent pas l’application au projet en mémoire.'),
         findsOneWidget,
       );
       expect(
@@ -325,7 +328,7 @@ void main() {
         await _pumpPanel(
           tester,
           manifest: _manifest(elements: [_element(id: 'e1')]),
-          onSaved: (_, __) {},
+          onSaved: (_, __, ___) {},
         );
         await tester
             .tap(find.byKey(const Key('environment-studio-open-draft')));
@@ -378,7 +381,7 @@ void main() {
         await _pumpPanel(
           tester,
           manifest: _manifest(elements: [_element(id: 'e1')]),
-          onSaved: (_, __) => throw StateError('simulé'),
+          onSaved: (_, __, ___) => throw StateError('simulé'),
         );
         await tester
             .tap(find.byKey(const Key('environment-studio-open-draft')));
@@ -420,7 +423,7 @@ void main() {
         );
         expect(
           find.text(
-            'Impossible d’ajouter le preset au projet en mémoire.',
+            'Impossible d’appliquer le preset au projet en mémoire.',
           ),
           findsOneWidget,
         );
@@ -597,7 +600,11 @@ class _ManifestSyncPanelHost extends StatefulWidget {
 
   final ProjectManifest initialManifest;
   final Set<String> knownTemplateIds;
-  final void Function(ProjectManifest, EnvironmentPreset)? onSaved;
+  final void Function(
+    ProjectManifest,
+    EnvironmentPreset,
+    EnvironmentPresetMemoryWriteKind,
+  )? onSaved;
 
   @override
   State<_ManifestSyncPanelHost> createState() => _ManifestSyncPanelHostState();
@@ -627,8 +634,8 @@ class _ManifestSyncPanelHostState extends State<_ManifestSyncPanelHost> {
       knownTemplateIds: widget.knownTemplateIds,
       onEnvironmentPresetSaved: widget.onSaved == null
           ? null
-          : (next, preset) {
-              widget.onSaved!(next, preset);
+          : (next, preset, kind) {
+              widget.onSaved!(next, preset, kind);
               setState(() => _manifest = next);
             },
     );
@@ -639,7 +646,11 @@ Future<void> _pumpPanel(
   WidgetTester tester, {
   required ProjectManifest manifest,
   Set<String> knownTemplateIds = const {},
-  void Function(ProjectManifest, EnvironmentPreset)? onSaved,
+  void Function(
+    ProjectManifest,
+    EnvironmentPreset,
+    EnvironmentPresetMemoryWriteKind,
+  )? onSaved,
 }) async {
   tester.view.physicalSize = const Size(900, 2200);
   tester.view.devicePixelRatio = 1.0;
diff --git a/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart b/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
index 87d3d705..5b150695 100644
--- a/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
+++ b/packages/map_editor/test/environment_studio/environment_studio_workspace_test.dart
@@ -2,6 +2,7 @@ import 'package:flutter/cupertino.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
 import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';
 
 void main() {
@@ -99,38 +100,41 @@ void main() {
       );
     });
 
-    testWidgets('browser : un seul CupertinoButton « Préparer un preset »', (
-      tester,
-    ) async {
+    testWidgets(
+        'browser : « Préparer un preset » + « Modifier en brouillon » (détail)',
+        (tester) async {
       await _pumpPanel(
         tester,
         _manifest(
           environmentPresets: [_preset(id: 'x')],
           elements: [_element(id: 'elm')],
         ),
+        onEnvironmentPresetSaved: (_, __, ___) {},
       );
 
-      final panel = find.byType(EnvironmentStudioPanel);
-      expect(
-        find.descendant(of: panel, matching: find.byType(CupertinoButton)),
-        findsOneWidget,
-      );
-      expect(
-        find.descendant(
-          of: panel,
-          matching: find.byKey(const Key('environment-studio-open-draft')),
-        ),
-        findsOneWidget,
-      );
+      expect(find.text('Préparer un preset'), findsOneWidget);
+      expect(find.byKey(const Key('environment-studio-edit-as-draft')),
+          findsOneWidget);
     });
   });
 }
 
-Future<void> _pumpPanel(WidgetTester tester, ProjectManifest manifest) async {
+Future<void> _pumpPanel(
+  WidgetTester tester,
+  ProjectManifest manifest, {
+  void Function(
+    ProjectManifest,
+    EnvironmentPreset,
+    EnvironmentPresetMemoryWriteKind,
+  )? onEnvironmentPresetSaved,
+}) async {
   await tester.pumpWidget(
     MacosApp(
       home: CupertinoPageScaffold(
-        child: EnvironmentStudioPanel(manifest: manifest),
+        child: EnvironmentStudioPanel(
+          manifest: manifest,
+          onEnvironmentPresetSaved: onEnvironmentPresetSaved,
+        ),
       ),
     ),
   );
```

## 19. Auto-review

- **Points solides** : un seul formulaire ; id forcé côté draft ; `existingPresetId` partout où requis ; tests couvrant workspace Riverpod réel ; grep disque explicite.
- **Points discutables** : duplication du widget hôte `_ManifestSyncPanelHost` entre `environment_preset_save_to_manifest_test.dart` et `environment_preset_edit_existing_test.dart` (acceptable pour isolation, refactor global hors lot).
- **Corrections après auto-review** : palette `tree_a` alignée sur `buildShellChromeProject` dans le test workspace ; test browser avec callback noop pour afficher le bouton ; suppression import Riverpod inutilisé.
- **Risques restants** : si un parent oublie le 3e paramètre du callback, erreur de compilation (intentionnel) ; `flutter test` package entier reste rouge (34 échecs hors lot).
- **Regard critique sur le prompt** :
  - **Rename d’id maintenant ?** Non — risque pour `presetId` et hors périmètre ; verrouillage UI + `existingPresetId` suffisent en V0.
  - **Id verrouillé frustrant ?** Oui mais nécessaire pour cohérence maps ; message d’aide explicite.
  - **Écran séparé pour editDraft ?** Non requis ; un mode local évite la duplication de formulaire.
  - **Callback create/update trop complexe ?** Un enum à trois arguments reste minimal vs deux callbacks.
  - **Évitement disque / générateur / layers ?** Oui — grep + périmètre fichiers + pas de changement `map_core`.

## 20. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
Lot 18 livré : édition brouillon d’un preset existant, id non renommable, upsert mémoire, feedback et statusMessage create/update, tests et rapport ; suite flutter map_editor globale non verte (34 échecs préexistants hors périmètre).
```

Prochain lot recommandé :

```text
Environment-19 — Environment Layer Creation in Map Editor V0
```

---

## Evidence Pack (confirmations explicites)

- **Git status initial** : voir §16 (instantané début conversation + modifications `map_core` non traitées ici).
- **Git status final** : voir §16 (liste exacte).
- **Fichiers inspectés (audit)** : listés §3 et chemins §12.
- **Contenu fichiers créés** : §17.1–17.2 ; **diff fichiers modifiés trackés** : §18.
- **Sortie tests ciblés `flutter test test/environment_studio`** : `00:05 +106: All tests passed!`
- **Sortie régressions** : `00:00 +14: All tests passed!` pour `editor_workspace_controller_test` + `top_toolbar_test`.
- **Sortie `flutter analyze` ciblé** : `No issues found! (ran in 2.0s)` exit 0.
- **Grep disque** : sortie complète §10.
- **`flutter test` complet (map_editor)** : dernière ligne `00:57 +939 -34: Some tests failed.` — échecs hors Lot 18.
- **Aucun `ProjectManifest` modèle / fixture canonique modifié** : confirmé (aucun fichier hors liste §12).
- **Aucun `MapLayer` modifié** : confirmé.
- **Id preset existant non modifiable en V0** : confirmé (`enabled: !isEdit` + `_effectiveIdForDraft`).
- **Aucun rename / delete preset** : confirmé (upsert même id uniquement).
- **`upsertProjectEnvironmentPreset` après validation sans erreur** : inchangé ; double validation dans le form avant save.
- **Aucune sauvegarde disque dans ce flux** : confirmé (grep §10).
- **Aucun `FileProjectRepository` / `saveProject` dans `environment_studio/`** : confirmé.
- **Aucun générateur** : confirmé.
- **Aucun `EnvironmentLayer` / `EnvironmentArea` créé ou modifié** : confirmé.
- **Aucun `build_runner` lancé** : confirmé.
- **Aucun fichier generated modifié** : confirmé.
- **Aucun commit / git add / git push** : confirmé (commandes git write interdites respectées).
