import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
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
  final maps = MapWorkspaceController(source.session, source.maps);
  await maps.initialize();
  final narrative = NarrativeWorkspaceController(
    maps,
    LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
    () {},
    (_, _) async {},
  );
  final events = EventWorkspaceController(
    narrative,
    LocalEventAdapter(session: source.session, mapAdapter: source.maps),
    changed: () {},
  );
  try {
    if (!await events.prepare()) throw StateError(events.error!);
    events.rename(Ui06SceneFixture.eventId, 'PNJ Chef de gare');
    events.setSource(
      Ui06SceneFixture.eventId,
      NarrativeEventSourceRef.entityInteract(map.id, 'chief'),
    );
    events.setEnabled(Ui06SceneFixture.eventId, true);
    final alternatives = <(String, NarrativeEventSourceRef)>[
      (
        'Entrée du quai',
        NarrativeEventSourceRef.triggerEnter(map.id, 'platform'),
      ),
      ('Arrivée en gare', NarrativeEventSourceRef.mapEnter(map.id)),
      (
        'Voyageuse',
        NarrativeEventSourceRef.entityInteract(map.id, 'traveller'),
      ),
    ];
    for (final entry in alternatives) {
      final record = events.create(entry.$1, source: entry.$2)!;
      events.setScene(record.id, Ui06SceneFixture.sceneId);
      events.setReuse(record.id, NarrativeEventReusePolicy.reusable);
      events.configure(record.id);
    }
    if (!await events.save()) throw StateError(events.error!);
  } finally {
    events.dispose();
    narrative.dispose();
    maps.dispose();
  }
  return source;
}
