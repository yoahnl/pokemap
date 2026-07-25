import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders the authored Hanazuki guesthouse room from its real project',
      () async {
    const projectRoot =
        '/Users/karim/Desktop/pokeMap Project/le_train_de_17h42';
    const outputPath = '$projectRoot/previews/m00_authoring/'
        'map_hanazuki_guesthouse_room_runtime_render_1024x768.png';

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '$projectRoot/project.json',
      mapId: 'map_hanazuki_guesthouse_room',
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

    final width = bundle.map.size.width * bundle.cellWidth.toInt();
    final height = bundle.map.size.height * bundle.cellHeight.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    component.render(canvas);
    final rendered = await recorder.endRecording().toImage(width, height);
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final rawMap = jsonDecode(
      await File(
        '$projectRoot/maps/map_hanazuki_guesthouse_room.json',
      ).readAsString(),
    ) as Map<String, dynamic>;
    final rawLayers = rawMap['layers'] as List<dynamic>;
    final structureLayer = rawLayers
        .cast<Map<String, dynamic>>()
        .singleWhere((layer) => layer['id'] == 'l_structure');
    final structureTiles = structureLayer['tiles'] as List<dynamic>;
    final rawPlacements = rawMap['placedElements'] as List<dynamic>;

    expect(bundle.map.size, const GridSize(width: 16, height: 12));
    expect((width, height), (1024, 768));
    expect(bundle.map.placedElements, hasLength(27));
    expect(
      structureTiles.where((tileId) => tileId != 0),
      hasLength(145),
    );
    expect(
      rawPlacements.cast<Map<String, dynamic>>().any(
            (placement) => placement['elementId'] == 'el_room_architecture',
          ),
      isFalse,
    );
    expect(images, contains('tileset_m00_hanazuki_guesthouse_room'));
    expect(png, isNotNull);

    final output = File(outputPath);
    await output.parent.create(recursive: true);
    await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    expect(await output.length(), greaterThan(100000));
  });
}
