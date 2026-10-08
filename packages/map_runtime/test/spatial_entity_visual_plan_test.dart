import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/src/spatial/spatial_entity_visual_plan.dart';

const pickup = MapEntity(
  id: 'pickup',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 3),
  editorVisual: MapEntityEditorVisual(elementId: 'item-ball'),
);

ProjectManifest project({List<ProjectElementEntry>? elements}) =>
    ProjectManifest(
      name: 'Native props',
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        tileWidth: 32,
        tileHeight: 24,
      ),
      maps: const [],
      tilesets: const [],
      elements: elements ??
          const [
            ProjectElementEntry(
              id: 'item-ball',
              name: 'Item ball',
              tilesetId: 'items',
              categoryId: 'props',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 1),
                  durationMs: 50,
                ),
                TilesetVisualFrame(
                  tilesetId: 'other-items',
                  source: TilesetSourceRect(x: 0, y: 0, width: 2),
                  durationMs: 100,
                ),
              ],
            ),
          ],
    );

MapData map({List<MapEntity> entities = const [pickup]}) => MapData(
      id: 'forest',
      name: 'Forest',
      size: const GridSize(width: 8, height: 8),
      entities: entities,
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        heightLevels: List.filled(64, 2),
        levelHeight: .5,
      ),
    );

Future<ui.Image> image(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xffffffff),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('canonical custom visuals resolve texture cells and authored timing',
      () async {
    final plan = SpatialEntityVisualPlan(map(), project());
    expect(plan.imageIds, {'items', 'other-items'});
    final images = {
      'items': await image(64, 48),
      'other-items': await image(64, 24),
    };
    addTearDown(() {
      for (final value in images.values) {
        value.dispose();
      }
    });
    plan.validateImages(images);
    final textures = {
      for (final entry in images.entries)
        entry.key: await SpatialActorTexture.fromImage(entry.value),
    };
    final first =
        plan.frames(textures: textures, elapsedMs: 0)['entity:pickup']!;
    expect(first.frame, const ui.Rect.fromLTWH(32, 24, 32, 24));
    expect(first.texture, same(textures['items']));
    expect(first.x, 2.5);
    expect(first.z, 3.5);
    expect(first.y, 1);
    expect(first.width, 1);
    expect(first.height, .75);
    final second =
        plan.frames(textures: textures, elapsedMs: 50)['entity:pickup']!;
    expect(second.frame, const ui.Rect.fromLTWH(0, 0, 64, 24));
    expect(second.texture, same(textures['other-items']));
    expect(second.width, 1);
    expect(second.height, .375);
    expect(
      plan.frames(textures: textures, elapsedMs: 150)['entity:pickup']!.frame,
      first.frame,
    );
  });

  test('entity size bounds the billboard while keeping the source aspect',
      () async {
    final plan = SpatialEntityVisualPlan(
      map(entities: [
        pickup.copyWith(size: const GridSize(width: 2, height: 3))
      ]),
      project(),
    );
    final source = await image(64, 48);
    addTearDown(source.dispose);
    final textures = {'items': await SpatialActorTexture.fromImage(source)};
    final frame =
        plan.frames(textures: textures, elapsedMs: 0)['entity:pickup']!;
    expect(frame.x, 3);
    expect(frame.z, 4.5);
    expect(frame.width, 2);
    expect(frame.height, 1.5);
    expect(frame.width! / frame.height, closeTo(32 / 24, .000001));
  });

  test('presence changes hide a custom prop without changing source map data',
      () async {
    final plan = SpatialEntityVisualPlan(map(), project());
    final source = await image(64, 48);
    addTearDown(source.dispose);
    final textures = {'items': await SpatialActorTexture.fromImage(source)};
    var visible = true;
    Map<String, SpatialActorVisual> frames() => plan.frames(
          textures: textures,
          elapsedMs: 0,
          isPresent: (entity) => visible,
        );
    expect(frames().keys, ['entity:pickup']);
    visible = false;
    expect(frames(), isEmpty);
    visible = true;
    expect(frames().keys, ['entity:pickup']);
    expect(plan.map.entities.single, pickup);
  });

  test('missing canonical elements and invalid texture rectangles fail closed',
      () async {
    expect(
      () => SpatialEntityVisualPlan(map(), project(elements: [])),
      throwsStateError,
    );
    final plan = SpatialEntityVisualPlan(map(), project());
    expect(() => plan.validateImages({}), throwsStateError);
    final source = await image(32, 24);
    addTearDown(source.dispose);
    expect(
      () => plan.validateImages({'items': source, 'other-items': source}),
      throwsStateError,
    );
    expect(
      () => plan.frames(textures: const {}, elapsedMs: 0),
      throwsStateError,
    );
  });

  test('duration defaults follow runtime element animation timing', () async {
    final manifest = project();
    final element = manifest.elements.single;
    final plan = SpatialEntityVisualPlan(
      map(),
      project(elements: [
        element.copyWith(frames: [
          element.frames.first.copyWith(durationMs: null),
          element.frames.last.copyWith(durationMs: 0),
        ]),
      ]),
    );
    final source = await image(64, 48);
    addTearDown(source.dispose);
    final texture = await SpatialActorTexture.fromImage(source);
    final textures = {'items': texture, 'other-items': texture};
    expect(
      plan.frames(textures: textures, elapsedMs: 199)['entity:pickup']!.frame,
      const ui.Rect.fromLTWH(32, 24, 32, 24),
    );
    expect(
      plan.frames(textures: textures, elapsedMs: 200)['entity:pickup']!.frame,
      const ui.Rect.fromLTWH(0, 0, 64, 24),
    );
    expect(
      () => plan.frames(textures: textures, elapsedMs: -1),
      throwsArgumentError,
    );
  });

  test('NPC character visuals retain precedence over a prop element', () {
    final npc = pickup.copyWith(
      kind: MapEntityKind.npc,
      npc: const MapEntityNpcData(characterId: 'guide'),
    );
    final plan = SpatialEntityVisualPlan(map(entities: [npc]), project());
    expect(plan.imageIds, isEmpty);
    expect(plan.frames(textures: const {}, elapsedMs: 0), isEmpty);
  });

  test('hero billboard dimensions preserve the existing 1.92 rendering',
      () async {
    final source = await image(32, 48);
    addTearDown(source.dispose);
    final visual = SpatialActorVisual(
      x: 0,
      y: 0,
      z: 0,
      texture: await SpatialActorTexture.fromImage(source),
      frame: const ui.Rect.fromLTWH(0, 0, 32, 48),
    );
    expect(visual.height, 1.92);
    expect(visual.resolvedWidth, closeTo(1.28, .000001));
  });

  test('tileset color keys reach prop textures without disposing source images',
      () async {
    final manifest = project().copyWith(tilesets: [
      ProjectTilesetEntry(
        id: 'items',
        name: 'Items',
        relativePath: 'items.png',
        transparentColor:
            TilesetTransparentColor(red: 255, green: 255, blue: 255),
      ),
    ]);
    final plan = SpatialEntityVisualPlan(map(), manifest);
    final source = await image(64, 48);
    addTearDown(source.dispose);
    final masked = await plan.createTexture('items', source);
    expect(masked.texture.sourceData.getUint8(3), 0);
    final unchanged = await plan.createTexture('other-items', source);
    expect(unchanged.texture.sourceData.getUint8(3), 255);
    expect((await source.toByteData())!.getUint8(3), 255);
  });
}
