import 'package:flutter_test/flutter_test.dart';
import '../support/uwu5_character_host.dart';
import '../support/m2_ui_fixture.dart';

void main() {
  testWidgets('replacement preserves unrelated undo and rejects deleted NPC', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester, referenced: true);
    final controller = host.fixture.controller;
    final document = controller.active!;
    final initial = document.current;
    document.commit(initial.copyWith(properties: {'ordinary': 'kept'}));
    final snapshot = document.current;
    final revision = (await WidgetResourcePort.serial(
      tester,
      () => host.fixture.port.saveMap(
        host.fixture.session,
        document.base,
        snapshot,
      ),
    ))!;
    document.acceptSave(snapshot, revision);
    final undoCount = document.undoCount;
    await host.tap('character-studio-remove');
    await host.choose(
      'character-removal-resolution',
      'Remplacer par un autre personnage',
    );
    await host.choose('character-removal-replacement', 'Remplaçant');
    await host.tap('character-removal-confirm');
    await host.tap('resource-management-save');
    expect(document.undoCount, undoCount);
    expect(document.dirty, false);
    final reopened = (await WidgetResourcePort.serial(
      tester,
      () => host.fixture.port.loadMap(
        host.fixture.session,
        controller.project!.maps.single,
      ),
    ))!;
    expect(document.base.revision, reopened.revision);
    controller.restore(redo: false);
    expect(document.current.properties, initial.properties);
    expect(document.current.entities.single.npc!.characterId, 'remplacant');
    controller.restore(redo: true);
    expect(document.current.properties['ordinary'], 'kept');
    expect(document.current.entities.single.npc!.characterId, 'remplacant');
    document.commit(document.current.copyWith(entities: []));
    controller.restore(redo: false);
    expect(document.current.entities.single.npc!.characterId, 'remplacant');
    final updated = document.current;
    document.commit(updated.copyWith(entities: initial.entities));
    document.commit(updated);
    final retained = document.undoCount;
    controller.restore(redo: false);
    expect(document.current, updated);
    expect(document.undoCount, retained);
    expect(document.error, contains('personnage supprimé'));
    expect(tester.takeException(), isNull);
  });
}
