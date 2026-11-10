import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_catalogue_host_fixture.dart';

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets(
      'native lifecycle preparation is read only with viewport $size',
      (tester) async {
        final f = await MapCatalogueHostFixture.open(tester, size: size);
        final before = await f.reopen();
        final duplicate = (await f.prepareDuplicate('first-map'))!;
        expect(duplicate.canApply, isTrue);
        expect((await f.reopen()).project, before.project);
        final resize = (await f.prepareResize(
          'first-map',
          const GridSize(width: 2, height: 2),
        ))!;
        expect(resize.canApply, isFalse);
        expect(resize.issues, isNotEmpty);
        final deletion = (await f.prepareDeletion('first-map'))!;
        expect(deletion.canApply, isFalse);
        expect(deletion.issues, isNotEmpty);
        final after = await f.reopen();
        expect(after.project, before.project);
        expect(after.maps, before.maps);
        expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'dirty source cancellation keeps its owner and does not duplicate',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final source = await f.createMap('Source non enregistrée');
      await f.paintCollision();
      final owner = f.host.maps.active!;
      final draft = owner.current;
      final before = await f.reopen();
      expect(await f.prepareDuplicate(source.id, confirmSave: false), isNull);
      expect(f.host.maps.active, same(owner));
      expect(owner.current, draft);
      expect(owner.dirty, isTrue);
      final after = await f.reopen();
      expect(after.project, before.project);
      expect(after.maps, before.maps);
    },
  );
}
