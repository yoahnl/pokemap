import 'dart:collection';
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'batch equals canonical mixed operations including positions and suffixes',
    () {
      final project = _project();
      final rules = [
        _rule('world_rule_same', ' Same '),
        _rule('world_rule_existing', 'Renamed'),
        _rule('world_rule_same_2', 'Same'),
      ];
      final batch = upsertWorldRules(project, rules: rules, maps: [_map]);
      final sequential = rules.fold(project, _applySingle);
      expect(batch.toJson(), sequential.toJson());
      expect(batch.worldRules.map((rule) => rule.id), [
        'world_rule_existing',
        'world_rule_keep',
        'world_rule_same',
        'world_rule_same_2',
      ]);
      expect(batch.worldRules[2].label, 'Same');
    },
  );

  test('128 rule batch preserves manifest maps and immutable input rules', () {
    final project = _project();
    final rules = List<WorldRuleDefinition>.unmodifiable(
      List.generate(128, (i) => _rule('world_rule_batch_$i', 'Batch $i')),
    );
    final before = jsonEncode(project.toJson());
    final ruleBytes = jsonEncode(rules.map((rule) => rule.toJson()).toList());
    final maps = List<MapData>.unmodifiable([_map]);
    final mapBytes = jsonEncode(_map.toJson());
    final result = upsertWorldRules(project, rules: rules, maps: maps);
    expect(result.worldRules, hasLength(130));
    expect(jsonEncode(project.toJson()), before);
    expect(jsonEncode(rules.map((rule) => rule.toJson()).toList()), ruleBytes);
    expect(jsonEncode(maps.single.toJson()), mapBytes);
    expect(result.facts, project.facts);
    expect(result.maps, project.maps);
  });

  test('duplicate ids are rejected before source validation', () {
    final invalid = _rule(
      'world_rule_duplicate',
      'Duplicate',
      factId: 'missing',
    );
    expect(
      () => upsertWorldRules(_project(), rules: [invalid, invalid]),
      throwsA(
        isA<WorldRuleBatchException>()
            .having((error) => error.index, 'index', 1)
            .having(
              (error) => error.cause.toString(),
              'cause',
              contains('must be unique'),
            ),
      ),
    );
  });

  test(
    'empty and 129 member batches are rejected without changing the project',
    () {
      final project = _project();
      final before = jsonEncode(project.toJson());
      for (final rules in <List<WorldRuleDefinition>>[
        [],
        List.generate(129, (i) => _rule('world_rule_batch_$i', 'Batch $i')),
      ]) {
        expect(
          () => upsertWorldRules(project, rules: rules),
          throwsArgumentError,
        );
        expect(jsonEncode(project.toJson()), before);
      }
    },
  );

  test('invalid last reference reports its index without mutating inputs', () {
    final project = _project();
    final before = jsonEncode(project.toJson());
    final rules = [
      _rule('world_rule_first', 'First'),
      _rule('world_rule_last', 'Last', factId: 'missing'),
    ];
    expect(
      () => upsertWorldRules(project, rules: rules, maps: [_map]),
      throwsA(
        isA<WorldRuleBatchException>()
            .having((error) => error.index, 'index', 1)
            .having(
              (error) => error.cause.toString(),
              'cause',
              contains('Unknown narrative fact'),
            ),
      ),
    );
    expect(jsonEncode(project.toJson()), before);
    expect(rules.first.id, 'world_rule_first');
  });

  test(
    'new ids must equal the generated id in the projected batch context',
    () {
      expect(
        () => upsertWorldRules(
          _project(),
          maps: [_map],
          rules: [
            _rule('world_rule_same', 'Same'),
            _rule('world_rule_wrong', 'Same'),
          ],
        ),
        throwsA(
          isA<WorldRuleBatchException>()
              .having((error) => error.index, 'index', 1)
              .having(
                (error) => error.cause.toString(),
                'cause',
                contains('world_rule_same_2'),
              ),
        ),
      );
    },
  );

  test(
    'batch validates dialogue and narrative targets against shared context',
    () {
      const eventId = 'evt_019abcde-0000-7000-8000-000000000001';
      final project = _project().copyWith(
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_known',
            name: 'Known',
            relativePath: 'dialogues/known.yarn',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: eventId,
                name: 'Draft',
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );
      final result = upsertWorldRules(
        project,
        maps: [_map],
        rules: [
          WorldRuleDefinition(
            id: 'world_rule_dialogue',
            label: 'Dialogue',
            source: _source(),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.npcDialogue,
              mapId: 'map',
              entityId: 'npc',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.npcDialogueOverride,
              dialogueId: 'dialogue_known',
            ),
          ),
          WorldRuleDefinition(
            id: 'world_rule_event',
            label: 'Event',
            source: _source(),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.narrativeEvent,
              mapId: '',
              eventId: eventId,
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );
      expect(result.worldRules.skip(2).map((rule) => rule.target.kind), [
        WorldRuleTargetKind.npcDialogue,
        WorldRuleTargetKind.narrativeEvent,
      ]);
    },
  );
  test(
    'single and batch validation leave unrelated map collections unread',
    () {
      const event = MapEventDefinition(
        id: 'event',
        title: 'Event',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'events', x: 0, y: 0),
      );
      for (final batch in [false, true]) {
        final unrelatedEntities = _CountingList<MapEntity>(_map.entities);
        final unrelatedEvents = _CountingList<MapEventDefinition>([event]);
        final maps = [
          _map.copyWith(events: [event]),
          _map.copyWith(
            id: 'unrelated',
            entities: unrelatedEntities,
            events: unrelatedEvents,
          ),
        ];
        final rules = [
          _rule('world_rule_entity', 'Entity'),
          WorldRuleDefinition(
            id: 'world_rule_event',
            label: 'Event',
            source: _source(),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEvent,
              mapId: 'map',
              eventId: 'event',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ];
        if (batch) {
          upsertWorldRules(_project(), rules: rules, maps: maps);
        } else {
          for (final rule in rules) {
            addWorldRule(
              _project(),
              label: rule.label,
              source: rule.source,
              target: rule.target,
              effect: rule.effect,
              maps: maps,
            );
          }
        }
        expect(unrelatedEntities.reads, 0, reason: 'batch=$batch');
        expect(unrelatedEvents.reads, 0, reason: 'batch=$batch');
      }
    },
  );
}

ProjectManifest _project() => ProjectManifest(
  name: 'World Rule batch',
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const [],
  facts: [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate')],
  worldRules: [
    _rule('world_rule_existing', 'Existing'),
    _rule('world_rule_keep', 'Keep'),
  ],
);

WorldRuleDefinition _rule(
  String id,
  String label, {
  String factId = 'fact_gate',
}) => WorldRuleDefinition(
  id: id,
  label: label,
  source: _source(factId),
  target: const WorldRuleTarget(
    kind: WorldRuleTargetKind.mapEntity,
    mapId: 'map',
    entityId: 'npc',
  ),
  effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
);

WorldRuleSource _source([String factId = 'fact_gate']) => WorldRuleSource(
  kind: WorldRuleSourceKind.fact,
  sourceId: factId,
  predicate: WorldRuleSourcePredicate.isTrue,
);

ProjectManifest _applySingle(
  ProjectManifest project,
  WorldRuleDefinition rule,
) {
  if (project.worldRules.any((item) => item.id == rule.id)) {
    return updateWorldRule(
      project,
      ruleId: rule.id,
      label: rule.label,
      source: rule.source,
      target: rule.target,
      effect: rule.effect,
      maps: [_map],
    ).updatedProject;
  }
  return addWorldRule(
    project,
    label: rule.label,
    source: rule.source,
    target: rule.target,
    effect: rule.effect,
    maps: [_map],
  ).updatedProject;
}

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  entities: [
    MapEntity(
      id: 'npc',
      name: 'NPC',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      npc: MapEntityNpcData(displayName: 'NPC'),
    ),
  ],
);

final class _CountingList<T> extends ListBase<T> {
  _CountingList(Iterable<T> values) : _values = values.toList();

  final List<T> _values;
  var reads = 0;

  @override
  int get length => _values.length;

  @override
  set length(int value) => _values.length = value;

  @override
  T operator [](int index) {
    reads++;
    return _values[index];
  }

  @override
  void operator []=(int index, T value) => _values[index] = value;
}
