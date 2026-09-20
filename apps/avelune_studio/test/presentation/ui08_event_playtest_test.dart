import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/event_playtest_harness.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'published event opens runtime using revalidated map and returns',
    (tester) async {
      final h = (await tester.runAsync(EventPlaytestHarness.create))!;
      addTearDown(h.dispose);
      await tester.pumpWidget(h.app());
      await tester.runAsync(() async {
        h.running = h.launch();
        await h.port.finished.future.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(h.launches, 1);
      await tester.tap(find.text('Fermer ${h.maps.active!.current.id}'));
      await tester.pumpAndSettle();
      expect(await tester.runAsync(() => h.running!), isNull);
      expect(find.text('Événements'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'pending event input is flushed and dirty record blocks launch before disk reads',
    (tester) async {
      final h = (await tester.runAsync(EventPlaytestHarness.create))!;
      addTearDown(h.dispose);
      await tester.pumpWidget(h.app());
      await tester.runAsync(h.events.prepare);
      final readsBefore = h.port.reads;
      h.events.flushEdits = () async {
        await h.events.prepare();
        h.events.rename(Ui06SceneFixture.eventId, 'Saisie encore focalisée');
      };
      final result = await tester.runAsync(h.launch);
      expect(result, contains('Enregistrez les événements'));
      expect(h.port.reads, readsBefore);
      expect(h.launches, 0);
      expect(h.events.dirty, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final draft in [false, true]) {
    testWidgets(
      'published ${draft ? 'draft' : 'disabled event'} refuses runtime launch',
      (tester) async {
        final h = (await tester.runAsync(EventPlaytestHarness.create))!;
        addTearDown(h.dispose);
        await tester.runAsync(() async {
          await h.events.prepare();
          if (draft) {
            expect(h.events.unconfigure(Ui06SceneFixture.eventId), isTrue);
          } else {
            expect(
              h.events.setEnabled(Ui06SceneFixture.eventId, false),
              isTrue,
            );
          }
          expect(await h.events.save(), isTrue);
        });
        await tester.pumpWidget(h.app());
        expect(
          await tester.runAsync(h.launch),
          contains('Configurez et activez'),
        );
        expect(h.launches, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final change in ['selection', 'record', 'map', 'project']) {
    testWidgets('launch refuses $change changing during asynchronous read', (
      tester,
    ) async {
      final h = (await tester.runAsync(EventPlaytestHarness.create))!;
      addTearDown(h.dispose);
      await tester.runAsync(h.events.prepare);
      await tester.pumpWidget(h.app());
      h.port.delay = true;
      final result = await tester.runAsync(() async {
        final running = h.launch();
        await h.port.entered.future.timeout(const Duration(seconds: 5));
        switch (change) {
          case 'selection':
            h.events.activeId = 'other';
          case 'record':
            h.events.rename(Ui06SceneFixture.eventId, 'Pendant la lecture');
          case 'map':
            h.maps.active!.commit(
              h.maps.active!.current.copyWith(name: 'Carte modifiée'),
            );
          case 'project':
            h.maps.project = h.maps.project!.copyWith(name: 'Autre contexte');
        }
        h.port.release.complete();
        return running.timeout(const Duration(seconds: 5));
      });
      expect(result, isNotNull);
      expect(h.launches, 0);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'flush failure blocks close and both playtest routes without rejected UI futures',
    (tester) async {
      final h = (await tester.runAsync(EventPlaytestHarness.create))!;
      addTearDown(h.dispose);
      await tester.pumpWidget(h.app());
      h.events.flushEdits = () async {
        throw StateError('Condition refusée');
      };
      final actions = h.actions();
      expect(await tester.runAsync(actions.allowClose), isFalse);
      expect(h.events.error, contains('Condition refusée'));
      await tester.runAsync(actions.test);
      expect(h.maps.error, contains('Condition refusée'));
      expect(await tester.runAsync(h.launch), contains('Condition refusée'));
      expect(h.launches, 0);
      expect(h.changed, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
