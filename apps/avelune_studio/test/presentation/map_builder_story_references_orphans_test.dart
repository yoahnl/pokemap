import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_references_orphans_harness.dart';

void main() {
  testWidgets('a map whose behaviours all have their element shows no repair', (
    tester,
  ) async {
    await open(tester, [orphanMeeting, orphanElsewhere]);

    expect(story.orphans, isEmpty);
    expect(key('map-story-repair'), findsNothing);
    expect(find.text('À réparer'), findsNothing);
  });

  testWidgets('behaviours whose element left the map are listed to repair', (
    tester,
  ) async {
    await open(tester, [
      orphanMeeting,
      orphanGhost,
      orphanLostZone,
      orphanElsewhere,
    ]);

    expect(find.text('À réparer'), findsOneWidget);
    expect(orphan(orphanGhost), findsOneWidget);
    expect(orphan(orphanLostZone), findsOneWidget);
    expect(orphan(orphanMeeting), findsNothing);
    expect(orphan(orphanElsewhere), findsNothing);
    expect(find.text('ghost'), findsOneWidget);
    expect(find.text('lost zone'), findsOneWidget);
    expect(
      find.text('Son élément n’existe plus sur cette carte.'),
      findsNWidgets(2),
    );
    expect(find.text('Réattribuer'), findsNWidgets(2));
    expect(find.text('Supprimer'), findsNWidgets(2));
  });

  testWidgets('reassigning an orphan rewrites its source in the draft', (
    tester,
  ) async {
    await open(tester, [orphanMeeting, orphanGhost]);

    final select = tester.widget<StudioSelect>(
      key('map-story-orphan-reassign-${orphanGhost.id}'),
    );
    expect(select.options.keys, [
      'entity:luth',
      'entity:board',
      'trigger:departure',
    ]);
    select.onChanged!('entity:board');
    await tester.pump();

    expect(story.repairError, isNull);
    expect(
      draft(orphanGhost)!.source,
      NarrativeEventSourceRef.entityInteract('a', 'board'),
    );
    expect(
      story.elements!.byKey('entity:board')!.behaviours.single.id,
      orphanGhost.id,
    );
    expect(key('map-story-repair'), findsNothing);
    expect(story.dirty, isTrue);
    expect(
      saved(orphanGhost).source,
      NarrativeEventSourceRef.entityInteract('a', 'gone'),
    );

    story.undo();
    await tester.pump();
    expect(
      draft(orphanGhost)!.source,
      NarrativeEventSourceRef.entityInteract('a', 'gone'),
    );
    expect(orphan(orphanGhost), findsOneWidget);
    expect(story.dirty, isFalse);

    story.redo();
    await tester.pump();
    expect(orphan(orphanGhost), findsNothing);
    expect(story.dirty, isTrue);
  });

  testWidgets('an orphan reassigned to a zone triggers when entering it', (
    tester,
  ) async {
    await open(tester, [orphanGhost]);

    tester
        .widget<StudioSelect>(
          key('map-story-orphan-reassign-${orphanGhost.id}'),
        )
        .onChanged!('trigger:departure');
    await tester.pump();

    expect(story.repairError, isNull);
    expect(
      draft(orphanGhost)!.source,
      NarrativeEventSourceRef.triggerEnter('a', 'departure'),
    );
    expect(key('map-story-repair'), findsNothing);
  });

  testWidgets('deleting an orphan removes it from the draft', (tester) async {
    await open(tester, [orphanMeeting, orphanGhost, orphanLostZone]);

    await tester.tap(key('map-story-orphan-delete-${orphanLostZone.id}'));
    await tester.pump();

    expect(story.repairError, isNull);
    expect(draft(orphanLostZone), isNull);
    expect(orphan(orphanLostZone), findsNothing);
    expect(orphan(orphanGhost), findsOneWidget);
    expect(story.dirty, isTrue);
    expect(saved(orphanLostZone).name, 'lost zone');

    story.undo();
    await tester.pump();
    expect(orphan(orphanLostZone), findsOneWidget);
    expect(story.dirty, isFalse);
  });

  testWidgets('an element deleted from the map draft orphans its behaviours', (
    tester,
  ) async {
    await open(tester, [orphanMeeting]);
    expect(key('map-story-repair'), findsNothing);

    final document = maps.active!;
    document.commit(
      document.current.copyWith(
        entities: [
          for (final entity in document.current.entities)
            if (entity.id != 'luth') entity,
        ],
      ),
    );
    maps.notify();
    story.changed();
    await tester.pump();

    expect(orphan(orphanMeeting), findsOneWidget);
    document.restore(redo: false);
    story.changed();
    await tester.pump();
    expect(key('map-story-repair'), findsNothing);
  });
}
