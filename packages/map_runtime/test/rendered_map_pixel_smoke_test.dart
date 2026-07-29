import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders repository-owned Selbrume pixels into a temporary PNG',
      () async {
    final fixture = SelbrumeEventV2RuntimeFixture.locate();
    final outputDirectory = await Directory.systemTemp.createTemp(
      'pokemap_rendered_map_pixel_smoke_',
    );
    addTearDown(() async {
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
    });

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: fixture.projectPath,
      mapId: selbrumePortMapId,
    );
    final transparentColors = <String, TilesetTransparentColor>{
      for (final tileset in bundle.manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    };
    final images = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: transparentColors,
    );
    final component = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: images,
    );
    final rendered = await _renderOverview(
      component,
      worldWidth: (bundle.map.size.width * bundle.cellWidth).round(),
      worldHeight: (bundle.map.size.height * bundle.cellHeight).round(),
    );
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);

    expect(fixture.isCanonicalProject, isFalse);
    expect(bundle.map.id, selbrumePortMapId);
    expect(bundle.map.placedElements, isNotEmpty);
    expect(
      bundle.map.layers
          .whereType<TileLayer>()
          .expand((layer) => layer.tiles)
          .where((tileId) => tileId > 0),
      isNotEmpty,
    );
    expect(
      images,
      contains('ts_selbrume_port_reference_v3'),
    );
    expect(
      images,
      contains('ts_selbrume_port_ground_v3'),
    );
    expect(await _containsNonBlackPixel(rendered), isTrue);
    expect(png, isNotNull);

    // The smoke may read the versioned project, but it must never mutate it.
    // Keeping the only write below under system temp protects fresh checkouts
    // and developer-authored projects from preview artifacts.
    final output = File(p.join(outputDirectory.path, 'selbrume_port.png'));
    expect(p.isWithin(fixture.root.path, output.path), isFalse);
    for (final assetPath in bundle.tilesetAbsolutePathsById.values) {
      expect(
        p.isWithin(fixture.root.path, assetPath),
        isTrue,
        reason: 'Runtime asset escaped the versioned fixture: $assetPath',
      );
    }
    await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    expect(await output.length(), greaterThan(1000));
  });
}

Future<ui.Image> _renderOverview(
  MapLayersComponent component, {
  required int worldWidth,
  required int worldHeight,
}) {
  const viewportWidth = 320;
  const viewportHeight = 240;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(
      0,
      0,
      viewportWidth.toDouble(),
      viewportHeight.toDouble(),
    ),
    ui.Paint()..color = const ui.Color(0xff000000),
  );

  final scale = math.min(
    viewportWidth / worldWidth,
    viewportHeight / worldHeight,
  );
  final offsetX = (viewportWidth - (worldWidth * scale)) / 2;
  final offsetY = (viewportHeight - (worldHeight * scale)) / 2;
  component.update(0);
  canvas
    ..save()
    ..translate(offsetX, offsetY)
    ..scale(scale, scale);
  component.render(canvas);
  canvas.restore();
  return recorder.endRecording().toImage(viewportWidth, viewportHeight);
}

Future<bool> _containsNonBlackPixel(ui.Image image) async {
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (pixels == null) {
    throw StateError('Could not read rendered pixels.');
  }
  for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
    if (pixels.getUint8(offset) != 0 ||
        pixels.getUint8(offset + 1) != 0 ||
        pixels.getUint8(offset + 2) != 0) {
      return true;
    }
  }
  return false;
}
