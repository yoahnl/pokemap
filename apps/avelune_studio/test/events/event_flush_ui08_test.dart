import 'dart:async';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'registry mode flushes pending text and refuses dirty record without writing',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      final before = await fixture.readFresh();
      final entered = Completer<void>();
      final release = Completer<void>();
      controller.flushEdits = () async {
        entered.complete();
        await release.future;
        await controller.prepare();
        controller.rename(Ui06SceneFixture.eventId, 'Nom focalisé');
      };
      final changing = controller.changeMode(EventSystemMode.dualRead);
      await entered.future;
      expect(controller.dirty, isFalse);
      release.complete();
      expect(await changing, isFalse);
      expect(controller.record(Ui06SceneFixture.eventId)!.name, 'Nom focalisé');
      expect(controller.error, contains('brouillons'));
      expect(controller.dirty, isTrue);
      expect(await fixture.readFresh(), before);
    },
  );

  test(
    'saveAll awaits focused edit before capturing publication snapshot',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      final entered = Completer<void>();
      final release = Completer<void>();
      controller.flushEdits = () async {
        entered.complete();
        await release.future;
        expect(await controller.prepare(), isTrue);
        expect(
          controller.rename(
            Ui06SceneFixture.eventId,
            'Nom encore dans le champ',
          ),
          isTrue,
        );
      };
      expect(controller.dirty, isFalse);
      final save = controller.saveAll();
      await entered.future;
      expect(controller.dirty, isFalse);
      release.complete();
      expect(await save, isTrue, reason: controller.error);
      expect(
        (await fixture.readFresh()).eventRegistry!.records.single.name,
        'Nom encore dans le champ',
      );
      expect(controller.dirty, isFalse);
    },
  );

  test('close while flushing never publishes pending text', () async {
    final fixture = await EventBackendFixture.create();
    addTearDown(fixture.dispose);
    final controller = fixture.attach();
    await controller.prepare();
    final before = await fixture.readFresh();
    final entered = Completer<void>();
    final release = Completer<void>();
    controller.flushEdits = () async {
      entered.complete();
      await release.future;
      controller.rename(Ui06SceneFixture.eventId, 'Après fermeture');
    };
    final save = controller.save();
    await entered.future;
    controller.dispose();
    release.complete();
    expect(await save, isFalse);
    expect(await fixture.readFresh(), before);
  });

  test(
    'failed focused edit flush reports error without publishing other drafts',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      await controller.prepare();
      controller.rename(Ui06SceneFixture.eventId, 'Brouillon à conserver');
      final before = await fixture.readFresh();
      controller.flushEdits = () async {
        throw StateError('Champ refusé');
      };
      expect(await controller.saveAll(), isFalse);
      expect(controller.error, contains('Champ refusé'));
      expect(controller.dirty, isTrue);
      expect(await fixture.readFresh(), before);
    },
  );
}
