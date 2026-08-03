import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

const _fixtureFingerprint = 'ROT-01/FP-52A7/2x1/q0-q3/light-east';
const _tile = 16;
const _canvasSize = ui.Size(320, 248);
const _fingerprintPixels = <int>[0xD5, 0x52, 0xA7, 0x01];
const _captureFontFamily = 'Rot01CaptureFont';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ROT-01 editor visual evidence keeps the shared rotated fixture visible',
    () async {
      await _loadCaptureFont();
      final atlas = await _atlas();
      addTearDown(atlas.dispose);
      final fixture = _fixture();
      _expectFixtureContract(fixture);

      final image = await _renderEditorEvidence(fixture, atlas);
      addTearDown(image.dispose);
      await _expectFingerprint(image);
      await expectLater(
        _imageProvider(image),
        matchesGoldenFile(
          '../../../reports/ui/world_map_editor_gate_5_rotation_editor.png',
        ),
      );
    },
  );
}

({MapData map, ProjectManifest manifest}) _fixture() {
  const positions = <GridPos>[
    GridPos(x: 1, y: 1),
    GridPos(x: 6, y: 1),
    GridPos(x: 1, y: 5),
    GridPos(x: 6, y: 5),
  ];
  final placed = <MapPlacedElement>[];
  final actors = <MapEntity>[];
  for (var q = 0; q < 4; q++) {
    const source = GridSize(width: 2, height: 1);
    final transform = QuarterTurnGridTransform(
      sourceSize: source,
      quarterTurns: q,
    );
    final foreground = transform.sourceToDestination(const GridPos(x: 1, y: 0));
    placed.add(
      MapPlacedElement(
        id: '$_fixtureFingerprint/placed-q$q',
        layerId: 'objects',
        elementId: 'asymmetric-awning',
        pos: positions[q],
        quarterTurns: q,
      ),
    );
    actors.add(
      MapEntity(
        id: '$_fixtureFingerprint/actor-q$q',
        name: 'Actor q$q',
        kind: MapEntityKind.npc,
        pos: GridPos(
          x: positions[q].x + foreground.x,
          y: positions[q].y + foreground.y,
        ),
        blocksMovement: false,
        editorVisual: const MapEntityEditorVisual(elementId: 'test-actor'),
      ),
    );
  }
  final map = MapData(
    id: _fixtureFingerprint,
    name: 'ROT-01 shared visual fixture',
    size: const GridSize(width: 10, height: 8),
    layers: <MapLayer>[
      TileLayer(
        id: 'objects',
        name: 'Objects',
        tilesetId: 'diagnostic-atlas',
        tiles: List<int>.filled(80, 0, growable: false),
      ),
    ],
    placedElements: placed,
    entities: actors,
  );
  final manifest = ProjectManifest(
    name: _fixtureFingerprint,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'diagnostic-atlas',
        name: 'Diagnostic atlas',
        relativePath: 'diagnostic.png',
      ),
    ],
    settings: const ProjectSettings(tileWidth: _tile, tileHeight: _tile),
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'asymmetric-awning',
        name: 'Asymmetric awning',
        tilesetId: 'diagnostic-atlas',
        categoryId: 'test',
        frames: const <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
          ),
        ],
        collisionProfile: const ElementCollisionProfile(
          cells: <GridPos>[GridPos(x: 0, y: 0)],
        ),
        projectedBuildingShadow: _shadowConfig(),
      ),
      const ProjectElementEntry(
        id: 'test-actor',
        name: 'Test actor',
        tilesetId: 'diagnostic-atlas',
        categoryId: 'test',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 2, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
    projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
      presets: <ProjectBuildingShadowPreset>[_shadowPreset()],
    ),
  );
  return (map: map, manifest: manifest);
}

Future<ui.Image> _renderEditorEvidence(
  ({MapData map, ProjectManifest manifest}) fixture,
  ui.Image atlas,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFF111827), ui.BlendMode.src);
  _paintHeader(canvas, 'EDITOR  •  $_fixtureFingerprint');
  for (var q = 0; q < 4; q++) {
    final panel = _panelRect(q);
    _paintPanelFrame(canvas, panel, 'q$q');
    canvas.save();
    canvas.clipRect(panel.deflate(4));
    canvas.translate(panel.left + 4, panel.top + 20);
    final focus = _focusForQuarterTurn(q);
    MapGridPainter(
      map: fixture.map,
      zoom: 1,
      offset: ui.Offset(-focus.dx, -focus.dy),
      tileWidth: _tile.toDouble(),
      tileHeight: _tile.toDouble(),
      tilesetImagesById: <String, ui.Image?>{'diagnostic-atlas': atlas},
      sourceTileWidth: _tile,
      sourceTileHeight: _tile,
      tilesPerRowById: const <String, int>{'diagnostic-atlas': 3},
      warps: const <MapWarp>[],
      gameplayZones: const <MapGameplayZone>[],
      connectionLabelsByDirection: const <MapConnectionDirection, String>{},
      project: fixture.manifest,
      showGrid: true,
      showEntityEditorChrome: false,
      showEditorOverlays: false,
    ).paint(canvas, ui.Size(panel.width - 8, panel.height - 24));
    canvas.restore();
  }
  _paintLegend(canvas);
  return recorder
      .endRecording()
      .toImage(_canvasSize.width.toInt(), _canvasSize.height.toInt());
}

void _expectFixtureContract(({MapData map, ProjectManifest manifest}) fixture) {
  expect(fixture.map.id, _fixtureFingerprint);
  expect(fixture.manifest.name, _fixtureFingerprint);
  expect(fixture.map.placedElements.map((e) => e.quarterTurns),
      orderedEquals(<int>[0, 1, 2, 3]));
  expect(fixture.map.entities, hasLength(4));
  expect(
      fixture
          .manifest.projectedBuildingShadowCatalog.presets.single.direction.x,
      0.8);
  expect(
      fixture
          .manifest.projectedBuildingShadowCatalog.presets.single.direction.y,
      0.35);
}

Future<void> _expectFingerprint(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  for (var index = 0; index < _fingerprintPixels.length; index++) {
    final offset = ((8 * image.width) + 8 + index) * 4;
    expect(data!.getUint8(offset), _fingerprintPixels[index]);
  }
}

Future<ui.Image> _atlas() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..isAntiAlias = false;
  // Three deliberately distinct 16px columns: the 2x1 prop reads clockwise.
  paint.color = const ui.Color(0xFFE84A5F);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 16, 16), paint);
  paint.color = const ui.Color(0xFFFFD166);
  canvas.drawRect(const ui.Rect.fromLTWH(16, 0, 16, 16), paint);
  paint.color = const ui.Color(0xFF4CC9F0);
  canvas.drawRect(const ui.Rect.fromLTWH(32, 0, 16, 16), paint);
  paint.color = const ui.Color(0xFF0B1020);
  canvas.drawRect(const ui.Rect.fromLTWH(4, 3, 4, 10), paint);
  canvas.drawRect(const ui.Rect.fromLTWH(20, 5, 10, 4), paint);
  return recorder.endRecording().toImage(48, 16);
}

ProjectElementProjectedBuildingShadowConfig _shadowConfig() =>
    ProjectElementProjectedBuildingShadowConfig(
      enabled: true,
      presetId: 'rot-01-world-light',
      anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
      localOffset: ProjectedShadowOffset(x: 0, y: 0),
    );

ProjectBuildingShadowPreset _shadowPreset() => ProjectBuildingShadowPreset(
      id: 'rot-01-world-light',
      name: 'World light unchanged',
      direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
      shape: ProjectedShadowShapeTuning(
        lengthRatio: 0.8,
        nearWidthRatio: 0.9,
        farWidthRatio: 0.45,
      ),
      appearance:
          ProjectedShadowAppearance(opacity: 0.55, colorHexRgb: '263238'),
      timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    );

ui.Rect _panelRect(int q) => ui.Rect.fromLTWH(
      q.isEven ? 8 : 164,
      q < 2 ? 36 : 134,
      148,
      88,
    );

ui.Offset _focusForQuarterTurn(int q) {
  const anchors = <ui.Offset>[
    ui.Offset(0, 0),
    ui.Offset(80, 0),
    ui.Offset(0, 64),
    ui.Offset(80, 64),
  ];
  return anchors[q];
}

void _paintHeader(ui.Canvas canvas, String text) {
  final paint = ui.Paint()..isAntiAlias = false;
  for (var index = 0; index < _fingerprintPixels.length; index++) {
    paint.color = ui.Color(0xFF000000 | (_fingerprintPixels[index] << 16));
    canvas.drawRect(ui.Rect.fromLTWH((8 + index).toDouble(), 8, 1, 1), paint);
  }
  _text(canvas, text, const ui.Offset(18, 5), 12, const ui.Color(0xFFF8FAFC));
}

void _paintPanelFrame(ui.Canvas canvas, ui.Rect panel, String label) {
  canvas.drawRect(panel, ui.Paint()..color = const ui.Color(0xFF1F2937));
  canvas.drawRect(
      panel,
      ui.Paint()
        ..color = const ui.Color(0xFF64748B)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1);
  _text(canvas, '$label  •  BG → ACTOR → FG/OCCLUSION',
      panel.topLeft + const ui.Offset(5, 3), 9, const ui.Color(0xFFE2E8F0));
}

void _paintLegend(ui.Canvas canvas) {
  _text(
      canvas,
      'pink/yellow = asymmetric source pixels  •  cyan = actor  •  slate polygon = same world-light shadow',
      const ui.Offset(8, 226),
      9,
      const ui.Color(0xFFCBD5E1));
}

void _text(ui.Canvas canvas, String text, ui.Offset offset, double size,
    ui.Color color) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(
            color: Color(color.toARGB32()),
            fontSize: size,
            fontFamily: _captureFontFamily)),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, Offset(offset.dx, offset.dy));
}

Future<Uint8List> _imageProvider(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();

Future<void> _loadCaptureFont() async {
  final bytes = await rootBundle.load(
    'assets/fonts/pokemap_capture_sans_regular.ttf',
  );
  final loader = FontLoader(_captureFontFamily)
    ..addFont(Future<ByteData>.value(bytes));
  await loader.load();
}
