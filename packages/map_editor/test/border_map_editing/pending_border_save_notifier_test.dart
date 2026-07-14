import 'dart:io';

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
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('EditorNotifier pending Border save transaction', () {
    test('requests a decision and Cancel Save performs zero writes or history',
        () async {
      final fixture = _fixture();
      final beforeHistory = fixture.notifier.state.mapUndoStack;
      final beforeStroke = fixture.notifier.state.mapStrokeStart;

      final first = await fixture.notifier.saveActiveMap();

      expect(first, ActiveMapSaveOutcome.pendingBorderDecisionRequired);
      expect(fixture.repository.savedMaps, isEmpty);
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.notifier.state.mapUndoStack, beforeHistory);
      expect(fixture.notifier.state.mapUndoStack.single,
          same(beforeHistory.single));
      expect(fixture.notifier.state.mapStrokeStart, same(beforeStroke));
      expect(fixture.preview.current.phase, BorderPreviewPhase.resolved);

      final cancelled = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.cancelSave,
      );

      expect(cancelled, ActiveMapSaveOutcome.cancelled);
      expect(fixture.repository.savedMaps, isEmpty);
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.notifier.state.mapUndoStack, beforeHistory);
      expect(fixture.notifier.state.mapUndoStack.single,
          same(beforeHistory.single));
      expect(fixture.notifier.state.mapStrokeStart, same(beforeStroke));
      expect(fixture.preview.current.phase, BorderPreviewPhase.resolved);
      fixture.dispose();
    });

    test(
        'Apply persists first, then records exactly one undo and clears preview',
        () async {
      final candidate = _richCandidateMap();
      final fixture = _fixture(candidate: candidate, withPendingStroke: false);
      final initialHistoryLength = fixture.notifier.state.mapUndoStack.length;

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.saved);
      expect(fixture.repository.savedMaps, <MapData>[candidate]);
      expect(fixture.repository.mapSeenInNotifierDuringWrite,
          same(fixture.baseMap));
      expect(fixture.repository.previewPhaseDuringWrite,
          BorderPreviewPhase.resolved);
      expect(fixture.notifier.state.activeMap, same(candidate));
      expect(
        fixture.notifier.state.mapUndoStack,
        hasLength(initialHistoryLength + 1),
      );
      expect(
          fixture.notifier.state.mapUndoStack.last.map, same(fixture.baseMap));
      expect(fixture.notifier.state.mapRedoStack, isEmpty);
      expect(fixture.notifier.state.savedMapSnapshot, same(candidate));
      expect(fixture.notifier.state.isDirty, isFalse);
      expect(fixture.preview.current, const BorderPreviewState.idle());
      fixture.dispose();
    });

    test(
        'successful Apply finalizes an earlier stroke after persistence and before the Border undo',
        () async {
      final candidate = _richCandidateMap();
      final fixture = _fixture(candidate: candidate);
      final pendingStroke = fixture.notifier.state.mapStrokeStart;
      final initialHistoryLength = fixture.notifier.state.mapUndoStack.length;

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.saved);
      expect(
        fixture.repository.strokeSeenInNotifierDuringWrite,
        same(pendingStroke),
      );
      expect(fixture.notifier.state.mapStrokeStart, isNull);
      expect(
        fixture.notifier.state.mapUndoStack,
        hasLength(initialHistoryLength + 2),
      );
      expect(
        fixture.notifier.state.mapUndoStack[initialHistoryLength],
        same(pendingStroke),
      );
      expect(
        fixture.notifier.state.mapUndoStack.last.map,
        same(fixture.baseMap),
      );
      expect(fixture.preview.current, const BorderPreviewState.idle());
      fixture.dispose();
    });

    test('Discard persists the current map without adding history', () async {
      final candidate = _richCandidateMap();
      final fixture = _fixture(candidate: candidate, withPendingStroke: false);
      final history = fixture.notifier.state.mapUndoStack;

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.discardAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.saved);
      expect(fixture.repository.savedMaps, <MapData>[fixture.baseMap]);
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.notifier.state.mapUndoStack, history);
      expect(fixture.notifier.state.mapUndoStack.single, same(history.single));
      expect(fixture.notifier.state.savedMapSnapshot, same(fixture.baseMap));
      expect(fixture.preview.current, const BorderPreviewState.idle());
      fixture.dispose();
    });

    test('successful Discard finalizes an earlier stroke after persistence',
        () async {
      final fixture = _fixture(candidate: _richCandidateMap());
      final pendingStroke = fixture.notifier.state.mapStrokeStart;
      final initialHistoryLength = fixture.notifier.state.mapUndoStack.length;

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.discardAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.saved);
      expect(
        fixture.repository.strokeSeenInNotifierDuringWrite,
        same(pendingStroke),
      );
      expect(fixture.notifier.state.mapStrokeStart, isNull);
      expect(
        fixture.notifier.state.mapUndoStack,
        hasLength(initialHistoryLength + 1),
      );
      expect(fixture.notifier.state.mapUndoStack.last, same(pendingStroke));
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.preview.current, const BorderPreviewState.idle());
      fixture.dispose();
    });

    test('persistence failure retains map, history, stroke and preview',
        () async {
      final fixture = _fixture(
        candidate: _richCandidateMap(),
        failPersistence: true,
      );
      final history = fixture.notifier.state.mapUndoStack;
      final stroke = fixture.notifier.state.mapStrokeStart;

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.failed);
      expect(fixture.repository.writeAttempts, 1);
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.notifier.state.mapUndoStack, history);
      expect(fixture.notifier.state.mapUndoStack.single, same(history.single));
      expect(fixture.notifier.state.mapStrokeStart, same(stroke));
      expect(fixture.notifier.state.savedMapSnapshot, same(fixture.baseMap));
      expect(fixture.notifier.state.isDirty, isTrue);
      expect(fixture.preview.current.phase, BorderPreviewPhase.resolved);
      expect(fixture.preview.current.transaction, isNotNull);
      fixture.dispose();
    });

    test('active identity conflict performs zero writes and retains preview',
        () async {
      final fixture = _fixture(candidate: _richCandidateMap());
      fixture.notifier.state =
          fixture.notifier.state.copyWith(activeLayerId: 'other-layer');

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.conflict);
      expect(fixture.repository.savedMaps, isEmpty);
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.preview.current.phase, BorderPreviewPhase.resolved);
      fixture.dispose();
    });

    test(
        'bulk-loss guard evaluates the prepared Apply candidate and preserves every transient state',
        () async {
      final candidate = _richCandidateMap().copyWith(
        placedElements: _richCandidateMap().placedElements.take(2).toList(),
      );
      final fixture = _fixture(candidate: candidate);
      final history = fixture.notifier.state.mapUndoStack;
      final stroke = fixture.notifier.state.mapStrokeStart;

      final outcome = await fixture.notifier.saveActiveMap(
        pendingBorderDecision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(outcome, ActiveMapSaveOutcome.bulkPlacementLossBlocked);
      expect(fixture.repository.writeAttempts, 0);
      expect(fixture.notifier.state.activeMap, same(fixture.baseMap));
      expect(fixture.notifier.state.mapUndoStack, history);
      expect(fixture.notifier.state.mapUndoStack.single, same(history.single));
      expect(fixture.notifier.state.mapStrokeStart, same(stroke));
      expect(fixture.preview.current.phase, BorderPreviewPhase.resolved);
      expect(fixture.notifier.state.errorMessage, contains('4'));
      expect(fixture.notifier.state.errorMessage, contains('2'));
      fixture.dispose();
    });
  });

  test('Apply save and real reload preserve every Border field exactly',
      () async {
    final root = await Directory.systemTemp.createTemp('border_save_7d_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final mapPath = p.join(root.path, 'maps', 'coast.json');
    final project = _project();
    final baseMap = _baseMap();
    final candidate = _richCandidateMap();
    final preview = _previewFor(
      project: project,
      map: baseMap,
      projectRootPath: root.path,
      activeMapPath: mapPath,
    );
    final repository = FileMapRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        mapRepositoryProvider.overrideWith((ref) => repository),
        borderPreviewControllerProvider.overrideWith((ref) => preview),
        pendingBorderSaveGuardProvider.overrideWithValue(
          PendingBorderSaveGuard(
            applier: ({required map, required transaction}) => candidate,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: baseMap,
      activeMapPath: mapPath,
      activeLayerId: 'borders',
      savedMapSnapshot: baseMap,
      isDirty: true,
    );
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(
          map: baseMap,
          layerId: 'borders',
          featureId: 'coast',
        );
    _resolvePreview(
      preview,
      project: project,
      map: baseMap,
      projectRootPath: root.path,
      activeMapPath: mapPath,
    );

    final outcome = await notifier.saveActiveMap(
      pendingBorderDecision: PendingBorderSaveDecision.applyAndSave,
    );
    final reloaded = await repository.loadMap(mapPath);

    expect(outcome, ActiveMapSaveOutcome.saved);
    expect(reloaded, candidate);
    final reloadedFeature = _feature(reloaded);
    final expectedFeature = _feature(candidate);
    expect(reloadedFeature.blueprintId, expectedFeature.blueprintId);
    expect(reloadedFeature.seed, expectedFeature.seed);
    expect(reloadedFeature.geometry, expectedFeature.geometry);
    expect(reloadedFeature.paramsOverride, expectedFeature.paramsOverride);
    expect(reloadedFeature.overrides, expectedFeature.overrides);
    expect(reloadedFeature.keepOutRegions, expectedFeature.keepOutRegions);
    expect(reloadedFeature.materialization?.ground,
        expectedFeature.materialization?.ground);
    expect(reloadedFeature.materialization?.placements,
        expectedFeature.materialization?.placements);
    expect(reloadedFeature.materialization?.receipt,
        expectedFeature.materialization?.receipt);
  });
}

_NotifierFixture _fixture({
  MapData? candidate,
  bool failPersistence = false,
  bool withPendingStroke = true,
}) {
  final project = _project();
  final map = _baseMap();
  final preview = _previewFor(
    project: project,
    map: map,
    projectRootPath: '/project',
    activeMapPath: '/project/maps/map.json',
  );
  final repository = _RecordingMapRepository(
    failPersistence: failPersistence,
  );
  final guard = PendingBorderSaveGuard(
    applier: ({required map, required transaction}) =>
        candidate ?? map.copyWith(name: 'Applied coast'),
  );
  final container = ProviderContainer(
    overrides: <Override>[
      mapRepositoryProvider.overrideWith((ref) => repository),
      borderPreviewControllerProvider.overrideWith((ref) => preview),
      pendingBorderSaveGuardProvider.overrideWithValue(guard),
    ],
  );
  final notifier = container.read(editorNotifierProvider.notifier);
  final historical = MapHistorySnapshot(map: map.copyWith(name: 'Historical'));
  final stroke = MapHistorySnapshot(map: map.copyWith(name: 'Stroke start'));
  notifier.state = EditorState(
    projectRootPath: '/project',
    project: project,
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeMapPath: '/project/maps/map.json',
    activeLayerId: 'borders',
    savedMapSnapshot: map,
    mapUndoStack: <MapHistorySnapshot>[historical],
    mapStrokeStart: withPendingStroke ? stroke : null,
    canUndoMap: true,
    isDirty: true,
  );
  container
      .read(activeBorderFeatureControllerProvider.notifier)
      .selectFeature(map: map, layerId: 'borders', featureId: 'coast');
  _resolvePreview(
    preview,
    project: project,
    map: map,
    projectRootPath: '/project',
    activeMapPath: '/project/maps/map.json',
  );
  repository
    ..notifier = notifier
    ..preview = preview;
  return _NotifierFixture(
    container: container,
    notifier: notifier,
    preview: preview,
    repository: repository,
    baseMap: map,
  );
}

BorderPreviewController _previewFor({
  required ProjectManifest project,
  required MapData map,
  required String projectRootPath,
  required String activeMapPath,
}) {
  return BorderPreviewController(resolver: (_) => _previewResult());
}

void _resolvePreview(
  BorderPreviewController preview, {
  required ProjectManifest project,
  required MapData map,
  required String projectRootPath,
  required String activeMapPath,
}) {
  preview.begin(
    map: map,
    layerId: 'borders',
    featureId: 'coast',
    context: createEditorBorderPreviewContext(
      projectRootPath: p.normalize(projectRootPath),
      activeMapPath: p.normalize(activeMapPath),
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
}

ProjectManifest _project() => ProjectManifest(
      name: 'Border save project',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tiles',
          name: 'Tiles',
          relativePath: 'tilesets/tiles.png',
        ),
      ],
      elementCategories: const <ProjectElementCategory>[
        ProjectElementCategory(id: 'props', name: 'Props'),
      ],
      elements: <ProjectElementEntry>[
        for (var index = 0; index < 4; index += 1)
          ProjectElementEntry(
            id: 'prop-$index',
            name: 'Prop $index',
            tilesetId: 'tiles',
            categoryId: 'props',
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
      ],
      borderCatalog: const ProjectBorderCatalog.empty(),
    );

MapData _baseMap() => MapData(
      id: 'map',
      name: 'Base map',
      version: ProjectVersion.v2,
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
                geometry: _region(<int>{0}),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
        MapLayer.tile(
          id: 'objects',
          name: 'Objets',
          tilesetId: 'tiles',
          tiles: List<int>.filled(16, 0),
        ),
      ],
      placedElements: <MapPlacedElement>[
        for (var index = 0; index < 4; index += 1)
          MapPlacedElement(
            id: 'manual-$index',
            layerId: 'objects',
            elementId: 'prop-$index',
            pos: GridPos(x: index, y: 3),
            applyCollision: false,
          ),
      ],
    );

MapData _richCandidateMap() {
  final base = _baseMap();
  final feature = BorderFeature(
    id: 'coast',
    name: 'Côte',
    blueprintId: 'coast-blueprint',
    seed: BorderSignedInt64.fromInt(-123456789),
    geometry: _region(<int>{0, 1, 4, 5, 9}),
    paramsOverride: BorderGenerationParams(
      irregularityPermille: 317,
      detailDensityPermille: 641,
      variationPermille: 509,
      maxOverlapPx: 3,
      gapTolerancePx: 2,
      depthRows: 2,
    ),
    overrides: <BorderSlotOverride>[
      BorderSlotOverride(
        slotKey: 'coast-slot-locked',
        variationSalt: BorderSignedInt64.fromInt(42),
        suppressed: false,
        locked: true,
        lockedPlacement: _placement(),
        replacementPrimitiveId: 'rock-large',
        offsetDeltaPx: const BorderPixelOffset(x: -2, y: 3),
        transformOverride: BorderSpriteTransform(
          quarterTurns: 3,
          flipX: true,
        ),
      ),
    ],
    keepOutRegions: <BorderKeepOutRegion>[
      BorderKeepOutRegion(
        id: 'coast-keep-out',
        region: _region(<int>{15}),
      ),
    ],
    materialization: _materialization(),
  );
  return base.copyWith(
    layers: <MapLayer>[
      for (final layer in base.layers)
        if (layer is BorderLayer)
          layer.copyWith(
            content: BorderLayerContent(features: <BorderFeature>[feature]),
          )
        else
          layer,
    ],
  );
}

BorderFeature _feature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

BorderRegionGeometry _region(Set<int> filled) => BorderRegionGeometry(
      width: 4,
      height: 4,
      cells: <bool>[for (var i = 0; i < 16; i += 1) filled.contains(i)],
    );

BorderResolutionResult _previewResult() => BorderResolutionResult(
      materialization: _materialization(),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

BorderMaterialization _materialization() => BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 7,
        blueprintRevision: 12,
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
          x: 1,
          y: 1,
          visualSnapshotId: _snapshotId,
          resolvedRole: SurfaceVariantRole.innerCornerSE,
        ),
      ],
      placements: <BorderResolvedPlacement>[_placement()],
    );

BorderResolvedPlacement _placement() => BorderResolvedPlacement(
      id: 'coast-placement-1',
      slotKey: 'coast-slot-locked',
      primitiveId: 'rock-large',
      visualSnapshotId: _snapshotId,
      anchorCell: const GridPos(x: 2, y: 1),
      topLeftWorldPx: const BorderPixelPos(x: 29, y: 13),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: 30,
        y: 14,
        width: 18,
        height: 21,
      ),
      transform: BorderSpriteTransform(quarterTurns: 1, flipX: true),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: 1,
        anchorRowMajor: 6,
        passIndex: 2,
        rank: 3,
        ordinalLocal: 4,
        slotKey: 'coast-slot-locked',
      ),
    );

const String _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

String _fingerprint(String digit) => 'sha256:${digit * 64}';

final class _NotifierFixture {
  const _NotifierFixture({
    required this.container,
    required this.notifier,
    required this.preview,
    required this.repository,
    required this.baseMap,
  });

  final ProviderContainer container;
  final EditorNotifier notifier;
  final BorderPreviewController preview;
  final _RecordingMapRepository repository;
  final MapData baseMap;

  void dispose() => container.dispose();
}

final class _RecordingMapRepository implements MapRepository {
  _RecordingMapRepository({required this.failPersistence});

  final bool failPersistence;
  final List<MapData> savedMaps = <MapData>[];
  int writeAttempts = 0;
  late EditorNotifier notifier;
  late BorderPreviewController preview;
  MapData? mapSeenInNotifierDuringWrite;
  MapHistorySnapshot? strokeSeenInNotifierDuringWrite;
  BorderPreviewPhase? previewPhaseDuringWrite;

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    writeAttempts += 1;
    mapSeenInNotifierDuringWrite = notifier.state.activeMap;
    strokeSeenInNotifierDuringWrite = notifier.state.mapStrokeStart;
    previewPhaseDuringWrite = preview.current.phase;
    if (failPersistence) throw StateError('disk failure');
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
