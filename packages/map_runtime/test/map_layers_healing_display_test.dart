import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/player/runtime_world_service_models.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart' show pixelAt, rgba;

RuntimeMapBundle _bundle({double scale = 1}) {
  final display = MapEntity(
    id: 'balls',
    kind: MapEntityKind.custom,
    pos: const GridPos(x: 2, y: 2),
    blocksMovement: false,
    healingDisplay: MapEntityHealingDisplayData(
      variantElementIds: [for (var n = 1; n <= 6; n++) 'balls-$n'],
    ),
  );
  return RuntimeMapBundle(
    projectRootDirectory: 'unused',
    tilesetAbsolutePathsById: const {},
    map: MapData(
      id: 'center',
      name: 'Centre',
      size: const GridSize(width: 8, height: 8),
      entities: [
        display,
        const MapEntity(
          id: 'decoration',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 6, y: 6),
          editorVisual: MapEntityEditorVisual(elementId: 'decoration'),
        ),
      ],
    ),
    manifest: ProjectManifest(
      name: 'Native display',
      maps: const [],
      settings: ProjectSettings(
        tileWidth: 32,
        tileHeight: 32,
        displayScale: scale,
      ),
      tilesets: [
        for (var sheet = 1; sheet <= 2; sheet++)
          ProjectTilesetEntry(
            id: 'sheet-$sheet',
            name: 'Sheet $sheet',
            relativePath: 'sheet-$sheet.png',
            source: ProjectRegularAtlasTilesetSource(
              assetId: 'sheet-$sheet',
              pixelWidth: 256,
              pixelHeight: 192,
              tileWidth: 64,
              tileHeight: 48,
            ),
          ),
        const ProjectTilesetEntry(
          id: 'decor',
          name: 'Decoration',
          relativePath: 'decor.png',
        ),
      ],
      elements: [
        for (var n = 1; n <= 6; n++)
          ProjectElementEntry(
            id: 'balls-$n',
            name: 'Balls $n',
            tilesetId: 'sheet-${n <= 3 ? 1 : 2}',
            categoryId: 'healing',
            frames: [
              for (var frame = 0; frame < 4; frame++)
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: frame, y: (n - 1) % 3 + 1),
                  durationMs: 125,
                ),
            ],
          ),
        const ProjectElementEntry(
          id: 'decoration',
          name: 'Decoration',
          tilesetId: 'decor',
          categoryId: 'other',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
        ),
      ],
    ),
  );
}

Future<RuntimeTilesetImage> _sheet(int sheet) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var row = 1; row <= 3; row++) {
    for (var frame = 0; frame < 4; frame++) {
      final count = (sheet - 1) * 3 + row;
      canvas.drawRect(
        Rect.fromLTWH((frame * 64).toDouble(), (row * 48).toDouble(), 64, 48),
        Paint()..color = Color.fromARGB(255, count * 30, frame * 50, 85),
      );
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(256, 192);
  picture.dispose();
  return RuntimeTilesetImage(
    images: [image],
    chunks: buildRuntimeTilesetChunks(totalWidth: 256, totalHeight: 192),
    width: 256,
    height: 192,
  );
}

Future<Map<String, RuntimeTilesetImage>> _images() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 32, 32),
    Paint()..color = const Color(0xFF22AA44),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 32);
  picture.dispose();
  final images = {
    'sheet-1': await _sheet(1),
    'sheet-2': await _sheet(2),
    'decor': RuntimeTilesetImage(
      images: [image],
      chunks: buildRuntimeTilesetChunks(totalWidth: 32, totalHeight: 32),
      width: 32,
      height: 32,
    ),
  };
  addTearDown(() {
    for (final image in images.values) {
      image.dispose();
    }
  });
  return images;
}

Future<ui.Image> _render(MapLayersComponent component, {int size = 256}) async {
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  final picture = recorder.endRecording();
  final result = await picture.toImage(size, size);
  picture.dispose();
  addTearDown(result.dispose);
  return result;
}

RuntimeHealingDisplaySnapshot _active(
  int count, {
  String mapId = 'center',
  String entityId = 'balls',
}) => RuntimeHealingDisplaySnapshot(
  mapId: mapId,
  entityId: entityId,
  memberCount: count,
);

void main() {
  test('native resource closure loads all six healing display variants', () {
    final bundle = _bundle();
    final ids = collectAllRuntimeTilesetIds(bundle.map, bundle.manifest);
    expect(ids, containsAll(['sheet-1', 'sheet-2', 'decor']));
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  for (var count = 1; count <= 6; count++) {
    test(
      'active display draws exact bottom-centered64x48 pixels for $count actual members',
      () async {
        final component = MapLayersComponent(
          bundle: _bundle(),
          tileImagesByTilesetId: await _images(),
          healingDisplaySnapshotProvider: () => _active(count),
        );
        addTearDown(component.dispose);
        final image = await _render(component);
        expect(await pixelAt(image, 48, 48), rgba(count * 30, 0, 85, 255));
        expect(await pixelAt(image, 111, 95), rgba(count * 30, 0, 85, 255));
        for (final point in [(47, 48), (112, 95), (64, 47), (64, 96)]) {
          expect(await pixelAt(image, point.$1, point.$2), rgba(0, 0, 0, 0));
        }
        expect(await pixelAt(image, 208, 208), rgba(34, 170, 68, 255));
        expect(
          component.bundle.map.entities.first.pos,
          const GridPos(x: 2, y: 2),
        );
      },
    );
  }
  test('off, wrong map and wrong entity never display balls or affect ordinary decoration', () async {
    RuntimeHealingDisplaySnapshot? snapshot;
    final component = MapLayersComponent(
      bundle: _bundle(),
      tileImagesByTilesetId: await _images(),
      healingDisplaySnapshotProvider: () => snapshot,
    );
    addTearDown(component.dispose);
    for (final value in [
      null,
      _active(3, mapId: 'other'),
      _active(3, entityId: 'missing'),
    ]) {
      snapshot = value;
      final image = await _render(component);
      expect(await pixelAt(image, 80, 72), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 208, 208), rgba(34, 170, 68, 255));
    }
  });
  test('native animation uses125ms frames and restarts for a new applying snapshot', () async {
    var snapshot = _active(1);
    final component = MapLayersComponent(
      bundle: _bundle(),
      tileImagesByTilesetId: await _images(),
      healingDisplaySnapshotProvider: () => snapshot,
    );
    addTearDown(component.dispose);
    expect(
      await pixelAt(await _render(component), 80, 72),
      rgba(30, 0, 85, 255),
    );
    component.update(.125);
    expect(
      await pixelAt(await _render(component), 80, 72),
      rgba(30, 50, 85, 255),
    );
    snapshot = _active(2);
    expect(
      await pixelAt(await _render(component), 80, 72),
      rgba(60, 0, 85, 255),
    );
  });
  test(
    'viewport sees the part of the64x48 visual outside its1x1 anchor',
    () async {
      final snapshot = _active(3);
      final component = MapLayersComponent(
        bundle: _bundle(),
        tileImagesByTilesetId: await _images(),
        healingDisplaySnapshotProvider: () => snapshot,
      );
      addTearDown(component.dispose);
      component.setVisibleLocalRect(const Rect.fromLTWH(48, 48, 8, 8));
      expect(
        await pixelAt(await _render(component), 52, 52),
        rgba(90, 0, 85, 255),
      );
    },
  );
  test(
    'display scales from native pixels without aspect fitting its anchor cell',
    () async {
      final snapshot = _active(4);
      final component = MapLayersComponent(
        bundle: _bundle(scale: 2),
        tileImagesByTilesetId: await _images(),
        healingDisplaySnapshotProvider: () => snapshot,
      );
      addTearDown(component.dispose);
      final image = await _render(component, size: 512);
      expect(await pixelAt(image, 96, 96), rgba(120, 0, 85, 255));
      expect(await pixelAt(image, 223, 191), rgba(120, 0, 85, 255));
      expect(await pixelAt(image, 224, 191), rgba(0, 0, 0, 0));
    },
  );
  test('foreground pass and native entity-presence refusal do not draw a duplicate', () async {
    final snapshot = _active(6);
    for (final foreground in [false, true]) {
      final component = MapLayersComponent(
        bundle: _bundle(),
        tileImagesByTilesetId: await _images(),
        renderPass: foreground
            ? MapLayerRenderPass.foreground
            : MapLayerRenderPass.background,
        mapEntityPresencePredicate: (_, entity) => entity.id != 'balls',
        healingDisplaySnapshotProvider: () => snapshot,
      );
      addTearDown(component.dispose);
      expect(await pixelAt(await _render(component), 80, 72), rgba(0, 0, 0, 0));
    }
  });
  test(
    'display preserves an existing canonical atlas animation timeline',
    () async {
      final base = _bundle();
      final first = base.manifest.tilesets.first;
      final animated = first.copyWith(
        source: const ProjectRegularAtlasTilesetSource(
          assetId: 'sheet-1',
          pixelWidth: 256,
          pixelHeight: 192,
          tileWidth: 64,
          tileHeight: 48,
          tileAnimations: [
            ProjectRegularAtlasTileAnimation(
              tileId: 4,
              frames: [
                ProjectImageCollectionAnimationFrame(
                  tileId: 4,
                  durationMs: 125,
                ),
                ProjectImageCollectionAnimationFrame(
                  tileId: 5,
                  durationMs: 125,
                ),
              ],
            ),
          ],
        ),
      );
      final element = base.manifest.elements.first.copyWith(
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 1)),
        ],
      );
      final bundle = base.copyWith(
        manifest: base.manifest.copyWith(
          tilesets: [animated, ...base.manifest.tilesets.skip(1)],
          elements: [element, ...base.manifest.elements.skip(1)],
        ),
      );
      final snapshot = _active(1);
      final component = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: await _images(),
        healingDisplaySnapshotProvider: () => snapshot,
      );
      addTearDown(component.dispose);
      expect(
        await pixelAt(await _render(component), 80, 72),
        rgba(30, 0, 85, 255),
      );
      component.update(.125);
      expect(
        await pixelAt(await _render(component), 80, 72),
        rgba(30, 50, 85, 255),
      );
    },
  );
}
