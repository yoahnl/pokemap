import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/runtime_projected_building_shadow_collection.dart';

const _fixtureFingerprint = 'ROT-01/FP-52A7/2x1/q0-q3/light-east';
const _tile = 16;
const _canvasSize = ui.Size(320, 248);
const _fingerprintPixels = <int>[0xD5, 0x52, 0xA7, 0x01];
const _captureFontFamily = 'Rot01CaptureFont';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ROT-01 runtime visual evidence and comparison keep the shared fixture aligned',
    () async {
      await _loadCaptureFont();
      final fixture = _fixture();
      _expectFixtureContract(fixture);
      final atlas = await _atlas();
      addTearDown(atlas.image.dispose);

      final runtime = await _renderRuntimeEvidence(fixture, atlas.runtimeImage);
      addTearDown(runtime.dispose);
      await _expectFingerprint(runtime);
      await expectLater(
        _imageProvider(runtime),
        matchesGoldenFile(
          '../../../reports/ui/world_map_editor_gate_5_rotation_runtime.png',
        ),
      );

      final editor = await _loadEditorGolden();
      addTearDown(editor.dispose);
      await _expectFingerprint(editor);
      expect(editor.width, runtime.width);
      expect(editor.height, runtime.height);
      final comparison = await _comparison(editor, runtime);
      addTearDown(comparison.dispose);
      await expectLater(
        _imageProvider(comparison),
        matchesGoldenFile(
          '../../../reports/ui/world_map_editor_gate_5_rotation_comparison.png',
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
  for (var q = 0; q < 4; q++) {
    placed.add(
      MapPlacedElement(
        id: '$_fixtureFingerprint/placed-q$q',
        layerId: 'objects',
        elementId: 'asymmetric-awning',
        pos: positions[q],
        quarterTurns: q,
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
    ],
    projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
      presets: <ProjectBuildingShadowPreset>[_shadowPreset()],
    ),
  );
  return (map: map, manifest: manifest);
}

Future<ui.Image> _renderRuntimeEvidence(
  ({MapData map, ProjectManifest manifest}) fixture,
  RuntimeTilesetImage atlas,
) async {
  final bundle = RuntimeMapBundle(
    manifest: fixture.manifest,
    map: fixture.map,
    projectRootDirectory: '/tmp/rot-01-visual-evidence',
    tilesetAbsolutePathsById: const <String, String>{},
  );
  final background = MapLayersComponent(
    bundle: bundle,
    tileImagesByTilesetId: <String, RuntimeTilesetImage>{
      'diagnostic-atlas': atlas,
    },
    shadowCollectionProvider: () =>
        buildRuntimeProjectedBuildingShadowCollection(
      manifest: fixture.manifest,
      mapData: fixture.map,
    ),
  );
  final foreground = MapLayersComponent(
    bundle: bundle,
    tileImagesByTilesetId: <String, RuntimeTilesetImage>{
      'diagnostic-atlas': atlas,
    },
    renderPass: MapLayerRenderPass.foreground,
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFF111827), ui.BlendMode.src);
  _paintHeader(canvas, 'RUNTIME • $_fixtureFingerprint');
  for (var q = 0; q < 4; q++) {
    final panel = _panelRect(q);
    _paintPanelFrame(canvas, panel, 'q$q');
    canvas.save();
    canvas.clipRect(panel.deflate(4));
    canvas.translate(panel.left + 4, panel.top + 20);
    final focus = _focusForQuarterTurn(q);
    canvas.translate(-focus.dx, -focus.dy);
    background.render(canvas);
    _paintActorsBetweenPasses(canvas);
    foreground.render(canvas);
    canvas.restore();
  }
  _paintLegend(canvas);
  return recorder
      .endRecording()
      .toImage(_canvasSize.width.toInt(), _canvasSize.height.toInt());
}

void _paintActorsBetweenPasses(ui.Canvas canvas) {
  const anchors = <GridPos>[
    GridPos(x: 1, y: 1),
    GridPos(x: 6, y: 1),
    GridPos(x: 1, y: 5),
    GridPos(x: 6, y: 5),
  ];
  final paint = ui.Paint()
    ..isAntiAlias = false
    ..color = const ui.Color(0xFF4CC9F0);
  for (var q = 0; q < 4; q++) {
    final transform = QuarterTurnGridTransform(
      sourceSize: const GridSize(width: 2, height: 1),
      quarterTurns: q,
    );
    final foreground = transform.sourceToDestination(const GridPos(x: 1, y: 0));
    canvas.drawRect(
      ui.Rect.fromLTWH(
        (anchors[q].x + foreground.x) * _tile.toDouble(),
        (anchors[q].y + foreground.y) * _tile.toDouble(),
        _tile.toDouble(),
        _tile.toDouble(),
      ),
      paint,
    );
  }
}

Future<ui.Image> _comparison(ui.Image editor, ui.Image runtime) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const width = 656;
  const height = 280;
  canvas.drawColor(const ui.Color(0xFF111827), ui.BlendMode.src);
  _text(
      canvas,
      'ROT-01 • SAME FP-52A7 • editor | runtime • 1:1 pixels / no resampling',
      const ui.Offset(8, 6),
      11,
      const ui.Color(0xFFF8FAFC));
  _text(
      canvas, 'EDITOR', const ui.Offset(8, 22), 10, const ui.Color(0xFFE2E8F0));
  _text(canvas, 'RUNTIME', const ui.Offset(336, 22), 10,
      const ui.Color(0xFFE2E8F0));
  canvas.drawImage(
      editor, const ui.Offset(8, 32), ui.Paint()..isAntiAlias = false);
  canvas.drawImage(
      runtime, const ui.Offset(336, 32), ui.Paint()..isAntiAlias = false);
  canvas.drawRect(const ui.Rect.fromLTWH(328, 32, 1, 248),
      ui.Paint()..color = const ui.Color(0xFF64748B));
  return recorder.endRecording().toImage(width, height);
}

Future<ui.Image> _loadEditorGolden() async {
  final bytes = await File(
    '../../reports/ui/world_map_editor_gate_5_rotation_editor.png',
  ).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

void _expectFixtureContract(({MapData map, ProjectManifest manifest}) fixture) {
  expect(fixture.map.id, _fixtureFingerprint);
  expect(fixture.manifest.name, _fixtureFingerprint);
  expect(fixture.map.placedElements.map((e) => e.quarterTurns),
      orderedEquals(<int>[0, 1, 2, 3]));
  final light =
      fixture.manifest.projectedBuildingShadowCatalog.presets.single.direction;
  expect(light.x, 0.8);
  expect(light.y, 0.35);
}

Future<void> _expectFingerprint(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  for (var index = 0; index < _fingerprintPixels.length; index++) {
    final offset = ((8 * image.width) + 8 + index) * 4;
    expect(data!.getUint8(offset), _fingerprintPixels[index]);
  }
}

Future<({ui.Image image, RuntimeTilesetImage runtimeImage})> _atlas() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..isAntiAlias = false;
  paint.color = const ui.Color(0xFFE84A5F);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 16, 16), paint);
  paint.color = const ui.Color(0xFFFFD166);
  canvas.drawRect(const ui.Rect.fromLTWH(16, 0, 16, 16), paint);
  paint.color = const ui.Color(0xFF4CC9F0);
  canvas.drawRect(const ui.Rect.fromLTWH(32, 0, 16, 16), paint);
  paint.color = const ui.Color(0xFF0B1020);
  canvas.drawRect(const ui.Rect.fromLTWH(4, 3, 4, 10), paint);
  canvas.drawRect(const ui.Rect.fromLTWH(20, 5, 10, 4), paint);
  final image = await recorder.endRecording().toImage(48, 16);
  return (
    image: image,
    runtimeImage: RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: const <RuntimeTilesetChunk>[
        RuntimeTilesetChunk(top: 0, height: 16, width: 48),
      ],
      width: 48,
      height: 16,
    ),
  );
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
          lengthRatio: 0.8, nearWidthRatio: 0.9, farWidthRatio: 0.45),
      appearance:
          ProjectedShadowAppearance(opacity: 0.55, colorHexRgb: '263238'),
      timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    );

ui.Rect _panelRect(int q) =>
    ui.Rect.fromLTWH(q.isEven ? 8 : 164, q < 2 ? 36 : 134, 148, 88);

ui.Offset _focusForQuarterTurn(int q) {
  const anchors = <ui.Offset>[
    ui.Offset(0, 0),
    ui.Offset(80, 0),
    ui.Offset(0, 64),
    ui.Offset(80, 64)
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

void _paintLegend(ui.Canvas canvas) => _text(
    canvas,
    'pink/yellow = asymmetric source pixels  •  cyan = actor  •  slate polygon = same world-light shadow',
    const ui.Offset(8, 226),
    9,
    const ui.Color(0xFFCBD5E1));

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
  final bytes = await File(
    '../map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final loader = FontLoader(_captureFontFamily)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}
