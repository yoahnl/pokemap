import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_catalogue_host_fixture.dart';

void main() {
  testWidgets('workspace duplicates the saved source into an independent map', (
    tester,
  ) async {
    final f = await MapCatalogueHostFixture.open(tester);
    final source = await f.createMap('Source des essais');
    await f.paintCollision();
    await f.saveActive();
    final before = await f.reopen();
    await f.duplicateMap(source.id, 'Copie indépendante');
    final after = await f.reopen();
    final copy = after.project.maps.singleWhere(
      (entry) => entry.name == 'Copie indépendante',
    );
    expect(copy.id, isNot(source.id));
    expect(copy.relativePath, isNot(source.relativePath));
    expect(f.host.maps.active!.base.mapId, copy.id);
    expect(
      after.maps[copy.id],
      before.maps[source.id]!.copyWith(id: copy.id, name: copy.name),
    );
    await f.paintCollision(
      cell: GridPos(
        x: before.maps[source.id]!.size.width ~/ 2 + 1,
        y: before.maps[source.id]!.size.height ~/ 2,
      ),
    );
    expect(f.host.maps.active!.dirty, isTrue);
    await f.saveActive();
    final independentlySaved = await f.reopen();
    expect(independentlySaved.maps[source.id], before.maps[source.id]);
    expect(independentlySaved.maps[copy.id], isNot(after.maps[copy.id]));
    expect(independentlySaved.project.newGame, before.project.newGame);
  });

  testWidgets(
    'workspace analyzes growth without writing then reloads new bounds',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final entry = await f.createMap('Carte à agrandir');
      final before = await f.reopen();
      final source = before.maps[entry.id]!;
      final preparation = (await f.prepareResize(
        entry.id,
        GridSize(width: source.size.width + 4, height: source.size.height + 3),
      ))!;
      expect(preparation.canApply, isTrue);
      expect((await f.reopen()).maps[entry.id], source);
      expect((await f.apply(preparation)).integrated, isTrue);
      final after = await f.reopen();
      final targetSize = GridSize(
        width: source.size.width + 4,
        height: source.size.height + 3,
      );
      expect(after.maps[entry.id]!.size, targetSize);
      expect(f.host.maps.active!.current.size, targetSize);
      expect(f.host.maps.active!.dirty, isFalse);
      expect(f.host.maps.project!.settings, before.project.settings);
      expect(
        tester
            .widget<MapEditingViewport2D>(find.byType(MapEditingViewport2D))
            .document
            .current
            .size,
        targetSize,
      );
      f.host.maps.restore(redo: false);
      expect(f.host.maps.active!.current.size, targetSize);
    },
  );

  testWidgets(
    'workspace deletes only the confirmed map and retires its owner',
    (tester) async {
      final f = await MapCatalogueHostFixture.open(tester);
      final entry = await f.createMap('Carte indépendante');
      final removedOwner = f.host.maps.active!;
      final before = await f.reopen();
      final preparation = (await f.prepareDeletion(entry.id))!;
      expect(preparation.canApply, isTrue);
      expect((await f.reopen()).project, before.project);
      expect(
        (await f.apply(preparation, confirmDestructive: true)).integrated,
        isTrue,
      );
      final after = await f.reopen();
      expect(after.project.maps.any((map) => map.id == entry.id), isFalse);
      expect(after.maps.containsKey(entry.id), isFalse);
      expect(f.host.maps.active?.base.mapId, isNot(entry.id));
      expect(f.host.maps.documents.containsKey(entry.id), isFalse);
      for (final original in before.project.maps.where(
        (map) => map.id != entry.id,
      )) {
        expect(after.maps[original.id], before.maps[original.id]);
      }
      expect(after.project.newGame, before.project.newGame);
      expect(await f.host.maps.save(removedOwner), isFalse);
      expect((await f.reopen()).project, after.project);
      await f.preserveNativeFixture();
    },
  );
}
