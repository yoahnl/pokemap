import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/event_backend_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'library performs no map scan, explicit preparation caches unchanged catalogue',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      final maps = WorkspaceMemoryPort();
      final workspace = MapWorkspaceController(workspaceSession, maps);
      await workspace.initialize();
      final narrative = NarrativeWorkspaceController(
        workspace,
        fixture.narrative.port,
        () {},
        (_, _) async {},
      );
      final controller = EventWorkspaceController(
        narrative,
        fixture.port,
        changed: () {},
      );
      addTearDown(() {
        controller.dispose();
        narrative.dispose();
        workspace.dispose();
      });
      expect(maps.reads, 1);
      expect(controller.records, isEmpty);
      expect(maps.reads, 1);
      expect(await controller.prepare(), isTrue);
      expect(maps.reads, 2);
      final catalog = controller.catalog;
      for (var index = 0; index < 30; index++) {
        expect(identical(controller.catalog, catalog), isTrue);
      }
      expect(await controller.prepare(), isTrue);
      expect(maps.reads, 2);
      final event = controller.create('Brouillon')!;
      expect(identical(controller.catalog, catalog), isFalse);
      expect(controller.open(event.id), isTrue);
      expect(maps.reads, 2);
    },
  );

  test('event consumed dependency blocks deleting its target', () async {
    final f = await EventBackendFixture.create();
    addTearDown(f.dispose);
    final c = f.attach();
    await c.prepare();
    final consumer = c.create(
      'Après la rencontre',
      source: c.record(Ui06SceneFixture.eventId)!.definitionOrNull!.source,
    )!;
    expect(c.setScene(consumer.id, Ui06SceneFixture.sceneId), isTrue);
    expect(c.setReuse(consumer.id, NarrativeEventReusePolicy.reusable), isTrue);
    expect(
      c.setExpression(
        consumer.id,
        NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.narrativeEventConsumed(
            Ui06SceneFixture.eventId,
            true,
          ),
        ),
      ),
      isTrue,
    );
    expect(c.configure(consumer.id), isTrue);
    expect(c.delete(Ui06SceneFixture.eventId), isFalse);
    expect(c.error, contains('encore utilisé'));
    expect(c.record(Ui06SceneFixture.eventId), isNotNull);
  });
}
