import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/environment_studio/environment_preset_memory_write_kind.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('EnvironmentPresetDraftForm — ajout mémoire (Lot 17)', () {
    testWidgets(
      'brouillon initial invalide : libellé bouton, aide, pas Save/Create/Generate',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __, ___) {},
        );
        await _openCreationPaletteStep(tester);

        expect(find.text('Ajouter au projet en mémoire'), findsOneWidget);
        expect(find.textContaining('Save'), findsNothing);
        expect(find.textContaining('Create'), findsNothing);
        expect(find.textContaining('Generate'), findsNothing);
        expect(
          find.byKey(const Key('environment-studio-draft-save-project')),
          findsOneWidget,
        );
        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNull);
        expect(
          find.byKey(const Key('environment-studio-draft-save-disabled-hint')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Corrigez les erreurs du brouillon pour appliquer au projet en mémoire.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sans callback : bouton désactivé + note indisponible',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
        );
        await _openCreationPaletteStep(tester);

        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNull);
        expect(
          find.byKey(
              const Key('environment-studio-draft-save-unavailable-note')),
          findsOneWidget,
        );
        expect(
          find.text('Ajout au projet indisponible dans ce contexte.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'brouillon valide : callback reçoit manifest + preset, browser + sélection',
      (tester) async {
        ProjectManifest? receivedManifest;
        EnvironmentPreset? receivedPreset;

        final initial = _manifest(elements: [_element(id: 'e1')]);
        await _pumpPanel(
          tester,
          manifest: initial,
          onSaved: (m, p, k) {
            receivedManifest = m;
            receivedPreset = p;
            expect(k, EnvironmentPresetMemoryWriteKind.create);
          },
        );
        await _openCreationPaletteStep(tester);

        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'meadow_new',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Prairie test',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          'prairie_tpl',
        );
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-palette-add-item')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-palette-draft-element-0')),
          'e1',
        );
        await tester.pumpAndSettle();

        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNotNull);

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(receivedManifest, isNotNull);
        expect(receivedPreset, isNotNull);
        expect(receivedPreset!.id, 'meadow_new');
        expect(receivedPreset!.name, 'Prairie test');
        expect(receivedPreset!.templateId, 'prairie_tpl');
        expect(receivedPreset!.palette.single.elementId, 'e1');
        expect(
          receivedManifest!.environmentPresets.map((e) => e.id).toList(),
          contains('meadow_new'),
        );

        expect(find.byKey(const Key('environment-studio-preset-list')),
            findsOneWidget);
        expect(find.text('Prairie test'), findsWidgets);

        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsOneWidget,
        );
        expect(
          find.textContaining('ajouté au projet en mémoire'),
          findsOneWidget,
        );
        expect(
          find.textContaining('sauvegarder le projet'),
          findsOneWidget,
        );
        expect(
          (tester.widget<Text>(
                  find.byKey(const Key('environment-studio-detail-id'))))
              .data,
          'meadow_new',
        );
        expect(
          (tester.widget<Text>(
                  find.byKey(const Key('environment-studio-detail-name'))))
              .data,
          'Prairie test',
        );
      },
    );

    testWidgets('duplicate id : bouton désactivé, callback non invoqué',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(
          environmentPresets: [_preset(id: 'forest')],
          elements: [_element(id: 'e1')],
        ),
        onSaved: (_, __, ___) => calls++,
      );
      await _openCreationPaletteStep(tester);

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'forest',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Doublon',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'e1',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Id déjà utilisé'), findsOneWidget);
      final saveBtn = tester.widget<CupertinoButton>(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      expect(saveBtn.onPressed, isNull);
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('élément palette inconnu : callback non invoqué',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(elements: [_element(id: 'e1')]),
        onSaved: (_, __, ___) => calls++,
      );
      await _openCreationPaletteStep(tester);

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'x',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Nom',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'introuvable',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Élément introuvable'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const Key('environment-studio-draft-save-project')),
            )
            .onPressed,
        isNull,
      );
      expect(calls, 0);
    });

    testWidgets(
        'palette mixte tilesets : bouton désactivé, callback non invoqué',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(
          elements: [
            _element(id: 'grass_a', tilesetId: 'grass'),
            _element(id: 'rock_a', tilesetId: 'rocks'),
          ],
        ),
        onSaved: (_, __, ___) => calls++,
      );
      await _openCreationPaletteStep(tester, tilesetId: 'grass');

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'mixed_tilesets',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'Mix',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        't',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'grass_a',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-1')),
        'rock_a',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tilesets mélangés'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const Key('environment-studio-draft-save-project')),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
    });

    testWidgets('warning template inconnu ne bloque pas l’ajout au projet',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(elements: [_element(id: 'e1')]),
        knownTemplateIds: {'only_this'},
        onSaved: (_, __, ___) => calls++,
      );
      await _openCreationPaletteStep(tester);

      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-id')),
        'warn_tpl',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-name')),
        'W',
      );
      await tester.enterText(
        find.byKey(const Key('environment-studio-draft-field-template')),
        'not_in_set',
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-palette-add-item')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('environment-studio-palette-draft-element-0')),
        'e1',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Template inconnu'), findsOneWidget);
      expect(
        find.byKey(const Key('environment-studio-draft-save-warnings-hint')),
        findsOneWidget,
      );
      expect(
        find.text(
            'Les avertissements ne bloquent pas l’application au projet en mémoire.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CupertinoButton>(
              find.byKey(const Key('environment-studio-draft-save-project')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(
        find.byKey(const Key('environment-studio-draft-save-project')),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    testWidgets(
      'ouvrir un nouveau brouillon efface le feedback local post-save',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __, ___) {},
        );
        await _openCreationPaletteStep(tester);
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'fb_clear',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'NomFb',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          't',
        );
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-palette-add-item')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-palette-draft-element-0')),
          'e1',
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsOneWidget,
        );

        await _openCreationPaletteStep(tester);

        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'callback qui lève : formulaire visible, erreur locale, pas de browser',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __, ___) => throw StateError('simulé'),
        );
        await _openCreationPaletteStep(tester);
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'boom_id',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Boom',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          't',
        );
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-palette-add-item')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-palette-draft-element-0')),
          'e1',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('environment-studio-draft-form-title')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('environment-studio-draft-save-error-message')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Impossible d’appliquer le preset au projet en mémoire.',
          ),
          findsOneWidget,
        );
        expect(
          (tester.widget<CupertinoTextField>(
                  find.byKey(const Key('environment-studio-draft-field-id'))))
              .controller
              ?.text,
          'boom_id',
        );
        expect(
          find.byKey(const Key('environment-studio-preset-list')),
          findsNothing,
        );
      },
    );
  });

  group('EditorNotifier — applyInMemoryProjectManifest (Lot 16)', () {
    test('statusMessage optionnel et errorMessage effacé', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        project: _manifest(elements: const []),
        errorMessage: 'erreur précédente',
        statusMessage: 'ancien',
      );

      notifier.applyInMemoryProjectManifest(
        _manifest(name: 'Après', elements: const []),
        statusMessage: 'Preset d’environnement « X » ajouté au projet.',
      );

      expect(notifier.state.errorMessage, isNull);
      expect(
        notifier.state.statusMessage,
        'Preset d’environnement « X » ajouté au projet.',
      );
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('sans statusMessage : conserve le message de statut précédent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        project: _manifest(elements: const []),
        statusMessage: 'conservé',
      );
      notifier.applyInMemoryProjectManifest(
        _manifest(name: 'N', elements: const []),
      );
      expect(notifier.state.statusMessage, 'conservé');
    });

    test('ne modifie pas activeMap', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      const map = MapData(
        id: 'm1',
        name: 'M',
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[],
      );
      notifier.state = notifier.state.copyWith(
        project: _manifest(elements: const []),
        activeMap: map,
        activeMapPath: 'maps/m1.json',
      );

      notifier.applyInMemoryProjectManifest(
        _manifest(name: 'Touch', elements: const []),
        statusMessage: 'ok',
      );

      expect(notifier.state.activeMap!.id, 'm1');
      expect(notifier.state.activeMapPath, 'maps/m1.json');
    });
  });

  group('Environment Studio workspace — persistance mémoire', () {
    testWidgets(
      'EditorCanvasHost : enregistrement met à jour le projet et dirty',
      (tester) async {
        final container = await pumpEditorCanvasHostHarness(
          tester,
          surfaceSize: const Size(960, 2200),
          initialState: EditorState(
            projectRootPath: '/tmp/lot16_env',
            project: buildShellChromeProject(
              tilesets: const [
                ProjectTilesetEntry(
                  id: 'ts',
                  name: 'Tileset test',
                  relativePath: 'tilesets/ts.png',
                ),
              ],
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

        await _openCreationPaletteStep(tester);

        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-id')),
          'lot16_ws',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-name')),
          'Depuis workspace',
        );
        await tester.enterText(
          find.byKey(const Key('environment-studio-draft-field-template')),
          'tpl_ws',
        );
        await tester.tap(
          find.byKey(const Key('environment-studio-draft-palette-add-item')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('environment-studio-palette-draft-element-0')),
          'tree_a',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        await tester.pumpAndSettle();

        final snap = container.read(editorNotifierProvider);
        expect(snap.isProjectDirty, isTrue);
        expect(
          snap.project!.environmentPresets.map((e) => e.id),
          contains('lot16_ws'),
        );
        expect(
          snap.statusMessage,
          'Preset d’environnement « Depuis workspace » ajouté au projet.',
        );
        expect(find.byKey(const Key('environment-studio-preset-list')),
            findsOneWidget);
        expect(
          find.byKey(const Key('environment-studio-post-save-local-feedback')),
          findsOneWidget,
        );
        expect(
          find.textContaining('ajouté au projet en mémoire'),
          findsOneWidget,
        );
      },
    );
  });
}

/// Rejoue le rafraîchissement Riverpod du manifest après enregistrement mémoire.
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

ProjectManifest _manifest({
  List<EnvironmentPreset> environmentPresets = const [],
  List<ProjectElementEntry> elements = const [],
  String name = 't-save',
}) {
  final tilesetIds = <String>{};
  for (final element in elements) {
    final id = element.tilesetId.trim();
    if (id.isNotEmpty) {
      tilesetIds.add(id);
    }
  }
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: [
      for (final id in tilesetIds) _tileset(id: id),
    ],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectTilesetEntry _tileset({required String id}) {
  return ProjectTilesetEntry(
    id: id,
    name: id,
    relativePath: 'tilesets/$id.png',
  );
}

EnvironmentPreset _preset({required String id}) {
  return EnvironmentPreset(
    id: id,
    name: 'P $id',
    templateId: 'tpl',
    palette: [
      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
    sortOrder: 0,
  );
}

ProjectElementEntry _element({
  required String id,
  String tilesetId = 'ts',
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
