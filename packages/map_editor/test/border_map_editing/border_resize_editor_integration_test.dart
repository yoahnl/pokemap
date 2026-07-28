import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('ResizeMapUseCase blocks non-Border cell loss before mutation', () {
    const source = MapData(
      id: 'tile-map',
      name: 'Tile map',
      size: GridSize(width: 2, height: 1),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'ground',
          name: 'Ground',
          tiles: <int>[0, 9],
        ),
      ],
    );

    final result = ResizeMapUseCase().execute(
      source,
      1,
      1,
      tileSizePx: const GridSize(width: 16, height: 16),
    );

    expect(result.canApply, isFalse);
    expect(result.map, isNull);
    expect(result.plan.impacts, hasLength(1));
    expect(result.plan.impacts.single.kind, MapResizeImpactKind.tileLayer);
    expect(source.size, const GridSize(width: 2, height: 1));
  });

  test('ResizeMapUseCase blocks destructive Border shrink before mutation', () {
    final source = _borderMap();

    final result = ResizeMapUseCase().execute(
      source,
      2,
      1,
      tileSizePx: const GridSize(width: 24, height: 20),
      project: _project(tileWidth: 24, tileHeight: 20),
    );

    expect(result.canApply, isFalse);
    expect(result.map, isNull);
    expect(result.plan.hasDestructiveImpacts, isTrue);
    expect(
      result.plan.impacts.map((value) => value.kind),
      containsAll(<MapResizeImpactKind>[
        MapResizeImpactKind.collisionLayer,
        MapResizeImpactKind.borderLayer,
      ]),
    );
    expect(
      result.diagnosticReport.diagnostics.map((value) => value.code),
      contains('region_cell_clipped'),
    );
    expect(source.size, const GridSize(width: 3, height: 1));
    expect(
      (source.layers
              .whereType<BorderLayer>()
              .single
              .content
              .features
              .single
              .geometry as BorderRegionGeometry)
          .width,
      3,
    );
  });

  test(
      'resizeActiveMap commits once, uses project tile size, and binds feedback to the new map',
      () async {
    final useCase = _RecordingResizeMapUseCase();
    final project = _project(tileWidth: 24, tileHeight: 20);
    final container = ProviderContainer(
      overrides: <Override>[
        resizeMapUseCaseProvider.overrideWith((ref) => useCase),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap(destructiveEdge: false);
    notifier.state = EditorState(
      project: project,
      activeMap: source,
      activeLayerId: 'borders',
      hoveredTile: const GridPos(x: 2, y: 0),
    );

    await notifier.resizeActiveMap(2, 1);

    final resized = notifier.state.activeMap!;
    expect(useCase.receivedTileSize, const GridSize(width: 24, height: 20));
    expect(useCase.receivedProject, same(project));
    expect(resized, isNot(same(source)));
    expect(resized.size, const GridSize(width: 2, height: 1));
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(notifier.state.mapUndoStack.single.map, same(source));
    expect(notifier.state.hoveredTile, isNull);

    expect(container.read(borderResizeFeedbackProvider), isNull);

    final collision = resized.layers.whereType<CollisionLayer>().single;
    expect(collision.collisions, const <bool>[true, false]);
    expect(resized.layers.whereType<CollisionLayer>(), hasLength(1));
    expect(
      resized.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .materialization,
      isNull,
      reason: 'resize must not synthesize runtime or collision output',
    );
  });

  test('resizeActiveMap rejects Border errors without mutation or history',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final malformed = _borderMap(regionWidth: 2);
    notifier.state = EditorState(
      project: _project(),
      activeMap: malformed,
      activeLayerId: 'borders',
    );
    container.read(borderResizeFeedbackProvider.notifier).state =
        _staleFeedback(malformed);

    await notifier.resizeActiveMap(2, 1);

    expect(notifier.state.activeMap, same(malformed));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('impact'));
    final feedback = container.read(borderResizeFeedbackProvider);
    expect(feedback, isNotNull);
    expect(feedback!.appliesTo(malformed), isTrue);
    expect(feedback.diagnosticReport.hasErrors, isTrue);
    expect(
      feedback.diagnosticReport.diagnostics.map((value) => value.code),
      contains('region_size_mismatch'),
    );
  });

  test('resizeActiveMap refuses to guess Border tile size without a project',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap();
    notifier.state = EditorState(
      activeMap: source,
      activeLayerId: 'borders',
    );

    await notifier.resizeActiveMap(2, 1);

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('réglages de tuile'));
    expect(container.read(borderResizeFeedbackProvider), isNull);
  });

  test(
      'resizeActiveMap rejects destructive impacts without mutation or history',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap();
    notifier.state = EditorState(
      project: _project(),
      activeMap: source,
      activeLayerId: 'borders',
    );

    await notifier.resizeActiveMap(2, 1);

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('2 impacts'));
    expect(
      notifier.planActiveMapResize(2, 1)?.canApply,
      isFalse,
    );
  });

  test('resizeActiveMap treats same-size resize as a history-free no-op',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap();
    notifier.state = EditorState(
      project: _project(),
      activeMap: source,
      activeLayerId: 'borders',
    );
    container.read(borderResizeFeedbackProvider.notifier).state =
        _staleFeedback(source);

    await notifier.resizeActiveMap(3, 1);

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.statusMessage, contains('déjà'));
    expect(container.read(borderResizeFeedbackProvider), isNull);
  });
}

final class _RecordingResizeMapUseCase extends ResizeMapUseCase {
  GridSize? receivedTileSize;
  ProjectManifest? receivedProject;

  @override
  ResizeMapUseCaseResult execute(
    MapData map,
    int width,
    int height, {
    required GridSize tileSizePx,
    ProjectManifest? project,
  }) {
    receivedTileSize = tileSizePx;
    receivedProject = project;
    return super.execute(
      map,
      width,
      height,
      tileSizePx: tileSizePx,
      project: project,
    );
  }
}

ProjectManifest _project({int tileWidth = 16, int tileHeight = 16}) =>
    ProjectManifest(
      name: 'Resize project',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: ProjectSettings(
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
    );

MapData _borderMap({
  int regionWidth = 3,
  bool destructiveEdge = true,
}) =>
    MapData(
      id: 'map',
      name: 'Border resize map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 1),
      layers: <MapLayer>[
        MapLayer.collision(
          id: 'collision',
          name: 'Collisions',
          collisions: <bool>[true, false, destructiveEdge],
        ),
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Côte',
                blueprintId: 'coast-blueprint',
                seed: BorderSignedInt64.zero,
                geometry: BorderRegionGeometry(
                  width: regionWidth,
                  height: 1,
                  cells: regionWidth == 3
                      ? <bool>[false, false, destructiveEdge]
                      : const <bool>[false, false],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
    );

BorderResizeFeedback _staleFeedback(MapData map) => BorderResizeFeedback(
      mapIdentity: map,
      diagnosticReport: BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          BorderDiagnostic(
            code: 'region_cell_clipped',
            severity: BorderDiagnosticSeverity.warning,
            phase: BorderDiagnosticPhase.resize,
            scope: BorderDiagnosticScope.geometry,
            featureId: 'coast',
            suggestedAction: 'border.resize.review_clipped_cells',
          ),
        ],
      ),
    );
