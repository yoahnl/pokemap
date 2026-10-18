import 'dart:convert';
import 'dart:io';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;
import 'ui07_story_fixture.dart';

Future<void> seedUi10Visuals(
  Ui07StoryFixture fixture, {
  int tileSize = 32,
}) async {
  final repo = Directory.current.parent.parent.path;
  final root = fixture.directory.path;
  final assets = <String, List<int>>{
    'grass': _syntheticAtlas(192, 128, 11),
    'path': _syntheticAtlas(128, 96, 37),
    'forest': _syntheticAtlas(256, 384, 83),
    'actor': await File(
      '$repo/packages/map_editor/test/fixtures/cinematics/actor_sprite_test_sheet.png',
    ).readAsBytes(),
  };
  for (final entry in assets.entries) {
    await File('$root/assets/ui10_${entry.key}.png').writeAsBytes(entry.value);
  }
  var manifest = await fixture.readFresh();
  final frames = 64 ~/ tileSize;
  manifest = manifest.copyWith(
    version: ProjectVersion.v8,
    settings: ProjectSettings(
      tileWidth: tileSize,
      tileHeight: tileSize,
      displayScale: 1,
      defaultPlayerCharacterId: 'guide',
    ),
    tilesets: [
      ...manifest.tilesets,
      for (final id in assets.keys)
        ProjectTilesetEntry(
          id: id,
          name: 'UI10 · $id',
          relativePath: 'assets/ui10_$id.png',
          transparentColor: id == 'actor'
              ? TilesetTransparentColor.fromHexRgb('ff00ff')
              : null,
        ),
    ],
    characters: [
      ProjectCharacterEntry(
        id: 'guide',
        name: 'Voyageur du jardin',
        tilesetId: 'actor',
        frameWidth: frames,
        frameHeight: frames,
        animations: [
          for (final state in [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
            CharacterAnimationState.run,
          ])
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: state,
                direction: direction,
                frames: [
                  for (
                    var index = 0;
                    index < (state == CharacterAnimationState.idle ? 1 : 4);
                    index++
                  )
                    CharacterAnimationFrame(
                      source: TilesetSourceRect(
                        x: index,
                        y: switch (direction) {
                          EntityFacing.south => 0,
                          EntityFacing.west => 1,
                          EntityFacing.east => 2,
                          EntityFacing.north => 3,
                        },
                        width: frames,
                        height: frames,
                      ),
                    ),
                ],
              ),
        ],
      ),
    ],
    elements: [
      ...manifest.elements,
      ProjectElementEntry(
        id: 'pine',
        categoryId: 'atelier',
        name: 'Bloc vertical synthétique',
        tilesetId: 'forest',
        frames: [
          TilesetVisualFrame(
            tilesetId: 'forest',
            source: TilesetSourceRect(
              x: 0,
              y: 0,
              width: 160 ~/ tileSize,
              height: 256 ~/ tileSize,
            ),
          ),
        ],
      ),
      ProjectElementEntry(
        id: 'bench',
        categoryId: 'atelier',
        name: 'Bloc horizontal synthétique',
        tilesetId: 'forest',
        frames: [
          TilesetVisualFrame(
            tilesetId: 'forest',
            source: TilesetSourceRect(
              x: 160 ~/ tileSize,
              y: 320 ~/ tileSize,
              width: 96 ~/ tileSize,
              height: 64 ~/ tileSize,
            ),
          ),
        ],
      ),
    ],
  );
  await File('$root/project.json').writeAsString(jsonEncode(manifest.toJson()));
  await fixture.maps.loadProject(fixture.session);
  for (final entry in manifest.maps) {
    final base = await fixture.maps.loadMap(fixture.session, entry);
    final map = base.map.copyWith(
      visualStack: MapVisualStackConfig.canonicalV1,
      tilesetId: 'grass',
      layers: [
        TileLayer(
          id: 'ground',
          name: 'Sol',
          palette: [
            for (var i = 0; i < 24; i++)
              TileLayerPaletteEntry(tilesetId: 'grass', localTileId: i),
            TileLayerPaletteEntry(
              tilesetId: 'path',
              localTileId: tileSize == 32 ? 6 : 22,
            ),
          ],
          cells: [
            for (var y = 0; y < 16; y++)
              for (var x = 0; x < 24; x++)
                y >= 8 && y <= 10 || x >= 12 && x <= 14
                    ? 25
                    : (x + y * 5) % 24 + 1,
          ],
        ),
        TileLayer(id: 'decor', name: 'Décors', cells: List.filled(24 * 16, 0)),
      ],
      placedElements: [
        for (final pos
            in tileSize == 16
                ? const [GridPos(x: 0, y: 0), GridPos(x: 14, y: 0)]
                : const [
                    GridPos(x: 1, y: 0),
                    GridPos(x: 6, y: 0),
                    GridPos(x: 17, y: 0),
                    GridPos(x: 18, y: 6),
                    GridPos(x: 2, y: 7),
                  ])
          MapPlacedElement(
            id: 'tree_${pos.x}_${pos.y}',
            elementId: 'pine',
            layerId: 'decor',
            pos: pos,
          ),
        const MapPlacedElement(
          id: 'bench',
          elementId: 'bench',
          layerId: 'decor',
          pos: GridPos(x: 16, y: 11),
        ),
      ],
      entities: [
        for (final entity in base.map.entities)
          entity.id == 'chief'
              ? entity.copyWith(pos: const GridPos(x: 13, y: 7))
              : entity,
      ],
    );
    MapValidator.validate(map, projectDialogueContext: manifest);
    await fixture.maps.saveMap(fixture.session, base, map);
  }
}

List<int> _syntheticAtlas(int width, int height, int seed) {
  final pixels = image.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      pixels.setPixelRgba(x, y, (x * 3 + seed) % 256,
          (y * 5 + seed) % 256, ((x ~/ 16 + y ~/ 16) * 29 + seed) % 256, 255);
    }
  }
  return image.encodePng(pixels);
}
