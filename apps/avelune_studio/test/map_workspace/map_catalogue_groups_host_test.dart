import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_catalogue_host_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';

void main() {
  testWidgets('native preview refreshes after a closed map title changes', (
    tester,
  ) async {
    final f = await MapCatalogueHostFixture.open(tester);
    expect(f.host.maps.documents.containsKey('annex'), isFalse);
    final before = await tester.runAsync(() => f.host.maps.previewMap('annex'));
    expect(before, isNotNull);
    expect(await f.renameMap('annex', 'Maison des saules'), isNull);
    final after = await tester.runAsync(() => f.host.maps.previewMap('annex'));
    expect(after!.name, 'Maison des saules');
    expect(f.host.maps.documents.containsKey('annex'), isFalse);
  });
  testWidgets(
    'real workspace organizes nested folders and preserves referenced maps',
    (tester) async {
      await tester.runAsync(loadDesktopCaptureFonts);
      final key = GlobalKey();
      final f = await MapCatalogueHostFixture.open(tester, captureKey: key);
      final before = await f.reopen();
      final active = f.host.maps.active!;
      final root = await f.createFolder('Région');
      final town = await f.createFolder('Village', parentId: root.id);
      final houses = await f.createFolder('Intérieurs', parentId: town.id);
      expect(houses.parentGroupId, town.id);
      expect(await f.moveMap('annex', houses.id), isNull);
      expect(f.host.maps.active, same(active));
      expect(
        f.host.maps.project!.maps.singleWhere((e) => e.id == 'annex').groupId,
        houses.id,
      );
      expect(await f.updateFolder(houses.copyWith(name: 'Maisons')), isNull);
      expect(
        f.host.maps.project!.groups.singleWhere((g) => g.id == houses.id).name,
        'Maisons',
      );
      expect(await f.deleteFolder(root.id), isNotNull);
      final renamedHouses = f.host.maps.project!.groups.singleWhere(
        (group) => group.id == houses.id,
      );
      expect(
        await f.updateFolder(renamedHouses.copyWith(parentGroupId: null)),
        isNull,
      );
      final empty = await f.createFolder('Dossier provisoire');
      expect(await f.deleteFolder(empty.id), isNull);
      expect(
        f.host.maps.project!.groups.any((group) => group.id == empty.id),
        isFalse,
      );
      final after = await f.reopen();
      expect(
        after.project.groups
            .singleWhere((g) => g.id == houses.id)
            .parentGroupId,
        isNull,
      );
      expect(after.maps, before.maps);
      expect(after.project.newGame, before.project.newGame);
      expect(after.project.elements, before.project.elements);
      await captureM3Widget(tester, key, 'uwu-folders-organized');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dirty rename saves only its target and cancellation preserves work',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final before = await f.reopen();
      final active = f.host.maps.active!;
      await f.paintCollision();
      final draft = active.current;
      expect(
        await f.renameMap(
          active.base.mapId,
          'Synthetic — orchard',
          confirmSave: false,
        ),
        isNotNull,
      );
      expect(active.current, draft);
      expect(active.dirty, isTrue);
      expect((await f.reopen()).maps, before.maps);
      expect(
        await f.renameMap(active.base.mapId, 'Synthetic — orchard'),
        isNull,
      );
      expect(active.dirty, isFalse);
      final after = await f.reopen();
      expect(
        after.maps[active.base.mapId],
        draft.copyWith(name: 'Synthetic — orchard'),
      );
      expect(after.maps['annex'], before.maps['annex']);
      expect(after.project.newGame, before.project.newGame);
    },
  );
}
