import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/editor/application/tiled_map_import_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

const _erwRootEnvironmentKey = 'POKEMAP_ERW_ROOT';
const _syntheticMapWidth = 80;
const _syntheticMapHeight = 80;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'STN-10.6 synthetic import reopens, renders and starts playtest',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap-stn10-golden-',
      );
      addTearDown(() => _deleteIfPresent(sandbox));
      final sourceRoot = Directory(p.join(sandbox.path, 'source'))
        ..createSync(recursive: true);
      final tmxPath = await _writeSyntheticTiledFixture(sourceRoot);

      final evidence = await _runGoldenWorkflow(
        sandbox: sandbox,
        tmxPath: tmxPath,
        sourceRootPath: sourceRoot.path,
      );

      expect(evidence.mapSize, const GridSize(width: 80, height: 80));
      expect(evidence.tileLayerCount, 6);
      expect(evidence.tilesetCount, 2);
      expect(evidence.compiledTileObjectCount, 1);
      expect(evidence.editorRenderedOpaquePixel, isTrue);
      expect(evidence.runtimeRenderedOpaquePixel, isTrue);
      expect(evidence.playtestPhase, 'overworld');
      expect(evidence.reopenedChecksum, evidence.importedChecksum);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  final erwRootPath = Platform.environment[_erwRootEnvironmentKey]?.trim();
  test(
    'STN-10.6 real ERW import reopens, renders and starts playtest',
    () async {
      final erwRoot = Directory(erwRootPath!);
      final tmxPath = await _discoverErwGoldenMap(erwRoot);
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap-stn10-erw-',
      );
      addTearDown(() => _deleteIfPresent(sandbox));

      final evidence = await _runGoldenWorkflow(
        sandbox: sandbox,
        tmxPath: tmxPath,
        sourceRootPath: erwRoot.path,
      );

      expect(evidence.mapSize, const GridSize(width: 80, height: 80));
      expect(evidence.tileLayerCount, 6);
      expect(evidence.tilesetCount, 19);
      expect(evidence.editorRenderedOpaquePixel, isTrue);
      expect(evidence.runtimeRenderedOpaquePixel, isTrue);
      expect(evidence.playtestPhase, 'overworld');
      expect(evidence.reopenedChecksum, evidence.importedChecksum);
      // The report is intentionally ephemeral: licensed filenames, source
      // paths and pixels must never become repository fixtures or snapshots.
      // ignore: avoid_print
      print(
        'STN-10.6 ERW local evidence: '
        'tilesets=${evidence.tilesetCount}, '
        'tileLayers=${evidence.tileLayerCount}, '
        'tileObjects=${evidence.compiledTileObjectCount}, '
        'checksum=${evidence.reopenedChecksum}, '
        'elapsedMs=${evidence.elapsed.inMilliseconds}, '
        'rssBytes=${ProcessInfo.currentRss}',
      );
    },
    skip: erwRootPath == null || erwRootPath.isEmpty
        ? 'Set POKEMAP_ERW_ROOT to run the licensed local corpus gate.'
        : false,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

final class _GoldenWorkflowEvidence {
  const _GoldenWorkflowEvidence({
    required this.mapSize,
    required this.tileLayerCount,
    required this.tilesetCount,
    required this.compiledTileObjectCount,
    required this.editorRenderedOpaquePixel,
    required this.runtimeRenderedOpaquePixel,
    required this.playtestPhase,
    required this.importedChecksum,
    required this.reopenedChecksum,
    required this.elapsed,
  });

  final GridSize mapSize;
  final int tileLayerCount;
  final int tilesetCount;
  final int compiledTileObjectCount;
  final bool editorRenderedOpaquePixel;
  final bool runtimeRenderedOpaquePixel;
  final String playtestPhase;
  final String importedChecksum;
  final String reopenedChecksum;
  final Duration elapsed;
}

Future<_GoldenWorkflowEvidence> _runGoldenWorkflow({
  required Directory sandbox,
  required String tmxPath,
  required String sourceRootPath,
}) async {
  final stopwatch = Stopwatch()..start();
  final projectRoot = Directory(p.join(sandbox.path, 'project'))
    ..createSync(recursive: true);
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  await projectFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(
      const ProjectManifest(
        name: 'STN-10.6 golden import',
        version: ProjectVersion.v6,
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ).toJson(),
    )}\n',
    flush: true,
  );

  // Closing both adapters is part of the acceptance gate: the subsequent
  // snapshot must come from disk, not from a warm editor cache.
  final first = _EditorTransports.open();
  final service = TiledMapImportService(
    mutations: first.mutations,
    queries: first.queries,
  );
  final inspection = await service.inspect(
    projectRootPath: projectRoot.path,
    tmxPath: tmxPath,
    sourceRootPath: sourceRootPath,
  );
  final imported = await service.apply(inspection);
  final importedChecksum = _structuralChecksum(
    manifest: imported.manifest,
    map: imported.map,
  );
  await first.close();

  final reopened = _EditorTransports.open();
  final snapshot = await reopened.queries.open(projectRoot.path);
  final reopenedManifest = snapshot.manifest;
  final map = snapshot.mapById(imported.map.id)!;
  final reopenedChecksum = _structuralChecksum(
    manifest: reopenedManifest,
    map: map,
  );
  await reopened.close();

  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile.path,
    mapId: map.id,
  );
  final editorRenderedOpaquePixel = await _renderEditorViewport(bundle);
  final runtimeRenderedOpaquePixel = await _renderRuntimeViewport(bundle);
  final playtestPhase = await _startPlaytest(
    bundle: bundle,
    projectFilePath: projectFile.path,
  );
  stopwatch.stop();

  return _GoldenWorkflowEvidence(
    mapSize: map.size,
    tileLayerCount: map.layers.whereType<TileLayer>().length,
    tilesetCount: reopenedManifest.tilesets.length,
    compiledTileObjectCount: map.layers
        .whereType<ObjectLayer>()
        .fold<int>(0, (count, layer) => count + layer.tileObjects.length),
    editorRenderedOpaquePixel: editorRenderedOpaquePixel,
    runtimeRenderedOpaquePixel: runtimeRenderedOpaquePixel,
    playtestPhase: playtestPhase,
    importedChecksum: importedChecksum,
    reopenedChecksum: reopenedChecksum,
    elapsed: stopwatch.elapsed,
  );
}

final class _EditorTransports {
  _EditorTransports._({required this.mutations, required this.queries});

  factory _EditorTransports.open() {
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    return _EditorTransports._(
      mutations: AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      ),
      queries: queries,
    );
  }

  final AuthoringMutationAdapter mutations;
  final AuthoringQueryAdapter queries;

  Future<void> close() async {
    await mutations.closeAll();
    await queries.closeAll();
  }
}

Future<bool> _renderEditorViewport(RuntimeMapBundle bundle) async {
  final images = <String, ui.Image>{};
  try {
    for (final entry in bundle.tilesetAbsolutePathsById.entries) {
      final bytes = await File(entry.value).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        images[entry.key] = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    }
    final recorder = ui.PictureRecorder();
    MapGridPainter(
      map: bundle.map,
      project: bundle.manifest,
      zoom: 1,
      offset: ui.Offset.zero,
      tileWidth: bundle.cellWidth,
      tileHeight: bundle.cellHeight,
      tilesetImagesById: images,
      sourceTileWidth: bundle.manifest.settings.tileWidth,
      sourceTileHeight: bundle.manifest.settings.tileHeight,
      tilesPerRowById: <String, int>{
        for (final tileset in bundle.manifest.tilesets)
          if (tileset.source case ProjectRegularAtlasTilesetSource source)
            tileset.id: source.columns,
      },
      warps: bundle.map.warps,
      gameplayZones: bundle.map.gameplayZones,
      connectionLabelsByDirection: const <MapConnectionDirection, String>{},
      showGrid: false,
      showEntityEditorChrome: false,
      showEditorOverlays: false,
    ).paint(ui.Canvas(recorder), const ui.Size(96, 96));
    final rendered = await recorder.endRecording().toImage(96, 96);
    try {
      return await _containsOpaquePixel(rendered);
    } finally {
      rendered.dispose();
    }
  } finally {
    for (final image in images.values) {
      image.dispose();
    }
  }
}

Future<bool> _renderRuntimeViewport(RuntimeMapBundle bundle) async {
  final images = await loadTilesetImagesById(
    bundle.tilesetAbsolutePathsById,
  );
  try {
    final component = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: images,
    )..setVisibleLocalRect(const ui.Rect.fromLTWH(0, 0, 96, 96));
    final recorder = ui.PictureRecorder();
    component.render(ui.Canvas(recorder));
    final rendered = await recorder.endRecording().toImage(96, 96);
    try {
      return await _containsOpaquePixel(rendered);
    } finally {
      rendered.dispose();
    }
  } finally {
    for (final image in images.values.toSet()) {
      image.dispose();
    }
  }
}

Future<bool> _containsOpaquePixel(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return false;
  for (var offset = 3; offset < data.lengthInBytes; offset += 4) {
    if (data.getUint8(offset) != 0) return true;
  }
  return false;
}

Future<String> _startPlaytest({
  required RuntimeMapBundle bundle,
  required String projectFilePath,
}) async {
  final game = _GoldenPlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFilePath,
    saveRepository: _MemoryGameSaveRepository(),
  );
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  for (var attempt = 0; attempt < 300; attempt += 1) {
    game.update(0.016);
    if (game.debugFlowPhaseName == 'overworld' &&
        !game.debugIsMapActivationDispatchInFlight) {
      final pos = game.debugPlayerGridPosition;
      expect(pos.x, inInclusiveRange(0, bundle.map.size.width - 1));
      expect(pos.y, inInclusiveRange(0, bundle.map.size.height - 1));
      final phase = game.debugFlowPhaseName;
      game.onRemove();
      return phase;
    }
    await Future<void>.delayed(Duration.zero);
  }
  game.onRemove();
  fail('The imported map did not reach the playable overworld phase.');
}

final class _GoldenPlayableMapGame extends PlayableMapGame {
  _GoldenPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  GameState? _state;

  @override
  Future<void> delete() async => _state = null;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<void> save(GameState state) async => _state = state;
}

String _structuralChecksum({
  required ProjectManifest manifest,
  required MapData map,
}) {
  final payload = jsonEncode(<String, Object?>{
    'manifest': manifest.toJson(),
    'map': map.toJson(),
  });
  return sha256.convert(utf8.encode(payload)).toString();
}

Future<String> _writeSyntheticTiledFixture(Directory root) async {
  final atlas = File(p.join(root.path, 'atlas.png'));
  final prop = File(p.join(root.path, 'prop.png'));
  await atlas.writeAsBytes(_onePixelPng, flush: true);
  await prop.writeAsBytes(_onePixelPng, flush: true);
  await File(p.join(root.path, 'atlas.tsx')).writeAsString(
    _syntheticAtlasTsx,
    flush: true,
  );
  await File(p.join(root.path, 'props.tsx')).writeAsString(
    _syntheticImageCollectionTsx,
    flush: true,
  );
  final tmx = File(p.join(root.path, 'golden-80x80.tmx'));
  await tmx.writeAsString(_syntheticTmx(), flush: true);
  return tmx.path;
}

String _syntheticTmx() {
  final empty = List<String>.filled(
    _syntheticMapWidth * _syntheticMapHeight,
    '0',
  );
  String csvWith(Map<int, int> values) {
    final cells = List<String>.from(empty);
    for (final entry in values.entries) {
      cells[entry.key] = '${entry.value}';
    }
    return cells.join(',');
  }

  final ground = List<String>.filled(
    _syntheticMapWidth * _syntheticMapHeight,
    '1',
  ).join(',');
  final layers = <String>[
    ground,
    csvWith(<int, int>{1: 0x80000001}),
    csvWith(<int, int>{2: 105}),
    csvWith(<int, int>{80: 1}),
    csvWith(<int, int>{81: 1}),
    csvWith(<int, int>{82: 1}),
  ];
  final xmlLayers = <String>[
    for (var index = 0; index < layers.length; index += 1)
      '''
  <layer id="${index + 1}" name="Layer ${index + 1}" width="80" height="80">
    <data encoding="csv">${layers[index]}</data>
  </layer>''',
  ].join();
  return '''
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
  renderorder="right-down" width="80" height="80" tilewidth="1"
  tileheight="1" infinite="0" nextlayerid="8" nextobjectid="3">
  <tileset firstgid="1" source="atlas.tsx"/>
  <tileset firstgid="100" source="props.tsx"/>
$xmlLayers
  <objectgroup id="7" name="Objects">
    <object id="1" name="Fractional prop" gid="105" x="1.25" y="1.75"
      width="0.5" height="0.5"/>
    <object id="2" name="Deferred shape" x="4" y="4" width="1" height="1"/>
  </objectgroup>
</map>
''';
}

Future<String> _discoverErwGoldenMap(Directory root) async {
  if (!await root.exists()) {
    throw StateError('POKEMAP_ERW_ROOT does not identify a directory.');
  }
  final canonicalRoot = p.normalize(await root.resolveSymbolicLinks());
  final matches = <String>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || p.extension(entity.path).toLowerCase() != '.tmx') {
      continue;
    }
    final canonicalFile = p.normalize(await entity.resolveSymbolicLinks());
    if (!_isWithinRoot(canonicalRoot, canonicalFile)) {
      throw StateError('The ERW corpus contains a TMX symlink escape.');
    }
    try {
      final document = parseTiledMap(await entity.readAsString());
      if (document.width == 80 &&
          document.height == 80 &&
          document.dependencyClosure.tilesets.length == 19 &&
          document.layers.whereType<TiledMapTileLayer>().length == 6) {
        matches.add(canonicalFile);
      }
    } on TiledMapImportException {
      // Rule maps outside the playable corpus are irrelevant to this gate.
    }
  }
  if (matches.length != 1) {
    throw StateError(
      'Expected one generic 80x80/19-tileset/6-layer ERW map, '
      'found ${matches.length}.',
    );
  }
  return matches.single;
}

bool _isWithinRoot(String root, String candidate) =>
    candidate == root || p.isWithin(root, candidate);

Future<void> _deleteIfPresent(Directory directory) async {
  if (await directory.exists()) await directory.delete(recursive: true);
}

final List<int> _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

const _syntheticAtlasTsx = '''
<tileset name="Golden atlas" tilewidth="1" tileheight="1" tilecount="1"
  columns="1">
  <image source="atlas.png" width="1" height="1"/>
  <wangsets>
    <wangset name="Ground" type="mixed" tile="0">
      <wangcolor name="Ground" color="#5a9f68" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,1,1,1,1,1,1,1"/>
    </wangset>
  </wangsets>
</tileset>
''';

const _syntheticImageCollectionTsx = '''
<tileset name="Golden props" tilewidth="1" tileheight="1" tilecount="1"
  columns="0">
  <tile id="5">
    <image source="prop.png" width="1" height="1"/>
  </tile>
</tileset>
''';
