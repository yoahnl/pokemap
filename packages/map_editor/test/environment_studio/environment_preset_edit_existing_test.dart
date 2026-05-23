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
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
