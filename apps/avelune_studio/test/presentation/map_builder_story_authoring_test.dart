import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';
import 'map_builder_story_harness.dart';

void main() {
  testWidgets('the add button places characters, signs and story zones', (
    tester,
  ) async {
    await open(tester);
    Finder key(String value) => find.byKey(ValueKey(value));

    await tester.tap(key('map-story-add'));
    await tester.pump();
    await tester.tap(key('map-story-add-character'));
    await tester.pump();
    await tester.pump();
    expect(key('map-story-character-elm'), findsOneWidget);
    await tester.enterText(key('map-story-character-search'), 'orme');
    await tester.pump();
    expect(key('map-story-character-rival'), findsNothing);
    await tester.tap(key('map-story-character-elm'));
    await tester.pump();
    expect(view.tool, StudioMapTool.character);
    expect(
      find.text('Cliquez sur la carte pour poser Professeur Orme.'),
      findsOneWidget,
    );

    final placed = CharacterEditingCommands(
      maps.active!,
      maps.project!,
    ).place(view.character!, const GridPos(x: 9, y: 9));
    view.select(maps.active!, MapSelectionFamily.character, placed.id);
    story.reconcile();
    await tester.pump();
    expect(view.tool, StudioMapTool.select);
    expect(story.adding, isNull);
    expect(story.selected?.id, placed.id);
    expect(key('map-story-properties-entity:${placed.id}'), findsOneWidget);

    await tester.tap(key('map-story-add'));
    await tester.pump();
    await tester.tap(key('map-story-add-zone'));
    await tester.pump();
    expect(view.tool, StudioMapTool.zone);
    expect(find.text('Dessinez la zone sur la carte.'), findsOneWidget);
    expect(
      story.addZone(
        const MapRect(
          pos: GridPos(x: 4, y: 4),
          size: GridSize(width: 2, height: 2),
        ),
      ),
      isTrue,
    );
    await tester.pump();
    final zone = maps.active!.current.triggers.last;
    expect(zone.name, 'Nouvelle zone');
    expect(zone.type, TriggerType.event);
    expect(view.selectedFor('a', MapSelectionFamily.trigger), zone.id);
    expect(view.tool, StudioMapTool.select);
    expect(
      story.addZone(
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      ),
      isFalse,
    );

    await tester.tap(key('map-story-add'));
    await tester.pump();
    await tester.tap(key('map-story-add-sign'));
    await tester.pump();
    expect(view.tool, StudioMapTool.sign);
    await tester.tap(key('map-story-add'));
    await tester.pump();
    expect(view.tool, StudioMapTool.select);
    expect(key('map-story-add-sign'), findsNothing);

    await tester.tap(key('map-story-element-entity:luth'));
    await tester.pump();
    tester.widget<StudioSelect>(key('map-story-appearance')).onChanged!('elm');
    await tester.pump();
    expect(
      maps.active!.current.entities
          .singleWhere((item) => item.id == 'luth')
          .npc!
          .characterId,
      'elm',
    );
  });

  testWidgets('behaviours are edited as a draft and published on save', (
    tester,
  ) async {
    await open(tester);
    Finder key(String value) => find.byKey(ValueKey(value));
    NarrativeEventRecord recordOf(String name) => story.behaviours
        .registry(maps.project!)!
        .records
        .singleWhere((record) => record.name == name);
    StudioSelect select(String value) =>
        tester.widget<StudioSelect>(key(value));

    await tester.tap(key('map-story-element-entity:luth'));
    await tester.pump();
    select('map-story-after').onChanged!('eachTime');
    await tester.pump();
    expect(recordOf('meeting').reusePolicy, NarrativeEventReusePolicy.reusable);
    expect(recordOf('meeting').enabledOrNull, isTrue);
    expect(story.dirty, isTrue);
    expect(
      maps.project!.eventRegistry!.records.first.reusePolicy,
      NarrativeEventReusePolicy.oneShot,
    );

    select('map-story-then').onChanged!('scene-greeting');
    await tester.pump();
    expect(recordOf('meeting').sceneId, 'scene-greeting');

    await tester.tap(key('map-story-behaviour-add'));
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsOneWidget);
    expect(recordOf('Comportement 3').draftOrNull, isNotNull);
    await tester.tap(key('map-story-behaviour-active'));
    await tester.pump();
    expect(story.error, isNotNull);
    expect(recordOf('Comportement 3').enabledOrNull, isNot(isTrue));
    select('map-story-then').onChanged!('scene-greeting');
    await tester.pump();
    await tester.tap(key('map-story-behaviour-active'));
    await tester.pump();
    expect(recordOf('Comportement 3').enabledOrNull, isTrue);

    await tester.tap(key('map-story-behaviour-delete'));
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsNothing);
    story.undo();
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsOneWidget);
    story.redo();
    await tester.pump();
    expect(find.text('3 · Comportement 3'), findsNothing);

    final port = _EventPort(maps);
    expect(await story.publish(storyEvents(story, port)), isTrue);
    expect(port.published, hasLength(1));
    expect(story.dirty, isFalse);
    final saved = maps.project!.eventRegistry!.records.singleWhere(
      (record) => record.name == 'meeting',
    );
    expect(saved.sceneId, 'scene-greeting');
    expect(saved.reusePolicy, NarrativeEventReusePolicy.reusable);
    expect(await story.publish(storyEvents(story, null)), isTrue);
  });

  testWidgets('the map element authors what happens on arrival', (
    tester,
  ) async {
    await open(tester);
    Finder key(String value) => find.byKey(ValueKey(value));
    StudioSelect select(String value) =>
        tester.widget<StudioSelect>(key(value));
    List<NarrativeEventRecord> arrivals() => [
      for (final record in story.behaviours.registry(maps.project!)!.records)
        if (record.source == NarrativeEventSourceRef.mapEnter('a')) record,
    ];

    await tester.tap(key('map-story-element-map:a'));
    await tester.pump();
    expect(find.text('Arrivée à a'), findsNWidgets(2));
    expect(select('map-story-when').options.keys, ['mapEnter']);

    await tester.tap(key('map-story-behaviour-add'));
    await tester.pump();
    expect(find.text('2 · Comportement 2'), findsOneWidget);
    final added = arrivals().last;
    expect(added.name, 'Comportement 2');
    expect(added.draftOrNull, isNotNull);

    select('map-story-then').onChanged!('scene-greeting');
    await tester.pump();
    select('map-story-after').onChanged!('oncePerVisit');
    await tester.pump();
    await tester.tap(key('map-story-behaviour-active'));
    await tester.pump();
    expect(story.error, isNull);
    final active = arrivals().last;
    expect(active.enabledOrNull, isTrue);
    expect(active.sceneId, 'scene-greeting');
    expect(active.resetPolicy, isA<NarrativeEventResetOnMapReentry>());
    expect(subtitle(tester, 'map:a'), '2 comportements');

    await tester.tap(find.text('Propriétés'));
    await tester.pump();
    expect(
      find.text(
        'Événement de carte : ses conditions et sa scène se règlent dans Comportement.',
      ),
      findsOneWidget,
    );

    final port = _EventPort(maps);
    expect(await story.publish(storyEvents(story, port)), isTrue);
    expect(port.published, [added.id]);
    final saved = maps.project!.eventRegistry!.records.singleWhere(
      (record) => record.id == added.id,
    );
    expect(saved.source, NarrativeEventSourceRef.mapEnter('a'));
    expect(saved.enabledOrNull, isTrue);
    expect(saved.sceneId, 'scene-greeting');
  });
}

class _EventPort implements EventPort {
  _EventPort(this.maps);

  final MapWorkspaceController maps;
  final published = <String>[];

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async {
    published.add(id);
    final before = maps.project!;
    final registry = before.eventRegistry!;
    final records = [
      for (final record in registry.records)
        if (record.id != id) record,
      ?current,
    ];
    return ResourceMutationReceipt(
      before: before,
      manifest: before.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: registry.mode,
          records: records,
          legacyClaims: registry.legacyClaims,
        ),
      ),
      beforeRevision: 'r${published.length - 1}',
      revision: 'r${published.length}',
      changedPaths: const ['project.json'],
    );
  }
}
