import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_actor_occlusion_component.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_animation_activation_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['AVELUNE_KANTO_VISUAL_PROJECT'];
  final evidence = Platform.environment['AVELUNE_KANTO_VISUAL_EVIDENCE'];

  test(
    'converted Azuria flowers retain opaque pixels in every native frame',
    () async {
      final manifest = await _manifest(root!);
      final map = await _map(root, manifest, 'Cerulean City');
      final ground = map.layers.whereType<TileLayer>().singleWhere(
        (layer) => layer.name == 'Source Z 0',
      );
      final tile = ground.palette[ground.cells[21 * map.size.width + 13] - 1];
      final tileset = manifest.tilesets.singleWhere(
        (t) => t.id == tile.tilesetId,
      );
      final image = await _image('$root/${tileset.relativePath}');
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final atlas = tileset.source as ProjectRegularAtlasTilesetSource;
        final animation = atlas.tileAnimations.singleWhere(
          (animation) => animation.tileId == tile.localTileId,
        );
        expect(animation.frames, hasLength(5));
        for (final frame in animation.frames) {
          final x = frame.tileId % (image.width ~/ 32) * 32;
          final y = frame.tileId ~/ (image.width ~/ 32) * 32;
          for (var dy = 0; dy < 32; dy++) {
            for (var dx = 0; dx < 32; dx++) {
              expect(
                bytes!.getUint8(((y + dy) * image.width + x + dx) * 4 + 3),
                255,
                reason: 'frame ${frame.tileId}, pixel $dx,$dy',
              );
            }
          }
        }
      } finally {
        image.dispose();
      }
    },
    skip: root == null,
  );

  test(
    'converted grass renders on entry then clears while the player stays',
    () async {
      final manifest = await _manifest(root!);
      final map = await _map(root, manifest, 'Route 5');
      final layer = map.layers.whereType<SmartTileLayer>().singleWhere(
        (layer) => layer.id.endsWith('_grass_rustle'),
      );
      expect(layer.animationActivation, SmartTileAnimationActivation.onEnter);
      final cells = smartTileSemanticCells(layer);
      final index = cells.indexWhere((value) => value != 0);
      expect(index, greaterThanOrEqualTo(0));
      final cell = GridPos(
        x: index % map.size.width,
        y: index ~/ map.size.width,
      );
      final blankIndex = cells.indexOf(0);
      expect(blankIndex, greaterThanOrEqualTo(0));
      final blank = GridPos(
        x: blankIndex % map.size.width,
        y: blankIndex ~/ map.size.width,
      );
      final preset = manifest.smartTileCatalog.presets.singleWhere(
        (preset) => preset.id == layer.presetId,
      );
      final animationId =
          (preset.rules.single.candidates.single.parts.single.source
                  as SmartTileAnimationSource)
              .animationId;
      final animation = manifest.smartTileCatalog.animations.singleWhere(
        (animation) => animation.id == animationId,
      );
      expect(animation.loop, SmartTileAnimationLoop.once);
      expect(animation.frames, hasLength(11));
      final atlasId = animation.frames[1].frame.atlasId;
      final atlas = manifest.smartTileCatalog.atlases.singleWhere(
        (atlas) => atlas.id == atlasId,
      );
      final tileset = manifest.tilesets.singleWhere(
        (t) => t.id == atlas.tilesetId,
      );
      final image = await _image('$root/${tileset.relativePath}');
      final isolated = map.copyWith(
        layers: [layer],
        placedElements: [],
        entities: [],
      );
      final controller = SmartTileAnimationActivationController(
        map: isolated,
        catalog: manifest.smartTileCatalog,
      );
      final bundle = RuntimeMapBundle(
        manifest: manifest,
        map: isolated,
        projectRootDirectory: root,
        tilesetAbsolutePathsById: {tileset.id: '$root/${tileset.relativePath}'},
      );
      final cellSize = ui.Size(bundle.cellWidth, bundle.cellHeight);
      final collection =
          SmartTileActorOcclusionLayerCollection(
            bundle: bundle,
            tileImagesByTilesetId: {
              tileset.id: RuntimeTilesetImage.borrowed(image),
            },
            smartTileAnimationController: controller,
          )..setVisibleLocalRect(
            ui.Rect.fromLTWH(
              cell.x * cellSize.width,
              cell.y * cellSize.height,
              cellSize.width,
              cellSize.height,
            ),
          );
      try {
        controller.resetPlayerOccupancy(blank);
        final idle = await _render(collection, cell, cellSize);
        expect(_alphaPixels(idle), 0);
        controller.onPlayerEnteredCell(cell, previousCell: blank);
        controller.update(0.08);
        collection.update(0.08);
        final active = await _render(collection, cell, cellSize);
        expect(_alphaPixels(active), greaterThan(0));
        controller.onPlayerStepCompleted();
        controller.update(0.6);
        collection.update(0.6);
        final finished = await _render(collection, cell, cellSize);
        expect(_alphaPixels(finished), 0);
        controller.onPlayerEnteredCell(blank, previousCell: cell);
        controller.update(0.08);
        collection.update(0.08);
        final outside = await _render(collection, cell, cellSize);
        expect(_alphaPixels(outside), 0);
        controller.onPlayerEnteredCell(cell, previousCell: blank);
        controller.update(0.08);
        collection.update(0.08);
        final repeated = await _render(collection, cell, cellSize);
        expect(repeated, active);
        if (evidence != null) {
          await Directory(evidence).create(recursive: true);
          await File('$evidence/grass-runtime-proof.json').writeAsString(
            jsonEncode({
              'projectPath': root,
              'mapId': map.id,
              'cell': {'x': cell.x, 'y': cell.y},
              'idleOpaquePixels': _alphaPixels(idle),
              'activeOpaquePixels': _alphaPixels(active),
              'finishedOpaquePixels': _alphaPixels(finished),
              'outsideOpaquePixels': _alphaPixels(outside),
              'reentryReplaysSamePixels':
                  repeated.toString() == active.toString(),
              'readOnlyProject': true,
            }),
          );
        }
      } finally {
        image.dispose();
      }
    },
    skip: root == null,
  );
}

Future<ProjectManifest> _manifest(String root) async =>
    ProjectManifest.fromJson(
      jsonDecode(await File('$root/project.json').readAsString()),
    );

Future<MapData> _map(String root, ProjectManifest manifest, String name) async {
  final entry = manifest.maps.singleWhere((entry) => entry.name == name);
  return MapData.fromJson(
    jsonDecode(await File('$root/${entry.relativePath}').readAsString()),
  );
}

Future<ui.Image> _image(String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

Future<Uint8List> _render(
  SmartTileActorOcclusionLayerCollection collection,
  GridPos cell,
  ui.Size cellSize,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..translate(-cell.x * cellSize.width, -cell.y * cellSize.height);
  collection.rows[cell.y].render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    cellSize.width.ceil(),
    cellSize.height.ceil(),
  );
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
        .asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

int _alphaPixels(Uint8List bytes) {
  var count = 0;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] > 0) count++;
  }
  return count;
}
