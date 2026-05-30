import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorldRuleTargetContextReadModel', () {
    test('finds rules targeting a map event and filters other contexts', () {
      final model = buildWorldRuleTargetContextReadModel(
        _manifest(
          worldRules: [
            _eventRule(
              id: 'rule_event',
              label: 'Open event',
              mapId: 'map_test',
              eventId: 'event_gate',
            ),
            _eventRule(
              id: 'rule_other_event',
              label: 'Other event',
              mapId: 'map_test',
              eventId: 'event_other',
            ),
            _eventRule(
              id: 'rule_other_map',
              label: 'Other map',
              mapId: 'map_other',
              eventId: 'event_gate',
            ),
          ],
        ),
        maps: [_mapWithTargets(), _otherMap()],
        targetKind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_test',
        eventId: 'event_gate',
      );

      expect(model.ruleCount, 1);
      expect(model.rules.single.rule.id, 'rule_event');
      expect(model.rules.single.targetLabel, 'Event Gate');
      expect(model.rules.single.sourceLabel, 'Fact known est vrai');
      expect(model.rules.single.effectLabel, 'Event activé');
    });

    test('finds map entity and npc dialogue rules when requested', () {
      final manifest = _manifest(
        worldRules: [
          _entityRule(id: 'rule_entity', label: 'Hide entity'),
          _npcDialogueRule(id: 'rule_dialogue', label: 'Override dialogue'),
        ],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_override',
            name: 'Override Dialogue',
            relativePath: 'dialogues/override.yarn',
          ),
        ],
      );

      final entityModel = buildWorldRuleTargetContextReadModel(
        manifest,
        maps: [_mapWithTargets()],
        targetKind: WorldRuleTargetKind.mapEntity,
        mapId: 'map_test',
        entityId: 'npc_test',
      );
      final dialogueModel = buildWorldRuleTargetContextReadModel(
        manifest,
        maps: [_mapWithTargets()],
        targetKind: WorldRuleTargetKind.npcDialogue,
        mapId: 'map_test',
        entityId: 'npc_test',
      );

      expect(entityModel.rules.map((view) => view.rule.id), ['rule_entity']);
      expect(
          dialogueModel.rules.map((view) => view.rule.id), ['rule_dialogue']);
      expect(entityModel.rules.single.effectLabel, 'Entité cachée');
      expect(dialogueModel.rules.single.effectLabel,
          'Dialogue remplacé par Override Dialogue');
    });

    test('returns diagnostics attached to matching rules only', () {
      final model = buildWorldRuleTargetContextReadModel(
        _manifest(
          worldRules: [
            _eventRule(
              id: 'rule_bad_source',
              label: 'Bad Source',
              mapId: 'map_test',
              eventId: 'event_gate',
              sourceId: 'missing_fact',
            ),
            _eventRule(
              id: 'rule_other_bad_source',
              label: 'Other Bad Source',
              mapId: 'map_test',
              eventId: 'event_other',
              sourceId: 'missing_fact',
            ),
          ],
        ),
        maps: [_mapWithTargets()],
        targetKind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_test',
        eventId: 'event_gate',
      );

      expect(model.hasDiagnostics, isTrue);
      expect(model.rules.single.diagnostics, hasLength(1));
      expect(
        model.rules.single.diagnostics.single.code,
        WorldRuleDiagnosticCode.worldRuleSourceUnknown,
      );
      expect(model.diagnostics.map((diagnostic) => diagnostic.ruleId),
          ['rule_bad_source']);
    });

    test('orders rules deterministically by priority then id', () {
      final model = buildWorldRuleTargetContextReadModel(
        _manifest(
          worldRules: [
            _eventRule(
              id: 'rule_c',
              label: 'C',
              mapId: 'map_test',
              eventId: 'event_gate',
              priority: 2,
            ),
            _eventRule(
              id: 'rule_b',
              label: 'B',
              mapId: 'map_test',
              eventId: 'event_gate',
            ),
            _eventRule(
              id: 'rule_a',
              label: 'A',
              mapId: 'map_test',
              eventId: 'event_gate',
            ),
          ],
        ),
        maps: [_mapWithTargets()],
        targetKind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_test',
        eventId: 'event_gate',
      );

      expect(model.rules.map((view) => view.rule.id),
          ['rule_a', 'rule_b', 'rule_c']);
    });

    test('does not mutate ProjectManifest or require GameState', () {
      final manifest = _manifest(
        worldRules: [
          _eventRule(
            id: 'rule_event',
            label: 'Open event',
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );
      final beforeJson = manifest.toJson();

      buildWorldRuleTargetContextReadModel(
        manifest,
        maps: [_mapWithTargets()],
        targetKind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_test',
        eventId: 'event_gate',
      );

      expect(manifest.toJson(), beforeJson);
    });
  });
}

ProjectManifest _manifest({
  List<WorldRuleDefinition> worldRules = const [],
  List<ProjectDialogueEntry> dialogues = const [],
}) {
  return ProjectManifest(
    name: 'World rule context test',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
      ProjectMapEntry(
        id: 'map_other',
        name: 'Other map',
        relativePath: 'maps/map_other.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(id: 'fact_known', label: 'Fact known'),
    ],
    dialogues: dialogues,
    worldRules: worldRules,
  );
}

MapData _mapWithTargets() {
  return const MapData(
    id: 'map_test',
    name: 'Map test',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'npc_test',
        name: 'NPC test',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'NPC test'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Event Gate',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
      MapEventDefinition(
        id: 'event_other',
        title: 'Other Event',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'events', x: 2, y: 1),
      ),
    ],
  );
}

MapData _otherMap() {
  return const MapData(
    id: 'map_other',
    name: 'Other map',
    size: GridSize(width: 10, height: 8),
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Other Gate',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _eventRule({
  required String id,
  required String label,
  required String mapId,
  required String eventId,
  String sourceId = 'fact_known',
  int priority = 0,
  bool enabled = true,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    enabled: enabled,
    source: WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: sourceId,
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: mapId,
      eventId: eventId,
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
    priority: priority,
  );
}

WorldRuleDefinition _entityRule({
  required String id,
  required String label,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_known',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_test',
      entityId: 'npc_test',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
  );
}

WorldRuleDefinition _npcDialogueRule({
  required String id,
  required String label,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_known',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.npcDialogue,
      mapId: 'map_test',
      entityId: 'npc_test',
    ),
    effect: const WorldRuleEffect(
      kind: WorldRuleEffectKind.npcDialogueOverride,
      dialogueId: 'dialogue_override',
    ),
  );
}
