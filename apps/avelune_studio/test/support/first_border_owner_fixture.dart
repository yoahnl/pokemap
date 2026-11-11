import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';

import '../resource_io/resource_fixture.dart';

const firstBorderId = 'garden-fence';

Future<void> seedFirstBorderOverOpaqueGround(ResourceFixture fixture) async {
  final tilesetId = (await fixture.maps.loadProject(
    fixture.session,
  )).tilesets.single.id;
  for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
    await fixture.resources.saveElement(
      fixture
          .element(tilesetId, id: id)
          .copyWith(
            frames: [TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0))],
          ),
    );
  }
  await fixture.resources.createBorder(
    const BorderCreationRequest(
      blueprintId: firstBorderId,
      name: 'Clôture du jardin',
      capElementId: 'cap',
      straightElementId: 'straight',
      cornerElementId: 'corner',
    ),
  );
  await fixture.resources.createBorder(
    const BorderCreationRequest(
      blueprintId: 'unfinished-fence',
      name: 'Préparation des essais',
      publish: false,
    ),
  );
  final source = File('${fixture.root.path}/opaque-ground.png');
  final pixels = image.Image(width: 16, height: 24);
  image.fill(pixels, color: image.ColorRgb8(200, 60, 40));
  await source.writeAsBytes(image.encodePng(pixels));
  final imported = await fixture.resources.importImage(
    ResourceImageImport(
      sourcePath: source.path,
      name: 'Sol opaque',
      tileWidth: 16,
      tileHeight: 24,
    ),
  );
  final base = await fixture.loadMap();
  await fixture.maps.saveMap(
    fixture.session,
    base,
    base.map.copyWith(
      layers: [
        TileLayer(
          id: 'ground',
          name: 'Sol',
          cells: List.filled(16, 1),
          palette: [
            TileLayerPaletteEntry(
              tilesetId: imported.createdTilesetId!,
              localTileId: 0,
            ),
          ],
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision témoin',
          collisions: List.generate(16, (index) => index == 15),
        ),
      ],
    ),
  );
}
