import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_catalogue_host_fixture.dart';

void main() {
  testWidgets(
    'the canonical creation owner reveals and persists a new identity among existing maps',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      for (var i = 1; i <= 3; i++) {
        await f.createMap('Essai $i');
      }
      await f.createMap('Carte depuis l’accueil');
      final map = f.host.maps.project!.maps.singleWhere(
        (e) => e.name == 'Carte depuis l’accueil',
      );
      expect(f.host.maps.active!.base.mapId, map.id);
      expect((await f.reopen()).maps[map.id]!.name, 'Carte depuis l’accueil');
      expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    },
  );
}
