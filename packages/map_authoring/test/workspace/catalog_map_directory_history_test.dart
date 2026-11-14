import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/map_directory_fixture.dart';
import '../support/narrative_title_fixture.dart';

void main() {
  Future<({NarrativeTitleFixture fixture, String first, String second})> edit(
      {required bool directory}) async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    await fixture.prepare(null);
    if (directory) await fixture.prepare(CatalogMapDirectory.preparationScope);
    final first = await publishRenamedNpc(fixture, 1, 'Elm');
    final second = await publishRenamedNpc(fixture, 1, 'Oak');
    return (fixture: fixture, first: first, second: second);
  }

  Future<String?> npc(NarrativeTitleFixture fixture) async => switch (
          await CatalogMapDirectory.read(await fixture.snapshot(), ['map_1'])) {
        CatalogMapDirectoryPages(:final pages) =>
          pages.single.elements.first['name'] as String,
        CatalogMapDirectoryPreparationRequired() => null,
      };

  test('the directory follows map saves, undo, redo and reopening', () async {
    final (:fixture, :first, :second) = await edit(directory: true);
    expect(await npc(fixture), 'Oak');
    await fixture.undo(second, 'undo-second');
    expect(await npc(fixture), 'Elm');
    await fixture.undo(first, 'undo-first');
    expect(await npc(fixture), 'Professor');
    await fixture.redo(first, 'redo-first');
    await fixture.reattach();
    expect(await npc(fixture), 'Elm');
  });

  for (final directory in [false, true]) {
    test(
        'history maintenance ${directory ? 'reports' : 'prepares'} retained '
        'generations ${directory ? 'with' : 'without'} the map directory',
        () async {
      final (:fixture, :first, :second) = await edit(directory: directory);
      await fixture.undo(second, 'undo-second');
      await fixture.reattach();
      await fixture.prepare(null);
      final head = 'sha256:${(await fixture.snapshot()).root.sha256}';
      final preview = await fixture.api.maintainHistory(
          fixture.opened.projectHandle,
          expectedRevision: head,
          maxOperations: 1);
      final applied = await fixture.api.maintainHistory(
          fixture.opened.projectHandle,
          expectedRevision: head,
          maxOperations: 1,
          apply: true,
          expectedFingerprint: preview['fingerprint'] as String);
      expect(applied['historicalGenerationsRequiringPreparation'],
          directory ? isNotEmpty : isEmpty);
      final copy = await fixture.copy();
      addTearDown(copy.close);
      await copy.prepare(null);
      final redo = copy.redo(second, 'copy-redo');
      if (!directory) {
        await redo;
        return;
      }
      await expectLater(
          redo,
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.preparation_required')));
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
