import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_test_layer_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/workbench/smart_tile_compact_lab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Tile lab sprites', () {
    test('the controller resolves visuals scaled to the lab cell extent', () {
      final controller = SmartTileTestLayerController(
        preset: _preset,
        catalog: _catalog,
      );
      controller.applyTarget(
        const SmartTileLabTarget(
          kind: SmartTileLabTargetKind.cell,
          x: 2,
          y: 2,
        ),
        tool: SmartTileLabTool.pencil,
      );

      final visuals = controller.resolveVisuals(
        destinationCellWidth: 44,
        destinationCellHeight: 44,
      );

      expect(visuals, hasLength(1));
      final visual = visuals.single;
      expect(visual.cellX, 2);
      expect(visual.cellY, 2);
      expect(visual.tilesetId, 'tileset');
      expect(visual.geometry.destinationRect.left, 88);
      expect(visual.geometry.destinationRect.top, 88);
      expect(visual.geometry.destinationRect.width, 44);
      expect(visual.geometry.destinationRect.height, 44);
    });

    test('an empty layer resolves no visual at all', () {
      final controller = SmartTileTestLayerController(
        preset: _preset,
        catalog: _catalog,
      );

      expect(
        controller.resolveVisuals(
          destinationCellWidth: 44,
          destinationCellHeight: 44,
        ),
        isEmpty,
      );
    });

    test('the painter draws the resolved sprite on the painted cell', () async {
      final tileset = await _redFirstCellTileset();
      addTearDown(tileset.dispose);
      final controller = SmartTileTestLayerController(
        preset: _preset,
        catalog: _catalog,
      );
      controller.applyTarget(
        const SmartTileLabTarget(
          kind: SmartTileLabTargetKind.cell,
          x: 2,
          y: 2,
        ),
        tool: SmartTileLabTool.pencil,
      );

      final pixels = await _paintLab(
        controller: controller,
        tilesetImages: <String, ui.Image?>{'tileset': tileset},
      );

      // Cell (2,2) spans 88..132 in map space, shifted by the 14px padding.
      final painted = _pixelAt(pixels, x: 124, y: 124);
      expect(painted.red, greaterThan(200));
      expect(painted.green, lessThan(60));
      expect(painted.blue, lessThan(60));
    });

    test('the painter leaves unpainted cells free of sprite pixels', () async {
      final tileset = await _redFirstCellTileset();
      addTearDown(tileset.dispose);
      final controller = SmartTileTestLayerController(
        preset: _preset,
        catalog: _catalog,
      );
      controller.applyTarget(
        const SmartTileLabTarget(
          kind: SmartTileLabTargetKind.cell,
          x: 2,
          y: 2,
        ),
        tool: SmartTileLabTool.pencil,
      );

      final pixels = await _paintLab(
        controller: controller,
        tilesetImages: <String, ui.Image?>{'tileset': tileset},
      );

      // Cell (5,5) was never painted, so no red sprite may bleed into it.
      final untouched = _pixelAt(pixels, x: 256, y: 256);
      expect(untouched.red, lessThan(200));
    });
  });
}

const double _cellExtent = 44;
const double _padding = SmartTileCompactLab.canvasPadding;

Future<ByteData> _paintLab({
  required SmartTileTestLayerController controller,
  required Map<String, ui.Image?> tilesetImages,
}) async {
  const side = 7 * _cellExtent + _padding * 2;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  SmartTileCompactLabPainter(
    layer: controller.layer,
    mapSize: controller.size,
    topology: controller.preset.topology,
    visuals: controller.resolveVisuals(
      destinationCellWidth: _cellExtent,
      destinationCellHeight: _cellExtent,
    ),
    tilesetImages: tilesetImages,
    showStructure: false,
    cellExtent: _cellExtent,
    padding: _padding,
    selectedX: null,
    selectedY: null,
    backgroundColor: const Color(0xff101010),
    emptyCellColor: const Color(0xff202020),
    authoredCellColor: const Color(0xff303030),
    gridColor: const Color(0xff404040),
    edgeColor: const Color(0xff505050),
    cornerColor: const Color(0xff606060),
    selectionColor: const Color(0xff707070),
  ).paint(canvas, const Size(side, side));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(side.round(), side.round());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!;
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

({int red, int green, int blue}) _pixelAt(
  ByteData pixels, {
  required int x,
  required int y,
}) {
  final width = (7 * _cellExtent + _padding * 2).round();
  final offset = ((y * width) + x) * 4;
  return (
    red: pixels.getUint8(offset),
    green: pixels.getUint8(offset + 1),
    blue: pixels.getUint8(offset + 2),
  );
}

/// A 64×64 atlas whose first 32×32 cell is opaque red and the rest deep blue.
Future<ui.Image> _redFirstCellTileset() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 64, 64),
    ui.Paint()..color = const Color(0xff0000ff),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    ui.Paint()..color = const Color(0xffff0000),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(64, 64);
  } finally {
    picture.dispose();
  }
}

final ProjectSmartTilePreset _preset = ProjectSmartTilePreset(
  id: 'lab-preset',
  name: 'Herbe de laboratoire',
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.explicit,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: const <String>['grass'],
  status: SmartTilePresetStatus.published,
  rules: <SmartTileRule>[
    SmartTileRule(
      id: 'uniform',
      centerMatch: const SmartTileSlotMatch.any(),
      signature: smartTileSignatureForMask(
        0,
        topology: SmartTileTopology.uniform,
      ),
      candidates: const <SmartTileCandidate>[
        SmartTileCandidate(
          id: 'variant',
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

final ProjectSmartTileCatalog _catalog = ProjectSmartTileCatalog(
  atlases: const <ProjectSmartTileAtlas>[
    ProjectSmartTileAtlas(
      id: 'atlas',
      name: 'Atlas',
      tilesetId: 'tileset',
      columns: 2,
      rows: 2,
    ),
  ],
  materials: const <ProjectSmartTileMaterial>[
    ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Grass',
      connectionGroupId: 'ground',
    ),
  ],
  presets: <ProjectSmartTilePreset>[_preset],
);
