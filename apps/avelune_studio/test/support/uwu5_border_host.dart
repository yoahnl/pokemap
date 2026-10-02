import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'uwu4_resource_host.dart';
import 'uwu_resource_host.dart';

Future<UwUResourceHost> openUwU5BorderHost(
  WidgetTester tester, {
  Size size = const Size(1536, 1024),
  double textScale = 1,
}) => openUwU4ResourceHost(
  tester,
  size: size,
  textScale: textScale,
  configure: (fixture) async {
    final tilesetId = (await fixture.maps.loadProject(
      fixture.session,
    )).tilesets.single.id;
    for (final (id, x) in [('cap', 0), ('straight', 1), ('corner', 2)]) {
      await fixture.resources.saveElement(
        fixture
            .element(tilesetId, id: id)
            .copyWith(
              frames: [
                TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0)),
              ],
            ),
      );
    }
    await fixture.resources.createBorder(
      const BorderCreationRequest(
        blueprintId: 'garden-fence',
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
  },
);
