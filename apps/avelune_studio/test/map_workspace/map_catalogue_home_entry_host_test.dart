import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/map_catalogue_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    'all maps uses the same creation owner and reveals the new identity',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      for (var i = 1; i <= 3; i++) {
        await f.createMap('Essai $i');
      }
      await tester.tap(find.text('Accueil'));
      await pumpIo(tester, frames: 20);
      await tester.tap(find.text('Voir toutes les cartes (5)'));
      await pumpIo(tester, frames: 12);
      await f.tapKey('home-all-new-map');
      await f.field('new-map-name', 'Carte depuis l’accueil');
      await tester.tap(find.text('Créer la carte'));
      await pumpIo(tester, frames: 30);
      final map = f.host.maps.project!.maps.singleWhere(
        (e) => e.name == 'Carte depuis l’accueil',
      );
      expect(f.host.maps.active!.base.mapId, map.id);
      expect((await f.reopen()).maps[map.id]!.name, 'Carte depuis l’accueil');
      expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    },
  );
}
