import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/environment_studio/environment_studio_panel.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('EnvironmentPresetDraftForm — Enregistrer dans le projet', () {
    testWidgets(
      'brouillon initial invalide : bouton désactivé + aide visible',
      (tester) async {
        await _pumpPanel(
          tester,
          manifest: _manifest(elements: [_element(id: 'e1')]),
          onSaved: (_, __) {},
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

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
            'Corrigez les erreurs du brouillon pour l’enregistrer dans le projet.',
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
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

        final saveBtn = tester.widget<CupertinoButton>(
          find.byKey(const Key('environment-studio-draft-save-project')),
        );
        expect(saveBtn.onPressed, isNull);
        expect(
          find.byKey(
              const Key('environment-studio-draft-save-unavailable-note')),
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
          onSaved: (m, p) {
            receivedManifest = m;
            receivedPreset = p;
          },
        );
        await tester
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

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
        onSaved: (_, __) => calls++,
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

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
        onSaved: (_, __) => calls++,
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

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

    testWidgets('warning template inconnu ne bloque pas l’enregistrement',
        (tester) async {
      var calls = 0;
      await _pumpPanel(
        tester,
        manifest: _manifest(elements: [_element(id: 'e1')]),
        knownTemplateIds: {'only_this'},
        onSaved: (_, __) => calls++,
      );
      await tester.tap(find.byKey(const Key('environment-studio-open-draft')));
      await tester.pumpAndSettle();

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
            .tap(find.byKey(const Key('environment-studio-open-draft')));
        await tester.pumpAndSettle();

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
  final void Function(ProjectManifest, EnvironmentPreset)? onSaved;

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
          : (next, preset) {
              widget.onSaved!(next, preset);
              setState(() => _manifest = next);
            },
    );
  }
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required ProjectManifest manifest,
  Set<String> knownTemplateIds = const {},
  void Function(ProjectManifest, EnvironmentPreset)? onSaved,
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
  String name = 't-save',
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    environmentPresets: environmentPresets,
    elements: elements,
    surfaceCatalog: ProjectSurfaceCatalog(),
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
