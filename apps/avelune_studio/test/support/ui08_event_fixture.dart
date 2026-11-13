import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:map_core/map_core.dart';
import 'ui06_scene_fixture.dart';
import 'ui07_story_fixture.dart';

Future<Ui07StoryFixture> createUi08Fixture() async {
  final source = await Ui07StoryFixture.create();
  final manifest = await source.readFresh();
  final base = await source.maps.loadMap(source.session, manifest.maps.first);
  final map = base.map.copyWith(
    entities: [
      ...base.map.entities,
      const MapEntity(
        id: 'chief',
        name: 'Chef de gare',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 8, y: 7),
        npc: MapEntityNpcData(characterId: 'guide'),
      ),
      const MapEntity(
        id: 'traveller',
        name: 'Voyageuse',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 10, y: 9),
        npc: MapEntityNpcData(characterId: 'guide'),
      ),
    ],
    triggers: [
      const MapTrigger(
        id: 'platform',
        name: 'Entrée du quai',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 6, y: 10),
          size: GridSize(width: 5, height: 2),
        ),
      ),
    ],
  );
  await source.maps.saveMap(source.session, base, map);
  final events = LocalEventAdapter(
    session: source.session,
    mapAdapter: source.maps,
  );
  final existing = manifest.eventRegistry!.records.singleWhere(
    (record) => record.id == Ui06SceneFixture.eventId,
  );
  final definition = existing.definitionOrNull!;
  final alternatives = <(String, String, NarrativeEventSourceRef)>[
    (
      'evt_019abcde-9000-7000-8000-000000000801',
      'Entrée du quai',
      NarrativeEventSourceRef.triggerEnter(map.id, 'platform'),
    ),
    (
      'evt_019abcde-9000-7000-8000-000000000802',
      'Arrivée en gare',
      NarrativeEventSourceRef.mapEnter(map.id),
    ),
    (
      'evt_019abcde-9000-7000-8000-000000000803',
      'Voyageuse',
      NarrativeEventSourceRef.entityInteract(map.id, 'traveller'),
    ),
  ];
  await events.publishEvents([
    (
      id: existing.id,
      base: existing,
      current: NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: definition.id,
          name: 'PNJ Chef de gare',
          source: NarrativeEventSourceRef.entityInteract(map.id, 'chief'),
          conditions: definition.conditions,
          sceneId: definition.sceneId,
          reusePolicy: definition.reusePolicy,
          priority: definition.priority,
          order: definition.order,
        ),
        enabled: true,
        activeInLegacyMode: true,
      ),
    ),
    for (final (index, entry) in alternatives.indexed)
      (
        id: entry.$1,
        base: null,
        current: NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: entry.$1,
            name: entry.$2,
            source: entry.$3,
            conditions: const [],
            sceneId: Ui06SceneFixture.sceneId,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: index + 1,
          ),
          enabled: true,
        ),
      ),
  ]);
  return source;
}
