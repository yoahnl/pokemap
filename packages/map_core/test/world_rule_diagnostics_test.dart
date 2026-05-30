import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule diagnostics', () {
    test('reports unknown source and unknown target references', () {
      final project = _manifest(
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_unknown_refs',
            label: 'Unknown refs',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_missing',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'entity_missing',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleSourceUnknown),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleTargetUnknown),
        hasLength(1),
      );
    });

    test('reports effect target mismatch and raw technical labels', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_known',
            name: 'Known',
            relativePath: 'dialogues/known.yarn',
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_raw',
            label: 'world_rule_raw',
            debugTechnicalLabel: 'ScriptCondition(flag: fact_known)',
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
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.npcDialogueOverride,
              dialogueId: 'dialogue_known',
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleEffectTargetMismatch),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleUsesRawTechnicalId),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleLegacyPredicateLeak),
        hasLength(1),
      );
    });

    test('reports unsupported predicates and conflicting same target priority',
        () {
      final first = _validRule(
        id: 'world_rule_first',
        label: 'First',
      );
      final second = _validRule(
        id: 'world_rule_second',
        label: 'Second',
      );
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          first,
          second,
          WorldRuleDefinition(
            id: 'world_rule_bad_predicate',
            label: 'Bad predicate',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_known',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleSourceUnsupported),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleConflict),
        isNotEmpty,
      );
      expect(report.warningCount, greaterThanOrEqualTo(1));
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Diagnostics project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    worldRules: worldRules,
  );
}

MapData _mapWithNpc() {
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
        id: 'event_test',
        title: 'Event test',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _validRule({
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
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
  );
}
