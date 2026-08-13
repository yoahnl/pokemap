import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/editor_canvas_repaint_clock.dart';

void main() {
  test('revisions advance only for the map domain that changed', () {
    final owner = EditorCanvasPictureCacheOwner(maxEntries: 8);
    addTearDown(owner.dispose);
    final first = owner.resolveRevisions(
      map: _map,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );
    final unchanged = owner.resolveRevisions(
      map: _map,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );

    expect(unchanged, first);

    final changedGround = (_map.layers.first as TileLayer).copyWith(
      cells: const <int>[1, 1, 0, 0],
    );
    final changedMap = _map.copyWith(
      layers: <MapLayer>[changedGround, ..._map.layers.skip(1)],
    );
    final changed = owner.resolveRevisions(
      map: changedMap,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );

    expect(changed.mapRevision, greaterThan(first.mapRevision));
    expect(
      changed.layerRevision('ground'),
      greaterThan(first.layerRevision('ground')),
    );
    expect(changed.layerRevision('water'), first.layerRevision('water'));
    expect(changed.overlayRevision, first.overlayRevision);
    expect(changed.geometryRevision, first.geometryRevision);
    expect(changed.placedElementsRevision, first.placedElementsRevision);
    expect(changed.entitiesRevision, first.entitiesRevision);

    final changedOverlay = owner.resolveRevisions(
      map: changedMap,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 1,
    );
    expect(
      changedOverlay.overlayRevision,
      greaterThan(changed.overlayRevision),
    );
    expect(
      changedOverlay.layerRevision('ground'),
      changed.layerRevision('ground'),
    );
  });

  test('animation ticks reuse static layers and repaint animated layers', () {
    final owner = EditorCanvasPictureCacheOwner(maxEntries: 16);
    final clock = EditorCanvasRepaintClock();
    addTearDown(() {
      clock.dispose();
      owner.dispose();
    });
    final events = <EditorCanvasPictureCacheEvent>[];
    final painter = _painter(
      owner: owner,
      clock: clock,
      onCacheEvent: events.add,
    );

    _record(painter);
    events.clear();
    clock.update(const Duration(milliseconds: 110));
    _record(painter);

    expect(
      events,
      contains(
        isA<EditorCanvasPictureCacheEvent>()
            .having(
              (event) => event.cacheId,
              'cacheId',
              'tile:ground:background',
            )
            .having(
              (event) => event.disposition,
              'disposition',
              EditorCanvasPictureCacheDisposition.hit,
            ),
      ),
      reason: '${events.map((event) => (event.cacheId, event.disposition))}',
    );
    expect(
      events,
      contains(
        isA<EditorCanvasPictureCacheEvent>()
            .having(
              (event) => event.cacheId,
              'cacheId',
              'smart:water:background',
            )
            .having(
              (event) => event.disposition,
              'disposition',
              EditorCanvasPictureCacheDisposition.animated,
            ),
      ),
    );
  });

  test('revision state stays isolated for multiple visible maps', () {
    final owner = EditorCanvasPictureCacheOwner(maxEntries: 16);
    addTearDown(owner.dispose);
    final first = owner.resolveRevisions(
      map: _map,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );

    owner.resolveRevisions(
      map: _staticMap,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );
    final activeAgain = owner.resolveRevisions(
      map: _map,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );

    expect(activeAgain, first);
  });

  test('revision state retains only a bounded set of maps', () {
    final owner = EditorCanvasPictureCacheOwner(
      maxEntries: 16,
      maxRevisionMaps: 2,
    );
    addTearDown(owner.dispose);
    final first = owner.resolveRevisions(
      map: _map,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );
    for (final mapId in const <String>['neighbor-a', 'neighbor-b']) {
      owner.resolveRevisions(
        map: _staticMap.copyWith(id: mapId),
        project: _project,
        imagesById: const <String, ui.Image?>{},
        overlayToken: 0,
      );
    }

    expect(owner.revisionMapCount, 2);
    final reopened = owner.resolveRevisions(
      map: _map,
      project: _project,
      imagesById: const <String, ui.Image?>{},
      overlayToken: 0,
    );
    expect(reopened.mapRevision, greaterThan(first.mapRevision));
    expect(owner.revisionMapCount, 2);
  });

  test('changing one layer invalidates only that cached layer', () {
    final owner = EditorCanvasPictureCacheOwner(maxEntries: 16);
    addTearDown(owner.dispose);
    _record(_painter(owner: owner));
    final events = <EditorCanvasPictureCacheEvent>[];
    final changedGround = (_map.layers.first as TileLayer).copyWith(
      cells: const <int>[1, 1, 0, 0],
    );
    final changedMap = _map.copyWith(
      layers: <MapLayer>[changedGround, ..._map.layers.skip(1)],
    );

    _record(_painter(owner: owner, map: changedMap, onCacheEvent: events.add));

    expect(
      events,
      contains(
        isA<EditorCanvasPictureCacheEvent>()
            .having(
              (event) => event.cacheId,
              'cacheId',
              'tile:ground:background',
            )
            .having(
              (event) => event.disposition,
              'disposition',
              EditorCanvasPictureCacheDisposition.miss,
            ),
      ),
    );
    expect(
      events
          .where((event) => event.cacheId == 'collision:collision')
          .map((event) => event.disposition),
      <EditorCanvasPictureCacheDisposition>[
        EditorCanvasPictureCacheDisposition.hit,
      ],
    );
    expect(owner.entryCount, lessThanOrEqualTo(owner.maxEntries));
  });

  test('cached and uncached static renders remain pixel-identical', () async {
    final tile = await _tileImage();
    addTearDown(tile.dispose);
    final owner = EditorCanvasPictureCacheOwner(maxEntries: 8);
    addTearDown(owner.dispose);
    final uncached = await _pixels(
      _painter(map: _staticMap, imagesById: <String, ui.Image?>{'tiles': tile}),
    );
    final cachedPainter = _painter(
      owner: owner,
      map: _staticMap,
      imagesById: <String, ui.Image?>{'tiles': tile},
    );
    await _pixels(cachedPainter);
    final cached = await _pixels(cachedPainter);

    expect(cached, uncached);
  });
}

MapGridPainter _painter({
  EditorCanvasPictureCacheOwner? owner,
  EditorCanvasRepaintClock? clock,
  MapData map = _map,
  Map<String, ui.Image?> imagesById = const <String, ui.Image?>{},
  EditorCanvasPictureCacheObserver? onCacheEvent,
}) {
  return MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: imagesById,
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{'tiles': 1},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    project: _project,
    animationClock: clock,
    pictureCacheOwner: owner,
    debugOnPictureCache: onCacheEvent,
    showGrid: false,
    showEntityEditorChrome: false,
    showEditorOverlays: false,
  );
}

void _record(MapGridPainter painter) {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const ui.Size(64, 64));
  recorder.endRecording().dispose();
}

Future<ui.Image> _tileImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFF36C26E),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(32, 32);
  } finally {
    picture.dispose();
  }
}

Future<List<int>> _pixels(MapGridPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const ui.Size(64, 64));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(64, 64);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!.buffer.asUint8List().toList(growable: false);
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

const _staticMap = MapData(
  id: 'static-map',
  name: 'Static map',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0),
      ],
      cells: <int>[1, 1, 1, 1],
    ),
  ],
);

const _map = MapData(
  id: 'cache-map',
  name: 'Cache map',
  version: ProjectVersion.v6,
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(id: 'ground', name: 'Ground', cells: <int>[1, 0, 0, 0]),
    SmartTileLayer(
      id: 'water',
      name: 'Water',
      presetId: 'water',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'water'],
      field: SmartTileField.cell(semanticCells: <int>[1, 1, 1, 1]),
    ),
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[false, true, false, false],
    ),
  ],
);

final _project = ProjectManifest(
  name: 'Cache project',
  version: ProjectVersion.v6,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'water',
        name: 'Water',
        connectionGroupId: 'water',
      ),
    ],
    animations: <ProjectSmartTileAnimation>[
      ProjectSmartTileAnimation(
        id: 'water-loop',
        name: 'Water loop',
        frames: <ProjectSmartTileAnimationFrame>[
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(atlasId: 'water-atlas', column: 0, row: 0),
            durationMs: 110,
          ),
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(atlasId: 'water-atlas', column: 0, row: 0),
            durationMs: 110,
          ),
        ],
      ),
    ],
    presets: <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'water',
        name: 'Water',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'water',
        allowedMaterialIds: <String>['water'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'water',
            centerMatch: SmartTileSlotMatch.material('water'),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'water-loop',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'water-loop',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
