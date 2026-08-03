import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
      'world map Save command shows the shared guard and Cancel writes nothing',
      (tester) async {
    final harness = await _pump(tester);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('world-map-command-save'),
      ),
    );
    await tester.pumpAndSettle();

    _expectSharedDialog();
    await tester.tap(find.text('Annuler la sauvegarde'));
    await tester.pumpAndSettle();

    expect(harness.repository.savedMaps, isEmpty);
    expect(harness.preview.current.phase, BorderPreviewPhase.resolved);
  });

  testWidgets('Cmd/Ctrl+S uses the shared guard and Apply saves the candidate',
      (tester) async {
    final harness = await _pump(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    _expectSharedDialog();
    await tester.tap(find.text('Appliquer et sauvegarder'));
    await tester.pumpAndSettle();

    expect(harness.repository.savedMaps, hasLength(1));
    expect(harness.repository.savedMaps.single.name, 'Applied candidate');
    expect(
      harness.container.read(editorNotifierProvider).mapUndoStack,
      hasLength(1),
    );
    expect(harness.preview.current, const BorderPreviewState.idle());
  });

  testWidgets(
      'stage-header save uses the shared guard and Discard saves current map',
      (tester) async {
    final harness = await _pump(tester);
    final stageMenu = find.byWidgetPredicate(
      (widget) =>
          widget is MacosPulldownButton &&
          widget.items.whereType<MacosPulldownMenuItem>().any(
                (item) => item.label == 'Sauvegarder la carte',
              ),
    );
    expect(stageMenu, findsOneWidget);

    await tester.tap(stageMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauvegarder la carte').last);
    await tester.pumpAndSettle();

    _expectSharedDialog();
    await tester.tap(find.text('Abandonner l’aperçu et sauvegarder'));
    await tester.pumpAndSettle();

    expect(harness.repository.savedMaps, hasLength(1));
    expect(harness.repository.savedMaps.single.name, 'Base map');
    expect(
      harness.container.read(editorNotifierProvider).mapUndoStack,
      isEmpty,
    );
    expect(harness.preview.current, const BorderPreviewState.idle());
  });
}

void _expectSharedDialog() {
  expect(
    find.byKey(const Key('pending-border-save-dialog')),
    findsOneWidget,
  );
  expect(find.text('Aperçu de bordure en attente'), findsOneWidget);
  expect(find.text('Appliquer et sauvegarder'), findsOneWidget);
  expect(find.text('Abandonner l’aperçu et sauvegarder'), findsOneWidget);
  expect(find.text('Annuler la sauvegarde'), findsOneWidget);
}

Future<_EntryPointHarness> _pump(WidgetTester tester) async {
  final project = _project();
  final map = _map();
  final preview = BorderPreviewController(resolver: (_) => _result());
  final repository = _RecordingMapRepository();
  final container = await pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: '/project',
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeMapPath: '/project/maps/map.json',
      activeLayerId: 'borders',
      savedMapSnapshot: map,
      isDirty: true,
    ),
    overrides: <Override>[
      mapRepositoryProvider.overrideWith((ref) => repository),
      borderPreviewControllerProvider.overrideWith((ref) => preview),
      pendingBorderSaveGuardProvider.overrideWithValue(
        PendingBorderSaveGuard(
          applier: ({required map, required transaction}) =>
              map.copyWith(name: 'Applied candidate'),
        ),
      ),
    ],
  );
  container
      .read(activeBorderFeatureControllerProvider.notifier)
      .selectFeature(map: map, layerId: 'borders', featureId: 'coast');
  preview.begin(
    map: map,
    layerId: 'borders',
    featureId: 'coast',
    context: createEditorBorderPreviewContext(
      projectRootPath: '/project',
      activeMapPath: '/project/maps/map.json',
      project: project,
      map: map,
    ),
  );
  preview.resolve(
    blueprintRevision: null,
    tileSizePx: const GridSize(width: 16, height: 16),
    visualSnapshots: const <BorderVisualSnapshot>[],
    resolverVersion: 1,
  );
  await tester.pump();
  return _EntryPointHarness(
    container: container,
    preview: preview,
    repository: repository,
  );
}

ProjectManifest _project() => const ProjectManifest(
      name: 'UI save guard',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      borderCatalog: ProjectBorderCatalog.empty(),
    );

MapData _map() => MapData(
      id: 'map',
      name: 'Base map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Côte',
                blueprintId: 'coast-blueprint',
                seed: BorderSignedInt64.fromInt(7),
                geometry: BorderRegionGeometry(
                  width: 4,
                  height: 4,
                  cells: const <bool>[
                    true,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                    false,
                  ],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
    );

BorderResolutionResult _result() => BorderResolutionResult(
      materialization: BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: 1,
          blueprintRevision: 1,
          components: BorderInputFingerprints(
            blueprint: _fingerprint('1'),
            geometryAndSeed: _fingerprint('2'),
            parameters: _fingerprint('3'),
            overrides: _fingerprint('4'),
            keepOutRegions: _fingerprint('5'),
            mapContext: _fingerprint('6'),
            visualSnapshots: _fingerprint('7'),
          ),
          inputFingerprint: _fingerprint('8'),
          outputFingerprint: _fingerprint('9'),
        ),
        ground: <BorderResolvedGroundCell>[
          BorderResolvedGroundCell(
            x: 0,
            y: 0,
            visualSnapshotId: 'border-snapshot-sha256:${'a' * 64}',
            resolvedRole: SurfaceVariantRole.isolated,
          ),
        ],
        placements: const <BorderResolvedPlacement>[],
      ),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

String _fingerprint(String digit) => 'sha256:${digit * 64}';

final class _EntryPointHarness {
  const _EntryPointHarness({
    required this.container,
    required this.preview,
    required this.repository,
  });

  final ProviderContainer container;
  final BorderPreviewController preview;
  final _RecordingMapRepository repository;
}

final class _RecordingMapRepository implements MapRepository {
  final List<MapData> savedMaps = <MapData>[];

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    savedMaps.add(map);
  }

  @override
  Future<MapData> loadMap(String path) => throw UnimplementedError();

  @override
  Future<void> deleteMap(String path) => throw UnimplementedError();

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      throw UnimplementedError();
}
