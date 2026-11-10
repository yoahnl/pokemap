import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/map_catalogue_host_fixture.dart';
import '../support/real_test_io.dart';

void main() {
  testWidgets(
    'folder creation and bulk map moves preserve raw maps after independent reopening',
    (tester) async {
      final fixture = await MapCatalogueHostFixture.open(tester);
      final original = await fixture.reopen();
      final rootPath = fixture.host.session.state.project!.directoryPath;
      final beforeBytes = (await RealTestIo.run(
        tester,
        () async => {
          for (final entry in original.project.maps)
            entry.id: await File('$rootPath/${entry.relativePath}')
                .readAsBytes(),
        },
      ))!;
      final gardens = await fixture.createFolder('Jardins');
      final park = await fixture.createFolder('Parc', parentId: gardens.id);
      expect(
        await fixture.organize(
          assignments: [
            for (final entry in original.project.maps)
              {'mapId': entry.id, 'groupId': park.id},
          ],
        ),
        isNull,
      );
      final reopened = await fixture.reopen();
      expect(
        reopened.project.groups
            .singleWhere((group) => group.id == park.id)
            .parentGroupId,
        gardens.id,
      );
      expect(
        reopened.project.maps.every((map) => map.groupId == park.id),
        isTrue,
      );
      expect(
        reopened.project.maps.map((map) => (map.id, map.relativePath)),
        original.project.maps.map((map) => (map.id, map.relativePath)),
      );
      expect(reopened.maps, original.maps);
      expect(reopened.project.newGame, original.project.newGame);
      for (final entry in original.project.maps) {
        expect(
          await RealTestIo.run(
            tester,
            () => File('$rootPath/${entry.relativePath}').readAsBytes(),
          ),
          beforeBytes[entry.id],
        );
      }
    },
  );
}
