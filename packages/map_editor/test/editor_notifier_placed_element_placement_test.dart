import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_tool_preview.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  test(
    'project element brush routes one pointer-down to semantic placement',
    () async {
      final seeded = _RoutingEditorNotifier(_state());
      final container = ProviderContainer(
        overrides: <Override>[
          editorNotifierProvider.overrideWith(() => seeded),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final beforeCells = (notifier.state.activeMap!.layers.single as TileLayer)
          .cells
          .toList(growable: false);

      await notifier.paintSelectedBrushAt(
        const GridPos(x: 3, y: 2),
        tilesetColumnsById: const <String, int>{'village': 64},
      );
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 4, y: 2),
        tilesetColumnsById: const <String, int>{'village': 64},
        partOfStroke: true,
      );

      expect(seeded.semanticPlacements, const <GridPos>[GridPos(x: 3, y: 2)]);
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).cells,
        beforeCells,
      );
    },
  );

  testWidgets('canvas tap routes one project element placement', (
    tester,
  ) async {
    final seeded = _RoutingEditorNotifier(_state());
    final container = ProviderContainer(
      overrides: <Override>[editorNotifierProvider.overrideWith(() => seeded)],
    );
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox.expand(child: MapCanvas()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final canvas = tester.getRect(find.byType(MapCanvas));

    await tester.tapAt(canvas.topLeft + const Offset(16, 16));
    await tester.pump();

    expect(seeded.semanticPlacements, const <GridPos>[GridPos(x: 0, y: 0)]);
  });

  test(
    'project element preview exposes the footprint and rejects overflow',
    () async {
      final seeded = _RoutingEditorNotifier(_state());
      final container = ProviderContainer(
        overrides: <Override>[
          editorNotifierProvider.overrideWith(() => seeded),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);

      final valid = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 3, y: 2),
        tilesetColumnsById: const <String, int>{'village': 64},
      );
      final invalid = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 10, y: 8),
        tilesetColumnsById: const <String, int>{'village': 64},
      );

      expect(valid?.mode, MapToolPreviewMode.elementPlacement);
      expect(valid?.size, const GridSize(width: 8, height: 7));
      expect(valid?.elementId, 'guesthouse');
      expect(valid?.validity, MapToolPreviewValidity.valid);
      expect(invalid?.mode, MapToolPreviewMode.elementPlacement);
      expect(invalid?.validity, MapToolPreviewValidity.invalid);
      expect(invalid?.reason, isNotEmpty);

      await notifier.paintSelectedBrushAt(
        const GridPos(x: 10, y: 8),
        tilesetColumnsById: const <String, int>{'village': 64},
      );

      expect(seeded.semanticPlacements, isEmpty);
      expect(notifier.state.errorMessage, contains('dépasse'));
    },
  );

  test(
    'canonical placement selects the instance and keeps properties editable',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);

      await fixture.notifier.placeSelectedProjectElementAt(
        const GridPos(x: 3, y: 2),
      );
      expect(await fixture.notifier.drainPlacedElementPublications(), isTrue);

      final placed = fixture.notifier.state.activeMap!.placedElements.single;
      expect(placed.id, 'objects::3::2');
      expect(fixture.notifier.state.selectedPlacedElementInstanceId, placed.id);
      expect(fixture.notifier.state.canUndoMap, isTrue);
      expect(fixture.notifier.state.isDirty, isFalse);
      expect(
        (fixture.notifier.state.activeMap!.layers.first as TileLayer).cells,
        everyElement(0),
      );

      fixture.notifier.setPlacedElementInstanceOpacity(
        instanceId: placed.id,
        opacity: 0.45,
      );

      expect(
        fixture.notifier.state.activeMap!.placedElements.single.opacity,
        0.45,
      );
      expect(fixture.notifier.state.selectedPlacedElementInstanceId, placed.id);
    },
  );

  test('canonical placement participates in map undo and redo', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);
    await fixture.notifier.placeSelectedProjectElementAt(
      const GridPos(x: 3, y: 2),
    );
    expect(
      await fixture.notifier.drainPlacedElementPublications(),
      isTrue,
      reason: fixture.notifier.state.errorMessage,
    );

    fixture.notifier.undoMap();
    await _waitFor(
      () => fixture.notifier.state.activeMap!.placedElements.isEmpty,
    );

    expect(fixture.notifier.state.canRedoMap, isTrue);
    expect(fixture.notifier.state.selectedPlacedElementInstanceId, isNull);

    fixture.notifier.redoMap();
    await _waitFor(
      () => fixture.notifier.state.activeMap!.placedElements.length == 1,
    );

    expect(
      fixture.notifier.state.selectedPlacedElementInstanceId,
      'objects::3::2',
    );
    expect(fixture.notifier.state.canUndoMap, isTrue);
  });

  test(
    'burst placement is local, latency-bounded, and canonically lossless',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);
      final recorder = EditorPerformanceRecorder();
      final recording = EditorPerformanceTelemetry.startRecording(recorder);
      final samplesUs = <int>[];

      for (var index = 0; index < 100; index++) {
        final stopwatch = Stopwatch()..start();
        fixture.notifier.placeSelectedProjectElementAt(
          GridPos(x: index % 10, y: index ~/ 10),
        );
        stopwatch.stop();
        samplesUs.add(stopwatch.elapsedMicroseconds);
      }
      recording.close();

      expect(fixture.notifier.state.activeMap!.placedElements, hasLength(100));
      expect(fixture.notifier.hasPendingPlacedElementPublications, isTrue);
      for (final counter in EditorPerformanceCounterName.all) {
        expect(recorder.snapshot().counter(counter), 0, reason: counter);
      }
      expect(
        recorder.snapshot().spanSamples(
          EditorPerformanceSpanName.mapIncrementalValidation,
        ),
        hasLength(100),
      );
      expect(
        recorder.snapshot().spanSamples(
          EditorPerformanceSpanName.mapFullValidation,
        ),
        isEmpty,
      );
      final sortedSamples = samplesUs.toList()..sort();
      final p50 = sortedSamples[(sortedSamples.length * 0.50).ceil() - 1];
      final p95 = sortedSamples[(sortedSamples.length * 0.95).ceil() - 1];
      final p99 = sortedSamples[(sortedSamples.length * 0.99).ceil() - 1];
      final max = sortedSamples.last;
      debugPrint(
        'PERF-002 local placement us: p50=$p50 p95=$p95 p99=$p99 max=$max',
      );
      expect(p95, lessThan(16000), reason: 'P95=$p95 us, P99=$p99 us');

      expect(
        await Future.wait<bool>(<Future<bool>>[
          fixture.notifier.drainPlacedElementPublications(),
          fixture.notifier.drainPlacedElementPublications(),
          fixture.notifier.drainPlacedElementPublications(),
        ]),
        everyElement(isTrue),
      );
      expect(fixture.notifier.hasPendingPlacedElementPublications, isFalse);
      expect(fixture.notifier.state.isDirty, isFalse);
      expect((await fixture.readPersistedMap()).placedElements, hasLength(100));

      fixture.notifier.undoMap();
      await _waitFor(
        () => fixture.notifier.state.activeMap!.placedElements.isEmpty,
      );
      expect((await fixture.readPersistedMap()).placedElements, isEmpty);

      fixture.notifier.redoMap();
      await _waitFor(
        () => fixture.notifier.state.activeMap!.placedElements.length == 100,
      );
      expect((await fixture.readPersistedMap()).placedElements, hasLength(100));
    },
  );

  test(
    'undo before publication removes the local and canonical placement',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);

      fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));
      expect(fixture.notifier.state.activeMap!.placedElements, hasLength(1));

      fixture.notifier.undoMap();

      expect(fixture.notifier.state.activeMap!.placedElements, isEmpty);
      expect(await fixture.notifier.drainPlacedElementPublications(), isTrue);
      expect((await fixture.readPersistedMap()).placedElements, isEmpty);
    },
  );

  test('failed publication preserves the draft and can be retried', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);
    final originalMap = await fixture.mapFile.readAsString();

    fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));
    await fixture.mapFile.writeAsString('{broken', flush: true);

    expect(await fixture.notifier.drainPlacedElementPublications(), isFalse);
    expect(fixture.notifier.hasPendingPlacedElementPublications, isTrue);
    expect(fixture.notifier.state.activeMap!.placedElements, hasLength(1));
    expect(fixture.notifier.state.errorMessage, isNotEmpty);

    await fixture.mapFile.writeAsString(originalMap, flush: true);

    expect(await fixture.notifier.retryPlacedElementPublications(), isTrue);
    expect(fixture.notifier.hasPendingPlacedElementPublications, isFalse);
    expect((await fixture.readPersistedMap()).placedElements, hasLength(1));
  });

  test('save drains a pending placement without publishing it twice', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);

    fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));

    expect(await fixture.notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
    expect(fixture.notifier.hasPendingPlacedElementPublications, isFalse);
    expect((await fixture.readPersistedMap()).placedElements, hasLength(1));
  });

  test('dirty map base is saved once before the queued placement', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);
    await fixture.notifier.placeSelectedProjectElementAt(
      const GridPos(x: 3, y: 2),
    );
    expect(await fixture.notifier.drainPlacedElementPublications(), isTrue);
    fixture.notifier.setPlacedElementInstanceOpacity(
      instanceId: 'objects::3::2',
      opacity: 0.45,
    );
    MapValidator.validate(
      fixture.notifier.state.activeMap!,
      projectDialogueContext: fixture.notifier.state.project,
    );
    ProjectValidator.validate(fixture.notifier.state.project!);

    fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 4, y: 2));

    expect(
      await fixture.notifier.drainPlacedElementPublications(),
      isTrue,
      reason: fixture.notifier.state.errorMessage,
    );
    final persisted = await fixture.readPersistedMap();
    expect(persisted.placedElements, hasLength(2));
    expect(
      persisted.placedElements
          .singleWhere((entry) => entry.id == 'objects::3::2')
          .opacity,
      0.45,
    );
  });

  test(
    'placements stay local and lossless while the dirty base is saving',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);
      fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));
      expect(await fixture.notifier.drainPlacedElementPublications(), isTrue);
      fixture.notifier.setPlacedElementInstanceOpacity(
        instanceId: 'objects::3::2',
        opacity: 0.45,
      );
      fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 4, y: 2));

      final publication = fixture.notifier.drainPlacedElementPublications();
      for (var index = 0; index < 20; index++) {
        fixture.notifier.placeSelectedProjectElementAt(
          GridPos(x: 10 + index, y: 20),
        );
      }

      expect(fixture.notifier.state.activeMap!.placedElements, hasLength(22));
      expect(await publication, isTrue);
      expect((await fixture.readPersistedMap()).placedElements, hasLength(22));
    },
  );

  test(
    'map activation drains pending placements before replacing the session',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);
      fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));

      final outcome = await fixture.notifier.activateMap('maps/second.json');

      expect(outcome, MapActivationOutcome.activated);
      expect(fixture.notifier.state.activeMap!.id, 'second');
      expect(fixture.notifier.hasPendingPlacedElementPublications, isFalse);
      expect((await fixture.readPersistedMap()).placedElements, hasLength(1));
    },
  );

  test('stale revision replans and preserves an external placement', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);
    await fixture.notifier.placeSelectedProjectElementAt(
      const GridPos(x: 3, y: 2),
    );
    expect(await fixture.notifier.drainPlacedElementPublications(), isTrue);

    fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 4, y: 2));
    final external = MapPlacedElement(
      id: 'objects::external',
      layerId: 'objects',
      elementId: 'guesthouse',
      pos: const GridPos(x: 8, y: 8),
    );
    await fixture.writePersistedMap(
      upsertMapPlacedElement(
        await fixture.readPersistedMap(),
        instance: external,
      ),
    );

    expect(await fixture.notifier.drainPlacedElementPublications(), isTrue);
    final ids = (await fixture.readPersistedMap()).placedElements
        .map((entry) => entry.id)
        .toSet();
    expect(ids, <String>{
      'objects::3::2',
      'objects::4::2',
      'objects::external',
    });
    expect(
      fixture.notifier.state.activeMap!.placedElements.map((entry) => entry.id),
      contains('objects::external'),
    );
  });

  test(
    'rebase reserves a new id when the canonical id was taken externally',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);
      fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));
      final external = MapPlacedElement(
        id: 'objects::3::2',
        layerId: 'objects',
        elementId: 'guesthouse',
        pos: const GridPos(x: 3, y: 2),
        opacity: 0.25,
      );
      await fixture.writePersistedMap(
        upsertMapPlacedElement(
          await fixture.readPersistedMap(),
          instance: external,
        ),
      );

      expect(
        await fixture.notifier.drainPlacedElementPublications(),
        isTrue,
        reason: fixture.notifier.state.errorMessage,
      );
      final persisted = await fixture.readPersistedMap();
      expect(
        persisted.placedElements.map((entry) => entry.id).toSet(),
        <String>{'objects::3::2', 'objects::3::2_2'},
      );
      expect(
        persisted.placedElements
            .singleWhere((entry) => entry.id == 'objects::3::2')
            .opacity,
        0.25,
      );
      expect(
        fixture.notifier.state.selectedPlacedElementInstanceId,
        'objects::3::2_2',
      );
    },
  );

  test(
    'project replacement drains before closing the authoring session',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);
      final replacementRoot = await Directory.systemTemp.createTemp(
        'element-placement-replacement-',
      );
      addTearDown(() => replacementRoot.delete(recursive: true));
      await _writeProjectFixture(replacementRoot);
      fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));

      final outcome = await fixture.notifier.activateProject(
        '${replacementRoot.path}/project.json',
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(fixture.notifier.state.projectRootPath, replacementRoot.path);
      expect(fixture.notifier.hasPendingPlacedElementPublications, isFalse);
      expect((await fixture.readPersistedMap()).placedElements, hasLength(1));
    },
  );

  test('queued placements preserve their layer publication order', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);
    fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 3, y: 2));
    fixture.notifier.selectLayerForTest('objects-secondary');
    fixture.notifier.placeSelectedProjectElementAt(const GridPos(x: 4, y: 2));

    expect(
      await fixture.notifier.drainPlacedElementPublications(),
      isTrue,
      reason: fixture.notifier.state.errorMessage,
    );
    final persisted = await fixture.readPersistedMap();
    expect(persisted.placedElements.map((entry) => entry.layerId), <String>[
      'objects',
      'objects-secondary',
    ]);
  });
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for canonical editor state.');
}

final class _CanonicalPlacementFixture {
  _CanonicalPlacementFixture._({
    required this.root,
    required this.container,
    required this.notifier,
  });

  final Directory root;
  final ProviderContainer container;
  final _SeededEditorNotifier notifier;

  File get mapFile => File('${root.path}/maps/map.json');

  Future<MapData> readPersistedMap() async {
    final decoded = jsonDecode(await mapFile.readAsString());
    return MapData.fromJson((decoded as Map).cast<String, dynamic>());
  }

  Future<void> writePersistedMap(MapData map) =>
      mapFile.writeAsString(jsonEncode(map.toJson()), flush: true);

  static Future<_CanonicalPlacementFixture> create() async {
    final root = await Directory.systemTemp.createTemp('element-placement-');
    final manifest = _projectWithMap();
    final map = _mapForCanonicalPlacement();
    final secondMap = _mapForCanonicalPlacement().copyWith(
      id: 'second',
      name: 'Second',
      placedElements: const <MapPlacedElement>[],
    );
    await Directory('${root.path}/maps').create();
    await File(
      '${root.path}/project.json',
    ).writeAsString(jsonEncode(manifest.toJson()), flush: true);
    final mapPath = '${root.path}/maps/map.json';
    await File(mapPath).writeAsString(jsonEncode(map.toJson()), flush: true);
    await File(
      '${root.path}/maps/second.json',
    ).writeAsString(jsonEncode(secondMap.toJson()), flush: true);
    final seeded = _SeededEditorNotifier(
      _state().copyWith(
        projectRootPath: root.path,
        project: manifest,
        activeMap: map,
        activeMapPath: mapPath,
        savedMapSnapshot: map,
      ),
    );
    final container = ProviderContainer(
      overrides: <Override>[editorNotifierProvider.overrideWith(() => seeded)],
    );
    container.read(editorNotifierProvider.notifier);
    return _CanonicalPlacementFixture._(
      root: root,
      container: container,
      notifier: seeded,
    );
  }

  Future<void> dispose() async {
    await notifier.drainPlacedElementPublications();
    container.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<void> _writeProjectFixture(Directory root) async {
  final manifest = _projectWithMap();
  final map = _mapForCanonicalPlacement();
  final secondMap = map.copyWith(
    id: 'second',
    name: 'Second',
    placedElements: const <MapPlacedElement>[],
  );
  await Directory('${root.path}/maps').create();
  await File(
    '${root.path}/project.json',
  ).writeAsString(jsonEncode(manifest.toJson()), flush: true);
  await File(
    '${root.path}/maps/map.json',
  ).writeAsString(jsonEncode(map.toJson()), flush: true);
  await File(
    '${root.path}/maps/second.json',
  ).writeAsString(jsonEncode(secondMap.toJson()), flush: true);
}

final class _SeededEditorNotifier extends EditorNotifier {
  _SeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() => initialState;

  void selectLayerForTest(String layerId) {
    state = state.copyWith(activeLayerId: layerId);
  }
}

ProjectManifest _projectWithMap() => const ProjectManifest(
  name: 'Placement project',
  version: ProjectVersion.v6,
  maps: <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
    ProjectMapEntry(
      id: 'second',
      name: 'Second',
      relativePath: 'maps/second.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'tilesets/village.png',
      source: ProjectRegularAtlasTilesetSource(
        assetId: 'village',
        pixelWidth: 2048,
        pixelHeight: 1024,
        tileWidth: 32,
        tileHeight: 32,
      ),
    ),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'building', name: 'Building'),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'guesthouse',
      name: 'Guesthouse',
      tilesetId: 'village',
      categoryId: 'building',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 1, width: 8, height: 7),
        ),
      ],
    ),
  ],
);

MapData _mapForCanonicalPlacement() => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 128, height: 128),
  layers: <MapLayer>[
    MapLayer.tile(
      id: 'objects',
      name: 'Objects',
      cells: List<int>.filled(128 * 128, 0),
    ),
    MapLayer.tile(
      id: 'objects-secondary',
      name: 'Objects secondary',
      cells: List<int>.filled(128 * 128, 0),
    ),
  ],
);

final class _RoutingEditorNotifier extends EditorNotifier {
  _RoutingEditorNotifier(this.initialState);

  final EditorState initialState;
  final List<GridPos> semanticPlacements = <GridPos>[];

  @override
  EditorState build() => initialState;

  @override
  Future<void> placeSelectedProjectElementAt(GridPos pos) async {
    semanticPlacements.add(pos);
  }
}

EditorState _state() => EditorState(
  project: const ProjectManifest(
    name: 'Placement project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'village',
        name: 'Village',
        relativePath: 'tilesets/village.png',
      ),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'guesthouse',
        name: 'Guesthouse',
        tilesetId: 'village',
        categoryId: 'building',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 1, width: 8, height: 7),
          ),
        ],
      ),
    ],
  ),
  activeMap: MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 16, height: 12),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'objects',
        name: 'Objects',
        cells: List<int>.filled(16 * 12, 0),
      ),
    ],
  ),
  activeLayerId: 'objects',
  activeTool: EditorToolType.tilePaint,
  activeBrush: const EditorBrush.projectElement(elementId: 'guesthouse'),
);
