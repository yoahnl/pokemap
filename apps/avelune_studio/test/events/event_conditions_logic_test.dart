import 'package:avelune_studio/features/events/application/event_condition_editing.dart';
import 'package:avelune_studio/features/events/application/event_condition_labels.dart';
import 'package:avelune_studio/features/events/application/event_labels.dart';
import 'package:avelune_studio/features/map_workspace/application/story_zone_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  final facts = [
    NarrativeFactDefinition(id: 'ticket', label: 'Billet'),
    NarrativeFactDefinition(id: 'ready', label: 'Prêt'),
  ];
  final notTicket = NarrativeEventConditionExpression.not(
    NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('ticket', true),
    ),
  );
  final ready = NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition.fact('ready', true),
  );

  test('the result sentence states group logic and inversion', () {
    final result = eventTriggerSentence(
      NarrativeEventConditionExpression.any([notTicket, ready]),
      facts,
      const [],
    );
    expect(result, contains('au moins une'));
    expect(result, contains('il n’est pas vrai que'));
    expect(result, contains('Billet'));
    expect(result, contains(' ou '));
    expect(result, contains('Prêt'));
  });

  test('changing group logic preserves every child and inversion', () {
    final source = NarrativeEventConditionExpression.any([notTicket, ready]);
    final changed = changeEventConditionGroupKind(source, any: false);
    expect(changed, NarrativeEventConditionExpression.all([notTicket, ready]));
    expect(source, NarrativeEventConditionExpression.any([notTicket, ready]));
    expect(changeEventConditionGroupKind(changed, any: true), source);
  });

  test(
    'inversion labels preserve the authored fact and original expression',
    () {
      final source = NarrativeEventConditionExpression.all([ready]);
      expect(
        eventTriggerSentence(source, facts, const []),
        'L’événement se déclenche quand Prêt est égal à Oui.',
      );
      final inverse = NarrativeEventConditionExpression.not(ready);
      expect(
        eventExpressionSentence(inverse, facts, const []),
        contains('il n’est pas vrai que'),
      );
      expect(source, NarrativeEventConditionExpression.all([ready]));
    },
  );

  test('an empty condition list reads as no condition', () {
    expect(
      eventTriggerSentence(
        NarrativeEventConditionExpression.all(const []),
        facts,
        const [],
      ),
      'L’événement se déclenche sans condition.',
    );
  });

  test('story zone sources retain the exact map and zone identity', () {
    NarrativeEventRecord record(
      String id,
      String name,
      String map,
      String zone,
    ) => NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: name,
        source: NarrativeEventSourceRef.triggerEnter(map, zone),
        conditions: const [],
        priority: 0,
        order: 0,
      ),
    );
    final records = [
      record(
        'evt_00000000-0000-7000-8000-000000000011',
        'Annonce du train',
        'a',
        'quai',
      ),
      record(
        'evt_00000000-0000-7000-8000-000000000012',
        'Autre zone',
        'a',
        'ailleurs',
      ),
      record(
        'evt_00000000-0000-7000-8000-000000000013',
        'Autre carte',
        'b',
        'quai',
      ),
    ];
    final sources = [
      for (final event in records)
        if (storyZoneEventMoment(event, 'a', 'quai') case final moment?)
          (eventName(event), moment),
    ];
    expect(sources, [('Annonce du train', 'en entrant dans la zone')]);
  });

  test('a story zone states which activations its profile admits', () {
    const zone = MapTrigger(
      id: 'quai',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 2, y: 3),
        size: GridSize(width: 2, height: 1),
      ),
    );
    final flat = workspaceMap('a').copyWith(triggers: const [zone]);
    expect(
      storyZoneAdmissibleSources(
        project: workspaceProject,
        map: flat,
        trigger: zone,
      ),
      [('En entrant dans la zone', null), ('En touchant la zone', null)],
    );
    final spatial = flat.copyWith(
      spatialScene: MapSpatialScene(width: 20, depth: 16),
    );
    expect(
      storyZoneAdmissibleSources(
        project: workspaceProject,
        map: spatial,
        trigger: zone,
      ).last,
      ('En touchant la zone', 'réservé aux cartes 2D'),
    );
    final warp = zone.copyWith(type: TriggerType.warp);
    final system = storyZoneAdmissibleSources(
      project: workspaceProject,
      map: flat.copyWith(triggers: [warp]),
      trigger: warp,
    );
    expect(system.first.$2, 'zone système réglée par ses outils dédiés');
    expect(system.last.$2, 'réservé aux zones d’événement');
    final outside = zone.copyWith(
      area: const MapRect(
        pos: GridPos(x: 19, y: 3),
        size: GridSize(width: 4, height: 1),
      ),
    );
    expect(
      storyZoneAdmissibleSources(
        project: workspaceProject,
        map: flat.copyWith(triggers: [outside]),
        trigger: outside,
      ).first.$2,
      'surface hors de la carte',
    );
  });
}
